import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

/// Сервис для работы с облачной базой данных Firestore
/// Отвечает за все операции с данными в Firebase
class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Коллекции в Firestore
  static const String _usersCollection = 'users';
  static const String _studentsCollection = 'students';
  static const String _groupsCollection = 'groups';
  static const String _lessonsCollection = 'lessons';
  static const String _attendanceCollection = 'attendance';

  // ========== ОПЕРАЦИИ С ГРУППАМИ ==========

  /// Создание новой группы
  /// [group] - данные группы
  Future<String> createGroup(Group group) async {
    try {
      final docRef = await _firestore
          .collection(_groupsCollection)
          .add(group.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания группы: $e');
    }
  }

  /// Получение всех групп преподавателя
  /// [teacherId] - идентификатор преподавателя
  Future<List<Group>> getGroupsByTeacher(String teacherId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_groupsCollection)
          .where('teacherId', isEqualTo: teacherId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Group.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения групп: $e');
    }
  }

  /// Получение группы по ID
  /// [groupId] - идентификатор группы
  Future<Group?> getGroupById(String groupId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_groupsCollection)
          .doc(groupId)
          .get();

      if (doc.exists) {
        return Group.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения группы: $e');
    }
  }

  /// Обновление группы
  /// [groupId] - идентификатор группы
  /// [group] - новые данные группы
  Future<void> updateGroup(String groupId, Group group) async {
    try {
      await _firestore
          .collection(_groupsCollection)
          .doc(groupId)
          .update(group.toJson());
    } catch (e) {
      throw Exception('Ошибка обновления группы: $e');
    }
  }

  /// Удаление группы
  /// [groupId] - идентификатор группы
  Future<void> deleteGroup(String groupId) async {
    try {
      await _firestore
          .collection(_groupsCollection)
          .doc(groupId)
          .update({'isActive': false});
    } catch (e) {
      throw Exception('Ошибка удаления группы: $e');
    }
  }

  // ========== ОПЕРАЦИИ СО СТУДЕНТАМИ ==========

  /// Добавление студента в группу
  /// [student] - данные студента
  Future<String> addStudent(Student student) async {
    try {
      final docRef = await _firestore
          .collection(_studentsCollection)
          .add(student.toJson());
      
      // Добавляем студента в группу
      await _firestore
          .collection(_groupsCollection)
          .doc(student.groupId)
          .update({
        'studentIds': FieldValue.arrayUnion([docRef.id]),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка добавления студента: $e');
    }
  }

  /// Получение всех студентов группы
  /// [groupId] - идентификатор группы
  Future<List<Student>> getStudentsByGroup(String groupId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_studentsCollection)
          .where('groupId', isEqualTo: groupId)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => Student.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения студентов: $e');
    }
  }

  /// Получение студента по ID
  /// [studentId] - идентификатор студента
  Future<Student?> getStudentById(String studentId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_studentsCollection)
          .doc(studentId)
          .get();

      if (doc.exists) {
        return Student.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения студента: $e');
    }
  }

  /// Обновление данных студента
  /// [studentId] - идентификатор студента
  /// [student] - новые данные студента
  Future<void> updateStudent(String studentId, Student student) async {
    try {
      await _firestore
          .collection(_studentsCollection)
          .doc(studentId)
          .update(student.toJson());
    } catch (e) {
      throw Exception('Ошибка обновления студента: $e');
    }
  }

  /// Удаление студента из группы
  /// [studentId] - идентификатор студента
  /// [groupId] - идентификатор группы
  Future<void> removeStudentFromGroup(String studentId, String groupId) async {
    try {
      // Помечаем студента как неактивного
      await _firestore
          .collection(_studentsCollection)
          .doc(studentId)
          .update({'isActive': false});

      // Удаляем из группы
      await _firestore
          .collection(_groupsCollection)
          .doc(groupId)
          .update({
        'studentIds': FieldValue.arrayRemove([studentId]),
      });
    } catch (e) {
      throw Exception('Ошибка удаления студента: $e');
    }
  }

  // ========== ОПЕРАЦИИ С ЗАНЯТИЯМИ ==========

  /// Создание нового занятия
  /// [lesson] - данные занятия
  Future<String> createLesson(Lesson lesson) async {
    try {
      final docRef = await _firestore
          .collection(_lessonsCollection)
          .add(lesson.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания занятия: $e');
    }
  }

  /// Получение занятий группы
  /// [groupId] - идентификатор группы
  /// [startDate] - начальная дата (опционально)
  /// [endDate] - конечная дата (опционально)
  Future<List<Lesson>> getLessonsByGroup(
    String groupId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection(_lessonsCollection)
          .where('groupId', isEqualTo: groupId)
          .orderBy('date', descending: true);

      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: endDate);
      }

      final QuerySnapshot snapshot = await query.get();

      return snapshot.docs
          .map((doc) => Lesson.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения занятий: $e');
    }
  }

  /// Получение занятия по ID
  /// [lessonId] - идентификатор занятия
  Future<Lesson?> getLessonById(String lessonId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_lessonsCollection)
          .doc(lessonId)
          .get();

      if (doc.exists) {
        return Lesson.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения занятия: $e');
    }
  }

  /// Обновление занятия
  /// [lessonId] - идентификатор занятия
  /// [lesson] - новые данные занятия
  Future<void> updateLesson(String lessonId, Lesson lesson) async {
    try {
      await _firestore
          .collection(_lessonsCollection)
          .doc(lessonId)
          .update(lesson.toJson());
    } catch (e) {
      throw Exception('Ошибка обновления занятия: $e');
    }
  }

  /// Удаление занятия
  /// [lessonId] - идентификатор занятия
  Future<void> deleteLesson(String lessonId) async {
    try {
      await _firestore
          .collection(_lessonsCollection)
          .doc(lessonId)
          .delete();
    } catch (e) {
      throw Exception('Ошибка удаления занятия: $e');
    }
  }

  // ========== ОПЕРАЦИИ С ПОСЕЩАЕМОСТЬЮ ==========

  /// Отметка посещаемости
  /// [attendance] - данные посещаемости
  Future<String> markAttendanceModel(AttendanceModel attendance) async {
    try {
      final docRef = await _firestore
          .collection(_attendanceCollection)
          .add(attendance.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка отметки посещаемости: $e');
    }
  }

  /// Получение посещаемости занятия
  /// [lessonId] - идентификатор занятия
  Future<List<AttendanceModel>> getAttendanceModelByLesson(String lessonId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_attendanceCollection)
          .where('lessonId', isEqualTo: lessonId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AttendanceModel.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения посещаемости: $e');
    }
  }

  /// Получение посещаемости студента
  /// [studentId] - идентификатор студента
  /// [startDate] - начальная дата (опционально)
  /// [endDate] - конечная дата (опционально)
  Future<List<AttendanceModel>> getAttendanceModelByStudent(
    String studentId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection(_attendanceCollection)
          .where('studentId', isEqualTo: studentId)
          .orderBy('timestamp', descending: true);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      final QuerySnapshot snapshot = await query.get();

      return snapshot.docs
          .map((doc) => AttendanceModel.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения посещаемости студента: $e');
    }
  }

  /// Обновление посещаемости
  /// [attendanceId] - идентификатор записи посещаемости
  /// [attendance] - новые данные посещаемости
  Future<void> updateAttendanceModel(String attendanceId, AttendanceModel attendance) async {
    try {
      await _firestore
          .collection(_attendanceCollection)
          .doc(attendanceId)
          .update(attendance.toJson());
    } catch (e) {
      throw Exception('Ошибка обновления посещаемости: $e');
    }
  }

  /// Получение статистики посещаемости группы
  /// [groupId] - идентификатор группы
  /// [startDate] - начальная дата
  /// [endDate] - конечная дата
  Future<Map<String, dynamic>> getGroupAttendanceModelStats(
    String groupId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Получаем все занятия группы за период
      final lessons = await getLessonsByGroup(
        groupId,
        startDate: startDate,
        endDate: endDate,
      );

      // Получаем всех студентов группы
      final students = await getStudentsByGroup(groupId);

      // Получаем посещаемость для каждого занятия
      final Map<String, List<AttendanceModel>> attendanceByLesson = {};
      for (final lesson in lessons) {
        attendanceByLesson[lesson.id] = await getAttendanceModelByLesson(lesson.id);
      }

      // Подсчитываем статистику
      int totalLessons = lessons.length;
      int totalPossibleAttendanceModel = students.length * totalLessons;
      int totalPresent = 0;
      int totalAbsent = 0;
      int totalLate = 0;
      int totalExcused = 0;

      final Map<String, Map<String, int>> studentStats = {};

      for (final student in students) {
        studentStats[student.id] = {
          'present': 0,
          'absent': 0,
          'late': 0,
          'excused': 0,
        };
      }

      for (final lesson in lessons) {
        final attendance = attendanceByLesson[lesson.id] ?? [];
        final attendanceMap = {
          for (final att in attendance) att.studentId: att
        };

        for (final student in students) {
          final att = attendanceMap[student.id];
          if (att != null) {
            switch (att.status) {
              case AttendanceStatus.present:
                totalPresent++;
                studentStats[student.id]!['present'] = 
                    studentStats[student.id]!['present']! + 1;
                break;
              case AttendanceStatus.absent:
                totalAbsent++;
                studentStats[student.id]!['absent'] = 
                    studentStats[student.id]!['absent']! + 1;
                break;
              case AttendanceStatus.late:
                totalLate++;
                studentStats[student.id]!['late'] = 
                    studentStats[student.id]!['late']! + 1;
                break;
              case AttendanceStatus.excused:
                totalExcused++;
                studentStats[student.id]!['excused'] = 
                    studentStats[student.id]!['excused']! + 1;
                break;
            }
          } else {
            totalAbsent++;
            studentStats[student.id]!['absent'] = 
                studentStats[student.id]!['absent']! + 1;
          }
        }
      }

      return {
        'totalLessons': totalLessons,
        'totalStudents': students.length,
        'totalPossibleAttendanceModel': totalPossibleAttendanceModel,
        'totalPresent': totalPresent,
        'totalAbsent': totalAbsent,
        'totalLate': totalLate,
        'totalExcused': totalExcused,
        'attendanceRate': totalPossibleAttendanceModel > 0 
            ? (totalPresent / totalPossibleAttendanceModel * 100).round()
            : 0,
        'studentStats': studentStats,
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики: $e');
    }
  }
}
