# AIn't Real App - TODO

**Last Updated:** December 12, 2025

## Current Status

- **Platform:** Flutter 3.38.4 (stable)
- **Package:** `com.aintreal`
- **Branch:** `main`
- **Architecture:** Design complete, ready for M1 implementation

---

## Milestones Overview

| Milestone | Description | Status |
|-----------|-------------|--------|
| M1 | Core Game Loop | Planned |
| M2 | Polish & Parity | Planned |
| M3 | Authentication | Planned |
| M4 | Mobile Features | Planned |
| M5 | Monetization | Planned |
| M6 | Release | Planned |

---

## M1: Core Game Loop

**Goal:** Playable game connecting to existing backend
**Priority:** P0 - Current Focus
**Status:** Planned

### 1.1: Project Setup (APP-SETUP)
**Effort:** 2-3 hours

- [ ] 1.1.1: Add all dependencies to pubspec.yaml
- [ ] 1.1.2: Create folder structure per CLAUDE.md architecture
- [ ] 1.1.3: Set up Riverpod providers
- [ ] 1.1.4: Create env.dart with API configuration
- [ ] 1.1.5: Run build_runner for code generation

### 1.2: Theme & App Shell (APP-THEME)
**Effort:** 2 hours

- [ ] 1.2.1: Create dark theme matching web (theme.dart)
- [ ] 1.2.2: Set up app.dart with MaterialApp + GoRouter
- [ ] 1.2.3: Configure routes.dart with all navigation paths
- [ ] 1.2.4: Create basic scaffold with bottom nav placeholder

### 1.3: Home Screen (APP-HOME)
**Effort:** 3-4 hours

- [ ] 1.3.1: Create home_screen.dart layout
- [ ] 1.3.2: Build mode_card.dart component (Party, Classic, Marathon)
- [ ] 1.3.3: Add "AIn't Real" branding/logo
- [ ] 1.3.4: Implement mode selection navigation

### 1.4: Create/Join Flow (APP-LOBBY)
**Effort:** 4-5 hours

- [ ] 1.4.1: Create create_game_screen.dart with config options
- [ ] 1.4.2: Create join_game_screen.dart with code input
- [ ] 1.4.3: Implement API client (dio) for game creation/joining
- [ ] 1.4.4: Create game_code_display.dart widget
- [ ] 1.4.5: Add QR code generation for game sharing

### 1.5: Lobby Screen (APP-LOBBY-UI)
**Effort:** 3-4 hours

- [ ] 1.5.1: Create lobby_screen.dart layout
- [ ] 1.5.2: Build player_list.dart component
- [ ] 1.5.3: Add game config display (rounds, time, bonuses)
- [ ] 1.5.4: Implement host controls (Start button)
- [ ] 1.5.5: Connect WebSocket for real-time player updates

### 1.6: WebSocket Integration (APP-WS)
**Effort:** 4-5 hours

- [ ] 1.6.1: Create ws_client.dart with web_socket_channel
- [ ] 1.6.2: Create ws_provider.dart Riverpod provider
- [ ] 1.6.3: Implement message parsing for all server message types
- [ ] 1.6.4: Handle reconnection with exponential backoff
- [ ] 1.6.5: Create game_provider.dart for game state management

### 1.7: Game Screen (APP-GAME)
**Effort:** 5-6 hours

- [ ] 1.7.1: Create game_screen.dart layout
- [ ] 1.7.2: Build image_pair.dart widget with cached_network_image
- [ ] 1.7.3: Create timer_bar.dart countdown component
- [ ] 1.7.4: Implement tap-to-answer with WebSocket submission
- [ ] 1.7.5: Create answer_feedback.dart for immediate response
- [ ] 1.7.6: Add "Get Ready" countdown between rounds

### 1.8: Results Screen (APP-RESULTS)
**Effort:** 3-4 hours

- [ ] 1.8.1: Create game_over_screen.dart layout
- [ ] 1.8.2: Build ranking_list.dart component
- [ ] 1.8.3: Display final scores and winner
- [ ] 1.8.4: Add Play Again / New Game buttons
- [ ] 1.8.5: Show photographer credits

---

## M2: Polish & Parity

**Goal:** Match web experience with animations and all features
**Priority:** P1
**Status:** Planned

### 2.1: Reveal Sequence (APP-REVEAL)
**Effort:** 4-5 hours

- [ ] 2.1.1: Create reveal_screen.dart for round-by-round reveals
- [ ] 2.1.2: Implement AI image highlight animation
- [ ] 2.1.3: Add score update animations with flutter_animate
- [ ] 2.1.4: Display bonus awards with animations
- [ ] 2.1.5: Show running leaderboard updates

### 2.2: Sound Effects (APP-SOUND)
**Effort:** 2-3 hours

- [ ] 2.2.1: Add correct/wrong answer sounds
- [ ] 2.2.2: Add countdown tick sound
- [ ] 2.2.3: Add bonus award sound
- [ ] 2.2.4: Add game win/lose sounds

### 2.3: Bonus Display (APP-BONUS)
**Effort:** 2 hours

- [ ] 2.3.1: Display Speed Bonus (+50) for fastest
- [ ] 2.3.2: Display all random bonus types
- [ ] 2.3.3: Add bonus-specific animations

### 2.4: Marathon Mode Polish (APP-MARATHON)
**Effort:** 2-3 hours

- [ ] 2.4.1: Create marathon end screen showing streak
- [ ] 2.4.2: Show which image ended the run
- [ ] 2.4.3: Add "Perfect Marathon" celebration (all 26 correct)

### 2.5: Celebrations (APP-CELEBRATE)
**Effort:** 2 hours

- [ ] 2.5.1: Add confetti animation for winner
- [ ] 2.5.2: Add victory sound/animation
- [ ] 2.5.3: Add achievement unlock animations

### 2.6: Image Preloading (APP-PRELOAD)
**Effort:** 2 hours

- [ ] 2.6.1: Preload next round images during current round
- [ ] 2.6.2: Cache strategy for image management
- [ ] 2.6.3: Loading placeholders

---

## M3: Authentication

**Goal:** Firebase Auth with Google and Apple sign-in
**Priority:** P1
**Status:** Planned

### 3.1: Firebase Setup (APP-FIREBASE)
**Effort:** 2-3 hours

- [ ] 3.1.1: Create Firebase project "aintreal"
- [ ] 3.1.2: Add Android app to Firebase
- [ ] 3.1.3: Add iOS app to Firebase
- [ ] 3.1.4: Download and add config files
- [ ] 3.1.5: Initialize Firebase in main.dart

### 3.2: Auth Integration (APP-AUTH)
**Effort:** 4-5 hours

- [ ] 3.2.1: Create firebase_auth.dart service
- [ ] 3.2.2: Create auth_provider.dart Riverpod provider
- [ ] 3.2.3: Implement Google Sign-In
- [ ] 3.2.4: Implement Sign in with Apple
- [ ] 3.2.5: Create sign-in screen with platform buttons

### 3.3: Backend Integration (APP-AUTH-API)
**Effort:** 3-4 hours

- [ ] 3.3.1: Implement POST /api/auth/firebase endpoint (backend)
- [ ] 3.3.2: Create user table in D1 (backend)
- [ ] 3.3.3: Link Firebase UID to user profile
- [ ] 3.3.4: Add auth token to API requests

### 3.4: Profile Screen (APP-PROFILE)
**Effort:** 3-4 hours

- [ ] 3.4.1: Create profile_screen.dart layout
- [ ] 3.4.2: Build stats_card.dart component
- [ ] 3.4.3: Display user stats (games, wins, streaks)
- [ ] 3.4.4: Add editable display name
- [ ] 3.4.5: Add sign out button

---

## M4: Mobile Features

**Goal:** Native mobile experience
**Priority:** P2
**Status:** Planned

### 4.1: Haptic Feedback (APP-HAPTICS)
**Effort:** 1-2 hours

- [ ] 4.1.1: Create haptics.dart utility
- [ ] 4.1.2: Add haptic on answer selection
- [ ] 4.1.3: Add haptic on timer expiry
- [ ] 4.1.4: Add haptic on bonus/win

### 4.2: Push Notifications (APP-PUSH)
**Effort:** 4-5 hours

- [ ] 4.2.1: Set up FCM in Firebase
- [ ] 4.2.2: Request notification permissions
- [ ] 4.2.3: Register FCM token with backend
- [ ] 4.2.4: Implement POST /api/user/fcm-token (backend)
- [ ] 4.2.5: Handle notification taps (deep linking)

### 4.3: Native Sharing (APP-SHARE)
**Effort:** 2-3 hours

- [ ] 4.3.1: Add share button to game over screen
- [ ] 4.3.2: Generate shareable game invite link
- [ ] 4.3.3: Share results with score summary

### 4.4: Deep Links (APP-DEEPLINKS)
**Effort:** 2-3 hours

- [ ] 4.4.1: Configure Android deep links (aintreal://join/CODE)
- [ ] 4.4.2: Configure iOS universal links
- [ ] 4.4.3: Handle deep link navigation in GoRouter

### 4.5: App Assets (APP-ASSETS)
**Effort:** 2-3 hours

- [ ] 4.5.1: Create app icon (all sizes)
- [ ] 4.5.2: Create splash screen
- [ ] 4.5.3: Configure native splash package

---

## M5: Monetization

**Goal:** AdMob integration
**Priority:** P2
**Status:** Planned

### 5.1: AdMob Setup (APP-ADMOB)
**Effort:** 2-3 hours

- [ ] 5.1.1: Create AdMob account/app
- [ ] 5.1.2: Add google_mobile_ads package
- [ ] 5.1.3: Configure Android AdMob App ID
- [ ] 5.1.4: Configure iOS AdMob App ID

### 5.2: Banner Ads (APP-ADS-BANNER)
**Effort:** 2 hours

- [ ] 5.2.1: Create ad_banner.dart widget
- [ ] 5.2.2: Add banner to home screen bottom
- [ ] 5.2.3: Add banner to lobby screen bottom
- [ ] 5.2.4: Hide banner during gameplay

### 5.3: Interstitial Ads (APP-ADS-INTER)
**Effort:** 2 hours

- [ ] 5.3.1: Create interstitial ad manager
- [ ] 5.3.2: Show after every 3 completed games
- [ ] 5.3.3: Track game count in preferences

### 5.4: Rewarded Ads (APP-ADS-REWARD)
**Effort:** 2-3 hours

- [ ] 5.4.1: Create rewarded ad manager
- [ ] 5.4.2: Add "Continue" option in Marathon mode
- [ ] 5.4.3: Grant extra life after watching ad

---

## M6: Release

**Goal:** App store submission
**Priority:** P3
**Status:** Planned

### 6.1: Store Assets (APP-STORE)
**Effort:** 4-5 hours

- [ ] 6.1.1: Create app screenshots (phone + tablet)
- [ ] 6.1.2: Write app description
- [ ] 6.1.3: Create feature graphic
- [ ] 6.1.4: Prepare promotional video (optional)

### 6.2: Legal (APP-LEGAL)
**Effort:** 2-3 hours

- [ ] 6.2.1: Create/update privacy policy
- [ ] 6.2.2: Create terms of service
- [ ] 6.2.3: Set up support email

### 6.3: Beta Testing (APP-BETA)
**Effort:** 2-3 hours

- [ ] 6.3.1: Set up TestFlight (iOS)
- [ ] 6.3.2: Set up Play Console internal testing
- [ ] 6.3.3: Recruit beta testers
- [ ] 6.3.4: Collect and address feedback

### 6.4: Production Release (APP-PROD)
**Effort:** 2-3 hours

- [ ] 6.4.1: Submit to Google Play
- [ ] 6.4.2: Submit to App Store
- [ ] 6.4.3: Monitor initial reviews
- [ ] 6.4.4: Address any store feedback

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
