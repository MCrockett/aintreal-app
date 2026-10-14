# app-1-0-2-finishers

Adopted from PR #19: feat(5.2): 1.0.2 finishers: host banner, version header, Play Billing 8, no host interstitial

## Why
The party host's phone is usually the shared screen in a room (a TV, a projector, or a phone passed around). An interstitial there interrupts everyone, while web guests never see one. Interstitials earn pennies a month, so the trade isn't close.

## Changes
- `AdService.allowsPostGameInterstitial({mode, isHost})`: a pure policy function. Solo modes (classic, marathon) are allowed, party guests are allowed, and the party host is skipped. An unknown or null mode counts as party, matching `_parseGameMode`.
- `results_screen.dart`: New Game and Leave Game route through `_maybeShowPostGameAd()`. Solo Play Again was already solo-only and is unchanged. `recordGameCompleted` counting is unaffected.
- `test/unit/post_game_ad_test.dart`: 4 tests. I wrote them first and confirmed they failed before the change.

## Verification
- `flutter analyze` is clean on the touched dirs. The new tests pass, and the full suite is 249 passing.
- `test/widget_test.dart` ("App renders home screen") was failing on main because of a 31px logo overflow. That's fixed here (see below), and the full suite is now **250/250**.
- Device pass: add "host finishes party game → New Game → no interstitial" to `PARTY_TEST_PLAN.md` for the 1.0.2 run.

**Also in this PR:**
- `lib/widgets/logo.dart`: the logo is wrapped in `FittedBox(fit: BoxFit.scaleDown)`, so it shrinks rather than overflowing on narrow screens or with large accessibility text.
- `PARTY_TEST_PLAN.md`: device-pass checks for the host no-ad change, how to join an invite while testing locally, and a new §10 for Android, which gets the +14 changes for the first time.

Ships with 1.0.2+15. No version bump needed.

## Play Billing Library 8 (added 2026-10-13)
- `in_app_purchase` ^3.2.0 → ^3.3.1, which resolves `in_app_purchase_android` 0.5.0 with `com.android.billingclient:billing:8.0.0` (was 7.1.1). Play Console flagged Billing 7 as deprecated: updates using it may be rejected after Aug 31, 2026.
- The app uses only `purchaseStream`, `buyNonConsumable` and `restorePurchases`; the 0.5.0 breaking change (`queryPurchaseHistory` removed) doesn't touch it.
- Verified: 250/250 tests pass; `flutter build apk --debug` resolves billing 8.0.0.
- Device check: Profile → Restore Purchases and the Remove Ads purchase sheet on Android.

## Host reconnecting banner + version header (added 2026-10-13)
- Parses `host_disconnected` (aintreal-game #18) into `GameState.hostAway`. Guests see "Host reconnecting… hang tight." in the lobby and on results until the host's `player_connected` arrives or `host_left` ends the game. A guest who reconnects mid-window derives it from the players list. Older servers never send the message, so nothing changes against prod today. 5 new unit tests (`test/unit/host_away_test.dart`); PARTY_TEST_PLAN 0.B gets a check.
- API requests now send `X-App-Version` (native only; the server's CORS allow-list doesn't include it). Pre-1.0.2 apps send none, so the server can tell them to update at the #17 cutover.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
