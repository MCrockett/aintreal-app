import 'package:flutter_test/flutter_test.dart';
import 'package:aintreal_app/core/websocket/game_state_provider.dart';
import 'package:aintreal_app/core/websocket/ws_client.dart';
import 'package:aintreal_app/core/websocket/ws_messages.dart';

void main() {
  group('GameStatus parsing', () {
    // Testing private function indirectly through GameState handling
    test('lobby status is default', () {
      const state = GameState();
      expect(state.status, GameStatus.lobby);
    });
  });

  group('RoundData', () {
    test('creates with required fields', () {
      final roundData = RoundData(
        round: 1,
        topUrl: '/api/images/pairs/abc/real.webp',
        bottomUrl: '/api/images/pairs/abc/ai.webp',
        aiPosition: 'bottom',
        totalRounds: 6,
      );

      expect(roundData.round, 1);
      expect(roundData.topUrl, '/api/images/pairs/abc/real.webp');
      expect(roundData.bottomUrl, '/api/images/pairs/abc/ai.webp');
      expect(roundData.aiPosition, 'bottom');
      expect(roundData.totalRounds, 6);
      expect(roundData.hasAnswered, false);
      expect(roundData.playerChoice, isNull);
      expect(roundData.answeredCount, 0);
      expect(roundData.totalPlayers, 0);
    });

    test('copyWith updates specified fields', () {
      final original = RoundData(
        round: 1,
        topUrl: '/api/images/pairs/abc/real.webp',
        bottomUrl: '/api/images/pairs/abc/ai.webp',
        aiPosition: 'bottom',
        totalRounds: 6,
      );

      final updated = original.copyWith(
        hasAnswered: true,
        playerChoice: 'top',
        answeredCount: 3,
        totalPlayers: 5,
      );

      expect(updated.round, 1);
      expect(updated.topUrl, '/api/images/pairs/abc/real.webp');
      expect(updated.hasAnswered, true);
      expect(updated.playerChoice, 'top');
      expect(updated.answeredCount, 3);
      expect(updated.totalPlayers, 5);
    });

    test('copyWith preserves unchanged fields', () {
      final original = RoundData(
        round: 3,
        topUrl: '/top.webp',
        bottomUrl: '/bottom.webp',
        aiPosition: 'top',
        totalRounds: 10,
        hasAnswered: true,
        playerChoice: 'bottom',
        answeredCount: 4,
        totalPlayers: 6,
      );

      final updated = original.copyWith(answeredCount: 5);

      expect(updated.round, 3);
      expect(updated.topUrl, '/top.webp');
      expect(updated.bottomUrl, '/bottom.webp');
      expect(updated.aiPosition, 'top');
      expect(updated.totalRounds, 10);
      expect(updated.hasAnswered, true);
      expect(updated.playerChoice, 'bottom');
      expect(updated.answeredCount, 5);
      expect(updated.totalPlayers, 6);
    });
  });

  group('RevealData', () {
    test('creates with required fields', () {
      final revealData = RevealData(
        round: 1,
        totalRounds: 6,
        aiPosition: 'top',
        topUrl: '/api/images/pairs/abc/ai.webp',
        bottomUrl: '/api/images/pairs/abc/real.webp',
        results: [
          PlayerResult(
            playerId: 'player-1',
            name: 'Alice',
            choice: 'bottom',
            correct: true,
            responseTime: 2500,
          ),
        ],
        scores: [
          PlayerScore(playerId: 'player-1', name: 'Alice', score: 100),
        ],
      );

      expect(revealData.round, 1);
      expect(revealData.totalRounds, 6);
      expect(revealData.aiPosition, 'top');
      expect(revealData.results.length, 1);
      expect(revealData.scores.length, 1);
      expect(revealData.bonus, isNull);
    });

    test('creates with optional bonus', () {
      final revealData = RevealData(
        round: 2,
        totalRounds: 6,
        aiPosition: 'bottom',
        topUrl: '/top.webp',
        bottomUrl: '/bottom.webp',
        results: [],
        scores: [],
        bonus: const RoundBonus(
          type: 'lucky_guess',
          playerId: 'player-1',
          playerName: 'Alice',
          points: 75,
        ),
      );

      expect(revealData.bonus, isNotNull);
      expect(revealData.bonus!.type, 'lucky_guess');
      expect(revealData.bonus!.points, 75);
    });
  });

  group('GameOverData', () {
    test('creates with rankings', () {
      final gameOverData = GameOverData(
        rankings: [
          FinalRanking(
            playerId: 'player-1',
            name: 'Alice',
            score: 600,
            rank: 1,
            correctAnswers: 5,
          ),
          FinalRanking(
            playerId: 'player-2',
            name: 'Bob',
            score: 400,
            rank: 2,
            correctAnswers: 4,
          ),
        ],
        totalRounds: 6,
      );

      expect(gameOverData.rankings.length, 2);
      expect(gameOverData.totalRounds, 6);
      expect(gameOverData.credits, isNull);
    });

    test('creates with photographer credits', () {
      final gameOverData = GameOverData(
        rankings: [],
        totalRounds: 6,
        credits: [
          PhotographerCredit(
            photographer: 'John Doe',
            photographerUrl: 'https://pexels.com/@johndoe',
            thumbnailUrl: 'https://example.com/thumb.jpg',
          ),
        ],
      );

      expect(gameOverData.credits, isNotNull);
      expect(gameOverData.credits!.length, 1);
      expect(gameOverData.credits![0].photographer, 'John Doe');
    });
  });

  group('GameState', () {
    test('creates with default values', () {
      const state = GameState();

      expect(state.code, isNull);
      expect(state.playerId, isNull);
      expect(state.playerName, isNull);
      expect(state.status, GameStatus.lobby);
      expect(state.players, isEmpty);
      expect(state.config, isNull);
      expect(state.currentRound, 0);
      expect(state.hostId, isNull);
      expect(state.connectionState, WsConnectionState.disconnected);
      expect(state.error, isNull);
      expect(state.roundData, isNull);
      expect(state.revealData, isNull);
      expect(state.gameOverData, isNull);
      expect(state.countdown, isNull);
    });

    test('isHost returns true when playerId matches hostId', () {
      const state = GameState(
        playerId: 'player-123',
        hostId: 'player-123',
      );

      expect(state.isHost, true);
    });

    test('isHost returns false when playerId does not match hostId', () {
      const state = GameState(
        playerId: 'player-123',
        hostId: 'player-456',
      );

      expect(state.isHost, false);
    });

    test('isHost returns false when playerId is null', () {
      const state = GameState(
        hostId: 'player-456',
      );

      expect(state.isHost, false);
    });

    test('isConnected returns true when connected', () {
      const state = GameState(
        connectionState: WsConnectionState.connected,
      );

      expect(state.isConnected, true);
    });

    test('isConnected returns false when not connected', () {
      const state = GameState(
        connectionState: WsConnectionState.disconnected,
      );

      expect(state.isConnected, false);
    });

    test('currentPlayer returns matching player', () {
      final players = <WsPlayer>[
        const WsPlayer(id: 'player-1', name: 'Alice', isHost: true),
        const WsPlayer(id: 'player-2', name: 'Bob', isHost: false),
      ];

      final state = GameState(
        playerId: 'player-2',
        players: players,
      );

      expect(state.currentPlayer, isNotNull);
      expect(state.currentPlayer!.name, 'Bob');
    });

    test('currentPlayer returns null when not found', () {
      final players = <WsPlayer>[
        const WsPlayer(id: 'player-1', name: 'Alice', isHost: false),
      ];

      final state = GameState(
        playerId: 'player-2',
        players: players,
      );

      expect(state.currentPlayer, isNull);
    });

    test('currentPlayer returns null when playerId is null', () {
      final players = <WsPlayer>[
        const WsPlayer(id: 'player-1', name: 'Alice', isHost: false),
      ];

      final state = GameState(
        players: players,
      );

      expect(state.currentPlayer, isNull);
    });

    group('copyWith', () {
      test('updates specified fields', () {
        const original = GameState();

        final updated = original.copyWith(
          code: 'ABCD',
          playerId: 'player-123',
          playerName: 'Alice',
          status: GameStatus.playing,
        );

        expect(updated.code, 'ABCD');
        expect(updated.playerId, 'player-123');
        expect(updated.playerName, 'Alice');
        expect(updated.status, GameStatus.playing);
      });

      test('preserves unchanged fields', () {
        final original = GameState(
          code: 'ABCD',
          playerId: 'player-123',
          playerName: 'Alice',
          status: GameStatus.lobby,
          players: const [WsPlayer(id: 'player-123', name: 'Alice', isHost: true)],
        );

        final updated = original.copyWith(status: GameStatus.playing);

        expect(updated.code, 'ABCD');
        expect(updated.playerId, 'player-123');
        expect(updated.playerName, 'Alice');
        expect(updated.players.length, 1);
      });

      test('clearError removes error', () {
        const original = GameState(error: 'Some error');

        final updated = original.copyWith(clearError: true);

        expect(updated.error, isNull);
      });

      test('clearRoundData removes roundData', () {
        final original = GameState(
          roundData: RoundData(
            round: 1,
            topUrl: '/top.webp',
            bottomUrl: '/bottom.webp',
            aiPosition: 'top',
            totalRounds: 6,
          ),
        );

        final updated = original.copyWith(clearRoundData: true);

        expect(updated.roundData, isNull);
      });

      test('clearRevealData removes revealData', () {
        final original = GameState(
          revealData: RevealData(
            round: 1,
            totalRounds: 6,
            aiPosition: 'top',
            topUrl: '/top.webp',
            bottomUrl: '/bottom.webp',
            results: [],
            scores: [],
          ),
        );

        final updated = original.copyWith(clearRevealData: true);

        expect(updated.revealData, isNull);
      });

      test('clearGameOverData removes gameOverData', () {
        final original = GameState(
          gameOverData: GameOverData(
            rankings: [],
            totalRounds: 6,
          ),
        );

        final updated = original.copyWith(clearGameOverData: true);

        expect(updated.gameOverData, isNull);
      });

      test('clearCountdown removes countdown', () {
        const original = GameState(countdown: 3);

        final updated = original.copyWith(clearCountdown: true);

        expect(updated.countdown, isNull);
      });
    });
  });

  group('RoundData correctness (dual contract)', () {
    RoundData oldServerRound({bool hasAnswered = false, String? playerChoice}) {
      return RoundData(
        round: 1,
        topUrl: '/top.webp',
        bottomUrl: '/bottom.webp',
        aiPosition: 'top',
        totalRounds: 6,
        hasAnswered: hasAnswered,
        playerChoice: playerChoice,
      );
    }

    RoundData newServerRound({bool hasAnswered = false, String? playerChoice}) {
      return RoundData(
        round: 1,
        topUrl: '/top.webp',
        bottomUrl: '/bottom.webp',
        aiPosition: null,
        totalRounds: 6,
        hasAnswered: hasAnswered,
        playerChoice: playerChoice,
      );
    }

    test('unanswered round has no verdict', () {
      expect(oldServerRound().isCorrect, isNull);
      expect(newServerRound().isCorrect, isNull);
    });

    test('old server: derives correctness from round_start aiPosition', () {
      expect(
        oldServerRound(hasAnswered: true, playerChoice: 'top').isCorrect,
        true,
      );
      expect(
        oldServerRound(hasAnswered: true, playerChoice: 'bottom').isCorrect,
        false,
      );
      expect(
        oldServerRound(hasAnswered: true, playerChoice: 'timeout').isCorrect,
        false,
      );
    });

    test('old server: revealedAiPosition available immediately', () {
      expect(oldServerRound().revealedAiPosition, 'top');
    });

    test('new server: verdict unknown until answer_result arrives', () {
      final answered = newServerRound(hasAnswered: true, playerChoice: 'top');
      expect(answered.isCorrect, isNull);
      expect(answered.revealedAiPosition, isNull);
    });

    test('new server: answer_result supplies verdict and aiPosition', () {
      final resolved = newServerRound(hasAnswered: true, playerChoice: 'top')
          .copyWith(resultCorrect: true, resultAiPosition: 'top');
      expect(resolved.isCorrect, true);
      expect(resolved.revealedAiPosition, 'top');
    });

    test('answer_result verdict wins over local derivation', () {
      // Server is authoritative even if the old-server fallback would disagree
      final resolved = oldServerRound(hasAnswered: true, playerChoice: 'top')
          .copyWith(resultCorrect: false, resultAiPosition: 'bottom');
      expect(resolved.isCorrect, false);
      expect(resolved.revealedAiPosition, 'bottom');
    });
  });

  group('GameStateNotifier answer_result handling', () {
    late GameStateNotifier notifier;

    setUp(() {
      notifier = GameStateNotifier();
      notifier.handleMessage(WsMessage.fromJson({
        'type': 'round_start',
        'round': 1,
        'topUrl': '/top.webp',
        'bottomUrl': '/bottom.webp',
        'totalRounds': 6,
      }));
    });

    tearDown(() {
      notifier.dispose();
    });

    test('round_start without aiPosition produces neutral round', () {
      expect(notifier.state.roundData, isNotNull);
      expect(notifier.state.roundData!.aiPosition, isNull);
      expect(notifier.state.roundData!.isCorrect, isNull);
    });

    test('answer_result resolves the current round', () {
      notifier.handleMessage(WsMessage.fromJson({
        'type': 'answer_result',
        'round': 1,
        'choice': 'top',
        'correct': true,
        'aiPosition': 'top',
      }));

      final round = notifier.state.roundData!;
      expect(round.hasAnswered, true);
      expect(round.playerChoice, 'top');
      expect(round.isCorrect, true);
      expect(round.revealedAiPosition, 'top');
    });

    test('timed-out answer_result marks round answered with no choice', () {
      notifier.handleMessage(WsMessage.fromJson({
        'type': 'answer_result',
        'round': 1,
        'choice': null,
        'correct': false,
        'timedOut': true,
        'aiPosition': 'bottom',
      }));

      final round = notifier.state.roundData!;
      expect(round.hasAnswered, true);
      expect(round.playerChoice, isNull);
      expect(round.isCorrect, false);
      expect(round.timedOut, true);
    });

    test('answer_result for a stale round is ignored', () {
      notifier.handleMessage(WsMessage.fromJson({
        'type': 'answer_result',
        'round': 99,
        'choice': 'top',
        'correct': true,
        'aiPosition': 'top',
      }));

      expect(notifier.state.roundData!.hasAnswered, false);
      expect(notifier.state.roundData!.isCorrect, isNull);
    });

    test('re-delivered answer_result is idempotent', () {
      final message = WsMessage.fromJson({
        'type': 'answer_result',
        'round': 1,
        'choice': 'bottom',
        'correct': false,
        'aiPosition': 'top',
      });
      notifier.handleMessage(message);
      notifier.handleMessage(message);

      final round = notifier.state.roundData!;
      expect(round.hasAnswered, true);
      expect(round.playerChoice, 'bottom');
      expect(round.isCorrect, false);
    });
  });

  group('GameStateNotifier roundState resync', () {
    late GameStateNotifier notifier;

    setUp(() {
      notifier = GameStateNotifier();
    });

    tearDown(() {
      notifier.dispose();
    });

    Map<String, dynamic> connectedJson({Map<String, dynamic>? roundState}) => {
          'type': 'connected',
          'playerId': 'player-123',
          'gameState': {
            'code': 'ABCD',
            'status': 'playing',
            'config': {
              'rounds': 6,
              'timePerRound': 5,
              'speedBonus': true,
              'randomBonuses': true,
              'mode': 'party',
            },
            'players': [
              {'id': 'player-123', 'name': 'Alice'},
              {'id': 'player-456', 'name': 'Bob'},
            ],
            'currentRound': 2,
          },
          'roundState': roundState,
        };

    test('connected with roundState restores mid-round state', () {
      notifier.handleMessage(WsMessage.fromJson(connectedJson(roundState: {
        'round': 3,
        'totalRounds': 6,
        'topUrl': '/top.webp',
        'bottomUrl': '/bottom.webp',
        // Deliberately different from config.timePerRound (5) to prove the
        // round-scoped value is plumbed through, not the config fallback.
        'timeSeconds': 7,
        'elapsedMs': 4200,
        'answered': false,
      })));

      expect(notifier.state.status, GameStatus.playing);
      final round = notifier.state.roundData!;
      expect(round.round, 3);
      expect(round.topUrl, '/top.webp');
      expect(round.elapsedMs, 4200);
      expect(round.timeSeconds, 7);
      expect(round.hasAnswered, false);
      expect(round.totalPlayers, 2);
    });

    test('connected roundState re-applies delivered answer_result', () {
      notifier.handleMessage(WsMessage.fromJson(connectedJson(roundState: {
        'round': 3,
        'totalRounds': 6,
        'topUrl': '/top.webp',
        'bottomUrl': '/bottom.webp',
        'timeSeconds': 5,
        'elapsedMs': 4800,
        'answered': true,
        'answerResult': {
          'type': 'answer_result',
          'round': 3,
          'choice': 'bottom',
          'correct': false,
          'aiPosition': 'top',
        },
      })));

      final round = notifier.state.roundData!;
      expect(round.hasAnswered, true);
      expect(round.playerChoice, 'bottom');
      expect(round.isCorrect, false);
      expect(round.revealedAiPosition, 'top');
    });

    test('connected without roundState leaves round data unset', () {
      notifier.handleMessage(WsMessage.fromJson(connectedJson()));
      expect(notifier.state.roundData, isNull);
    });
  });

  group('GameStateNotifier', () {
    late GameStateNotifier notifier;

    setUp(() {
      notifier = GameStateNotifier();
    });

    tearDown(() {
      notifier.dispose();
    });

    test('initial state is empty', () {
      expect(notifier.state.code, isNull);
      expect(notifier.state.playerId, isNull);
      expect(notifier.state.status, GameStatus.lobby);
    });

    test('clearError clears error state', () {
      // Simulate an error state
      notifier.state = notifier.state.copyWith(error: 'Test error');
      expect(notifier.state.error, 'Test error');

      notifier.clearError();
      expect(notifier.state.error, isNull);
    });

    test('disconnect resets state to empty', () {
      // Set some state first
      notifier.state = notifier.state.copyWith(
        code: 'ABCD',
        playerId: 'player-123',
        status: GameStatus.playing,
      );

      notifier.disconnect();

      expect(notifier.state.code, isNull);
      expect(notifier.state.playerId, isNull);
      expect(notifier.state.status, GameStatus.lobby);
    });

    test('startGame does nothing when not host', () {
      notifier.state = notifier.state.copyWith(
        playerId: 'player-1',
        hostId: 'player-2', // Different player is host
      );

      // This should not crash, just be a no-op
      notifier.startGame();
      expect(notifier.state.status, GameStatus.lobby);
    });

    test('playAgain does nothing when not host', () {
      notifier.state = notifier.state.copyWith(
        playerId: 'player-1',
        hostId: 'player-2', // Different player is host
      );

      // This should not crash, just be a no-op
      notifier.playAgain();
    });

    test('updateConfig does nothing when not host', () {
      notifier.state = notifier.state.copyWith(
        playerId: 'player-1',
        hostId: 'player-2',
      );

      // This should not crash, just be a no-op
      notifier.updateConfig({'rounds': 8});
    });

    test('submitAnswer without a connection reports failure, not answered', () {
      notifier.state = notifier.state.copyWith(
        roundData: RoundData(
          round: 1,
          topUrl: '/top.webp',
          bottomUrl: '/bottom.webp',
          aiPosition: 'top',
          totalRounds: 6,
          hasAnswered: false,
        ),
      );

      final sent = notifier.submitAnswer('bottom', 2500);

      expect(sent, false);
      expect(notifier.state.roundData!.hasAnswered, false);
      expect(notifier.state.error, isNotNull);
    });

    test('submitAnswer does nothing if already answered', () {
      notifier.state = notifier.state.copyWith(
        roundData: RoundData(
          round: 1,
          topUrl: '/top.webp',
          bottomUrl: '/bottom.webp',
          aiPosition: 'top',
          totalRounds: 6,
          hasAnswered: true,
          playerChoice: 'top',
        ),
      );

      notifier.submitAnswer('bottom', 3000);

      // Should not change the choice
      expect(notifier.state.roundData!.playerChoice, 'top');
    });

    test('leave calls disconnect', () {
      notifier.state = notifier.state.copyWith(
        code: 'ABCD',
        playerId: 'player-123',
      );

      notifier.leave();

      expect(notifier.state.code, isNull);
      expect(notifier.state.playerId, isNull);
    });
  });

  group('GameStatus enum', () {
    test('contains all expected values', () {
      expect(GameStatus.values.length, 4);
      expect(GameStatus.values.contains(GameStatus.lobby), true);
      expect(GameStatus.values.contains(GameStatus.playing), true);
      expect(GameStatus.values.contains(GameStatus.revealing), true);
      expect(GameStatus.values.contains(GameStatus.finished), true);
    });
  });

  group('Host-left detection conditions', () {
    // These test the exact conditions used in game_screen, reveal_screen,
    // and results_screen ref.listen callbacks to detect when host leaves.

    bool shouldShowHostLeftDialog(GameState previous, GameState next) {
      final hostLeft = next.error == 'Host left the game' && !next.isHost;
      final hostDisconnected = !next.isHost &&
          next.connectionState == WsConnectionState.disconnected &&
          previous.connectionState != WsConnectionState.disconnected;
      return hostLeft || hostDisconnected;
    }

    test('detects host_left error for guest', () {
      const previous = GameState(
        playerId: 'guest-1',
        hostId: 'host-1',
        connectionState: WsConnectionState.connected,
      );
      const next = GameState(
        playerId: 'guest-1',
        hostId: 'host-1',
        error: 'Host left the game',
        connectionState: WsConnectionState.connected,
      );

      expect(shouldShowHostLeftDialog(previous, next), isTrue);
    });

    test('does not trigger for host seeing own error', () {
      const previous = GameState(
        playerId: 'host-1',
        hostId: 'host-1',
        connectionState: WsConnectionState.connected,
      );
      const next = GameState(
        playerId: 'host-1',
        hostId: 'host-1',
        error: 'Host left the game',
        connectionState: WsConnectionState.connected,
      );

      expect(shouldShowHostLeftDialog(previous, next), isFalse);
    });

    test('detects disconnect for guest when previously connected', () {
      const previous = GameState(
        playerId: 'guest-1',
        hostId: 'host-1',
        connectionState: WsConnectionState.connected,
      );
      const next = GameState(
        playerId: 'guest-1',
        hostId: 'host-1',
        connectionState: WsConnectionState.disconnected,
      );

      expect(shouldShowHostLeftDialog(previous, next), isTrue);
    });

    test('does not trigger disconnect for host', () {
      const previous = GameState(
        playerId: 'host-1',
        hostId: 'host-1',
        connectionState: WsConnectionState.connected,
      );
      const next = GameState(
        playerId: 'host-1',
        hostId: 'host-1',
        connectionState: WsConnectionState.disconnected,
      );

      expect(shouldShowHostLeftDialog(previous, next), isFalse);
    });

    test('does not trigger when already disconnected', () {
      const previous = GameState(
        playerId: 'guest-1',
        hostId: 'host-1',
        connectionState: WsConnectionState.disconnected,
      );
      const next = GameState(
        playerId: 'guest-1',
        hostId: 'host-1',
        connectionState: WsConnectionState.disconnected,
      );

      expect(shouldShowHostLeftDialog(previous, next), isFalse);
    });

    test('detects disconnect from reconnecting state', () {
      const previous = GameState(
        playerId: 'guest-1',
        hostId: 'host-1',
        connectionState: WsConnectionState.reconnecting,
      );
      const next = GameState(
        playerId: 'guest-1',
        hostId: 'host-1',
        connectionState: WsConnectionState.disconnected,
      );

      expect(shouldShowHostLeftDialog(previous, next), isTrue);
    });

    test('does not trigger for unrelated errors', () {
      const previous = GameState(
        playerId: 'guest-1',
        hostId: 'host-1',
        connectionState: WsConnectionState.connected,
      );
      const next = GameState(
        playerId: 'guest-1',
        hostId: 'host-1',
        error: 'Some other error',
        connectionState: WsConnectionState.connected,
      );

      expect(shouldShowHostLeftDialog(previous, next), isFalse);
    });
  });
}
