import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/group_model.dart';

/// Сервис для работы с группами студентов
class GroupService {
  static final GroupService _instance = GroupService._internal();
  factory GroupService() => _instance;
  GroupService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Создание новой группы
  Future<String> createGroup(GroupModel group) async {
    try {
      final groupId = _uuid.v4();
      final groupWithId = group.copyWith(id: groupId);
      
      await _firestore
          .collection('groups')
          .doc(groupId)
          .set(groupWithId.toMap());
      
      return groupId;
    } catch (e) {
      throw Exception('Ошибка создания группы: $e');
    }
  }

  /// Получение группы по ID
  Future<GroupModel?> getGroup(String groupId) async {
    try {
      final doc = await _firestore
          .collection('groups')
          .doc(groupId)
          .get();
      
      if (doc.exists) {
        return GroupModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения группы: $e');
    }
  }

  /// Получение всех групп преподавателя
  Future<List<GroupModel>> getTeacherGroups(String teacherId) async {
    try {
      final querySnapshot = await _firestore
          .collection('groups')
          .where('teacherId', isEqualTo: teacherId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => GroupModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения групп преподавателя: $e');
    }
  }

  /// Получение группы студента
  Future<GroupModel?> getStudentGroup(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('groups')
          .where('studentIds', arrayContains: studentId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return GroupModel.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения группы студента: $e');
    }
  }

  /// Обновление группы
  Future<void> updateGroup(GroupModel group) async {
    try {
      final updatedGroup = group.copyWith(updatedAt: DateTime.now());
      
      await _firestore
          .collection('groups')
          .doc(group.id)
          .update(updatedGroup.toMap());
    } catch (e) {
      throw Exception('Ошибка обновления группы: $e');
    }
  }

  /// Удаление группы
  Future<void> deleteGroup(String groupId) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .delete();
    } catch (e) {
      throw Exception('Ошибка удаления группы: $e');
    }
  }

  /// Добавление студента в группу
  Future<void> addStudentToGroup(String groupId, String studentId) async {
    try {
      final group = await getGroup(groupId);
      if (group == null) {
        throw Exception('Группа не найдена');
      }
      
      final updatedGroup = group.addStudent(studentId);
      await updateGroup(updatedGroup);
    } catch (e) {
      throw Exception('Ошибка добавления студента в группу: $e');
    }
  }

  /// Удаление студента из группы
  Future<void> removeStudentFromGroup(String groupId, String studentId) async {
    try {
      final group = await getGroup(groupId);
      if (group == null) {
        throw Exception('Группа не найдена');
      }
      
      final updatedGroup = group.removeStudent(studentId);
      await updateGroup(updatedGroup);
    } catch (e) {
      throw Exception('Ошибка удаления студента из группы: $e');
    }
  }

  /// Поиск групп по названию
  Future<List<GroupModel>> searchGroups(String teacherId, String query) async {
    try {
      final querySnapshot = await _firestore
          .collection('groups')
          .where('teacherId', isEqualTo: teacherId)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .orderBy('name')
          .get();
      
      return querySnapshot.docs
          .map((doc) => GroupModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Ошибка поиска групп: $e');
    }
  }

  /// Получение статистики группы
  Future<Map<String, dynamic>> getGroupStats(String groupId) async {
    try {
      final group = await getGroup(groupId);
      if (group == null) {
        throw Exception('Группа не найдена');
      }

      // Получаем количество занятий для группы
      final lessonsSnapshot = await _firestore
          .collection('lessons')
          .where('groupId', isEqualTo: groupId)
          .get();

      // Получаем записи посещаемости для группы
      final attendanceSnapshot = await _firestore
          .collection('attendance')
          .where('groupId', isEqualTo: groupId)
          .get();

      final totalLessons = lessonsSnapshot.docs.length;
      final totalAttendanceRecords = attendanceSnapshot.docs.length;
      final averageAttendance = totalLessons > 0 
          ? (totalAttendanceRecords / (totalLessons * group.studentCount)) * 100 
          : 0.0;

      return {
        'groupId': groupId,
        'groupName': group.name,
        'studentCount': group.studentCount,
        'totalLessons': totalLessons,
        'totalAttendanceRecords': totalAttendanceRecords,
        'averageAttendance': averageAttendance,
        'createdAt': group.createdAt,
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики группы: $e');
    }
  }

  /// Получение списка студентов группы
  Future<List<Map<String, dynamic>>> getGroupStudents(String groupId) async {
    try {
      final group = await getGroup(groupId);
      if (group == null) {
        throw Exception('Группа не найдена');
      }

      final students = <Map<String, dynamic>>[];
      
      for (final studentId in group.studentIds) {
        try {
          final studentDoc = await _firestore
              .collection('users')
              .doc(studentId)
              .get();
          
          if (studentDoc.exists) {
            final studentData = studentDoc.data()!;
            students.add({
              'id': studentId,
              'name': studentData['name'] ?? '',
              'email': studentData['email'] ?? '',
              'photoUrl': studentData['photoUrl'],
              'lastName': studentData['lastName'],
              'middleName': studentData['middleName'],
            });
          }
        } catch (e) {
          // Пропускаем студентов, которые не найдены
          continue;
        }
      }
      
      return students;
    } catch (e) {
      throw Exception('Ошибка получения студентов группы: $e');
    }
  }

  /// Проверка, существует ли группа с таким названием у преподавателя
  Future<bool> isGroupNameExists(String teacherId, String groupName) async {
    try {
      final querySnapshot = await _firestore
          .collection('groups')
          .where('teacherId', isEqualTo: teacherId)
          .where('name', isEqualTo: groupName)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Ошибка проверки существования группы: $e');
    }
  }

  /// Получение групп с фильтрацией по курсу
  Future<List<GroupModel>> getGroupsByCourse(String teacherId, String course) async {
    try {
      final querySnapshot = await _firestore
          .collection('groups')
          .where('teacherId', isEqualTo: teacherId)
          .where('course', isEqualTo: course)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => GroupModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения групп по курсу: $e');
    }
  }

  /// Получение групп с фильтрацией по году обучения
  Future<List<GroupModel>> getGroupsByYear(String teacherId, int year) async {
    try {
      final querySnapshot = await _firestore
          .collection('groups')
          .where('teacherId', isEqualTo: teacherId)
          .where('year', isEqualTo: year)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => GroupModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения групп по году: $e');
    }
  }
}
