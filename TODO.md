# AIn't Real App - TODO

**Last Updated:** February 10, 2026

## Current Status

- **Platform:** Flutter 3.38.4 (stable)
- **Package:** `com.aintreal.app`
- **Version:** 1.0.0+11
- **Google Play:** PUBLISHED - https://play.google.com/store/apps/details?id=com.aintreal.app
- **iOS App Store:** PUBLISHED - https://apps.apple.com/us/app/aint-real/id6758273529
- **Next:** Social media campaign, content expansion

See [DONE.md](DONE.md) for completed milestones (M1-M6) and [CLAUDE.md](CLAUDE.md) for development workflow.

---

## v8 Pre-Launch Fixes

### Completed
- [x] Connection loss resilience: WsClient stays in reconnecting state during retries
- [x] Connection loss resilience: Lobby only shows fatal dialog on disconnected (not reconnecting)
- [x] Connection loss resilience: ConnectionLostOverlay widget for game + reveal screens
- [x] Account deletion: Delete user_pair_results on account delete (App Store compliance)
- [x] iOS ATT: Added NSUserTrackingUsageDescription to Info.plist
- [x] iOS SKAdNetwork: Expanded from 1 to 19 network identifiers for AdMob

### Deferred (post-launch)
- [ ] Firebase token signature verification (currently validates claims only)
- [ ] Rotate/harden Turnstile mobile bypass secret (replace static app secret with Play Integrity / DeviceCheck attestation)
- [x] Server-side config validation (rounds/timePerRound bounds)
- [ ] Timeout UX normalization (choice='timeout' vs null)
- [ ] Host disconnect: promote another player or end game cleanly mid-round
- [ ] Leaderboard integrity (authenticated user IDs)
- [ ] Don't send aiPosition in round_start; defer to round_reveal (prevents DevTools cheating in party web)
- [ ] Add demo_eligible column to schema.sql (exists in prod DB, missing from base schema)

---

## Immediate: Post-Launch

### iOS App Store
- [ ] Await App Store review approval
- [ ] Update website (index.html, download.html) with App Store link
- [ ] Test iOS build from App Store on real device

### Social Media Campaign
- [ ] Create TikTok/Reels gameplay clips ("Can you spot the AI?")
- [ ] Post to Reddit (r/gaming, r/artificial, r/AndroidGaming, r/iosgaming)
- [ ] Set up UTM tracking for install attribution
- [ ] Monitor reviews and respond to feedback

### Content Expansion
- [ ] Continue generating base image pairs (currently 262)
- [ ] Target 300+ total base pairs

### Guest Name Readability
- [x] Rework guest name generator — readable `{Adjective}{Noun}{Number}` format (SwiftPixel42)
- [x] Replace text input with 3-choice name picker + shuffle button

### Web Limiting (Drive App Downloads)
- [ ] Remove Solo Mode from web (redirect to download page)
- [ ] Remove Marathon Mode from web (redirect to download page)
- [ ] Remove Party Hosting from web (show "Download app to host" message)
- [ ] Keep Try Mode and Party Guest joining functional

---

## Phase 2: Theme Packs (Week 2-4 After Launch) 💎

### Theme Packs: Technical Infrastructure
**Goal:** Enable premium content packs

- [ ] Add `pack_id` field to `image_pairs` database table (D1 schema migration)
- [ ] Implement pack ownership tracking:
  - Add user_packs field to Firebase user profile
  - Store owned pack IDs (e.g., ["animals", "travel", "space"])
- [ ] Create pack purchase flow UI:
  - Pack catalog/browser screen
  - Pack preview with 3-5 sample images
  - Purchase button with price display
  - Purchase states (loading, success, error)
  - "Owned" badge for purchased packs
- [ ] Implement pack filtering in game logic:
  - Filter available pairs by owned packs when generating games
  - Show "locked pack" message if player doesn't own required pack
  - Base pack (pack_id = "base") always free
- [ ] Add pack management to settings screen
- [ ] Test pack purchase and unlock flow

### Pack 1: Animals Pack ($0.99, 50 pairs)
**Timeline:** Week 2-3 after launch

- [ ] Generate 50 animal-themed image pairs (~1.5-2 hours)
  - Categories: cats, dogs, wildlife, birds, marine life, insects
- [ ] Upload pairs to R2 bucket with pack_id="animals"
- [ ] Insert pairs into D1 database with pack association
- [ ] Configure Play Console IAP:
  - Product ID: `com.aintreal.pack_animals`
  - Type: Non-consumable
  - Price: $0.99 USD
- [ ] Test pack purchase → unlock → gameplay
- [ ] Build and ship app update (v1.1.0 or similar)

### Pack 2: Travel Pack ($0.99, 50 pairs)
**Timeline:** Week 3-4 after launch

- [ ] Generate 50 travel-themed image pairs (~1.5-2 hours)
  - Categories: landscapes, cities, monuments, beaches, famous destinations
- [ ] Upload pairs to R2 with pack_id="travel"
- [ ] Insert pairs into D1 database
- [ ] Configure Play Console IAP:
  - Product ID: `com.aintreal.pack_travel`
  - Price: $0.99 USD
- [ ] Ship app update

### Pack 3: Space Pack ($0.99, 50 pairs)
**Timeline:** Week 3-4 after launch

- [ ] Generate 50 space-themed image pairs (~1.5-2 hours)
  - Categories: planets, galaxies, astronauts, rockets, sci-fi scenes, nebulae
- [ ] Upload pairs to R2 with pack_id="space"
- [ ] Insert pairs into D1 database
- [ ] Configure Play Console IAP:
  - Product ID: `com.aintreal.pack_space`
  - Price: $0.99 USD
- [ ] Ship app update

---

## Phase 3: Daily Challenge + Ultimate Bundle (Week 5-6) 🏆

### Daily Challenge Mode
**Goal:** Free engagement hook that drives daily app opens and sign-ins

**Design:**
- Free to play, requires app + sign-in (drives account creation)
- 5 rounds per challenge, one attempt per challenge
- 3x per week (specific days TBD, e.g. MWF or TuThSa)
- Curated content, queued ahead of time via admin tooling
- Track and display both accuracy and speed
- Challenge pairs migrate to main pool after challenge expires

#### App UI
- [ ] "Daily Challenge" card on home screen (prominent, distinctive styling)
  - Show availability state: "Live now", "Next challenge in Xh", "Completed"
  - Require sign-in to play (prompt if guest)
- [ ] Challenge game flow:
  - Load today's 5 pairs
  - Track time per round and cumulative time
  - Prevent skipping or going back
  - Submit results to server on completion
  - Mark as attempted (prevent replay)
- [ ] Results screen:
  - Score breakdown (accuracy + speed)
  - Personal stats (streak, best score, avg accuracy)
  - Global leaderboard position
  - Friends leaderboard (see Friends System below)
- [ ] Challenge history: view past challenges and personal results

#### Backend (aintreal-game)
- [ ] Database schema:
  - **daily_challenges** table:
    - challenge_id (UUID)
    - challenge_date (DATE)
    - pair_ids (JSON array of 5 pair IDs)
    - active (boolean)
  - **challenge_results** table:
    - challenge_id (FK)
    - user_id (FK)
    - score (int)
    - correct_answers (int)
    - total_time_ms (int)
    - completed_at (timestamp)
    - Unique constraint on (user_id, challenge_id)
- [ ] API endpoints:
  - `GET /api/challenge/today` — return active challenge (pairs + metadata)
  - `POST /api/challenge/:id/submit` — submit results (server-side validation)
  - `GET /api/challenge/:id/leaderboard` — global leaderboard
  - `GET /api/challenge/:id/leaderboard/friends` — friends leaderboard
  - `GET /api/challenge/history` — user's past results + streaks
- [ ] Challenge scheduling:
  - Cron or scheduled function to activate queued challenges on release day
  - Auto-deactivate previous challenge
  - Migrate expired challenge pairs to main pool
- [ ] Anti-cheat:
  - Server-side timing validation (flag impossibly fast completions)
  - One attempt enforcement via DB unique constraint

#### Content Pipeline
- [ ] Admin tool to queue challenge sets (5 curated pairs each)
  - Batch upload to R2 + insert into D1 with challenge_id
  - Set release date (queued ahead of time)
- [ ] Target: queue 2-4 weeks of challenges at a time (~30-60 pairs)

#### Push Notifications
- [ ] Firebase Cloud Messaging on challenge days ("Today's challenge is live!")
- [ ] Configurable notification preferences

### Friends System (Prerequisite)
**Goal:** Enable friends leaderboard for Daily Challenge and future social features

- [ ] Design friend data model:
  - Friend relationships (bidirectional or follow-based?)
  - Storage: Firebase, D1, or both?
- [ ] Friend invite flow:
  - Share invite link / code
  - In-app friend search (by display name or ID)
  - Accept/decline/block
- [ ] Friends list UI in profile/settings
- [ ] API endpoints:
  - `POST /api/friends/invite` — send friend request
  - `POST /api/friends/accept` — accept request
  - `GET /api/friends` — list friends
  - `DELETE /api/friends/:id` — remove friend
- [ ] Privacy considerations: what stats are visible to friends?

### Ultimate Bundle IAP
**Goal:** Premium tier with best value

- [ ] Configure Play Console IAP:
  - Product ID: `com.aintreal.ultimate_bundle`
  - Type: Non-consumable (one-time purchase)
  - Price: $7.99 USD
- [ ] Implement bundle entitlement system:
  - Store bundle ownership flag in user profile (Firebase)
  - Bundle grants:
    - Ad removal (skip all ad loading)
    - All current theme packs (animals, travel, space)
    - All future theme packs (auto-unlock when released)
  - Ensure bundle supersedes individual purchases
- [ ] Create bundle marketing UI:
  - Dedicated bundle screen or modal
  - Value proposition: "Get everything forever!"
  - Show included items with value breakdown
  - "Best Value!" badge
- [ ] Update pack/ad-removal purchase flows for bundle owners
- [ ] Test bundle purchase grants all entitlements correctly

---

## Phase 4: iOS Launch ✅ (Submitted)

### Apple Developer Setup — Complete
- [x] Apple Developer Program membership
- [x] App Store Connect app record
- [x] Bundle ID, capabilities, certificates, provisioning profiles

### iOS AdMob — Complete
- [x] iOS-specific ad unit IDs configured
- [x] Info.plist AdMob App ID
- [x] ATT consent dialog
- [x] SKAdNetwork identifiers (19 networks)

### iOS IAP — Complete (Ad Removal)
- [x] Ad Removal - $2.99 (com.aintreal.remove_ads)
- [ ] Theme pack IAPs (deferred to Phase 2)

### iOS-Specific Features — Complete
- [x] Sign in with Apple (Firebase provider + UI)
- [x] Universal links configured
- [x] Edge-to-edge layout fixes

### iOS App Store Submission — In Review
- [x] Built and uploaded IPA
- [x] Screenshots, privacy labels, reviewer instructions
- [x] Submitted to App Review
- [ ] Await approval and release

---

## Future: Additional Content & Features (Post-Launch)

### Additional Theme Packs (Ongoing)
**Goal:** Expand content library over time

- [ ] Food & Cooking Pack (50 pairs, $0.99)
- [ ] Holidays Pack - seasonal (50 pairs, $0.99) - launch Oct/Nov
- [ ] Sports & Fitness Pack (50 pairs, $0.99)
- [ ] Art & Architecture Pack (50 pairs, $0.99)
- [ ] Fantasy & Magic Pack (50 pairs, $0.99)
- [ ] Nature & Plants Pack (50 pairs, $0.99)
- [ ] Fashion & Style Pack (50 pairs, $0.99)

### Additional Game Modes (Phase 5+)
**Goal:** Increase replayability and depth

- [ ] Speed Run Mode:
  - Time trial with fastest completions
  - Global leaderboard
  - Could be free or premium ($1.99)
- [ ] Versus Mode:
  - Real-time 1v1 head-to-head matches
  - Ranked matchmaking
  - Premium feature ($1.99 or included in Ultimate Bundle)
- [ ] Expert Mode:
  - Harder AI images (more realistic)
  - No hints or help
  - Higher score multipliers
  - Premium feature

### Future Monetization Ideas (Phase 6+)
**Goal:** Diversify revenue streams

- [ ] Cosmetics:
  - Player avatars/profile pictures
  - UI themes (dark mode variants, color schemes)
  - Celebration animations (confetti styles, sound packs)
  - $0.99 - $1.99 per cosmetic or bundles
- [ ] Season Pass / Battle Pass:
  - Quarterly season with progression tiers
  - Free tier + Premium tier ($4.99)
  - Unlock exclusive content, cosmetics, badges
- [ ] Sponsored Theme Packs:
  - Partner with brands (e.g., National Geographic for nature pack)
  - Revenue share model
- [ ] Tournament Mode:
  - Entry fee ($0.99 - $2.99)
  - Prize pool for top players
  - Requires robust anti-cheat

---

## Analytics & Optimization (Ongoing) 📊

### Key Metrics to Track
**Goal:** Data-driven iteration

- [ ] Set up Firebase Analytics custom events:
  - `ad_impression` (banner, interstitial)
  - `ad_clicked`
  - `iap_product_viewed` (which product)
  - `iap_purchase_initiated` (which product)
  - `iap_purchase_completed` (which product, price)
  - `iap_purchase_failed` (which product, error)
  - `game_completed` (mode, score, duration)
  - `weekly_challenge_started`
  - `weekly_challenge_completed` (score, rank)
  - `pack_unlocked` (which pack)
- [ ] Create Firebase Analytics dashboard for:
  - Daily Active Users (DAU)
  - Retention (D1, D7, D30)
  - Ad revenue estimates
  - IAP conversion funnel (views → purchases)
  - Most popular game modes
  - Drop-off points in user journey
  - Weekly Challenge participation rate
- [ ] Set up weekly metric review routine (e.g., every Monday morning)
- [ ] Set up automated alerts (e.g., crash rate spike, IAP errors)

### A/B Testing Ideas
**Goal:** Optimize pricing and UX

- [ ] Test ad removal pricing: $2.99 vs. $3.99
- [ ] Test interstitial frequency: every 3rd game vs. every 5th game
- [ ] Test Ultimate Bundle pricing: $7.99 vs. $9.99
- [ ] Test theme pack pricing: $0.99 vs. $1.99
- [ ] Test bundle CTA placement (home screen vs. settings vs. post-game)
- [ ] Test pack preview UI (grid vs. carousel)

---

## Testing Backlog (Lower Priority)

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

## Web Version (Deprioritized) 🌐

**Strategy:** Web as acquisition funnel, not revenue source

### Current State
- [x] Web version live at aint-real.com
- [x] Playable game (party/solo/marathon modes)
- [x] No monetization (no ads, no IAP)

### Future Web Features (Low Priority)
- [ ] Prominent "Download the App" CTAs after games
- [ ] "App has exclusive content!" messaging
- [ ] Track conversion rate: web plays → app installs
- [ ] Try Mode demo flow (for new players)
- [ ] Turnstile Bot Protection (if abuse becomes an issue)
- [ ] Achievements system (synced with mobile if logged in)
- [ ] Share results to social media

**Note:** Skip AdSense integration for now (rejected due to "insufficient content"). Revisit web monetization only after mobile is successful (6+ months).

---

## Bugs / Polish / Cleanup

### Completed
- [x] Non-host players: detect when host closes game or leaves lobby
- [x] Review wrong answer color logic (confusing feedback)

### Remaining
- [x] Remove debug logging from auth_provider.dart and session_provider.dart (before production release)
- [x] iOS build configuration (submitted to App Store)
- [ ] Consider haptic feedback patterns for different events
- [ ] Evaluate animation performance on older devices
- [ ] Skip ATT prompt if ad removal already purchased (currently fires for all iOS users on every launch)

---

## Decisions Made (2026-01-19 Planning Session) ✅

**Monetization Model:**
- ✅ Freemium: Free with ads + optional IAP
- ✅ Ad removal: $2.99 (launch product)
- ✅ Theme packs: 50 pairs for $0.99 each
- ✅ Ultimate Bundle: $7.99 (includes ad removal + all packs + Weekly Challenge)

**Content Strategy:**
- ✅ Launch with 262 base pairs
- ✅ AI imperfection is part of the charm (some funny failures are okay)
- ✅ First three packs: Animals, Travel, Space

**Ad Strategy:**
- ✅ Interstitial frequency: None for first 5 games, then after 5th, then every 3rd
- ✅ Frequency cap: Max 1 interstitial per 5 minutes
- ✅ Web version: No ads, but heavily limited features (demo + party guest only)

**Web Strategy:**
- ✅ Web is demo + party guest mode only (not full game)
- ✅ Try Mode: Basic demo with limited image rotation (stays as-is)
- ✅ Party Guest: Join parties via link (no hosting, no account)
- ✅ Remove from web: Solo mode, Marathon mode, Party hosting, accounts, leaderboards
- ✅ Goal: Web users must download app to actually play the game
- ✅ Viral loop: App users host → share links → web users join as guests → want to host → download app

**Launch Strategy:**
- ✅ Google Play first (easier approval, faster iteration)
- ✅ iOS second (after Google Play is stable)
- ✅ IAP rollout: Ad removal first → theme packs → Ultimate Bundle (create FOMO)

**Daily Challenge:**
- ✅ Free, requires app + sign-in
- ✅ 3x per week (specific days TBD)
- ✅ 5 rounds per challenge, curated content queued ahead of time
- ✅ One attempt per player
- ✅ Track and display both accuracy and speed
- ✅ Leaderboards: global, friends, personal stats/streaks
- ✅ Pairs migrate to main pool after challenge expires
- ✅ Friends system needed as prerequisite for friends leaderboard

---

## Open Questions ❓

- ❓ Ultimate Bundle pricing: $7.99 confirmed or test $9.99?
- ❓ Rewarded ads: What should the reward be? (Hints? Bonus points? Free mode trial?)
- ❓ Daily Challenge: Which 3 days per week? (MWF, TuThSa, other?)
- ❓ Daily Challenge: Scoring formula — (Correct × 100) - (Seconds ÷ 2), or simpler?
- ❓ Friends system: Bidirectional (mutual accept) or follow-based (one-way)?
- ❓ Should base pack grow over time (e.g., 250 → 300 → 350) to keep free players engaged?

---

## Quick Links

- [CLAUDE.md](CLAUDE.md) - Development workflow
- [DONE.md](DONE.md) - Completed milestones archive
- [AUDIT.md](AUDIT.md) - App store learning audit
- [TRIAGE.md](TRIAGE.md) - Bugs and issues tracker
- [store/PLAY_STORE_LISTING.md](store/PLAY_STORE_LISTING.md) - Store copy
- [store/REVIEWER_INSTRUCTIONS.md](store/REVIEWER_INSTRUCTIONS.md) - Reviewer guide
- [../MONETIZATION_PLAN.md](../MONETIZATION_PLAN.md) - Full monetization strategy
- [../PROJECT.md](../PROJECT.md) - Cross-repo project overview

---

**Priority Summary:**
1. **Now:** iOS approval, social media campaign, web limiting
2. **Week 2-4:** Theme packs (Animals, Travel, Space)
3. **Week 5-6:** Ultimate Bundle + Daily Challenge
