# Plan: stop reconnecting when the game is gone (1.0.2)

Found in the 1.0.2 device pass (2026-10-18, Round A on the #18 server): a host away from the
lobby longer than the server's grace window returns to "Connecting…/Reconnecting…" for minutes.
The server has deleted the room and answers the WebSocket upgrade with 404, which dart:io reports
only as "not upgraded to websocket" (no status code), so WsClient retried up to 10 times.

## Tasks
- `WsClient` takes an optional `gameExists` check. After any failed connect it asks it; `false`
  stops retrying, reports `WsClient.gameEndedError` ("This game ended while you were away."), and
  goes to `disconnected`. A thrown check (offline, server error) keeps the normal retry path.
- `GameApi.gameExists(code)`: GET /api/game/:code; false only on `GameNotFoundException` (404).
- `GameStateNotifier.connect` passes `gameExists` for its code.
- Lobby: the existing disconnected dialog says "Game Ended" + the message when that error is set.
- `WsClient._recordError` no longer throws when Firebase isn't initialized (tests).

## Tests
- `test/unit/ws_client_game_gone_test.dart` with a local server that refuses the upgrade with 404:
  gone -> one check, game-ended error, disconnected; exists -> keeps retrying; check throws ->
  keeps retrying.
- Gates: `flutter test` (267 pass), `flutter analyze` on changed files clean. No CI in this repo.
