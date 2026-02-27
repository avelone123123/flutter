import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../models/lesson_model.dart';
import 'qr_service.dart';
import 'api_service.dart';

/// Сервис для работы с занятиями
class LessonService {
  static final LessonService _instance = LessonService._internal();
  factory LessonService() => _instance;
  LessonService._internal();

  FirebaseFirestore get _firestore {
    if (kIsWeb) {
      throw Exception('Firestore is not supported on Web. Use ApiService instead.');
    }
    return FirebaseFirestore.instance;
  }
  
  final Uuid _uuid = const Uuid();
  final QRService _qrService = QRService();

  /// Создание нового занятия
  Future<String> createLesson(LessonModel lesson) async {
    try {
      final lessonId = _uuid.v4();
      
      // Генерируем QR-код для занятия
      final qrCode = _qrService.generateLessonQR(lessonId);
      
      // Устанавливаем время действия QR-кода
      final now = DateTime.now();
      final qrValidFrom = now.subtract(const Duration(minutes: 10));
      final qrValidUntil = now.add(const Duration(hours: 2, minutes: 10));
      
      final lessonWithId = lesson.copyWith(
        id: lessonId,
        qrCode: qrCode,
        qrValidFrom: qrValidFrom,
        qrValidUntil: qrValidUntil,
      );
      
      await _firestore
          .collection('lessons')
          .doc(lessonId)
          .set(lessonWithId.toMap());
      
      return lessonId;
    } catch (e) {
      throw Exception('Ошибка создания занятия: $e');
    }
  }

  /// Получение занятия по ID
  Future<LessonModel?> getLesson(String lessonId) async {
    try {
      final doc = await _firestore
          .collection('lessons')
          .doc(lessonId)
          .get();
      
      if (doc.exists) {
        return LessonModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения занятия: $e');
    }
  }

  /// Получение всех занятий преподавателя
  Future<List<LessonModel>> getTeacherLessons(String teacherId) async {
    try {
      final querySnapshot = await _firestore
          .collection('lessons')
          .where('teacherId', isEqualTo: teacherId)
          .orderBy('date', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => LessonModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения занятий преподавателя: $e');
    }
  }

  /// Получение активных занятий преподавателя
  Future<List<LessonModel>> getActiveLessons(String teacherId) async {
    try {
      if (kIsWeb) {
        final apiService = ApiService();
        final rawLessons = await apiService.getActiveLessons();
        return rawLessons.map((e) {
          final now = DateTime.now();
          final date = e['date'] != null ? DateTime.parse(e['date']) : now;
          return LessonModel(
            id: e['id'] ?? '',
            groupId: e['groupId'] ?? '',
            groupName: e['group']?['name'] ?? 'Группа',
            subject: e['title'] ?? 'Занятие',
            type: LessonType.lecture,
            date: date,
            startTime: '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
            endTime: '${date.add(Duration(minutes: e['duration'] ?? 90)).hour.toString().padLeft(2, '0')}:${date.add(Duration(minutes: e['duration'] ?? 90)).minute.toString().padLeft(2, '0')}',
            classroom: 'Аудитория',
            teacherId: e['teacherId'] ?? teacherId,
            qrCode: e['qrCode'] ?? '',
            qrValidFrom: now.subtract(const Duration(hours: 1)),
            qrValidUntil: now.add(const Duration(hours: 2)),
            createdAt: e['createdAt'] != null ? DateTime.parse(e['createdAt']) : now,
            attendanceMarked: (e['attendance'] as List?)?.map((a) => a['studentId'].toString()).toList() ?? [],
            isActive: e['isActive'] ?? true,
          );
        }).toList();
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final querySnapshot = await _firestore
          .collection('lessons')
          .where('teacherId', isEqualTo: teacherId)
          .where('isActive', isEqualTo: true)
          .where('date', isGreaterThanOrEqualTo: today)
          .orderBy('date')
          .orderBy('startTime')
          .get();
      
      return querySnapshot.docs
          .map((doc) => LessonModel.fromFirestore(doc))
          .where((lesson) => lesson.isCurrentlyActive)
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения активных занятий: $e');
    }
  }

  /// Получение занятий группы
  Future<List<LessonModel>> getGroupLessons(String groupId) async {
    try {
      final querySnapshot = await _firestore
          .collection('lessons')
          .where('groupId', isEqualTo: groupId)
          .orderBy('date', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => LessonModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения занятий группы: $e');
    }
  }

  /// Получение занятий студента
  Future<List<LessonModel>> getStudentLessons(String studentId) async {
    try {
      // Сначала получаем группу студента
      final groupQuery = await _firestore
          .collection('groups')
          .where('studentIds', arrayContains: studentId)
          .limit(1)
          .get();
      
      if (groupQuery.docs.isEmpty) {
        return [];
      }
      
      final groupId = groupQuery.docs.first.id;
      return await getGroupLessons(groupId);
    } catch (e) {
      throw Exception('Ошибка получения занятий студента: $e');
    }
  }

  /// Обновление занятия
  Future<void> updateLesson(LessonModel lesson) async {
    try {
      await _firestore
          .collection('lessons')
          .doc(lesson.id)
          .update(lesson.toMap());
    } catch (e) {
      throw Exception('Ошибка обновления занятия: $e');
    }
  }

  /// Удаление занятия
  Future<void> deleteLesson(String lessonId) async {
    try {
      await _firestore
          .collection('lessons')
          .doc(lessonId)
          .delete();
    } catch (e) {
      throw Exception('Ошибка удаления занятия: $e');
    }
  }

  /// Отметка посещаемости студента
  Future<void> markStudentAttendance(String lessonId, String studentId) async {
    try {
      final lesson = await getLesson(lessonId);
      if (lesson == null) {
        throw Exception('Занятие не найдено');
      }
      
      if (!lesson.isCurrentlyActive) {
        throw Exception('QR-код занятия недействителен');
      }
      
      if (lesson.isStudentMarked(studentId)) {
        throw Exception('Студент уже отмечен на этом занятии');
      }
      
      final updatedLesson = lesson.markStudentAttendance(studentId);
      await updateLesson(updatedLesson);
    } catch (e) {
      throw Exception('Ошибка отметки посещаемости: $e');
    }
  }

  /// Обновление QR-кода занятия
  Future<void> refreshLessonQR(String lessonId) async {
    try {
      final newQrCode = _qrService.generateLessonQR(lessonId);
      
      if (kIsWeb) {
        final apiService = ApiService();
        await apiService.refreshLessonQR(lessonId, newQrCode);
        return;
      }

      final lesson = await getLesson(lessonId);
      if (lesson == null) {
        throw Exception('Занятие не найдено');
      }
      
      final now = DateTime.now();
      final qrValidFrom = now.subtract(const Duration(minutes: 10));
      final qrValidUntil = now.add(const Duration(hours: 2, minutes: 10));
      
      final updatedLesson = lesson.copyWith(
        qrCode: newQrCode,
        qrValidFrom: qrValidFrom,
        qrValidUntil: qrValidUntil,
      );
      
      await updateLesson(updatedLesson);
    } catch (e) {
      throw Exception('Ошибка обновления QR-кода: $e');
    }
  }

  /// Завершение занятия
  Future<void> endLesson(String lessonId) async {
    try {
      if (kIsWeb) {
        final apiService = ApiService();
        await apiService.endLesson(lessonId);
        return;
      }

      final lesson = await getLesson(lessonId);
      if (lesson == null) {
        throw Exception('Занятие не найдено');
      }
      
      final updatedLesson = lesson.copyWith(isActive: false);
      await updateLesson(updatedLesson);
    } catch (e) {
      throw Exception('Ошибка завершения занятия: $e');
    }
  }

  /// Получение занятий за период
  Future<List<LessonModel>> getLessonsByDateRange(
    String teacherId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('lessons')
          .where('teacherId', isEqualTo: teacherId)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .orderBy('date')
          .orderBy('startTime')
          .get();
      
      return querySnapshot.docs
          .map((doc) => LessonModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения занятий за период: $e');
    }
  }

  /// Получение занятий по предмету
  Future<List<LessonModel>> getLessonsBySubject(String teacherId, String subject) async {
    try {
      final querySnapshot = await _firestore
          .collection('lessons')
          .where('teacherId', isEqualTo: teacherId)
          .where('subject', isEqualTo: subject)
          .orderBy('date', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => LessonModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения занятий по предмету: $e');
    }
  }

  /// Получение статистики занятий
  Future<Map<String, dynamic>> getLessonStats(String lessonId) async {
    try {
      final lesson = await getLesson(lessonId);
      if (lesson == null) {
        throw Exception('Занятие не найдено');
      }

      // Получаем группу для подсчёта общего количества студентов
      final groupQuery = await _firestore
          .collection('groups')
          .doc(lesson.groupId)
          .get();
      
      int totalStudents = 0;
      if (groupQuery.exists) {
        final groupData = groupQuery.data()!;
        totalStudents = (groupData['studentIds'] as List).length;
      }

      final attendancePercentage = lesson.getAttendancePercentage(totalStudents);
      final timeUntilExpires = lesson.timeUntilQrExpires;

      return {
        'lessonId': lessonId,
        'subject': lesson.subject,
        'groupName': lesson.groupName,
        'date': lesson.date,
        'timeRange': lesson.timeRange,
        'totalStudents': totalStudents,
        'markedStudents': lesson.attendanceMarked.length,
        'attendancePercentage': attendancePercentage,
        'isActive': lesson.isCurrentlyActive,
        'isQrExpired': lesson.isQrExpired,
        'timeUntilExpires': timeUntilExpires.inMinutes,
        'qrCode': lesson.qrCode,
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики занятия: $e');
    }
  }

  /// Поиск занятий
  Future<List<LessonModel>> searchLessons(String teacherId, String query) async {
    try {
      final querySnapshot = await _firestore
          .collection('lessons')
          .where('teacherId', isEqualTo: teacherId)
          .where('subject', isGreaterThanOrEqualTo: query)
          .where('subject', isLessThan: query + 'z')
          .orderBy('subject')
          .get();
      
      return querySnapshot.docs
          .map((doc) => LessonModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Ошибка поиска занятий: $e');
    }
  }

  /// Получение занятий на сегодня
  Future<List<LessonModel>> getTodayLessons(String teacherId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      
      return await getLessonsByDateRange(teacherId, today, tomorrow);
    } catch (e) {
      throw Exception('Ошибка получения занятий на сегодня: $e');
    }
  }

  /// Получение занятий на завтра
  Future<List<LessonModel>> getTomorrowLessons(String teacherId) async {
    try {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final dayAfterTomorrow = tomorrow.add(const Duration(days: 1));
      
      return await getLessonsByDateRange(teacherId, tomorrow, dayAfterTomorrow);
    } catch (e) {
      throw Exception('Ошибка получения занятий на завтра: $e');
    }
  }
}
