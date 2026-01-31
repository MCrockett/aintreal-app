import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../core/websocket/ws_client.dart';

/// Overlay that shows reconnection status or connection lost state.
///
/// Renders nothing when connected or connecting. During [reconnecting],
/// shows a semi-transparent overlay with a spinner. During [disconnected],
/// shows an overlay with a "Return Home" button.
class ConnectionLostOverlay extends StatelessWidget {
  const ConnectionLostOverlay({
    super.key,
    required this.connectionState,
    required this.onReturnHome,
  });

  final WsConnectionState connectionState;
  final VoidCallback onReturnHome;

  @override
  Widget build(BuildContext context) {
    if (connectionState != WsConnectionState.reconnecting &&
        connectionState != WsConnectionState.disconnected) {
      return const SizedBox.shrink();
    }

    final isReconnecting =
        connectionState == WsConnectionState.reconnecting;

    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isReconnecting ? Icons.wifi_off : Icons.signal_wifi_off,
              size: 48,
              color: isReconnecting
                  ? AppTheme.warning
                  : AppTheme.wrongAnswer,
            ),
            const SizedBox(height: 24),
            Text(
              isReconnecting ? 'Reconnecting...' : 'Connection Lost',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isReconnecting
                        ? AppTheme.warning
                        : AppTheme.wrongAnswer,
                  ),
            ),
            const SizedBox(height: 16),
            if (isReconnecting) ...[
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppTheme.warning,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Trying to restore connection...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ] else ...[
              Text(
                'Unable to reconnect to the game.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton(
                  onPressed: onReturnHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Return Home',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
