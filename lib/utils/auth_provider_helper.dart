import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../providers/web_auth_provider.dart';
import '../models/models.dart';

/// Helper class to work with both AuthProvider and WebAuthProvider
class AuthProviderHelper {
  /// Get the appropriate auth provider based on platform
  static dynamic getAuthProvider(BuildContext context, {bool listen = true}) {
    if (kIsWeb) {
      return Provider.of<WebAuthProvider>(context, listen: listen);
    } else {
      return Provider.of<AuthProvider>(context, listen: listen);
    }
  }

  /// Common interface methods that work with both providers
  static Future<bool> signIn(BuildContext context, {
    required String email,
    required String password,
  }) async {
    final provider = getAuthProvider(context, listen: false);
    return await provider.signIn(email: email, password: password);
  }

  static Future<bool> signUp(BuildContext context, {
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    final provider = getAuthProvider(context, listen: false);
    return await provider.signUp(
      email: email,
      password: password,
      name: name,
      role: role,
    );
  }

  static Future<void> signOut(BuildContext context) async {
    final provider = getAuthProvider(context, listen: false);
    await provider.signOut();
  }

  static bool isSignedIn(BuildContext context) {
    final provider = getAuthProvider(context, listen: false);
    return provider.isSignedIn;
  }

  static User? getUserData(BuildContext context) {
    final provider = getAuthProvider(context, listen: false);
    return provider.userData;
  }

  static String? getErrorMessage(BuildContext context) {
    final provider = getAuthProvider(context, listen: false);
    return provider.errorMessage;
  }

  static bool isLoading(BuildContext context) {
    final provider = getAuthProvider(context, listen: false);
    return provider.isLoading;
  }
}
