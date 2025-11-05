import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('kk'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'Smart Attendance'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In ru, this message translates to:
  /// **'Добро пожаловать'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get login;

  /// No description provided for @register.
  ///
  /// In ru, this message translates to:
  /// **'Регистрация'**
  String get register;

  /// No description provided for @email.
  ///
  /// In ru, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите пароль'**
  String get confirmPassword;

  /// No description provided for @name.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get name;

  /// No description provided for @role.
  ///
  /// In ru, this message translates to:
  /// **'Роль'**
  String get role;

  /// No description provided for @teacher.
  ///
  /// In ru, this message translates to:
  /// **'Преподаватель'**
  String get teacher;

  /// No description provided for @student.
  ///
  /// In ru, this message translates to:
  /// **'Студент'**
  String get student;

  /// No description provided for @groups.
  ///
  /// In ru, this message translates to:
  /// **'Группы'**
  String get groups;

  /// No description provided for @students.
  ///
  /// In ru, this message translates to:
  /// **'Студенты'**
  String get students;

  /// No description provided for @lessons.
  ///
  /// In ru, this message translates to:
  /// **'Занятия'**
  String get lessons;

  /// No description provided for @attendance.
  ///
  /// In ru, this message translates to:
  /// **'Посещаемость'**
  String get attendance;

  /// No description provided for @statistics.
  ///
  /// In ru, this message translates to:
  /// **'Статистика'**
  String get statistics;

  /// No description provided for @profile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get logout;

  /// No description provided for @add.
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @search.
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In ru, this message translates to:
  /// **'Фильтр'**
  String get filter;

  /// No description provided for @export.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт'**
  String get export;

  /// No description provided for @scanQR.
  ///
  /// In ru, this message translates to:
  /// **'Сканировать QR'**
  String get scanQR;

  /// No description provided for @generateQR.
  ///
  /// In ru, this message translates to:
  /// **'Генерировать QR'**
  String get generateQR;

  /// No description provided for @present.
  ///
  /// In ru, this message translates to:
  /// **'Присутствует'**
  String get present;

  /// No description provided for @absent.
  ///
  /// In ru, this message translates to:
  /// **'Отсутствует'**
  String get absent;

  /// No description provided for @late.
  ///
  /// In ru, this message translates to:
  /// **'Опоздал'**
  String get late;

  /// No description provided for @excused.
  ///
  /// In ru, this message translates to:
  /// **'Уважительная причина'**
  String get excused;

  /// No description provided for @totalStudents.
  ///
  /// In ru, this message translates to:
  /// **'Всего студентов'**
  String get totalStudents;

  /// No description provided for @presentStudents.
  ///
  /// In ru, this message translates to:
  /// **'Присутствующих'**
  String get presentStudents;

  /// No description provided for @absentStudents.
  ///
  /// In ru, this message translates to:
  /// **'Отсутствующих'**
  String get absentStudents;

  /// No description provided for @attendanceRate.
  ///
  /// In ru, this message translates to:
  /// **'Процент посещаемости'**
  String get attendanceRate;

  /// No description provided for @today.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In ru, this message translates to:
  /// **'Эта неделя'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In ru, this message translates to:
  /// **'Этот месяц'**
  String get thisMonth;

  /// No description provided for @allTime.
  ///
  /// In ru, this message translates to:
  /// **'За все время'**
  String get allTime;

  /// No description provided for @monday.
  ///
  /// In ru, this message translates to:
  /// **'Понедельник'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In ru, this message translates to:
  /// **'Вторник'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In ru, this message translates to:
  /// **'Среда'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In ru, this message translates to:
  /// **'Четверг'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In ru, this message translates to:
  /// **'Пятница'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In ru, this message translates to:
  /// **'Суббота'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In ru, this message translates to:
  /// **'Воскресенье'**
  String get sunday;

  /// No description provided for @january.
  ///
  /// In ru, this message translates to:
  /// **'Январь'**
  String get january;

  /// No description provided for @february.
  ///
  /// In ru, this message translates to:
  /// **'Февраль'**
  String get february;

  /// No description provided for @march.
  ///
  /// In ru, this message translates to:
  /// **'Март'**
  String get march;

  /// No description provided for @april.
  ///
  /// In ru, this message translates to:
  /// **'Апрель'**
  String get april;

  /// No description provided for @may.
  ///
  /// In ru, this message translates to:
  /// **'Май'**
  String get may;

  /// No description provided for @june.
  ///
  /// In ru, this message translates to:
  /// **'Июнь'**
  String get june;

  /// No description provided for @july.
  ///
  /// In ru, this message translates to:
  /// **'Июль'**
  String get july;

  /// No description provided for @august.
  ///
  /// In ru, this message translates to:
  /// **'Август'**
  String get august;

  /// No description provided for @september.
  ///
  /// In ru, this message translates to:
  /// **'Сентябрь'**
  String get september;

  /// No description provided for @october.
  ///
  /// In ru, this message translates to:
  /// **'Октябрь'**
  String get october;

  /// No description provided for @november.
  ///
  /// In ru, this message translates to:
  /// **'Ноябрь'**
  String get november;

  /// No description provided for @december.
  ///
  /// In ru, this message translates to:
  /// **'Декабрь'**
  String get december;

  /// No description provided for @error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка'**
  String get error;

  /// No description provided for @success.
  ///
  /// In ru, this message translates to:
  /// **'Успешно'**
  String get success;

  /// No description provided for @loading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка...'**
  String get loading;

  /// No description provided for @noData.
  ///
  /// In ru, this message translates to:
  /// **'Нет данных'**
  String get noData;

  /// No description provided for @tryAgain.
  ///
  /// In ru, this message translates to:
  /// **'Попробовать снова'**
  String get tryAgain;

  /// No description provided for @invalidEmail.
  ///
  /// In ru, this message translates to:
  /// **'Неверный формат email'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In ru, this message translates to:
  /// **'Пароль слишком короткий'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In ru, this message translates to:
  /// **'Пароли не совпадают'**
  String get passwordsDoNotMatch;

  /// No description provided for @fieldRequired.
  ///
  /// In ru, this message translates to:
  /// **'Поле обязательно для заполнения'**
  String get fieldRequired;

  /// No description provided for @loginSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Вход выполнен успешно'**
  String get loginSuccess;

  /// No description provided for @loginFailed.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка входа'**
  String get loginFailed;

  /// No description provided for @registerSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Регистрация выполнена успешно'**
  String get registerSuccess;

  /// No description provided for @registerFailed.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка регистрации'**
  String get registerFailed;

  /// No description provided for @attendanceMarked.
  ///
  /// In ru, this message translates to:
  /// **'Посещаемость отмечена'**
  String get attendanceMarked;

  /// No description provided for @attendanceMarkFailed.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка отметки посещаемости'**
  String get attendanceMarkFailed;

  /// No description provided for @qrCodeGenerated.
  ///
  /// In ru, this message translates to:
  /// **'QR-код сгенерирован'**
  String get qrCodeGenerated;

  /// No description provided for @qrCodeScanned.
  ///
  /// In ru, this message translates to:
  /// **'QR-код отсканирован'**
  String get qrCodeScanned;

  /// No description provided for @invalidQRCode.
  ///
  /// In ru, this message translates to:
  /// **'Неверный QR-код'**
  String get invalidQRCode;

  /// No description provided for @permissionDenied.
  ///
  /// In ru, this message translates to:
  /// **'Разрешение отклонено'**
  String get permissionDenied;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In ru, this message translates to:
  /// **'Требуется разрешение на камеру'**
  String get cameraPermissionRequired;

  /// No description provided for @dataExported.
  ///
  /// In ru, this message translates to:
  /// **'Данные экспортированы'**
  String get dataExported;

  /// No description provided for @exportFailed.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка экспорта'**
  String get exportFailed;

  /// No description provided for @notificationScheduled.
  ///
  /// In ru, this message translates to:
  /// **'Уведомление запланировано'**
  String get notificationScheduled;

  /// No description provided for @languageChanged.
  ///
  /// In ru, this message translates to:
  /// **'Язык изменен'**
  String get languageChanged;

  /// No description provided for @themeChanged.
  ///
  /// In ru, this message translates to:
  /// **'Тема изменена'**
  String get themeChanged;

  /// No description provided for @darkMode.
  ///
  /// In ru, this message translates to:
  /// **'Темная тема'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In ru, this message translates to:
  /// **'Светлая тема'**
  String get lightMode;

  /// No description provided for @systemMode.
  ///
  /// In ru, this message translates to:
  /// **'Системная тема'**
  String get systemMode;

  /// No description provided for @appName.
  ///
  /// In ru, this message translates to:
  /// **'Smart Attendance'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In ru, this message translates to:
  /// **'Главная'**
  String get home;

  /// No description provided for @reports.
  ///
  /// In ru, this message translates to:
  /// **'Отчёты'**
  String get reports;

  /// No description provided for @createGroup.
  ///
  /// In ru, this message translates to:
  /// **'Создать группу'**
  String get createGroup;

  /// No description provided for @newLesson.
  ///
  /// In ru, this message translates to:
  /// **'Новое занятие'**
  String get newLesson;

  /// No description provided for @qrCode.
  ///
  /// In ru, this message translates to:
  /// **'QR-код'**
  String get qrCode;

  /// No description provided for @groupName.
  ///
  /// In ru, this message translates to:
  /// **'Название группы'**
  String get groupName;

  /// No description provided for @course.
  ///
  /// In ru, this message translates to:
  /// **'Курс'**
  String get course;

  /// No description provided for @year.
  ///
  /// In ru, this message translates to:
  /// **'Год обучения'**
  String get year;

  /// No description provided for @description.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get description;

  /// No description provided for @subject.
  ///
  /// In ru, this message translates to:
  /// **'Предмет'**
  String get subject;

  /// No description provided for @lessonType.
  ///
  /// In ru, this message translates to:
  /// **'Тип занятия'**
  String get lessonType;

  /// No description provided for @date.
  ///
  /// In ru, this message translates to:
  /// **'Дата'**
  String get date;

  /// No description provided for @startTime.
  ///
  /// In ru, this message translates to:
  /// **'Время начала'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In ru, this message translates to:
  /// **'Время окончания'**
  String get endTime;

  /// No description provided for @classroom.
  ///
  /// In ru, this message translates to:
  /// **'Аудитория'**
  String get classroom;

  /// No description provided for @notes.
  ///
  /// In ru, this message translates to:
  /// **'Примечания'**
  String get notes;

  /// No description provided for @lecture.
  ///
  /// In ru, this message translates to:
  /// **'Лекция'**
  String get lecture;

  /// No description provided for @practice.
  ///
  /// In ru, this message translates to:
  /// **'Практика'**
  String get practice;

  /// No description provided for @seminar.
  ///
  /// In ru, this message translates to:
  /// **'Семинар'**
  String get seminar;

  /// No description provided for @laboratory.
  ///
  /// In ru, this message translates to:
  /// **'Лабораторная'**
  String get laboratory;

  /// No description provided for @markAttendance.
  ///
  /// In ru, this message translates to:
  /// **'Отметить посещаемость'**
  String get markAttendance;

  /// No description provided for @byGroups.
  ///
  /// In ru, this message translates to:
  /// **'По группам'**
  String get byGroups;

  /// No description provided for @bySubjects.
  ///
  /// In ru, this message translates to:
  /// **'По предметам'**
  String get bySubjects;

  /// No description provided for @detailedStats.
  ///
  /// In ru, this message translates to:
  /// **'Детальная статистика'**
  String get detailedStats;

  /// No description provided for @exportToExcel.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт в Excel'**
  String get exportToExcel;

  /// No description provided for @editProfile.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать профиль'**
  String get editProfile;

  /// No description provided for @notifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get notifications;

  /// No description provided for @changeTheme.
  ///
  /// In ru, this message translates to:
  /// **'Смена темы'**
  String get changeTheme;

  /// No description provided for @changeLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Смена языка'**
  String get changeLanguage;

  /// No description provided for @help.
  ///
  /// In ru, this message translates to:
  /// **'Помощь'**
  String get help;

  /// No description provided for @about.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get about;

  /// No description provided for @lightTheme.
  ///
  /// In ru, this message translates to:
  /// **'Светлая тема'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная тема'**
  String get darkTheme;

  /// No description provided for @systemTheme.
  ///
  /// In ru, this message translates to:
  /// **'Системная тема'**
  String get systemTheme;

  /// No description provided for @english.
  ///
  /// In ru, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @russian.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get russian;

  /// No description provided for @kazakh.
  ///
  /// In ru, this message translates to:
  /// **'Қазақша'**
  String get kazakh;

  /// No description provided for @selectGroup.
  ///
  /// In ru, this message translates to:
  /// **'Выберите группу'**
  String get selectGroup;

  /// No description provided for @selectSubject.
  ///
  /// In ru, this message translates to:
  /// **'Выберите предмет'**
  String get selectSubject;

  /// No description provided for @selectDate.
  ///
  /// In ru, this message translates to:
  /// **'Выберите дату'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In ru, this message translates to:
  /// **'Выберите время'**
  String get selectTime;

  /// No description provided for @addStudents.
  ///
  /// In ru, this message translates to:
  /// **'Добавить студентов'**
  String get addStudents;

  /// No description provided for @searchStudents.
  ///
  /// In ru, this message translates to:
  /// **'Поиск студентов'**
  String get searchStudents;

  /// No description provided for @noStudentsFound.
  ///
  /// In ru, this message translates to:
  /// **'Студенты не найдены'**
  String get noStudentsFound;

  /// No description provided for @selectedStudents.
  ///
  /// In ru, this message translates to:
  /// **'Выбрано студентов'**
  String get selectedStudents;

  /// No description provided for @totalLessons.
  ///
  /// In ru, this message translates to:
  /// **'Всего занятий'**
  String get totalLessons;

  /// No description provided for @averageAttendance.
  ///
  /// In ru, this message translates to:
  /// **'Средняя посещаемость'**
  String get averageAttendance;

  /// No description provided for @excellentAttendance.
  ///
  /// In ru, this message translates to:
  /// **'Отличная посещаемость'**
  String get excellentAttendance;

  /// No description provided for @lowAttendance.
  ///
  /// In ru, this message translates to:
  /// **'Низкая посещаемость'**
  String get lowAttendance;

  /// No description provided for @upcoming.
  ///
  /// In ru, this message translates to:
  /// **'Предстоящие'**
  String get upcoming;

  /// No description provided for @past.
  ///
  /// In ru, this message translates to:
  /// **'Прошедшие'**
  String get past;

  /// No description provided for @week.
  ///
  /// In ru, this message translates to:
  /// **'Неделя'**
  String get week;

  /// No description provided for @month.
  ///
  /// In ru, this message translates to:
  /// **'Месяц'**
  String get month;

  /// No description provided for @semester.
  ///
  /// In ru, this message translates to:
  /// **'Семестр'**
  String get semester;

  /// No description provided for @year_period.
  ///
  /// In ru, this message translates to:
  /// **'Год'**
  String get year_period;

  /// No description provided for @confirmLogout.
  ///
  /// In ru, this message translates to:
  /// **'Вы уверены, что хотите выйти?'**
  String get confirmLogout;

  /// No description provided for @yes.
  ///
  /// In ru, this message translates to:
  /// **'Да'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In ru, this message translates to:
  /// **'Нет'**
  String get no;

  /// No description provided for @groupCreatedSuccessfully.
  ///
  /// In ru, this message translates to:
  /// **'Группа успешно создана'**
  String get groupCreatedSuccessfully;

  /// No description provided for @lessonCreatedSuccessfully.
  ///
  /// In ru, this message translates to:
  /// **'Занятие успешно создано'**
  String get lessonCreatedSuccessfully;

  /// No description provided for @attendanceMarkedSuccessfully.
  ///
  /// In ru, this message translates to:
  /// **'Посещаемость отмечена'**
  String get attendanceMarkedSuccessfully;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In ru, this message translates to:
  /// **'Профиль обновлён'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @fillAllFields.
  ///
  /// In ru, this message translates to:
  /// **'Заполните все поля'**
  String get fillAllFields;

  /// No description provided for @forgotPassword.
  ///
  /// In ru, this message translates to:
  /// **'Забыли пароль?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In ru, this message translates to:
  /// **'Нет аккаунта?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In ru, this message translates to:
  /// **'Уже есть аккаунт?'**
  String get alreadyHaveAccount;

  /// No description provided for @signIn.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In ru, this message translates to:
  /// **'Зарегистрироваться'**
  String get signUp;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
