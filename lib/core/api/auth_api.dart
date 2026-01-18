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

/// User statistics from the backend (per-mode breakdown).
class UserStats {
  const UserStats({
    required this.party,
    required this.solo,
    required this.marathon,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      party: PartyStats.fromJson(json['party'] as Map<String, dynamic>? ?? {}),
      solo: SoloStats.fromJson(json['solo'] as Map<String, dynamic>? ?? {}),
      marathon: MarathonStats.fromJson(json['marathon'] as Map<String, dynamic>? ?? {}),
    );
  }

  final PartyStats party;
  final SoloStats solo;
  final MarathonStats marathon;
}

/// Party mode stats.
class PartyStats {
  const PartyStats({
    required this.games,
    required this.wins,
    required this.correct,
    required this.answered,
  });

  factory PartyStats.fromJson(Map<String, dynamic> json) {
    return PartyStats(
      games: json['games'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      correct: json['correct'] as int? ?? 0,
      answered: json['answered'] as int? ?? 0,
    );
  }

  final int games;
  final int wins;
  final int correct;
  final int answered;

  double get winRate => games > 0 ? (wins / games) * 100 : 0;
  double get accuracy => answered > 0 ? (correct / answered) * 100 : 0;
}

/// Solo/classic mode stats.
class SoloStats {
  const SoloStats({
    required this.games,
    required this.correct,
    required this.answered,
  });

  factory SoloStats.fromJson(Map<String, dynamic> json) {
    return SoloStats(
      games: json['games'] as int? ?? 0,
      correct: json['correct'] as int? ?? 0,
      answered: json['answered'] as int? ?? 0,
    );
  }

  final int games;
  final int correct;
  final int answered;

  double get accuracy => answered > 0 ? (correct / answered) * 100 : 0;
}

/// Marathon mode stats.
class MarathonStats {
  const MarathonStats({
    required this.attempts,
    required this.correct,
    required this.bestStreak,
    required this.perfectRuns,
  });

  factory MarathonStats.fromJson(Map<String, dynamic> json) {
    return MarathonStats(
      attempts: json['attempts'] as int? ?? 0,
      correct: json['correct'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      perfectRuns: json['perfectRuns'] as int? ?? 0,
    );
  }

  final int attempts;
  final int correct;
  final int bestStreak;
  final int perfectRuns;
}
