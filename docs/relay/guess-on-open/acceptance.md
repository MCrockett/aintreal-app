# Acceptance ledger: guess on open

Checks that depend on devices or later events, per the owner rule of
2026-10-01. The build is reviewed on code and tests; these are tracked here.

| Check | Trigger | Status |
|-------|---------|--------|
| iPad and Galaxy S24: home guess, then Next pair, shows "Round 2 / 6" (R9) | 1.1.0 build on TestFlight / Play internal | Open |
| End-of-game results list round 1 with the home answer (R9) | Same build | Open |
| Airplane mode on home shows "Couldn't load a pair · Tap to retry"; turning it off and tapping loads a pair (F1) | Same build | Open |
| Backgrounding home for over 15 minutes, then resuming, shows a new pair (F2) | Same build | Open |
| Home layout on the iPad and S24 has no clipping, with the pair and mode row on one screen (R11) | Same build | Open |
| home_pair_shown, home_guess and home_game_started appear in Firebase Analytics (R10) | 1.1.0 live, first day | Open |

Release record: 1.1.0+16 (Android versionCode 16; iOS build number is the
release tools' UTC timestamp). Store text: docs/store/1.1.0/listing.json.
Rollback: the server changes are additive (aintreal-game #21, #23), so 1.0.x
keeps working; if 1.1.0 misbehaves, halt the Play rollout and remove the iOS
version from sale or ship a 1.1.1 fix.
