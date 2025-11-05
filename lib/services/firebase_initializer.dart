import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Инициализация Firebase
/// Этот класс отвечает за настройку Firebase в приложении
class FirebaseInitializer {
  /// Инициализирует Firebase
  /// Вызывается в main() перед запуском приложения
  static Future<void> initialize() async {
    try {
      // На вебе пропускаем инициализацию без FirebaseOptions,
      // чтобы приложение запускалось в браузере без конфигурации Firebase
      if (kIsWeb) {
        debugPrint('Firebase initialization skipped on Web');
        return;
      }
      // Инициализируем Firebase
      await Firebase.initializeApp();
      debugPrint('Firebase инициализирован успешно');
    } catch (e) {
      debugPrint('Ошибка инициализации Firebase: $e');
      rethrow;
    }
  }
}
