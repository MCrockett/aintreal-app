import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:aintreal_app/core/websocket/ws_messages.dart';

void main() {
  group('WsMessage parsing', () {
    group('parseMessageType', () {
      test('parses connected message', () {
        expect(parseMessageType('connected'), WsMessageType.connectionEstablished);
      });

      test('parses player_joined message', () {
        expect(parseMessageType('player_joined'), WsMessageType.playerJoined);
      });

      test('parses player_connected message', () {
        expect(parseMessageType('player_connected'), WsMessageType.playerJoined);
      });

      test('parses player_left message', () {
        expect(parseMessageType('player_left'), WsMessageType.playerLeft);
      });

      test('parses player_disconnected message', () {
        expect(parseMessageType('player_disconnected'), WsMessageType.playerLeft);
      });

      test('parses game_state message', () {
        expect(parseMessageType('game_state'), WsMessageType.gameState);
      });

      test('parses config_updated message', () {
        expect(parseMessageType('config_updated'), WsMessageType.configUpdated);
      });

      test('parses game_starting message', () {
        expect(parseMessageType('game_starting'), WsMessageType.gameStarting);
      });

      test('parses round_start message', () {
        expect(parseMessageType('round_start'), WsMessageType.roundStart);
      });

      test('parses player_answered message', () {
        expect(parseMessageType('player_answered'), WsMessageType.playerAnswered);
      });

      test('parses early_click_warning message', () {
        expect(parseMessageType('early_click_warning'), WsMessageType.earlyClickWarning);
      });

      test('parses reveal message', () {
        expect(parseMessageType('reveal'), WsMessageType.reveal);
      });

      test('parses round_reveal message', () {
        expect(parseMessageType('round_reveal'), WsMessageType.reveal);
      });

      test('parses marathon_ended message', () {
        expect(parseMessageType('marathon_ended'), WsMessageType.marathonEnded);
      });

      test('parses game_over message', () {
        expect(parseMessageType('game_over'), WsMessageType.gameOver);
      });

      test('parses return_to_lobby message', () {
        expect(parseMessageType('return_to_lobby'), WsMessageType.returnToLobby);
      });

      test('parses host_left message', () {
        expect(parseMessageType('host_left'), WsMessageType.hostLeft);
      });

      test('parses error message', () {
        expect(parseMessageType('error'), WsMessageType.error);
      });

      test('parses unknown message types', () {
        expect(parseMessageType('unknown_type'), WsMessageType.unknown);
        expect(parseMessageType(''), WsMessageType.unknown);
      });
    });

    group('ConnectionEstablishedMessage', () {
      test('parses from JSON correctly', () {
        final json = {
          'type': 'connected',
          'playerId': 'player-123',
        };

        final message = WsMessage.fromJson(json) as ConnectionEstablishedMessage;
        expect(message.playerId, 'player-123');
        expect(message.gameState, isNull);
      });

      test('parses with gameState', () {
        final json = {
          'type': 'connected',
          'playerId': 'player-123',
          'gameState': {
            'code': 'ABCD',
            'status': 'lobby',
            'config': {
              'rounds': 6,
              'timePerRound': 5,
              'speedBonus': true,
              'randomBonuses': true,
              'mode': 'party',
            },
            'players': [],
            'currentRound': 0,
          },
        };

        final message = WsMessage.fromJson(json) as ConnectionEstablishedMessage;
        expect(message.playerId, 'player-123');
        expect(message.gameState, isNotNull);
        expect(message.gameState!.code, 'ABCD');
      });
    });

    group('RoundStartMessage', () {
      test('parses from JSON correctly', () {
        final json = {
          'type': 'round_start',
          'round': 1,
          'topUrl': '/api/images/pairs/abc/real.webp',
          'bottomUrl': '/api/images/pairs/abc/ai.webp',
          'aiPosition': 'bottom',
          'totalRounds': 6,
        };

        final message = WsMessage.fromJson(json) as RoundStartMessage;
        expect(message.round, 1);
        expect(message.topUrl, '/api/images/pairs/abc/real.webp');
        expect(message.bottomUrl, '/api/images/pairs/abc/ai.webp');
        expect(message.aiPosition, 'bottom');
        expect(message.totalRounds, 6);
      });
    });

    group('PlayerAnsweredMessage', () {
      test('parses from JSON correctly', () {
        final json = {
          'type': 'player_answered',
          'playerId': 'player-123',
          'answeredCount': 3,
          'totalPlayers': 5,
        };

        final message = WsMessage.fromJson(json) as PlayerAnsweredMessage;
        expect(message.playerId, 'player-123');
        expect(message.answeredCount, 3);
        expect(message.totalPlayers, 5);
      });
    });

    group('EarlyClickWarningMessage', () {
      test('parses from JSON correctly', () {
        final json = {
          'type': 'early_click_warning',
          'message': 'Too early! No speed bonus.',
        };

        final message = WsMessage.fromJson(json) as EarlyClickWarningMessage;
        expect(message.message, 'Too early! No speed bonus.');
      });

      test('uses default message when not provided', () {
        final json = {
          'type': 'early_click_warning',
        };

        final message = WsMessage.fromJson(json) as EarlyClickWarningMessage;
        expect(message.message, 'Too early! No speed bonus this round.');
      });
    });

    group('RevealMessage', () {
      test('parses from JSON correctly', () {
        final json = {
          'type': 'reveal',
          'round': 1,
          'totalRounds': 6,
          'aiPosition': 'top',
          'topUrl': '/api/images/pairs/abc/real.webp',
          'bottomUrl': '/api/images/pairs/abc/ai.webp',
          'results': [
            {
              'playerId': 'player-1',
              'name': 'Alice',
              'choice': 'top',
              'isCorrect': true,
              'responseTime': 2500,
              'rank': 1,
              'rankBonus': 50,
              'speedBonus': 30,
            },
          ],
          'scores': [
            {
              'id': 'player-1',
              'name': 'Alice',
              'score': 180,
            },
          ],
        };

        final message = WsMessage.fromJson(json) as RevealMessage;
        expect(message.round, 1);
        expect(message.totalRounds, 6);
        expect(message.aiPosition, 'top');
        expect(message.results.length, 1);
        expect(message.results[0].playerId, 'player-1');
        expect(message.results[0].correct, true);
        expect(message.results[0].rankBonus, 50);
        expect(message.scores.length, 1);
        expect(message.scores[0].score, 180);
      });
    });

    group('PlayerResult', () {
      test('calculates points correctly', () {
        final result = PlayerResult(
          playerId: 'player-1',
          name: 'Alice',
          choice: 'top',
          correct: true,
          responseTime: 2500,
          rank: 1,
          rankBonus: 50,
          speedBonus: 30,
          streakBonus: 30,
        );

        // 100 (correct) + 50 (rank) + 30 (speed) + 30 (streak) = 210
        expect(result.points, 210);
      });

      test('calculates zero points when incorrect', () {
        final result = PlayerResult(
          playerId: 'player-1',
          name: 'Alice',
          choice: 'top',
          correct: false,
          responseTime: 2500,
        );

        expect(result.points, 0);
      });

      test('hasBonus returns true when bonuses exist', () {
        final result = PlayerResult(
          playerId: 'player-1',
          name: 'Alice',
          choice: 'top',
          correct: true,
          responseTime: 2500,
          speedBonus: 30,
        );

        expect(result.hasBonus, true);
      });

      test('hasBonus returns false when no bonuses', () {
        final result = PlayerResult(
          playerId: 'player-1',
          name: 'Alice',
          choice: 'top',
          correct: true,
          responseTime: 2500,
        );

        expect(result.hasBonus, false);
      });
    });

    group('GameOverMessage', () {
      test('parses from JSON correctly', () {
        final json = {
          'type': 'game_over',
          'rankings': [
            {
              'id': 'player-1',
              'name': 'Alice',
              'score': 600,
              'rank': 1,
              'correct': 5,
              'avgResponseTime': 3500,
              'bestStreak': 3,
            },
            {
              'id': 'player-2',
              'name': 'Bob',
              'score': 400,
              'rank': 2,
              'correct': 4,
            },
          ],
          'totalRounds': 6,
        };

        final message = WsMessage.fromJson(json) as GameOverMessage;
        expect(message.rankings.length, 2);
        expect(message.rankings[0].name, 'Alice');
        expect(message.rankings[0].score, 600);
        expect(message.rankings[0].rank, 1);
        expect(message.rankings[0].correctAnswers, 5);
        expect(message.rankings[0].avgResponseTime, 3500);
        expect(message.rankings[0].bestStreak, 3);
        expect(message.totalRounds, 6);
      });

      test('parses with photographer credits', () {
        final json = {
          'type': 'game_over',
          'rankings': [],
          'totalRounds': 6,
          'credits': [
            {
              'photographer': 'John Doe',
              'photographer_url': 'https://pexels.com/@johndoe',
              'thumbnail_url': 'https://example.com/thumb.jpg',
            },
          ],
        };

        final message = WsMessage.fromJson(json) as GameOverMessage;
        expect(message.credits, isNotNull);
        expect(message.credits!.length, 1);
        expect(message.credits![0].photographer, 'John Doe');
      });
    });

    group('MarathonEndedMessage', () {
      test('parses successful marathon', () {
        final json = {
          'type': 'marathon_ended',
          'streak': 26,
          'totalRounds': 26,
          'completed': true,
          'avgResponseTime': 3200,
        };

        final message = WsMessage.fromJson(json) as MarathonEndedMessage;
        expect(message.streak, 26);
        expect(message.completed, true);
        expect(message.avgResponseTime, 3200);
      });

      test('parses failed marathon', () {
        final json = {
          'type': 'marathon_ended',
          'streak': 15,
          'totalRounds': 26,
          'completed': false,
          'failedRound': 16,
          'topUrl': '/api/images/pairs/abc/real.webp',
          'bottomUrl': '/api/images/pairs/abc/ai.webp',
          'aiPosition': 'top',
          'playerChoice': 'bottom',
        };

        final message = WsMessage.fromJson(json) as MarathonEndedMessage;
        expect(message.streak, 15);
        expect(message.completed, false);
        expect(message.failedRound, 16);
        expect(message.playerChoice, 'bottom');
      });
    });

    group('WsGameConfig', () {
      test('parses from JSON with defaults', () {
        final json = <String, dynamic>{};
        final config = WsGameConfig.fromJson(json);

        expect(config.rounds, 6);
        expect(config.timePerRound, 5);
        expect(config.speedBonus, true);
        expect(config.randomBonuses, true);
        expect(config.mode, 'party');
      });

      test('parses from JSON with values', () {
        final json = {
          'rounds': 10,
          'timePerRound': 7,
          'speedBonus': false,
          'randomBonuses': false,
          'mode': 'marathon',
        };
        final config = WsGameConfig.fromJson(json);

        expect(config.rounds, 10);
        expect(config.timePerRound, 7);
        expect(config.speedBonus, false);
        expect(config.randomBonuses, false);
        expect(config.mode, 'marathon');
      });
    });

    group('WsPlayer', () {
      test('parses from JSON correctly', () {
        final json = {
          'id': 'player-123',
          'name': 'Alice',
          'isHost': true,
          'score': 100,
          'hasAnswered': true,
        };

        final player = WsPlayer.fromJson(json);
        expect(player.id, 'player-123');
        expect(player.name, 'Alice');
        expect(player.isHost, true);
        expect(player.score, 100);
        expect(player.hasAnswered, true);
      });

      test('uses defaults when optional fields missing', () {
        final json = {
          'id': 'player-123',
          'name': 'Alice',
        };

        final player = WsPlayer.fromJson(json);
        expect(player.isHost, false);
        expect(player.score, 0);
        expect(player.hasAnswered, false);
      });
    });

    group('Client messages', () {
      test('JoinMessage encodes correctly', () {
        final message = JoinMessage(name: 'Alice', code: 'ABCD');
        final json = jsonDecode(message.encode());

        expect(json['type'], 'join');
        expect(json['name'], 'Alice');
        expect(json['code'], 'ABCD');
      });

      test('AnswerMessage encodes correctly', () {
        final message = AnswerMessage(choice: 'top', responseTime: 2500);
        final json = jsonDecode(message.encode());

        expect(json['type'], 'answer');
        expect(json['choice'], 'top');
        expect(json['responseTime'], 2500);
      });

      test('StartGameMessage encodes correctly', () {
        const message = StartGameMessage();
        final json = jsonDecode(message.encode());

        expect(json['type'], 'start_game');
      });

      test('PlayAgainMessage encodes correctly', () {
        const message = PlayAgainMessage();
        final json = jsonDecode(message.encode());

        expect(json['type'], 'play_again');
      });

      test('LeaveMessage encodes correctly', () {
        const message = LeaveMessage();
        final json = jsonDecode(message.encode());

        expect(json['type'], 'leave');
      });

      test('UpdateConfigMessage encodes correctly', () {
        final message = UpdateConfigMessage(config: {
          'rounds': 8,
          'timePerRound': 7,
        });
        final json = jsonDecode(message.encode());

        expect(json['type'], 'update_config');
        expect(json['config']['rounds'], 8);
        expect(json['config']['timePerRound'], 7);
      });
    });

    group('WsMessage.tryParse', () {
      test('returns message for valid JSON', () {
        final data = '{"type":"connected","playerId":"abc"}';
        final message = WsMessage.tryParse(data);

        expect(message, isNotNull);
        expect(message, isA<ConnectionEstablishedMessage>());
      });

      test('returns null for invalid JSON', () {
        final message = WsMessage.tryParse('not json');
        expect(message, isNull);
      });

      test('returns null for empty string', () {
        final message = WsMessage.tryParse('');
        expect(message, isNull);
      });
    });
  });
}
