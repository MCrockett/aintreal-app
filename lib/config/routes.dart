import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../features/lobby/create_game_screen.dart';
import '../features/lobby/join_game_screen.dart';
import '../features/lobby/lobby_screen.dart';
import '../features/game/game_screen.dart';
import '../features/reveal/reveal_screen.dart';
import '../features/results/results_screen.dart';
import '../models/game.dart';

/// Route paths for the app.
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String createGame = '/create';
  static const String joinGame = '/join';
  static const String lobby = '/lobby/:code';
  static const String game = '/game/:code';
  static const String reveal = '/reveal/:code';
  static const String results = '/results/:code';

  /// Constructs the lobby path with a game code.
  static String lobbyPath(String code) => '/lobby/$code';

  /// Constructs the game path with a game code.
  static String gamePath(String code) => '/game/$code';

  /// Constructs the reveal path with a game code.
  static String revealPath(String code) => '/reveal/$code';

  /// Constructs the results path with a game code.
  static String resultsPath(String code) => '/results/$code';
}

/// GoRouter configuration for the app.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.createGame,
      name: 'create',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final mode = extra?['mode'] as GameMode? ?? GameMode.party;
        final playerName = extra?['playerName'] as String?;
        final rounds = extra?['rounds'] as int?;
        final timePerRound = extra?['timePerRound'] as int?;
        final speedBonus = extra?['speedBonus'] as bool?;
        final randomBonuses = extra?['randomBonuses'] as bool?;
        return CreateGameScreen(
          mode: mode,
          initialName: playerName,
          initialRounds: rounds,
          initialTimePerRound: timePerRound,
          initialSpeedBonus: speedBonus,
          initialRandomBonuses: randomBonuses,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.joinGame,
      name: 'join',
      builder: (context, state) => const JoinGameScreen(),
    ),
    GoRoute(
      path: AppRoutes.lobby,
      name: 'lobby',
      builder: (context, state) {
        final code = state.pathParameters['code']!;
        return LobbyScreen(gameCode: code);
      },
    ),
    GoRoute(
      path: AppRoutes.game,
      name: 'game',
      builder: (context, state) {
        final code = state.pathParameters['code']!;
        return GameScreen(gameCode: code);
      },
    ),
    GoRoute(
      path: AppRoutes.reveal,
      name: 'reveal',
      builder: (context, state) {
        final code = state.pathParameters['code']!;
        return RevealScreen(gameCode: code);
      },
    ),
    GoRoute(
      path: AppRoutes.results,
      name: 'results',
      builder: (context, state) {
        final code = state.pathParameters['code']!;
        return ResultsScreen(gameCode: code);
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.uri.path}'),
    ),
  ),
);
