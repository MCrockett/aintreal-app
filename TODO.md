# AIn't Real App - TODO

**Last Updated:** December 14, 2025

## Current Status

- **Platform:** Flutter 3.38.4 (stable)
- **Package:** `com.aintreal`
- **Branch:** `feature/1.4-results-screen`
- **Phase:** M1 Complete, Epic 7.1-7.3 Complete
- **Next:** M2 remaining polish (7.4 Image Preloading)

---

## Theme Overview

| # | Theme | Code | Description |
|---|-------|------|-------------|
| 1 | Core Gameplay | CG | Game screens, WebSocket, real-time play |
| 2 | User Interface | UI | Screens, navigation, theming |
| 3 | Networking | NW | API client, WebSocket, connectivity |
| 4 | Authentication | AU | Firebase Auth, user profiles |
| 5 | Monetization | MO | AdMob integration |
| 6 | Mobile Features | MF | Haptics, push, sharing, deep links |
| 7 | Polish | PO | Animations, sounds, celebrations |
| 8 | Release | RE | Store assets, beta, production |

---

## Priority Levels

- **P0** - Critical: Must have for MVP
- **P1** - High: Important for good UX
- **P2** - Medium: Nice to have
- **P3** - Low: Future enhancement

---

## Epic 1.1: Project Foundation (UI-FOUNDATION)

**Goal:** Set up project architecture and dependencies
**Priority:** P0 - Critical
**Status:** Complete

| Task | Description | Effort | Status |
|------|-------------|--------|--------|
| 1.1.1 | Add all dependencies to pubspec.yaml | 1h | [x] |
| 1.1.2 | Create folder structure per architecture | 1h | [x] |
| 1.1.3 | Set up Riverpod providers structure | 1h | [x] |
| 1.1.4 | Create env.dart with API configuration | 30m | [x] |
| 1.1.5 | Run build_runner for code generation | 15m | [x] |

---

## Epic 1.2: App Shell & Theme (UI-SHELL)

**Goal:** Create app foundation with navigation and theming
**Priority:** P0 - Critical
**Status:** Complete

| Task | Description | Effort | Status |
|------|-------------|--------|--------|
| 1.2.1 | Create dark theme matching web (theme.dart) | 2h | [x] |
| 1.2.2 | Set up app.dart with MaterialApp + GoRouter | 1h | [x] |
| 1.2.3 | Configure routes.dart with all navigation paths | 1h | [x] |
| 1.2.4 | Create basic scaffold structure | 30m | [x] |

---

## Epic 2.1: Home Screen (UI-HOME)

**Goal:** Main entry point with game mode selection
**Priority:** P0 - Critical
**Status:** Complete

| Task | Description | Effort | Status |
|------|-------------|--------|--------|
| 2.1.1 | Create home_screen.dart layout | 2h | [x] |
| 2.1.2 | Build mode_card.dart component (Party, Classic, Marathon) | 2h | [x] |
| 2.1.3 | Add "AIn't Real" branding/logo | 1h | [x] |
| 2.1.4 | Implement mode selection navigation | 1h | [x] |

---

## Epic 2.2: Lobby Screens (UI-LOBBY)

**Goal:** Create and join game flows
**Priority:** P0 - Critical
**Status:** Complete

| Task | Description | Effort | Status |
|------|-------------|--------|--------|
| 2.2.1 | Create create_game_screen.dart with config options | 2h | [x] |
| 2.2.2 | Create join_game_screen.dart with code input | 2h | [x] |
| 2.2.3 | Create lobby_screen.dart layout | 2h | [x] |
| 2.2.4 | Build player_list.dart component | 1h | [x] |
| 2.2.5 | Create game_code_display.dart widget | 1h | [x] |
| 2.2.6 | Add QR code generation for sharing | 1h | [x] |
| 2.2.7 | Implement host controls (Start button) | 1h | [x] |

---

## Epic 3.1: API Client (NW-API)

**Goal:** HTTP client for game creation and joining
**Priority:** P0 - Critical
**Status:** Complete

| Task | Description | Effort | Status |
|------|-------------|--------|--------|
| 3.1.1 | Create api_client.dart with dio | 2h | [x] |
| 3.1.2 | Define endpoints.dart constants | 30m | [x] |
| 3.1.3 | Implement game creation endpoint | 1h | [x] |
| 3.1.4 | Implement game join endpoint | 1h | [x] |
| 3.1.5 | Add error handling and retry logic | 1h | [x] |

---

## Epic 3.2: WebSocket Integration (NW-WS)

**Goal:** Real-time game state synchronization
**Priority:** P0 - Critical
**Status:** Complete

| Task | Description | Effort | Status |
|------|-------------|--------|--------|
| 3.2.1 | Create ws_client.dart with web_socket_channel | 2h | [x] |
| 3.2.2 | Create ws_provider.dart Riverpod provider | 2h | [x] |
| 3.2.3 | Implement message parsing for all server types | 2h | [x] |
| 3.2.4 | Handle reconnection with exponential backoff | 2h | [x] |
| 3.2.5 | Create game_provider.dart for game state | 2h | [x] |

---

## Epic 1.3: Game Screen (CG-GAME)

**Goal:** Active gameplay with image selection
**Priority:** P0 - Critical
**Status:** Complete

| Task | Description | Effort | Status |
|------|-------------|--------|--------|
| 1.3.1 | Create game_screen.dart layout | 2h | [x] |
| 1.3.2 | Build image_pair.dart with cached_network_image | 2h | [x] |
| 1.3.3 | Create timer_bar.dart countdown component | 1h | [x] |
| 1.3.4 | Implement tap-to-answer with WebSocket submission | 2h | [x] |
| 1.3.5 | Create answer_feedback.dart for immediate response | 1h | [x] |
| 1.3.6 | Add "Get Ready" countdown between rounds | 1h | [x] |

---

## Epic 1.4: Results Screen (CG-RESULTS)

**Goal:** Game over display with rankings
**Priority:** P0 - Critical
**Status:** Complete

| Task | Description | Effort | Status |
|------|-------------|--------|--------|
| 1.4.1 | Create game_over_screen.dart layout | 2h | [x] |
| 1.4.2 | Build ranking_list.dart component | 1h | [x] |
| 1.4.3 | Display final scores and winner | 1h | [x] |
| 1.4.4 | Add Play Again / New Game buttons | 1h | [x] |
| 1.4.5 | Show photographer credits | 30m | [ ] |

---

## Epic 7.1: Reveal Sequence (PO-REVEAL)

**Goal:** Animated round-by-round results
**Priority:** P1 - High
**Status:** Complete

| Task | Description | Effort | Status |
|------|-------------|--------|--------|
| 7.1.1 | Create reveal_screen.dart for round reveals | 2h | [x] |
| 7.1.2 | Implement AI image highlight animation | 2h | [x] |
| 7.1.3 | Add score update animations with flutter_animate | 2h | [x] |
| 7.1.4 | Display bonus awards with animations | 1h | [x] |
| 7.1.5 | Show running leaderboard updates | 1h | [x] |

---

## Epic 7.2: Sound Effects (PO-SOUND)

**Goal:** Audio feedback for game events
**Priority:** P1 - High
**Status:** Complete

| Task | Description | Effort | Status |
|------|-------------|--------|--------|
| 7.2.1 | Add correct/wrong answer sounds | 1h | [x] |
| 7.2.2 | Add countdown tick sound | 30m | [x] |
| 7.2.3 | Add bonus award sound | 30m | [x] |
| 7.2.4 | Add game win/lose sounds | 30m | [x] |

---

## Epic 7.3: Celebrations (PO-CELEBRATE)

**Goal:** Victory animations and effects
**Priority:** P1 - High
**Status:** Complete

| Task | Description | Effort | Status |
|------|-------------|--------|--------|
| 7.3.1 | Add confetti animation for winner | 2h | [x] |
| 7.3.2 | Add victory sound/animation | 1h | [x] |
| 7.3.3 | Marathon "Perfect" celebration (26/26) | 1h | [ ] |

---

## Epic 7.4: Image Preloading (PO-PRELOAD)

**Goal:** Smooth image loading experience
**Priority:** P1 - High
**Status:** Planned

| Task | Description | Effort | Status |
|------|-------------|--------|--------|
| 7.4.1 | Preload next round images during current round | 2h | [ ] |
| 7.4.2 | Cache strategy for image management | 1h | [ ] |
| 7.4.3 | Loading placeholders | 1h | [ ] |

---

## Epic 4.1: Firebase Setup (AU-FIREBASE)

**Goal:** Firebase project and configuration
**Priority:** P1 - High
**Status:** Planned

| Task | Description | Effort | Status |
|------|-------------|--------|--------|
| 4.1.1 | Create Firebase project "aintreal" | 1h | [ ] |
| 4.1.2 | Add Android app to Firebase | 30m | [ ] |
| 4.1.3 | Add iOS app to Firebase | 30m | [ ] |
| 4.1.4 | Download and add config files | 30m | [ ] |
| 4.1.5 | Initialize Firebase in main.dart | 30m | [ ] |

---

## Epic 4.2: Auth Integration (AU-AUTH)

**Goal:** Sign-in with Google and Apple
**Priority:** P1 - High
**Status:** Planned

| Task | Description | Effort | Status |
|------|-------------|--------|--------|
| 4.2.1 | Create firebase_auth.dart service | 2h | [ ] |
| 4.2.2 | Create auth_provider.dart Riverpod provider | 2h | [ ] |
| 4.2.3 | Implement Google Sign-In | 2h | [ ] |
| 4.2.4 | Implement Sign in with Apple | 2h | [ ] |
| 4.2.5 | Create sign-in screen with platform buttons | 2h | [ ] |

---

## Epic 4.3: User Profile (AU-PROFILE)

**Goal:** User stats and profile management
**Priority:** P1 - High
**Status:** Planned

| Task | Description | Effort | Status |
|------|-------------|--------|--------|
| 4.3.1 | Implement backend POST /api/auth/firebase | 2h | [ ] |
| 4.3.2 | Create user table in D1 (backend) | 1h | [ ] |
| 4.3.3 | Create profile_screen.dart layout | 2h | [ ] |
| 4.3.4 | Build stats_card.dart component | 1h | [ ] |
| 4.3.5 | Add editable display name | 1h | [ ] |
| 4.3.6 | Add sign out button | 30m | [ ] |

---

## Epic 6.1: Haptic Feedback (MF-HAPTICS)

**Goal:** Tactile feedback for interactions
**Priority:** P2 - Medium
**Status:** Planned

| Task | Description | Effort | Status |
|------|-------------|--------|--------|
| 6.1.1 | Create haptics.dart utility | 1h | [ ] |
| 6.1.2 | Add haptic on answer selection | 30m | [ ] |
| 6.1.3 | Add haptic on timer expiry | 30m | [ ] |
| 6.1.4 | Add haptic on bonus/win | 30m | [ ] |

---

## Epic 6.2: Push Notifications (MF-PUSH)

**Goal:** Game invite notifications
**Priority:** P2 - Medium
**Status:** Planned

| Task | Description | Effort | Status |
|------|-------------|--------|--------|
| 6.2.1 | Set up FCM in Firebase | 1h | [ ] |
| 6.2.2 | Request notification permissions | 1h | [ ] |
| 6.2.3 | Register FCM token with backend | 1h | [ ] |
| 6.2.4 | Implement backend POST /api/user/fcm-token | 1h | [ ] |
| 6.2.5 | Handle notification taps (deep linking) | 2h | [ ] |

---

## Epic 6.3: Native Sharing (MF-SHARE)

**Goal:** Share game invites and results
**Priority:** P2 - Medium
**Status:** Planned

| Task | Description | Effort | Status |
|------|-------------|--------|--------|
| 6.3.1 | Add share button to game over screen | 1h | [ ] |
| 6.3.2 | Generate shareable game invite link | 1h | [ ] |
| 6.3.3 | Share results with score summary | 1h | [ ] |

---

## Epic 6.4: Deep Links (MF-DEEPLINKS)

**Goal:** Direct game join via links
**Priority:** P2 - Medium
**Status:** Planned

| Task | Description | Effort | Status |
|------|-------------|--------|--------|
| 6.4.1 | Configure Android deep links (aintreal://join/CODE) | 1h | [ ] |
| 6.4.2 | Configure iOS universal links | 1h | [ ] |
| 6.4.3 | Handle deep link navigation in GoRouter | 1h | [ ] |

---

## Epic 5.1: AdMob Setup (MO-ADMOB)

**Goal:** Ad platform configuration
**Priority:** P2 - Medium
**Status:** Planned

| Task | Description | Effort | Status |
|------|-------------|--------|--------|
| 5.1.1 | Create AdMob account/app | 1h | [ ] |
| 5.1.2 | Add google_mobile_ads package | 30m | [ ] |
| 5.1.3 | Configure Android AdMob App ID | 30m | [ ] |
| 5.1.4 | Configure iOS AdMob App ID | 30m | [ ] |

---

## Epic 5.2: Ad Implementation (MO-ADS)

**Goal:** Banner, interstitial, and rewarded ads
**Priority:** P2 - Medium
**Status:** Planned

| Task | Description | Effort | Status |
|------|-------------|--------|--------|
| 5.2.1 | Create ad_banner.dart widget | 1h | [ ] |
| 5.2.2 | Add banner to home screen bottom | 30m | [ ] |
| 5.2.3 | Add banner to lobby screen bottom | 30m | [ ] |
| 5.2.4 | Create interstitial ad manager | 1h | [ ] |
| 5.2.5 | Show interstitial after every 3 games | 1h | [ ] |
| 5.2.6 | Create rewarded ad manager | 1h | [ ] |
| 5.2.7 | Add Marathon "Continue" option with rewarded ad | 2h | [ ] |

---

## Epic 8.1: App Assets (RE-ASSETS)

**Goal:** App icon, splash screen
**Priority:** P2 - Medium
**Status:** Planned

| Task | Description | Effort | Status |
|------|-------------|--------|--------|
| 8.1.1 | Create app icon (all sizes) | 2h | [ ] |
| 8.1.2 | Create splash screen | 1h | [ ] |
| 8.1.3 | Configure native splash package | 1h | [ ] |

---

## Epic 8.2: Store Preparation (RE-STORE)

**Goal:** App store submission materials
**Priority:** P3 - Low
**Status:** Planned

| Task | Description | Effort | Status |
|------|-------------|--------|--------|
| 8.2.1 | Create app screenshots (phone + tablet) | 3h | [ ] |
| 8.2.2 | Write app description | 1h | [ ] |
| 8.2.3 | Create feature graphic | 1h | [ ] |
| 8.2.4 | Create/update privacy policy | 2h | [ ] |
| 8.2.5 | Create terms of service | 1h | [ ] |

---

## Epic 8.3: Beta Testing (RE-BETA)

**Goal:** Pre-release testing
**Priority:** P3 - Low
**Status:** Planned

| Task | Description | Effort | Status |
|------|-------------|--------|--------|
| 8.3.1 | Set up TestFlight (iOS) | 1h | [ ] |
| 8.3.2 | Set up Play Console internal testing | 1h | [ ] |
| 8.3.3 | Recruit beta testers | 1h | [ ] |
| 8.3.4 | Collect and address feedback | 4h | [ ] |

---

## Epic 8.4: Production Release (RE-PROD)

**Goal:** App store submission
**Priority:** P3 - Low
**Status:** Planned

| Task | Description | Effort | Status |
|------|-------------|--------|--------|
| 8.4.1 | Submit to Google Play | 2h | [ ] |
| 8.4.2 | Submit to App Store | 2h | [ ] |
| 8.4.3 | Monitor initial reviews | 2h | [ ] |
| 8.4.4 | Address any store feedback | 4h | [ ] |

---

## Milestone Summary

Milestones are built from completed Epics:

| Milestone | Epics Required | Priority |
|-----------|----------------|----------|
| **M1: Playable Game** | 1.1, 1.2, 2.1, 2.2, 3.1, 3.2, 1.3, 1.4 | P0 |
| **M2: Polish** | 7.1, 7.2, 7.3, 7.4 | P1 |
| **M3: Authentication** | 4.1, 4.2, 4.3 | P1 |
| **M4: Mobile Features** | 6.1, 6.2, 6.3, 6.4 | P2 |
| **M5: Monetization** | 5.1, 5.2 | P2 |
| **M6: Release** | 8.1, 8.2, 8.3, 8.4 | P3 |

---

## Backlog (Future)

### Web Polish
- [ ] Achievements system
- [ ] Share results to social
- [ ] First-time tutorial overlay
- [ ] Tap image to view fullscreen

### Future Features
- [ ] Custom game rooms
- [ ] Category/difficulty selection
- [ ] Leaderboards UI
- [ ] Friends & invites

---

## Quick Links

- [CLAUDE.md](CLAUDE.md) - Development workflow
- [DONE.md](DONE.md) - Completed work archive
