# Guess on open: app home + website hero (1.1)

**Date:** 2026-10-24 · **Owner:** Matt · **Status:** design, awaiting owner approval
**Repos:** aintreal-app (home), aintreal-game (server endpoints + `ui/index.html`)
**Sketch:** [2026-10-24-guess-on-open-sketch.html](2026-10-24-guess-on-open-sketch.html) (open in a browser; it loads live demo pairs)

## Why

AIn't Real is picking up organic installs from Google and the Play Store. Newcomers open
the app to a menu of mode cards and often play one game or none (the 2026-10-15 deep dive
found 6 of 11 recent sign-ins played zero games). The Reddit splash already works the
way we want: a pair on screen, "Which one is AI?", one tap. The app and the website
should feel the same: **open it and you're already guessing.**

Success: a newcomer makes a guess within seconds of opening the app or loading
aint-real.com, without reading anything or choosing a mode. On the web, that first
guess leads to the store badges.

## Goals

1. **Same feel on every surface.** Wordmark (dark "AI" + coral gradient on "n't Real",
   as on Reddit and the web), "Which one is AI?", a pair, the hint
   "👆 Tap the image that AIn't Real", one tap to guess, instant reveal.
2. **"Next pair" appears only after a guess.** Before the guess, the hint occupies that
   spot.
3. **App: the home pair is the start of a real Classic game**, but only once the player
   commits (see App behavior).
4. **Web: a no-score demo that keeps reminding people about the app.**

## Non-goals

- The Reddit splash (already follows this pattern).
- The weekly leaderboard, packs, Daily Challenge (separate 1.1 / 1.2 items).
- Trimming or re-curating the demo pool.
- Redesigning Party, Marathon, lobby, game or results screens.

## Anti-goals (failure even if it works)

- **Opening the app creates games.** Abandoned "games" from people who just look at the
  home pair must not reach `game_history`, stats, the leaderboard or KPI counts.
- **The home guess leaks the answer before the tap.** The app must not receive
  `aiPosition` for the home pair before the guess (same rule as the answer-leak work and
  the Reddit splash rule).
- **An annoying website.** No lockouts, waits or walls; they're trivially bypassed and
  feel hostile.
- **Burying the other modes.** Party, Marathon and Join stay one tap away on the app home.

## App behavior (aintreal-app)

### Home layout (top to bottom)

1. Wordmark (matches Reddit/web) left, menu icon right. The menu holds profile/sign-in,
   How to Play, settings, and the test-mode version line (1.1 item "version only in test
   mode").
2. "Which one is AI?"
3. The pair, as large as fits (square images, side by side on phones; follow the
   existing game screen's orientation if it differs; builder's call).
4. Result line (empty before the guess).
5. Before the guess: the hint "👆 Tap the image that AIn't Real". After the guess:
   **▶ Next pair** (primary button) in the same spot.
6. "or pick a mode": a compact row of Party (2–8 players) · Classic · Marathon (26, one
   miss), then "Join a party · enter code".

The existing 5-tap test-mode toggle on the subtitle moves wherever the subtitle goes;
keep it working.

### Flow

1. **Open:** the app fetches one home pair (no answer included). Nothing is created on
   the server and nothing counts toward stats.
2. **Guess:** the tap is checked by the server, which returns right/wrong and which side
   was AI. The app shows the reveal (green/red borders, Real/AI tags, "✓ Nailed it" /
   "✗ Fooled you"), and the hint becomes Next pair.
3. **Next pair:** only now does a Classic solo game start, with:
   - **settings:** the player's last Classic settings (rounds, time per round) if they
     have played before, otherwise the defaults (today 6 rounds, 5 s);
   - **round 1 already filled in** with the home guess: right or wrong counts, with
     **no time or speed points**;
   - play continuing at **round 2** in the normal game screen.
4. **Leave without tapping Next pair:** nothing is recorded.
5. **Returning to home** (after a game, or reopening the app) shows a fresh pair.

### Settings memory

Today the create screen does not persist settings (`create_game_screen.dart` defaults
`_rounds = 6`, `_timePerRound = 5`; Play Again passes them via route extras). Add
persistence of the last Classic settings (SharedPreferences, like `sound_service.dart`)
and use it both for the home-started game and as the create screen's initial values.

### Analytics

Log: home pair shown, home guess (correct/incorrect), Next pair tapped (game started
from home). These answer "did the redesign get newcomers playing?" Use the existing
`AnalyticsService` style.

## Web behavior (aintreal-game `ui/index.html`)

- **The game replaces the phone screenshots in the current hero; the hero's layout
  stays** (owner). At full width it is two columns, as today:
  - **left:** brand, "Can you spot the fake?", the subtitle, the **store badges**, and a
    "Play 5 rounds" button that keeps linking to `/try`;
  - **right:** the game: "Which one is AI?", the pair, the result line, hint/Next pair.
- **Narrow views (≤ 900px)** behave like the current hero image does (`order: -1`): the
  game moves to the top, and the brand and store badges stack beneath it. A phone
  visitor sees the pair first and the badges right after their guess. (The sketch's
  centred single-column web mockup is superseded by this.)
- **No score, demo pool only, rotating.** Pairs come from the existing demo pool
  (`demo_eligible = 1`). Next pair shows another one; no totals, no streaks.
- **App reminder every 3 pairs.** After the 3rd, 6th, 9th… guess, the result line is
  joined by a reminder card ("Like it? The app has Party, Marathon and hundreds more
  pairs" + store badges). It doesn't block: Next pair keeps working. *(Builder may
  tune the copy.)*
- Everything below the hero (modes, how it works, download) stays, with the
  screenshots that the hero used to show moving down if they're still useful.
- Track: `home_pair_guess`, `home_next_pair`, `home_reminder_shown`, plus the existing
  store-click events with `location: 'hero_pair'` / `'reminder'`.

## Server (aintreal-game)

Additive endpoints, deployable before the app ships (like the leaderboard data change).

1. **Home pair:** `GET` returns one random **demo-pool** pair (`demo_eligible = 1`;
   owner: the curated pool for the first round only, which also covers the 1.1
   "easier first rounds" item for the opening pair) with neutral image URLs and an opaque
   token, **no `aiPosition`**. The token lets the server know the pair and which side is
   AI without storing state (e.g. HMAC-signed `{pairId, aiSide, issuedAt}`); builder's
   call on the mechanism.
2. **Guess:** `POST {token, choice}` returns `{correct, aiSide}` and a second token that
   records the result (signed `{pairId, aiSide, choice, correct}`).
3. **Create Classic with a first round:** the existing create/start flow accepts that
   result token. The server verifies it, puts the pair in round 1 with the recorded
   answer (no response time, no speed bonus), fills rounds 2+ from the **full pool**
   as today (excluding that pair), and starts play at round 2. A missing or bad token means a normal game.
4. **Web demo:** the website can keep using `GET /api/game/demo-pairs` (nothing is
   scored there). It should switch to the neutral image URLs below.

### Neutral image URLs (the answer-in-the-filename leak)

Pair images are served at their R2 paths, e.g. `/api/images/pairs/<id>/ai.png` and
`/real.jpg`, so the file name gives away the answer (the open "Channel 1" item). With
the guess front and centre, the new home pair endpoint and the demo endpoint must serve
URLs that don't reveal which image is which (e.g. `/api/images/p/<opaque>` resolved
server-side). Neutralising URLs inside regular game rounds is in scope only if it
falls out naturally; otherwise it stays the separate Channel-1 item.

### Dependency on the held answer-leak PRs

aintreal-game #17/#18 change the game protocol (no `aiPosition` in `round_start`,
new `answer_result`, rejoin/grace) and are held until 1.0.2 is live in both stores.
1.1 ships after that cutover, so **build the create-with-first-round change on top of
#17/#18** (after they merge), not on today's main. The home pair and guess endpoints are
independent and can land earlier.

### Details settled after the builder review

- **Tokens: short-lived, replay tolerated.** Pair and result tokens expire after 15
  minutes. They stay stateless, so someone could re-POST a pair token with the other
  choice and turn a wrong home guess into a right one. That gains one round of one solo
  game. Solo games already have weak leaderboard integrity, which is a separate 1.2
  item, so no nonce store is added now.
- **Stats for the carried round 1.** Once the game starts, round 1 counts like any other
  answer in `solo_answered`/`solo_correct` and in per-pair accuracy/difficulty. It has a
  null response time and a `carried: true` flag, is excluded from average response time,
  and earns no speed bonus. Home guesses that never become a game are recorded
  nowhere on the server (client analytics only).
- **Carrying it into the game.** The result token rides as a new field on
  `POST /api/game/create` (same mobile gates as today) into the DO config. It is
  applied when rounds are built at start. The app goes straight to round 2 ("Round 2 of
  N", score already including round 1). Round 1 shows in the end-of-game results like any
  round. Write the plan against the `fix/answer-leak-channel2` + `feat/ws-rejoin-resync`
  branches; implement after they merge.
- **No new auth on the home pair and guess endpoints.** They're public, like
  `demo-pairs`, which already exposes the demo pool with answers. Add a basic per-IP rate
  limit only if the Worker already has a pattern for it.
- **Neutral URLs.** Use a stable opaque id per image (e.g. HMAC of the R2 path), so CDN,
  browser and `cached_network_image` caching keep working. Serve with no file extension.
  The `Content-Type` header can still differ (PNG vs JPEG), which is accepted for now:
  you need devtools to see it, the web demo is unscored, and the app doesn't show
  headers. `demo-pairs` keeps returning the old URLs too, for `/try` and 1.0.x clients.
  New consumers use the neutral ones.
- **Signing secret.** One new Worker secret for prod and local dev. Creating it needs
  the owner's explicit go at build time, followed by an inventory entry.
- **Web.** `/try` is unchanged. Web events use the page's existing `trackEvent` (GA).
  Nothing is counted server-side.
- **Home pair fails to load** (offline, API error). The pair area shows a retry tile
  ("Couldn't load a pair · Tap to retry"). The mode row and Join stay usable beneath it.

## Constraints

- Flutter app; the server is the Cloudflare Worker + Durable Object in aintreal-game.
- Branch + PR per change; relay review; CI required for code changes (game repo has
  CI); merging aintreal-game deploys.
- 1.0.x apps must keep working against the new server (additive endpoints only).
- iOS deployment target moves to 15.0 in the same 1.1 release (separate item).

## Decided by the owner

- Pair on open with one-tap guessing, on app and web; consistent feel like Reddit.
- Next pair only after a guess. Hint copy: "👆 Tap the image that AIn't Real".
- App: a game starts only on guess + Next pair; round 1 carries the home result with no
  time score; play starts at round 2; last settings or defaults.
- Web: no score, demo pool, rotating; remind about the app every 3 pairs; no annoyance
  mechanics.
- App home pair comes from the demo pool; rounds 2+ from the full pool.
- Web: the game replaces the hero image; the two-column hero stays with store badges on
  the left; on narrow views the game moves on top like the current hero image.

## My calls (owner to check)

- The home guess counts toward the game score (right/wrong only).
- Fresh pair every time the home screen appears.
- Menu icon holds profile, How to Play, settings and the test-mode version line.
- Web keeps "Play 5 rounds" → `/try`.
- Reminder card copy and placement (under the result line).
- Server-held answer via signed tokens rather than sending `aiPosition` to the app.
- Neutral image URLs for the home and demo endpoints are part of this work.

## Left to the builder

Exact visuals, spacing and animation; token format and signing key handling (follow the
credentials rules: new secret goes in the inventory); endpoint paths; how the app passes
the result token into game creation; image preloading for the next home pair; tests.
