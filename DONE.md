# AIn't Real App - Completed Work Archive

This document archives all completed work for the aintreal-app project.

---

## Completed Summary

| Phase | Description | Status |
|-------|-------------|--------|
| Setup | Project creation, repo setup | Completed |
| Design | Architecture decisions, tech stack | Completed |
| M1 | Core game loop (Party, Classic, Marathon) | Completed Dec 2025 |
| M2 | Polish (reveal, sounds, confetti) | Completed Dec 2025 |
| M3 | Authentication (Firebase, Google Sign-In, Sign in with Apple) | Completed Dec 2025 |
| M4 | Mobile features (haptics, deep links, sharing) | Completed Dec 2025 |
| M5 | Monetization (AdMob, IAP) | Completed Dec 2025 |
| M6 | Google Play Release | Completed Jan 2026 |
| M6b | iOS App Store Submission | Submitted Jan 2026 |

---

## Design Phase - December 2025

**Duration:** December 12, 2025
**Status:** Completed

### Project Setup
- Created GitHub repo: `MCrockett/aintreal-app`
- Initialized Flutter project with `com.aintreal` package ID
- Configured for iOS and Android platforms
- Set up `.gitignore` for Flutter

### Tech Stack Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| State Management | Riverpod | Async-friendly, compile-safe, testable |
| Navigation | GoRouter | Deep linking built-in, declarative |
| HTTP Client | dio | Interceptors for auth, retry logic |
| WebSocket | web_socket_channel | Standard, works with Riverpod streams |
| UI Framework | Material 3 | Customizable, consistent cross-platform |
| Image Caching | cached_network_image | Essential for game performance |
| Local Storage | shared_preferences | Settings, session data |
| Animations | flutter_animate | Reveal sequences, celebrations |
| Analytics | Firebase Analytics | Usage tracking from start |
| Ads | AdMob | Banner + interstitial + rewarded |

### Architecture Design
- Feature-based folder structure defined
- Riverpod providers pattern established
- API client approach documented
- WebSocket integration planned

### Documentation Created
- `CLAUDE.md` - Development workflow guidance
- `TODO.md` - Feature backlog with milestones M1-M6
- `DONE.md` - This archive file

---

## M1: Playable Game - December 2025

**Duration:** December 12-14, 2025
**Status:** Complete

### Epic 1.1: Project Foundation (UI-FOUNDATION)
- [x] Added all dependencies to pubspec.yaml
- [x] Created folder structure per architecture
- [x] Set up Riverpod providers structure
- [x] Created env.dart with API configuration
- [x] Ran build_runner for code generation

### Epic 1.2: App Shell & Theme (UI-SHELL)
- [x] Created dark theme matching web (theme.dart)
- [x] Set up app.dart with MaterialApp + GoRouter
- [x] Configured routes.dart with all navigation paths
- [x] Created basic scaffold structure

### Epic 2.1: Home Screen (UI-HOME)
- [x] Created home_screen.dart layout
- [x] Built mode_card.dart component (Party, Classic, Marathon)
- [x] Added "AIn't Real" branding/logo
- [x] Implemented mode selection navigation

### Epic 2.2: Lobby Screens (UI-LOBBY)
- [x] Created create_game_screen.dart with config options
- [x] Created join_game_screen.dart with code input
- [x] Created lobby_screen.dart layout
- [x] Built player_list.dart component
- [x] Created game_code_display.dart widget
- [x] Added QR code generation for sharing
- [x] Implemented host controls (Start button)

### Epic 3.1: API Client (NW-API)
- [x] Created api_client.dart with dio
- [x] Defined endpoints.dart constants
- [x] Implemented game creation endpoint
- [x] Implemented game join endpoint
- [x] Added error handling and retry logic

### Epic 3.2: WebSocket Integration (NW-WS)
- [x] Created ws_client.dart with web_socket_channel
- [x] Created game_state_provider.dart Riverpod provider
- [x] Implemented message parsing for all server types
- [x] Handle reconnection with exponential backoff
- [x] Created ws_messages.dart for game state

### Epic 1.3: Game Screen (CG-GAME)
- [x] Created game_screen.dart layout
- [x] Built image display with cached_network_image
- [x] Created timer_bar countdown component
- [x] Implemented tap-to-answer with WebSocket submission
- [x] Created answer feedback overlay (Correct!/Wrong!)
- [x] Added "Get Ready" countdown between rounds

### Epic 1.4: Results Screen (CG-RESULTS)
- [x] Created results_screen.dart layout
- [x] Built ranking list component
- [x] Display final scores and winner
- [x] Added Play Again / Leave buttons

### Key Bug Fixes (December 14, 2025)
- Fixed StartGameMessage type from 'start' to 'start_game'
- Fixed game logic: players correct when picking AI image
- Fixed FinalRanking JSON parsing (id/correct vs playerId/correctAnswers)
- Added message type mappings for round_reveal and reveal_phase_start

### Known Limitations
- Photographer credits not shown

---

## Epic 7.1: Reveal Sequence (PO-REVEAL) - December 2025

**Duration:** December 14, 2025
**Status:** Complete

### Completed Tasks
- [x] 7.1.1 Created reveal_screen.dart for round reveals
- [x] 7.1.2 Implemented AI image highlight animation (scale + glow)
- [x] 7.1.3 Added score update animations with flutter_animate
- [x] 7.1.4 Display bonus awards with animations
- [x] 7.1.5 Show running leaderboard updates

### Key Implementation Details
- Created `/reveal/:code` route with animated reveal screen
- Shows both images with AI/Real labels animating in
- Player result card shows correct/wrong with response time
- Bonus card displays speed/lucky/streak bonuses when awarded
- Running leaderboard sorted by score with current player highlighted
- Fixed round_reveal JSON parsing:
  - Server sends `isCorrect` not `correct` for PlayerResult
  - Server sends `id` not `playerId` for PlayerScore
  - Added `topUrl`/`bottomUrl` to RevealMessage for image display

### Score Animations (7.1.3)
- Fade-in and slide animations for result card and bonus card
- Staggered slide-in animations for each score item in leaderboard
- Count-up animation for score numbers using IntTween
- Pulse animation on points badge

### Play Again Fix
- Fixed lobby reconnection issue that broke Play Again flow
- Lobby screen now checks if already connected before reconnecting

---

## Epic 7.2: Sound Effects (PO-SOUND) - December 2025

**Duration:** December 14, 2025
**Status:** Complete

### Completed Tasks
- [x] 7.2.1 Added correct/wrong answer sounds
- [x] 7.2.2 Added countdown tick sound
- [x] 7.2.3 Added bonus award sound
- [x] 7.2.4 Added game win/lose sounds

### Key Implementation Details
- Created `SoundService` singleton in `lib/core/audio/sound_service.dart`
- Added `audioplayers` package (v6.1.0) for audio playback
- Created 10 placeholder WAV sound files with distinct tones
- Integrated haptic feedback with HapticFeedback class
- Sound effects with paired haptics for better UX

### Files Created/Modified
- `lib/core/audio/sound_service.dart` (new) - Central sound service
- `assets/sounds/*.wav` (10 files) - Placeholder audio files
- `lib/main.dart` - SoundService initialization
- `lib/features/game/game_screen.dart` - Countdown and timer sounds
- `lib/features/reveal/reveal_screen.dart` - Reveal and result sounds
- `lib/features/results/results_screen.dart` - Victory/game over sounds

### Sound Integration Points
- **game_screen.dart:** "Get Ready" countdown ticks, round start, timer warning, time up
- **reveal_screen.dart:** Reveal animation, correct/wrong result, bonus awards
- **results_screen.dart:** Victory fanfare (winner), game over sound (all)

---

## Epic 7.3: Celebrations (PO-CELEBRATE) - December 2025

**Duration:** December 14, 2025
**Status:** Complete (7.3.3 pending)

### Completed Tasks
- [x] 7.3.1 Confetti animation for winner (already existed in results_screen.dart)
- [x] 7.3.2 Victory sound/animation integrated with confetti

### Implementation Notes
- Confetti uses `confetti` package already in pubspec.yaml
- Confetti fires when player is determined to be winner (rank == 1)
- Victory sound plays for winners, game over sound for others
- Sound and confetti are timed to play together on results screen

### Remaining
- [ ] 7.3.3 Marathon "Perfect" celebration (26/26) - needs mode detection

---

## Epic 7.4: Image Preloading (PO-PRELOAD) - December 2025
**Status:** Complete

- [x] 7.4.1 Preload current round images during Get Ready
- [x] 7.4.2 Cache strategy (CachedNetworkImage)
- [x] 7.4.3 Loading placeholders (shimmer animation)

---

## Epic 4.1: Firebase Setup (AU-FIREBASE) - December 2025
**Status:** Complete

- [x] 4.1.1 Created Firebase project "aintreal"
- [x] 4.1.2 Added Android app to Firebase
- [x] 4.1.3 Added iOS app to Firebase
- [x] 4.1.4 Downloaded and added config files
- [x] 4.1.5 Initialized Firebase in main.dart

---

## Epic 4.2: Auth Integration (AU-AUTH) - December 2025
**Status:** Complete

- [x] 4.2.1 Created firebase_auth.dart service
- [x] 4.2.2 Created auth_provider.dart Riverpod provider
- [x] 4.2.3 Implemented Google Sign-In
- [x] 4.2.4 Sign in with Apple (completed Jan 2026)
- [x] 4.2.5 Created sign-in screen with platform buttons
- [x] 4.2.6 Implemented Guest mode

---

## Epic 4.3: User Profile (AU-PROFILE) - December 2025
**Status:** Complete

- [x] 4.3.1 Implemented backend POST /api/auth/firebase
- [x] 4.3.2 Created user table in D1 (backend)
- [x] 4.3.3 Created profile_screen.dart layout
- [x] 4.3.4 Built stats_card.dart component (per-mode sections)
- [x] 4.3.5 Added editable display name
- [x] 4.3.6 Added sign out button
- [x] 4.3.7 Per-mode stats (Party/Solo/Marathon separate)

---

## Epic 6.1: Haptic Feedback (MF-HAPTICS) - December 2025
**Status:** Complete (integrated with Epic 7.2)

- [x] 6.1.1 Created haptics.dart utility
- [x] 6.1.2 Added haptic on answer selection
- [x] 6.1.3 Added haptic on timer expiry
- [x] 6.1.4 Added haptic on bonus/win

---

## Epic 6.2: Push Notifications (MF-PUSH)
**Status:** Removed (overkill for current scope)

Push notifications removed from scope. Deep linking works via URL schemes instead.

---

## Epic 6.3: Native Sharing (MF-SHARE) - December 2025
**Status:** Complete

- [x] 6.3.1 Added share button to game over screen
- [x] 6.3.2 Generated shareable game invite link
- [x] 6.3.3 Share results with score summary

---

## Epic 6.4: Deep Links (MF-DEEPLINKS) - December 2025
**Status:** Complete

- [x] 6.4.1 Configured Android deep links (aintreal://join/CODE)
- [x] 6.4.2 Configured iOS universal links
- [x] 6.4.3 Handled deep link navigation in GoRouter

---

## Epic 5.1: AdMob Setup (MO-ADMOB) - December 2025
**Status:** Complete

- [x] 5.1.1 Created AdMob account/app (test IDs)
- [x] 5.1.2 Added google_mobile_ads package
- [x] 5.1.3 Configured Android AdMob App ID
- [x] 5.1.4 Configured iOS AdMob App ID

---

## Epic 5.2: Ad Implementation (MO-ADS) - December 2025
**Status:** Complete (core features)

- [x] 5.2.1 Created ad_banner.dart widget
- [x] 5.2.2 Added banner to home screen bottom
- [~] 5.2.3 Lobby screen banner - skipped
- [x] 5.2.4 Created interstitial ad manager
- [x] 5.2.5 Show interstitial when leaving game
- [~] 5.2.6 Rewarded ad manager - future
- [~] 5.2.7 Marathon "Continue" with rewarded ad - future

---

## Epic 8.1: App Assets (RE-ASSETS) - December 2025
**Status:** Complete

- [x] 8.1.1 Created app icon (all sizes)
- [x] 8.1.2 Created splash screen
- [x] 8.1.3 Configured native splash package
- [x] 8.1.4 Configured release signing (keystore)
- [x] 8.1.5 Built signed release AAB

---

## M6: Google Play Release - January 2026

**Status:** PUBLISHED - https://play.google.com/store/apps/details?id=com.aintreal.app

### Completed
- [x] Production AdMob setup (banner + interstitial, Android + iOS ad unit IDs)
- [x] Interstitial frequency logic (5 game grace period, every 3rd after, 5-min cap)
- [x] Interstitial retry on load failure (60s delay + load on each game complete)
- [x] In-app purchase for ad removal ($2.99) - works for both signed-in and guest users
- [x] Privacy policy, Data Safety form, age rating
- [x] Store listing, screenshots, reviewer instructions
- [x] Signed AAB, internal testing, production promotion
- [x] Android 15 edge-to-edge fix (removed deprecated windowFullscreen styles)
- [x] Google Play published and live

### iOS App Store Submission
- [x] Apple Developer account setup
- [x] Sign in with Apple implemented
- [x] iOS AdMob ad unit IDs configured
- [x] iOS IAP product configured
- [x] Submitted to App Store review

### Bug Fixes (January 2026)
- [x] Marathon personal best display on results screen (replaces redundant "Best Streak")
- [x] Interstitial ad not showing after 5+ games (added retry + load on game complete)
- [x] Edge-to-edge warnings fixed (all 4 styles.xml variants)

### v8 Pre-Launch Fixes (January 2026)
- [x] Connection loss resilience: WsClient stays in reconnecting state during retry attempts
- [x] Connection loss resilience: Lobby only shows fatal dialog on transition to disconnected
- [x] Connection loss resilience: New ConnectionLostOverlay widget for game + reveal screens
- [x] Account deletion completeness: Delete user_pair_results on account delete (compliance)
- [x] iOS ATT: Added NSUserTrackingUsageDescription to Info.plist for AdMob
- [x] iOS SKAdNetwork: Expanded from 1 to 19 network identifiers for better ad fill

---

## Milestone Summary

| Milestone | Status | Date |
|-----------|--------|------|
| M1: Playable Game | Complete | Dec 2025 |
| M2: Polish | Complete | Dec 2025 |
| M3: Authentication | Complete | Dec 2025 |
| M4: Mobile Features | Complete | Dec 2025 |
| M5: Monetization | Complete | Dec 2025 |
| M6: Google Play Release | Complete | Jan 2026 |
| M6b: iOS Submission | In Review | Jan 2026 |

---

---

## February 2026

### Guest Name Picker (2026-02-10)
- Replaced text input with 3-choice name picker + shuffle button on join screen
- Same `{Adjective}{Noun}{Number}` format as readable guest names from +11
- Same word lists shared with web party client

### Debug Logging Fix (2026-02-10)
- Changed `debugLogDiagnostics: true` to `kDebugMode` in GoRouter config
- Prevents verbose route logging in release builds

---

## Document Last Updated

February 10, 2026
