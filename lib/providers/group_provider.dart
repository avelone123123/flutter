import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../services/group_service.dart';
import '../services/web_group_service.dart';

/// Провайдер для управления группами
class GroupProvider extends ChangeNotifier {
  final GroupService? _groupService = kIsWeb ? null : GroupService();
  final WebGroupService? _webGroupService = kIsWeb ? WebGroupService() : null;

  List<GroupModel> _groups = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _searchQuery;

  /// Список групп
  List<GroupModel> get groups => _groups;
  
  /// Загружается ли данные
  bool get isLoading => _isLoading;
  
  /// Сообщение об ошибке
  String? get errorMessage => _errorMessage;
  
  /// Поисковый запрос
  String? get searchQuery => _searchQuery;

  /// Отфильтрованные группы
  List<GroupModel> get filteredGroups {
    if (_searchQuery == null || _searchQuery!.isEmpty) {
      return _groups;
    }
    
    return _groups.where((group) {
      return group.name.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
             group.course.toLowerCase().contains(_searchQuery!.toLowerCase());
    }).toList();
  }

  /// Количество групп
  int get groupCount => _groups.length;

  /// Инициализация провайдера
  Future<void> initialize() async {
    await loadGroups();
  }

  /// Загрузка групп преподавателя
  Future<void> loadGroups([String? teacherId]) async {
    _setLoading(true);
    _clearError();

    try {
      if (teacherId != null) {
        if (kIsWeb) {
          _groups = await _webGroupService!.getTeacherGroups(teacherId);
        } else {
          _groups = await _groupService!.getTeacherGroups(teacherId);
        }
      } else {
        // Здесь можно загрузить группы по умолчанию или показать пустой список
        _groups = [];
      }
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки групп: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Создание новой группы
  Future<bool> createGroup(GroupModel group) async {
    _setLoading(true);
    _clearError();

    try {
      final groupId = kIsWeb 
          ? await _webGroupService!.createGroup(group)
          : await _groupService!.createGroup(group);
      final newGroup = group.copyWith(id: groupId);
      _groups.insert(0, newGroup);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Ошибка создания группы: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Обновление группы
  Future<bool> updateGroup(GroupModel group) async {
    _setLoading(true);
    _clearError();

    try {
      if (kIsWeb) {
        await _webGroupService!.updateGroup(group);
      } else {
        await _groupService!.updateGroup(group);
      }
      final index = _groups.indexWhere((g) => g.id == group.id);
      if (index != -1) {
        _groups[index] = group;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Ошибка обновления группы: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Удаление группы
  Future<bool> deleteGroup(String groupId) async {
    _setLoading(true);
    _clearError();

    try {
      if (kIsWeb) {
        await _webGroupService!.deleteGroup(groupId);
      } else {
        await _groupService!.deleteGroup(groupId);
      }
      _groups.removeWhere((group) => group.id == groupId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Ошибка удаления группы: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Добавление студента в группу
  Future<bool> addStudentToGroup(String groupId, String studentId) async {
    _setLoading(true);
    _clearError();

    try {
      if (kIsWeb) {
        await _webGroupService!.addStudentToGroup(groupId, studentId);
      } else {
        await _groupService!.addStudentToGroup(groupId, studentId);
      }
      
      // Обновляем локальный список
      final index = _groups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        _groups[index] = _groups[index].addStudent(studentId);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Ошибка добавления студента: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Удаление студента из группы
  Future<bool> removeStudentFromGroup(String groupId, String studentId) async {
    _setLoading(true);
    _clearError();

    try {
      if (kIsWeb) {
        await _webGroupService!.removeStudentFromGroup(groupId, studentId);
      } else {
        await _groupService!.removeStudentFromGroup(groupId, studentId);
      }
      
      // Обновляем локальный список
      final index = _groups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        _groups[index] = _groups[index].removeStudent(studentId);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Ошибка удаления студента: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Поиск групп
  Future<void> searchGroups(String teacherId, String query) async {
    _setSearchQuery(query);
    
    if (query.isEmpty) {
      await loadGroups(teacherId);
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      if (kIsWeb) {
        _groups = await _webGroupService!.searchGroups(query, teacherId);
      } else {
        _groups = await _groupService!.searchGroups(teacherId, query);
      }
      notifyListeners();
    } catch (e) {
      _setError('Ошибка поиска групп: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Получение группы по ID
  GroupModel? getGroupById(String groupId) {
    try {
      return _groups.firstWhere((group) => group.id == groupId);
    } catch (e) {
      return null;
    }
  }

  /// Получение групп по курсу
  List<GroupModel> getGroupsByCourse(String course) {
    return _groups.where((group) => group.course == course).toList();
  }

  /// Получение групп по году обучения
  List<GroupModel> getGroupsByYear(int year) {
    return _groups.where((group) => group.year == year).toList();
  }

  /// Получение статистики группы
  Future<Map<String, dynamic>?> getGroupStats(String groupId) async {
    try {
      if (kIsWeb) {
        return await _webGroupService!.getGroupStats(groupId);
      } else {
        return await _groupService!.getGroupStats(groupId);
      }
    } catch (e) {
      _setError('Ошибка получения статистики группы: $e');
      return null;
    }
  }

  /// Получение студентов группы
  Future<List<Map<String, dynamic>>> getGroupStudents(String groupId) async {
    try {
      if (kIsWeb) {
        return await _webGroupService!.getGroupStudents(groupId);
      } else {
        return await _groupService!.getGroupStudents(groupId);
      }
    } catch (e) {
      _setError('Ошибка получения студентов группы: $e');
      return [];
    }
  }

  /// Проверка существования группы с таким названием
  Future<bool> isGroupNameExists(String teacherId, String groupName) async {
    try {
      if (kIsWeb) {
        return await _webGroupService!.isGroupNameExists(teacherId, groupName);
      } else {
        return await _groupService!.isGroupNameExists(teacherId, groupName);
      }
    } catch (e) {
      return false;
    }
  }

  /// Обновление группы из Firestore
  Future<void> refreshGroup(String groupId) async {
    try {
      final group = kIsWeb
          ? await _webGroupService!.getGroup(groupId)
          : await _groupService!.getGroup(groupId);
      if (group != null) {
        final index = _groups.indexWhere((g) => g.id == groupId);
        if (index != -1) {
          _groups[index] = group;
          notifyListeners();
        }
      }
    } catch (e) {
      _setError('Ошибка обновления группы: $e');
    }
  }

  /// Очистка данных
  void clear() {
    _groups.clear();
    _clearError();
    _setSearchQuery(null);
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

  /// Получение групп с сортировкой
  List<GroupModel> getSortedGroups(GroupSortType sortType) {
    final sortedGroups = List<GroupModel>.from(_groups);
    
    switch (sortType) {
      case GroupSortType.nameAsc:
        sortedGroups.sort((a, b) => a.name.compareTo(b.name));
        break;
      case GroupSortType.nameDesc:
        sortedGroups.sort((a, b) => b.name.compareTo(a.name));
        break;
      case GroupSortType.courseAsc:
        sortedGroups.sort((a, b) => a.course.compareTo(b.course));
        break;
      case GroupSortType.courseDesc:
        sortedGroups.sort((a, b) => b.course.compareTo(a.course));
        break;
      case GroupSortType.yearAsc:
        sortedGroups.sort((a, b) => a.year.compareTo(b.year));
        break;
      case GroupSortType.yearDesc:
        sortedGroups.sort((a, b) => b.year.compareTo(a.year));
        break;
      case GroupSortType.createdAsc:
        sortedGroups.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case GroupSortType.createdDesc:
        sortedGroups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case GroupSortType.studentsAsc:
        sortedGroups.sort((a, b) => a.studentCount.compareTo(b.studentCount));
        break;
      case GroupSortType.studentsDesc:
        sortedGroups.sort((a, b) => b.studentCount.compareTo(a.studentCount));
        break;
    }
    
    return sortedGroups;
  }
}

/// Типы сортировки групп
enum GroupSortType {
  nameAsc('По названию (А-Я)'),
  nameDesc('По названию (Я-А)'),
  courseAsc('По курсу (А-Я)'),
  courseDesc('По курсу (Я-А)'),
  yearAsc('По году (1-4)'),
  yearDesc('По году (4-1)'),
  createdAsc('По дате создания (старые)'),
  createdDesc('По дате создания (новые)'),
  studentsAsc('По количеству студентов (меньше)'),
  studentsDesc('По количеству студентов (больше)');

  const GroupSortType(this.displayName);
  final String displayName;
}