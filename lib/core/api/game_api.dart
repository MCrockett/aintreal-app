import 'package:dio/dio.dart';

import '../../models/game.dart';
import 'api_client.dart';
import 'api_exceptions.dart';
import 'endpoints.dart';

/// Game API service for creating and joining games.
class GameApi {
  GameApi._();

  static final GameApi instance = GameApi._();

  final ApiClient _client = ApiClient.instance;

  /// Create a new game with the given configuration.
  ///
  /// Returns the game code, player ID, and WebSocket URL.
  Future<CreateGameResponse> createGame({
    required String playerName,
    required GameConfig config,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        Endpoints.gameCreate,
        data: {
          'hostName': playerName,
          'config': config.toJson(),
        },
      );

      final data = response.data;
      if (data == null) {
        throw const ServerException('Invalid response from server');
      }

      return CreateGameResponse.fromJson(data);
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      rethrow;
    }
  }

  /// Join an existing game with a code.
  ///
  /// Returns the player ID, WebSocket URL, and current game state.
  Future<JoinGameResponse> joinGame({
    required String code,
    required String playerName,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        Endpoints.gameJoin(code.toUpperCase()),
        data: {
          'playerName': playerName,
        },
      );

      final data = response.data;
      if (data == null) {
        throw const ServerException('Invalid response from server');
      }

      return JoinGameResponse.fromJson(data);
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      rethrow;
    }
  }

  /// Get current game state by code.
  ///
  /// Useful for reconnection or state sync.
  Future<GameState> getGameState(String code) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        Endpoints.gameState(code.toUpperCase()),
      );

      final data = response.data;
      if (data == null) {
        throw const ServerException('Invalid response from server');
      }

      return GameState.fromJson(data);
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      rethrow;
    }
  }

  /// Build full image URL from relative path.
  String getImageUrl(String path) {
    final baseUrl = _client.dio.options.baseUrl;
    return '$baseUrl${Endpoints.image(path)}';
  }

  /// Build WebSocket URL for a game.
  String getWebSocketUrl(String code, String playerId) {
    final baseUrl = _client.dio.options.baseUrl;
    final wsBase = baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    return '$wsBase${Endpoints.gameWebSocket(code, playerId)}';
  }
}
