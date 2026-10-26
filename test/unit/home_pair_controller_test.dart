import 'dart:async';

import 'package:aintreal_app/core/api/home_pair_api.dart';
import 'package:aintreal_app/features/home/home_pair_controller.dart';
import 'package:aintreal_app/models/home_pair.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fake API: each fetch/guess returns the next queued completer's future.
class FakeApi extends HomePairApi {
  FakeApi() : super(Dio());

  final fetches = <bool>[]; // fullPool flag per call
  final guesses = <String>[];
  final fetchResults = <Object>[]; // Completer, or an error thrown at call time
  final guessResults = <Object>[];

  int _n = 0;

  Completer<GuessResult> queueGuess() => (Completer<GuessResult>()..let(guessResults.add));
  void failFetch(Object e) => fetchResults.add(e);
  void failGuess(Object e) => guessResults.add(e);

  HomePair pair() => HomePair(leftUrl: 'l${++_n}', rightUrl: 'r$_n', pairToken: 't$_n');

  @override
  Future<HomePair> fetch({bool fullPool = false}) {
    fetches.add(fullPool);
    if (fetchResults.isEmpty) return Future.value(pair());
    final next = fetchResults.removeAt(0);
    return next is Completer<HomePair> ? next.future : Future.error(next);
  }

  @override
  Future<GuessResult> guess(String pairToken, String choice) {
    guesses.add(choice);
    if (guessResults.isEmpty) {
      return Future.value(GuessResult(correct: choice == 'left', aiSide: 'left', resultToken: 'res'));
    }
    final next = guessResults.removeAt(0);
    return next is Completer<GuessResult> ? next.future : Future.error(next);
  }
}

extension<T> on T {
  void let(void Function(T) f) => f(this);
}

const _result = GuessResult(correct: true, aiSide: 'left', resultToken: 'res');

void main() {
  late FakeApi api;
  late DateTime now;
  late HomePairController c;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = FakeApi();
    now = DateTime(2026, 10, 26, 12);
    c = HomePairController(api, clock: () => now);
  });

  Future<void> ready() async {
    await c.load();
    c.imagesLoaded(c.state.loadId);
  }

  test('load shows a pair', () async {
    await c.load();
    expect(c.state.phase, HomePairPhase.ready);
    expect(c.state.pair, isNotNull);
    expect(c.state.imagesReady, isFalse);
  });

  test('first pair is from the demo pool, later ones from the full pool', () async {
    await c.load();
    await c.load();
    expect(api.fetches, [false, true]);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(homeFirstPairSeenKey), isTrue);
  });

  test('a returning player starts on the full pool', () async {
    SharedPreferences.setMockInitialValues({homeFirstPairSeenKey: true});
    await HomePairController(api, clock: () => now).load();
    expect(api.fetches, [true]);
  });

  test('a failed first fetch keeps the next one on the demo pool', () async {
    api.failFetch(const NetworkFailure());
    await c.load();
    await c.load();
    expect(api.fetches, [false, false]);
  });

  test('guess ignored until both images loaded', () async {
    await c.load();
    await c.guess('left');
    expect(api.guesses, isEmpty);
    c.imagesLoaded(c.state.loadId);
    await c.guess('left');
    expect(api.guesses, ['left']);
  });

  test('guess reveals, and a second guess is a no-op', () async {
    await ready();
    await c.guess('left');
    expect(c.state.phase, HomePairPhase.revealed);
    expect(c.state.result!.correct, isTrue);
    expect(c.state.choice, 'left');
    await c.guess('right');
    expect(api.guesses, ['left']);
  });

  test('pending guard: two quick guesses make one call', () async {
    await ready();
    final g = api.queueGuess();
    final a = c.guess('left');
    final b = c.guess('right');
    expect(c.state.guessPending, isTrue);
    g.complete(_result);
    await Future.wait([a, b]);
    expect(api.guesses, ['left']);
  });

  test('stale response dropped', () async {
    await ready();
    final g = api.queueGuess();
    final pending = c.guess('left');
    await c.load();
    g.complete(_result);
    await pending;
    expect(c.state.phase, HomePairPhase.ready);
    expect(c.state.result, isNull);
  });

  test('expired token refreshes quietly', () async {
    await ready();
    final firstToken = c.state.pair!.pairToken;
    api.failGuess(const TokenExpired());
    await c.guess('left');
    expect(c.state.phase, HomePairPhase.ready);
    expect(c.state.error, isFalse);
    expect(c.state.pair!.pairToken, isNot(firstToken));
  });

  test('network error allows retry', () async {
    await ready();
    api.failGuess(const NetworkFailure());
    await c.guess('left');
    expect(c.state.phase, HomePairPhase.ready);
    expect(c.state.error, isTrue);
    expect(c.state.guessPending, isFalse);
    await c.guess('left');
    expect(c.state.phase, HomePairPhase.revealed);
    expect(c.state.error, isFalse);
  });

  test('resume after expiry refreshes', () async {
    await ready();
    final token = c.state.pair!.pairToken;
    await c.onResume(now.add(const Duration(minutes: 10)));
    expect(c.state.pair!.pairToken, token);
    await c.onResume(now.add(const Duration(minutes: 16)));
    expect(c.state.pair!.pairToken, isNot(token));
  });

  test('resume keeps a revealed pair', () async {
    await ready();
    await c.guess('left');
    await c.onResume(now.add(const Duration(minutes: 30)));
    expect(c.state.phase, HomePairPhase.revealed);
  });

  test('fetch failure is failed', () async {
    api.failFetch(const NetworkFailure());
    await c.load();
    expect(c.state.phase, HomePairPhase.failed);
  });

  test('leave drops a pending guess, success or failure', () async {
    for (final outcome in [_result, const NetworkFailure()]) {
      await ready();
      final g = api.queueGuess();
      final pending = c.guess('left');
      c.leave();
      final before = c.state;
      outcome is GuessResult ? g.complete(outcome) : g.completeError(outcome);
      await pending;
      expect(c.state.phase, before.phase);
      expect(c.state.result, isNull);
      expect(c.state.error, isFalse);
      expect(c.state.guessPending, isFalse);
    }
  });

  test('stale image callbacks are ignored', () async {
    await c.load();
    final old = c.state.loadId;
    await c.load();
    c.imagesLoaded(old);
    expect(c.state.imagesReady, isFalse);
    c.imageFailed(old);
    expect(c.state.phase, HomePairPhase.ready);
    c.imageFailed(c.state.loadId);
    expect(c.state.phase, HomePairPhase.failed);
  });

  test('isCurrent tracks the load id', () async {
    await c.load();
    final id = c.state.loadId;
    expect(c.isCurrent(id), isTrue);
    c.leave();
    expect(c.isCurrent(id), isFalse);
  });
}
