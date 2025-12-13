/// Environment configuration for the AIn't Real app.
///
/// API URLs and environment flags are configured here.
/// Use --dart-define=API_BASE=http://localhost:8789 for local development.
library;

class Env {
  Env._();

  /// Base URL for the game API.
  ///
  /// Defaults to production. Override with:
  /// ```bash
  /// flutter run --dart-define=API_BASE=http://localhost:8789
  /// ```
  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://api.aint-real.com',
  );

  /// WebSocket URL for real-time game communication.
  ///
  /// Automatically derived from [apiBase], converting http(s) to ws(s).
  static String get wsBase {
    if (apiBase.startsWith('https://')) {
      return apiBase.replaceFirst('https://', 'wss://');
    }
    return apiBase.replaceFirst('http://', 'ws://');
  }

  /// Whether running in development mode.
  static const bool isDevelopment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production',
  ) == 'development';

  /// App version displayed in the UI.
  static const String appVersion = '1.0.0';
}
