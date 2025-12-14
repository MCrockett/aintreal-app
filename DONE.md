# AIn't Real App - Completed Work Archive

This document archives all completed work for the aintreal-app project.

---

## Completed Summary

| Phase | Description | Status |
|-------|-------------|--------|
| Setup | Project creation, repo setup | Completed |
| Design | Architecture decisions, tech stack | Completed |

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

## Document Last Updated

December 14, 2025
