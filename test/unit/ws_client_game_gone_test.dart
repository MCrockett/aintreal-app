import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:aintreal_app/core/websocket/ws_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // A local server that refuses the WebSocket upgrade with 404, as the game
  // server does once a lobby has closed.
  late HttpServer server;
  late String url;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) {
      req.response.statusCode = 404;
      req.response.close();
    });
    url = 'ws://127.0.0.1:${server.port}/api/game/ABCD/ws?playerId=p1';
  });

  tearDown(() => server.close(force: true));

  test('stops reconnecting and reports game ended when the game is gone',
      () async {
    final errors = <String>[];
    final states = <WsConnectionState>[];
    var checks = 0;
    final client = WsClient(
      url: url,
      onError: errors.add,
      onStateChange: states.add,
      gameExists: () async {
        checks++;
        return false;
      },
    );

    await client.connect();
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    expect(errors, [WsClient.gameEndedError]);
    expect(client.state, WsConnectionState.disconnected);
    expect(checks, 1, reason: 'no reconnect attempts after the game is gone');
    client.dispose();
  });

  test('keeps retrying while the game still exists', () async {
    final errors = <String>[];
    final client = WsClient(
      url: url,
      onError: errors.add,
      gameExists: () async => true,
    );

    await client.connect();

    expect(errors, isNot(contains(WsClient.gameEndedError)));
    expect(client.state, isNot(WsConnectionState.connected));
    client.dispose();
  });

  test('keeps retrying when the existence check fails (offline)', () async {
    final errors = <String>[];
    final client = WsClient(
      url: url,
      onError: errors.add,
      gameExists: () async => throw const SocketException('offline'),
    );

    await client.connect();

    expect(errors, isNot(contains(WsClient.gameEndedError)));
    client.dispose();
  });
}
