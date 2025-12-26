import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Callback for when a notification is tapped.
typedef NotificationTapCallback = void Function(Map<String, dynamic> data);

/// Service for handling push notifications via Firebase Cloud Messaging.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Stream controller for FCM token changes.
  final _tokenController = StreamController<String?>.broadcast();

  /// Stream of FCM token changes.
  Stream<String?> get tokenStream => _tokenController.stream;

  /// Current FCM token.
  String? _currentToken;
  String? get currentToken => _currentToken;

  /// Callback for handling notification taps.
  NotificationTapCallback? onNotificationTap;

  /// Initialize the push notification service.
  /// Should be called after Firebase.initializeApp().
  Future<void> init() async {
    // Skip on web - push notifications are mobile only
    if (kIsWeb) return;

    // Request permission
    await requestPermission();

    // Get initial token (may fail on emulators without Google Play Services)
    try {
      _currentToken = await _messaging.getToken();
      debugPrint('FCM Token: $_currentToken');
    } catch (e) {
      debugPrint('FCM getToken failed (expected on emulators): $e');
      // Continue without token - app should still work
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((token) {
      _currentToken = token;
      _tokenController.add(token);
      debugPrint('FCM Token refreshed: $token');
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a notification (terminated state)
    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      debugPrint('FCM getInitialMessage failed: $e');
    }
  }

  /// Request notification permission.
  /// Returns true if permission was granted.
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    debugPrint('Push notification permission: ${settings.authorizationStatus}');
    return granted;
  }

  /// Get the current FCM token.
  /// Returns null if not available (e.g., permission denied).
  Future<String?> getToken() async {
    if (kIsWeb) return null;

    try {
      _currentToken = await _messaging.getToken();
      return _currentToken;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Subscribe to a topic.
  Future<void> subscribeToTopic(String topic) async {
    if (kIsWeb) return;
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    if (kIsWeb) return;
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  /// Handle foreground message (app is open and visible).
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received:');
    debugPrint('  Title: ${message.notification?.title}');
    debugPrint('  Body: ${message.notification?.body}');
    debugPrint('  Data: ${message.data}');

    // For foreground messages, we might want to show a local notification
    // or update the UI. For now, we just log it.
    // TODO: Consider showing an in-app notification banner
  }

  /// Handle notification tap (app was in background or terminated).
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped:');
    debugPrint('  Title: ${message.notification?.title}');
    debugPrint('  Body: ${message.notification?.body}');
    debugPrint('  Data: ${message.data}');

    // Call the callback if set
    if (onNotificationTap != null && message.data.isNotEmpty) {
      onNotificationTap!(message.data);
    }
  }

  /// Dispose of resources.
  void dispose() {
    _tokenController.close();
  }
}
