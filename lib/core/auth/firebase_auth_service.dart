import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../config/env.dart';
import '../api/auth_api.dart';

/// Service for handling Firebase authentication with Google and Apple sign-in.
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current user, or null if not signed in.
  User? get currentUser => _auth.currentUser;

  /// Sign in with Google.
  ///
  /// Returns the [UserCredential] on success, or throws an exception on failure.
  Future<UserCredential> signInWithGoogle() async {
    // Trigger the Google Sign-In flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      throw AuthCancelledException();
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the Google credential
    final userCredential = await _auth.signInWithCredential(credential);

    // Sync with backend to create/update user record
    await _syncWithBackend(userCredential.user);

    return userCredential;
  }

  /// Sign in with Apple.
  ///
  /// Returns the [UserCredential] on success, or throws an exception on failure.
  Future<UserCredential> signInWithApple() async {
    // Generate a random nonce for security
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    // Request Apple ID credential
    debugPrint('Apple Sign-In: requesting credential...');
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    debugPrint('Apple Sign-In: got credential, identityToken=${appleCredential.identityToken != null ? 'present' : 'NULL'}');
    debugPrint('Apple Sign-In: authorizationCode=${appleCredential.authorizationCode.isNotEmpty ? 'present' : 'empty'}');

    if (appleCredential.identityToken == null) {
      throw Exception('Apple Sign-In returned null identity token');
    }

    // Create an OAuth credential from the Apple credential
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
      rawNonce: rawNonce,
    );

    // Sign in to Firebase with the Apple credential
    debugPrint('Apple Sign-In: signing in to Firebase...');
    final userCredential = await _auth.signInWithCredential(oauthCredential);
    debugPrint('Apple Sign-In: Firebase sign-in successful');

    // Apple only provides name on first sign-in, so update profile if available
    if (appleCredential.givenName != null || appleCredential.familyName != null) {
      final displayName = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].where((s) => s != null && s.isNotEmpty).join(' ');

      if (displayName.isNotEmpty) {
        await userCredential.user?.updateDisplayName(displayName);
      }
    }

    // Sync with backend to create/update user record
    await _syncWithBackend(userCredential.user);

    return userCredential;
  }

  /// Sync user with backend after sign-in.
  /// Creates or updates the user record in our database.
  Future<void> _syncWithBackend(User? user) async {
    if (user == null) return;

    try {
      final idToken = await user.getIdToken();
      if (idToken == null) return;

      await AuthApi.instance.authenticateWithFirebase(
        idToken,
        displayName: user.displayName,
      );
    } catch (_) {
      // Don't fail sign-in if backend sync fails
    }
  }

  /// Sign out from all providers.
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  /// Delete user account data from the backend.
  /// This must be called before deleting the Firebase user.
  Future<void> deleteAccountData() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user signed in');
    }

    // Get the Firebase ID token
    final idToken = await user.getIdToken();

    // Call the backend to delete account data
    final dio = Dio();
    final response = await dio.delete(
      '${Env.apiBase}/api/auth/account',
      options: Options(
        headers: {
          'Authorization': 'Bearer $idToken',
          'X-Mobile-App': Env.mobileAppSecret,
        },
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete account data: ${response.statusMessage}');
    }
  }

  /// Generate a random nonce string for Apple Sign-In.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// SHA256 hash of a string.
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

/// Exception thrown when user cancels authentication.
class AuthCancelledException implements Exception {
  @override
  String toString() => 'Authentication was cancelled by the user';
}
