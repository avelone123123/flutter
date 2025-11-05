/// Модель студента
/// Расширяет базовую модель User специфичными для студента полями
class Student {
  /// Уникальный идентификатор студента
  final String id;
  
  /// Имя студента
  final String name;
  
  /// Фамилия студента
  final String surname;
  
  /// Идентификатор группы, к которой принадлежит студент
  final String groupId;
  
  /// Студенческий билет (номер)
  final String studentId;
  
  /// Email студента
  final String email;
  
  /// Номер телефона
  final String? phoneNumber;
  
  /// Фото студента (URL или путь к файлу)
  final String? photoUrl;
  
  /// Дата рождения
  final DateTime? dateOfBirth;
  
  /// Дата поступления
  final DateTime enrollmentDate;
  
  /// Активен ли студент
  final bool isActive;
  
  /// Дополнительная информация о студенте
  final String? notes;

  /// Конструктор модели Student
  const Student({
    required this.id,
    required this.name,
    required this.surname,
    required this.groupId,
    required this.studentId,
    required this.email,
    this.phoneNumber,
    this.photoUrl,
    this.dateOfBirth,
    required this.enrollmentDate,
    this.isActive = true,
    this.notes,
  });

  /// Полное имя студента (имя + фамилия)
  String get fullName => '$name $surname';

  /// Создание объекта Student из JSON
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      name: json['name'] as String,
      surname: json['surname'] as String,
      groupId: json['groupId'] as String,
      studentId: json['studentId'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      photoUrl: json['photoUrl'] as String?,
      dateOfBirth: json['dateOfBirth'] != null 
          ? DateTime.parse(json['dateOfBirth'] as String) 
          : null,
      enrollmentDate: DateTime.parse(json['enrollmentDate'] as String),
      isActive: json['isActive'] as bool? ?? true,
      notes: json['notes'] as String?,
    );
  }

  /// Преобразование объекта Student в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'groupId': groupId,
      'studentId': studentId,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'enrollmentDate': enrollmentDate.toIso8601String(),
      'isActive': isActive,
      'notes': notes,
    };
  }

  /// Создание копии объекта с измененными полями
  Student copyWith({
    String? id,
    String? name,
    String? surname,
    String? groupId,
    String? studentId,
    String? email,
    String? phoneNumber,
    String? photoUrl,
    DateTime? dateOfBirth,
    DateTime? enrollmentDate,
    bool? isActive,
    String? notes,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      groupId: groupId ?? this.groupId,
      studentId: studentId ?? this.studentId,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
    );
  }

  /// Проверка равенства объектов
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Student &&
        other.id == id &&
        other.name == name &&
        other.surname == surname &&
        other.groupId == groupId &&
        other.studentId == studentId &&
        other.email == email &&
        other.phoneNumber == phoneNumber &&
        other.photoUrl == photoUrl &&
        other.dateOfBirth == dateOfBirth &&
        other.enrollmentDate == enrollmentDate &&
        other.isActive == isActive &&
        other.notes == notes;
  }

  /// Генерация хэш-кода для объекта
  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      surname,
      groupId,
      studentId,
      email,
      phoneNumber,
      photoUrl,
      dateOfBirth,
      enrollmentDate,
      isActive,
      notes,
    );
  }

  /// Строковое представление объекта
  @override
  String toString() {
    return 'Student(id: $id, name: $name, surname: $surname, groupId: $groupId, studentId: $studentId, email: $email, phoneNumber: $phoneNumber, photoUrl: $photoUrl, dateOfBirth: $dateOfBirth, enrollmentDate: $enrollmentDate, isActive: $isActive, notes: $notes)';
  }
}
