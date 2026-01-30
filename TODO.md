# AIn't Real App - TODO

**Last Updated:** January 19, 2026

## Current Status

- **Platform:** Flutter 3.38.4 (stable)
- **Package:** `com.aintreal.app`
- **Phase:** M1-M5 Complete, M6 Google Play Launch Prep
- **Next:** Production AdMob setup + content generation + Google Play submission

See [DONE.md](DONE.md) for completed milestones (M1-M5) and [CLAUDE.md](CLAUDE.md) for development workflow.

---

## Phase 1: Google Play Launch (PRIORITY 1) 🚀

### Pre-Launch: Content Generation
**Goal:** Reach 250 base image pairs before launch (currently 169)

- [ ] Generate 80+ new base image pairs (~2.5-3 hours total)
  - Target: 250-270 total base pairs
  - Mix of quality AI + some funny failures (AI imperfection is part of the charm)

### Pre-Launch: Production AdMob Setup
**Goal:** Replace test ad unit IDs with production IDs

- [ ] Create production AdMob account (if not exists)
- [ ] Link AdMob to Firebase project "aintreal"
- [ ] Register Android app (com.aintreal) in AdMob
- [ ] Register iOS app (com.aintreal) in AdMob (for future)
- [ ] Generate production ad unit IDs:
  - Banner ad (home screen)
  - Interstitial ad (post-game)
  - Rewarded ad (future use)
- [ ] Replace test ad unit IDs in code:
  - Update `lib/core/ads/ad_service.dart`
  - Update Android manifest
  - Update iOS Info.plist (when ready)
- [ ] Document production ad unit IDs in project docs

### Pre-Launch: Ad Placement Implementation
**Goal:** Implement smart interstitial frequency

- [x] Implement interstitial trigger logic:
  - No interstitials for first 5 games (let users get hooked)
  - Show after 5th game completion
  - Then show every 3rd game after that
  - Frequency cap: Max 1 per 5 minutes
  - Skip if user has purchased ad removal
- [x] Add interstitial call after game results screen
- [ ] Test ad flow doesn't break game experience
- [x] Ensure proper loading states (game continues if ad fails)
- [ ] Test frequency capping works correctly

### Pre-Launch: IAP - Ad Removal
**Goal:** Launch with one IAP product (Ad Removal $2.99)

- [x] Add `in_app_purchase` Flutter package to pubspec.yaml
- [ ] Configure Google Play Console product:
  - Product ID: `com.aintreal.remove_ads`
  - Type: Non-consumable (one-time purchase)
  - Price: $2.99 USD
- [x] Create purchase flow UI:
  - "Remove Ads" button in settings
  - Clear benefit messaging ("Play ad-free forever!")
  - Handle purchase states (pending, success, error, already owned)
- [x] Implement entitlement check:
  - Store purchase state locally (shared_preferences)
  - Verify with Play Billing Library
  - Skip all ad loading when entitlement active
  - ~~Sync entitlement via Firebase~~ (deferred - local storage sufficient for launch)
- [x] Implement "Restore Purchases" functionality
- [ ] Test with Google Play test accounts (sandbox environment)

### Pre-Launch: Limit Web Version
**Goal:** Make web a demo/guest-only experience to drive app downloads

- [ ] Remove Solo Mode from web (redirect to download page)
- [ ] Remove Marathon Mode from web (redirect to download page)
- [ ] Remove Party Hosting from web (show "Download app to host" message)
- [ ] Keep Try Mode functional (basic demo with limited images)
- [ ] Keep Party Guest joining functional (join via link, no account needed)
- [ ] Add prominent download CTAs on all web pages
- [ ] Update homepage messaging: "Try the game on web, play for real in the app"
- [ ] Test party guest flow: app user hosts → web user joins as guest
- [ ] Add post-game CTA for web guests: "Host your own party - Download app"

### Pre-Launch: Google Play Store Submission
**Goal:** Submit to Play Store within 1-2 weeks

- [ ] Update privacy policy to include AdMob data collection disclosures
- [ ] Publish privacy policy at aint-real.com/privacy (or host on GitHub Pages)
- [ ] Complete Data Safety form in Play Console:
  - Declare AdMob SDK (advertising data collection)
  - Declare Firebase Analytics (usage/diagnostics)
  - Declare Firebase Auth (account data)
- [ ] Complete age rating questionnaire (likely E for Everyone or E10+)
- [ ] Review and finalize store screenshots (already in store/ folder)
- [ ] Review store listing copy (description, short description, title)
- [ ] Finalize reviewer instructions (store/REVIEWER_INSTRUCTIONS.md)
- [ ] Ensure app signing key secured and documented
- [ ] Build signed APK/AAB with production ad unit IDs:
  - `flutter build appbundle --release`
- [ ] Submit to Internal Testing track first
- [ ] Install and test from Play Store on real Android device
- [ ] Validate ads show correctly and IAP purchase works
- [ ] Promote to Production track when validated

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

## Phase 3: Ultimate Bundle + Weekly Challenge (Week 5-6) 🏆

### Weekly Challenge Mode: Technical Implementation
**Goal:** Exclusive competitive mode for Ultimate Bundle owners

- [ ] Design Weekly Challenge UI/UX:
  - "Weekly Challenge" button on home screen with distinctive styling
  - Lock icon overlay if user doesn't own Ultimate Bundle
  - Challenge info screen (10 rounds, one attempt, global leaderboard)
  - Live leaderboard display during challenge
  - Final leaderboard after challenge closes
  - "One attempt only" prominent messaging
  - Score breakdown display (accuracy + speed components)
- [ ] Database schema additions (D1 or Firestore):
  - **weekly_challenges** table:
    - challenge_id (UUID)
    - week_start_date (timestamp)
    - week_end_date (timestamp)
    - challenge_pair_ids[] (array of 10 pair IDs)
    - active (boolean)
  - **challenge_leaderboard** table:
    - challenge_id (FK)
    - user_id (FK)
    - score (int, calculated: correct × 100 - seconds ÷ 2)
    - correct_answers (int)
    - total_time_seconds (int)
    - completion_timestamp (timestamp)
    - rank (int, computed)
  - **challenge_attempts** table:
    - user_id (FK)
    - challenge_id (FK)
    - has_attempted (boolean)
    - Unique constraint on (user_id, challenge_id)
- [ ] Implement challenge game flow:
  - Check entitlement (Ultimate Bundle ownership)
  - Load current week's 10 pairs
  - Track time per round and cumulative time
  - Prevent skipping or going back
  - Calculate final score: (Correct × 100) - (Total Seconds ÷ 2)
  - Submit score to leaderboard (server-side)
  - Mark user as attempted (prevent replay)
  - Display user's rank + top 10 global leaderboard
- [ ] Implement leaderboard functionality:
  - Live updates during 48-hour window (poll or WebSocket)
  - Show top 10 players with scores
  - Highlight current user's rank prominently
  - Final leaderboard display when challenge closes
  - Leaderboard history (view past week challenges)
- [ ] Anti-cheat measures:
  - Server-side validation: Flag perfect scores under 30 seconds (impossible)
  - Validate timing patterns (e.g., all rounds same speed = suspicious)
  - Admin dashboard to review flagged scores
  - Manual review capability for top 10 final leaderboard
- [ ] Challenge scheduling automation:
  - Cron job or scheduled function:
    - Saturday 12:00 AM: Activate new challenge (set active=true)
    - Monday 12:00 AM: Deactivate challenge (set active=false)
    - Monday: Migrate challenge pairs to main pool (update pack_id to "base")
- [ ] Push notification integration:
  - Send Firebase Cloud Messaging notification Saturday morning: "Weekend Challenge is LIVE!"
  - Only send to Ultimate Bundle owners
- [ ] Test full challenge lifecycle (creation → play → leaderboard → close → migration)

### Weekly Challenge: Content Pipeline
**Goal:** Sustainable weekly content generation

- [ ] Generate first 10-pair challenge set (~20 minutes)
- [ ] Document weekly content generation workflow
- [ ] Set up Friday evening calendar reminder to generate next week's pairs
- [ ] Create admin script/tool to:
  - Upload 10 pairs to R2
  - Insert pairs into D1 with challenge_id
  - Activate challenge for upcoming Saturday

### Ultimate Bundle IAP
**Goal:** Premium tier with best value and exclusive access

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
    - Weekly Challenge access
  - Ensure bundle supersedes individual purchases
- [ ] Create bundle marketing UI:
  - Dedicated bundle screen or modal
  - Value proposition: "Get everything forever, including Weekly Challenges!"
  - Show included items:
    - "Ad-Free Experience ($2.99 value)"
    - "All Theme Packs ($2.97+ value)"
    - "Exclusive Weekly Challenges"
    - "All Future Content Included"
  - Total value display vs. bundle price
  - "Best Value!" badge
- [ ] Update pack purchase flows:
  - Show "Included in Ultimate Bundle" for bundle owners
  - Prevent redundant pack purchases if bundle owned
- [ ] Update ad removal purchase flow:
  - Suggest bundle upgrade if user viewing ad removal
- [ ] Test bundle purchase grants all entitlements correctly
- [ ] Build and ship app update with Ultimate Bundle + Weekly Challenge mode

---

## Phase 4: iOS Launch (Week 7-8+) 🍎

### Apple Developer Setup
**Goal:** Get iOS app ready for App Store

- [ ] Purchase Apple Developer Program membership ($99/year)
- [ ] Complete Apple Developer enrollment (can take a few days)
- [ ] Create App Store Connect app record for "AIn't Real"
- [ ] Configure bundle ID: com.aintreal
- [ ] Set up required capabilities (Sign in with Apple, Push Notifications, etc.)
- [ ] Generate and install code signing certificates
- [ ] Create provisioning profiles (development, distribution)

### iOS AdMob Configuration
**Goal:** Enable ads on iOS

- [ ] Configure iOS-specific ad unit IDs in AdMob console
- [ ] Update iOS Info.plist with AdMob App ID
- [ ] Test ads on physical iOS device (simulators don't show real ads)

### iOS IAP Configuration
**Goal:** Mirror Android IAP products to iOS

- [ ] Create App Store Connect IAP products (mirror Google Play):
  - Ad Removal - $2.99 (Product ID: com.aintreal.remove_ads)
  - Animals Pack - $0.99 (Product ID: com.aintreal.pack_animals)
  - Travel Pack - $0.99 (Product ID: com.aintreal.pack_travel)
  - Space Pack - $0.99 (Product ID: com.aintreal.pack_space)
  - Ultimate Bundle - $7.99 (Product ID: com.aintreal.ultimate_bundle)
- [ ] Match product IDs exactly to Android (simplifies code)
- [ ] Set pricing for all regions (App Store Connect auto-converts)
- [ ] Test IAP purchases via TestFlight with sandbox accounts

### iOS-Specific Features
**Goal:** Meet Apple requirements

- [ ] Implement Sign in with Apple:
  - Required by Apple if offering third-party sign-in (Google)
  - Configure Firebase Apple Sign-In provider
  - Add Apple Sign-In button to auth screen
  - Test authentication flow
- [ ] Update UI for iOS design conventions (if needed)
- [ ] Test haptic feedback on physical devices

### iOS App Store Submission
**Goal:** Publish to App Store

- [ ] Build iOS release archive:
  - `flutter build ipa --release`
- [ ] Upload to App Store Connect via Xcode or Transporter
- [ ] Prepare iOS-specific screenshots (required sizes differ from Android)
- [ ] Prepare App Preview video (optional but recommended)
- [ ] Complete App Store privacy "nutrition labels":
  - Data collected: Account info, usage data, identifiers
  - Data linked to user vs. not linked
  - Similar to Android Data Safety form
- [ ] Submit for App Review
- [ ] Monitor review status (Apple reviews typically 24-48 hours)
- [ ] Respond to any App Review feedback or rejections
- [ ] Release to App Store when approved

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
- [ ] Daily Challenge:
  - One curated game per day (5-10 rounds)
  - Global leaderboard resets daily
  - Free feature to drive daily engagement
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
- [ ] iOS build configuration needs testing (per TRIAGE.md)
- [ ] Consider haptic feedback patterns for different events
- [ ] Evaluate animation performance on older devices

---

## Decisions Made (2026-01-19 Planning Session) ✅

**Monetization Model:**
- ✅ Freemium: Free with ads + optional IAP
- ✅ Ad removal: $2.99 (launch product)
- ✅ Theme packs: 50 pairs for $0.99 each
- ✅ Ultimate Bundle: $7.99 (includes ad removal + all packs + Weekly Challenge)

**Content Strategy:**
- ✅ Launch with 250 base pairs (currently 169, need +81)
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

**Weekly Challenge:**
- ✅ Ultimate Bundle exclusive feature
- ✅ 48-hour window (Saturday 12am - Monday 12am)
- ✅ 10 new pairs per week
- ✅ One attempt per player
- ✅ Score = (Correct × 100) - (Seconds ÷ 2) (rewards speed + accuracy)
- ✅ Pairs migrate to main pool after challenge ends
- ✅ Anti-cheat: Auto-flag impossibly fast perfect scores (<30 sec)

---

## Open Questions ❓

- ❓ Ultimate Bundle pricing: $7.99 confirmed or test $9.99?
- ❓ Rewarded ads: What should the reward be? (Hints? Bonus points? Free mode trial?)
- ❓ Weekly Challenge: Is current anti-cheat sufficient or need stronger measures (randomized pairs)?
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
1. **This week:** Content generation (80 pairs) + AdMob setup + Google Play submission
2. **Week 2-4:** Theme packs (Animals, Travel, Space)
3. **Week 5-6:** Ultimate Bundle + Weekly Challenge
4. **Week 7-8+:** iOS launch
