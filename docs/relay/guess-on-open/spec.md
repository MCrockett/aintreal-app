# Spec: guess on open (1.1 home redesign)

Source design, written with the owner on 2026-10-24 and checked by a builder review:
[docs/superpowers/specs/2026-10-24-guess-on-open-design.md](../../superpowers/specs/2026-10-24-guess-on-open-design.md),
with a clickable sketch next to it. This spec turns that design into numbered
requirements. Where they differ, this spec wins.

## Why

Organic installs from Google and the Play Store are rising, but a newcomer opens the app
to a menu of mode cards, and many play one game or none (2026-10-15 deep dive: 6 of 11
recent sign-ins played zero games). The Reddit splash already works the way we want: a
pair on screen, "Which one is AI?", one tap. The app and aint-real.com should feel the
same. Open it and you are already guessing.

Success: a newcomer makes a guess within seconds of opening the app or the site, without
choosing a mode or reading instructions. On the web, that first guess leads to the store
badges.

## Decisions made

Owner decisions (2026-10-24):

- D1. Every surface opens on a pair you can guess with one tap: "Which one is AI?", the
  hint "👆 Tap the image that AIn't Real", and an instant reveal.
- D2. Next pair appears only after a guess. Before the guess, the hint fills that spot.
- D3. App: a Classic game starts only when the player guesses and then taps Next pair.
  Round 1 carries the home guess (right or wrong, no time score). Play starts at
  round 2, using the player's last Classic settings, or the defaults the first time.
- D4. App: the home pair comes from the demo pool (`demo_eligible = 1`). Rounds 2 and
  later come from the full pool, as Classic does today.
- D5. Web: no score, demo pool only, rotating pairs, and an app reminder every 3 pairs.
  Nothing annoying: no waits, lockouts or walls.
- D6. Web: the game replaces the phone screenshots in the current two-column hero. The
  left column keeps the brand and gets the store badges. At 900px or narrower the game
  moves to the top, as the hero image does today.
- D7. Wordmark matches Reddit and the web: dark "AI", coral gradient on "n't Real".

Agent decisions, with reasons:

- D8. The server holds the answer for the home pair. The app gets the pair without
  `aiPosition`, sends the guess to the server, and gets the result back. Reason: the
  answer-leak work (aintreal-game #17/#18) and the Reddit splash rule both say the client
  must not know the answer before the tap.
- D9. Stateless signed tokens with a 15-minute expiry carry the pair and then the guess
  result. A replay can flip one round of one solo game, and that is accepted. Reason: it
  avoids a new storage binding, and solo leaderboard integrity is a separate 1.2 item.
- D10. Neutral image URLs for the new home-pair endpoint and the web demo. Today's
  URLs end in `/ai.png` and `/real.jpg`, which gives the answer away on the page that
  now puts the guess front and centre.
- D11. The server work is additive. The home-pair and guess endpoints and the neutral
  URLs can deploy before the app ships. Create-with-first-round is built after
  aintreal-game #17/#18 merge, because those change the round protocol and are held
  until 1.0.2 is live in both stores.

## Non-goals

- The Reddit splash.
- The weekly leaderboard, packs, Daily Challenge, and seen-pair dedup.
- Trimming or re-curating the demo pool.
- Changing the Party, Marathon, lobby, game or results screens beyond what R9 needs.
- Neutral image URLs inside regular game rounds (the separate Channel-1 item), unless
  that falls out of R16 for free.
- Changing `/try`.

## Requirements

### App home (aintreal-app)

- R1. The home screen shows, top to bottom: the wordmark (D7) with a menu icon; "Which
  one is AI?"; the pair, as large as fits; a result line; the hint or Next pair (D2);
  "or pick a mode" with a compact row of Party (2-8 players), Classic and Marathon (26,
  one miss); then "Join a party · enter code".
- R2. The menu holds profile and sign-in, How to Play, settings, and the version line,
  which shows only in test mode. The existing 5-tap test-mode toggle keeps working,
  wherever its subtitle ends up.
- R3. When the home screen appears, the app fetches one home pair (R12). Each time the
  home screen appears, it shows a fresh pair, including after a game and on app reopen.
- R4. Tapping an image sends the guess (R13). On the response the app shows the reveal:
  green border and "Real" tag on the real image, red border and "AI" tag on the AI image,
  and "✓ Nailed it. That one is AI." or "✗ Fooled you. The other one is AI." The hint
  becomes Next pair. Further taps on the pair do nothing.
- R5. Tapping Next pair creates a Classic solo game with the result token (R14) and the
  settings from R7, then opens the game at round 2.
- R6. Leaving the home screen without tapping Next pair creates nothing on the server.
- R7. The app saves the last Classic settings (rounds, time per round) on the device
  whenever a Classic game is created. A home-started game and the create screen's
  initial values both use them, or the current defaults (6 rounds, 5 s) if none are
  saved.
- R8. The mode cards' existing actions (create Party, Classic, Marathon; Join) are
  unchanged; only their layout moves.
- R9. In a home-started game the round header reads "Round 2 of N" first, the score
  already includes round 1, and round 1 shows in the end-of-game results like any round.
- R10. Analytics events: home pair shown, home guess (correct or not), and game started
  from home. They follow the existing `AnalyticsService` style.
- R11. The home layout works on phones and iPads, in the app's current orientations.

### Server (aintreal-game)

- R12. Home pair endpoint (GET, public). It returns one random demo-pool pair with
  neutral image URLs (R16), left and right positions chosen at random, and a signed pair
  token holding the pair id, the AI side and the issue time. The response has no
  `aiPosition` and no other field that reveals the answer.
- R13. Guess endpoint (POST, public). It takes the pair token and a choice. It rejects
  bad or expired tokens with 400. Otherwise it returns whether the guess was correct, the
  AI side, and a signed result token holding the pair id, AI side, choice, correctness
  and issue time.
- R14. `POST /api/game/create` accepts an optional result token for Classic solo games,
  behind the same mobile gates as today. When the token is valid and unexpired, the game
  is built with that pair as round 1 and the recorded answer. Rounds 2 to N come from the
  full pool without that pair, and play starts at round 2. When the token is missing,
  invalid or expired, a normal game is created and the response says the token was
  ignored.
- R15. The carried round 1 counts toward the score (correct or not) and toward
  `solo_answered`, `solo_correct` and per-pair accuracy and difficulty. It has a null
  response time and a `carried` flag, is excluded from average response time, and earns
  no speed bonus. Home guesses that never become a game are not recorded on the server.
- R16. Neutral image URLs. Each image gets a stable opaque id (for example an HMAC of its
  R2 path) and is served at a path with no file extension and nothing that reveals real
  or AI. Caching keeps working (stable URL, same cache headers). The `Content-Type` may
  still differ between PNG and JPEG; that is accepted.
- R17. `GET /api/game/demo-pairs` keeps its current fields and URLs for `/try` and
  1.0.x clients, and adds the neutral URLs for new consumers.
- R18. Token signing uses one new Worker secret, set for prod and local dev. Creating it
  needs the owner's explicit go at build time, and it is then added to the credentials
  inventory.
- R19. 1.0.x and 1.0.2 apps keep working against the new server. Every change is
  additive.

### Website (aintreal-game `ui/index.html`)

- R20. Hero layout per D6. Left: brand, "Can you spot the fake?", the subtitle, the
  store badges, and a "Play 5 rounds" button linking to `/try`. Right: "Which one is AI?",
  the pair, the result line, and the hint or Next pair.
- R21. At 900px or narrower the game is first and the left column stacks beneath it.
- R22. Pairs come from the demo pool through `demo-pairs`, using the neutral URLs. No
  score, streak or totals are shown or stored.
- R23. After the 3rd, 6th, 9th and later guesses, a reminder card shows under the
  result line, with copy along the lines of "Like it? The app has Party, Marathon and
  hundreds more pairs" and the store badges. It never blocks Next pair.
- R24. Web analytics through the page's existing `trackEvent`: `home_pair_guess`,
  `home_next_pair`, `home_reminder_shown`, and store clicks with location `hero_pair` or
  `reminder`.
- R25. Everything below the hero stays. Party guests joining by code are unaffected.

### Delivery

- R26. Delivery is split into separate PRs, one open per repo at a time:
  (a) aintreal-game: R12, R13, R16, R17 and R18, deployable now;
  (b) aintreal-game: R20 to R25, website;
  (c) aintreal-game: R14 and R15, after #17/#18 merge;
  (d) aintreal-app: R1 to R11, against a server with (a) and (c).
  The plan sets the order and may merge (a) with (b).

## Failure paths

- F1. The home pair fails to load (offline, API error, empty pool). The pair area shows
  a retry tile ("Couldn't load a pair · Tap to retry"). The mode row and Join stay usable.
- F2. The guess request fails. The app keeps the pair unrevealed, shows a short error,
  and lets the player tap again. The pair token is still valid within its 15 minutes.
- F3. The player waits more than 15 minutes before tapping Next pair. Create ignores the
  expired token (R14), and the app starts a normal game at round 1 with no error shown.
- F4. Create fails for another reason (network, 426 version gate). The app shows the
  same error handling as the existing create flow and stays on home with the reveal.
- F5. Web: `demo-pairs` fails or returns nothing. The hero falls back to the current
  phone screenshots, and the store badges stay.
- F6. An image fails to load. The pair shows its retry state (app) or the next pair is
  fetched (web). It never shows a half-loaded pair that can be guessed.
- F7. A bad, tampered or replayed token. Bad or tampered tokens get 400 from guess and
  are ignored by create. Replays within 15 minutes are accepted (D9).

## Open questions
