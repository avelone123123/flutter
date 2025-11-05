import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/models.dart';

/// Сервис для работы с локальной базой данных SQLite
/// Используется для кэширования данных и работы в оффлайн режиме
class LocalDatabaseService {
  static Database? _database;
  static const String _databaseName = 'smart_attendance.db';
  static const int _databaseVersion = 1;

  // Названия таблиц
  static const String _usersTable = 'users';
  static const String _studentsTable = 'students';
  static const String _groupsTable = 'groups';
  static const String _lessonsTable = 'lessons';
  static const String _attendanceTable = 'attendance';
  static const String _syncStatusTable = 'sync_status';

  /// Получение экземпляра базы данных
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Инициализация базы данных
  Future<Database> _initDatabase() async {
    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Создание таблиц при первом запуске
  Future<void> _onCreate(Database db, int version) async {
    // Таблица пользователей
    await db.execute('''
      CREATE TABLE $_usersTable (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        lastLoginAt TEXT,
        photoUrl TEXT,
        phoneNumber TEXT,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Таблица студентов
    await db.execute('''
      CREATE TABLE $_studentsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        surname TEXT NOT NULL,
        groupId TEXT NOT NULL,
        studentId TEXT NOT NULL,
        email TEXT NOT NULL,
        phoneNumber TEXT,
        photoUrl TEXT,
        dateOfBirth TEXT,
        enrollmentDate TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        lastUpdated TEXT NOT NULL
      )
    ''');

    // Таблица групп
    await db.execute('''
      CREATE TABLE $_groupsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        teacherId TEXT NOT NULL,
        studentIds TEXT NOT NULL,
        schedule TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        startDate TEXT,
        endDate TEXT,
        isActive INTEGER NOT NULL DEFAULT 1,
        maxStudents INTEGER,
        lastUpdated TEXT NOT NULL
      )
    ''');

    // Таблица занятий
    await db.execute('''
      CREATE TABLE $_lessonsTable (
        id TEXT PRIMARY KEY,
        groupId TEXT NOT NULL,
        subject TEXT NOT NULL,
        date TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        classroom TEXT,
        description TEXT,
        qrCode TEXT,
        createdAt TEXT NOT NULL,
        teacherId TEXT NOT NULL,
        status TEXT NOT NULL,
        attendanceWindowMinutes INTEGER NOT NULL DEFAULT 15,
        lastUpdated TEXT NOT NULL
      )
    ''');

    // Таблица посещаемости
    await db.execute('''
      CREATE TABLE $_attendanceTable (
        id TEXT PRIMARY KEY,
        lessonId TEXT NOT NULL,
        studentId TEXT NOT NULL,
        status TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        method TEXT NOT NULL,
        comment TEXT,
        markedByTeacherId TEXT,
        location TEXT,
        lastUpdated TEXT NOT NULL
      )
    ''');

    // Таблица статуса синхронизации
    await db.execute('''
      CREATE TABLE $_syncStatusTable (
        tableName TEXT PRIMARY KEY,
        lastSyncTime TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// Обновление базы данных при изменении версии
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Здесь можно добавить логику миграции данных
    if (oldVersion < 2) {
      // Пример миграции для версии 2
      // await db.execute('ALTER TABLE $_usersTable ADD COLUMN newField TEXT');
    }
  }

  // ========== ОПЕРАЦИИ С ПОЛЬЗОВАТЕЛЯМИ ==========

  /// Сохранение пользователя в локальную базу
  Future<void> saveUser(User user) async {
    final db = await database;
    await db.insert(
      _usersTable,
      user.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Получение пользователя по ID
  Future<User?> getUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _usersTable,
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    }
    return null;
  }

  /// Получение всех пользователей
  Future<List<User>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_usersTable);
    return maps.map((map) => User.fromJson(map)).toList();
  }

  // ========== ОПЕРАЦИИ СО СТУДЕНТАМИ ==========

  /// Сохранение студента в локальную базу
  Future<void> saveStudent(Student student) async {
    final db = await database;
    final studentData = student.toJson();
    studentData['lastUpdated'] = DateTime.now().toIso8601String();
    
    await db.insert(
      _studentsTable,
      studentData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Получение студентов группы
  Future<List<Student>> getStudentsByGroup(String groupId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _studentsTable,
      where: 'groupId = ? AND isActive = 1',
      whereArgs: [groupId],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Student.fromJson(map)).toList();
  }

  /// Получение студента по ID
  Future<Student?> getStudent(String studentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _studentsTable,
      where: 'id = ?',
      whereArgs: [studentId],
    );

    if (maps.isNotEmpty) {
      return Student.fromJson(maps.first);
    }
    return null;
  }

  /// Удаление студента
  Future<void> deleteStudent(String studentId) async {
    final db = await database;
    await db.update(
      _studentsTable,
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [studentId],
    );
  }

  // ========== ОПЕРАЦИИ С ГРУППАМИ ==========

  /// Сохранение группы в локальную базу
  Future<void> saveGroup(Group group) async {
    final db = await database;
    final groupData = group.toJson();
    groupData['lastUpdated'] = DateTime.now().toIso8601String();
    
    await db.insert(
      _groupsTable,
      groupData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Получение групп преподавателя
  Future<List<Group>> getGroupsByTeacher(String teacherId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _groupsTable,
      where: 'teacherId = ? AND isActive = 1',
      whereArgs: [teacherId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Group.fromJson(map)).toList();
  }

  /// Получение группы по ID
  Future<Group?> getGroup(String groupId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _groupsTable,
      where: 'id = ?',
      whereArgs: [groupId],
    );

    if (maps.isNotEmpty) {
      return Group.fromJson(maps.first);
    }
    return null;
  }

  // ========== ОПЕРАЦИИ С ЗАНЯТИЯМИ ==========

  /// Сохранение занятия в локальную базу
  Future<void> saveLesson(Lesson lesson) async {
    final db = await database;
    final lessonData = lesson.toJson();
    lessonData['lastUpdated'] = DateTime.now().toIso8601String();
    
    await db.insert(
      _lessonsTable,
      lessonData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Получение занятий группы
  Future<List<Lesson>> getLessonsByGroup(String groupId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _lessonsTable,
      where: 'groupId = ?',
      whereArgs: [groupId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Lesson.fromJson(map)).toList();
  }

  /// Получение занятия по ID
  Future<Lesson?> getLesson(String lessonId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _lessonsTable,
      where: 'id = ?',
      whereArgs: [lessonId],
    );

    if (maps.isNotEmpty) {
      return Lesson.fromJson(maps.first);
    }
    return null;
  }

  // ========== ОПЕРАЦИИ С ПОСЕЩАЕМОСТЬЮ ==========

  /// Сохранение посещаемости в локальную базу
  Future<void> saveAttendanceModel(AttendanceModel attendance) async {
    final db = await database;
    final attendanceData = attendance.toJson();
    attendanceData['lastUpdated'] = DateTime.now().toIso8601String();
    
    await db.insert(
      _attendanceTable,
      attendanceData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Получение посещаемости занятия
  Future<List<AttendanceModel>> getAttendanceModelByLesson(String lessonId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _attendanceTable,
      where: 'lessonId = ?',
      whereArgs: [lessonId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => AttendanceModel.fromJson(map)).toList();
  }

  /// Получение посещаемости студента
  Future<List<AttendanceModel>> getAttendanceModelByStudent(String studentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _attendanceTable,
      where: 'studentId = ?',
      whereArgs: [studentId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => AttendanceModel.fromJson(map)).toList();
  }

  // ========== СИНХРОНИЗАЦИЯ ==========

  /// Получение времени последней синхронизации таблицы
  Future<DateTime?> getLastSyncTime(String tableName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _syncStatusTable,
      where: 'tableName = ?',
      whereArgs: [tableName],
    );

    if (maps.isNotEmpty) {
      return DateTime.parse(maps.first['lastSyncTime'] as String);
    }
    return null;
  }

  /// Обновление времени последней синхронизации
  Future<void> updateSyncTime(String tableName) async {
    final db = await database;
    await db.insert(
      _syncStatusTable,
      {
        'tableName': tableName,
        'lastSyncTime': DateTime.now().toIso8601String(),
        'isSynced': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Очистка всех данных
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_usersTable);
    await db.delete(_studentsTable);
    await db.delete(_groupsTable);
    await db.delete(_lessonsTable);
    await db.delete(_attendanceTable);
    await db.delete(_syncStatusTable);
  }

  /// Получение размера базы данных
  Future<int> getDatabaseSize() async {
    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, _databaseName);
    final File file = File(path);
    
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Закрытие базы данных
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
