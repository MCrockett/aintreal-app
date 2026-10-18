# Plan: tracking prompt after the first screen + export compliance (1.0.2)

Found in the 1.0.2 device pass (2026-10-17): AdService.init requested App Tracking Transparency
before runApp, while the app was still launching, so iOS skipped the prompt on first launch
(status notDetermined until a later launch). App Review looks for the prompt; new installs went
without a decision.

## Tasks
- `AdService.init` no longer requests ATT. New `AdService.requestTrackingIfNeeded()` asks only when
  the status is notDetermined and ads are not removed (`shouldRequestTracking`, pure, tested).
- `HomeScreen.initState` post-frame: await the tracking request, then the first-launch How to Play,
  so the two dialogs never overlap.
- `ios/Runner/Info.plist`: `ITSAppUsesNonExemptEncryption` false (HTTPS only), required by the
  shared release tools' package check (UpstreamPartners #63).
- TODO.md: the 1.0.2 entry and a "Next: 1.1" section (version only in test mode, home redesign,
  weekly leaderboard), docs only.

## Tests
- `test/unit/tracking_prompt_test.dart`: asks only when undecided; never after ad removal.
- Gates: `flutter test` (275 pass), `flutter analyze` on changed files clean. No CI in this repo.
- Device: fresh install on iPad (2026-10-18) showed the tracking prompt, then How to Play.
