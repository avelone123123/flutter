import 'package:cloud_firestore/cloud_firestore.dart';

/// Статус посещаемости
enum AttendanceStatus {
  present('Присутствовал'),
  absent('Отсутствовал'),
  late('Опоздал'),
  excused('Уважительная причина');

  const AttendanceStatus(this.displayName);
  final String displayName;

  static AttendanceStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'присутствовал':
      case 'present':
        return AttendanceStatus.present;
      case 'отсутствовал':
      case 'absent':
        return AttendanceStatus.absent;
      case 'опоздал':
      case 'late':
        return AttendanceStatus.late;
      case 'уважительная причина':
      case 'excused':
        return AttendanceStatus.excused;
      default:
        return AttendanceStatus.absent;
    }
  }
}

/// Модель записи посещаемости
class AttendanceModel {
  final String id;
  final String studentId;
  final String studentName;
  final String lessonId;
  final String groupId;
  final String teacherId;
  final AttendanceStatus status;
  final DateTime markedAt;
  final String? notes;
  final String? qrCode;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AttendanceModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.lessonId,
    required this.groupId,
    required this.teacherId,
    required this.status,
    required this.markedAt,
    this.notes,
    this.qrCode,
    required this.createdAt,
    this.updatedAt,
  });

  /// Создание модели из Firestore документа
  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      lessonId: data['lessonId'] ?? '',
      groupId: data['groupId'] ?? '',
      teacherId: data['teacherId'] ?? '',
      status: AttendanceStatus.fromString(data['status'] ?? ''),
      markedAt: (data['markedAt'] as Timestamp).toDate(),
      notes: data['notes'],
      qrCode: data['qrCode'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  /// Создание модели из Map
  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      lessonId: map['lessonId'] ?? '',
      groupId: map['groupId'] ?? '',
      teacherId: map['teacherId'] ?? '',
      status: AttendanceStatus.fromString(map['status'] ?? ''),
      markedAt: map['markedAt'] is DateTime 
          ? map['markedAt'] 
          : DateTime.now(),
      notes: map['notes'],
      qrCode: map['qrCode'],
      createdAt: map['createdAt'] is DateTime 
          ? map['createdAt'] 
          : DateTime.now(),
      updatedAt: map['updatedAt'] is DateTime 
          ? map['updatedAt'] 
          : null,
    );
  }

  /// Создание модели из JSON
  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      lessonId: json['lessonId'] ?? '',
      groupId: json['groupId'] ?? '',
      teacherId: json['teacherId'] ?? '',
      status: AttendanceStatus.fromString(json['status'] ?? ''),
      markedAt: json['markedAt'] is String 
          ? DateTime.parse(json['markedAt'])
          : json['markedAt'] is DateTime 
              ? json['markedAt'] 
              : DateTime.now(),
      notes: json['notes'],
      qrCode: json['qrCode'],
      createdAt: json['createdAt'] is String 
          ? DateTime.parse(json['createdAt'])
          : json['createdAt'] is DateTime 
              ? json['createdAt'] 
              : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? (json['updatedAt'] is String 
              ? DateTime.parse(json['updatedAt'])
              : json['updatedAt'] is DateTime 
                  ? json['updatedAt'] 
                  : null)
          : null,
    );
  }

  /// Преобразование в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'lessonId': lessonId,
      'groupId': groupId,
      'teacherId': teacherId,
      'status': status.displayName,
      'markedAt': Timestamp.fromDate(markedAt),
      'notes': notes,
      'qrCode': qrCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'lessonId': lessonId,
      'groupId': groupId,
      'teacherId': teacherId,
      'status': status.displayName,
      'markedAt': markedAt.toIso8601String(),
      'notes': notes,
      'qrCode': qrCode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Создание копии с изменениями
  AttendanceModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? lessonId,
    String? groupId,
    String? teacherId,
    AttendanceStatus? status,
    DateTime? markedAt,
    String? notes,
    String? qrCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      lessonId: lessonId ?? this.lessonId,
      groupId: groupId ?? this.groupId,
      teacherId: teacherId ?? this.teacherId,
      status: status ?? this.status,
      markedAt: markedAt ?? this.markedAt,
      notes: notes ?? this.notes,
      qrCode: qrCode ?? this.qrCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Проверка, присутствовал ли студент
  bool get isPresent => status == AttendanceStatus.present;

  /// Проверка, отсутствовал ли студент
  bool get isAbsent => status == AttendanceStatus.absent;

  /// Проверка, опоздал ли студент
  bool get isLate => status == AttendanceStatus.late;

  /// Проверка, есть ли уважительная причина
  bool get isExcused => status == AttendanceStatus.excused;

  /// Получение времени отметки в формате строки
  String get markedAtString {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final markedDate = DateTime(markedAt.year, markedAt.month, markedAt.day);
    
    if (markedDate == today) {
      return 'Сегодня в ${markedAt.hour.toString().padLeft(2, '0')}:${markedAt.minute.toString().padLeft(2, '0')}';
    } else if (markedDate == today.add(const Duration(days: 1))) {
      return 'Завтра в ${markedAt.hour.toString().padLeft(2, '0')}:${markedAt.minute.toString().padLeft(2, '0')}';
    } else if (markedDate == today.subtract(const Duration(days: 1))) {
      return 'Вчера в ${markedAt.hour.toString().padLeft(2, '0')}:${markedAt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${markedAt.day}.${markedAt.month}.${markedAt.year} в ${markedAt.hour.toString().padLeft(2, '0')}:${markedAt.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Получение цвета для статуса
  String get statusColor {
    switch (status) {
      case AttendanceStatus.present:
        return '#4CAF50'; // Зелёный
      case AttendanceStatus.late:
        return '#FF9800'; // Оранжевый
      case AttendanceStatus.excused:
        return '#2196F3'; // Синий
      case AttendanceStatus.absent:
        return '#F44336'; // Красный
    }
  }

  /// Получение иконки для статуса
  String get statusIcon {
    switch (status) {
      case AttendanceStatus.present:
        return '✓';
      case AttendanceStatus.late:
        return '⏰';
      case AttendanceStatus.excused:
        return '📝';
      case AttendanceStatus.absent:
        return '✗';
    }
  }

  @override
  String toString() {
    return 'AttendanceModel(id: $id, student: $studentName, status: ${status.displayName}, markedAt: $markedAtString)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AttendanceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Статистика посещаемости студента
class AttendanceStats {
  final String studentId;
  final String studentName;
  final int totalLessons;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int excusedCount;
  final double attendancePercentage;

  const AttendanceStats({
    required this.studentId,
    required this.studentName,
    required this.totalLessons,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.excusedCount,
    required this.attendancePercentage,
  });

  /// Создание статистики из списка записей посещаемости
  factory AttendanceStats.fromAttendanceList(
    String studentId,
    String studentName,
    List<AttendanceModel> attendanceList,
  ) {
    int presentCount = 0;
    int absentCount = 0;
    int lateCount = 0;
    int excusedCount = 0;

    for (final attendance in attendanceList) {
      switch (attendance.status) {
        case AttendanceStatus.present:
          presentCount++;
          break;
        case AttendanceStatus.absent:
          absentCount++;
          break;
        case AttendanceStatus.late:
          lateCount++;
          break;
        case AttendanceStatus.excused:
          excusedCount++;
          break;
      }
    }

    final totalLessons = attendanceList.length;
    final attendancePercentage = totalLessons > 0 
        ? (presentCount / totalLessons) * 100 
        : 0.0;

    return AttendanceStats(
      studentId: studentId,
      studentName: studentName,
      totalLessons: totalLessons,
      presentCount: presentCount,
      absentCount: absentCount,
      lateCount: lateCount,
      excusedCount: excusedCount,
      attendancePercentage: attendancePercentage,
    );
  }

  /// Получение цветового индикатора посещаемости
  String get attendanceColor {
    if (attendancePercentage >= 90) return '#4CAF50'; // Зелёный
    if (attendancePercentage >= 70) return '#FF9800'; // Оранжевый
    return '#F44336'; // Красный
  }

  /// Получение текстового описания посещаемости
  String get attendanceDescription {
    if (attendancePercentage >= 90) return 'Отличная посещаемость';
    if (attendancePercentage >= 70) return 'Хорошая посещаемость';
    if (attendancePercentage >= 50) return 'Удовлетворительная посещаемость';
    return 'Неудовлетворительная посещаемость';
  }

  /// Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'totalLessons': totalLessons,
      'presentCount': presentCount,
      'absentCount': absentCount,
      'lateCount': lateCount,
      'excusedCount': excusedCount,
      'attendancePercentage': attendancePercentage,
    };
  }

  @override
  String toString() {
    return 'AttendanceStats(student: $studentName, percentage: ${attendancePercentage.toStringAsFixed(1)}%, present: $presentCount/$totalLessons)';
  }
}
