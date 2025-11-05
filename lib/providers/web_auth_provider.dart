import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/web_auth_service.dart';
import '../services/api_service.dart';

/// Web-compatible auth provider using REST API
class WebAuthProvider extends ChangeNotifier {
  final WebAuthService _webAuthService = WebAuthService();
  final ApiService _apiService = ApiService();

  // State
  User? _userData;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSignedIn => _userData != null;
  String? get currentUserId => _userData?.id;
  UserRole? get userRole => _userData?.role;

  /// Получение имени пользователя
  String get userName => _userData?.name ?? 'Пользователь';

  /// Получение email пользователя
  String get userEmail => _userData?.email ?? '';

  /// Initialize provider
  Future<void> initialize() async {
    _isLoading = true;
    try {
      await _webAuthService.initialize();
      _userData = _webAuthService.currentUser;
    } catch (e) {
      _errorMessage = 'Ошибка инициализации: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign up new user
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final user = await _webAuthService.signUp(
        email: email,
        password: password,
        name: name,
        role: role,
      );

      if (user != null) {
        _userData = user;
        _setLoading(false);
        notifyListeners();
        return true;
      }

      _setError('Ошибка регистрации');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  /// Sign in user
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    debugPrint('🚀 WebAuthProvider: signIn called for $email');
    _setLoading(true);
    _setError(null);

    try {
      debugPrint('📞 WebAuthProvider: Calling webAuthService.signIn');
      
      final user = await _webAuthService.signIn(
        email: email,
        password: password,
      );

      debugPrint('📦 WebAuthProvider: Got user: ${user?.name}');

      if (user != null) {
        _userData = user;
        debugPrint('✅ WebAuthProvider: Sign in successful, setting userData');
        _setLoading(false);
        notifyListeners();
        return true;
      }

      debugPrint('⚠️ WebAuthProvider: User is null');
      _setError('Ошибка входа');
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('❌ WebAuthProvider: Sign in failed with error: $e');
      _setError(_getErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _webAuthService.signOut();
      _userData = null;
    } catch (e) {
      _setError('Ошибка выхода: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Reset password (not implemented for API)
  Future<bool> resetPassword({required String email}) async {
    _setError('Функция сброса пароля доступна только в мобильном приложении');
    return false;
  }

  /// Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    if (message != null) {
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('invalid credentials')) {
      return 'Неверный email или пароль';
    } else if (errorStr.contains('already exists')) {
      return 'Пользователь с таким email уже существует';
    } else if (errorStr.contains('network')) {
      return 'Ошибка сети. Проверьте подключение';
    } else if (errorStr.contains('server')) {
      return 'Ошибка сервера. Попробуйте позже';
    }
    
    return 'Произошла ошибка: $error';
  }
}
