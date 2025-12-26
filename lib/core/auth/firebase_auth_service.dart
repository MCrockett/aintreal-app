import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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
    return await _auth.signInWithCredential(credential);
  }

  /// Sign in with Apple.
  ///
  /// Returns the [UserCredential] on success, or throws an exception on failure.
  Future<UserCredential> signInWithApple() async {
    // Generate a random nonce for security
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    debugPrint('Apple Sign-In: Starting with nonce hash: ${nonce.substring(0, 10)}...');

    // Request Apple ID credential
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    debugPrint('Apple Sign-In: Got Apple credential');
    debugPrint('Apple Sign-In: identityToken present: ${appleCredential.identityToken != null}');
    debugPrint('Apple Sign-In: identityToken length: ${appleCredential.identityToken?.length ?? 0}');
    debugPrint('Apple Sign-In: authorizationCode present: ${appleCredential.authorizationCode != null}');
    debugPrint('Apple Sign-In: userIdentifier: ${appleCredential.userIdentifier}');
    debugPrint('Apple Sign-In: email: ${appleCredential.email}');

    // Decode JWT header to see audience/issuer
    if (appleCredential.identityToken != null) {
      final parts = appleCredential.identityToken!.split('.');
      if (parts.length >= 2) {
        try {
          final payload = parts[1];
          final normalized = base64Url.normalize(payload);
          final decoded = utf8.decode(base64Url.decode(normalized));
          debugPrint('Apple Sign-In: JWT payload: $decoded');
        } catch (e) {
          debugPrint('Apple Sign-In: Could not decode JWT: $e');
        }
      }
    }

    // Create an OAuth credential from the Apple credential
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    debugPrint('Apple Sign-In: Created Firebase credential, attempting sign in...');

    // Sign in to Firebase with the Apple credential
    final userCredential = await _auth.signInWithCredential(oauthCredential);

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

    return userCredential;
  }

  /// Sign out from all providers.
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
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
