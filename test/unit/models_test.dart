import 'package:flutter_test/flutter_test.dart';
import 'package:aintreal_app/models/game.dart';

void main() {
  group('GameConfig', () {
    test('creates with default values', () {
      const config = GameConfig();

      expect(config.rounds, 6);
      expect(config.timePerRound, 5);
      expect(config.speedBonus, true);
      expect(config.randomBonuses, true);
      expect(config.mode, GameMode.party);
    });

    test('creates with custom values', () {
      const config = GameConfig(
        rounds: 10,
        timePerRound: 7,
        speedBonus: false,
        randomBonuses: false,
        mode: GameMode.marathon,
      );

      expect(config.rounds, 10);
      expect(config.timePerRound, 7);
      expect(config.speedBonus, false);
      expect(config.randomBonuses, false);
      expect(config.mode, GameMode.marathon);
    });

    test('parses from JSON with defaults', () {
      final config = GameConfig.fromJson({});

      expect(config.rounds, 6);
      expect(config.timePerRound, 5);
      expect(config.speedBonus, true);
      expect(config.randomBonuses, true);
      expect(config.mode, GameMode.party);
    });

    test('parses from JSON with values', () {
      final config = GameConfig.fromJson({
        'rounds': 8,
        'timePerRound': 3,
        'speedBonus': false,
        'randomBonuses': false,
        'mode': 'classic',
      });

      expect(config.rounds, 8);
      expect(config.timePerRound, 3);
      expect(config.speedBonus, false);
      expect(config.randomBonuses, false);
      expect(config.mode, GameMode.classic);
    });

    test('parses from JSON with invalid mode', () {
      final config = GameConfig.fromJson({
        'mode': 'invalid_mode',
      });

      expect(config.mode, GameMode.party);
    });

    test('serializes to JSON', () {
      const config = GameConfig(
        rounds: 10,
        timePerRound: 7,
        speedBonus: false,
        randomBonuses: true,
        mode: GameMode.marathon,
      );

      final json = config.toJson();

      expect(json['rounds'], 10);
      expect(json['timePerRound'], 7);
      expect(json['speedBonus'], false);
      expect(json['randomBonuses'], true);
      expect(json['mode'], 'marathon');
    });

    test('copyWith updates specified fields', () {
      const original = GameConfig();

      final updated = original.copyWith(
        rounds: 12,
        mode: GameMode.classic,
      );

      expect(updated.rounds, 12);
      expect(updated.timePerRound, 5);
      expect(updated.speedBonus, true);
      expect(updated.randomBonuses, true);
      expect(updated.mode, GameMode.classic);
    });
  });

  group('GameMode', () {
    test('has all expected values', () {
      expect(GameMode.values.length, 3);
      expect(GameMode.values.contains(GameMode.party), true);
      expect(GameMode.values.contains(GameMode.classic), true);
      expect(GameMode.values.contains(GameMode.marathon), true);
    });
  });

  group('GameStatus', () {
    test('has all expected values', () {
      expect(GameStatus.values.length, 4);
      expect(GameStatus.values.contains(GameStatus.lobby), true);
      expect(GameStatus.values.contains(GameStatus.playing), true);
      expect(GameStatus.values.contains(GameStatus.revealing), true);
      expect(GameStatus.values.contains(GameStatus.finished), true);
    });
  });

  group('Player', () {
    test('creates with required fields', () {
      const player = Player(
        id: 'player-123',
        name: 'Alice',
        isHost: true,
      );

      expect(player.id, 'player-123');
      expect(player.name, 'Alice');
      expect(player.isHost, true);
      expect(player.score, 0);
      expect(player.hasAnswered, false);
    });

    test('creates with all fields', () {
      const player = Player(
        id: 'player-123',
        name: 'Alice',
        isHost: true,
        score: 500,
        hasAnswered: true,
      );

      expect(player.id, 'player-123');
      expect(player.name, 'Alice');
      expect(player.isHost, true);
      expect(player.score, 500);
      expect(player.hasAnswered, true);
    });

    test('parses from JSON with defaults', () {
      final player = Player.fromJson({
        'id': 'player-123',
        'name': 'Bob',
      });

      expect(player.id, 'player-123');
      expect(player.name, 'Bob');
      expect(player.isHost, false);
      expect(player.score, 0);
      expect(player.hasAnswered, false);
    });

    test('parses from JSON with all values', () {
      final player = Player.fromJson({
        'id': 'player-456',
        'name': 'Charlie',
        'isHost': true,
        'score': 300,
        'hasAnswered': true,
      });

      expect(player.id, 'player-456');
      expect(player.name, 'Charlie');
      expect(player.isHost, true);
      expect(player.score, 300);
      expect(player.hasAnswered, true);
    });

    test('serializes to JSON', () {
      const player = Player(
        id: 'player-123',
        name: 'Alice',
        isHost: true,
        score: 500,
        hasAnswered: true,
      );

      final json = player.toJson();

      expect(json['id'], 'player-123');
      expect(json['name'], 'Alice');
      expect(json['isHost'], true);
      expect(json['score'], 500);
      expect(json['hasAnswered'], true);
    });

    test('copyWith updates specified fields', () {
      const original = Player(
        id: 'player-123',
        name: 'Alice',
        isHost: false,
      );

      final updated = original.copyWith(
        score: 100,
        hasAnswered: true,
      );

      expect(updated.id, 'player-123');
      expect(updated.name, 'Alice');
      expect(updated.isHost, false);
      expect(updated.score, 100);
      expect(updated.hasAnswered, true);
    });
  });

  group('GameState', () {
    test('creates with required fields', () {
      final state = GameState(
        code: 'ABCD',
        status: GameStatus.lobby,
        config: const GameConfig(),
        players: const [],
      );

      expect(state.code, 'ABCD');
      expect(state.status, GameStatus.lobby);
      expect(state.config, isNotNull);
      expect(state.players, isEmpty);
      expect(state.currentRound, 0);
      expect(state.hostId, isNull);
    });

    test('parses from JSON', () {
      final state = GameState.fromJson({
        'code': 'WXYZ',
        'status': 'playing',
        'config': {
          'rounds': 8,
          'timePerRound': 5,
          'speedBonus': true,
          'randomBonuses': true,
          'mode': 'party',
        },
        'players': [
          {'id': 'player-1', 'name': 'Alice', 'isHost': true},
          {'id': 'player-2', 'name': 'Bob'},
        ],
        'currentRound': 3,
        'hostId': 'player-1',
      });

      expect(state.code, 'WXYZ');
      expect(state.status, GameStatus.playing);
      expect(state.config.rounds, 8);
      expect(state.players.length, 2);
      expect(state.players[0].name, 'Alice');
      expect(state.currentRound, 3);
      expect(state.hostId, 'player-1');
    });

    test('parses from JSON with invalid status', () {
      final state = GameState.fromJson(<String, dynamic>{
        'code': 'ABCD',
        'status': 'invalid_status',
        'config': <String, dynamic>{},
        'players': <dynamic>[],
      });

      expect(state.status, GameStatus.lobby);
    });

    test('parses from JSON with null players', () {
      final state = GameState.fromJson(<String, dynamic>{
        'code': 'ABCD',
        'status': 'lobby',
        'config': <String, dynamic>{},
      });

      expect(state.players, isEmpty);
    });

    test('serializes to JSON', () {
      final state = GameState(
        code: 'ABCD',
        status: GameStatus.playing,
        config: const GameConfig(rounds: 8),
        players: const [
          Player(id: 'player-1', name: 'Alice', isHost: true),
        ],
        currentRound: 2,
        hostId: 'player-1',
      );

      final json = state.toJson();

      expect(json['code'], 'ABCD');
      expect(json['status'], 'playing');
      expect(json['config']['rounds'], 8);
      expect((json['players'] as List).length, 1);
      expect(json['currentRound'], 2);
      expect(json['hostId'], 'player-1');
    });

    test('copyWith updates specified fields', () {
      final original = GameState(
        code: 'ABCD',
        status: GameStatus.lobby,
        config: const GameConfig(),
        players: const [],
      );

      final updated = original.copyWith(
        status: GameStatus.playing,
        currentRound: 1,
      );

      expect(updated.code, 'ABCD');
      expect(updated.status, GameStatus.playing);
      expect(updated.currentRound, 1);
    });
  });

  group('CreateGameResponse', () {
    test('parses from JSON', () {
      final response = CreateGameResponse.fromJson(<String, dynamic>{
        'code': 'ABCD',
        'playerId': 'player-123',
        'gameState': <String, dynamic>{
          'code': 'ABCD',
          'status': 'lobby',
          'config': <String, dynamic>{},
          'players': <dynamic>[],
        },
      });

      expect(response.code, 'ABCD');
      expect(response.playerId, 'player-123');
      expect(response.gameState.code, 'ABCD');
    });
  });

  group('JoinGameResponse', () {
    test('parses from JSON', () {
      final response = JoinGameResponse.fromJson(<String, dynamic>{
        'playerId': 'player-456',
        'gameState': <String, dynamic>{
          'code': 'ABCD',
          'status': 'lobby',
          'config': <String, dynamic>{},
          'players': <dynamic>[
            <String, dynamic>{'id': 'player-123', 'name': 'Alice', 'isHost': true},
            <String, dynamic>{'id': 'player-456', 'name': 'Bob'},
          ],
        },
      });

      expect(response.playerId, 'player-456');
      expect(response.gameState.code, 'ABCD');
      expect(response.gameState.players.length, 2);
    });
  });
}
