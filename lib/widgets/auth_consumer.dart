import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/web_auth_provider.dart';
import '../models/models.dart';

/// Universal auth consumer that works with both AuthProvider and WebAuthProvider
class AuthConsumer extends StatelessWidget {
  final Widget Function(BuildContext context, dynamic authProvider, Widget? child) builder;
  final Widget? child;

  const AuthConsumer({
    Key? key,
    required this.builder,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Consumer<WebAuthProvider>(
        builder: (context, provider, child) => builder(context, provider, child),
        child: child,
      );
    } else {
      return Consumer<AuthProvider>(
        builder: (context, provider, child) => builder(context, provider, child),
        child: child,
      );
    }
  }
}

/// Helper class to provide common interface for both providers
class AuthProviderData {
  final User? userData;
  final bool isLoading;
  final String? errorMessage;
  final bool isSignedIn;
  final String? currentUserId;
  final UserRole? userRole;

  AuthProviderData({
    this.userData,
    required this.isLoading,
    this.errorMessage,
    required this.isSignedIn,
    this.currentUserId,
    this.userRole,
  });

  factory AuthProviderData.fromAuthProvider(AuthProvider provider) {
    return AuthProviderData(
      userData: provider.userData,
      isLoading: provider.isLoading,
      errorMessage: provider.errorMessage,
      isSignedIn: provider.isSignedIn,
      currentUserId: provider.currentUserId,
      userRole: provider.userRole,
    );
  }

  factory AuthProviderData.fromWebAuthProvider(WebAuthProvider provider) {
    return AuthProviderData(
      userData: provider.userData,
      isLoading: provider.isLoading,
      errorMessage: provider.errorMessage,
      isSignedIn: provider.isSignedIn,
      currentUserId: provider.currentUserId,
      userRole: provider.userRole,
    );
  }

  factory AuthProviderData.from(dynamic provider) {
    if (provider is AuthProvider) {
      return AuthProviderData.fromAuthProvider(provider);
    } else if (provider is WebAuthProvider) {
      return AuthProviderData.fromWebAuthProvider(provider);
    }
    throw Exception('Unknown provider type');
  }
}
