import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип занятия
enum LessonType {
  lecture('Лекция'),
  practice('Практика'),
  seminar('Семинар'),
  laboratory('Лабораторная');

  const LessonType(this.displayName);
  final String displayName;

  static LessonType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'лекция':
      case 'lecture':
        return LessonType.lecture;
      case 'практика':
      case 'practice':
        return LessonType.practice;
      case 'семинар':
      case 'seminar':
        return LessonType.seminar;
      case 'лабораторная':
      case 'laboratory':
        return LessonType.laboratory;
      default:
        return LessonType.lecture;
    }
  }
}

/// Модель занятия
class LessonModel {
  final String id;
  final String groupId;
  final String groupName;
  final String subject;
  final LessonType type;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String classroom;
  final String? notes;
  final String teacherId;
  final String qrCode;
  final DateTime qrValidFrom;
  final DateTime qrValidUntil;
  final DateTime createdAt;
  final List<String> attendanceMarked;
  final bool isActive;

  const LessonModel({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.subject,
    required this.type,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.classroom,
    this.notes,
    required this.teacherId,
    required this.qrCode,
    required this.qrValidFrom,
    required this.qrValidUntil,
    required this.createdAt,
    required this.attendanceMarked,
    this.isActive = true,
  });

  /// Создание модели из Firestore документа
  factory LessonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LessonModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      groupName: data['groupName'] ?? '',
      subject: data['subject'] ?? '',
      type: LessonType.fromString(data['type'] ?? ''),
      date: (data['date'] as Timestamp).toDate(),
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      classroom: data['classroom'] ?? '',
      notes: data['notes'],
      teacherId: data['teacherId'] ?? '',
      qrCode: data['qrCode'] ?? '',
      qrValidFrom: (data['qrValidFrom'] as Timestamp).toDate(),
      qrValidUntil: (data['qrValidUntil'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      attendanceMarked: List<String>.from(data['attendanceMarked'] ?? []),
      isActive: data['isActive'] ?? true,
    );
  }

  /// Создание модели из Map
  factory LessonModel.fromMap(Map<String, dynamic> map) {
    return LessonModel(
      id: map['id'] ?? '',
      groupId: map['groupId'] ?? '',
      groupName: map['groupName'] ?? '',
      subject: map['subject'] ?? '',
      type: LessonType.fromString(map['type'] ?? ''),
      date: map['date'] is DateTime 
          ? map['date'] 
          : DateTime.now(),
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      classroom: map['classroom'] ?? '',
      notes: map['notes'],
      teacherId: map['teacherId'] ?? '',
      qrCode: map['qrCode'] ?? '',
      qrValidFrom: map['qrValidFrom'] is DateTime 
          ? map['qrValidFrom'] 
          : DateTime.now(),
      qrValidUntil: map['qrValidUntil'] is DateTime 
          ? map['qrValidUntil'] 
          : DateTime.now().add(const Duration(hours: 2)),
      createdAt: map['createdAt'] is DateTime 
          ? map['createdAt'] 
          : DateTime.now(),
      attendanceMarked: List<String>.from(map['attendanceMarked'] ?? []),
      isActive: map['isActive'] ?? true,
    );
  }

  /// Преобразование в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'subject': subject,
      'type': type.displayName,
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,
      'classroom': classroom,
      'notes': notes,
      'teacherId': teacherId,
      'qrCode': qrCode,
      'qrValidFrom': Timestamp.fromDate(qrValidFrom),
      'qrValidUntil': Timestamp.fromDate(qrValidUntil),
      'createdAt': Timestamp.fromDate(createdAt),
      'attendanceMarked': attendanceMarked,
      'isActive': isActive,
    };
  }

  /// Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'groupName': groupName,
      'subject': subject,
      'type': type.displayName,
      'date': date.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'classroom': classroom,
      'notes': notes,
      'teacherId': teacherId,
      'qrCode': qrCode,
      'qrValidFrom': qrValidFrom.toIso8601String(),
      'qrValidUntil': qrValidUntil.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'attendanceMarked': attendanceMarked,
      'isActive': isActive,
    };
  }

  /// Создание копии с изменениями
  LessonModel copyWith({
    String? id,
    String? groupId,
    String? groupName,
    String? subject,
    LessonType? type,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? classroom,
    String? notes,
    String? teacherId,
    String? qrCode,
    DateTime? qrValidFrom,
    DateTime? qrValidUntil,
    DateTime? createdAt,
    List<String>? attendanceMarked,
    bool? isActive,
  }) {
    return LessonModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      subject: subject ?? this.subject,
      type: type ?? this.type,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      classroom: classroom ?? this.classroom,
      notes: notes ?? this.notes,
      teacherId: teacherId ?? this.teacherId,
      qrCode: qrCode ?? this.qrCode,
      qrValidFrom: qrValidFrom ?? this.qrValidFrom,
      qrValidUntil: qrValidUntil ?? this.qrValidUntil,
      createdAt: createdAt ?? this.createdAt,
      attendanceMarked: attendanceMarked ?? this.attendanceMarked,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Получение полного названия занятия
  String get fullName => '$subject (${type.displayName})';

  /// Получение времени занятия в формате строки
  String get timeRange => '$startTime - $endTime';

  /// Получение даты в формате строки
  String get dateString {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lessonDate = DateTime(date.year, date.month, date.day);
    
    if (lessonDate == today) {
      return 'Сегодня';
    } else if (lessonDate == today.add(const Duration(days: 1))) {
      return 'Завтра';
    } else if (lessonDate == today.subtract(const Duration(days: 1))) {
      return 'Вчера';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  /// Проверка, активно ли занятие сейчас
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && now.isAfter(qrValidFrom) && now.isBefore(qrValidUntil);
  }

  /// Проверка, истёк ли QR-код
  bool get isQrExpired {
    return DateTime.now().isAfter(qrValidUntil);
  }

  /// Получение времени до истечения QR-кода
  Duration get timeUntilQrExpires {
    return qrValidUntil.difference(DateTime.now());
  }

  /// Проверка, отметился ли студент
  bool isStudentMarked(String studentId) {
    return attendanceMarked.contains(studentId);
  }

  /// Добавление студента в список отметившихся
  LessonModel markStudentAttendance(String studentId) {
    if (attendanceMarked.contains(studentId)) {
      return this;
    }
    return copyWith(
      attendanceMarked: [...attendanceMarked, studentId],
    );
  }

  /// Удаление студента из списка отметившихся
  LessonModel unmarkStudentAttendance(String studentId) {
    return copyWith(
      attendanceMarked: attendanceMarked.where((id) => id != studentId).toList(),
    );
  }

  /// Получение процента посещаемости
  double getAttendancePercentage(int totalStudents) {
    if (totalStudents == 0) return 0.0;
    return (attendanceMarked.length / totalStudents) * 100;
  }

  @override
  String toString() {
    return 'LessonModel(id: $id, subject: $subject, groupName: $groupName, date: $dateString, time: $timeRange)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LessonModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
