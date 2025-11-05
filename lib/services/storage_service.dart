import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Сервис для работы с Firebase Storage
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  /// Загрузка фото профиля
  Future<String> uploadProfilePhoto(
    File imageFile,
    String userId, {
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    try {
      // Сжимаем изображение
      final compressedImage = await _compressImage(
        imageFile,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      );

      // Создаём временный файл для сжатого изображения
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/compressed_${_uuid.v4()}.jpg');
      await tempFile.writeAsBytes(compressedImage);

      // Загружаем в Firebase Storage
      final fileName = 'profile_${userId}_${_uuid.v4()}.jpg';
      final ref = _storage.ref().child('profile_photos/$userId/$fileName');
      
      final uploadTask = ref.putFile(tempFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Удаляем временный файл
      await tempFile.delete();

      return downloadUrl;
    } catch (e) {
      throw Exception('Ошибка загрузки фото профиля: $e');
    }
  }

  /// Загрузка изображения из байтов
  Future<String> uploadProfilePhotoFromBytes(
    Uint8List imageBytes,
    String userId, {
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    try {
      // Сжимаем изображение
      final compressedImage = await _compressImageFromBytes(
        imageBytes,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      );

      // Создаём временный файл для сжатого изображения
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/compressed_${_uuid.v4()}.jpg');
      await tempFile.writeAsBytes(compressedImage);

      // Загружаем в Firebase Storage
      final fileName = 'profile_${userId}_${_uuid.v4()}.jpg';
      final ref = _storage.ref().child('profile_photos/$userId/$fileName');
      
      final uploadTask = ref.putFile(tempFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Удаляем временный файл
      await tempFile.delete();

      return downloadUrl;
    } catch (e) {
      throw Exception('Ошибка загрузки фото профиля: $e');
    }
  }

  /// Загрузка файла в общую папку
  Future<String> uploadFile(
    File file,
    String folderPath, {
    String? customFileName,
  }) async {
    try {
      final fileName = customFileName ?? '${_uuid.v4()}_${file.path.split('/').last}';
      final ref = _storage.ref().child('$folderPath/$fileName');
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Ошибка загрузки файла: $e');
    }
  }

  /// Загрузка файла из байтов
  Future<String> uploadFileFromBytes(
    Uint8List bytes,
    String folderPath,
    String fileName,
  ) async {
    try {
      final ref = _storage.ref().child('$folderPath/$fileName');
      
      final uploadTask = ref.putData(bytes);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Ошибка загрузки файла: $e');
    }
  }

  /// Удаление файла
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Ошибка удаления файла: $e');
    }
  }

  /// Получение метаданных файла
  Future<FullMetadata> getFileMetadata(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      return await ref.getMetadata();
    } catch (e) {
      throw Exception('Ошибка получения метаданных файла: $e');
    }
  }

  /// Скачивание файла
  Future<Uint8List> downloadFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      return await ref.getData() ?? Uint8List(0);
    } catch (e) {
      throw Exception('Ошибка скачивания файла: $e');
    }
  }

  /// Получение списка файлов в папке
  Future<List<Reference>> listFiles(String folderPath) async {
    try {
      final ref = _storage.ref().child(folderPath);
      final result = await ref.listAll();
      return result.items;
    } catch (e) {
      throw Exception('Ошибка получения списка файлов: $e');
    }
  }

  /// Сжатие изображения
  Future<Uint8List> _compressImage(
    File imageFile, {
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      return await _compressImageFromBytes(
        imageBytes,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      );
    } catch (e) {
      throw Exception('Ошибка сжатия изображения: $e');
    }
  }

  /// Сжатие изображения из байтов
  Future<Uint8List> _compressImageFromBytes(
    Uint8List imageBytes, {
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    try {
      // Декодируем изображение
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Не удалось декодировать изображение');
      }

      // Вычисляем новые размеры с сохранением пропорций
      int newWidth = image.width;
      int newHeight = image.height;

      if (image.width > maxWidth || image.height > maxHeight) {
        final aspectRatio = image.width / image.height;
        
        if (image.width > image.height) {
          newWidth = maxWidth;
          newHeight = (maxWidth / aspectRatio).round();
        } else {
          newHeight = maxHeight;
          newWidth = (maxHeight * aspectRatio).round();
        }
      }

      // Изменяем размер изображения
      final resizedImage = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );

      // Кодируем в JPEG с заданным качеством
      final compressedBytes = img.encodeJpg(resizedImage, quality: quality);
      
      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      throw Exception('Ошибка сжатия изображения: $e');
    }
  }

  /// Создание миниатюры изображения
  Future<Uint8List> createThumbnail(
    Uint8List imageBytes, {
    int thumbnailSize = 200,
  }) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Не удалось декодировать изображение');
      }

      // Создаём квадратную миниатюру
      final thumbnail = img.copyResizeCropSquare(
        image,
        size: thumbnailSize,
        interpolation: img.Interpolation.linear,
      );

      final thumbnailBytes = img.encodeJpg(thumbnail, quality: 80);
      return Uint8List.fromList(thumbnailBytes);
    } catch (e) {
      throw Exception('Ошибка создания миниатюры: $e');
    }
  }

  /// Получение размера файла в байтах
  Future<int> getFileSize(String fileUrl) async {
    try {
      final metadata = await getFileMetadata(fileUrl);
      return metadata.size ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Получение размера файла в читаемом формате
  Future<String> getFileSizeFormatted(String fileUrl) async {
    try {
      final sizeInBytes = await getFileSize(fileUrl);
      return _formatFileSize(sizeInBytes);
    } catch (e) {
      return 'Неизвестно';
    }
  }

  /// Форматирование размера файла
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Проверка существования файла
  Future<bool> fileExists(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Получение URL для загрузки файла
  Future<String> getDownloadUrl(String filePath) async {
    try {
      final ref = _storage.ref().child(filePath);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Ошибка получения URL для скачивания: $e');
    }
  }

  /// Копирование файла
  Future<String> copyFile(String sourceUrl, String destinationPath) async {
    try {
      final sourceRef = _storage.refFromURL(sourceUrl);
      final destinationRef = _storage.ref().child(destinationPath);
      
      await destinationRef.putData(await sourceRef.getData() ?? Uint8List(0));
      return await destinationRef.getDownloadURL();
    } catch (e) {
      throw Exception('Ошибка копирования файла: $e');
    }
  }
}
