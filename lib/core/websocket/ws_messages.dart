import 'dart:convert';

/// WebSocket message types from server.
enum WsMessageType {
  connectionEstablished,
  playerJoined,
  playerLeft,
  gameState,
  configUpdated,
  gameStarting,
  roundStart,
  playerAnswered,
  reveal,
  marathonEnded,
  gameOver,
  returnToLobby,
  hostLeft,
  error,
  unknown,
}

/// Parse server message type string to enum.
WsMessageType parseMessageType(String type) {
  return switch (type) {
    'connected' => WsMessageType.connectionEstablished,
    'player_joined' => WsMessageType.playerJoined,
    'player_connected' => WsMessageType.playerJoined,
    'player_left' => WsMessageType.playerLeft,
    'player_disconnected' => WsMessageType.playerLeft,
    'game_state' => WsMessageType.gameState,
    'config_updated' => WsMessageType.configUpdated,
    'game_starting' => WsMessageType.gameStarting,
    'round_start' => WsMessageType.roundStart,
    'player_answered' => WsMessageType.playerAnswered,
    'reveal' => WsMessageType.reveal,
    'round_reveal' => WsMessageType.reveal,
    'reveal_phase_start' => WsMessageType.unknown, // TODO: Implement reveal UI
    'marathon_ended' => WsMessageType.marathonEnded,
    'game_over' => WsMessageType.gameOver,
    'return_to_lobby' => WsMessageType.returnToLobby,
    'host_left' => WsMessageType.hostLeft,
    'error' => WsMessageType.error,
    _ => WsMessageType.unknown,
  };
}

/// Base class for server messages.
sealed class WsMessage {
  const WsMessage();

  factory WsMessage.fromJson(Map<String, dynamic> json) {
    final type = parseMessageType(json['type'] as String? ?? '');

    return switch (type) {
      WsMessageType.connectionEstablished =>
        ConnectionEstablishedMessage.fromJson(json),
      WsMessageType.playerJoined => PlayerJoinedMessage.fromJson(json),
      WsMessageType.playerLeft => PlayerLeftMessage.fromJson(json),
      WsMessageType.gameState => GameStateMessage.fromJson(json),
      WsMessageType.configUpdated => ConfigUpdatedMessage.fromJson(json),
      WsMessageType.gameStarting => GameStartingMessage.fromJson(json),
      WsMessageType.roundStart => RoundStartMessage.fromJson(json),
      WsMessageType.playerAnswered => PlayerAnsweredMessage.fromJson(json),
      WsMessageType.reveal => RevealMessage.fromJson(json),
      WsMessageType.marathonEnded => MarathonEndedMessage.fromJson(json),
      WsMessageType.gameOver => GameOverMessage.fromJson(json),
      WsMessageType.returnToLobby => ReturnToLobbyMessage.fromJson(json),
      WsMessageType.hostLeft => const HostLeftMessage(),
      WsMessageType.error => ErrorMessage.fromJson(json),
      WsMessageType.unknown => UnknownMessage(json),
    };
  }

  static WsMessage? tryParse(String data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      return WsMessage.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}

/// Server confirmed connection.
class ConnectionEstablishedMessage extends WsMessage {
  const ConnectionEstablishedMessage({
    required this.playerId,
    this.gameState,
  });

  factory ConnectionEstablishedMessage.fromJson(Map<String, dynamic> json) {
    return ConnectionEstablishedMessage(
      playerId: json['playerId'] as String,
      gameState: json['gameState'] != null
          ? WsGameState.fromJson(json['gameState'] as Map<String, dynamic>)
          : null,
    );
  }

  final String playerId;
  final WsGameState? gameState;
}

/// Player info in messages.
class WsPlayer {
  const WsPlayer({
    required this.id,
    required this.name,
    required this.isHost,
    this.score = 0,
    this.hasAnswered = false,
  });

  factory WsPlayer.fromJson(Map<String, dynamic> json) {
    return WsPlayer(
      id: json['id'] as String,
      name: json['name'] as String,
      isHost: json['isHost'] as bool? ?? false,
      score: json['score'] as int? ?? 0,
      hasAnswered: json['hasAnswered'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final bool isHost;
  final int score;
  final bool hasAnswered;
}

/// Someone joined the lobby or connected via WebSocket.
class PlayerJoinedMessage extends WsMessage {
  const PlayerJoinedMessage({
    this.player,
    this.playerId,
    required this.players,
  });

  factory PlayerJoinedMessage.fromJson(Map<String, dynamic> json) {
    // Handle both 'player_joined' (has player object) and 'player_connected' (has playerId)
    return PlayerJoinedMessage(
      player: json['player'] != null
          ? WsPlayer.fromJson(json['player'] as Map<String, dynamic>)
          : null,
      playerId: json['playerId'] as String?,
      players: (json['players'] as List<dynamic>)
          .map((p) => WsPlayer.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  final WsPlayer? player;
  final String? playerId;
  final List<WsPlayer> players;
}

/// Someone left the game.
class PlayerLeftMessage extends WsMessage {
  const PlayerLeftMessage({
    required this.playerId,
    required this.players,
    this.newHost,
  });

  factory PlayerLeftMessage.fromJson(Map<String, dynamic> json) {
    return PlayerLeftMessage(
      playerId: json['playerId'] as String,
      players: (json['players'] as List<dynamic>)
          .map((p) => WsPlayer.fromJson(p as Map<String, dynamic>))
          .toList(),
      newHost: json['newHost'] as String?,
    );
  }

  final String playerId;
  final List<WsPlayer> players;
  final String? newHost;
}

/// Full game state sync.
class GameStateMessage extends WsMessage {
  const GameStateMessage({required this.gameState});

  factory GameStateMessage.fromJson(Map<String, dynamic> json) {
    return GameStateMessage(
      gameState: WsGameState.fromJson(json['gameState'] as Map<String, dynamic>),
    );
  }

  final WsGameState gameState;
}

/// Game state from server.
class WsGameState {
  const WsGameState({
    required this.code,
    required this.status,
    required this.config,
    required this.players,
    required this.currentRound,
    this.hostId,
  });

  factory WsGameState.fromJson(Map<String, dynamic> json) {
    return WsGameState(
      code: json['code'] as String,
      status: json['status'] as String,
      config: WsGameConfig.fromJson(json['config'] as Map<String, dynamic>),
      players: (json['players'] as List<dynamic>)
          .map((p) => WsPlayer.fromJson(p as Map<String, dynamic>))
          .toList(),
      currentRound: json['currentRound'] as int? ?? 0,
      hostId: json['hostId'] as String?,
    );
  }

  final String code;
  final String status;
  final WsGameConfig config;
  final List<WsPlayer> players;
  final int currentRound;
  final String? hostId;
}

/// Game config from server.
class WsGameConfig {
  const WsGameConfig({
    required this.rounds,
    required this.timePerRound,
    required this.speedBonus,
    required this.randomBonuses,
    required this.mode,
  });

  factory WsGameConfig.fromJson(Map<String, dynamic> json) {
    return WsGameConfig(
      rounds: json['rounds'] as int? ?? 6,
      timePerRound: json['timePerRound'] as int? ?? 5,
      speedBonus: json['speedBonus'] as bool? ?? true,
      randomBonuses: json['randomBonuses'] as bool? ?? true,
      mode: json['mode'] as String? ?? 'party',
    );
  }

  final int rounds;
  final int timePerRound;
  final bool speedBonus;
  final bool randomBonuses;
  final String mode;
}

/// Host changed settings.
class ConfigUpdatedMessage extends WsMessage {
  const ConfigUpdatedMessage({required this.config});

  factory ConfigUpdatedMessage.fromJson(Map<String, dynamic> json) {
    return ConfigUpdatedMessage(
      config: WsGameConfig.fromJson(json['config'] as Map<String, dynamic>),
    );
  }

  final WsGameConfig config;
}

/// Game is about to start.
class GameStartingMessage extends WsMessage {
  const GameStartingMessage({required this.countdown});

  factory GameStartingMessage.fromJson(Map<String, dynamic> json) {
    return GameStartingMessage(
      countdown: json['countdown'] as int? ?? 3,
    );
  }

  final int countdown;
}

/// New round beginning.
class RoundStartMessage extends WsMessage {
  const RoundStartMessage({
    required this.round,
    required this.topUrl,
    required this.bottomUrl,
    required this.aiPosition,
    required this.totalRounds,
  });

  factory RoundStartMessage.fromJson(Map<String, dynamic> json) {
    return RoundStartMessage(
      round: json['round'] as int,
      topUrl: json['topUrl'] as String,
      bottomUrl: json['bottomUrl'] as String,
      aiPosition: json['aiPosition'] as String,
      totalRounds: json['totalRounds'] as int,
    );
  }

  final int round;
  final String topUrl;
  final String bottomUrl;
  final String aiPosition; // 'top' or 'bottom'
  final int totalRounds;
}

/// Someone submitted their answer.
class PlayerAnsweredMessage extends WsMessage {
  const PlayerAnsweredMessage({
    required this.playerId,
    required this.answeredCount,
    required this.totalPlayers,
  });

  factory PlayerAnsweredMessage.fromJson(Map<String, dynamic> json) {
    return PlayerAnsweredMessage(
      playerId: json['playerId'] as String,
      answeredCount: json['answeredCount'] as int,
      totalPlayers: json['totalPlayers'] as int,
    );
  }

  final String playerId;
  final int answeredCount;
  final int totalPlayers;
}

/// Round result for a player.
class PlayerResult {
  const PlayerResult({
    required this.playerId,
    required this.name,
    required this.choice,
    required this.correct,
    required this.responseTime,
    required this.points,
  });

  factory PlayerResult.fromJson(Map<String, dynamic> json) {
    return PlayerResult(
      playerId: json['playerId'] as String,
      name: json['name'] as String,
      choice: json['choice'] as String?,
      correct: json['correct'] as bool? ?? false,
      responseTime: json['responseTime'] as int? ?? 0,
      points: json['points'] as int? ?? 0,
    );
  }

  final String playerId;
  final String name;
  final String? choice;
  final bool correct;
  final int responseTime;
  final int points;
}

/// Player score update.
class PlayerScore {
  const PlayerScore({
    required this.playerId,
    required this.name,
    required this.score,
  });

  factory PlayerScore.fromJson(Map<String, dynamic> json) {
    return PlayerScore(
      playerId: json['playerId'] as String,
      name: json['name'] as String,
      score: json['score'] as int,
    );
  }

  final String playerId;
  final String name;
  final int score;
}

/// Bonus awarded in a round.
class RoundBonus {
  const RoundBonus({
    required this.type,
    required this.playerId,
    required this.playerName,
    required this.points,
  });

  factory RoundBonus.fromJson(Map<String, dynamic> json) {
    return RoundBonus(
      type: json['type'] as String,
      playerId: json['playerId'] as String,
      playerName: json['playerName'] as String,
      points: json['points'] as int,
    );
  }

  final String type;
  final String playerId;
  final String playerName;
  final int points;
}

/// Round reveal with results.
class RevealMessage extends WsMessage {
  const RevealMessage({
    required this.round,
    required this.aiPosition,
    required this.results,
    required this.scores,
    this.bonus,
    this.credits,
  });

  factory RevealMessage.fromJson(Map<String, dynamic> json) {
    return RevealMessage(
      round: json['round'] as int,
      aiPosition: json['aiPosition'] as String,
      results: (json['results'] as List<dynamic>)
          .map((r) => PlayerResult.fromJson(r as Map<String, dynamic>))
          .toList(),
      scores: (json['scores'] as List<dynamic>)
          .map((s) => PlayerScore.fromJson(s as Map<String, dynamic>))
          .toList(),
      bonus: json['bonus'] != null
          ? RoundBonus.fromJson(json['bonus'] as Map<String, dynamic>)
          : null,
      credits: json['credits'] as List<dynamic>?,
    );
  }

  final int round;
  final String aiPosition;
  final List<PlayerResult> results;
  final List<PlayerScore> scores;
  final RoundBonus? bonus;
  final List<dynamic>? credits;
}

/// Marathon game ended.
class MarathonEndedMessage extends WsMessage {
  const MarathonEndedMessage({
    required this.streak,
    required this.completed,
    this.topUrl,
    this.bottomUrl,
    this.aiPosition,
    this.playerChoice,
  });

  factory MarathonEndedMessage.fromJson(Map<String, dynamic> json) {
    return MarathonEndedMessage(
      streak: json['streak'] as int,
      completed: json['completed'] as bool,
      topUrl: json['topUrl'] as String?,
      bottomUrl: json['bottomUrl'] as String?,
      aiPosition: json['aiPosition'] as String?,
      playerChoice: json['playerChoice'] as String?,
    );
  }

  final int streak;
  final bool completed;
  final String? topUrl;
  final String? bottomUrl;
  final String? aiPosition;
  final String? playerChoice;
}

/// Final ranking for game over.
class FinalRanking {
  const FinalRanking({
    required this.playerId,
    required this.name,
    required this.score,
    required this.rank,
    this.correctAnswers = 0,
  });

  factory FinalRanking.fromJson(Map<String, dynamic> json) {
    return FinalRanking(
      // Server sends 'id', not 'playerId'
      playerId: (json['playerId'] ?? json['id']) as String,
      name: json['name'] as String,
      score: json['score'] as int,
      rank: json['rank'] as int,
      // Server sends 'correct', not 'correctAnswers'
      correctAnswers: (json['correctAnswers'] ?? json['correct']) as int? ?? 0,
    );
  }

  final String playerId;
  final String name;
  final int score;
  final int rank;
  final int correctAnswers;
}

/// Game over with final rankings.
class GameOverMessage extends WsMessage {
  const GameOverMessage({
    required this.rankings,
    required this.totalRounds,
    this.credits,
  });

  factory GameOverMessage.fromJson(Map<String, dynamic> json) {
    return GameOverMessage(
      rankings: (json['rankings'] as List<dynamic>)
          .map((r) => FinalRanking.fromJson(r as Map<String, dynamic>))
          .toList(),
      totalRounds: json['totalRounds'] as int,
      credits: json['credits'] as List<dynamic>?,
    );
  }

  final List<FinalRanking> rankings;
  final int totalRounds;
  final List<dynamic>? credits;
}

/// Play Again - return to lobby.
class ReturnToLobbyMessage extends WsMessage {
  const ReturnToLobbyMessage({required this.gameState});

  factory ReturnToLobbyMessage.fromJson(Map<String, dynamic> json) {
    return ReturnToLobbyMessage(
      gameState: WsGameState.fromJson(json['gameState'] as Map<String, dynamic>),
    );
  }

  final WsGameState gameState;
}

/// Host disconnected.
class HostLeftMessage extends WsMessage {
  const HostLeftMessage();
}

/// Error from server.
class ErrorMessage extends WsMessage {
  const ErrorMessage({required this.message});

  factory ErrorMessage.fromJson(Map<String, dynamic> json) {
    return ErrorMessage(
      message: json['message'] as String? ?? 'Unknown error',
    );
  }

  final String message;
}

/// Unknown message type.
class UnknownMessage extends WsMessage {
  const UnknownMessage(this.data);

  final Map<String, dynamic> data;
}

// =============================================================================
// Client → Server Messages
// =============================================================================

/// Base class for client messages.
abstract class WsClientMessage {
  const WsClientMessage(this.type);

  final String type;

  Map<String, dynamic> toJson();

  String encode() => jsonEncode(toJson());
}

/// Join a game.
class JoinMessage extends WsClientMessage {
  const JoinMessage({
    required this.name,
    required this.code,
  }) : super('join');

  final String name;
  final String code;

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'name': name,
        'code': code,
      };
}

/// Update game config (host only).
class UpdateConfigMessage extends WsClientMessage {
  const UpdateConfigMessage({required this.config}) : super('update_config');

  final Map<String, dynamic> config;

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'config': config,
      };
}

/// Start the game (host only).
class StartGameMessage extends WsClientMessage {
  const StartGameMessage() : super('start_game');

  @override
  Map<String, dynamic> toJson() => {'type': type};
}

/// Submit answer.
class AnswerMessage extends WsClientMessage {
  const AnswerMessage({
    required this.choice,
    required this.responseTime,
  }) : super('answer');

  final String choice; // 'top' or 'bottom'
  final int responseTime;

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'choice': choice,
        'responseTime': responseTime,
      };
}

/// Trigger next round reveal (host only, usually auto).
class NextRoundMessage extends WsClientMessage {
  const NextRoundMessage() : super('next_round');

  @override
  Map<String, dynamic> toJson() => {'type': type};
}

/// Play again - return to lobby (host only).
class PlayAgainMessage extends WsClientMessage {
  const PlayAgainMessage() : super('play_again');

  @override
  Map<String, dynamic> toJson() => {'type': type};
}

/// Leave the game.
class LeaveMessage extends WsClientMessage {
  const LeaveMessage() : super('leave');

  @override
  Map<String, dynamic> toJson() => {'type': type};
}
