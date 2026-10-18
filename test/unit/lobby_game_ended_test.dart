import 'package:flutter_test/flutter_test.dart';
import 'package:aintreal_app/core/websocket/game_state_provider.dart';
import 'package:aintreal_app/core/websocket/ws_client.dart';
import 'package:aintreal_app/features/lobby/lobby_screen.dart';

void main() {
  group('lobby dialog when the game is gone', () {
    test('handleGameGone publishes disconnected and the reason in one update',
        () {
      final notifier = GameStateNotifier();
      final updates = <GameState>[];
      notifier.addListener(updates.add, fireImmediately: false);

      notifier.handleGameGone();

      expect(updates, hasLength(1));
      expect(updates.single.connectionState, WsConnectionState.disconnected);
      expect(updates.single.error, WsClient.gameEndedError);
      notifier.dispose();
    });

    test('the lobby rule shows Game Ended for that update', () {
      const previous = GameState(
        playerId: 'host-1',
        hostId: 'host-1',
        connectionState: WsConnectionState.reconnecting,
      );
      final next = previous.copyWith(
        connectionState: WsConnectionState.disconnected,
        error: WsClient.gameEndedError,
      );

      expect(lobbyDisconnectDialog(previous, next),
          LobbyDisconnectDialog.gameEnded);
    });

    test('an ordinary lost connection still shows Connection Lost', () {
      const previous =
          GameState(connectionState: WsConnectionState.reconnecting);
      final next =
          previous.copyWith(connectionState: WsConnectionState.disconnected);

      expect(lobbyDisconnectDialog(previous, next),
          LobbyDisconnectDialog.connectionLost);
    });

    test('host left keeps its own dialog', () {
      const previous = GameState(connectionState: WsConnectionState.connected);
      final next = previous.copyWith(
        connectionState: WsConnectionState.disconnected,
        error: 'Host left the game',
      );

      expect(lobbyDisconnectDialog(previous, next), LobbyDisconnectDialog.none);
    });
  });
}
