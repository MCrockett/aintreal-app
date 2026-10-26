import 'dart:async';

import 'package:aintreal_app/config/routes.dart';
import 'package:aintreal_app/config/theme.dart';
import 'package:aintreal_app/core/api/home_pair_api.dart';
import 'package:aintreal_app/core/auth/auth_provider.dart';
import 'package:aintreal_app/features/home/home_game_starter.dart';
import 'package:aintreal_app/features/home/home_screen.dart';
import 'package:aintreal_app/features/home/widgets/home_pair_view.dart';
import 'package:aintreal_app/models/game.dart';
import 'package:aintreal_app/models/home_pair.dart';
import 'package:aintreal_app/core/api/api_exceptions.dart';
import 'package:aintreal_app/widgets/how_to_play_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeHomePairApi extends HomePairApi {
  FakeHomePairApi({this.failFetch = false}) : super(Dio());

  bool failFetch;
  int fetches = 0;

  @override
  Future<HomePair> fetch({bool fullPool = false}) async {
    fetches++;
    if (failFetch) throw const NetworkFailure();
    return HomePair(leftUrl: 'https://img/l$fetches', rightUrl: 'https://img/r$fetches', pairToken: 'tok$fetches');
  }

  @override
  Future<GuessResult> guess(String pairToken, String choice) async =>
      const GuessResult(correct: true, aiSide: 'left', resultToken: 'res');
}

/// Images "load" on the next frame, as cached_network_image would.
Widget _instantImage(String url, VoidCallback onLoaded, VoidCallback onFailed) {
  WidgetsBinding.instance.addPostFrameCallback((_) => onLoaded());
  return const ColoredBox(color: Colors.teal);
}

/// Pushed routes record where they were opened from.
final pushed = <String>[];

class FakeStarter extends HomeGameStarter {
  final calls = <(String, GameConfig, String)>[];
  Completer<CreateGameResponse>? next;
  String firstRound = 'applied';

  @override
  Future<CreateGameResponse> start({required String playerName, required GameConfig config, required String firstRoundToken}) {
    calls.add((playerName, config, firstRoundToken));
    if (next != null) return next!.future;
    return Future.value(response(firstRound));
  }

  static CreateGameResponse response(String firstRound) => CreateGameResponse.fromJson({
        'code': 'ABCD',
        'playerId': 'host1',
        'firstRound': firstRound,
        'gameState': {'code': 'ABCD', 'status': 'lobby', 'players': <dynamic>[], 'config': <String, dynamic>{}},
      });
}

class RecordingAnalytics extends HomeAnalytics {
  final events = <String>[];
  @override
  void pairShown() => events.add('shown');
  @override
  void guess({required bool correct}) => events.add('guess:$correct');
  @override
  void gameStarted({required bool carried}) => events.add('started:$carried');
}

FakeStarter starter = FakeStarter();
RecordingAnalytics analytics = RecordingAnalytics();

Widget app(FakeHomePairApi api) {
  final router = GoRouter(
    observers: [homeRouteObserver],
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: AppRoutes.createGame,
        builder: (_, state) {
          final mode = (state.extra as Map)['mode'] as GameMode;
          pushed.add('create:${mode.name}');
          return const Scaffold(body: Text('create'));
        },
      ),
      GoRoute(path: AppRoutes.joinGame, builder: (_, __) {
        pushed.add('join');
        return const Scaffold(body: Text('join'));
      }),
      GoRoute(path: '/lobby/:code', builder: (_, state) {
        final extra = state.extra as Map;
        pushed.add('lobby:${state.pathParameters['code']}:solo=${extra['isSoloMode']}');
        return const Scaffold(body: Text('lobby'));
      }),
      GoRoute(path: AppRoutes.profile, builder: (_, __) {
        pushed.add('profile');
        return const Scaffold(body: Text('profile'));
      }),
    ],
  );
  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(null),
      homePairApiProvider.overrideWithValue(api),
      pairImageBuilderProvider.overrideWithValue(_instantImage),
      homeGameStarterProvider.overrideWithValue(starter),
      homeAnalyticsProvider.overrideWithValue(analytics),
    ],
    child: MaterialApp.router(theme: AppTheme.darkTheme, routerConfig: router),
  );
}

double top(WidgetTester tester, Finder f) => tester.getTopLeft(f).dy;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'guest_name': 'TestPlayer'});
    PackageInfo.setMockInitialValues(
        appName: 'AIn\'t Real', packageName: 'com.aintreal.app', version: '1.1.0', buildNumber: '16', buildSignature: '');
    pushed.clear();
    starter = FakeStarter();
    analytics = RecordingAnalytics();
  });

  Future<void> guessLeft(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('home-pair-left')));
    await tester.pumpAndSettle();
  }

  // An iPhone 15 screen unless a test sets its own
  Future<void> pumpHome(WidgetTester tester, FakeHomePairApi api) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(api));
    await tester.pumpAndSettle();
  }

  testWidgets('order: wordmark, question, pair, hint, mode row', (tester) async {
    await pumpHome(tester, FakeHomePairApi());
    final positions = [
      top(tester, find.text('Spot the AI')),
      top(tester, find.text('Which one is AI?')),
      top(tester, find.byKey(const ValueKey('home-pair-left'))),
      top(tester, find.text("👆 Tap the image that AIn't Real")),
      top(tester, find.text('Party')),
      top(tester, find.text('Join a party · enter code')),
    ];
    expect([...positions]..sort(), positions);
    expect(find.text('▶ Next pair'), findsNothing);
  });

  testWidgets('a guess reveals the result and Next pair', (tester) async {
    await pumpHome(tester, FakeHomePairApi());
    await tester.tap(find.byKey(const ValueKey('home-pair-left')));
    await tester.pumpAndSettle();
    expect(find.text('✓ Nailed it. That one is AI.'), findsOneWidget);
    expect(find.text('▶ Next pair'), findsOneWidget);
    expect(find.text("👆 Tap the image that AIn't Real"), findsNothing);
    expect(find.text('AI'), findsWidgets);
    expect(find.text('Real'), findsOneWidget);
  });

  testWidgets('a failed load shows the retry tile and the modes still work', (tester) async {
    final api = FakeHomePairApi(failFetch: true);
    await pumpHome(tester, api);
    expect(find.text("Couldn't load a pair · Tap to retry"), findsOneWidget);
    await tester.tap(find.text('Classic'));
    await tester.pumpAndSettle();
    expect(pushed, ['create:classic']);
  });

  testWidgets('retry tile loads again', (tester) async {
    final api = FakeHomePairApi(failFetch: true);
    await pumpHome(tester, api);
    api.failFetch = false;
    await tester.tap(find.text("Couldn't load a pair · Tap to retry"));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-pair-left')), findsOneWidget);
  });

  testWidgets('mode cards and Join open the same routes as before', (tester) async {
    await pumpHome(tester, FakeHomePairApi());
    for (final label in ['Party', 'Classic', 'Marathon', 'Join a party · enter code']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(Scaffold).last)).pop();
      await tester.pumpAndSettle();
    }
    expect(pushed, ['create:party', 'create:classic', 'create:marathon', 'join']);
  });

  testWidgets('coming back to home loads a fresh pair', (tester) async {
    final api = FakeHomePairApi();
    await pumpHome(tester, api);
    expect(api.fetches, 1);
    await tester.tap(find.text('Party'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('create'))).pop();
    await tester.pumpAndSettle();
    expect(api.fetches, 2);
  });

  testWidgets('menu holds profile and How to Play; version only in test mode', (tester) async {
    await pumpHome(tester, FakeHomePairApi());
    await tester.tap(find.byKey(const ValueKey('home-menu')));
    await tester.pumpAndSettle();
    expect(find.text('Profile & settings'), findsOneWidget);
    expect(find.text('How to Play'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^v\d')), findsNothing);
    await tester.tap(find.text('Profile & settings'));
    await tester.pumpAndSettle();
    expect(pushed, ['profile']);
  });

  testWidgets('a guest can sign in from the menu', (tester) async {
    await pumpHome(tester, FakeHomePairApi());
    await tester.tap(find.byKey(const ValueKey('home-menu')));
    await tester.pumpAndSettle();
    expect(find.text('Sign in to save your stats'), findsOneWidget);
  });

  testWidgets('five taps on the subtitle toggle test mode and show the version', (tester) async {
    await pumpHome(tester, FakeHomePairApi());
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('Spot the AI'));
    }
    await tester.pumpAndSettle();
    expect(find.text('Test Mode'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-menu')));
    await tester.pumpAndSettle();
    expect(find.textContaining(RegExp(r'^v\d')), findsOneWidget);
  });

  testWidgets('the menu and dialogs keep the current pair', (tester) async {
    final api = FakeHomePairApi();
    await pumpHome(tester, api);
    await tester.tap(find.byKey(const ValueKey('home-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('How to Play'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(HowToPlayDialog))).pop();
    await tester.pumpAndSettle();
    expect(api.fetches, 1);
    await tester.tap(find.byKey(const ValueKey('home-pair-left')));
    await tester.pumpAndSettle();
    expect(find.text('▶ Next pair'), findsOneWidget);
  });

  testWidgets('first launch shows no dialog; the menu still opens How to Play', (tester) async {
    await pumpHome(tester, FakeHomePairApi());
    expect(find.byType(HowToPlayDialog), findsNothing);
    expect(find.byKey(const ValueKey('home-pair-left')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('How to Play'));
    await tester.pumpAndSettle();
    expect(find.byType(HowToPlayDialog), findsOneWidget);
  });

  group('Next pair', () {
    testWidgets('creates a Classic game with the result token and saved settings', (tester) async {
      SharedPreferences.setMockInitialValues({'guest_name': 'TestPlayer', 'classic_rounds': 8, 'classic_time_per_round': 7});
      await pumpHome(tester, FakeHomePairApi());
      await guessLeft(tester);
      await tester.tap(find.text('▶ Next pair'));
      await tester.pumpAndSettle();
      final (name, config, token) = starter.calls.single;
      expect(name, 'TestPlayer');
      expect(token, 'res');
      expect(config.mode, GameMode.classic);
      expect((config.rounds, config.timePerRound), (8, 7));
      expect(pushed, ['lobby:ABCD:solo=true']);
    });

    testWidgets('first time uses the defaults and saves them', (tester) async {
      await pumpHome(tester, FakeHomePairApi());
      await guessLeft(tester);
      await tester.tap(find.text('▶ Next pair'));
      await tester.pumpAndSettle();
      expect((starter.calls.single.$2.rounds, starter.calls.single.$2.timePerRound), (6, 5));
      final prefs = await SharedPreferences.getInstance();
      expect((prefs.getInt('classic_rounds'), prefs.getInt('classic_time_per_round')), (6, 5));
    });

    testWidgets('a double tap creates one game, with a spinner while pending', (tester) async {
      await pumpHome(tester, FakeHomePairApi());
      await guessLeft(tester);
      starter.next = Completer();
      await tester.tap(find.byKey(const ValueKey('home-next-pair')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('home-next-pair')), warnIfMissed: false);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      starter.next!.complete(FakeStarter.response('applied'));
      await tester.pumpAndSettle();
      expect(starter.calls, hasLength(1));
    });

    testWidgets('a create failure stays home with the reveal; Next pair works again', (tester) async {
      await pumpHome(tester, FakeHomePairApi());
      await guessLeft(tester);
      starter.next = Completer();
      await tester.tap(find.text('▶ Next pair'));
      await tester.pump();
      starter.next!.completeError(const ServerException('Please update the app'));
      await tester.pumpAndSettle();
      expect(find.text('Please update the app'), findsOneWidget);
      expect(find.text('✓ Nailed it. That one is AI.'), findsOneWidget);
      starter.next = null;
      await tester.tap(find.text('▶ Next pair'));
      await tester.pumpAndSettle();
      expect(pushed, ['lobby:ABCD:solo=true']);
    });

    testWidgets('an ignored token still starts the game, with no error', (tester) async {
      starter.firstRound = 'ignored';
      await pumpHome(tester, FakeHomePairApi());
      await guessLeft(tester);
      await tester.tap(find.text('▶ Next pair'));
      await tester.pumpAndSettle();
      expect(pushed, ['lobby:ABCD:solo=true']);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('leaving home after a guess creates nothing', (tester) async {
      await pumpHome(tester, FakeHomePairApi());
      await guessLeft(tester);
      await tester.tap(find.text('Party'));
      await tester.pumpAndSettle();
      expect(starter.calls, isEmpty);
    });

    for (final fails in [false, true]) {
      testWidgets('leaving during create: no lobby and no error (${fails ? 'failure' : 'success'})', (tester) async {
        await pumpHome(tester, FakeHomePairApi());
        await guessLeft(tester);
        starter.next = Completer();
        await tester.tap(find.text('▶ Next pair'));
        await tester.pump();
        await tester.tap(find.text('Join a party · enter code'));
        await tester.pumpAndSettle();
        fails
            ? starter.next!.completeError(const ServerException('boom'))
            : starter.next!.complete(FakeStarter.response('applied'));
        await tester.pumpAndSettle();
        expect(pushed, ['join']);
        expect(find.byType(SnackBar), findsNothing);
      });
    }

    testWidgets('analytics: shown once per pair, guess, started with carried', (tester) async {
      await pumpHome(tester, FakeHomePairApi());
      await guessLeft(tester);
      await tester.tap(find.text('▶ Next pair'));
      await tester.pumpAndSettle();
      expect(analytics.events, ['shown', 'guess:true', 'started:true']);
    });
  });

  for (final size in const [Size(375, 667), Size(393, 852), Size(412, 915), Size(1024, 1366)]) {
    testWidgets('fits ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(FakeHomePairApi()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final f in [
        find.text('Which one is AI?'),
        find.byKey(const ValueKey('home-pair-right')),
        find.text("👆 Tap the image that AIn't Real"),
        find.text('Marathon'),
      ]) {
        expect(tester.getBottomRight(f).dy, lessThanOrEqualTo(size.height), reason: '$f within the screen');
      }
      expect(tester.getSize(find.byKey(const ValueKey('home-pair-left'))).width, greaterThanOrEqualTo(150));
    });
  }
}
