# Repository Guidelines - AIn't Real App

## Project Structure & Module Organization

Flutter mobile app with feature-based architecture.

```
lib/
├── main.dart           # Entry point, Firebase init
├── app.dart            # MaterialApp + GoRouter
├── config/             # Environment, routes, theme
├── core/               # API, auth, WebSocket, storage
├── features/           # Feature modules (home, lobby, game, etc.)
├── models/             # Data models
├── widgets/            # Shared UI components
└── utils/              # Helpers, extensions
```

## Build, Test, and Development Commands

```bash
# Run app
flutter run

# Run with local backend
flutter run --dart-define=API_BASE=http://localhost:8789

# Install dependencies
flutter pub get

# Code generation (Riverpod)
dart run build_runner build

# Build release
flutter build apk --release
flutter build ios --release

# Run tests
flutter test
```

## Coding Style & Naming Conventions

- Use standard Dart formatting (`dart format`)
- File names: `snake_case.dart`
- Variables/functions: `lowerCamelCase`
- Types/classes: `UpperCamelCase`
- Feature folders: One folder per feature under `lib/features/`

## Testing Guidelines

- Tests live in `test/` following `*_test.dart` naming
- Widget tests for UI components
- Unit tests for providers and business logic
- Integration tests in `integration_test/`

## Commit & Pull Request Guidelines

- Branch naming: `<type>/<theme>.<epic>.<task>-description`
- Commit format: `<type>(<theme>.<epic>.<task>): summary`
- NEVER merge directly to main - use Pull Requests
- Include screenshots for UI changes

## Security & Configuration

- Firebase config files not committed: `google-services.json`, `GoogleService-Info.plist`
- API keys via `--dart-define` for builds
- Environment switching via `lib/config/env.dart`
