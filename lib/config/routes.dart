import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/session_provider.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_screen.dart';
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

  static const String signIn = '/sign-in';
  static const String home = '/';
  static const String profile = '/profile';
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

/// Provider for the app router with auth gating.
final routerProvider = Provider<GoRouter>((ref) {
  final sessionState = ref.watch(sessionProvider);

  return GoRouter(
    initialLocation: AppRoutes.signIn,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoading = sessionState is SessionLoading;
      final hasSession = sessionState is SessionGuest || sessionState is SessionAuthenticated;
      final isOnSignIn = state.matchedLocation == AppRoutes.signIn;

      // Still loading - stay where we are
      if (isLoading) return null;

      // No session and not on sign-in -> redirect to sign-in
      if (!hasSession && !isOnSignIn) {
        return AppRoutes.signIn;
      }

      // Has session and on sign-in -> redirect to home
      if (hasSession && isOnSignIn) {
        return AppRoutes.home;
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.signIn,
        name: 'signIn',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
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
});
