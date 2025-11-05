import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'dart:math';
import '../models/models.dart';

/// Сервис для работы с QR-кодами
/// Отвечает за генерацию и сканирование QR-кодов для отметки посещаемости
class QRService {
  /// Генерация QR-кода для занятия
  /// [lesson] - данные занятия
  /// [size] - размер QR-кода
  Future<QrImageView> generateQRCodeForLesson(
    LessonModel lesson, {
    double size = 200.0,
  }) async {
    try {
      final qrString = lesson.qrCode;

      return QrImageView(
        data: qrString,
        version: QrVersions.auto,
        size: size,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        errorStateBuilder: (context, error) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Ошибка генерации QR-кода',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        },
      );
    } catch (e) {
      throw Exception('Ошибка генерации QR-кода: $e');
    }
  }

  /// Генерация строки QR-кода для занятия
  String generateLessonQR(String lessonId) {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomHash = random.nextInt(999999).toString().padLeft(6, '0');
    
    return 'lesson_${lessonId}_${timestamp}_$randomHash';
  }

  /// Генерация QR-кода для студента
  /// [student] - данные студента
  /// [size] - размер QR-кода
  Future<QrImageView> generateQRCodeForStudent(
    Student student, {
    double size = 200.0,
  }) async {
    try {
      final qrData = {
        'type': 'student',
        'studentId': student.id,
        'groupId': student.groupId,
        'studentNumber': student.studentId,
        'name': student.fullName,
      };

      final qrString = jsonEncode(qrData);

      return QrImageView(
        data: qrString,
        version: QrVersions.auto,
        size: size,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        errorStateBuilder: (context, error) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Ошибка генерации QR-кода',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        },
      );
    } catch (e) {
      throw Exception('Ошибка генерации QR-кода студента: $e');
    }
  }

  /// Валидация отсканированного QR-кода занятия
  /// [qrCode] - отсканированный QR-код
  Future<QRValidationResult> validateLessonQR(String qrCode) async {
    try {
      // Проверяем формат QR-кода занятия
      if (!qrCode.startsWith('lesson_')) {
        return QRValidationResult(
          isValid: false,
          errorMessage: 'Неверный формат QR-кода занятия',
        );
      }

      // Парсим QR-код
      final parts = qrCode.split('_');
      if (parts.length != 4) {
        return QRValidationResult(
          isValid: false,
          errorMessage: 'Неверный формат QR-кода занятия',
        );
      }

      final lessonId = parts[1];
      final timestamp = int.tryParse(parts[2]);
      final randomHash = parts[3];

      if (timestamp == null) {
        return QRValidationResult(
          isValid: false,
          errorMessage: 'Неверный формат времени в QR-коде',
        );
      }

      // Проверяем, не слишком ли старый QR-код
      final qrTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final timeDiff = now.difference(qrTime).inHours;
      
      if (timeDiff > 24) { // QR-код старше суток
        return QRValidationResult(
          isValid: false,
          errorMessage: 'QR-код устарел. Попросите преподавателя сгенерировать новый',
        );
      }

      return QRValidationResult(
        isValid: true,
        lessonId: lessonId,
        qrCode: qrCode,
      );
    } catch (e) {
      return QRValidationResult(
        isValid: false,
        errorMessage: 'Ошибка валидации QR-кода: $e',
      );
    }
  }

  /// Валидация отсканированного QR-кода
  /// [qrCode] - отсканированный QR-код
  /// [expectedLessonId] - ожидаемый ID занятия (опционально)
  Future<QRValidationResult> validateQRCode(
    String qrCode, {
    String? expectedLessonId,
  }) async {
    try {
      // Сначала пробуем как QR-код занятия
      if (qrCode.startsWith('lesson_')) {
        final result = await validateLessonQR(qrCode);
        if (result.isValid && expectedLessonId != null) {
          if (result.lessonId != expectedLessonId) {
            return QRValidationResult(
              isValid: false,
              errorMessage: 'QR-код не соответствует текущему занятию',
            );
          }
        }
        return result;
      }

      // Пробуем парсить как JSON
      final Map<String, dynamic> data = jsonDecode(qrCode);
      
      // Проверяем тип QR-кода
      final String type = data['type'] as String? ?? '';
      
      if (type == 'attendance') {
        return _validateAttendanceQR(data, expectedLessonId);
      } else if (type == 'student') {
        return _validateStudentQR(data);
      } else {
        return QRValidationResult(
          isValid: false,
          errorMessage: 'Неизвестный тип QR-кода',
        );
      }
    } catch (e) {
      return QRValidationResult(
        isValid: false,
        errorMessage: 'Неверный формат QR-кода: $e',
      );
    }
  }

  /// Валидация QR-кода посещаемости
  QRValidationResult _validateAttendanceQR(
    Map<String, dynamic> data,
    String? expectedLessonId,
  ) {
    try {
      // Проверяем обязательные поля
      final String? lessonId = data['lessonId'] as String?;
      final String? groupId = data['groupId'] as String?;
      final String? teacherId = data['teacherId'] as String?;
      final int? timestamp = data['timestamp'] as int?;
      final int? expiresAt = data['expiresAt'] as int?;

      if (lessonId == null || groupId == null || teacherId == null) {
        return QRValidationResult(
          isValid: false,
          errorMessage: 'QR-код содержит неполные данные',
        );
      }

      // Проверяем, соответствует ли QR-код ожидаемому занятию
      if (expectedLessonId != null && lessonId != expectedLessonId) {
        return QRValidationResult(
          isValid: false,
          errorMessage: 'QR-код не соответствует текущему занятию',
        );
      }

      // Проверяем срок действия QR-кода
      if (expiresAt != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now > expiresAt) {
          return QRValidationResult(
            isValid: false,
            errorMessage: 'QR-код истек. Время для отметки посещаемости прошло',
          );
        }
      }

      // Проверяем, не слишком ли рано сканируется QR-код
      if (timestamp != null) {
        final qrTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        final timeDiff = now.difference(qrTime).inMinutes;
        
        if (timeDiff > 60) { // QR-код старше часа
          return QRValidationResult(
            isValid: false,
            errorMessage: 'QR-код устарел. Попросите преподавателя сгенерировать новый',
          );
        }
      }

      return QRValidationResult(
        isValid: true,
        lessonId: lessonId,
        groupId: groupId,
        teacherId: teacherId,
      );
    } catch (e) {
      return QRValidationResult(
        isValid: false,
        errorMessage: 'Ошибка валидации QR-кода: $e',
      );
    }
  }

  /// Валидация QR-кода студента
  QRValidationResult _validateStudentQR(Map<String, dynamic> data) {
    try {
      final String? studentId = data['studentId'] as String?;
      final String? groupId = data['groupId'] as String?;
      final String? studentNumber = data['studentNumber'] as String?;
      final String? name = data['name'] as String?;

      if (studentId == null || groupId == null) {
        return QRValidationResult(
          isValid: false,
          errorMessage: 'QR-код студента содержит неполные данные',
        );
      }

      return QRValidationResult(
        isValid: true,
        studentId: studentId,
        groupId: groupId,
        studentNumber: studentNumber,
        studentName: name,
      );
    } catch (e) {
      return QRValidationResult(
        isValid: false,
        errorMessage: 'Ошибка валидации QR-кода студента: $e',
      );
    }
  }

  /// Создание QR-кода для быстрой отметки
  /// [lessonId] - ID занятия
  /// [groupId] - ID группы
  /// [teacherId] - ID преподавателя
  Future<String> createQuickAttendanceQR({
    required String lessonId,
    required String groupId,
    required String teacherId,
    int attendanceWindowMinutes = 15,
  }) async {
    try {
      final now = DateTime.now();
      final qrData = {
        'type': 'attendance',
        'lessonId': lessonId,
        'groupId': groupId,
        'teacherId': teacherId,
        'timestamp': now.millisecondsSinceEpoch,
        'expiresAt': now.add(Duration(minutes: attendanceWindowMinutes))
            .millisecondsSinceEpoch,
      };

      return jsonEncode(qrData);
    } catch (e) {
      throw Exception('Ошибка создания QR-кода: $e');
    }
  }

  /// Проверка разрешений камеры
  Future<bool> checkCameraPermission() async {
    // Эта функция будет реализована с использованием permission_handler
    // Пока возвращаем true для тестирования
    return true;
  }

  /// Запрос разрешения на камеру
  Future<bool> requestCameraPermission() async {
    // Эта функция будет реализована с использованием permission_handler
    // Пока возвращаем true для тестирования
    return true;
  }
}

/// Результат валидации QR-кода
class QRValidationResult {
  /// Валиден ли QR-код
  final bool isValid;
  
  /// Сообщение об ошибке (если есть)
  final String? errorMessage;
  
  /// ID занятия (для QR-кодов посещаемости)
  final String? lessonId;
  
  /// ID группы
  final String? groupId;
  
  /// ID преподавателя
  final String? teacherId;
  
  /// ID студента (для QR-кодов студентов)
  final String? studentId;
  
  /// Номер студенческого билета
  final String? studentNumber;
  
  /// Имя студента
  final String? studentName;

  /// Сам QR-код
  final String? qrCode;

  /// Конструктор результата валидации
  const QRValidationResult({
    required this.isValid,
    this.errorMessage,
    this.lessonId,
    this.groupId,
    this.teacherId,
    this.studentId,
    this.studentNumber,
    this.studentName,
    this.qrCode,
  });

  /// Проверка, является ли QR-код для посещаемости
  bool get isAttendanceQR => lessonId != null;

  /// Проверка, является ли QR-код для студента
  bool get isStudentQR => studentId != null;

  /// Проверка, является ли QR-код для занятия
  bool get isLessonQR => qrCode != null && qrCode!.startsWith('lesson_');
}
