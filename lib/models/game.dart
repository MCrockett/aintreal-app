/// Game-related data models.
library;

/// Configuration options for a game.
class GameConfig {
  const GameConfig({
    this.rounds = 6,
    this.timePerRound = 5,
    this.speedBonus = true,
    this.randomBonuses = true,
    this.mode = GameMode.party,
  });

  factory GameConfig.fromJson(Map<String, dynamic> json) {
    return GameConfig(
      rounds: json['rounds'] as int? ?? 6,
      timePerRound: json['timePerRound'] as int? ?? 5,
      speedBonus: json['speedBonus'] as bool? ?? true,
      randomBonuses: json['randomBonuses'] as bool? ?? true,
      mode: GameMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => GameMode.party,
      ),
    );
  }

  final int rounds;
  final int timePerRound;
  final bool speedBonus;
  final bool randomBonuses;
  final GameMode mode;

  Map<String, dynamic> toJson() => {
        'rounds': rounds,
        'timePerRound': timePerRound,
        'speedBonus': speedBonus,
        'randomBonuses': randomBonuses,
        'mode': mode.name,
      };

  GameConfig copyWith({
    int? rounds,
    int? timePerRound,
    bool? speedBonus,
    bool? randomBonuses,
    GameMode? mode,
  }) {
    return GameConfig(
      rounds: rounds ?? this.rounds,
      timePerRound: timePerRound ?? this.timePerRound,
      speedBonus: speedBonus ?? this.speedBonus,
      randomBonuses: randomBonuses ?? this.randomBonuses,
      mode: mode ?? this.mode,
    );
  }
}

/// Game mode type.
enum GameMode {
  party,
  classic,
  marathon,
}

/// Game state enum matching server states.
enum GameStatus {
  lobby,
  playing,
  revealing,
  finished,
}

/// Player in a game.
class Player {
  const Player({
    required this.id,
    required this.name,
    required this.isHost,
    this.score = 0,
    this.hasAnswered = false,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isHost': isHost,
        'score': score,
        'hasAnswered': hasAnswered,
      };

  Player copyWith({
    String? id,
    String? name,
    bool? isHost,
    int? score,
    bool? hasAnswered,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      isHost: isHost ?? this.isHost,
      score: score ?? this.score,
      hasAnswered: hasAnswered ?? this.hasAnswered,
    );
  }
}

/// Full game state.
class GameState {
  const GameState({
    required this.code,
    required this.status,
    required this.config,
    required this.players,
    this.currentRound = 0,
    this.hostId,
  });

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      code: json['code'] as String,
      status: GameStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => GameStatus.lobby,
      ),
      config: GameConfig.fromJson(json['config'] as Map<String, dynamic>),
      players: (json['players'] as List<dynamic>?)
              ?.map((p) => Player.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      currentRound: json['currentRound'] as int? ?? 0,
      hostId: json['hostId'] as String?,
    );
  }

  final String code;
  final GameStatus status;
  final GameConfig config;
  final List<Player> players;
  final int currentRound;
  final String? hostId;

  Map<String, dynamic> toJson() => {
        'code': code,
        'status': status.name,
        'config': config.toJson(),
        'players': players.map((p) => p.toJson()).toList(),
        'currentRound': currentRound,
        'hostId': hostId,
      };

  GameState copyWith({
    String? code,
    GameStatus? status,
    GameConfig? config,
    List<Player>? players,
    int? currentRound,
    String? hostId,
  }) {
    return GameState(
      code: code ?? this.code,
      status: status ?? this.status,
      config: config ?? this.config,
      players: players ?? this.players,
      currentRound: currentRound ?? this.currentRound,
      hostId: hostId ?? this.hostId,
    );
  }
}

/// Response from creating a game.
class CreateGameResponse {
  const CreateGameResponse({
    required this.code,
    required this.playerId,
    required this.wsUrl,
  });

  factory CreateGameResponse.fromJson(Map<String, dynamic> json) {
    return CreateGameResponse(
      code: json['code'] as String,
      playerId: json['playerId'] as String,
      wsUrl: json['wsUrl'] as String,
    );
  }

  final String code;
  final String playerId;
  final String wsUrl;
}

/// Response from joining a game.
class JoinGameResponse {
  const JoinGameResponse({
    required this.playerId,
    required this.wsUrl,
    required this.gameState,
  });

  factory JoinGameResponse.fromJson(Map<String, dynamic> json) {
    return JoinGameResponse(
      playerId: json['playerId'] as String,
      wsUrl: json['wsUrl'] as String,
      gameState: GameState.fromJson(json['gameState'] as Map<String, dynamic>),
    );
  }

  final String playerId;
  final String wsUrl;
  final GameState gameState;
}
