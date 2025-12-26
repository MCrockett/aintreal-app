import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'push_notification_service.dart';

/// Provider for the current FCM token.
/// Returns null on web or if permission is denied.
final fcmTokenProvider = StreamProvider<String?>((ref) {
  if (kIsWeb) {
    return Stream.value(null);
  }

  final service = PushNotificationService.instance;

  // Emit current token first, then listen for changes
  return Stream.value(service.currentToken).asyncExpand((_) {
    return service.tokenStream;
  });
});

/// Provider to get the FCM token once (not a stream).
final fcmTokenFutureProvider = FutureProvider<String?>((ref) async {
  if (kIsWeb) return null;
  return PushNotificationService.instance.getToken();
});
