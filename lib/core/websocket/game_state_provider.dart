import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/game_api.dart';
import 'ws_client.dart';
import 'ws_messages.dart';

/// Game status enum matching server states.
enum GameStatus {
  lobby,
  playing,
  revealing,
  finished,
}

GameStatus _parseStatus(String status) {
  return switch (status) {
    'lobby' => GameStatus.lobby,
    'playing' => GameStatus.playing,
    'revealing' => GameStatus.revealing,
    'finished' => GameStatus.finished,
    _ => GameStatus.lobby,
  };
}

/// Current round data during gameplay.
class RoundData {
  const RoundData({
    required this.round,
    required this.topUrl,
    required this.bottomUrl,
    required this.aiPosition,
    required this.totalRounds,
    this.hasAnswered = false,
    this.playerChoice,
    this.answeredCount = 0,
    this.totalPlayers = 0,
  });

  final int round;
  final String topUrl;
  final String bottomUrl;
  final String aiPosition; // 'top' or 'bottom'
  final int totalRounds;
  final bool hasAnswered;
  final String? playerChoice;
  final int answeredCount;
  final int totalPlayers;

  RoundData copyWith({
    int? round,
    String? topUrl,
    String? bottomUrl,
    String? aiPosition,
    int? totalRounds,
    bool? hasAnswered,
    String? playerChoice,
    int? answeredCount,
    int? totalPlayers,
  }) {
    return RoundData(
      round: round ?? this.round,
      topUrl: topUrl ?? this.topUrl,
      bottomUrl: bottomUrl ?? this.bottomUrl,
      aiPosition: aiPosition ?? this.aiPosition,
      totalRounds: totalRounds ?? this.totalRounds,
      hasAnswered: hasAnswered ?? this.hasAnswered,
      playerChoice: playerChoice ?? this.playerChoice,
      answeredCount: answeredCount ?? this.answeredCount,
      totalPlayers: totalPlayers ?? this.totalPlayers,
    );
  }
}

/// Reveal data for showing round results.
class RevealData {
  const RevealData({
    required this.round,
    required this.aiPosition,
    required this.results,
    required this.scores,
    this.bonus,
  });

  final int round;
  final String aiPosition;
  final List<PlayerResult> results;
  final List<PlayerScore> scores;
  final RoundBonus? bonus;
}

/// Game over data with final rankings.
class GameOverData {
  const GameOverData({
    required this.rankings,
    required this.totalRounds,
  });

  final List<FinalRanking> rankings;
  final int totalRounds;
}

/// Complete game state.
class GameState {
  const GameState({
    this.code,
    this.playerId,
    this.playerName,
    this.status = GameStatus.lobby,
    this.players = const [],
    this.config,
    this.currentRound = 0,
    this.hostId,
    this.connectionState = WsConnectionState.disconnected,
    this.error,
    this.roundData,
    this.revealData,
    this.gameOverData,
    this.countdown,
  });

  final String? code;
  final String? playerId;
  final String? playerName;
  final GameStatus status;
  final List<WsPlayer> players;
  final WsGameConfig? config;
  final int currentRound;
  final String? hostId;
  final WsConnectionState connectionState;
  final String? error;
  final RoundData? roundData;
  final RevealData? revealData;
  final GameOverData? gameOverData;
  final int? countdown;

  bool get isHost => playerId != null && playerId == hostId;
  bool get isConnected => connectionState == WsConnectionState.connected;

  WsPlayer? get currentPlayer {
    if (playerId == null) return null;
    return players.cast<WsPlayer?>().firstWhere(
          (p) => p?.id == playerId,
          orElse: () => null,
        );
  }

  GameState copyWith({
    String? code,
    String? playerId,
    String? playerName,
    GameStatus? status,
    List<WsPlayer>? players,
    WsGameConfig? config,
    int? currentRound,
    String? hostId,
    WsConnectionState? connectionState,
    String? error,
    RoundData? roundData,
    RevealData? revealData,
    GameOverData? gameOverData,
    int? countdown,
    bool clearError = false,
    bool clearRoundData = false,
    bool clearRevealData = false,
    bool clearGameOverData = false,
    bool clearCountdown = false,
  }) {
    return GameState(
      code: code ?? this.code,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      status: status ?? this.status,
      players: players ?? this.players,
      config: config ?? this.config,
      currentRound: currentRound ?? this.currentRound,
      hostId: hostId ?? this.hostId,
      connectionState: connectionState ?? this.connectionState,
      error: clearError ? null : (error ?? this.error),
      roundData: clearRoundData ? null : (roundData ?? this.roundData),
      revealData: clearRevealData ? null : (revealData ?? this.revealData),
      gameOverData:
          clearGameOverData ? null : (gameOverData ?? this.gameOverData),
      countdown: clearCountdown ? null : (countdown ?? this.countdown),
    );
  }
}

/// Notifier for managing game state and WebSocket connection.
class GameStateNotifier extends StateNotifier<GameState> {
  GameStateNotifier() : super(const GameState());

  WsClient? _wsClient;

  /// Initialize and connect to a game.
  Future<void> connect({
    required String code,
    required String playerId,
    required String playerName,
    bool isHost = false,
    WsGameConfig? config,
  }) async {
    // Disconnect any existing connection
    disconnect();

    // Set initial state
    state = GameState(
      code: code,
      playerId: playerId,
      playerName: playerName,
      status: GameStatus.lobby,
      hostId: isHost ? playerId : null,
      config: config,
      players: [
        WsPlayer(
          id: playerId,
          name: playerName,
          isHost: isHost,
        ),
      ],
    );

    // Build WebSocket URL
    final wsUrl = GameApi.instance.getWebSocketUrl(code, playerId);
    debugPrint('Connecting to WebSocket: $wsUrl');

    _wsClient = WsClient(
      url: wsUrl,
      onMessage: _handleMessage,
      onStateChange: _handleConnectionStateChange,
      onError: _handleError,
    );

    await _wsClient!.connect();
  }

  /// Disconnect from the game.
  void disconnect() {
    _wsClient?.disconnect();
    _wsClient?.dispose();
    _wsClient = null;
    state = const GameState();
  }

  /// Send start game command (host only).
  void startGame() {
    debugPrint('startGame() called: isHost=${state.isHost}, playerId=${state.playerId}, hostId=${state.hostId}');
    if (!state.isHost) {
      debugPrint('startGame() blocked: not host');
      return;
    }
    debugPrint('Sending start_game message...');
    _wsClient?.send(const StartGameMessage());
  }

  /// Submit answer for current round.
  void submitAnswer(String choice, int responseTimeMs) {
    if (state.roundData?.hasAnswered == true) return;

    _wsClient?.send(AnswerMessage(
      choice: choice,
      responseTime: responseTimeMs,
    ));

    // Optimistically update local state
    if (state.roundData != null) {
      state = state.copyWith(
        roundData: state.roundData!.copyWith(
          hasAnswered: true,
          playerChoice: choice,
        ),
      );
    }
  }

  /// Send play again command (host only).
  void playAgain() {
    if (!state.isHost) return;
    _wsClient?.send(const PlayAgainMessage());
  }

  /// Send leave command.
  void leave() {
    _wsClient?.send(const LeaveMessage());
    disconnect();
  }

  /// Update game config (host only).
  void updateConfig(Map<String, dynamic> config) {
    if (!state.isHost) return;
    _wsClient?.send(UpdateConfigMessage(config: config));
  }

  void _handleMessage(WsMessage message) {
    debugPrint('WS message: ${message.runtimeType}');

    switch (message) {
      case ConnectionEstablishedMessage(:final playerId, :final gameState):
        // Update state with full game state from server
        if (gameState != null) {
          state = state.copyWith(
            playerId: playerId,
            code: gameState.code,
            status: _parseStatus(gameState.status),
            config: gameState.config,
            players: gameState.players,
            currentRound: gameState.currentRound,
            hostId: gameState.hostId,
          );
        } else {
          state = state.copyWith(playerId: playerId);
        }

      case PlayerJoinedMessage(:final players):
        state = state.copyWith(players: players);

      case PlayerLeftMessage(:final players, :final newHost):
        state = state.copyWith(
          players: players,
          hostId: newHost ?? state.hostId,
        );

      case GameStateMessage(:final gameState):
        state = state.copyWith(
          code: gameState.code,
          status: _parseStatus(gameState.status),
          config: gameState.config,
          players: gameState.players,
          currentRound: gameState.currentRound,
          hostId: gameState.hostId,
        );

      case ConfigUpdatedMessage(:final config):
        state = state.copyWith(config: config);

      case GameStartingMessage(:final countdown):
        state = state.copyWith(
          status: GameStatus.playing,
          countdown: countdown,
          clearRoundData: true,
          clearRevealData: true,
          clearGameOverData: true,
        );

      case RoundStartMessage(
          :final round,
          :final topUrl,
          :final bottomUrl,
          :final aiPosition,
          :final totalRounds
        ):
        state = state.copyWith(
          status: GameStatus.playing,
          currentRound: round,
          roundData: RoundData(
            round: round,
            topUrl: topUrl,
            bottomUrl: bottomUrl,
            aiPosition: aiPosition,
            totalRounds: totalRounds,
            totalPlayers: state.players.length,
          ),
          clearCountdown: true,
          clearRevealData: true,
        );

      case PlayerAnsweredMessage(:final answeredCount, :final totalPlayers):
        if (state.roundData != null) {
          state = state.copyWith(
            roundData: state.roundData!.copyWith(
              answeredCount: answeredCount,
              totalPlayers: totalPlayers,
            ),
          );
        }

      case RevealMessage(
          :final round,
          :final aiPosition,
          :final results,
          :final scores,
          :final bonus
        ):
        state = state.copyWith(
          status: GameStatus.revealing,
          revealData: RevealData(
            round: round,
            aiPosition: aiPosition,
            results: results,
            scores: scores,
            bonus: bonus,
          ),
        );

      case GameOverMessage(:final rankings, :final totalRounds):
        debugPrint('GameOver received! Rankings: ${rankings.length}, totalRounds: $totalRounds');
        state = state.copyWith(
          status: GameStatus.finished,
          gameOverData: GameOverData(
            rankings: rankings,
            totalRounds: totalRounds,
          ),
          clearRoundData: true,
          clearRevealData: true,
        );
        debugPrint('State updated: status=${state.status}, gameOverData=${state.gameOverData != null}');

      case ReturnToLobbyMessage(:final gameState):
        state = state.copyWith(
          status: GameStatus.lobby,
          config: gameState.config,
          players: gameState.players,
          currentRound: 0,
          hostId: gameState.hostId,
          clearRoundData: true,
          clearRevealData: true,
          clearGameOverData: true,
          clearCountdown: true,
        );

      case HostLeftMessage():
        state = state.copyWith(
          error: 'Host left the game',
        );

      case ErrorMessage(:final message):
        state = state.copyWith(error: message);

      case MarathonEndedMessage():
        // Handle marathon mode ending
        state = state.copyWith(status: GameStatus.finished);

      case UnknownMessage():
        // Ignore unknown messages
        break;
    }
  }

  void _handleConnectionStateChange(WsConnectionState connectionState) {
    debugPrint('WS connection state: $connectionState');
    state = state.copyWith(connectionState: connectionState);
  }

  void _handleError(String error) {
    debugPrint('WS error: $error');
    state = state.copyWith(error: error);
  }

  /// Clear any error state.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _wsClient?.dispose();
    super.dispose();
  }
}

/// Provider for game state.
final gameStateProvider =
    StateNotifierProvider<GameStateNotifier, GameState>((ref) {
  return GameStateNotifier();
});
