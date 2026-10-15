# app-1-0-2-predevice

Adopted from PR #20: fix(5.2): 1.0.2 pre-device-pass: no email as player name, first-launch How to Play, test plan

Lands before the 1.0.2 device pass:
- **Privacy fix:** `AuthStateAuthenticated.displayName` no longer falls back to the account email. Sign-ins without a display name (Sign in with Apple, Hide my email) now get a guest-style name derived from the uid (`GuestNameGenerator.forSeed`), stable across launches. The email reached the public leaderboard (5 visible on 2026-10-15). Server-side masking for stored names and old apps: aintreal-game #19.
- **First-launch How to Play:** the dialog opens once on the first home screen (key `how_to_play_seen` in SharedPreferences); the button still opens it any time. Existing players see it once after updating. New test plan item 10.5.
- PARTY_TEST_PLAN.md: 10.3 no longer asks for a home-screen banner (removed in +14) and checks that the party host never gets a post-game interstitial (#19). New 10.4 Play Billing 8 checks. Build line points at main.
- Android **debug** manifest allows cleartext http so a debug build can reach a local wrangler server on the Mac's LAN IP. Release builds are unchanged.

Tests: 261 pass, including 4 new in `test/unit/public_player_name_test.dart` and 2 in `test/widget/how_to_play_first_launch_test.dart`. Analyzer: the same 4 issues as before, none in changed files.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
