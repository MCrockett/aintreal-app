# att-after-first-screen

Adopted from PR #24: fix(8.1): ask for tracking after the first screen; declare no non-exempt encryption

Found in the 1.0.2 device pass: the App Tracking Transparency prompt was requested during startup, before the app was active, so iOS skipped it on first launch.

- The home screen now asks after its first frame (only while undecided and ads aren't removed), then shows the first-launch How to Play.
- Info.plist declares `ITSAppUsesNonExemptEncryption = false` (HTTPS only); the shared release tools' iOS package check requires it.
- TODO: the 1.0.2 entry and a Next: 1.1 section.

Tests: 2 new, 275 pass. Device check: a fresh iPad install showed the tracking prompt, then How to Play.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
