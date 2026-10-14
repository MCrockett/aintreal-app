# 1.0.2 finishers (PR #19)

The last app changes before the 1.0.2+15 store release. Main already has the Channel-2 fast-follow (PR #17) and the version sync (PR #18). The release itself, the device pass and the store uploads happen after this merges and are out of scope here.

## Tasks

1. **No post-game interstitial for the party host.** The host's screen is often the shared one, so a full-screen ad there interrupts the room. `AdService.allowsPostGameInterstitial(mode, isHost)` returns true for solo modes (classic, marathon) and party guests, false for the party host and for an unknown mode (treated as party, matching `_parseGameMode`). The results screen checks it before showing the interstitial on New Game and Leave Game. Tests: `test/unit/post_game_ad_test.dart`.
2. **Logo scales down instead of overflowing** on narrow screens or large text sizes (`FittedBox(fit: BoxFit.scaleDown)` in `lib/widgets/logo.dart`). This also fixes `test/widget_test.dart`, which fails on main.
3. **Google Play Billing Library 8.** Play Console flagged Billing 7 as deprecated, with updates using it at risk of rejection after Aug 31, 2026. `in_app_purchase` goes from ^3.2.0 to ^3.3.1, which resolves `in_app_purchase_android` 0.5.0 with `com.android.billingclient:billing:8.0.0`. The app uses only `purchaseStream`, `buyNonConsumable` and `restorePurchases`, which this upgrade doesn't change; the breaking change in 0.5.0 (`queryPurchaseHistory` removed) is not used. `pubspec.lock` is gitignored in this repo, so the constraint is what pins it.
4. **"Host reconnecting" banner for guests.** The server change in aintreal-game PR #18 (not yet deployed) sends `host_disconnected {graceMs}` when the host drops in the lobby or on results, and holds the game for 60s. The host coming back sends `player_connected`; otherwise `host_left` follows. The app parses the message into `GameState.hostAway`:
   - set (guests only) on `host_disconnected`;
   - cleared when a `player_connected` / `player_joined` players list shows the host connected, and on `host_left`;
   - on `connected` (a guest reconnecting during the window), derived from the players list.
   A `HostAwayBanner` shows "Host reconnecting… hang tight." to guests in the lobby and on the results screen. Prod today never sends the message, so behavior there is unchanged. Tests: `test/unit/host_away_test.dart`. Device check added to `PARTY_TEST_PLAN.md` 0.B.
5. **`X-App-Version` header on API requests (native only).** 1.0.1 sends no version, so when aintreal-game #17 deploys (the neutral round contract that 1.0.1 can't render), the server can answer old apps on create/join with an "update required" error. Web builds skip the header because the server's CORS allow-list doesn't include it.

## Gates

`flutter analyze lib` (no new issues) and `flutter test` (all pass). A debug Android build resolves billing 8.0.0.

## Out of scope

The server-side "update required" gate (aintreal-game, separate repo), the device pass, store builds and uploads.
