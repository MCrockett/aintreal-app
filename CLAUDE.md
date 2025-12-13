# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Quick Reference

- **Feature Tracking**: See [TODO.md](TODO.md) for backlog and milestones
- **Completed Work**: See [DONE.md](DONE.md) for archived completed work
- **Project Overview**: See parent [aintreal-game/CLAUDE.md](../aintreal-game/CLAUDE.md)

## Project Context

AIn't Real mobile app - Flutter implementation for iOS and Android.

- **Type**: Flutter app connecting to existing Cloudflare Workers backend
- **Package**: `com.aintreal`
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
| Ads | AdMob (banner + interstitial + rewarded) |

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
│   ├── api/                  # dio client, endpoints
│   ├── auth/                 # Firebase auth
│   ├── websocket/            # WebSocket client, Riverpod provider
│   └── storage/              # SharedPreferences
├── features/
│   ├── home/                 # Home screen, mode selection
│   ├── lobby/                # Create/join game, player list
│   ├── game/                 # Active gameplay
│   ├── results/              # Game over, rankings
│   ├── profile/              # User profile, stats
│   └── settings/             # App settings
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
```

## Git Workflow

**Branch Naming**: `<type>/<milestone>.<task>-description`

```bash
# Examples
feature/m1.setup-dependencies
feature/m1.home-screen
fix/m1.websocket-reconnect
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
git checkout -b feature/m1.1-project-setup

# Complete and push
git add -A && git commit -m "feat(m1.1): description"
git push origin feature/m1.1-project-setup
# STOP - let user review and create PR
```

## Commit Format

```
<type>(<milestone.task>): <short summary>

[Context]
- M<N>.<T> (SHORT-CODE): Task description

<detailed description>

**Changes:**
- Bulleted list of changes

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## When Implementing Features

1. **Check TODO.md** - Find the milestone/task ID
2. **Create branch** from updated main
3. **Update TODO.md** - Mark task as in-progress
4. **Implement** following architecture patterns
5. **Test** on device/emulator
6. **Update TODO.md** - Mark task complete
7. **Commit and push** - Let user create PR

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

## Current State (December 2025)

**Status**: Design phase complete, ready for M1 implementation

**Completed**:
- Tech stack decisions finalized
- Architecture designed
- Dependencies identified
- TODO.md backlog created

**Next**: M1.1 - Project Setup (add dependencies, create folder structure)

## Questions?

- Feature backlog → [TODO.md](TODO.md)
- Completed work → [DONE.md](DONE.md)
- Game flow → [../aintreal-game/GAMEFLOW.md](../aintreal-game/GAMEFLOW.md)
- Project overview → [../aintreal-game/CLAUDE.md](../aintreal-game/CLAUDE.md)
