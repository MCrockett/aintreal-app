import 'dart:async';
import 'dart:math';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/widgets.dart'
    show AppLifecycleState, WidgetsBinding, WidgetsBindingObserver;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'ws_messages.dart';

/// Connection state for the WebSocket.
enum WsConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// WebSocket client with automatic reconnection.
class WsClient with WidgetsBindingObserver {
  WsClient({
    required this.url,
    this.onMessage,
    this.onStateChange,
    this.onError,
  }) {
    WidgetsBinding.instance.addObserver(this);
  }

  final String url;
  final void Function(WsMessage message)? onMessage;
  final void Function(WsConnectionState state)? onStateChange;
  final void Function(String error)? onError;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  WsConnectionState _state = WsConnectionState.disconnected;
  WsConnectionState get state => _state;

  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _baseReconnectDelay = Duration(seconds: 1);
  static const Duration _maxReconnectDelay = Duration(seconds: 30);
  static const Duration _pingInterval = Duration(seconds: 15);

  bool _intentionalDisconnect = false;
  DateTime? _backgroundedAt;

  /// Connect to the WebSocket server.
  Future<void> connect() async {
    debugPrint('WS connect() called, current state: $_state, url: $url');

    if (_state == WsConnectionState.connecting ||
        _state == WsConnectionState.connected) {
      debugPrint('WS already connecting/connected, skipping');
      return;
    }

    _intentionalDisconnect = false;
    _setConnectionState(WsConnectionState.connecting);

    try {
      debugPrint('WS creating channel...');
      _channel = WebSocketChannel.connect(Uri.parse(url));

      // Wait for connection to be ready
      debugPrint('WS waiting for ready...');
      await _channel!.ready;
      debugPrint('WS channel ready!');

      _setConnectionState(WsConnectionState.connected);
      _reconnectAttempts = 0;

      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );

      _startPingTimer();
      debugPrint('WS fully connected and listening');
    } catch (e, stack) {
      debugPrint('WebSocket connect error: $e');
      _recordError(e, stack, 'WebSocket connection failed');

      // If we're reconnecting, stay in reconnecting state and keep trying
      // rather than transitioning to disconnected on each failed attempt.
      if (_reconnectAttempts > 0) {
        _setConnectionState(WsConnectionState.reconnecting);
        _scheduleReconnect();
      } else {
        _setConnectionState(WsConnectionState.disconnected);
        onError?.call('Failed to connect: $e');
        _scheduleReconnect();
      }
    }
  }

  /// Disconnect from the WebSocket server.
  void disconnect() {
    _intentionalDisconnect = true;
    _cleanup();
    _setConnectionState(WsConnectionState.disconnected);
  }

  /// Send a message to the server. Returns true if sent successfully.
  bool send(WsClientMessage message) {
    if (_state != WsConnectionState.connected || _channel == null) {
      debugPrint('Cannot send message: not connected (state: $_state)');
      return false;
    }

    try {
      _channel!.sink.add(message.encode());
      return true;
    } catch (e, stack) {
      debugPrint('WebSocket send error: $e');
      _recordError(e, stack, 'WebSocket send failed');
      onError?.call('Failed to send message: $e');
      return false;
    }
  }

  void _handleMessage(dynamic data) {
    if (data is! String) return;

    debugPrint('WS raw message: $data');

    final message = WsMessage.tryParse(data);
    if (message != null) {
      onMessage?.call(message);
    } else {
      debugPrint('Failed to parse WebSocket message: $data');
    }
  }

  void _handleError(dynamic error) {
    debugPrint('WebSocket error: $error');
    _recordError(error, null, 'WebSocket stream error');
    onError?.call('WebSocket error: $error');
  }

  void _handleDone() {
    debugPrint('WebSocket connection closed');
    _cleanup();

    if (!_intentionalDisconnect) {
      _setConnectionState(WsConnectionState.reconnecting);
      _scheduleReconnect();
    } else {
      _setConnectionState(WsConnectionState.disconnected);
    }
  }

  void _scheduleReconnect() {
    if (_intentionalDisconnect) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnect attempts reached');
      _recordError(
        Exception('Max WebSocket reconnect attempts ($_maxReconnectAttempts) reached'),
        null,
        'WebSocket reconnection exhausted',
      );
      onError?.call('Connection lost. Please try again.');
      _setConnectionState(WsConnectionState.disconnected);
      return;
    }

    _reconnectAttempts++;
    final delay = _calculateReconnectDelay();

    debugPrint(
        'Scheduling reconnect attempt $_reconnectAttempts in ${delay.inMilliseconds}ms');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (!_intentionalDisconnect) {
        connect();
      }
    });
  }

  Duration _calculateReconnectDelay() {
    // Exponential backoff with jitter
    final exponentialDelay = _baseReconnectDelay.inMilliseconds *
        pow(2, _reconnectAttempts - 1).toInt();
    final cappedDelay = min(exponentialDelay, _maxReconnectDelay.inMilliseconds);

    // Add up to 25% jitter
    final jitter = (cappedDelay * Random().nextDouble() * 0.25).toInt();

    return Duration(milliseconds: cappedDelay + jitter);
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      if (_state == WsConnectionState.connected && _channel != null) {
        try {
          _channel!.sink.add('{"type":"ping"}');
        } catch (e) {
          debugPrint('Ping send failed, connection dead: $e');
          _handleDone();
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _backgroundedAt = DateTime.now();
        break;
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      default:
        break;
    }
  }

  void _handleAppResumed() {
    final bg = _backgroundedAt;
    _backgroundedAt = null;

    if (_intentionalDisconnect) return;

    // If backgrounded briefly, just send a ping to verify the socket
    // survived — a synchronous send failure surfaces the death now instead
    // of waiting up to 15s for the periodic ping timer.
    if (bg == null || DateTime.now().difference(bg).inSeconds <= 2) {
      _sendVerificationPing();
      return;
    }

    debugPrint(
        'App resumed after ${DateTime.now().difference(bg).inSeconds}s in background');

    if (_state == WsConnectionState.connected && _channel != null) {
      // Force reconnect — iOS kills WebSocket connections when backgrounded
      debugPrint('Forcing reconnect after background...');
      _cleanup();
      _setConnectionState(WsConnectionState.reconnecting);
      _reconnectAttempts = 0;
      connect();
    }
  }

  void _sendVerificationPing() {
    if (_state != WsConnectionState.connected || _channel == null) return;
    try {
      _channel!.sink.add('{"type":"ping"}');
    } catch (e) {
      debugPrint('Resume ping failed, connection dead: $e');
      _handleDone();
    }
  }

  void _cleanup() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  void _setConnectionState(WsConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      onStateChange?.call(newState);
    }
  }

  /// Dispose of resources.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disconnect();
  }

  /// Record non-fatal error to Crashlytics (mobile only).
  void _recordError(dynamic error, StackTrace? stack, String reason) {
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stack ?? StackTrace.current,
        reason: reason,
        fatal: false,
      );
    }
  }
}
