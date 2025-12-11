# AIn't Real - Flutter Mobile App

Flutter mobile application for iOS and Android.

## Project Status: Design Phase

This app will provide a native mobile experience for the AIn't Real game, connecting to the same backend API as the web version.

---

## Confirmed Decisions (from parent CLAUDE.md)

### Platform Strategy
- **Framework:** Flutter (single codebase for iOS + Android)
- **Release Priority:** Android first, develop both simultaneously
- **Web:** Stays as separate HTML/JS (not Flutter web)

### Feature Scope
- Full parity with web version
- All 3 game modes: Party, Classic Solo, Marathon
- All bonuses and scoring
- Photographer credits

### Authentication
- **Provider:** Firebase Authentication
- **Methods:** Google Sign-In, Sign in with Apple
- **Anonymous Play:** Supported (like web)
- **Account Linking:** Prompt to link when signing in (preserves anonymous stats)
- **Cross-Platform Sync:** Stats sync via Firebase UID

### User Data (stored in D1 via API)
- Display name (editable)
- Total games played
- Win count / win rate
- Best Marathon streak
- Achievements earned
- Friends list (for invites)
- Game history

### Monetization
- **Ads:** AdMob integration (mobile only)
- **Placements:** TBD - options include between games, rewarded ads
- **Web:** No ads (keep clean for sharing/virality)

### Mobile-Specific Features
- Haptic feedback on answer selection
- Push notifications for game invites
- Native share sheet integration
- Platform sign-in buttons

---

## Open Design Questions

### 1. App Architecture
- [ ] State management: Provider, Riverpod, BLoC, or GetX?
- [ ] Navigation: GoRouter, auto_route, or Navigator 2.0?
- [ ] Dependency injection approach?

### 2. Networking
- [ ] HTTP client: dio or http package?
- [ ] WebSocket handling: web_socket_channel or custom?
- [ ] Offline handling / caching strategy?

### 3. UI/UX
- [ ] Design system: Material 3, Cupertino adaptive, or custom?
- [ ] Animation library: built-in, rive, or lottie?
- [ ] Dark mode support?

### 4. Firebase Setup
- [ ] Project structure (single project or separate dev/prod)?
- [ ] Analytics events to track?
- [ ] Crashlytics integration?

### 5. Ad Implementation
- [ ] Banner ads, interstitials, or rewarded only?
- [ ] Frequency capping rules?
- [ ] Premium ad-free tier?

### 6. Push Notifications
- [ ] FCM setup
- [ ] Notification types (game invites, friend requests, etc.)
- [ ] Deep linking from notifications

### 7. App Store Requirements
- [ ] Privacy policy updates needed?
- [ ] Age rating considerations?
- [ ] Required screenshots/metadata?

---

## Proposed Architecture

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # MaterialApp configuration
├── config/
│   ├── env.dart              # Environment configuration
│   ├── routes.dart           # Route definitions
│   └── theme.dart            # App theming
├── core/
│   ├── api/                  # API client, endpoints
│   ├── auth/                 # Firebase auth service
│   ├── websocket/            # WebSocket connection manager
│   └── storage/              # Local storage (SharedPreferences, etc.)
├── features/
│   ├── home/                 # Home screen, mode selection
│   ├── lobby/                # Create/join game, player list
│   ├── game/                 # Active gameplay
│   ├── results/              # Game over, rankings
│   ├── profile/              # User profile, stats
│   └── settings/             # App settings
├── models/                   # Data models (Game, Player, Round, etc.)
├── widgets/                  # Shared UI components
└── utils/                    # Helpers, extensions
```

---

## API Integration

The app connects to `api.aint-real.com` - same endpoints as web:

```
POST /api/game/create        - Create new game
POST /api/game/join/:code    - Join existing game
GET  /api/game/:code         - Get game state
WS   /api/game/:code/ws      - WebSocket connection

GET  /api/images/:path       - Serve images from R2
GET  /api/stats              - Game statistics
```

### New Endpoints Needed (for mobile features)
```
POST /api/auth/firebase      - Verify Firebase token, link/create user
GET  /api/user/profile       - Get user profile & stats
PUT  /api/user/profile       - Update display name
GET  /api/user/history       - Game history
POST /api/user/fcm-token     - Register push notification token
```

---

## Development Setup

### Prerequisites
1. Flutter SDK (latest stable)
2. Android Studio or Xcode
3. Firebase project with Auth enabled

### Getting Started
```bash
# Clone the repo
git clone https://github.com/MCrockett/aintreal-app.git
cd aintreal-app

# Install dependencies
flutter pub get

# Run on device/emulator
flutter run
```

---

## Branch Naming Convention

Following project-wide convention: `Theme.Epic.Task`

```
feature.app.initial-setup
feature.app.home-screen
feature.app.game-screen
feature.app.firebase-auth
bugfix.app.websocket-reconnect
```

---

## Milestones

### M1: Core Game Loop
- [ ] Project setup with architecture
- [ ] Home screen with mode selection
- [ ] Create/join game flow
- [ ] Game screen with image display
- [ ] Answer submission via WebSocket
- [ ] Results screen

### M2: Polish & Parity
- [ ] Reveal sequence animations
- [ ] Sound effects
- [ ] All bonus displays
- [ ] Marathon mode end screen
- [ ] Confetti/celebration animations

### M3: Authentication
- [ ] Firebase setup
- [ ] Google Sign-In
- [ ] Sign in with Apple
- [ ] Anonymous-to-account migration
- [ ] Profile screen

### M4: Mobile Features
- [ ] Haptic feedback
- [ ] Push notifications
- [ ] Native sharing
- [ ] Deep links

### M5: Monetization
- [ ] AdMob integration
- [ ] Ad placement implementation
- [ ] (Optional) Premium tier

### M6: Release
- [ ] App store assets
- [ ] Beta testing
- [ ] Production release

---

## Notes

- Keep feature parity with web as source of truth
- Test WebSocket reconnection thoroughly (mobile networks are flaky)
- Image caching is critical for good UX
- Consider battery/data usage for background connections
