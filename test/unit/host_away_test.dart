import 'package:flutter_test/flutter_test.dart';
import 'package:aintreal_app/core/websocket/game_state_provider.dart';
import 'package:aintreal_app/core/websocket/ws_messages.dart';

/// host_disconnected (newer servers): guests see "Host reconnecting…" until
/// the host's player_connected arrives or the game ends with host_left.
void main() {
  Map<String, dynamic> player(String id, {bool host = false, bool connected = true}) =>
      {'id': id, 'name': id, 'isHost': host, 'connected': connected};

  Map<String, dynamic> connectedMsg(String me, {bool hostConnected = true}) => {
        'type': 'connected',
        'playerId': me,
        'gameState': {
          'code': 'ABCD',
          'status': 'lobby',
          'hostId': 'host',
          'currentRound': 0,
          'config': {'rounds': 6, 'timePerRound': 5},
          'players': [
            player('host', host: true, connected: hostConnected),
            player('guest'),
          ],
        },
      };

  late GameStateNotifier notifier;

  setUp(() => notifier = GameStateNotifier());
  tearDown(() => notifier.dispose());

  test('parses host_disconnected with graceMs', () {
    final msg = WsMessage.fromJson({'type': 'host_disconnected', 'graceMs': 60000});
    expect(msg, isA<HostDisconnectedMessage>());
    expect((msg as HostDisconnectedMessage).graceMs, 60000);
  });

  test('guest: host_disconnected sets hostAway, host reconnect clears it', () {
    notifier.handleMessage(WsMessage.fromJson(connectedMsg('guest')));
    expect(notifier.state.hostAway, isFalse);

    notifier.handleMessage(WsMessage.fromJson({'type': 'host_disconnected', 'graceMs': 60000}));
    expect(notifier.state.hostAway, isTrue);

    // player_disconnected for the host keeps it set
    notifier.handleMessage(WsMessage.fromJson({
      'type': 'player_disconnected',
      'playerId': 'host',
      'players': [player('host', host: true, connected: false), player('guest')],
    }));
    expect(notifier.state.hostAway, isTrue);

    // another guest connecting does not clear it
    notifier.handleMessage(WsMessage.fromJson({
      'type': 'player_connected',
      'playerId': 'guest2',
      'players': [player('host', host: true, connected: false), player('guest'), player('guest2')],
    }));
    expect(notifier.state.hostAway, isTrue);

    notifier.handleMessage(WsMessage.fromJson({
      'type': 'player_connected',
      'playerId': 'host',
      'players': [player('host', host: true), player('guest'), player('guest2')],
    }));
    expect(notifier.state.hostAway, isFalse);
  });

  test('guest: host_left clears hostAway and reports the host left', () {
    notifier.handleMessage(WsMessage.fromJson(connectedMsg('guest')));
    notifier.handleMessage(WsMessage.fromJson({'type': 'host_disconnected', 'graceMs': 60000}));
    notifier.handleMessage(WsMessage.fromJson({'type': 'host_left'}));
    expect(notifier.state.hostAway, isFalse);
    expect(notifier.state.error, 'Host left the game');
  });

  test('guest reconnecting during the grace window sees hostAway', () {
    notifier.handleMessage(WsMessage.fromJson(connectedMsg('guest', hostConnected: false)));
    expect(notifier.state.hostAway, isTrue);
  });

  test('host never flags itself as away', () {
    notifier.handleMessage(WsMessage.fromJson(connectedMsg('host')));
    notifier.handleMessage(WsMessage.fromJson({'type': 'host_disconnected', 'graceMs': 60000}));
    expect(notifier.state.hostAway, isFalse);
  });
}
