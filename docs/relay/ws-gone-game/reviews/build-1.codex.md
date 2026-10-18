---
{
  "at": "2026-10-18T15:48:39-04:00",
  "base_ref": "origin/main",
  "base_sha": "10d9a6dee2517c975a17a1117bd9590fbf72119b",
  "confirmation": false,
  "duration_s": 138.3,
  "effort": "high",
  "head": "793963ab06acd5f6749298828906a608f352f22d",
  "inputs": {
    "idea": "c765500d8855489df7688b23b0ae4e0fc698af9e610d756234afe0d16a7e3bdd",
    "plan": "b16cb25c870d986de3f09948fdb60fc2740ed528058a867b69be24423f7e749a"
  },
  "model": "gpt-6-astra",
  "refresh": false,
  "reviewer": "codex",
  "round": 1,
  "same_provider": false,
  "skipped_reviewers": [],
  "tokens": {
    "cached": 299648,
    "input": 352401,
    "output": 3924
  },
  "verdict": "NO-GO"
}
---

Two behavior issues block promotion. Review was read-only; `git diff --check` passed. I did not rerun Flutter tests because they write build artifacts.

```text
verdict: NO-GO
prior:
blocking:
  - id: R1-1 lib/core/websocket/ws_client.dart:99 - The new asynchronous existence check can finish after disconnect/dispose. If a retry is pending, the user leaves and connects to another game, and the old check returns true or throws, the old client emits reconnecting through the shared GameStateNotifier. This overwrites the new connection's state and can leave its UI stuck reconnecting. Check that the client/connection attempt is still active after the await, before emitting callbacks.
  - id: R1-2 lib/core/websocket/ws_client.dart:103 - gameEndedError is emitted before disconnected. The lobby's synchronous listener handles that first notification as a snackbar and clears the error at lobby_screen.dart:310. The subsequent disconnect therefore opens "Connection Lost", never the promised "Game Ended" dialog. Publish the terminal state and reason together, or preserve the reason until the dialog consumes it. Add coverage through the actual lobby listener.
notes:
  - Version references agree on 1.0.2+15; native build configuration derives its values from Flutter. Repository docs identify this as the pending release after Android +13 and iOS +14, so this feature does not require another bump. Actual store upload history was not verified.
  - Signing, entitlements, permissions, dependencies, and platform metadata are unchanged. The iOS privacy manifest and tracking usage string are present. Submitted privacy/data-collection answers and export-compliance answers were unavailable for verification.
  - No persistent storage or schema changes occur in this range; no migration is needed.
  - docs/relay/ws-gone-game/idea.md covers the commit range, but DONE.md has no corresponding release entry.
  - Release-record inputs are origin/main, 1.0.2+15, source 793963ab06acd5f6749298828906a608f352f22d, and open/in-review state. No rollback procedure is recorded; reverting implementation commit 3640c88 would remove this fix. A store rollback would require a fresh increasing build number.
  - Preserve the documented release sequence: ship the app, allow adoption, then deploy backend PRs #17/#18. This PR does not change that sequence.
```
