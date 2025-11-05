import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'api_service.dart';

/// Web-compatible authentication service using REST API
/// Used on web platform instead of Firebase
class WebAuthService {
  final ApiService _apiService = ApiService();
  
  User? _currentUser;
  String? _currentToken;

  User? get currentUser => _currentUser;
  String? get currentToken => _currentToken;
  bool get isSignedIn => _currentUser != null;

  /// Initialize and restore session if token exists
  Future<void> initialize() async {
    try {
      if (_apiService.token != null) {
        final userData = await _apiService.getCurrentUser();
        _currentUser = User.fromJson(userData);
      }
    } catch (e) {
      debugPrint('Session restore failed: $e');
      _currentUser = null;
      _currentToken = null;
    }
  }

  /// Sign up new user
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      final response = await _apiService.register(
        email: email,
        password: password,
        name: name,
        role: role.toString().split('.').last,
      );

      _currentToken = response['token'];
      _apiService.setToken(_currentToken!);
      
      final userData = response['user'];
      _currentUser = User.fromJson({
        'id': userData['id'],
        'email': userData['email'],
        'name': userData['name'],
        'role': userData['role'],
        'createdAt': userData['createdAt'],
      });

      return _currentUser;
    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }

  /// Sign in existing user
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔑 WebAuthService: Starting sign in for $email');
      
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      debugPrint('✅ WebAuthService: Got response from API');
      
      _currentToken = response['token'];
      _apiService.setToken(_currentToken!);
      
      final userData = response['user'];
      _currentUser = User.fromJson({
        'id': userData['id'],
        'email': userData['email'],
        'name': userData['name'],
        'role': userData['role'],
        'createdAt': userData['createdAt'],
      });

      debugPrint('✅ WebAuthService: User signed in successfully: ${_currentUser?.name}');
      return _currentUser;
    } catch (e) {
      debugPrint('❌ WebAuthService sign in error: $e');
      rethrow;
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      _apiService.logout();
      _currentUser = null;
      _currentToken = null;
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  /// Get user data by ID
  Future<User?> getUserData(String userId) async {
    try {
      final userData = await _apiService.getCurrentUser();
      return User.fromJson(userData);
    } catch (e) {
      debugPrint('Get user data error: $e');
      return null;
    }
  }
}
