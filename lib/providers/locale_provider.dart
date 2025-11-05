import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Провайдер для управления локализацией приложения
/// Отвечает за переключение языков и сохранение выбранного языка
class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'selected_locale';
  
  Locale _locale = const Locale('ru', 'RU'); // По умолчанию русский
  bool _isLoading = false;

  // Геттеры
  Locale get locale => _locale;
  bool get isLoading => _isLoading;
  String get languageCode => _locale.languageCode;
  String get countryCode => _locale.countryCode ?? '';

  /// Инициализация провайдера
  /// Загружает сохраненный язык из SharedPreferences
  Future<void> initialize() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocaleCode = prefs.getString(_localeKey);
      
      if (savedLocaleCode != null) {
        _locale = Locale(savedLocaleCode);
      }
    } catch (e) {
      print('Ошибка загрузки настроек локализации: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Изменение языка приложения
  /// [newLocale] - новый локаль
  Future<void> changeLocale(Locale newLocale) async {
    _setLoading(true);
    try {
      _locale = newLocale;
      
      // Сохраняем выбор в SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, newLocale.languageCode);
      
      notifyListeners();
    } catch (e) {
      print('Ошибка изменения языка: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Переключение на русский язык
  Future<void> setRussian() async {
    await changeLocale(const Locale('ru', 'RU'));
  }

  /// Переключение на казахский язык
  Future<void> setKazakh() async {
    await changeLocale(const Locale('kk', 'KZ'));
  }

  /// Переключение на английский язык
  Future<void> setEnglish() async {
    await changeLocale(const Locale('en', 'US'));
  }

  /// Переключение языка (циклически между русским, казахским и английским)
  Future<void> toggleLanguage() async {
    if (_locale.languageCode == 'ru') {
      await setKazakh();
    } else if (_locale.languageCode == 'kk') {
      await setEnglish();
    } else {
      await setRussian();
    }
  }

  /// Получение названия текущего языка
  String get currentLanguageName {
    switch (_locale.languageCode) {
      case 'ru':
        return 'Русский';
      case 'kk':
        return 'Қазақша';
      case 'en':
        return 'English';
      default:
        return 'Русский';
    }
  }

  /// Получение названия языка по коду
  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'ru':
        return 'Русский';
      case 'kk':
        return 'Қазақша';
      case 'en':
        return 'English';
      default:
        return 'Русский';
    }
  }

  /// Проверка, является ли текущий язык русским
  bool get isRussian => _locale.languageCode == 'ru';

  /// Проверка, является ли текущий язык казахским
  bool get isKazakh => _locale.languageCode == 'kk';

  /// Проверка, является ли текущий язык английским
  bool get isEnglish => _locale.languageCode == 'en';

  /// Получение флага страны для текущего языка
  String get countryFlag {
    switch (_locale.languageCode) {
      case 'ru':
        return '🇷🇺';
      case 'kk':
        return '🇰🇿';
      case 'en':
        return '🇺🇸';
      default:
        return '🇷🇺';
    }
  }

  /// Получение списка поддерживаемых языков
  static List<Map<String, String>> get supportedLanguages => [
    {
      'code': 'ru',
      'name': 'Русский',
      'flag': '🇷🇺',
      'nativeName': 'Русский',
    },
    {
      'code': 'kk',
      'name': 'Қазақша',
      'flag': '🇰🇿',
      'nativeName': 'Қазақша',
    },
    {
      'code': 'en',
      'name': 'English',
      'flag': '🇺🇸',
      'nativeName': 'English',
    },
  ];

  /// Получение локали по коду языка
  static Locale getLocaleFromCode(String languageCode) {
    switch (languageCode) {
      case 'ru':
        return const Locale('ru', 'RU');
      case 'kk':
        return const Locale('kk', 'KZ');
      case 'en':
        return const Locale('en', 'US');
      default:
        return const Locale('ru', 'RU');
    }
  }

  /// Сброс к языку по умолчанию
  Future<void> resetToDefault() async {
    await changeLocale(const Locale('ru', 'RU'));
  }

  /// Установка состояния загрузки
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Получение формата даты для текущего языка
  String getDateFormat() {
    switch (_locale.languageCode) {
      case 'ru':
        return 'dd.MM.yyyy';
      case 'kk':
        return 'dd.MM.yyyy';
      case 'en':
        return 'MM/dd/yyyy';
      default:
        return 'dd.MM.yyyy';
    }
  }

  /// Получение формата времени для текущего языка
  String getTimeFormat() {
    switch (_locale.languageCode) {
      case 'ru':
        return 'HH:mm';
      case 'kk':
        return 'HH:mm';
      case 'en':
        return 'hh:mm a';
      default:
        return 'HH:mm';
    }
  }

  /// Получение названий дней недели для текущего языка
  List<String> getWeekdayNames() {
    switch (_locale.languageCode) {
      case 'ru':
        return [
          'Понедельник',
          'Вторник',
          'Среда',
          'Четверг',
          'Пятница',
          'Суббота',
          'Воскресенье',
        ];
      case 'kk':
        return [
          'Дүйсенбі',
          'Сейсенбі',
          'Сәрсенбі',
          'Бейсенбі',
          'Жұма',
          'Сенбі',
          'Жексенбі',
        ];
      default:
        return [
          'Понедельник',
          'Вторник',
          'Среда',
          'Четверг',
          'Пятница',
          'Суббота',
          'Воскресенье',
        ];
    }
  }

  /// Получение названий месяцев для текущего языка
  List<String> getMonthNames() {
    switch (_locale.languageCode) {
      case 'ru':
        return [
          'Январь',
          'Февраль',
          'Март',
          'Апрель',
          'Май',
          'Июнь',
          'Июль',
          'Август',
          'Сентябрь',
          'Октябрь',
          'Ноябрь',
          'Декабрь',
        ];
      case 'kk':
        return [
          'Қаңтар',
          'Ақпан',
          'Наурыз',
          'Сәуір',
          'Мамыр',
          'Маусым',
          'Шілде',
          'Тамыз',
          'Қыркүйек',
          'Қазан',
          'Қараша',
          'Желтоқсан',
        ];
      default:
        return [
          'Январь',
          'Февраль',
          'Март',
          'Апрель',
          'Май',
          'Июнь',
          'Июль',
          'Август',
          'Сентябрь',
          'Октябрь',
          'Ноябрь',
          'Декабрь',
        ];
    }
  }
}
