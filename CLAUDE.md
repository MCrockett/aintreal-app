# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Quick Reference

- **Feature Tracking**: See [TODO.md](TODO.md) for backlog and milestones
- **Completed Work**: See [DONE.md](DONE.md) for archived completed work
- **Project Overview**: See parent [aintreal-game/CLAUDE.md](../aintreal-game/CLAUDE.md)

## Project Context

AIn't Real mobile app - Flutter implementation for iOS and Android.

- **Type**: Flutter app connecting to existing Cloudflare Workers backend
- **Package**: `com.aintreal.app`
- **Flutter**: 3.38.4 (stable) at `~/Library/flutter`
- **Backend**: `api.aint-real.com` (same as web)

## Tech Stack

| Category | Choice |
|----------|--------|
| State Management | Riverpod |
| Navigation | GoRouter |
| HTTP Client | dio |
| WebSocket | web_socket_channel |
| UI Framework | Material 3 (dark theme) |
| Image Caching | cached_network_image |
| Analytics | Firebase Analytics |
| Ads | AdMob (banner + interstitial) |
| In-App Purchases | in_app_purchase |

## Architecture

```
lib/
├── main.dart                 # App entry, Firebase init
├── app.dart                  # MaterialApp + GoRouter setup
├── config/
│   ├── env.dart              # API URLs, environment flags
│   ├── routes.dart           # GoRouter route definitions
│   └── theme.dart            # Material 3 theme (dark mode)
├── core/
│   ├── ads/                  # AdMob service (banner + interstitial)
│   ├── api/                  # dio client, endpoints
│   ├── auth/                 # Firebase auth
│   ├── audio/                # Sound effects service
│   ├── purchases/            # In-app purchase service
│   ├── sharing/              # Share service
│   ├── websocket/            # WebSocket client, Riverpod provider
│   └── storage/              # SharedPreferences
├── features/
│   ├── home/                 # Home screen, mode selection
│   ├── lobby/                # Create/join game, player list
│   ├── game/                 # Active gameplay
│   ├── results/              # Game over, rankings
│   └── profile/              # User profile, stats, settings
├── models/                   # Data models
├── widgets/                  # Shared UI components
└── utils/                    # Helpers, extensions
```

## Development Commands

```bash
# Run app
cd aintreal-app && flutter run

# Run with local backend
flutter run --dart-define=API_BASE=http://localhost:8789

# Install dependencies
flutter pub get

# Code generation (Riverpod)
dart run build_runner build

# Build release
flutter build apk --release
flutter build ios --release
flutter build appbundle --release  # For Google Play
```

## Versioning

Version is managed in `pubspec.yaml` using the format: `X.Y.Z+N`

- **X.Y.Z** = Semantic version (e.g., `1.0.0`)
  - X = Major (breaking changes)
  - Y = Minor (new features)
  - Z = Patch (bug fixes)
- **+N** = Build number (must increment for each store upload)

**Rules:**
- ALWAYS increment build number (+N) before each Play Store / App Store upload
- Build number must be unique and increasing (can't reuse or go backwards)
- Semantic version can stay same for bug fixes (just increment build number)

**Current:** Check `pubspec.yaml` for latest version

**History:**
| Build | Version | Date | Notes |
|-------|---------|------|-------|
| +1 | 1.0.0 | Dec 2025 | Initial internal test |
| +2 | 1.0.0 | Dec 2025 | First Play Store submission |
| +3 | 1.0.0 | Jan 2026 | Test fixes, UI polish, color scheme update |
| +4 | 1.0.0 | Jan 2026 | Banner ad hides immediately after purchase |

## Theme-Epic-Task System

Work is organized using Theme.Epic.Task numbering:

**Format:** `Theme.Epic.Task (SHORT-CODE)`
- **Theme (1-8):** Major area (e.g., 1 = Core Gameplay)
- **Epic (X.1-X.N):** Group of related tasks
- **Task (X.X.1-X.X.N):** Individual unit of work

**8 Themes:**
1. Core Gameplay (CG) | 2. User Interface (UI) | 3. Networking (NW)
4. Authentication (AU) | 5. Monetization (MO) | 6. Mobile Features (MF)
7. Polish (PO) | 8. Release (RE)

**Priority Levels:**
- P0 = Critical (MVP)
- P1 = High (good UX)
- P2 = Medium (nice to have)
- P3 = Low (future)

See [TODO.md](TODO.md) for full Epic/Task breakdown.

---

## Git Workflow

**Branch Naming**: `<type>/<theme>.<epic>.<task>-description`

```bash
# Examples
feature/1.1.1-add-dependencies
feature/2.1.1-home-screen-layout
fix/3.2.4-websocket-reconnect
```

**Types**: `feature`, `fix`, `refactor`, `test`, `docs`, `chore`

**Critical Rules**:
- NEVER merge directly to main - use Pull Requests
- ALWAYS push branches for user review
- Branch from updated main for each new feature

**Workflow**:
```bash
# Start new feature
git checkout main
git pull origin main
git checkout -b feature/1.1.1-add-dependencies

# Complete and push
git add -A && git commit -m "feat(1.1.1): add project dependencies"
git push origin feature/1.1.1-add-dependencies
# STOP - let user review and create PR
```

## Commit Format

```
<type>(<theme>.<epic>.<task>): <short summary>

[Theme-Epic-Task Context]
- <Theme>.<Epic>.<Task> (<SHORT-CODE>): Task description

<detailed description>

**Changes:**
- Bulleted list of changes

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Examples:**
```
feat(1.1.1): add project dependencies
feat(2.1.2): create mode selection cards
fix(3.2.4): handle WebSocket reconnection
```

## When Implementing Features

1. **Check TODO.md** - Find the Theme.Epic.Task ID
2. **Create branch** from updated main: `feature/<theme>.<epic>.<task>-desc`
3. **Update TODO.md** - Mark task as `[x]` when starting
4. **Implement** following architecture patterns
5. **Test** on device/emulator
6. **Commit** with Theme.Epic.Task ID in message
7. **Push and stop** - Let user review and create PR

## Key Files

- `lib/main.dart` - App entry point
- `lib/config/env.dart` - API configuration
- `lib/config/routes.dart` - Navigation routes
- `lib/core/websocket/ws_client.dart` - WebSocket connection
- `pubspec.yaml` - Dependencies

## API Integration

Connects to `api.aint-real.com`:

```
POST /api/game/create        - Create new game
POST /api/game/join/:code    - Join existing game
GET  /api/game/:code         - Get game state
WS   /api/game/:code/ws      - WebSocket connection
GET  /api/images/:path       - Serve images from R2
```

See [aintreal-game/GAMEFLOW.md](../aintreal-game/GAMEFLOW.md) for WebSocket message format.

## Current State (January 2026)

**Status**: Published on Google Play, iOS in App Store Review

**Google Play:** https://play.google.com/store/apps/details?id=com.aintreal.app
**Version:** 1.0.0+8

**Completed Milestones:**
- M1: Core game loop (Party, Classic, Marathon modes)
- M2: Polish & parity (reveal animations, sounds, confetti)
- M3: Authentication (Firebase, Google Sign-In, Sign in with Apple)
- M4: Mobile features (haptics, deep links, sharing)
- M5: Monetization (AdMob banner + interstitial, IAP ad removal $2.99)
- M6: Google Play published, iOS submitted

**Next**: Social media campaign, iOS approval, content expansion

## Questions?

- Feature backlog → [TODO.md](TODO.md)
- Completed work → [DONE.md](DONE.md)
- Game flow → [../aintreal-game/GAMEFLOW.md](../aintreal-game/GAMEFLOW.md)
- Project overview → [../aintreal-game/CLAUDE.md](../aintreal-game/CLAUDE.md)
