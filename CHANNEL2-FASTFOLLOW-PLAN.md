# Channel-2 Flutter Fast-Follow Plan

**Repo:** `aintreal-app` (Flutter) · **Status:** NOT STARTED · **Effort:** M · **Owner session:** dedicated
**Canonical fix plan:** `aint-real-reddit/ANSWER-LEAK-FIX-PLAN.md` (this is the Flutter half of Channel-2)

## Why this exists

The game leaks the answer to the client **before** the player answers. Channel-2 is the
explicit `aiPosition` field carried in the `round_start` WebSocket payload (visible in
network traffic). The **server + web fix is already built and tested** in `aintreal-game`
but is **deliberately held unmerged** because merging auto-deploys and **totally breaks the
store-released app (1.0.1+13)**:

> `RoundStartMessage.fromJson` does a non-nullable cast — `ws_messages.dart:299`
> (`aiPosition: json['aiPosition'] as String`). With the field removed, `round_start`
> is unparseable → **no rounds render in ANY mode** for old-app users until they update.

So the sequence is forced:

1. **This fast-follow** — rework the app to the new server contract, ship to both stores.
2. Wait for adoption.
3. **Then** merge/deploy `aintreal-game` **#17** (Channel-2 server + web) and **#18**
   (WS rejoin/resync + host-disconnect grace). Re-confirm the break at merge time.

## Server contract this app must adopt (from aintreal-game #17 + #18)

- `round_start` **no longer carries `aiPosition`.** Neutral payload only.
- New per-player message **`answer_result { round, choice, correct, aiPosition }`**, sent
  *after* the player's answer locks in (before the marathon early-return). Non-answerers
  get `{ choice: null, timedOut: true }` at round end. Late answers for an ended round are rejected.
- `connected` now carries a neutral mid-round **`roundState`** for resync, and re-delivers
  `answer_result` to players who had already answered.
- Host-disconnect **grace window** (`HOST_GRACE_MS`, default 60s) instead of instant
  `host_left` + game delete.

## Flutter tasks

1. **Add the `answer_result` message type** — `lib/core/websocket/ws_messages.dart`
   - New `WsMessageType.answerResult` + `AnswerResultMessage` (round, choice, correct, aiPosition, timedOut).
   - Wire it into the `switch` at `ws_messages.dart:64`.

2. **Make `aiPosition` nullable / tolerate its absence** — `ws_messages.dart:299` and `:512`
   - `RoundStartMessage.aiPosition` → nullable; stop reading it as the answer source.
   - Check the second carrier at `:512` (demo/other message) — apply the same treatment or drop.

3. **Defer reveal + feedback to `answer_result`** — `lib/features/reveal/reveal_screen.dart`,
   `lib/features/game/*`
   - Remove client-side "is this correct" derivation; show the correct/incorrect reveal only
     when `answer_result` arrives. Neutral round labels until then.

4. **Consume `roundState` resync on (re)connect** — `lib/core/websocket/ws_client.dart`
   - On `connected` mid-round, restore round UI from `roundState` and re-apply any
     re-delivered `answer_result` (don't double-count).

5. **Fix the tab-out teardown** — `ws_client.dart` `didChangeAppLifecycleState` (~`:214`)
   - Same root cause as the leak-fix rejoin gap: on background/foreground, **rejoin and
     resync** instead of forced teardown. #18's `roundState` re-delivery is what makes this safe.

6. **Neutral UI labels** — audit any UI that renders top/bottom as "AI"/"REAL" before the answer.

## Verification

- Multiplayer party game end-to-end against a `wrangler dev` build of `aintreal-game`
  **with #17 + #18 applied** (they are held unmerged — check out the branch/PRs locally).
- Confirm: no `aiPosition` in `round_start` traffic; feedback appears only post-answer;
  tab-out → foreground resyncs mid-round without dropping the player; host phone-lock within
  60s doesn't kill the lobby.

## Release sequencing (do not reorder)

1. Ship this app build to Play + App Store; bump version + build number (see MEMORY versioning).
2. Give it adoption time.
3. Merge `aintreal-game` #17 then #18 (auto-deploys). Re-confirm the old-app break is acceptable.

---

## Bundled Devvit → "real" app port candidates

Since we're cutting an app release anyway, bundle high-value features the Reddit app (now
**2.5.3**) has that the Flutter app lacks. Prioritized for **retention** — the prod stats
(2026-08-01) show acquisition is the bottleneck and replay depth is already healthy (~2×),
so the leverage is in bringing players *back*.

| Candidate | Reddit ver | App state today | Effort | Recommend |
|---|---|---|---|---|
| **Weekly cross-mode leaderboard** | 2.5.0 | endpoint referenced (`endpoints.dart`), no UI | S/M | ✅ bundle — server `/api/stats/leaderboard` exists |
| **Career / "Your career" stats summary** | 2.2 | no career UI | S/M | ✅ bundle — server has stats; strong profile hook |
| **Seen-pair dedup (per-player no-repeat)** | 2.2 | not wired | S/M | ✅ bundle — `user_pair_results` table exists, just unwired |
| **Daily play streak** | (app-native) | in-game marathon streak only, no daily | S | ✅ bundle — cheap retention nudge |
| **Achievement badges** (Sharp Eye / Marathoner / Perfect) | 2.5.0 flair | none | M | ⚠️ optional — flair itself is Reddit-only; port the *badge* concept to profile |
| **Daily Challenge** (shared daily puzzle) | 2.5.2 | none | L | ⛔ defer — needs a Worker cron (`aintreal-game` has no `[triggers]`/`scheduled()` yet) |
| **Opt-in push reminder** | 2.5.0 | partial FCM plumbing | M | ⛔ defer — pairs with Daily Challenge; needs the same cron infra |
| **Monday / Featured Marathon** (scheduled community post) | 2.4/2.3 | n/a | — | ⛔ skip — Reddit-community concept, doesn't map to a solo mobile app |

**Recommended bundle:** weekly leaderboard + career stats + seen-pair dedup + daily streak
(all S/M, all retention). Defer Daily Challenge + push until the game backend gains a
cron/scheduler; skip the Reddit-community-only modes.
