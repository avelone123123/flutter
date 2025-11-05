import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Поддерживаемые языки приложения
enum AppLanguage {
  russian('ru', 'RU', 'Русский', '🇷🇺'),
  kazakh('kk', 'KZ', 'Қазақша', '🇰🇿'),
  english('en', 'US', 'English', '🇺🇸');

  const AppLanguage(this.languageCode, this.countryCode, this.displayName, this.flag);

  final String languageCode;
  final String countryCode;
  final String displayName;
  final String flag;

  /// Получение локали
  Locale get locale => Locale(languageCode, countryCode);

  /// Получение языка по коду
  static AppLanguage fromCode(String code) {
    switch (code.toLowerCase()) {
      case 'ru':
        return AppLanguage.russian;
      case 'kk':
        return AppLanguage.kazakh;
      case 'en':
        return AppLanguage.english;
      default:
        return AppLanguage.russian;
    }
  }
}

/// Провайдер для управления языком приложения
class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  
  AppLanguage _currentLanguage = AppLanguage.russian;
  bool _isInitialized = false;

  /// Текущий язык
  AppLanguage get currentLanguage => _currentLanguage;
  
  /// Текущая локаль
  Locale get locale => _currentLanguage.locale;
  
  /// Инициализирован ли провайдер
  bool get isInitialized => _isInitialized;

  /// Инициализация провайдера
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey) ?? 'ru';
      _currentLanguage = AppLanguage.fromCode(languageCode);
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _currentLanguage = AppLanguage.russian;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Установка языка
  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;
    
    try {
      _currentLanguage = language;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language.languageCode);
    } catch (e) {
      // Игнорируем ошибки сохранения
    }
  }

  /// Установка локали
  Future<void> setLocale(Locale locale) async {
    final language = AppLanguage.fromCode(locale.languageCode);
    await setLanguage(language);
  }

  /// Переключение языка
  Future<void> toggleLanguage() async {
    final languages = AppLanguage.values;
    final currentIndex = languages.indexOf(_currentLanguage);
    final nextIndex = (currentIndex + 1) % languages.length;
    await setLanguage(languages[nextIndex]);
  }

  /// Получение флага текущего языка
  String get countryFlag => _currentLanguage.flag;

  /// Получение названия текущего языка
  String get currentLanguageName => _currentLanguage.displayName;

  /// Получение кода текущего языка
  String get currentLanguageCode => _currentLanguage.languageCode;

  /// Проверка, является ли язык русским
  bool get isRussian => _currentLanguage == AppLanguage.russian;

  /// Проверка, является ли язык казахским
  bool get isKazakh => _currentLanguage == AppLanguage.kazakh;

  /// Проверка, является ли язык английским
  bool get isEnglish => _currentLanguage == AppLanguage.english;

  /// Получение списка всех поддерживаемых языков
  List<AppLanguage> get supportedLanguages => AppLanguage.values;

  /// Получение локализованного текста
  String getLocalizedText(Map<AppLanguage, String> translations) {
    return translations[_currentLanguage] ?? translations[AppLanguage.russian] ?? '';
  }

  /// Получение локализованного текста с fallback
  String getLocalizedTextWithFallback(
    Map<AppLanguage, String> translations,
    String fallback,
  ) {
    return translations[_currentLanguage] ?? 
           translations[AppLanguage.russian] ?? 
           fallback;
  }
}

/// Расширение для работы с локализацией
extension LanguageProviderExtension on LanguageProvider {
  /// Получение локализованного названия роли
  String getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'teacher':
        return getLocalizedText({
          AppLanguage.russian: 'Преподаватель',
          AppLanguage.kazakh: 'Мұғалім',
          AppLanguage.english: 'Teacher',
        });
      case 'student':
        return getLocalizedText({
          AppLanguage.russian: 'Студент',
          AppLanguage.kazakh: 'Студент',
          AppLanguage.english: 'Student',
        });
      default:
        return role;
    }
  }

  /// Получение локализованного названия статуса посещаемости
  String getAttendanceStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return getLocalizedText({
          AppLanguage.russian: 'Присутствовал',
          AppLanguage.kazakh: 'Қатысты',
          AppLanguage.english: 'Present',
        });
      case 'absent':
        return getLocalizedText({
          AppLanguage.russian: 'Отсутствовал',
          AppLanguage.kazakh: 'Қатыспады',
          AppLanguage.english: 'Absent',
        });
      case 'late':
        return getLocalizedText({
          AppLanguage.russian: 'Опоздал',
          AppLanguage.kazakh: 'Кешікті',
          AppLanguage.english: 'Late',
        });
      case 'excused':
        return getLocalizedText({
          AppLanguage.russian: 'Уважительная причина',
          AppLanguage.kazakh: 'Негізді себеп',
          AppLanguage.english: 'Excused',
        });
      default:
        return status;
    }
  }

  /// Получение локализованного названия типа занятия
  String getLessonTypeDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'lecture':
        return getLocalizedText({
          AppLanguage.russian: 'Лекция',
          AppLanguage.kazakh: 'Дәріс',
          AppLanguage.english: 'Lecture',
        });
      case 'practice':
        return getLocalizedText({
          AppLanguage.russian: 'Практика',
          AppLanguage.kazakh: 'Практика',
          AppLanguage.english: 'Practice',
        });
      case 'seminar':
        return getLocalizedText({
          AppLanguage.russian: 'Семинар',
          AppLanguage.kazakh: 'Семинар',
          AppLanguage.english: 'Seminar',
        });
      case 'laboratory':
        return getLocalizedText({
          AppLanguage.russian: 'Лабораторная',
          AppLanguage.kazakh: 'Зертханалық',
          AppLanguage.english: 'Laboratory',
        });
      default:
        return type;
    }
  }

  /// Получение локализованного названия дня недели
  String getWeekdayDisplayName(int weekday) {
    final weekdays = {
      AppLanguage.russian: ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'],
      AppLanguage.kazakh: ['Дүйсенбі', 'Сейсенбі', 'Сәрсенбі', 'Бейсенбі', 'Жұма', 'Сенбі', 'Жексенбі'],
      AppLanguage.english: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
    };

    if (weekday >= 1 && weekday <= 7) {
      return getLocalizedText({
        AppLanguage.russian: weekdays[AppLanguage.russian]![weekday - 1],
        AppLanguage.kazakh: weekdays[AppLanguage.kazakh]![weekday - 1],
        AppLanguage.english: weekdays[AppLanguage.english]![weekday - 1],
      });
    }
    return '';
  }

  /// Получение локализованного названия месяца
  String getMonthDisplayName(int month) {
    final months = {
      AppLanguage.russian: ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 
                           'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'],
      AppLanguage.kazakh: ['Қаңтар', 'Ақпан', 'Наурыз', 'Сәуір', 'Мамыр', 'Маусым',
                          'Шілде', 'Тамыз', 'Қыркүйек', 'Қазан', 'Қараша', 'Желтоқсан'],
      AppLanguage.english: ['January', 'February', 'March', 'April', 'May', 'June',
                           'July', 'August', 'September', 'October', 'November', 'December'],
    };

    if (month >= 1 && month <= 12) {
      return getLocalizedText({
        AppLanguage.russian: months[AppLanguage.russian]![month - 1],
        AppLanguage.kazakh: months[AppLanguage.kazakh]![month - 1],
        AppLanguage.english: months[AppLanguage.english]![month - 1],
      });
    }
    return '';
  }
}
