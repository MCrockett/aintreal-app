/// API endpoint constants for the AIn't Real game server.
library;

/// All API endpoints used by the app.
abstract class Endpoints {
  /// Game management endpoints.
  static const String gameCreate = '/api/game/create';
  static String gameJoin(String code) => '/api/game/join/$code';
  static String gameState(String code) => '/api/game/$code';

  /// WebSocket endpoint for real-time game communication.
  static String gameWebSocket(String code, String playerId) =>
      '/api/game/$code/ws?playerId=$playerId';

  /// Image serving endpoint.
  static String image(String path) => '/api/images/$path';

  /// Statistics endpoints.
  static const String stats = '/api/stats';
  static const String leaderboard = '/api/stats/leaderboard';

  /// Future auth endpoints (for mobile app).
  static const String authFirebase = '/api/auth/firebase';
  static const String userProfile = '/api/user/profile';
  static const String userFcmToken = '/api/user/fcm-token';
}
