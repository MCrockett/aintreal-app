import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Service for tracking analytics events.
///
/// Tracks key user actions for understanding engagement and debugging issues.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? _analytics;

  /// Initialize the analytics service.
  Future<void> init() async {
    if (kIsWeb) return;
    _analytics = FirebaseAnalytics.instance;
  }

  /// Log a custom event.
  Future<void> _logEvent(String name, Map<String, Object>? parameters) async {
    if (_analytics == null) return;
    await _analytics!.logEvent(name: name, parameters: parameters);
  }

  // ============ Game Events ============

  /// User selected a game mode from home screen.
  Future<void> logGameModeSelected(String mode) async {
    await _logEvent('game_mode_selected', {'mode': mode});
  }

  /// User created a new game.
  Future<void> logGameCreated({
    required String mode,
    required int rounds,
    required int timeLimit,
  }) async {
    await _logEvent('game_created', {
      'mode': mode,
      'rounds': rounds,
      'time_limit': timeLimit,
    });
  }

  /// User joined an existing game.
  Future<void> logGameJoined({required bool asHost}) async {
    await _logEvent('game_joined', {'as_host': asHost});
  }

  /// Game started.
  Future<void> logGameStarted({
    required String mode,
    required int playerCount,
    required int rounds,
  }) async {
    await _logEvent('game_started', {
      'mode': mode,
      'player_count': playerCount,
      'rounds': rounds,
    });
  }

  /// Round completed.
  Future<void> logRoundCompleted({
    required String mode,
    required int roundNumber,
    required bool correct,
    required int responseTimeMs,
  }) async {
    await _logEvent('round_completed', {
      'mode': mode,
      'round': roundNumber,
      'correct': correct,
      'response_time_ms': responseTimeMs,
    });
  }

  /// Game completed.
  Future<void> logGameCompleted({
    required String mode,
    required int score,
    required int correctCount,
    required int totalRounds,
    required int rank,
    required int playerCount,
  }) async {
    await _logEvent('game_completed', {
      'mode': mode,
      'score': score,
      'correct_count': correctCount,
      'total_rounds': totalRounds,
      'accuracy': totalRounds > 0 ? (correctCount / totalRounds * 100).round() : 0,
      'rank': rank,
      'player_count': playerCount,
    });
  }

  /// Marathon ended (special case - one wrong answer ends it).
  Future<void> logMarathonEnded({
    required int roundsCompleted,
    required int score,
  }) async {
    await _logEvent('marathon_ended', {
      'rounds_completed': roundsCompleted,
      'score': score,
    });
  }

  // ============ Party Events ============

  /// User shared a party invite.
  Future<void> logPartyInviteShared() async {
    await _logEvent('party_invite_shared', null);
  }

  /// Player joined the party lobby.
  Future<void> logPlayerJoinedParty({required int playerCount}) async {
    await _logEvent('player_joined_party', {'player_count': playerCount});
  }

  // ============ Auth Events ============

  /// User signed in.
  Future<void> logSignIn(String method) async {
    await _logEvent('sign_in', {'method': method});
  }

  /// User signed out.
  Future<void> logSignOut() async {
    await _logEvent('sign_out', null);
  }

  // ============ Purchase Events ============

  /// User started ad removal purchase.
  Future<void> logPurchaseStarted(String productId) async {
    await _logEvent('purchase_started', {'product_id': productId});
  }

  /// Ad removal purchase completed.
  Future<void> logPurchaseCompleted(String productId) async {
    await _logEvent('purchase_completed', {'product_id': productId});
  }

  // ============ Error Events ============

  /// WebSocket connection failed.
  Future<void> logConnectionError(String reason) async {
    await _logEvent('connection_error', {'reason': reason});
  }
}
