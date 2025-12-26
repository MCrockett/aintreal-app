# App Store Learning Audit

This document captures what is already documented for shipping AIn't Real to the app stores, what is missing, and the step order for future sessions. It is simulator-first and emphasizes moving from manual release to CI/CD as launch approaches.

## What’s Already Documented
- Flutter stack and architecture are defined in `CLAUDE.md`.
- Local run/build commands exist (`flutter run`, `flutter build`, `build_runner`).
- Backend endpoints and environment variables are documented in project docs.
- Branch and commit conventions are documented for the mobile app.
- Web deployment script exists (`deploy.sh`) for Flutter web (not app stores).

## Gaps to Ship to App Store & Google Play

### Shared (iOS + Android)
- Versioning strategy (semantic + build number mapping to `pubspec.yaml`).
- Release checklist (QA gates, crash-free targets, analytics checks).
- Store assets (icons, screenshots, promo text, privacy labels).
- Privacy/compliance (data collection inventory, consent, analytics disclosure).
- Crash reporting (e.g., Firebase Crashlytics) and thresholds.
- Ads policy checks (AdMob), age rating, and content guidelines.
- Release notes template and changelog strategy.

### iOS (App Store)
- Apple Developer account access workflow and team roles.
- Code signing: certificates, provisioning profiles, keychain handling.
- Build/archive commands and TestFlight upload steps.
- App Store Connect setup: app record, bundle ID, capabilities.
- Privacy nutrition labels and ATT (if applicable).
- Export compliance and encryption declarations.

### Android (Google Play)
- Keystore creation and secure storage strategy.
- Gradle signing config and build types.
- Play Console setup and release tracks.
- Target SDK and Play Integrity requirements.
- Data safety form and ads declarations.

## CI/CD Strategy (Manual → Automated)

### Manual (Now)
- Build locally (`flutter build apk` / `flutter build ipa`).
- Upload via Play Console / TestFlight.
- Maintain a checklist to avoid missed steps.

### Automated (Near Launch)
- Default path: GitHub Actions (familiar and repo-native).
- Alternatives: Codemagic or Bitrise for mobile-focused signing and store uploads.
- Plan to migrate to full CI/CD once signing and store workflows are stable.

## Simulator-First Testing Plan
- Primary iteration on iOS Simulator + Android Emulator.
- Minimum real-device checks: one iOS and one Android device per release candidate.
- Track gaps: push notifications, camera, performance on low-end hardware.

## Recommended Docs to Add
- `RELEASE.md`: manual release steps for iOS and Android.
- `CI_CD.md`: GitHub Actions baseline and alternatives.
- `PRIVACY.md`: data collection inventory and store disclosures.
- `STORE_ASSETS.md`: asset specs and checklist.

## Suggested Fill-In Order
1. `RELEASE.md` manual steps (iOS + Android).
2. `PRIVACY.md` (data collection + AdMob + Firebase).
3. `CI_CD.md` (GitHub Actions baseline + alternatives).
4. Store metadata checklist + asset specs.
5. Device testing checklist + release QA rubric.

## Git Note
There are existing local modifications and untracked files in this repo. I left them untouched per instruction. When you’re ready, we can create a new branch before making additional changes.
