import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Модель для хранения настроек уведомлений
class AppNotificationSettings {
  bool allNotificationsEnabled;
  bool newLessons;
  bool scheduleChanges;
  bool lessonReminders;
  bool weeklyReport;
  bool teacherMessages;
  String reminderTime; // Например, "30 минут до", "1 час до"

  AppNotificationSettings({
    this.allNotificationsEnabled = true,
    this.newLessons = true,
    this.scheduleChanges = true,
    this.lessonReminders = true,
    this.weeklyReport = true,
    this.teacherMessages = true,
    this.reminderTime = '30 минут до',
  });

  AppNotificationSettings copyWith({
    bool? allNotificationsEnabled,
    bool? newLessons,
    bool? scheduleChanges,
    bool? lessonReminders,
    bool? weeklyReport,
    bool? teacherMessages,
    String? reminderTime,
  }) {
    return AppNotificationSettings(
      allNotificationsEnabled: allNotificationsEnabled ?? this.allNotificationsEnabled,
      newLessons: newLessons ?? this.newLessons,
      scheduleChanges: scheduleChanges ?? this.scheduleChanges,
      lessonReminders: lessonReminders ?? this.lessonReminders,
      weeklyReport: weeklyReport ?? this.weeklyReport,
      teacherMessages: teacherMessages ?? this.teacherMessages,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}

/// Сервис для работы с уведомлениями
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  FirebaseMessaging? _firebaseMessaging;

  /// Инициализация сервиса уведомлений
  Future<void> initialize() async {
    try {
      // Инициализация локальных уведомлений
      await _initializeLocalNotifications();
      
      // Инициализация Firebase Messaging только для мобильных платформ
      if (!kIsWeb) {
        await _initializeFirebaseMessaging();
        // Запрос разрешений
        await _requestPermissions();
      } else {
        print('ℹ️ Веб-платформа: Firebase Messaging отключен');
      }
    } catch (e) {
      print('⚠️ Ошибка инициализации NotificationService: $e');
      // Не выбрасываем ошибку, чтобы приложение продолжило работу
    }
  }

  /// Инициализация локальных уведомлений
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Инициализация Firebase Messaging
  Future<void> _initializeFirebaseMessaging() async {
    try {
      _firebaseMessaging = FirebaseMessaging.instance;
      
      // Обработка сообщений в фоне
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Обработка входящих сообщений в активном состоянии
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Обработка нажатия на уведомление при открытии приложения
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    } catch (e) {
      print('⚠️ Ошибка инициализации Firebase Messaging: $e');
      // Продолжаем работу без push-уведомлений
    }
  }

  /// Запрос разрешений на отправку уведомлений
  Future<void> _requestPermissions() async {
    if (_firebaseMessaging == null) return;
    
    final settings = await _firebaseMessaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _localNotifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Разрешение на уведомления получено');
      // Получить FCM токен
      String? token = await _firebaseMessaging!.getToken();
      print('📱 FCM Token: $token');
    } else {
      print('❌ Разрешение на уведомления отклонено');
    }
  }

  /// Показать локальное уведомление
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationDetails? notificationDetails,
  }) async {
    try {
      final details = notificationDetails ?? _getDefaultNotificationDetails();
      
      await _localNotifications.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      throw Exception('Ошибка показа уведомления: $e');
    }
  }

  /// Показать уведомление о новом занятии
  Future<void> showNewLessonNotification({
    required String lessonTitle,
    required String groupName,
    required DateTime lessonTime,
    String? lessonId,
  }) async {
    try {
      final timeString = _formatTime(lessonTime);
      final body = 'Занятие "$lessonTitle" для группы $groupName в $timeString';
      
      await showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: 'Новое занятие',
        body: body,
        payload: lessonId != null ? jsonEncode({'type': 'lesson', 'id': lessonId}) : null,
        notificationDetails: _getLessonNotificationDetails(),
      );
    } catch (e) {
      throw Exception('Ошибка показа уведомления о занятии: $e');
    }
  }

  /// Показать уведомление о напоминании
  Future<void> showReminderNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        _getDefaultNotificationDetails(),
        payload: payload,
      );
    } catch (e) {
      throw Exception('Ошибка показа напоминания: $e');
    }
  }

  /// Показать уведомление о посещаемости
  Future<void> showAttendanceNotification({
    required String studentName,
    required String lessonTitle,
    required bool isPresent,
  }) async {
    try {
      final title = isPresent ? 'Студент отметился' : 'Студент отсутствует';
      final body = isPresent 
          ? '$studentName отметился на занятии "$lessonTitle"'
          : '$studentName отсутствует на занятии "$lessonTitle"';
      
      await showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        notificationDetails: _getAttendanceNotificationDetails(isPresent),
      );
    } catch (e) {
      throw Exception('Ошибка показа уведомления о посещаемости: $e');
    }
  }

  /// Отменить уведомление
  Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
    } catch (e) {
      throw Exception('Ошибка отмены уведомления: $e');
    }
  }

  /// Отменить все уведомления
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      throw Exception('Ошибка отмены всех уведомлений: $e');
    }
  }

  /// Получить токен FCM
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging?.getToken();
    } catch (e) {
      throw Exception('Ошибка получения FCM токена: $e');
    }
  }

  /// Подписаться на топик
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging?.subscribeToTopic(topic);
    } catch (e) {
      throw Exception('Ошибка подписки на топик: $e');
    }
  }

  /// Отписаться от топика
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging?.unsubscribeFromTopic(topic);
    } catch (e) {
      throw Exception('Ошибка отписки от топика: $e');
    }
  }

  /// Сохранить настройки уведомлений
  Future<void> saveNotificationSettings(Map<String, bool> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in settings.entries) {
        await prefs.setBool('notification_${entry.key}', entry.value);
      }
    } catch (e) {
      throw Exception('Ошибка сохранения настроек уведомлений: $e');
    }
  }

  /// Загрузить настройки уведомлений
  Future<Map<String, bool>> loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'allNotifications': prefs.getBool('notification_allNotifications') ?? true,
        'newLessons': prefs.getBool('notification_newLessons') ?? true,
        'scheduleChanges': prefs.getBool('notification_scheduleChanges') ?? true,
        'reminders': prefs.getBool('notification_reminders') ?? true,
        'weeklyReport': prefs.getBool('notification_weeklyReport') ?? true,
        'messages': prefs.getBool('notification_messages') ?? true,
      };
    } catch (e) {
      return {
        'allNotifications': true,
        'newLessons': true,
        'scheduleChanges': true,
        'reminders': true,
        'weeklyReport': true,
        'messages': true,
      };
    }
  }

  /// Обработка нажатия на уведомление
  void _onNotificationTapped(NotificationResponse response) {
    try {
      if (response.payload != null) {
        final payload = jsonDecode(response.payload!);
        _handleNotificationPayload(payload);
      }
    } catch (e) {
      // Игнорируем ошибки парсинга
    }
  }

  /// Обработка сообщения в foreground
  void _handleForegroundMessage(RemoteMessage message) {
    try {
      final notification = message.notification;
      if (notification != null) {
        showLocalNotification(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title: notification.title ?? 'Уведомление',
          body: notification.body ?? '',
          payload: jsonEncode(message.data),
        );
      }
    } catch (e) {
      // Игнорируем ошибки
    }
  }

  /// Обработка открытия приложения через уведомление
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('🚀 Приложение открыто через уведомление: ${message.notification?.title}');
    try {
      _handleNotificationPayload(message.data);
    } catch (e) {
      print('Ошибка обработки уведомления: $e');
    }
  }

  /// Обработка нажатия на уведомление FCM
  void _handleNotificationTap(RemoteMessage message) {
    try {
      _handleNotificationPayload(message.data);
    } catch (e) {
      // Игнорируем ошибки
    }
  }

  /// Обработка данных уведомления
  void _handleNotificationPayload(Map<String, dynamic> payload) {
    try {
      final type = payload['type'] as String?;
      final id = payload['id'] as String?;

      switch (type) {
        case 'lesson':
          // Навигация к занятию
          break;
        case 'group':
          // Навигация к группе
          break;
        case 'attendance':
          // Навигация к посещаемости
          break;
        default:
          // Навигация на главную
          break;
      }
    } catch (e) {
      // Игнорируем ошибки
    }
  }

  /// Получение настроек уведомления по умолчанию
  NotificationDetails _getDefaultNotificationDetails() {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'smart_attendance_channel',
      'Smart Attendance',
      channelDescription: 'Уведомления приложения Smart Attendance',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Настройки уведомления о занятии
  NotificationDetails _getLessonNotificationDetails() {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'lesson_channel',
      'Занятия',
      channelDescription: 'Уведомления о занятиях',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Настройки уведомления о посещаемости
  NotificationDetails _getAttendanceNotificationDetails(bool isPresent) {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'attendance_channel',
      'Посещаемость',
      channelDescription: 'Уведомления о посещаемости',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(isPresent ? 0xFF4CAF50 : 0xFFF44336),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Форматирование времени
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Получить текущие настройки уведомлений
  Future<AppNotificationSettings> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return AppNotificationSettings(
      allNotificationsEnabled: prefs.getBool('allNotificationsEnabled') ?? true,
      newLessons: prefs.getBool('newLessons') ?? true,
      scheduleChanges: prefs.getBool('scheduleChanges') ?? true,
      lessonReminders: prefs.getBool('lessonReminders') ?? true,
      weeklyReport: prefs.getBool('weeklyReport') ?? true,
      teacherMessages: prefs.getBool('teacherMessages') ?? true,
      reminderTime: prefs.getString('reminderTime') ?? '30 минут до',
    );
  }

  /// Обновить настройки уведомлений
  Future<void> updateNotificationSettings(AppNotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('allNotificationsEnabled', settings.allNotificationsEnabled);
    await prefs.setBool('newLessons', settings.newLessons);
    await prefs.setBool('scheduleChanges', settings.scheduleChanges);
    await prefs.setBool('lessonReminders', settings.lessonReminders);
    await prefs.setBool('weeklyReport', settings.weeklyReport);
    await prefs.setBool('teacherMessages', settings.teacherMessages);
    await prefs.setString('reminderTime', settings.reminderTime);
  }

  /// Отправить тестовое уведомление
  Future<void> sendTestNotification() async {
    await _localNotifications.show(
      0,
      'Тестовое уведомление',
      'Это тестовое уведомление от Smart Attendance!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Тестовые уведомления',
          channelDescription: 'Канал для тестовых уведомлений',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}

/// Обработчик фоновых сообщений FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Инициализация Firebase
  // await Firebase.initializeApp();
  
  // Обработка фонового сообщения
  print('Обработка фонового сообщения: ${message.messageId}');
}