import 'package:flutter/foundation.dart';
import '../models/lesson_model.dart';
import 'api_service.dart';

/// Веб-сервис для работы с занятиями через REST API
class WebLessonService {
  final ApiService _apiService = ApiService();

  /// Создание нового занятия
  Future<String> createLesson(LessonModel lesson) async {
    try {
      // Auto-generate QR code if empty
      final qrCode = lesson.qrCode.isNotEmpty
          ? lesson.qrCode
          : 'lesson_${DateTime.now().millisecondsSinceEpoch}';

      final response = await _apiService.createLesson(
        groupId: lesson.groupId,
        title: lesson.subject,
        description: lesson.notes,
        date: lesson.date,
        duration: 90,
        qrCode: qrCode,
        type: lesson.type.name,
        startTime: lesson.startTime,
        endTime: lesson.endTime,
        classroom: lesson.classroom,
      );
      return response['id'] ?? '';
    } catch (e) {
      debugPrint('Ошибка создания занятия: $e');
      throw Exception('Ошибка создания занятия: $e');
    }
  }

  /// Получение занятия по ID
  Future<LessonModel?> getLesson(String lessonId) async {
    try {
      final response = await _apiService.get('/lessons/$lessonId');
      return LessonModel.fromMap(response);
    } catch (e) {
      debugPrint('Ошибка получения занятия: $e');
      return null;
    }
  }

  /// Получение всех занятий преподавателя
  Future<List<LessonModel>> getTeacherLessons(String teacherId) async {
    try {
      final response = await _apiService.get('/lessons/teacher/$teacherId');
      final List<dynamic> lessonsData = response['lessons'] ?? [];
      return lessonsData.map((data) => LessonModel.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Ошибка получения занятий преподавателя: $e');
      return [];
    }
  }

  /// Получение занятий группы
  Future<List<LessonModel>> getGroupLessons(String groupId) async {
    try {
      final response = await _apiService.get('/lessons/group/$groupId');
      final List<dynamic> lessonsData = response['lessons'] ?? [];
      return lessonsData.map((data) => LessonModel.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Ошибка получения занятий группы: $e');
      return [];
    }
  }

  /// Обновление занятия
  Future<void> updateLesson(LessonModel lesson) async {
    try {
      await _apiService.put('/lessons/${lesson.id}', lesson.toJson());
    } catch (e) {
      debugPrint('Ошибка обновления занятия: $e');
      throw Exception('Ошибка обновления занятия: $e');
    }
  }

  /// Удаление занятия
  Future<void> deleteLesson(String lessonId) async {
    try {
      await _apiService.delete('/lessons/$lessonId');
    } catch (e) {
      debugPrint('Ошибка удаления занятия: $e');
      throw Exception('Ошибка удаления занятия: $e');
    }
  }

  /// Начало занятия
  Future<void> startLesson(String lessonId) async {
    try {
      await _apiService.post('/lessons/$lessonId/start', {});
    } catch (e) {
      debugPrint('Ошибка начала занятия: $e');
      throw Exception('Ошибка начала занятия: $e');
    }
  }

  /// Окончание занятия
  Future<void> endLesson(String lessonId) async {
    try {
      await _apiService.post('/lessons/$lessonId/end', {});
    } catch (e) {
      debugPrint('Ошибка окончания занятия: $e');
      throw Exception('Ошибка окончания занятия: $e');
    }
  }
}
