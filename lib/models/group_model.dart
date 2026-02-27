import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель группы студентов
class GroupModel {
  final String id;
  final String name;
  final String course;
  final int year;
  final String? description;
  final List<String> studentIds;
  final String teacherId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const GroupModel({
    required this.id,
    required this.name,
    required this.course,
    required this.year,
    this.description,
    required this.studentIds,
    required this.teacherId,
    required this.createdAt,
    this.updatedAt,
  });

  /// Создание модели из Firestore документа
  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      course: data['course'] ?? '',
      year: data['year'] ?? 1,
      description: data['description'],
      studentIds: List<String>.from(data['studentIds'] ?? []),
      teacherId: data['teacherId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  /// Создание модели из Map
  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      course: map['course'] ?? '',
      year: map['year'] ?? 1,
      description: map['description'],
      studentIds: map.containsKey('students')
          ? (map['students'] as List).map((s) => s['id'] as String).toList()
          : List<String>.from(map['studentIds'] ?? []),
      teacherId: map['teacherId'] ?? '',
      createdAt: map['createdAt'] is DateTime 
          ? map['createdAt'] 
          : DateTime.now(),
      updatedAt: map['updatedAt'] is DateTime 
          ? map['updatedAt'] 
          : null,
    );
  }

  /// Преобразование в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'course': course,
      'year': year,
      'description': description,
      'studentIds': studentIds,
      'teacherId': teacherId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'course': course,
      'year': year,
      'description': description,
      'studentIds': studentIds,
      'teacherId': teacherId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Создание копии с изменениями
  GroupModel copyWith({
    String? id,
    String? name,
    String? course,
    int? year,
    String? description,
    List<String>? studentIds,
    String? teacherId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      course: course ?? this.course,
      year: year ?? this.year,
      description: description ?? this.description,
      studentIds: studentIds ?? this.studentIds,
      teacherId: teacherId ?? this.teacherId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Получение полного названия группы
  String get fullName => '$name ($course, $year курс)';

  /// Получение количества студентов
  int get studentCount => studentIds.length;

  /// Проверка, является ли пользователь студентом группы
  bool isStudentInGroup(String studentId) {
    return studentIds.contains(studentId);
  }

  /// Добавление студента в группу
  GroupModel addStudent(String studentId) {
    if (studentIds.contains(studentId)) {
      return this;
    }
    return copyWith(
      studentIds: [...studentIds, studentId],
      updatedAt: DateTime.now(),
    );
  }

  /// Удаление студента из группы
  GroupModel removeStudent(String studentId) {
    return copyWith(
      studentIds: studentIds.where((id) => id != studentId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'GroupModel(id: $id, name: $name, course: $course, year: $year, studentCount: $studentCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
