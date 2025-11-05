/// Модель группы студентов
/// Содержит информацию о группе и её участниках
class Group {
  /// Уникальный идентификатор группы
  final String id;
  
  /// Название группы
  final String name;
  
  /// Описание группы
  final String? description;
  
  /// Идентификатор преподавателя группы
  final String teacherId;
  
  /// Список идентификаторов студентов в группе
  final List<String> studentIds;
  
  /// Расписание занятий группы
  final List<ScheduleItem> schedule;
  
  /// Дата создания группы
  final DateTime createdAt;
  
  /// Дата начала обучения
  final DateTime? startDate;
  
  /// Дата окончания обучения
  final DateTime? endDate;
  
  /// Активна ли группа
  final bool isActive;
  
  /// Максимальное количество студентов в группе
  final int? maxStudents;

  /// Конструктор модели Group
  const Group({
    required this.id,
    required this.name,
    this.description,
    required this.teacherId,
    required this.studentIds,
    required this.schedule,
    required this.createdAt,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.maxStudents,
  });

  /// Количество студентов в группе
  int get studentCount => studentIds.length;

  /// Проверка, заполнена ли группа
  bool get isFull => maxStudents != null && studentCount >= maxStudents!;

  /// Создание объекта Group из JSON
  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      teacherId: json['teacherId'] as String,
      studentIds: List<String>.from(json['studentIds'] as List),
      schedule: (json['schedule'] as List)
          .map((item) => ScheduleItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate'] as String) 
          : null,
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate'] as String) 
          : null,
      isActive: json['isActive'] as bool? ?? true,
      maxStudents: json['maxStudents'] as int?,
    );
  }

  /// Преобразование объекта Group в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'teacherId': teacherId,
      'studentIds': studentIds,
      'schedule': schedule.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'maxStudents': maxStudents,
    };
  }

  /// Создание копии объекта с измененными полями
  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? teacherId,
    List<String>? studentIds,
    List<ScheduleItem>? schedule,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    int? maxStudents,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      teacherId: teacherId ?? this.teacherId,
      studentIds: studentIds ?? this.studentIds,
      schedule: schedule ?? this.schedule,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      maxStudents: maxStudents ?? this.maxStudents,
    );
  }

  /// Проверка равенства объектов
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Group &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.teacherId == teacherId &&
        other.studentIds == studentIds &&
        other.schedule == schedule &&
        other.createdAt == createdAt &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.isActive == isActive &&
        other.maxStudents == maxStudents;
  }

  /// Генерация хэш-кода для объекта
  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      teacherId,
      studentIds,
      schedule,
      createdAt,
      startDate,
      endDate,
      isActive,
      maxStudents,
    );
  }

  /// Строковое представление объекта
  @override
  String toString() {
    return 'Group(id: $id, name: $name, description: $description, teacherId: $teacherId, studentIds: $studentIds, schedule: $schedule, createdAt: $createdAt, startDate: $startDate, endDate: $endDate, isActive: $isActive, maxStudents: $maxStudents)';
  }
}

/// Элемент расписания группы
class ScheduleItem {
  /// День недели (1-7, где 1 - понедельник)
  final int dayOfWeek;
  
  /// Время начала занятия
  final TimeOfDay startTime;
  
  /// Время окончания занятия
  final TimeOfDay endTime;
  
  /// Название предмета
  final String subject;
  
  /// Аудитория
  final String? classroom;

  /// Конструктор элемента расписания
  const ScheduleItem({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.subject,
    this.classroom,
  });

  /// Создание объекта ScheduleItem из JSON
  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      dayOfWeek: json['dayOfWeek'] as int,
      startTime: TimeOfDay.fromJson(json['startTime'] as Map<String, dynamic>),
      endTime: TimeOfDay.fromJson(json['endTime'] as Map<String, dynamic>),
      subject: json['subject'] as String,
      classroom: json['classroom'] as String?,
    );
  }

  /// Преобразование объекта ScheduleItem в JSON
  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek,
      'startTime': startTime.toJson(),
      'endTime': endTime.toJson(),
      'subject': subject,
      'classroom': classroom,
    };
  }

  /// Проверка равенства объектов
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduleItem &&
        other.dayOfWeek == dayOfWeek &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.subject == subject &&
        other.classroom == classroom;
  }

  /// Генерация хэш-кода для объекта
  @override
  int get hashCode {
    return Object.hash(dayOfWeek, startTime, endTime, subject, classroom);
  }

  /// Строковое представление объекта
  @override
  String toString() {
    return 'ScheduleItem(dayOfWeek: $dayOfWeek, startTime: $startTime, endTime: $endTime, subject: $subject, classroom: $classroom)';
  }
}

/// Время дня (часы и минуты)
class TimeOfDay {
  /// Часы (0-23)
  final int hour;
  
  /// Минуты (0-59)
  final int minute;

  /// Конструктор времени
  const TimeOfDay({
    required this.hour,
    required this.minute,
  });

  /// Создание объекта TimeOfDay из JSON
  factory TimeOfDay.fromJson(Map<String, dynamic> json) {
    return TimeOfDay(
      hour: json['hour'] as int,
      minute: json['minute'] as int,
    );
  }

  /// Преобразование объекта TimeOfDay в JSON
  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'minute': minute,
    };
  }

  /// Форматирование времени в строку (HH:MM)
  String format() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Проверка равенства объектов
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeOfDay && other.hour == hour && other.minute == minute;
  }

  /// Генерация хэш-кода для объекта
  @override
  int get hashCode => Object.hash(hour, minute);

  /// Строковое представление объекта
  @override
  String toString() => format();
}
