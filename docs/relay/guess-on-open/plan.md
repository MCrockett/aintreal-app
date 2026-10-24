# Guess on Open Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** On the app home and on aint-real.com, the first thing a visitor sees is a pair they can guess with one tap. In the app, Next pair turns that guess into round 1 of a Classic game.

**Architecture:** The game server (Cloudflare Worker + `GameRoom` Durable Object, aintreal-game) gets additive endpoints:
- a home pair without the answer, carried in an encrypted token;
- a server-checked guess that returns an encrypted result token;
- neutral image ids;
- create-with-first-round.

The website hero (`ui/index.html`) becomes a no-score demo-pool game. The Flutter home screen gets a pair controller and creates a solo game with the result token, then reuses the existing lobby auto-start.

**Tech Stack:**
- aintreal-game: Worker JS (ES modules), WebCrypto (`crypto.subtle`), D1, R2, `node --test` (Node 22).
- aintreal-app: Flutter 3.38, Riverpod, dio, SharedPreferences, `flutter test`.

**Spec:** [docs/relay/guess-on-open/spec.md](spec.md). The design background is in [docs/superpowers/specs/2026-10-24-guess-on-open-design.md](../../superpowers/specs/2026-10-24-guess-on-open-design.md).

## Global Constraints

- Copy, exactly:
  - "Which one is AI?"
  - "👆 Tap the image that AIn't Real"
  - "▶ Next pair"
  - "✓ Nailed it. That one is AI."
  - "✗ Fooled you. The other one is AI."
  - "Couldn't load a pair · Tap to retry"
- Plain English in all copy and docs. No em-dashes (owner rule).
- Wordmark: dark "AI" (`#b02e45`), with the coral gradient `#ff6b6b → #ff8a8a` on "n't Real" (D7).
- Tokens: AES-GCM through WebCrypto, keyed from Worker secret `HOME_TOKEN_SECRET`, expiring 15 minutes (900 s) after issue (D9, R18).
- Every server change is additive. 1.0.x and 1.0.2 apps keep working (R19).
- Classic defaults when nothing is saved: 6 rounds, 5 s per round (R7).
- Layout check sizes: 375x667, 393x852, 412x915, 1024x1366. Each image is at least 150 logical px wide (R11).
- Web reminder after the 3rd, 6th, 9th and later guesses (R23). Narrow breakpoint: 900px (R21).
- One open PR per repo. Merging aintreal-game deploys. CI is required for code PRs.

## Delivery (R26)

| PR | Repo | Tasks | When |
|----|------|-------|------|
| A | aintreal-game | 1-4 | now (needs the owner's go to create the secret) |
| B | aintreal-game | 5 | after A merges |
| C | aintreal-game | 6-7 | after #17/#18 merge (they need a rebase onto #19 first) |
| D | aintreal-app | 8-12 | after A and C are deployed; ships as 1.1 |

Each game PR is its own relay feature in aintreal-game (`relay new <slug> --base main`), citing this plan. This app feature carries PR D.

## Review Focus

1. **Slow images on the app home.** The pair must not be guessable until both images have loaded (F6). Pinned in Task 9 (`guess ignored until both images loaded`).
2. **App resumed after a long background.** The pair token has expired by then, so the app quietly loads a fresh pair (F2). Pinned in Task 9 (`resume after expiry refreshes`).
3. **Carried round 1 with a null response time** reaching the speed-bonus sort, the pair response-time average or the reveal maths, and producing NaN or a crash. Pinned in Task 7 (`carried round never NaN`).
4. **A small demo pool on the web.** Rotation must restart cleanly when every pair has been shown, not stall or repeat in a loop. Pinned in Task 5 (`rotation restarts after exhaustion`).
5. **A double tap on Next pair** must create exactly one game (R4a). Pinned in Task 12 (`double tap creates one game`).

---

## PR A: server endpoints (aintreal-game)

### Task 1: Encrypted tokens

**Files:**
- Create: `src/utils/tokens.js`
- Modify: `.github/workflows/deploy.yml` (run `node --test test/` in the ci job if it doesn't already)
- Test: `test/tokens.test.mjs`

**Interfaces:**
- Produces:
  - `sealToken(secret: string, payload: object, nowMs?: number) -> Promise<string>`: base64url of `iv(12) || ciphertext`. The payload gets `iat` (seconds).
  - `openToken(secret: string, token: string, nowMs?: number) -> Promise<{ok: true, payload} | {ok: false, reason: 'bad_token' | 'expired_token'}>`.
  - `TOKEN_TTL_S = 900`.
  - The key is derived with `crypto.subtle.importKey` over SHA-256 of `secret`, then AES-GCM-256. Use a random 12-byte IV per token.

Covers: R18, D9, F7

- [ ] **Step 1: Write the failing tests**

```js
test('sealed token round-trips', async () => {
  const t = await sealToken('s3cret', { pairId: 'p1', aiSide: 'left' }, 1_000_000);
  const r = await openToken('s3cret', t, 1_000_000 + 899_000);
  assert.equal(r.ok, true);
  assert.equal(r.payload.aiSide, 'left');
});
test('token payload is not readable', async () => {
  const t = await sealToken('s3cret', { pairId: 'p1', aiSide: 'left' });
  const raw = Buffer.from(t, 'base64url').toString('latin1');
  assert.ok(!raw.includes('left') && !raw.includes('aiSide'));
});
test('expired after 900s', async () => {
  const t = await sealToken('s3cret', { a: 1 }, 0);
  assert.deepEqual(await openToken('s3cret', t, 901_000), { ok: false, reason: 'expired_token' });
});
test('tampered, wrong key and garbage are bad_token', async () => {
  const t = await sealToken('s3cret', { a: 1 });
  const flipped = t.slice(0, -2) + (t.at(-2) === 'A' ? 'B' : 'A') + t.at(-1);
  for (const [k, v] of [['s3cret', flipped], ['other', t], ['s3cret', 'zz'], ['s3cret', '']]) {
    assert.equal((await openToken(k, v)).reason, 'bad_token');
  }
});
```

- [ ] **Step 2: Run** `node --test test/tokens.test.mjs`. Expected: FAIL (module not found).
- [ ] **Step 3: Implement `src/utils/tokens.js`** to the interface above.
- [ ] **Step 4: Run** `node --test test/tokens.test.mjs`. Expected: PASS.
- [ ] **Step 5: Add `test/*.test.mjs` to CI** if `deploy.yml` doesn't already run `node --test test/`, so these tests gate the deploy. Commit `feat(home): encrypted home tokens`.

### Task 2: Neutral image ids and route

**Files:**
- Create: `src/utils/imageIds.js`
- Modify: `src/index.js` (`handleImages`, around lines 208-260)
- Test: `test/image-ids.test.mjs`

**Interfaces:**
- Produces:
  - `imageIdFor(secret: string, r2Path: string) -> Promise<string>`: deterministic and fixed length. The path is UTF-8 encoded and zero-padded to exactly `IMAGE_PATH_PAD = 96` bytes (it throws if longer; today's paths are about 50). The IV is the first 12 bytes of HMAC-SHA256(secret, r2Path), and the ciphertext is AES-GCM of the padded bytes, base64url `iv || ct`. So every id has the same length (12 + 96 + 16 bytes = 166 base64url chars), and the AI and real ids can't be told apart by length. The same path always gives the same id, so CDN, browser and `cached_network_image` caching keep working.
  - `r2PathFor(secret: string, id: string) -> Promise<string | null>`: strips the zero padding after decrypting.
  - `neutralUrl(secret, r2Path) -> Promise<string>`: returns `/api/images/p/<id>`.
  - Key derivation uses a distinct label (`'img:' + secret`), so token and image keys differ.

Covers: R16

- [ ] **Step 1: Write the failing tests**
  - `stable id`: the same path twice gives an equal id.
  - `id hides the path`: the id does not contain `ai`, `real`, `.png` or `.jpg` as substrings of its decoded latin1 bytes. Also, `neutralUrl` has no `.` after `/p/`.
  - `round-trip`: `r2PathFor(imageIdFor(p)) === p` for `pairs/x/ai.png` and `pairs/x/real.jpg`.
  - `bad id`: `r2PathFor(secret, 'nope')` returns `null`.
  - `ids have one length`: the ids for `pairs/<uuid>/ai.png`, `pairs/<uuid>/real.jpg`, `pairs/<uuid>/ai.webp` and `pairs/<uuid>/real.webp` all have length 166.
  - `too long throws`: a 97-byte path throws.
- [ ] **Step 2: Run** `node --test test/image-ids.test.mjs`. Expected: FAIL.
- [ ] **Step 3: Implement** `imageIdFor`, `r2PathFor` and `neutralUrl` as above.
- [ ] **Step 4: Route `p/<id>` in `handleImages`.** When `path.startsWith('p/')`, resolve it with `r2PathFor(env.HOME_TOKEN_SECRET, path.slice(2))`. Return a 404 for `null`, and otherwise serve exactly as today: same origin check (`isAllowedImageRequest`), same headers, same `Cache-Control`.
- [ ] **Step 5: Run** `node --test test/image-ids.test.mjs`. Expected: PASS. Commit `feat(home): neutral image urls`.

### Task 3: Home pair and guess endpoints

**Files:**
- Create: `src/routes/home.js`
- Modify: `src/routes/game.js` (route table at the top of `handleGame`)
- Test: `test/home-endpoints.test.mjs`

**Interfaces:**
- Consumes: `sealToken` and `openToken` (Task 1), `neutralUrl` (Task 2).
- Produces:
  - `GET /api/game/home-pair` returns `200 {leftUrl, rightUrl, pairToken, category, photographer, photographerUrl}`. The pair is one random `demo_eligible = 1` row, and the side is random. The token payload is `{t:'pair', pairId, aiSide}`. The response has no `aiPosition` and no `aiUrl`/`realUrl`.
  - `POST /api/game/home-guess {pairToken, choice}`:
    - success returns `200 {correct: bool, aiSide: 'left'|'right', resultToken}`, with result payload `{t:'result', pairId, aiSide, choice, correct}`;
    - a malformed body or a choice other than `left`/`right` gets `400 {error:'bad_request'}`;
    - a bad token, or one whose `t !== 'pair'`, gets `400 {error:'bad_token'}`;
    - an expired token gets `400 {error:'expired_token'}`.
  - An empty demo pool gets `404 {error:'no_pairs'}`.
  - Export `getHomePair(request, env)` and `postHomeGuess(request, env)` for tests. They take `env.DB` and `env.HOME_TOKEN_SECRET`.

Covers: R12, R13, F7

- [ ] **Step 1: Write the failing tests.** Use a fake `env.DB` whose `prepare().bind().first()` returns `{id:'p1', real_r2_path:'pairs/p1/real.jpg', ai_r2_path:'pairs/p1/ai.png', category:'cats', photographer:'X', photographer_url:'u'}`.
  - `home pair leaks nothing`: `JSON.stringify(body)` has no `aiPosition`, `ai.png`, `real.jpg` or `"ai"` key, and both URLs start `/api/images/p/`.
  - `guess correct and wrong`: decode the side by calling `openToken` on `pairToken` in the test. The right choice returns `correct:true`, and the other returns `correct:false`. Both return the same `aiSide`.
  - `result token opens`: the `resultToken` payload equals `{t:'result', pairId:'p1', aiSide, choice, correct}`, plus `iat`.
  - `guess errors`: choice `'top'` gets 400 `bad_request`, a body that isn't JSON gets 400 `bad_request`, a result token passed as `pairToken` gets 400 `bad_token`, and a token sealed at `now - 901s` gets 400 `expired_token`.
  - `empty pool`: `first()` returns `null`, which gives 404 `no_pairs`.
- [ ] **Step 2: Run** `node --test test/home-endpoints.test.mjs`. Expected: FAIL.
- [ ] **Step 3: Implement `src/routes/home.js`** and add the two routes before the `/create` match in `handleGame`. They are public, with no Turnstile and no mobile gate. Use the `json`/`error` helpers from `src/utils/response.js`.
- [ ] **Step 4: Run** `node --test test/`. Expected: PASS, including the existing tests.
- [ ] **Step 5: Commit** `feat(home): home pair and guess endpoints`.

### Task 4: demo-pairs neutral fields, secret, deploy

**Files:**
- Modify: `src/routes/game.js` (`getDemoPairs` formatter, around lines 270-285)
- Modify: `.dev.vars.example` (create it if missing; `.dev.vars` stays gitignored)
- Test: `test/home-endpoints.test.mjs` (add a case)

**Interfaces:**
- Produces: each `demo-pairs` item keeps every current field and adds `leftNeutralUrl`, `rightNeutralUrl`, which come from `neutralUrl`.

Covers: R17, R18, R19

- [ ] **Step 1: Write the failing test** `demo-pairs keeps old fields and adds neutral ones`. It checks that `leftUrl` still matches `^/api/images/pairs/`, that `aiPosition` is present, and that `leftNeutralUrl` starts with `/api/images/p/`.
- [ ] **Step 2: Implement it.** The formatter becomes async per pair (`Promise.all`).
- [ ] **Step 3: Run** `node --test test/`. Expected: PASS.
- [ ] **Step 4: Secret, prod and local.** Ask the owner for an explicit go covering both. Then:
  - prod: generate a value with `openssl rand -base64 32` piped straight into `npx wrangler secret put HOME_TOKEN_SECRET`, so it is never printed or saved;
  - local: write a separately generated value into `.dev.vars` (gitignored) as `HOME_TOKEN_SECRET=...`, without printing it;
  - add `HOME_TOKEN_SECRET=` with a comment to `.dev.vars.example`;
  - add one inventory entry to `~/StudioProjects/UpstreamPartners/portfolio/credentials/inventory.md` (name, purpose, consumers: aintreal-game Worker prod and local dev; no value).

  The PR must not merge before the prod secret exists.
- [ ] **Step 4b: Local check.** Run `npx wrangler dev --port 8789`, then `curl -s localhost:8789/api/game/home-pair`, which returns a `pairToken`. POST that token to `/api/game/home-guess` with `choice:"left"`, which returns `correct` and a `resultToken`. Fetching the returned `leftUrl` with an allowed `Origin` returns an image.
- [ ] **Step 5: Verify after deploy:**
  - `curl -s https://api.aint-real.com/api/game/home-pair` returns JSON with `pairToken` and no `aiPosition`;
  - the `leftUrl` image loads with the aint-real.com `Origin`/`Referer` (the same rule as today);
  - `curl -s .../demo-pairs?count=1` still has `aiPosition` and `leftUrl`.

  Commit `feat(home): neutral demo urls; HOME_TOKEN_SECRET`.

## PR B: website hero (aintreal-game)

### Task 5: Hero game on aint-real.com

**Files:**
- Create: `ui/home-pair.js` (an ES module with pure logic, plus `mountHeroGame(root)`)
- Modify: `ui/index.html` (the hero section, around lines 20-140 of the CSS and the `.hero-image` block in the markup)
- Test: `test/home-pair-web.test.mjs`

**Interfaces:**
- Consumes: `GET /api/game/demo-pairs?count=10&exclude=<ids>`, using `leftNeutralUrl`/`rightNeutralUrl` and `aiPosition` (unscored on the web, so sending the answer is fine). The exclude parameter is the existing one the endpoint already reads; confirm its name in `getDemoPairs`.
- Produces (pure, exported for tests):
  - `shouldRemind(guessCount: number) -> boolean`: true for 3, 6, 9 and so on.
  - `createRotation(fetchBatch: (excludeIds) => Promise<Pair[]>) -> { next(): Promise<Pair | null> }`. It skips ids shown this page load. When a batch comes back empty after some ids have been shown, it clears the shown set and fetches again. Two empty fetches in a row give `null`.

Covers: R20, R21, R22, R23, R24, R25, F5, F6

- [ ] **Step 1: Write the failing tests**
  - `shouldRemind`: `[1,2,3,4,6,9,10].map(shouldRemind)` deep-equals `[false,false,true,false,true,true,false]`.
  - `rotation skips shown`: a fake batch returns `[a,b]`, then `[]`, then `[a,b]`. `next()` gives a, b, a, and the third call has cleared the exclusions.
  - `rotation restarts after exhaustion`: with a pool of 1, ten `next()` calls all return that pair, and none return `null`.
  - `rotation gives null when the pool is empty`: two empty fetches give `null`.
  - `rejected fetch`: a fetch that throws makes `next()` resolve `null` (the caller shows the F5 fallback), not reject.
  - `image failures stop after two`: with a fake image loader that always errors, `mountHeroGame`'s `onImageError` path tries exactly one other pair, then reports `fallback`, and makes no third attempt. Export the retry policy as `nextActionAfterImageError(failuresInARow: number) -> 'retry' | 'fallback'` and test `[1, 2].map(...)` deep-equals `['retry', 'fallback']`.
- [ ] **Step 2: Run** `node --test test/home-pair-web.test.mjs`. Expected: FAIL.
- [ ] **Step 3: Implement the pure functions**, then `mountHeroGame`. It renders the question, pair, result line, the hint or Next pair (D2), and the reminder card under the result line when `shouldRemind(count)`. The reminder copy is "Like it? The app has Party, Marathon and hundreds more pairs" with both store badges, and it clears on the next pair. A pair becomes clickable only after both `img` load events (F6). On an image error it tries one other pair. A second failure, or `null` from the rotation, shows the old `.phone-mockup` screenshots with a "Try again" button and stops automatic attempts (F5, F6).
- [ ] **Step 4: Edit `index.html`.**
  - `.hero-image` contents become the game mount, with the phone mockup kept as a hidden fallback.
  - The left column keeps the brand, the h2 and the subtitle. Then come the store buttons, then "Play 5 rounds" linking to `/try`. The old "Try the Demo" button is replaced by it.
  - The `@media (max-width: 900px)` rule keeps `.hero-image { order: -1 }`.
  - Add `trackEvent('home_pair_guess', {correct})`, `home_next_pair`, `home_reminder_shown`, and store clicks with `location: 'hero_pair'` and `location: 'reminder'`.
  - Leave the sections below the hero untouched.
- [ ] **Step 5: Run** `node --test test/`. Expected: PASS.
- [ ] **Step 6: Browser check.** Serve `ui/` locally against prod or `wrangler dev`, at 1280x800, 900x800 and 390x844:
  - the pair shows before the badges at 390 and 900;
  - three guesses show the reminder;
  - Next pair stays clickable;
  - blocking `/api/images/p/*` in devtools shows the fallback and "Try again".
- [ ] **Step 7: Commit** `feat(web): guess-on-open hero`.

## PR C: create with first round (aintreal-game, after #17/#18)

Base this on main after #17/#18 have merged. That changes `round_start` (no `aiPosition`) and adds `answer_result`, plus `test/harness.mjs`.

### Task 6: Create accepts a result token; game starts at round 2

**Files:**
- Modify: `src/routes/game.js` (`createGame`)
- Modify: `src/game/GameRoom.js` (`handleCreate`, `handleStartGame`, `fetchImagePairs`)
- Test: `test/first-round.test.mjs` (uses `test/harness.mjs`)

**Interfaces:**
- Consumes: `openToken` (Task 1), the result payload (Task 3).
- Produces:
  - `POST /api/game/create` body accepts an optional `firstRoundToken`. The Worker opens it. A valid `t:'result'` payload is passed to the DO as `firstRound = {pairId, aiSide, choice, correct}` beside `config`.
  - The DO decides whether to apply it, after normalising the config in `handleCreate` (`mode = config.mode || (config.soloMode ? 'classic' : 'party')`). It is applied only when the normalised `mode === 'classic'`. The Flutter `GameConfig` JSON sends `mode: 'classic'` and no `soloMode`, which must count.
  - The create response always carries `firstRound: 'applied' | 'ignored'`. It is `'ignored'` when the token is missing, bad, tampered, expired or of the wrong type, when the mode isn't classic, or when the pair row is gone; a normal game is created in those cases (R14). Old apps ignore the extra field.
  - `fetchImagePairs(count, excludeIds = [])`.
  - In `handleStartGame` with `config.firstRound`:
    - fetch that pair by id, plus `rounds - 1` random pairs excluding it;
    - round 0 maps `aiSide` `left`/`right` to `top`/`bottom` for the stored `aiPosition`;
    - set `answers[0][hostId] = {choice: <mapped>, responseTime: null, earlyClick: false, carried: true}`, `currentRound = 1` and `roundEnded = 0`;
    - the first `round_start` then says `round: 2`.
  - If the pair row is gone at start, it starts a normal game at round 1.

Covers: R14, F3

- [ ] **Step 1: Write the failing tests** (harness room, solo classic, `rounds: 6`):
  - `applied`: the first `round_start` has `round === 2` and `totalRounds === 6`; `answers[0][host].carried === true`; no later round reuses `pairId`.
  - `ignored`: an expired token makes create respond with `firstRound: 'ignored'`, and the first `round_start` has `round === 1`.
  - `party ignores it`: with `mode: 'party'`, the response says `ignored` and the game starts at round 1.
  - `flutter-shaped request`: the body `{hostName, config: {rounds: 6, timePerRound: 5, speedBonus: false, randomBonuses: false, mode: 'classic'}, firstRoundToken}`, with no `soloMode`, gets `applied`.
  - `tampered and malformed`: a flipped-byte token and the string `'x'` both get `ignored`, and the game starts at round 1.
  - `replay accepted`: the same valid result token used for two creates within 15 minutes gets `applied` both times (D9).
  - `missing token`: a normal create gets `firstRound: 'ignored'` and is otherwise unchanged.
  - `party join unchanged`: a party create plus join through the harness behaves exactly as before (existing join test still passes, plus one join after a home-started create in another room).
  - `left maps to top`: `aiSide:'left', choice:'left'` stores `aiPosition:'top'` and the choice `'top'`.
- [ ] **Step 2: Run** `node --test test/first-round.test.mjs`. Expected: FAIL.
- [ ] **Step 3: Implement** to the interface.
- [ ] **Step 4: Run** `node --test test/`. Expected: PASS, including #17/#18's tests.
- [ ] **Step 5: Commit** `feat(home): create classic with a carried first round`.

### Task 7: Scoring and stats for the carried round

**Files:**
- Modify: `src/game/GameRoom.js` (the speed bonus in the reveal, around line 788-805; `calculateAvgResponseTime`, around line 1210; the pair stats average, around line 1083; per-answer time, around line 1106)
- Test: `test/first-round.test.mjs` (add cases)

**Interfaces:**
- Consumes: the `carried: true` answers from Task 6.
- Produces: carried answers count for correctness everywhere (score, `solo_answered`, `solo_correct`, `times_shown`, `times_correct`, difficulty inputs). They are skipped in the speed-bonus ranking and in every response-time average, and they never earn a speed bonus.

Covers: R15, R9

Scoring stays where it is today: Classic points are worked out in the reveal sequence after the last round, and the game screen shows no running score in Classic (it shows "Round X / N" only). So R9's "score already includes round 1" is met at the reveal and results, which this task tests. Nothing needs crediting earlier.

- [ ] **Step 1: Write the failing tests** by playing a 3-round home-started game through the harness to the end:
  - `carried correct scores`: the final score includes round 1's correct points, and the saved history row has `solo_answered = 3`, with `solo_correct` matching.
  - `carried round never NaN`: every numeric field in the `game_over` / results payload and in the D1 binds is finite or null, and `avgResponseTime` equals the mean of rounds 2-3 only.
  - `no speed bonus on carried`: the round 1 reveal shows no speed bonus for the carried answer.
  - `pair stats`: the round-1 pair's `times_shown` goes up by 1, and `times_correct` goes up by 1 if it was correct.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.** Filter `a.carried` out of time arrays and sorts, and keep it in the correctness counts.
- [ ] **Step 4: Run** `node --test test/`. Expected: PASS.
- [ ] **Step 5: Commit** `feat(home): carried round counts without a time score`.

## PR D: app home (aintreal-app, 1.1)

### Task 8: Home pair API

**Files:**
- Create: `lib/models/home_pair.dart`, `lib/core/api/home_pair_api.dart`
- Modify: `lib/core/api/endpoints.dart`, `lib/core/api/game_api.dart` (`createGame` gets an optional `String? firstRoundToken`, added to the body), `lib/models/game.dart` (`CreateGameResponse` around line 188 gains `firstRound`)
- Test: `test/unit/home_pair_api_test.dart`

**Interfaces:**
- Produces:
  - `class HomePair { String leftUrl, rightUrl, pairToken; String? category; }`. The URLs are made absolute with `Env.apiBase`.
  - `class GuessResult { bool correct; String aiSide; String resultToken; }`.
  - `sealed class GuessFailure` with variants `TokenExpired`, `NetworkFailure`.
  - `HomePairApi.instance.fetch() -> Future<HomePair>`.
  - `HomePairApi.instance.guess(String pairToken, String choice) -> Future<GuessResult>`, which throws `TokenExpired` on 400 `expired_token` or `bad_token`, and `NetworkFailure` otherwise.
  - `CreateGameResponse` gains `String? firstRound`.

Covers: R12, R13 (client side)

- [ ] **Step 1: Write the failing tests** with dio's mock adapter or the existing test pattern in `test/unit/`: fetch parsing; guess parsing; `expired_token` and `bad_token` give `TokenExpired`; a socket error gives `NetworkFailure`; `createGame(firstRoundToken: 'x')` sends `firstRoundToken: 'x'`, and omits it when null.
- [ ] **Step 2: Run** `flutter test test/unit/home_pair_api_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** to the interface.
- [ ] **Step 4: Run.** Expected: PASS. Commit `feat(2.1): home pair api`.

### Task 9: Home pair controller

**Files:**
- Create: `lib/features/home/home_pair_controller.dart`
- Test: `test/unit/home_pair_controller_test.dart`

**Interfaces:**
- Consumes: `HomePairApi` (Task 8), injected as a constructor parameter for tests.
- Produces: `homePairProvider = StateNotifierProvider<HomePairController, HomePairState>`.
  - `HomePairState { int loadId; HomePairPhase phase; HomePair? pair; GuessResult? result; String? choice; bool imagesReady; bool guessPending; bool error; }`
  - `HomePairPhase { loading, ready, revealed, failed }`
  - Methods:
    - `load()`: increments `loadId`, then fetches; failure goes to `failed`.
    - `guess(String side)`: ignored unless `ready && imagesReady && !guessPending`. Drops the response if `loadId` changed. `TokenExpired` calls `load()` with no error. `NetworkFailure` stays `ready`, sets `error: true` and allows another tap.
    - `onResume(DateTime now)`: calls `load()` if the pair was fetched more than 15 minutes ago and is not revealed.
    - `leave()`: called when the home route stops being visible. It increments `loadId` and clears `guessPending`, so any in-flight guess response, success or failure, is dropped.
    - `imagesLoaded(int loadId)` and `imageFailed(int loadId)` take the load id of the pair the image belonged to, and ignore stale ones.
    - `bool isCurrent(int loadId)`: used by Task 12 to guard create responses.

Covers: R3, R4, R4a, F1, F2, F6

- [ ] **Step 1: Write the failing tests** with a fake API:
  - `load shows a pair`;
  - `guess ignored until both images loaded`;
  - `guess reveals`: `phase == revealed`, `result.correct` is set, and a second `guess()` is a no-op;
  - `pending guard`: two quick `guess()` calls make one API call;
  - `stale response dropped`: start a guess, call `load()` before it resolves, and the old result never shows;
  - `expired refreshes`: on `TokenExpired`, a new pair loads with `error == false`;
  - `network error allows retry`;
  - `resume after expiry refreshes`: `onResume(fetchedAt + 16min)` reloads, and `+10min` doesn't;
  - `fetch failure is failed`.
  - `leave drops pending guess`: start a guess, call `leave()`, then resolve the guess with success and, in a second case, with `NetworkFailure`. The state is unchanged by either.
  - `stale image callback`: `imagesLoaded(oldLoadId)` after a reload doesn't set `imagesReady`.
- [ ] **Step 2: Run** `flutter test test/unit/home_pair_controller_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** to the interface. `fetchedAt` comes from an injectable clock.
- [ ] **Step 4: Run.** Expected: PASS. Commit `feat(2.1): home pair controller`.

### Task 10: Remember Classic settings

**Files:**
- Create: `lib/core/storage/classic_settings_store.dart`
- Modify: `lib/features/lobby/create_game_screen.dart` (initial values around lines 42-43 and 95-101; save in `_createGame` for Classic)
- Test: `test/unit/classic_settings_store_test.dart`

**Interfaces:**
- Produces: `ClassicSettingsStore.load() -> Future<({int rounds, int timePerRound})>`, which defaults to `(rounds: 6, timePerRound: 5)`, and `ClassicSettingsStore.save(int rounds, int timePerRound) -> Future<void>`. SharedPreferences keys are `classic_rounds` and `classic_time_per_round`.

Covers: R7

- [ ] **Step 1: Write the failing tests** using `SharedPreferences.setMockInitialValues({})`:
  - `defaults` gives 6 and 5;
  - `save then load` returns 10 and 8;
  - a create screen widget test checks that Classic starts with the saved values when there are no route extras, and that route extras still win.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.** Save only for `GameMode.classic`, after a successful create.
- [ ] **Step 4: Run.** Expected: PASS. Commit `feat(2.1): remember classic settings`.

### Task 11: Home screen layout and menu

**Files:**
- Create: `lib/features/home/widgets/home_pair_view.dart`, `lib/features/home/widgets/mode_row.dart`
- Modify:
  - `lib/features/home/home_screen.dart`: replace the mode-card column (around lines 95-160); move profile, How to Play and the version line into a menu; remove the automatic `showHowToPlayOnFirstLaunch` call in `initState` (around line 37), because the pair now is the first-launch instruction and the spec wants a guess without reading anything first.
  - `lib/widgets/logo.dart`: wordmark colours per D7.
  - `lib/widgets/how_to_play_dialog.dart`: keep `showHowToPlayDialog`; leave `showHowToPlayOnFirstLaunch` unused, or delete it with its test.
  - `test/widget/how_to_play_first_launch_test.dart`: update it to assert the dialog does not open on first launch.
- Test: `test/widget/home_screen_test.dart` (update)

**Interfaces:**
- Consumes: `homePairProvider` (Task 9).
- Produces:
  - `HomePairView`: the pair, result line, and hint or "▶ Next pair". It takes `onNextPair: VoidCallback` and `nextPending: bool`. Until Task 12 lands, `HomeScreen` passes `onNextPair: () {}` and `nextPending: false`, so this task builds and tests on its own.
  - `ModeRow`: Party, Classic and Marathon cards with the existing `onTap` actions, then "Join a party · enter code" with the existing route.

Covers: R1, R2, R8, R11, F1

- [ ] **Step 1: Write the failing widget tests:**
  - order: wordmark, then "Which one is AI?", then the pair, then the hint "👆 Tap the image that AIn't Real", then the mode row;
  - after a revealed state: "▶ Next pair" and the result copy are shown, and the hint is gone;
  - the `failed` phase shows "Couldn't load a pair · Tap to retry", and the mode row is still tappable;
  - each mode card pushes the same route and extras as today;
  - the menu holds Profile/Sign in, How to Play and Settings, and the version line only in test mode;
  - five taps on the subtitle still toggle test mode;
  - `first launch shows no dialog`: with empty SharedPreferences, no How to Play dialog appears and the pair is visible; the menu's How to Play still opens it;
  - at the R11 sizes (`tester.view.physicalSize`), there's no overflow, the pair and mode row are within the viewport, and each image is at least 150 px wide.
- [ ] **Step 2: Run** `flutter test test/widget/home_screen_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement.** Images use `cached_network_image` with load/error callbacks, wired to `imagesLoaded` and `imageFailed`. Call `load()` on first build and when the route becomes visible again (a `RouteAware` / GoRouter listener), and `leave()` when it stops being visible. Call `onResume` from `AppLifecycleState.resumed`. Pass the pair's `loadId` into the image callbacks.
- [ ] **Step 4: Run** `flutter test`. Expected: PASS.
- [ ] **Step 5: Commit** `feat(2.1): guess-on-open home layout`.

### Task 12: Next pair starts the game; analytics

**Files:**
- Modify: `lib/features/home/home_screen.dart` (the `onNextPair` handler), `lib/core/analytics/analytics_service.dart`, `lib/core/storage/classic_settings_store.dart` (used, not changed)
- Test: `test/widget/home_screen_test.dart`, `test/unit/home_next_pair_test.dart`

**Interfaces:**
- Consumes: `GameApi.createGame(firstRoundToken:)` (Task 8), `ClassicSettingsStore.load()` (Task 10), `homePairProvider`.
- Produces:
  - `AnalyticsService.logHomePairShown()`
  - `logHomeGuess({required bool correct})`
  - `logHomeGameStarted({required bool carried})`
  - Next pair builds `GameConfig(mode: classic, rounds, timePerRound from the store, speedBonus/randomBonuses: the create screen defaults)` and calls `createGame` with the session player name (the same source as `create_game_screen.dart` around lines 115-118), the id token if signed in, and `firstRoundToken: state.result.resultToken`. It records `loadId` before the call. On success it saves the settings with `ClassicSettingsStore.save` (R7), and then navigates only if `isCurrent(loadId)` and the widget is mounted: `context.go('/lobby/<code>', extra: {... 'isSoloMode': true})`, so the existing lobby auto-start runs. On failure it shows the SnackBar only if `isCurrent(loadId)`. A game created after the player left home is abandoned in its lobby state, never started, so it records nothing.

Covers: R5, R6, R9, R10, F3, F4

- [ ] **Step 1: Write the failing tests:**
  - `next pair creates with token`: the fake `GameApi` receives `firstRoundToken` and saved settings, and navigation goes to `/lobby/ABCD` with `isSoloMode: true`;
  - `double tap creates one game`: two taps make one `createGame` call, with the button showing a spinner while pending;
  - `create failure stays home`: `ApiException('Please update…')` shows a SnackBar, the reveal stays, and Next pair works again;
  - `ignored token still starts`: a response with `firstRound: 'ignored'` still navigates with no error shown (F3);
  - `no game without next`: leaving home after a guess makes zero `createGame` calls (R6);
  - `leave during create`: tap Next pair, navigate away before `createGame` resolves, then resolve it with success and, in a second case, with failure. There is no navigation to the lobby and no SnackBar;
  - `home create saves settings`: after a successful home create, `ClassicSettingsStore.save` was called with the values used;
  - analytics: shown fires once per load, guess fires with `correct`, and started fires with `carried: firstRound == 'applied'`.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement** to the interface.
- [ ] **Step 4: Run** `flutter test`. Expected: PASS.
- [ ] **Step 5: Device check (R9, R11).** Run `flutter run --dart-define=API_BASE=http://<LAN>:8789` on the iPad and the S24, against a local server with PRs A and C. Check that:
  - home guess, then Next pair, shows "Round 2 / 6";
  - the end results list round 1 with its answer;
  - airplane mode on home shows the retry tile;
  - backgrounding for over 15 minutes and resuming shows a new pair.
- [ ] **Step 6: Commit** `feat(2.1): next pair starts classic at round 2`.

## Coverage

| Req | Task |
|-----|------|
| R1, R2, R8, R11 | 11 |
| R3, R4, R4a | 9, 11 |
| R5, R6, R9, R10 | 12 (R9 also 6) |
| R7 | 10 |
| R12, R13 | 3, 8 |
| R14 | 6 |
| R15 | 7 |
| R16 | 2 |
| R17, R19 | 4 |
| R18 | 1, 4 |
| R20-R25 | 5 |
| R26 | Delivery table |
| F1 | 9, 11 |
| F2 | 9 |
| F3 | 6, 12 |
| F4 | 12 |
| F5, F6 | 5, 9 |
| F7 | 1, 3 |
