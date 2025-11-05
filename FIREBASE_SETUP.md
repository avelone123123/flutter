# Инструкция по настройке Firebase для Smart Attendance

## Шаг 1: Создание проекта Firebase

1. Перейдите на https://console.firebase.google.com/
2. Нажмите "Создать проект"
3. Введите название проекта: `smart-attendance`
4. Отключите Google Analytics (не обязательно)
5. Нажмите "Создать проект"

## Шаг 2: Настройка Android приложения

1. В консоли Firebase нажмите "Добавить приложение" → Android
2. Введите Package name: `com.smartattendance.app`
3. Введите App nickname: `Smart Attendance Android`
4. Нажмите "Зарегистрировать приложение"
5. Скачайте файл `google-services.json`
6. Замените файл `android/app/google-services.json` на скачанный файл

## Шаг 3: Настройка iOS приложения (опционально)

1. В консоли Firebase нажмите "Добавить приложение" → iOS
2. Введите Bundle ID: `com.smartattendance.app`
3. Введите App nickname: `Smart Attendance iOS`
4. Нажмите "Зарегистрировать приложение"
5. Скачайте файл `GoogleService-Info.plist`
6. Поместите файл в папку `ios/Runner/`

## Шаг 4: Включение сервисов Firebase

### Authentication
1. В консоли Firebase перейдите в "Authentication"
2. Нажмите "Начать"
3. Перейдите на вкладку "Sign-in method"
4. Включите "Email/Password"

### Firestore Database
1. В консоли Firebase перейдите в "Firestore Database"
2. Нажмите "Создать базу данных"
3. Выберите "Начать в тестовом режиме"
4. Выберите ближайший регион
5. Нажмите "Готово"

## Шаг 5: Настройка правил безопасности Firestore

Замените правила в Firestore на следующие:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Пользователи могут читать и писать только свои данные
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Группы доступны только преподавателям
    match /groups/{groupId} {
      allow read, write: if request.auth != null && 
        resource.data.teacherId == request.auth.uid;
    }
    
    // Занятия доступны преподавателям группы
    match /lessons/{lessonId} {
      allow read, write: if request.auth != null && 
        exists(/databases/$(database)/documents/groups/$(resource.data.groupId)) &&
        get(/databases/$(database)/documents/groups/$(resource.data.groupId)).data.teacherId == request.auth.uid;
    }
    
    // Посещаемость доступна преподавателям и студентам группы
    match /attendance/{attendanceId} {
      allow read, write: if request.auth != null && (
        // Преподаватель группы
        exists(/databases/$(database)/documents/lessons/$(resource.data.lessonId)) &&
        exists(/databases/$(database)/documents/groups/$(get(/databases/$(database)/documents/lessons/$(resource.data.lessonId)).data.groupId)) &&
        get(/databases/$(database)/documents/groups/$(get(/databases/$(database)/documents/lessons/$(resource.data.lessonId)).data.groupId)).data.teacherId == request.auth.uid ||
        // Студент группы
        resource.data.studentId == request.auth.uid
      );
    }
  }
}
```

## Шаг 6: Проверка настройки

После выполнения всех шагов:
1. Запустите приложение: `flutter run`
2. Проверьте, что Firebase инициализируется без ошибок
3. Попробуйте зарегистрировать пользователя

## Возможные проблемы и решения

### Ошибка "Firebase not initialized"
- Убедитесь, что файл `google-services.json` находится в `android/app/`
- Проверьте, что в `android/app/build.gradle.kts` добавлен plugin `com.google.gms.google-services`

### Ошибка "Permission denied"
- Проверьте правила безопасности Firestore
- Убедитесь, что пользователь авторизован

### Ошибка сборки Android
- Выполните `flutter clean`
- Выполните `flutter pub get`
- Попробуйте собрать заново: `flutter build apk`
