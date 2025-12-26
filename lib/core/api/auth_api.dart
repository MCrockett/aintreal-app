import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'endpoints.dart';

/// API client for authentication endpoints.
class AuthApi {
  AuthApi._();

  static final AuthApi instance = AuthApi._();

  final ApiClient _client = ApiClient.instance;

  /// Authenticate with Firebase ID token.
  ///
  /// Creates or updates the user in the backend and returns user data.
  Future<AuthResponse> authenticateWithFirebase(
    String idToken, {
    String? displayName,
  }) async {
    try {
      final response = await _client.post(
        Endpoints.authFirebase,
        data: {
          'idToken': idToken,
          if (displayName != null) 'displayName': displayName,
        },
      );

      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('AuthApi.authenticateWithFirebase error: $e');
      rethrow;
    }
  }

  /// Get user profile.
  ///
  /// Requires Authorization header with Firebase ID token.
  Future<UserProfile> getProfile(String idToken) async {
    try {
      final response = await _client.get(
        Endpoints.authProfile,
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
        ),
      );

      final data = response.data as Map<String, dynamic>;
      return UserProfile.fromJson(data['user'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('AuthApi.getProfile error: $e');
      rethrow;
    }
  }

  /// Update user profile.
  ///
  /// Requires Authorization header with Firebase ID token.
  Future<UserProfile> updateProfile(
    String idToken, {
    required String displayName,
  }) async {
    try {
      final response = await _client.put(
        Endpoints.authProfile,
        data: {'displayName': displayName},
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
        ),
      );

      final data = response.data as Map<String, dynamic>;
      return UserProfile.fromJson(data['user'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('AuthApi.updateProfile error: $e');
      rethrow;
    }
  }
}

/// Response from Firebase authentication.
class AuthResponse {
  const AuthResponse({
    required this.user,
    required this.isNewUser,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
      isNewUser: json['isNewUser'] as bool? ?? false,
    );
  }

  final UserProfile user;
  final bool isNewUser;
}

/// User profile from the backend.
class UserProfile {
  const UserProfile({
    required this.id,
    this.email,
    required this.displayName,
    this.photoUrl,
    required this.provider,
    required this.stats,
    required this.createdAt,
    required this.lastLoginAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      provider: json['provider'] as String,
      stats: UserStats.fromJson(json['stats'] as Map<String, dynamic>),
      createdAt: json['createdAt'] as String,
      lastLoginAt: json['lastLoginAt'] as String,
    );
  }

  final String id;
  final String? email;
  final String displayName;
  final String? photoUrl;
  final String provider;
  final UserStats stats;
  final String createdAt;
  final String lastLoginAt;
}

/// User statistics from the backend.
class UserStats {
  const UserStats({
    required this.gamesPlayed,
    required this.gamesWon,
    required this.totalCorrect,
    required this.totalAnswered,
    required this.bestMarathonStreak,
    required this.perfectMarathons,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      gamesWon: json['gamesWon'] as int? ?? 0,
      totalCorrect: json['totalCorrect'] as int? ?? 0,
      totalAnswered: json['totalAnswered'] as int? ?? 0,
      bestMarathonStreak: json['bestMarathonStreak'] as int? ?? 0,
      perfectMarathons: json['perfectMarathons'] as int? ?? 0,
    );
  }

  final int gamesPlayed;
  final int gamesWon;
  final int totalCorrect;
  final int totalAnswered;
  final int bestMarathonStreak;
  final int perfectMarathons;

  double get accuracy =>
      totalAnswered > 0 ? (totalCorrect / totalAnswered) * 100 : 0;

  double get winRate =>
      gamesPlayed > 0 ? (gamesWon / gamesPlayed) * 100 : 0;
}
