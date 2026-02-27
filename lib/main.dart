import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import 'l10n/app_localizations.dart';
import 'services/services.dart';
import 'providers/providers.dart';
import 'providers/web_auth_provider.dart';
import 'utils/router.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

/// Главная функция приложения
/// Инициализирует Firebase и запускает приложение
void main() async {
  // Обеспечиваем инициализацию Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // На вебе используем только REST API
    if (!kIsWeb) {
      await FirebaseInitializer.initialize();
      await NotificationService().initialize();
    } else {
      debugPrint('Веб-режим: используется REST API');
    }
  } catch (e) {
    debugPrint('Ошибка инициализации: $e');
  }
  
  runApp(const SmartAttendanceApp());
}

/// Главный виджет приложения
class SmartAttendanceApp extends StatelessWidget {
  const SmartAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Провайдер аутентификации (web использует REST API, mobile - Firebase)
        if (kIsWeb)
          ChangeNotifierProvider(create: (_) => WebAuthProvider())
        else
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Провайдер локализации
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        // Провайдер темы
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Провайдер языка
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        // Провайдер групп (содержит логику для работы и с Web, и с Mobile)
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        // Провайдер занятий (содержит логику для работы и с Web, и с Mobile)
        ChangeNotifierProvider(create: (_) => LessonProvider()),
      ],
      child: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (context, localeProvider, themeProvider, child) {
          return MaterialApp(
            // Настройки локализации
            locale: localeProvider.locale,
            supportedLocales: const [
              Locale('ru', 'RU'), // Русский
              Locale('en', 'US'), // Английский
              Locale('kk', 'KZ'), // Казахский
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            
            // Настройки темы
            themeMode: themeProvider.materialThemeMode,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2196F3), // Синий цвет
                brightness: Brightness.light,
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            
            // Темная тема
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2196F3),
                brightness: Brightness.dark,
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            
            // Определяем начальный экран и маршруты
            initialRoute: AppRouter.splash,
            onGenerateRoute: AppRouter.generateRoute,
            
            // Отключаем отладочный баннер
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
