import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

/// Сервис аутентификации
/// Отвечает за вход, регистрацию и управление пользователями
class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получение текущего пользователя
  firebase_auth.User? get currentUser => _auth.currentUser;

  /// Поток изменений состояния аутентификации
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  /// Регистрация нового пользователя
  /// [email] - email пользователя
  /// [password] - пароль
  /// [name] - имя пользователя
  /// [role] - роль пользователя (teacher/student)
  Future<firebase_auth.User?> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      // Создаем пользователя в Firebase Auth
      final firebase_auth.UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebase_auth.User? user = userCredential.user;
      if (user != null) {
        // Обновляем отображаемое имя
        await user.updateDisplayName(name);

        // Создаем запись пользователя в Firestore
        final userData = User(
          id: user.uid,
          email: email,
          name: name,
          role: role,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userData.toJson());

        return user;
      }
      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Ошибка регистрации: $e');
    }
  }

  /// Вход пользователя
  /// [email] - email пользователя
  /// [password] - пароль
  Future<firebase_auth.User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final firebase_auth.UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebase_auth.User? user = userCredential.user;
      if (user != null) {
        // Обновляем время последнего входа
        await _updateLastLogin(user.uid);
        return user;
      }
      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Ошибка входа: $e');
    }
  }

  /// Выход пользователя
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Ошибка выхода: $e');
    }
  }

  /// Сброс пароля
  /// [email] - email пользователя
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Ошибка сброса пароля: $e');
    }
  }

  /// Получение данных пользователя из Firestore
  /// [userId] - идентификатор пользователя
  Future<User?> getUserData(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        return User.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения данных пользователя: $e');
    }
  }

  /// Обновление данных пользователя
  /// [userId] - идентификатор пользователя
  /// [userData] - новые данные пользователя
  Future<void> updateUserData(String userId, User userData) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update(userData.toJson());
    } catch (e) {
      throw Exception('Ошибка обновления данных пользователя: $e');
    }
  }

  /// Обновление времени последнего входа
  Future<void> _updateLastLogin(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'lastLoginAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Не критичная ошибка, просто логируем
      print('Ошибка обновления времени входа: $e');
    }
  }

  /// Проверка, авторизован ли пользователь
  bool get isSignedIn => currentUser != null;

  /// Получение ID текущего пользователя
  String? get currentUserId => currentUser?.uid;

  /// Удаление аккаунта пользователя
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user != null) {
        // Удаляем данные пользователя из Firestore
        await _firestore.collection('users').doc(user.uid).delete();
        
        // Удаляем аккаунт из Firebase Auth
        await user.delete();
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Ошибка удаления аккаунта: $e');
    }
  }

  /// Изменение пароля
  /// [currentPassword] - текущий пароль
  /// [newPassword] - новый пароль
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = currentUser;
      if (user != null) {
        // Переаутентифицируем пользователя
        final credential = firebase_auth.EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);
        
        // Обновляем пароль
        await user.updatePassword(newPassword);
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Ошибка изменения пароля: $e');
    }
  }

  /// Обработка исключений Firebase Auth
  String _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Пользователь с таким email не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'email-already-in-use':
        return 'Пользователь с таким email уже существует';
      case 'weak-password':
        return 'Пароль слишком слабый';
      case 'invalid-email':
        return 'Неверный формат email';
      case 'user-disabled':
        return 'Аккаунт заблокирован';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже';
      case 'operation-not-allowed':
        return 'Операция не разрешена';
      case 'requires-recent-login':
        return 'Требуется повторная авторизация';
      default:
        return 'Ошибка аутентификации: ${e.message}';
    }
  }
}
