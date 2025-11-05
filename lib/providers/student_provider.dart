import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Провайдер для управления состоянием студентов
/// Отвечает за загрузку, добавление, обновление и удаление студентов
class StudentProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final LocalDatabaseService _localDatabaseService = LocalDatabaseService();

  // Состояние студентов
  List<Student> _students = [];
  Map<String, List<Student>> _studentsByGroup = {};
  bool _isLoading = false;
  String? _errorMessage;

  // Геттеры
  List<Student> get students => _students;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalStudents => _students.length;

  /// Получение студентов группы
  List<Student> getStudentsByGroup(String groupId) {
    return _studentsByGroup[groupId] ?? [];
  }

  /// Получение студента по ID
  Student? getStudentById(String studentId) {
    try {
      return _students.firstWhere((student) => student.id == studentId);
    } catch (e) {
      return null;
    }
  }

  /// Инициализация провайдера
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // Загружаем студентов из локальной базы
      await _loadStudentsFromLocal();
    } catch (e) {
      _setError('Ошибка инициализации студентов: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Загрузка студентов из локальной базы
  Future<void> _loadStudentsFromLocal() async {
    try {
      // Здесь можно добавить логику загрузки из локальной базы
      // Пока оставляем пустым, так как студенты загружаются по группам
    } catch (e) {
      print('Ошибка загрузки студентов из локальной базы: $e');
    }
  }

  /// Загрузка студентов группы
  Future<void> loadStudentsByGroup(String groupId) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Загружаем из локальной базы
      final localStudents = await _localDatabaseService.getStudentsByGroup(groupId);
      _studentsByGroup[groupId] = localStudents;
      
      // Загружаем из Firebase
      final firebaseStudents = await _databaseService.getStudentsByGroup(groupId);
      
      // Обновляем локальную базу
      for (final student in firebaseStudents) {
        await _localDatabaseService.saveStudent(student);
      }
      
      _studentsByGroup[groupId] = firebaseStudents;
      _updateStudentsList();
      
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки студентов: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Добавление нового студента
  Future<bool> addStudent(Student student) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Добавляем в Firebase
      final studentId = await _databaseService.addStudent(student);
      
      // Обновляем локальную базу
      final updatedStudent = student.copyWith(id: studentId);
      await _localDatabaseService.saveStudent(updatedStudent);
      
      // Обновляем локальное состояние
      if (_studentsByGroup[student.groupId] != null) {
        _studentsByGroup[student.groupId]!.add(updatedStudent);
        _updateStudentsList();
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Ошибка добавления студента: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Обновление данных студента
  Future<bool> updateStudent(String studentId, Student updatedStudent) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Обновляем в Firebase
      await _databaseService.updateStudent(studentId, updatedStudent);
      
      // Обновляем в локальной базе
      await _localDatabaseService.saveStudent(updatedStudent);
      
      // Обновляем локальное состояние
      final groupId = updatedStudent.groupId;
      if (_studentsByGroup[groupId] != null) {
        final index = _studentsByGroup[groupId]!
            .indexWhere((student) => student.id == studentId);
        if (index != -1) {
          _studentsByGroup[groupId]![index] = updatedStudent;
          _updateStudentsList();
        }
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Ошибка обновления студента: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Удаление студента из группы
  Future<bool> removeStudentFromGroup(String studentId, String groupId) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Удаляем из Firebase
      await _databaseService.removeStudentFromGroup(studentId, groupId);
      
      // Удаляем из локальной базы
      await _localDatabaseService.deleteStudent(studentId);
      
      // Обновляем локальное состояние
      if (_studentsByGroup[groupId] != null) {
        _studentsByGroup[groupId]!.removeWhere((student) => student.id == studentId);
        _updateStudentsList();
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Ошибка удаления студента: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Поиск студентов по имени
  List<Student> searchStudents(String query) {
    if (query.isEmpty) return _students;
    
    final lowercaseQuery = query.toLowerCase();
    return _students.where((student) {
      return student.name.toLowerCase().contains(lowercaseQuery) ||
             student.surname.toLowerCase().contains(lowercaseQuery) ||
             student.studentId.toLowerCase().contains(lowercaseQuery) ||
             student.email.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Получение статистики студентов группы
  Map<String, int> getGroupStatistics(String groupId) {
    final groupStudents = getStudentsByGroup(groupId);
    
    return {
      'total': groupStudents.length,
      'active': groupStudents.where((s) => s.isActive).length,
      'inactive': groupStudents.where((s) => !s.isActive).length,
    };
  }

  /// Обновление списка всех студентов
  void _updateStudentsList() {
    _students = [];
    for (final groupStudents in _studentsByGroup.values) {
      _students.addAll(groupStudents);
    }
  }

  /// Очистка данных студентов
  void clearStudents() {
    _students.clear();
    _studentsByGroup.clear();
    notifyListeners();
  }

  /// Очистка студентов группы
  void clearGroupStudents(String groupId) {
    _studentsByGroup.remove(groupId);
    _updateStudentsList();
    notifyListeners();
  }

  /// Установка состояния загрузки
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Установка сообщения об ошибке
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Очистка сообщения об ошибке
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Очистка ошибки (публичный метод)
  void clearError() {
    _clearError();
  }

  /// Обновление данных студентов из Firebase
  Future<void> refreshStudents(String groupId) async {
    await loadStudentsByGroup(groupId);
  }

  /// Получение студентов с низкой посещаемостью
  Future<List<Student>> getStudentsWithLowAttendance(
    String groupId,
    double threshold,
  ) async {
    try {
      final students = getStudentsByGroup(groupId);
      final lowAttendanceStudents = <Student>[];
      
      // Здесь можно добавить логику расчета посещаемости
      // Пока возвращаем пустой список
      
      return lowAttendanceStudents;
    } catch (e) {
      print('Ошибка получения студентов с низкой посещаемостью: $e');
      return [];
    }
  }

  /// Экспорт данных студентов группы
  Future<Map<String, dynamic>> exportGroupStudents(String groupId) async {
    try {
      final students = getStudentsByGroup(groupId);
      
      return {
        'groupId': groupId,
        'exportDate': DateTime.now().toIso8601String(),
        'students': students.map((student) => student.toJson()).toList(),
        'totalCount': students.length,
      };
    } catch (e) {
      throw Exception('Ошибка экспорта студентов: $e');
    }
  }
}
