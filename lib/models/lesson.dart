import 'group.dart';

/// Модель занятия
/// Содержит информацию о конкретном занятии
class Lesson {
  /// Уникальный идентификатор занятия
  final String id;
  
  /// Идентификатор группы
  final String groupId;
  
  /// Название предмета
  final String subject;
  
  /// Дата проведения занятия
  final DateTime date;
  
  /// Время начала занятия
  final TimeOfDay startTime;
  
  /// Время окончания занятия
  final TimeOfDay endTime;
  
  /// Аудитория
  final String? classroom;
  
  /// Описание занятия
  final String? description;
  
  /// QR-код для отметки посещаемости
  final String? qrCode;
  
  /// Дата создания занятия
  final DateTime createdAt;
  
  /// Идентификатор преподавателя
  final String teacherId;
  
  /// Статус занятия
  final LessonStatus status;
  
  /// Максимальное время для отметки посещаемости (в минутах)
  final int attendanceWindowMinutes;

  /// Конструктор модели Lesson
  const Lesson({
    required this.id,
    required this.groupId,
    required this.subject,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.classroom,
    this.description,
    this.qrCode,
    required this.createdAt,
    required this.teacherId,
    this.status = LessonStatus.scheduled,
    this.attendanceWindowMinutes = 15,
  });

  /// Полная дата и время начала занятия
  DateTime get fullStartDateTime {
    return DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );
  }

  /// Полная дата и время окончания занятия
  DateTime get fullEndDateTime {
    return DateTime(
      date.year,
      date.month,
      date.day,
      endTime.hour,
      endTime.minute,
    );
  }

  /// Проверка, можно ли еще отмечать посещаемость
  bool get canMarkAttendance {
    final now = DateTime.now();
    final attendanceDeadline = fullStartDateTime.add(
      Duration(minutes: attendanceWindowMinutes),
    );
    return now.isBefore(attendanceDeadline) && status == LessonStatus.inProgress;
  }

  /// Проверка, началось ли занятие
  bool get hasStarted {
    return DateTime.now().isAfter(fullStartDateTime);
  }

  /// Проверка, закончилось ли занятие
  bool get hasEnded {
    return DateTime.now().isAfter(fullEndDateTime);
  }

  /// Создание объекта Lesson из JSON
  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      subject: json['subject'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: TimeOfDay.fromJson(json['startTime'] as Map<String, dynamic>),
      endTime: TimeOfDay.fromJson(json['endTime'] as Map<String, dynamic>),
      classroom: json['classroom'] as String?,
      description: json['description'] as String?,
      qrCode: json['qrCode'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      teacherId: json['teacherId'] as String,
      status: LessonStatus.fromString(json['status'] as String),
      attendanceWindowMinutes: json['attendanceWindowMinutes'] as int? ?? 15,
    );
  }

  /// Преобразование объекта Lesson в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'subject': subject,
      'date': date.toIso8601String(),
      'startTime': startTime.toJson(),
      'endTime': endTime.toJson(),
      'classroom': classroom,
      'description': description,
      'qrCode': qrCode,
      'createdAt': createdAt.toIso8601String(),
      'teacherId': teacherId,
      'status': status.toString(),
      'attendanceWindowMinutes': attendanceWindowMinutes,
    };
  }

  /// Создание копии объекта с измененными полями
  Lesson copyWith({
    String? id,
    String? groupId,
    String? subject,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? classroom,
    String? description,
    String? qrCode,
    DateTime? createdAt,
    String? teacherId,
    LessonStatus? status,
    int? attendanceWindowMinutes,
  }) {
    return Lesson(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      subject: subject ?? this.subject,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      classroom: classroom ?? this.classroom,
      description: description ?? this.description,
      qrCode: qrCode ?? this.qrCode,
      createdAt: createdAt ?? this.createdAt,
      teacherId: teacherId ?? this.teacherId,
      status: status ?? this.status,
      attendanceWindowMinutes: attendanceWindowMinutes ?? this.attendanceWindowMinutes,
    );
  }

  /// Проверка равенства объектов
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Lesson &&
        other.id == id &&
        other.groupId == groupId &&
        other.subject == subject &&
        other.date == date &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.classroom == classroom &&
        other.description == description &&
        other.qrCode == qrCode &&
        other.createdAt == createdAt &&
        other.teacherId == teacherId &&
        other.status == status &&
        other.attendanceWindowMinutes == attendanceWindowMinutes;
  }

  /// Генерация хэш-кода для объекта
  @override
  int get hashCode {
    return Object.hash(
      id,
      groupId,
      subject,
      date,
      startTime,
      endTime,
      classroom,
      description,
      qrCode,
      createdAt,
      teacherId,
      status,
      attendanceWindowMinutes,
    );
  }

  /// Строковое представление объекта
  @override
  String toString() {
    return 'Lesson(id: $id, groupId: $groupId, subject: $subject, date: $date, startTime: $startTime, endTime: $endTime, classroom: $classroom, description: $description, qrCode: $qrCode, createdAt: $createdAt, teacherId: $teacherId, status: $status, attendanceWindowMinutes: $attendanceWindowMinutes)';
  }
}

/// Статусы занятия
enum LessonStatus {
  /// Запланировано
  scheduled,
  /// В процессе
  inProgress,
  /// Завершено
  completed,
  /// Отменено
  cancelled;

  /// Получение статуса из строки
  static LessonStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return LessonStatus.scheduled;
      case 'inprogress':
        return LessonStatus.inProgress;
      case 'completed':
        return LessonStatus.completed;
      case 'cancelled':
        return LessonStatus.cancelled;
      default:
        throw ArgumentError('Неизвестный статус занятия: $status');
    }
  }

  /// Получение строкового представления статуса
  @override
  String toString() {
    switch (this) {
      case LessonStatus.scheduled:
        return 'scheduled';
      case LessonStatus.inProgress:
        return 'inProgress';
      case LessonStatus.completed:
        return 'completed';
      case LessonStatus.cancelled:
        return 'cancelled';
    }
  }

  /// Получение локализованного названия статуса
  String getDisplayName() {
    switch (this) {
      case LessonStatus.scheduled:
        return 'Запланировано';
      case LessonStatus.inProgress:
        return 'В процессе';
      case LessonStatus.completed:
        return 'Завершено';
      case LessonStatus.cancelled:
        return 'Отменено';
    }
  }
}

