import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/models.dart';
import '../services/services.dart';

/// Провайдер для управления состоянием аутентификации
/// Отвечает за вход, регистрацию и управление текущим пользователем
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final LocalDatabaseService _localDatabaseService = LocalDatabaseService();

  // Состояние аутентификации
  firebase_auth.User? _currentUser;
  User? _userData;
  bool _isLoading = false;
  String? _errorMessage;

  // Геттеры
  firebase_auth.User? get currentUser => _currentUser;
  User? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSignedIn => _currentUser != null;
  String? get currentUserId => _currentUser?.uid;
  UserRole? get userRole => _userData?.role;

  /// Инициализация провайдера
  /// Проверяет, авторизован ли пользователь при запуске приложения
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // Слушаем изменения состояния аутентификации
      _authService.authStateChanges.listen((firebase_auth.User? user) async {
        _currentUser = user;
        if (user != null) {
          // Загружаем данные пользователя
          await _loadUserData(user.uid);
        } else {
          _userData = null;
        }
        notifyListeners();
      });

      // Проверяем текущего пользователя
      _currentUser = _authService.currentUser;
      if (_currentUser != null) {
        await _loadUserData(_currentUser!.uid);
      }
    } catch (e) {
      _setError('Ошибка инициализации: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Загрузка данных пользователя
  Future<void> _loadUserData(String userId) async {
    try {
      // Сначала пытаемся загрузить из локальной базы
      _userData = await _localDatabaseService.getUser(userId);
      
      // Затем загружаем из Firebase и обновляем локальную базу
      final firebaseUserData = await _authService.getUserData(userId);
      if (firebaseUserData != null) {
        _userData = firebaseUserData;
        await _localDatabaseService.saveUser(firebaseUserData);
      }
    } catch (e) {
      print('Ошибка загрузки данных пользователя: $e');
    }
  }

  /// Регистрация нового пользователя
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final user = await _authService.signUp(
        email: email,
        name: name,
        password: password,
        role: role,
      );

      if (user != null) {
        _currentUser = user;
        await _loadUserData(user.uid);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Вход пользователя
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final user = await _authService.signIn(
        email: email,
        password: password,
      );

      if (user != null) {
        _currentUser = user;
        await _loadUserData(user.uid);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Выход пользователя
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _currentUser = null;
      _userData = null;
      notifyListeners();
    } catch (e) {
      _setError('Ошибка выхода: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Сброс пароля
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Обновление данных пользователя
  Future<bool> updateUserData(User updatedUser) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.updateUserData(updatedUser.id, updatedUser);
      _userData = updatedUser;
      
      // Сохраняем в локальную базу
      await _localDatabaseService.saveUser(updatedUser);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Ошибка обновления данных: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Изменение пароля
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Удаление аккаунта
  Future<bool> deleteAccount() async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.deleteAccount();
      _currentUser = null;
      _userData = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Ошибка удаления аккаунта: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Проверка, является ли пользователь преподавателем
  bool get isTeacher => _userData?.role == UserRole.teacher;

  /// Проверка, является ли пользователь студентом
  bool get isStudent => _userData?.role == UserRole.student;

  /// Получение имени пользователя
  String get userName => _userData?.name ?? _currentUser?.displayName ?? 'Пользователь';

  /// Получение email пользователя
  String get userEmail => _userData?.email ?? _currentUser?.email ?? '';

  /// Установка состояния загрузки
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Установка сообщения об ошибке
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Очистка сообщения об ошибке
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Очистка ошибки (публичный метод)
  void clearError() {
    _clearError();
  }

  /// Обновление данных пользователя из Firebase
  Future<void> refreshUserData() async {
    if (_currentUser != null) {
      await _loadUserData(_currentUser!.uid);
      notifyListeners();
    }
  }
}
