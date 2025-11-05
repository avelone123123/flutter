import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../providers/web_auth_provider.dart';
import '../models/models.dart';
import '../screens/screens.dart';

/// Роутер приложения с защитой маршрутов
/// Управляет навигацией и проверяет права доступа
class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String groups = '/groups';
  static const String groupDetail = '/groups/detail';
  static const String students = '/students';
  static const String studentDetail = '/students/detail';
  static const String lessons = '/lessons';
  static const String lessonDetail = '/lessons/detail';
  static const String qrScanner = '/qr-scanner';
  static const String qrGenerator = '/qr-generator';
  static const String attendance = '/attendance';
  static const String statistics = '/statistics';
  static const String profile = '/profile';
  static const String settings = '/settings';

  /// Генерация маршрутов
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );

      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
          settings: settings,
        );

      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );

      case groups:
        return MaterialPageRoute(
          builder: (_) => const GroupScreen(),
          settings: settings,
        );

      case groupDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final groupId = args?['groupId'] as String?;
        if (groupId == null) {
          return _errorRoute('Не указан ID группы');
        }
        return MaterialPageRoute(
          builder: (_) => GroupDetailScreen(groupId: groupId),
          settings: settings,
        );

      case students:
        return MaterialPageRoute(
          builder: (_) => const StudentScreen(),
          settings: settings,
        );

      case studentDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final studentId = args?['studentId'] as String?;
        if (studentId == null) {
          return _errorRoute('Не указан ID студента');
        }
        return MaterialPageRoute(
          builder: (_) => StudentDetailScreen(studentId: studentId),
          settings: settings,
        );

      case lessons:
        return MaterialPageRoute(
          builder: (_) => const LessonScreen(),
          settings: settings,
        );

      case lessonDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final lessonId = args?['lessonId'] as String?;
        if (lessonId == null) {
          return _errorRoute('Не указан ID занятия');
        }
        return MaterialPageRoute(
          builder: (_) => LessonDetailScreen(lessonId: lessonId),
          settings: settings,
        );

      case qrScanner:
        return MaterialPageRoute(
          builder: (_) => const QRScannerScreen(),
          settings: settings,
        );

      case qrGenerator:
        final args = settings.arguments as Map<String, dynamic>?;
        final lessonId = args?['lessonId'] as String?;
        if (lessonId == null) {
          return _errorRoute('Не указан ID занятия');
        }
        return MaterialPageRoute(
          builder: (_) => QRGeneratorScreen(lessonId: lessonId),
          settings: settings,
        );

      case attendance:
        return MaterialPageRoute(
          builder: (_) => const AttendanceScreen(),
          settings: settings,
        );

      case statistics:
        return MaterialPageRoute(
          builder: (_) => const AttendanceStatisticsScreen(),
          settings: settings,
        );

      case profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );

      case AppRouter.settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );

      default:
        return _errorRoute('Маршрут не найден: ${settings.name}');
    }
  }

  /// Маршрут ошибки
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Ошибка'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    home,
                    (route) => false,
                  );
                },
                child: const Text('На главную'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Проверка прав доступа к маршруту
  static bool canAccessRoute(String routeName, BuildContext context) {
    // Используем универсальный подход для получения провайдера аутентификации
    dynamic authProvider;
    try {
      if (kIsWeb) {
        authProvider = Provider.of<WebAuthProvider>(context, listen: false);
      } else {
        authProvider = Provider.of<AuthProvider>(context, listen: false);
      }
    } catch (e) {
      // Если провайдер не найден, считаем что пользователь не авторизован
      return false;
    }
    
    // Публичные маршруты (доступны всем)
    const publicRoutes = <String>{
      splash,
      login,
      register,
    };
    
    if (publicRoutes.contains(routeName)) {
      return true;
    }
    
    // Защищенные маршруты (требуют авторизации)
    if (!authProvider.isSignedIn) {
      return false;
    }
    
    // Маршруты только для преподавателей
    const teacherOnlyRoutes = <String>{
      groups,
      groupDetail,
      students,
      studentDetail,
      lessons,
      lessonDetail,
      qrGenerator,
      statistics,
    };
    
    if (teacherOnlyRoutes.contains(routeName)) {
      return authProvider.isTeacher;
    }
    
    // Маршруты только для студентов
    const studentOnlyRoutes = <String>{
      qrScanner,
    };
    
    if (studentOnlyRoutes.contains(routeName)) {
      return authProvider.isStudent;
    }
    
    // Остальные маршруты доступны всем авторизованным пользователям
    return true;
  }

  /// Переход с проверкой прав доступа
  static Future<T?> pushNamed<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    if (canAccessRoute(routeName, context)) {
      return Navigator.of(context).pushNamed<T>(
        routeName,
        arguments: arguments,
      );
    } else {
      _showAccessDeniedDialog(context);
      return null;
    }
  }

  /// Замена маршрута с проверкой прав доступа
  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    TO? result,
  }) async {
    if (canAccessRoute(routeName, context)) {
      return Navigator.of(context).pushReplacementNamed<T, TO>(
        routeName,
        arguments: arguments,
        result: result,
      );
    } else {
      _showAccessDeniedDialog(context);
      return null;
    }
  }

  /// Переход с очисткой стека и проверкой прав доступа
  static Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    BuildContext context,
    String routeName,
    RoutePredicate predicate, {
    Object? arguments,
  }) async {
    if (canAccessRoute(routeName, context)) {
      return Navigator.of(context).pushNamedAndRemoveUntil<T>(
        routeName,
        predicate,
        arguments: arguments,
      );
    } else {
      _showAccessDeniedDialog(context);
      return null;
    }
  }

  /// Показ диалога отказа в доступе
  static void _showAccessDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Доступ запрещен'),
        content: const Text(
          'У вас нет прав для доступа к этому разделу. '
          'Обратитесь к администратору.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Получение начального маршрута в зависимости от состояния авторизации
  static String getInitialRoute(BuildContext context) {
    // Используем универсальный подход для получения провайдера аутентификации
    dynamic authProvider;
    try {
      if (kIsWeb) {
        authProvider = Provider.of<WebAuthProvider>(context, listen: false);
      } else {
        authProvider = Provider.of<AuthProvider>(context, listen: false);
      }
    } catch (e) {
      // Если провайдер не найден, переходим на экран входа
      return login;
    }
    
    if (authProvider.isLoading) {
      return splash;
    } else if (authProvider.isSignedIn) {
      return home;
    } else {
      return login;
    }
  }

  /// Переход к главному экрану с очисткой стека
  static void goToHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      home,
      (route) => false,
    );
  }

  /// Переход к экрану входа с очисткой стека
  static void goToLogin(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      login,
      (route) => false,
    );
  }

  /// Переход к экрану регистрации
  static void goToRegister(BuildContext context) {
    Navigator.of(context).pushNamed(register);
  }

  /// Переход к деталям группы
  static void goToGroupDetail(BuildContext context, String groupId) {
    Navigator.of(context).pushNamed(
      groupDetail,
      arguments: {'groupId': groupId},
    );
  }

  /// Переход к деталям студента
  static void goToStudentDetail(BuildContext context, String studentId) {
    Navigator.of(context).pushNamed(
      studentDetail,
      arguments: {'studentId': studentId},
    );
  }

  /// Переход к деталям занятия
  static void goToLessonDetail(BuildContext context, String lessonId) {
    Navigator.of(context).pushNamed(
      lessonDetail,
      arguments: {'lessonId': lessonId},
    );
  }

  /// Переход к генератору QR-кода
  static void goToQRGenerator(BuildContext context, String lessonId) {
    Navigator.of(context).pushNamed(
      qrGenerator,
      arguments: {'lessonId': lessonId},
    );
  }

  /// Переход к сканеру QR-кода
  static void goToQRScanner(BuildContext context) {
    Navigator.of(context).pushNamed(qrScanner);
  }

  /// Переход к статистике
  static void goToStatistics(BuildContext context) {
    Navigator.of(context).pushNamed(statistics);
  }

  /// Переход к профилю
  static void goToProfile(BuildContext context) {
    Navigator.of(context).pushNamed(profile);
  }

  /// Переход к настройкам
  static void goToSettings(BuildContext context) {
    Navigator.of(context).pushNamed(settings);
  }
}

/// Заглушки для экранов, которые будут реализованы позже
class GroupDetailScreen extends StatelessWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Группа $groupId')),
      body: const Center(child: Text('Детали группы - в разработке')),
    );
  }
}

class StudentScreen extends StatelessWidget {
  const StudentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Список студентов - в разработке')),
    );
  }
}

class StudentDetailScreen extends StatelessWidget {
  final String studentId;
  const StudentDetailScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Студент $studentId')),
      body: const Center(child: Text('Детали студента - в разработке')),
    );
  }
}

class LessonDetailScreen extends StatelessWidget {
  final String lessonId;
  const LessonDetailScreen({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Занятие $lessonId')),
      body: const Center(child: Text('Детали занятия - в разработке')),
    );
  }
}

class QRScannerScreen extends StatelessWidget {
  const QRScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('QR Сканер - в разработке')),
    );
  }
}

class QRGeneratorScreen extends StatelessWidget {
  final String lessonId;
  const QRGeneratorScreen({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('QR для занятия $lessonId')),
      body: const Center(child: Text('Генератор QR - в разработке')),
    );
  }
}

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Посещаемость - в разработке')),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Настройки - в разработке')),
    );
  }
}
