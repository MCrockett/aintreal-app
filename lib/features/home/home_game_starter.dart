import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/api/game_api.dart';
import '../../models/game.dart';

/// Creates the Classic game that Next pair starts. Overridden in tests,
/// which have no Firebase.
class HomeGameStarter {
  const HomeGameStarter();

  Future<CreateGameResponse> start({
    required String playerName,
    required GameConfig config,
    required String firstRoundToken,
  }) async {
    // Signed-in players get stats, as on the create screen
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    return GameApi.instance.createGame(
      playerName: playerName,
      config: config,
      idToken: idToken,
      firstRoundToken: firstRoundToken,
    );
  }
}

final homeGameStarterProvider = Provider<HomeGameStarter>((ref) => const HomeGameStarter());

/// Guess-on-open analytics, injectable for tests.
class HomeAnalytics {
  const HomeAnalytics();

  void pairShown() => AnalyticsService.instance.logHomePairShown();
  void guess({required bool correct}) => AnalyticsService.instance.logHomeGuess(correct: correct);
  void gameStarted({required bool carried}) => AnalyticsService.instance.logHomeGameStarted(carried: carried);
}

final homeAnalyticsProvider = Provider<HomeAnalytics>((ref) => const HomeAnalytics());
