import 'package:aintreal_app/config/routes.dart';
import 'package:aintreal_app/config/theme.dart';
import 'package:aintreal_app/core/api/home_pair_api.dart';
import 'package:aintreal_app/core/auth/auth_provider.dart';
import 'package:aintreal_app/features/home/home_screen.dart';
import 'package:aintreal_app/features/home/widgets/home_pair_view.dart';
import 'package:aintreal_app/models/game.dart';
import 'package:aintreal_app/models/home_pair.dart';
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
  });

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
