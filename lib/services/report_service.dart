import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'group_service.dart';
import 'lesson_service.dart';

/// Сервис для генерации отчётов и статистики
class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GroupService _groupService = GroupService();
  final LessonService _lessonService = LessonService();

  /// Получение статистики посещаемости группы
  Future<Map<String, dynamic>> getGroupAttendanceStats(String groupId) async {
    try {
      final group = await _groupService.getGroup(groupId);
      if (group == null) {
        throw Exception('Группа не найдена');
      }

      // Получаем все занятия группы
      final lessons = await _lessonService.getGroupLessons(groupId);
      
      // Получаем записи посещаемости
      final attendanceSnapshot = await _firestore
          .collection('attendance')
          .where('groupId', isEqualTo: groupId)
          .get();

      final attendanceRecords = attendanceSnapshot.docs
          .map((doc) => AttendanceModel.fromFirestore(doc))
          .toList();

      // Группируем по студентам
      final Map<String, List<AttendanceModel>> studentAttendance = {};
      for (final record in attendanceRecords) {
        if (!studentAttendance.containsKey(record.studentId)) {
          studentAttendance[record.studentId] = [];
        }
        studentAttendance[record.studentId]!.add(record);
      }

      // Создаём статистику для каждого студента
      final List<AttendanceStats> studentStats = [];
      for (final studentId in group.studentIds) {
        final studentRecords = studentAttendance[studentId] ?? [];
        final studentName = await _getStudentName(studentId);
        
        final stats = AttendanceStats.fromAttendanceList(
          studentId,
          studentName,
          studentRecords,
        );
        studentStats.add(stats);
      }

      // Сортируем по проценту посещаемости
      studentStats.sort((a, b) => b.attendancePercentage.compareTo(a.attendancePercentage));

      // Общая статистика группы
      final totalLessons = lessons.length;
      final totalAttendanceRecords = attendanceRecords.length;
      final averageAttendance = totalLessons > 0 
          ? (totalAttendanceRecords / (totalLessons * group.studentCount)) * 100 
          : 0.0;

      return {
        'groupId': groupId,
        'groupName': group.name,
        'course': group.course,
        'year': group.year,
        'studentCount': group.studentCount,
        'totalLessons': totalLessons,
        'averageAttendance': averageAttendance,
        'studentStats': studentStats.map((s) => s.toJson()).toList(),
        'createdAt': group.createdAt,
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики группы: $e');
    }
  }

  /// Получение статистики по предметам
  Future<List<Map<String, dynamic>>> getSubjectStats(String teacherId) async {
    try {
      final lessons = await _lessonService.getTeacherLessons(teacherId);
      
      // Группируем занятия по предметам
      final Map<String, List<LessonModel>> subjectLessons = {};
      for (final lesson in lessons) {
        if (!subjectLessons.containsKey(lesson.subject)) {
          subjectLessons[lesson.subject] = [];
        }
        subjectLessons[lesson.subject]!.add(lesson);
      }

      final List<Map<String, dynamic>> subjectStats = [];
      
      for (final entry in subjectLessons.entries) {
        final subject = entry.key;
        final subjectLessonsList = entry.value;
        
        // Получаем записи посещаемости для этого предмета
        final lessonIds = subjectLessonsList.map((l) => l.id).toList();
        final attendanceSnapshot = await _firestore
            .collection('attendance')
            .where('lessonId', whereIn: lessonIds)
            .get();

        final attendanceRecords = attendanceSnapshot.docs
            .map((doc) => AttendanceModel.fromFirestore(doc))
            .toList();

        // Подсчитываем статистику
        final totalLessons = subjectLessonsList.length;
        final totalAttendanceRecords = attendanceRecords.length;
        final presentCount = attendanceRecords.where((r) => r.isPresent).length;
        final averageAttendance = totalAttendanceRecords > 0 
            ? (presentCount / totalAttendanceRecords) * 100 
            : 0.0;

        // Получаем уникальные группы
        final groups = subjectLessonsList.map((l) => l.groupName).toSet().toList();

        subjectStats.add({
          'subject': subject,
          'totalLessons': totalLessons,
          'totalAttendanceRecords': totalAttendanceRecords,
          'presentCount': presentCount,
          'averageAttendance': averageAttendance,
          'groups': groups,
          'lastLessonDate': subjectLessonsList.isNotEmpty 
              ? subjectLessonsList.map((l) => l.date).reduce((a, b) => a.isAfter(b) ? a : b)
              : null,
        });
      }

      // Сортируем по среднему проценту посещаемости
      subjectStats.sort((a, b) => b['averageAttendance'].compareTo(a['averageAttendance']));

      return subjectStats;
    } catch (e) {
      throw Exception('Ошибка получения статистики по предметам: $e');
    }
  }

  /// Получение детальной статистики за период
  Future<Map<String, dynamic>> getDetailedStats(
    String teacherId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Получаем занятия за период
      final lessons = await _lessonService.getLessonsByDateRange(
        teacherId,
        startDate,
        endDate,
      );

      // Получаем все записи посещаемости за период
      final attendanceSnapshot = await _firestore
          .collection('attendance')
          .where('teacherId', isEqualTo: teacherId)
          .where('markedAt', isGreaterThanOrEqualTo: startDate)
          .where('markedAt', isLessThanOrEqualTo: endDate)
          .get();

      final attendanceRecords = attendanceSnapshot.docs
          .map((doc) => AttendanceModel.fromFirestore(doc))
          .toList();

      // Получаем все группы преподавателя
      final groups = await _groupService.getTeacherGroups(teacherId);

      // Подсчитываем общую статистику
      final totalLessons = lessons.length;
      final totalAttendanceRecords = attendanceRecords.length;
      final presentCount = attendanceRecords.where((r) => r.isPresent).length;
      final averageAttendance = totalAttendanceRecords > 0 
          ? (presentCount / totalAttendanceRecords) * 100 
          : 0.0;

      // Статистика по группам
      final Map<String, Map<String, dynamic>> groupStats = {};
      for (final group in groups) {
        final groupLessons = lessons.where((l) => l.groupId == group.id).toList();
        final groupAttendance = attendanceRecords.where((r) => r.groupId == group.id).toList();
        final groupPresentCount = groupAttendance.where((r) => r.isPresent).length;
        final groupAverageAttendance = groupAttendance.isNotEmpty 
            ? (groupPresentCount / groupAttendance.length) * 100 
            : 0.0;

        groupStats[group.id] = {
          'groupName': group.name,
          'studentCount': group.studentCount,
          'totalLessons': groupLessons.length,
          'totalAttendanceRecords': groupAttendance.length,
          'averageAttendance': groupAverageAttendance,
        };
      }

      // Находим лучшую группу
      String? bestGroupId;
      double bestAttendance = 0.0;
      for (final entry in groupStats.entries) {
        if (entry.value['averageAttendance'] > bestAttendance) {
          bestAttendance = entry.value['averageAttendance'];
          bestGroupId = entry.key;
        }
      }

      // Статистика студентов
      final Map<String, List<AttendanceModel>> studentAttendance = {};
      for (final record in attendanceRecords) {
        if (!studentAttendance.containsKey(record.studentId)) {
          studentAttendance[record.studentId] = [];
        }
        studentAttendance[record.studentId]!.add(record);
      }

      final List<Map<String, dynamic>> studentStats = [];
      for (final entry in studentAttendance.entries) {
        final studentId = entry.key;
        final studentRecords = entry.value;
        final studentName = await _getStudentName(studentId);
        
        final stats = AttendanceStats.fromAttendanceList(
          studentId,
          studentName,
          studentRecords,
        );

        studentStats.add({
          'studentId': studentId,
          'studentName': studentName,
          'attendancePercentage': stats.attendancePercentage,
          'presentCount': stats.presentCount,
          'totalLessons': stats.totalLessons,
        });
      }

      // Сортируем студентов по проценту посещаемости
      studentStats.sort((a, b) => b['attendancePercentage'].compareTo(a['attendancePercentage']));

      // Студенты с отличной посещаемостью (>90%)
      final excellentStudents = studentStats.where((s) => s['attendancePercentage'] >= 90).toList();

      // Студенты с проблемами (<50%)
      final problemStudents = studentStats.where((s) => s['attendancePercentage'] < 50).toList();

      return {
        'period': {
          'startDate': startDate,
          'endDate': endDate,
        },
        'overall': {
          'totalLessons': totalLessons,
          'totalAttendanceRecords': totalAttendanceRecords,
          'averageAttendance': averageAttendance,
          'totalGroups': groups.length,
          'totalStudents': studentStats.length,
        },
        'bestGroup': bestGroupId != null ? {
          'groupId': bestGroupId,
          'groupName': groupStats[bestGroupId]!['groupName'],
          'averageAttendance': bestAttendance,
        } : null,
        'excellentStudents': excellentStudents,
        'problemStudents': problemStudents,
        'groupStats': groupStats,
        'studentStats': studentStats,
      };
    } catch (e) {
      throw Exception('Ошибка получения детальной статистики: $e');
    }
  }

  /// Получение статистики посещаемости студента
  Future<Map<String, dynamic>> getStudentAttendanceStats(String studentId) async {
    try {
      // Получаем группу студента
      final group = await _groupService.getStudentGroup(studentId);
      if (group == null) {
        throw Exception('Студент не найден в группе');
      }

      // Получаем занятия группы
      final lessons = await _lessonService.getGroupLessons(group.id);

      // Получаем записи посещаемости студента
      final attendanceSnapshot = await _firestore
          .collection('attendance')
          .where('studentId', isEqualTo: studentId)
          .orderBy('markedAt', descending: true)
          .get();

      final attendanceRecords = attendanceSnapshot.docs
          .map((doc) => AttendanceModel.fromFirestore(doc))
          .toList();

      // Создаём статистику
      final stats = AttendanceStats.fromAttendanceList(
        studentId,
        await _getStudentName(studentId),
        attendanceRecords,
      );

      // Статистика по месяцам
      final Map<String, List<AttendanceModel>> monthlyAttendance = {};
      for (final record in attendanceRecords) {
        final monthKey = '${record.markedAt.year}-${record.markedAt.month.toString().padLeft(2, '0')}';
        if (!monthlyAttendance.containsKey(monthKey)) {
          monthlyAttendance[monthKey] = [];
        }
        monthlyAttendance[monthKey]!.add(record);
      }

      final List<Map<String, dynamic>> monthlyStats = [];
      for (final entry in monthlyAttendance.entries) {
        final monthKey = entry.key;
        final monthRecords = entry.value;
        final monthStats = AttendanceStats.fromAttendanceList(
          studentId,
          stats.studentName,
          monthRecords,
        );

        monthlyStats.add({
          'month': monthKey,
          'attendancePercentage': monthStats.attendancePercentage,
          'presentCount': monthStats.presentCount,
          'totalLessons': monthStats.totalLessons,
        });
      }

      // Сортируем по месяцам
      monthlyStats.sort((a, b) => b['month'].compareTo(a['month']));

      return {
        'studentId': studentId,
        'studentName': stats.studentName,
        'groupId': group.id,
        'groupName': group.name,
        'overallStats': {
          'attendancePercentage': stats.attendancePercentage,
          'presentCount': stats.presentCount,
          'absentCount': stats.absentCount,
          'lateCount': stats.lateCount,
          'excusedCount': stats.excusedCount,
          'totalLessons': stats.totalLessons,
        },
        'monthlyStats': monthlyStats,
        'recentAttendance': attendanceRecords.take(10).map((r) => r.toJson()).toList(),
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики студента: $e');
    }
  }

  /// Получение тепловой карты посещаемости
  Future<Map<String, dynamic>> getAttendanceHeatmap(
    String teacherId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final lessons = await _lessonService.getLessonsByDateRange(
        teacherId,
        startDate,
        endDate,
      );

      final Map<String, Map<String, int>> heatmapData = {};
      
      for (final lesson in lessons) {
        final dateKey = '${lesson.date.year}-${lesson.date.month.toString().padLeft(2, '0')}-${lesson.date.day.toString().padLeft(2, '0')}';
        
        if (!heatmapData.containsKey(dateKey)) {
          heatmapData[dateKey] = {
            'total': 0,
            'present': 0,
            'absent': 0,
          };
        }

        // Получаем записи посещаемости для этого занятия
        final attendanceSnapshot = await _firestore
            .collection('attendance')
            .where('lessonId', isEqualTo: lesson.id)
            .get();

        final attendanceRecords = attendanceSnapshot.docs
            .map((doc) => AttendanceModel.fromFirestore(doc))
            .toList();

        heatmapData[dateKey]!['total'] = heatmapData[dateKey]!['total']! + attendanceRecords.length;
        heatmapData[dateKey]!['present'] = heatmapData[dateKey]!['present']! + 
            attendanceRecords.where((r) => r.isPresent).length;
        heatmapData[dateKey]!['absent'] = heatmapData[dateKey]!['absent']! + 
            attendanceRecords.where((r) => r.isAbsent).length;
      }

      return {
        'heatmapData': heatmapData,
        'startDate': startDate,
        'endDate': endDate,
      };
    } catch (e) {
      throw Exception('Ошибка получения тепловой карты: $e');
    }
  }

  /// Получение имени студента по ID
  Future<String> _getStudentName(String studentId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(studentId)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        return data['name'] ?? 'Неизвестный студент';
      }
      return 'Неизвестный студент';
    } catch (e) {
      return 'Неизвестный студент';
    }
  }
}
