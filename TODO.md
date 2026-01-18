# AIn't Real App - TODO

**Last Updated:** January 17, 2026

## Current Status

- **Platform:** Flutter 3.38.4 (stable)
- **Package:** `com.aintreal.app`
- **Phase:** M1-M5 Complete, M6 In Progress
- **Next:** Google Play Store submission

See [DONE.md](DONE.md) for completed milestones (M1-M5) and [CLAUDE.md](CLAUDE.md) for development workflow.

---

## In Progress

### Epic 8.2: Store Preparation (RE-STORE)
**Goal:** App store submission materials
**Status:** In Progress

| Task | Description | Status |
|------|-------------|--------|
| 8.2.1 | Create app screenshots (phone + tablet) | [x] phone done |
| 8.2.2 | Write app description | [x] |
| 8.2.3 | Create feature graphic | [x] |
| 8.2.4 | Create/update privacy policy | [x] |
| 8.2.5 | Create terms of service | [x] |
| 8.2.6 | Implement account deletion | [x] |
| 8.2.7 | Write reviewer instructions | [x] |

### Epic 4.2: Auth Integration (AU-AUTH) - Partial
**Note:** Apple Sign-In blocked pending developer account

| Task | Description | Status |
|------|-------------|--------|
| 4.2.4 | Implement Sign in with Apple | [~] blocked |

---

## Planned

### Epic 8.3: Beta Testing (RE-BETA)
**Goal:** Pre-release testing

- [ ] 8.3.1: Set up TestFlight (iOS)
- [ ] 8.3.2: Set up Play Console internal testing
- [ ] 8.3.3: Recruit beta testers
- [ ] 8.3.4: Collect and address feedback

### Epic 8.4: Production Release (RE-PROD)
**Goal:** App store submission

- [ ] 8.4.1: Submit to Google Play
- [ ] 8.4.2: Submit to App Store
- [ ] 8.4.3: Monitor initial reviews
- [ ] 8.4.4: Address any store feedback

---

## Testing Backlog

### Epic 9.1: Unit Tests (TS-UNIT)
- [ ] 9.1.1: WebSocket message parsing tests
- [ ] 9.1.2: Game state provider tests
- [ ] 9.1.3: Score calculation tests
- [ ] 9.1.4: Model serialization tests

### Epic 9.2: Widget Tests (TS-WIDGET)
- [ ] 9.2.1-9.2.6: Screen widget tests (home, lobby, game, results, reveal, shared)

### Epic 9.3: Integration Tests (TS-INTEGRATION)
- [ ] 9.3.1-9.3.4: E2E flow tests

### Epic 9.4: Golden Tests (TS-GOLDEN)
- [ ] 9.4.1-9.4.4: Visual regression tests

---

## Future Backlog

### Flutter Web
- [ ] Try Mode demo flow
- [ ] AdSense Integration
- [ ] Turnstile Bot Protection

### Web Polish
- [ ] Achievements system
- [ ] Share results to social
- [ ] First-time tutorial overlay
- [ ] Tap image to view fullscreen

### Bugs/Polish
- [x] Non-host players: detect when host closes game or leaves lobby
- [x] Review wrong answer color logic (confusing feedback)

### Cleanup
- [ ] Remove debug logging from auth_provider.dart and session_provider.dart

### New Game Modes (Post-Launch)
- [ ] Quad Mode (4 images, 1-3 AI)
- [ ] Slice Mode (30% crop)

---

## Quick Links

- [CLAUDE.md](CLAUDE.md) - Development workflow
- [DONE.md](DONE.md) - Completed milestones archive
