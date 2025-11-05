import 'package:flutter/material.dart';
import '../models/lesson_model.dart';
import '../services/lesson_service.dart';

/// Провайдер для управления занятиями
class LessonProvider extends ChangeNotifier {
  final LessonService _lessonService = LessonService();

  List<LessonModel> _lessons = [];
  List<LessonModel> _activeLessons = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _searchQuery;
  String? _selectedGroupId;
  String? _selectedSubject;

  /// Список всех занятий
  List<LessonModel> get lessons => _lessons;
  
  /// Список активных занятий
  List<LessonModel> get activeLessons => _activeLessons;
  
  /// Загружается ли данные
  bool get isLoading => _isLoading;
  
  /// Сообщение об ошибке
  String? get errorMessage => _errorMessage;
  
  /// Поисковый запрос
  String? get searchQuery => _searchQuery;
  
  /// Выбранная группа
  String? get selectedGroupId => _selectedGroupId;
  
  /// Выбранный предмет
  String? get selectedSubject => _selectedSubject;

  /// Отфильтрованные занятия
  List<LessonModel> get filteredLessons {
    List<LessonModel> filtered = _lessons;

    // Фильтр по поисковому запросу
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      filtered = filtered.where((lesson) {
        return lesson.subject.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
               lesson.groupName.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
               lesson.classroom.toLowerCase().contains(_searchQuery!.toLowerCase());
      }).toList();
    }

    // Фильтр по группе
    if (_selectedGroupId != null) {
      filtered = filtered.where((lesson) => lesson.groupId == _selectedGroupId).toList();
    }

    // Фильтр по предмету
    if (_selectedSubject != null) {
      filtered = filtered.where((lesson) => lesson.subject == _selectedSubject).toList();
    }

    return filtered;
  }

  /// Количество занятий
  int get lessonCount => _lessons.length;

  /// Количество активных занятий
  int get activeLessonCount => _activeLessons.length;

  /// Инициализация провайдера
  Future<void> initialize() async {
    await loadLessons();
  }

  /// Загрузка занятий преподавателя
  Future<void> loadLessons([String? teacherId]) async {
    _setLoading(true);
    _clearError();

    try {
      if (teacherId != null) {
        _lessons = await _lessonService.getTeacherLessons(teacherId);
        _activeLessons = _lessons.where((lesson) => lesson.isCurrentlyActive).toList();
      } else {
        _lessons = [];
        _activeLessons = [];
      }
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки занятий: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Загрузка активных занятий
  Future<void> loadActiveLessons(String? teacherId) async {
    if (teacherId == null) return;
    
    _setLoading(true);
    _clearError();

    try {
      _activeLessons = await _lessonService.getActiveLessons(teacherId);
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки активных занятий: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Загрузка занятий группы
  Future<void> loadGroupLessons(String groupId) async {
    _setLoading(true);
    _clearError();

    try {
      _lessons = await _lessonService.getGroupLessons(groupId);
      _activeLessons = _lessons.where((lesson) => lesson.isCurrentlyActive).toList();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки занятий группы: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Создание нового занятия
  Future<bool> createLesson(LessonModel lesson) async {
    _setLoading(true);
    _clearError();

    try {
      final lessonId = await _lessonService.createLesson(lesson);
      final newLesson = lesson.copyWith(id: lessonId);
      _lessons.insert(0, newLesson);
      
      if (newLesson.isCurrentlyActive) {
        _activeLessons.add(newLesson);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Ошибка создания занятия: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Обновление занятия
  Future<bool> updateLesson(LessonModel lesson) async {
    _setLoading(true);
    _clearError();

    try {
      await _lessonService.updateLesson(lesson);
      final index = _lessons.indexWhere((l) => l.id == lesson.id);
      if (index != -1) {
        _lessons[index] = lesson;
        
        // Обновляем активные занятия
        if (lesson.isCurrentlyActive) {
          final activeIndex = _activeLessons.indexWhere((l) => l.id == lesson.id);
          if (activeIndex != -1) {
            _activeLessons[activeIndex] = lesson;
          } else {
            _activeLessons.add(lesson);
          }
        } else {
          _activeLessons.removeWhere((l) => l.id == lesson.id);
        }
        
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Ошибка обновления занятия: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Удаление занятия
  Future<bool> deleteLesson(String lessonId) async {
    _setLoading(true);
    _clearError();

    try {
      await _lessonService.deleteLesson(lessonId);
      _lessons.removeWhere((lesson) => lesson.id == lessonId);
      _activeLessons.removeWhere((lesson) => lesson.id == lessonId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Ошибка удаления занятия: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Отметка посещаемости студента
  Future<bool> markStudentAttendance(String lessonId, String studentId) async {
    _setLoading(true);
    _clearError();

    try {
      await _lessonService.markStudentAttendance(lessonId, studentId);
      
      // Обновляем локальный список
      final index = _lessons.indexWhere((l) => l.id == lessonId);
      if (index != -1) {
        _lessons[index] = _lessons[index].markStudentAttendance(studentId);
        
        // Обновляем активные занятия
        final activeIndex = _activeLessons.indexWhere((l) => l.id == lessonId);
        if (activeIndex != -1) {
          _activeLessons[activeIndex] = _lessons[index];
        }
        
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Ошибка отметки посещаемости: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Обновление QR-кода занятия
  Future<bool> refreshLessonQR(String lessonId) async {
    _setLoading(true);
    _clearError();

    try {
      await _lessonService.refreshLessonQR(lessonId);
      
      // Обновляем локальный список
      final index = _lessons.indexWhere((l) => l.id == lessonId);
      if (index != -1) {
        final lesson = await _lessonService.getLesson(lessonId);
        if (lesson != null) {
          _lessons[index] = lesson;
          
          // Обновляем активные занятия
          final activeIndex = _activeLessons.indexWhere((l) => l.id == lessonId);
          if (activeIndex != -1) {
            _activeLessons[activeIndex] = lesson;
          }
          
          notifyListeners();
        }
      }
      return true;
    } catch (e) {
      _setError('Ошибка обновления QR-кода: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Завершение занятия
  Future<bool> endLesson(String lessonId) async {
    _setLoading(true);
    _clearError();

    try {
      await _lessonService.endLesson(lessonId);
      
      // Обновляем локальный список
      final index = _lessons.indexWhere((l) => l.id == lessonId);
      if (index != -1) {
        _lessons[index] = _lessons[index].copyWith(isActive: false);
        _activeLessons.removeWhere((l) => l.id == lessonId);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Ошибка завершения занятия: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Поиск занятий
  Future<void> searchLessons(String teacherId, String query) async {
    _setSearchQuery(query);
    
    if (query.isEmpty) {
      await loadLessons(teacherId);
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      _lessons = await _lessonService.searchLessons(teacherId, query);
      _activeLessons = _lessons.where((lesson) => lesson.isCurrentlyActive).toList();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка поиска занятий: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Получение занятия по ID
  LessonModel? getLessonById(String lessonId) {
    try {
      return _lessons.firstWhere((lesson) => lesson.id == lessonId);
    } catch (e) {
      return null;
    }
  }

  /// Получение занятий за период
  Future<void> loadLessonsByDateRange(
    String teacherId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      _lessons = await _lessonService.getLessonsByDateRange(teacherId, startDate, endDate);
      _activeLessons = _lessons.where((lesson) => lesson.isCurrentlyActive).toList();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки занятий за период: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Получение занятий по предмету
  Future<void> loadLessonsBySubject(String teacherId, String subject) async {
    _setLoading(true);
    _clearError();

    try {
      _lessons = await _lessonService.getLessonsBySubject(teacherId, subject);
      _activeLessons = _lessons.where((lesson) => lesson.isCurrentlyActive).toList();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки занятий по предмету: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Получение занятий на сегодня
  Future<void> loadTodayLessons(String teacherId) async {
    _setLoading(true);
    _clearError();

    try {
      _lessons = await _lessonService.getTodayLessons(teacherId);
      _activeLessons = _lessons.where((lesson) => lesson.isCurrentlyActive).toList();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки занятий на сегодня: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Получение занятий на завтра
  Future<void> loadTomorrowLessons(String teacherId) async {
    _setLoading(true);
    _clearError();

    try {
      _lessons = await _lessonService.getTomorrowLessons(teacherId);
      _activeLessons = _lessons.where((lesson) => lesson.isCurrentlyActive).toList();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки занятий на завтра: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Получение статистики занятия
  Future<Map<String, dynamic>?> getLessonStats(String lessonId) async {
    try {
      return await _lessonService.getLessonStats(lessonId);
    } catch (e) {
      _setError('Ошибка получения статистики занятия: $e');
      return null;
    }
  }

  /// Установка фильтра по группе
  void setGroupFilter(String? groupId) {
    _selectedGroupId = groupId;
    notifyListeners();
  }

  /// Установка фильтра по предмету
  void setSubjectFilter(String? subject) {
    _selectedSubject = subject;
    notifyListeners();
  }

  /// Очистка фильтров
  void clearFilters() {
    _selectedGroupId = null;
    _selectedSubject = null;
    _setSearchQuery(null);
    notifyListeners();
  }

  /// Очистка данных
  void clear() {
    _lessons.clear();
    _activeLessons.clear();
    _clearError();
    _setSearchQuery(null);
    _selectedGroupId = null;
    _selectedSubject = null;
    notifyListeners();
  }

  /// Установка состояния загрузки
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Установка ошибки
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Очистка ошибки
  void _clearError() {
    _errorMessage = null;
  }

  /// Установка поискового запроса
  void _setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Обновление поискового запроса
  void updateSearchQuery(String? query) {
    _setSearchQuery(query);
  }

  /// Получение занятий с сортировкой
  List<LessonModel> getSortedLessons(LessonSortType sortType) {
    final sortedLessons = List<LessonModel>.from(filteredLessons);
    
    switch (sortType) {
      case LessonSortType.dateAsc:
        sortedLessons.sort((a, b) => a.date.compareTo(b.date));
        break;
      case LessonSortType.dateDesc:
        sortedLessons.sort((a, b) => b.date.compareTo(a.date));
        break;
      case LessonSortType.subjectAsc:
        sortedLessons.sort((a, b) => a.subject.compareTo(b.subject));
        break;
      case LessonSortType.subjectDesc:
        sortedLessons.sort((a, b) => b.subject.compareTo(a.subject));
        break;
      case LessonSortType.groupAsc:
        sortedLessons.sort((a, b) => a.groupName.compareTo(b.groupName));
        break;
      case LessonSortType.groupDesc:
        sortedLessons.sort((a, b) => b.groupName.compareTo(a.groupName));
        break;
      case LessonSortType.timeAsc:
        sortedLessons.sort((a, b) => a.startTime.compareTo(b.startTime));
        break;
      case LessonSortType.timeDesc:
        sortedLessons.sort((a, b) => b.startTime.compareTo(a.startTime));
        break;
    }
    
    return sortedLessons;
  }
}

/// Типы сортировки занятий
enum LessonSortType {
  dateAsc('По дате (ранние)'),
  dateDesc('По дате (поздние)'),
  subjectAsc('По предмету (А-Я)'),
  subjectDesc('По предмету (Я-А)'),
  groupAsc('По группе (А-Я)'),
  groupDesc('По группе (Я-А)'),
  timeAsc('По времени (ранние)'),
  timeDesc('По времени (поздние)');

  const LessonSortType(this.displayName);
  final String displayName;
}