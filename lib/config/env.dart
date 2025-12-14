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

  /// Base URL for the web frontend (for sharing links).
  static const String webBase = 'https://aint-real.com';

  /// App version displayed in the UI.
  static const String appVersion = '1.0.0';

  /// Mobile app secret for bypassing Turnstile verification.
  /// This is passed in the X-Mobile-App header.
  static const String mobileAppSecret = String.fromEnvironment(
    'MOBILE_APP_SECRET',
    defaultValue: 'aintreal-mobile-v1-2024',
  );
}
