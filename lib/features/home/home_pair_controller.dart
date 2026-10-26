import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/home_pair_api.dart';
import '../../models/home_pair.dart';

/// Set once the player has seen a home pair. The first pair after install
/// comes from the demo pool; later ones from every pair (spec D4).
const homeFirstPairSeenKey = 'home_first_pair_seen';

/// The pair token lives this long on the server.
const _tokenLife = Duration(minutes: 15);

enum HomePairPhase { loading, ready, revealed, failed }

class HomePairState {
  const HomePairState({
    this.loadId = 0,
    this.phase = HomePairPhase.loading,
    this.pair,
    this.result,
    this.choice,
    this.imagesReady = false,
    this.guessPending = false,
    this.error = false,
    this.fetchedAt,
  });

  /// Bumped on every load and on leave; responses for an older id are dropped.
  final int loadId;
  final HomePairPhase phase;
  final HomePair? pair;
  final GuessResult? result;

  /// 'left' or 'right' once guessed.
  final String? choice;
  final bool imagesReady;
  final bool guessPending;

  /// The last guess failed on the network; the player can tap again.
  final bool error;
  final DateTime? fetchedAt;

  HomePairState copyWith({
    int? loadId,
    HomePairPhase? phase,
    HomePair? pair,
    GuessResult? result,
    String? choice,
    bool? imagesReady,
    bool? guessPending,
    bool? error,
    DateTime? fetchedAt,
  }) =>
      HomePairState(
        loadId: loadId ?? this.loadId,
        phase: phase ?? this.phase,
        pair: pair ?? this.pair,
        result: result ?? this.result,
        choice: choice ?? this.choice,
        imagesReady: imagesReady ?? this.imagesReady,
        guessPending: guessPending ?? this.guessPending,
        error: error ?? this.error,
        fetchedAt: fetchedAt ?? this.fetchedAt,
      );
}

/// Guess on open: loads the home pair and checks the guess with the server.
class HomePairController extends StateNotifier<HomePairState> {
  HomePairController(this._api, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        super(const HomePairState());

  final HomePairApi _api;
  final DateTime Function() _clock;

  bool isCurrent(int loadId) => mounted && state.loadId == loadId;

  /// Fetches a new pair; the old one, and any guess in flight, are dropped.
  Future<void> load() async {
    if (!mounted) return;
    final id = state.loadId + 1;
    state = HomePairState(loadId: id);
    final prefs = await SharedPreferences.getInstance();
    final fullPool = prefs.getBool(homeFirstPairSeenKey) ?? false;
    try {
      final pair = await _api.fetch(fullPool: fullPool);
      if (!isCurrent(id)) return;
      state = HomePairState(loadId: id, phase: HomePairPhase.ready, pair: pair, fetchedAt: _clock());
      if (!fullPool) await prefs.setBool(homeFirstPairSeenKey, true);
    } on GuessFailure {
      if (isCurrent(id)) state = HomePairState(loadId: id, phase: HomePairPhase.failed);
    }
  }

  /// [side] is 'left' or 'right'.
  Future<void> guess(String side) async {
    final s = state;
    if (s.phase != HomePairPhase.ready || !s.imagesReady || s.guessPending) return;
    final id = s.loadId;
    state = s.copyWith(guessPending: true, error: false);
    try {
      final result = await _api.guess(s.pair!.pairToken, side);
      if (!isCurrent(id)) return;
      state = state.copyWith(phase: HomePairPhase.revealed, result: result, choice: side, guessPending: false);
    } on TokenExpired {
      if (isCurrent(id)) await load();
    } on GuessFailure {
      if (isCurrent(id)) state = state.copyWith(guessPending: false, error: true);
    }
  }

  /// Back from the background: an unguessed pair whose token has expired is
  /// replaced.
  Future<void> onResume(DateTime now) async {
    final fetchedAt = state.fetchedAt;
    if (state.phase == HomePairPhase.revealed || fetchedAt == null) return;
    if (now.difference(fetchedAt) > _tokenLife) await load();
  }

  /// The home route stopped being visible: drop anything in flight.
  void leave() {
    if (!mounted) return;
    state = state.copyWith(loadId: state.loadId + 1).withoutPending();
  }

  // Image builders report on every rebuild; only the first report changes state.
  void imagesLoaded(int loadId) {
    if (isCurrent(loadId) && state.phase == HomePairPhase.ready && !state.imagesReady) {
      state = state.copyWith(imagesReady: true);
    }
  }

  void imageFailed(int loadId) {
    if (isCurrent(loadId) && state.phase != HomePairPhase.failed) {
      state = HomePairState(loadId: loadId, phase: HomePairPhase.failed);
    }
  }
}

extension on HomePairState {
  HomePairState withoutPending() => HomePairState(
        loadId: loadId,
        phase: phase,
        pair: pair,
        result: result,
        choice: choice,
        imagesReady: imagesReady,
        fetchedAt: fetchedAt,
      );
}

final homePairProvider = StateNotifierProvider<HomePairController, HomePairState>(
  (ref) => HomePairController(ref.watch(homePairApiProvider)),
);
