import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/web_auth_provider.dart';

/// Утилита для безопасной работы с аутентификацией
/// Автоматически определяет платформу и использует соответствующий провайдер
class AuthHelper {
  /// Получить ID текущего пользователя
  /// Возвращает null если пользователь не авторизован
  static String? getCurrentUserId(BuildContext context) {
    try {
      if (kIsWeb) {
        final webAuthProvider = Provider.of<WebAuthProvider>(context, listen: false);
        return webAuthProvider.isSignedIn ? webAuthProvider.currentUserId : null;
      } else {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        return authProvider.isSignedIn ? authProvider.currentUserId : null;
      }
    } catch (e) {
      debugPrint('Ошибка получения ID пользователя: $e');
      return null;
    }
  }

  /// Проверить, авторизован ли пользователь
  static bool isSignedIn(BuildContext context) {
    try {
      if (kIsWeb) {
        final webAuthProvider = Provider.of<WebAuthProvider>(context, listen: false);
        return webAuthProvider.isSignedIn;
      } else {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        return authProvider.isSignedIn;
      }
    } catch (e) {
      debugPrint('Ошибка проверки авторизации: $e');
      return false;
    }
  }

  /// Получить email текущего пользователя
  static String? getCurrentUserEmail(BuildContext context) {
    try {
      if (kIsWeb) {
        final webAuthProvider = Provider.of<WebAuthProvider>(context, listen: false);
        return webAuthProvider.userData?.email;
      } else {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        return authProvider.currentUser?.email;
      }
    } catch (e) {
      debugPrint('Ошибка получения email пользователя: $e');
      return null;
    }
  }

  /// Получить имя текущего пользователя
  static String? getCurrentUserName(BuildContext context) {
    try {
      if (kIsWeb) {
        final webAuthProvider = Provider.of<WebAuthProvider>(context, listen: false);
        return webAuthProvider.userData?.name;
      } else {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        return authProvider.currentUser?.displayName;
      }
    } catch (e) {
      debugPrint('Ошибка получения имени пользователя: $e');
      return null;
    }
  }

  /// Выйти из системы
  static Future<bool> signOut(BuildContext context) async {
    try {
      if (kIsWeb) {
        final webAuthProvider = Provider.of<WebAuthProvider>(context, listen: false);
        await webAuthProvider.signOut();
        return true;
      } else {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.signOut();
        return true;
      }
    } catch (e) {
      debugPrint('Ошибка выхода из системы: $e');
      return false;
    }
  }
}
