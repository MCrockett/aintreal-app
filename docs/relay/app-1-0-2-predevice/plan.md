# Plan: 1.0.2 pre-device-pass fixes (aintreal-app PR #20)

Source: aint-real `docs/organic-deep-dive-2026-10-15.md`. Owner approved
2026-10-15. Lands before the 1.0.2 device pass.

## Tasks
1. **No email as player name.** `AuthStateAuthenticated.displayName` fell
   back to `user.email` when Firebase had no display name (Sign in with
   Apple, Hide my email); the email reached the public leaderboard. Add
   `publicPlayerName({displayName, uid})`: trimmed display name if non-empty
   and not email-like, else `GuestNameGenerator.forSeed(uid)` (stable per uid,
   own FNV-1a hash so it does not depend on `String.hashCode`).
   Tests: `test/unit/public_player_name_test.dart`.
2. **First-launch How to Play.** Show the existing dialog once from the home
   screen (post-frame), remembered via SharedPreferences `how_to_play_seen`.
   Existing home/app widget tests mark it seen. Tests:
   `test/widget/how_to_play_first_launch_test.dart`.
3. **Test plan.** PARTY_TEST_PLAN.md: 10.3 matches +14/#19 ad rules, new 10.4
   Play Billing 8 checks, new 10.5 first-launch check.
4. **Android debug cleartext.** Debug manifest only: allow http to a local
   wrangler server for the device pass. Release builds unchanged.

## Gates
`flutter analyze` (no new issues) and `flutter test` (all pass).

## Out of scope
Server-side masking of stored names (aintreal-game PR #19). Easier first
rounds (server, later).
