# ws-gone-game

Adopted from PR #23: fix(2.1): stop reconnecting when the game no longer exists

Found in the 1.0.2 device pass: a host away from the lobby longer than the server's grace window came back to a stuck Connecting/Reconnecting screen (Back still worked). The server had deleted the room and refused the WebSocket upgrade with 404, which dart:io reports without a status code, so the client kept retrying.

- After a failed connect, `WsClient` asks `GameApi.gameExists` (GET /api/game/:code). A 404 stops retrying and reports "This game ended while you were away."; other failures keep retrying.
- The lobby's disconnect dialog shows "Game Ended" with that message.
- Crashlytics reporting in `WsClient` can't throw when Firebase isn't initialized.

Tests: 3 new (local 404 server), 267 pass.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
