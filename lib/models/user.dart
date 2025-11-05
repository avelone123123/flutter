/// Модель пользователя системы
/// Содержит информацию о преподавателях и студентах
class User {
  /// Уникальный идентификатор пользователя (Firebase UID)
  final String id;
  
  /// Email пользователя
  final String email;
  
  /// Имя пользователя
  final String name;
  
  /// Роль пользователя (teacher - преподаватель, student - студент)
  final UserRole role;
  
  /// Дата создания аккаунта
  final DateTime createdAt;
  
  /// Дата последнего входа
  final DateTime? lastLoginAt;
  
  /// Фото профиля (URL или путь к файлу)
  final String? photoUrl;
  
  /// Номер телефона
  final String? phoneNumber;
  
  /// Фамилия
  final String? lastName;
  
  /// Отчество
  final String? middleName;
  
  /// Должность/факультет (для преподавателей)
  final String? position;
  
  /// Группа (для студентов)
  final String? groupId;
  
  /// О себе
  final String? bio;
  
  /// Активен ли аккаунт
  final bool isActive;

  /// Конструктор модели User
  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    this.lastLoginAt,
    this.photoUrl,
    this.phoneNumber,
    this.lastName,
    this.middleName,
    this.position,
    this.groupId,
    this.bio,
    this.isActive = true,
  });

  /// Создание объекта User из JSON (для работы с Firebase)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: UserRole.fromString(json['role'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.parse(json['lastLoginAt'] as String) 
          : null,
      photoUrl: json['photoUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      lastName: json['lastName'] as String?,
      middleName: json['middleName'] as String?,
      position: json['position'] as String?,
      groupId: json['groupId'] as String?,
      bio: json['bio'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Преобразование объекта User в JSON (для сохранения в Firebase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.toString(),
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'lastName': lastName,
      'middleName': middleName,
      'position': position,
      'groupId': groupId,
      'bio': bio,
      'isActive': isActive,
    };
  }

  /// Создание копии объекта с измененными полями
  User copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? photoUrl,
    String? phoneNumber,
    String? lastName,
    String? middleName,
    String? position,
    String? groupId,
    String? bio,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      position: position ?? this.position,
      groupId: groupId ?? this.groupId,
      bio: bio ?? this.bio,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Проверка равенства объектов
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.role == role &&
        other.createdAt == createdAt &&
        other.lastLoginAt == lastLoginAt &&
        other.photoUrl == photoUrl &&
        other.phoneNumber == phoneNumber &&
        other.isActive == isActive;
  }

  /// Генерация хэш-кода для объекта
  @override
  int get hashCode {
    return Object.hash(
      id,
      email,
      name,
      role,
      createdAt,
      lastLoginAt,
      photoUrl,
      phoneNumber,
      isActive,
    );
  }

  /// Строковое представление объекта
  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, role: $role, createdAt: $createdAt, lastLoginAt: $lastLoginAt, photoUrl: $photoUrl, phoneNumber: $phoneNumber, isActive: $isActive)';
  }
}

/// Роли пользователей в системе
enum UserRole {
  /// Преподаватель
  teacher,
  /// Студент
  student;

  /// Получение роли из строки
  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'teacher':
        return UserRole.teacher;
      case 'student':
        return UserRole.student;
      default:
        throw ArgumentError('Неизвестная роль: $role');
    }
  }

  /// Получение строкового представления роли
  @override
  String toString() {
    switch (this) {
      case UserRole.teacher:
        return 'teacher';
      case UserRole.student:
        return 'student';
    }
  }

  /// Получение локализованного названия роли
  String getDisplayName() {
    switch (this) {
      case UserRole.teacher:
        return 'Преподаватель';
      case UserRole.student:
        return 'Студент';
    }
  }
}

/// Расширение для модели User с дополнительными методами
extension UserExtension on User {
  /// Получение полного имени пользователя
  String get fullName {
    final parts = <String>[];
    if (lastName != null && lastName!.isNotEmpty) parts.add(lastName!);
    if (name.isNotEmpty) parts.add(name);
    if (middleName != null && middleName!.isNotEmpty) parts.add(middleName!);
    return parts.join(' ');
  }

  /// Получение инициалов пользователя
  String get initials {
    final parts = <String>[];
    if (lastName != null && lastName!.isNotEmpty) parts.add(lastName![0].toUpperCase());
    if (name.isNotEmpty) parts.add(name[0].toUpperCase());
    if (middleName != null && middleName!.isNotEmpty) parts.add(middleName![0].toUpperCase());
    return parts.join('');
  }

  /// Получение отображаемого имени (полное имя или просто имя)
  String get displayName => fullName.isNotEmpty ? fullName : name;

  /// Проверка, является ли пользователь преподавателем
  bool get isTeacher => role == UserRole.teacher;

  /// Проверка, является ли пользователь студентом
  bool get isStudent => role == UserRole.student;

  /// Получение описания роли с дополнительной информацией
  String get roleDescription {
    switch (role) {
      case UserRole.teacher:
        return position != null ? '$position' : 'Преподаватель';
      case UserRole.student:
        return groupId != null ? 'Студент группы $groupId' : 'Студент';
    }
  }

  /// Проверка, заполнен ли профиль полностью
  bool get isProfileComplete {
    return name.isNotEmpty &&
           email.isNotEmpty &&
           (lastName?.isNotEmpty ?? false) &&
           (phoneNumber?.isNotEmpty ?? false);
  }

  /// Получение процента заполненности профиля
  double get profileCompletionPercentage {
    int filledFields = 0;
    int totalFields = 6; // name, email, lastName, phoneNumber, photoUrl, bio

    if (name.isNotEmpty) filledFields++;
    if (email.isNotEmpty) filledFields++;
    if (lastName?.isNotEmpty ?? false) filledFields++;
    if (phoneNumber?.isNotEmpty ?? false) filledFields++;
    if (photoUrl?.isNotEmpty ?? false) filledFields++;
    if (bio?.isNotEmpty ?? false) filledFields++;

    return (filledFields / totalFields) * 100;
  }
}
