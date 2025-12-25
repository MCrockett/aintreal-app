import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_auth_service.dart';

/// Auth state representing the user's authentication status.
sealed class AuthState {
  const AuthState();
}

/// User is not authenticated.
class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

/// Auth state is being determined.
class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

/// User is authenticated.
class AuthStateAuthenticated extends AuthState {
  const AuthStateAuthenticated(this.user);
  final User user;

  String get displayName => user.displayName ?? user.email ?? 'Player';
  String? get email => user.email;
  String? get photoUrl => user.photoURL;
  String get uid => user.uid;
}

/// Error occurred during authentication.
class AuthStateError extends AuthState {
  const AuthStateError(this.message);
  final String message;
}

/// Notifier for managing authentication state.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authService) : super(const AuthStateLoading()) {
    _init();
  }

  final FirebaseAuthService _authService;

  void _init() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        state = AuthStateAuthenticated(user);
      } else {
        state = const AuthStateUnauthenticated();
      }
    }, onError: (error) {
      debugPrint('Auth state error: $error');
      state = AuthStateError(error.toString());
    });
  }

  /// Sign in with Google.
  Future<void> signInWithGoogle() async {
    state = const AuthStateLoading();
    try {
      final credential = await _authService.signInWithGoogle();
      state = AuthStateAuthenticated(credential.user!);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'sign-in-cancelled') {
        // User cancelled, go back to unauthenticated
        state = const AuthStateUnauthenticated();
      } else {
        state = AuthStateError(e.message);
      }
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      state = AuthStateError('Failed to sign in with Google');
    }
  }

  /// Sign in with Apple.
  Future<void> signInWithApple() async {
    state = const AuthStateLoading();
    try {
      final credential = await _authService.signInWithApple();
      state = AuthStateAuthenticated(credential.user!);
    } catch (e) {
      debugPrint('Apple sign-in error: $e');
      state = AuthStateError('Failed to sign in with Apple');
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    state = const AuthStateLoading();
    try {
      await _authService.signOut();
      state = const AuthStateUnauthenticated();
    } catch (e) {
      debugPrint('Sign out error: $e');
      state = AuthStateError('Failed to sign out');
    }
  }

  /// Clear any error state.
  void clearError() {
    if (state is AuthStateError) {
      state = const AuthStateUnauthenticated();
    }
  }
}

/// Provider for the auth service singleton.
final authServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

/// Provider for authentication state.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

/// Convenience provider for the current user (null if not authenticated).
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthStateAuthenticated) {
    return authState.user;
  }
  return null;
});

/// Convenience provider for checking if user is authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState is AuthStateAuthenticated;
});
