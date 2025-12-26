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

    test('submitAnswer updates local state optimistically', () {
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

      notifier.submitAnswer('bottom', 2500);

      expect(notifier.state.roundData!.hasAnswered, true);
      expect(notifier.state.roundData!.playerChoice, 'bottom');
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
}
