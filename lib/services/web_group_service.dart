import 'package:flutter/foundation.dart';
import '../models/group_model.dart';
import 'api_service.dart';

/// Веб-сервис для работы с группами через REST API
class WebGroupService {
  final ApiService _apiService = ApiService();

  /// Создание новой группы
  Future<String> createGroup(GroupModel group) async {
    try {
      final response = await _apiService.post('/groups', group.toJson());
      return response['id'] ?? '';
    } catch (e) {
      debugPrint('Ошибка создания группы: $e');
      throw Exception('Ошибка создания группы: $e');
    }
  }

  /// Получение группы по ID
  Future<GroupModel?> getGroup(String groupId) async {
    try {
      final response = await _apiService.get('/groups/$groupId');
      return GroupModel.fromMap(response);
    } catch (e) {
      debugPrint('Ошибка получения группы: $e');
      return null;
    }
  }

  /// Получение всех групп преподавателя
  Future<List<GroupModel>> getTeacherGroups(String teacherId) async {
    try {
      final response = await _apiService.get('/groups/teacher/$teacherId');
      final List<dynamic> groupsData = response['groups'] ?? [];
      return groupsData.map((data) => GroupModel.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Ошибка получения групп преподавателя: $e');
      return [];
    }
  }

  /// Получение группы студента
  Future<GroupModel?> getStudentGroup(String studentId) async {
    try {
      final response = await _apiService.get('/groups/student/$studentId');
      if (response['group'] != null) {
        return GroupModel.fromMap(response['group']);
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка получения группы студента: $e');
      return null;
    }
  }

  /// Обновление группы
  Future<void> updateGroup(GroupModel group) async {
    try {
      await _apiService.put('/groups/${group.id}', group.toJson());
    } catch (e) {
      debugPrint('Ошибка обновления группы: $e');
      throw Exception('Ошибка обновления группы: $e');
    }
  }

  /// Удаление группы
  Future<void> deleteGroup(String groupId) async {
    try {
      await _apiService.delete('/groups/$groupId');
    } catch (e) {
      debugPrint('Ошибка удаления группы: $e');
      throw Exception('Ошибка удаления группы: $e');
    }
  }

  /// Добавление студента в группу
  Future<void> addStudentToGroup(String groupId, String studentId) async {
    try {
      await _apiService.post('/groups/$groupId/students', {
        'studentId': studentId,
      });
    } catch (e) {
      debugPrint('Ошибка добавления студента в группу: $e');
      throw Exception('Ошибка добавления студента в группу: $e');
    }
  }

  /// Удаление студента из группы
  Future<void> removeStudentFromGroup(String groupId, String studentId) async {
    try {
      await _apiService.delete('/groups/$groupId/students/$studentId');
    } catch (e) {
      debugPrint('Ошибка удаления студента из группы: $e');
      throw Exception('Ошибка удаления студента из группы: $e');
    }
  }

  /// Получение студентов группы
  Future<List<Map<String, dynamic>>> getGroupStudents(String groupId) async {
    try {
      return await _apiService.getStudentsByGroup(groupId);
    } catch (e) {
      debugPrint('Ошибка получения студентов группы: $e');
      return [];
    }
  }

  /// Поиск групп
  Future<List<GroupModel>> searchGroups(String query, String teacherId) async {
    try {
      final response = await _apiService.get('/groups/search', queryParams: {
        'q': query,
        'teacherId': teacherId,
      });
      final List<dynamic> groupsData = response['groups'] ?? [];
      return groupsData.map((data) => GroupModel.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Ошибка поиска групп: $e');
      return [];
    }
  }

  /// Проверка существования группы с таким названием
  Future<bool> isGroupNameExists(String teacherId, String groupName) async {
    try {
      final response = await _apiService.get('/groups/check-name', queryParams: {
        'teacherId': teacherId,
        'name': groupName,
      });
      return response['exists'] ?? false;
    } catch (e) {
      // Если группа не найдена, это нормально - значит имя свободно
      if (e.toString().contains('Group not found') || e.toString().contains('not found')) {
        return false;
      }
      debugPrint('Ошибка проверки названия группы: $e');
      return false;
    }
  }

  /// Получение статистики группы
  Future<Map<String, dynamic>> getGroupStats(String groupId) async {
    try {
      final response = await _apiService.get('/groups/$groupId/stats');
      return response;
    } catch (e) {
      debugPrint('Ошибка получения статистики группы: $e');
      return {};
    }
  }
}
