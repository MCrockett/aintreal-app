# Party Mode Test Plan — v8

Manual test plan for party mode on Android. Use two physical devices (or one device + web browser at play.aint-real.com).

**Devices needed:** 2 Android phones (or 1 Android + 1 web browser)
**Build:** v1.0.0+8 release AAB

---

## 1. Game Creation & Lobby

### 1.1 Create party game (host)
- [x] Open app → "Host Party" → set name, config (6 rounds, 5s)
- [x] Verify 4-character game code appears
- [x] Verify player list shows host with star icon
- [x] Verify "Waiting for players..." shown (can't start with 1 player)
- [x] Verify connection indicator is hidden (connected state)

### 1.2 Join party game (guest)
- [ ] On second device, "Join Game" → enter code + name
- [ ] Verify guest appears in both lobby player lists
- [ ] Verify host's player count badge updates (2/8)
- [ ] Verify host's "Start Game" button enables

### 1.3 Share/invite flows
- [ ] Copy code → paste elsewhere → verify correct
- [ ] Copy link → open in browser → verify redirects to join flow
- [ ] Share button → verify share sheet opens with correct URL
- [ ] QR code → scan with second device → verify opens join flow

### 1.4 Lobby edge cases
- [ ] Try starting with only 1 player (host) → should be blocked
- [ ] Guest leaves lobby → verify host's player list updates
- [ ] Guest rejoins → verify appears again in list
- [ ] Host leaves lobby → verify guest sees "Game Ended" dialog

---

## 2. Gameplay — Happy Path

### 2.1 Game start
- [ ] Host taps "Start Game"
- [ ] Both devices navigate to game screen
- [ ] "Get Ready" overlay shows with 3-2-1 countdown
- [ ] After countdown, images appear and timer starts
- [ ] Timer bar animates smoothly

### 2.2 Answering
- [ ] Tap an image → border highlights, result badge shows (Correct!/Wrong!)
- [ ] Can't tap again after answering
- [ ] Header shows answered count (e.g., "1/2" then "2/2")
- [ ] Verify both devices show correct answered count

### 2.3 Reveal screen
- [ ] Both devices navigate to reveal screen after all answer (or timeout)
- [ ] AI image animates with scale + glow
- [ ] AI/REAL labels appear on both images
- [ ] Your result card shows correct/wrong with response time
- [ ] Bonus card appears if earned (streak, speed, etc.)
- [ ] Scores leaderboard shows both players
- [ ] Auto-advance countdown shows "Next round in 5..."

### 2.4 Round progression
- [ ] After countdown, both devices advance to next round
- [ ] New "Get Ready" countdown for round 2
- [ ] Round counter updates (Round 2/6)
- [ ] Repeat through all 6 rounds

### 2.5 Results screen
- [ ] After final reveal, both devices show results
- [ ] Winner banner displays
- [ ] Final standings show all players ranked
- [ ] Photo credits section visible
- [ ] Host sees "Play Again" button
- [ ] Guest sees "Leave" button

---

## 3. Timing & Timeout

### 3.1 Timer expiry
- [ ] Don't answer on one device → timer counts to 0
- [ ] "Time Up!" sound plays
- [ ] Timeout auto-submits (treated as wrong answer)
- [ ] Reveal shows "Time's up!" for that player
- [ ] Game continues normally

### 3.2 One player answers, one times out
- [ ] Player A answers quickly, Player B lets timer expire
- [ ] Verify reveal shows correct info for both
- [ ] Verify scores are correct (0 points for timeout)

### 3.3 Both players answer quickly
- [ ] Both tap within 1 second
- [ ] Answered count updates to 2/2
- [ ] Reveal triggers immediately (doesn't wait for timer)

---

## 4. Connection Loss — Lobby

### 4.1 Brief disconnect in lobby
- [ ] In lobby, toggle airplane mode on guest for 5 seconds, then disable
- [ ] Verify "Reconnecting..." appears in header
- [ ] Verify connection restores without fatal dialog
- [ ] Verify player list still correct after reconnect

### 4.2 Extended disconnect in lobby
- [ ] Toggle airplane mode for 60+ seconds
- [ ] After reconnect attempts exhaust, verify "Connection Lost" dialog appears
- [ ] Tap OK → navigates home

---

## 5. Connection Loss — Mid-Game

### 5.1 Brief disconnect during round (new overlay)
- [ ] During active round, toggle airplane mode for 10 seconds
- [ ] Verify "Reconnecting..." overlay appears over game
- [ ] Verify timer pauses (doesn't count down during overlay)
- [ ] Re-enable wifi → overlay clears, timer resumes
- [ ] Verify game continues normally

### 5.2 Brief disconnect during Get Ready countdown
- [ ] During 3-2-1 countdown, toggle airplane mode for 5 seconds
- [ ] Verify overlay appears, countdown pauses
- [ ] Re-enable → countdown resumes from where it left off

### 5.3 Brief disconnect during reveal (new overlay)
- [ ] During reveal screen, toggle airplane mode for 10 seconds
- [ ] Verify "Reconnecting..." overlay appears
- [ ] Verify auto-advance countdown pauses
- [ ] Re-enable → overlay clears, countdown resumes

### 5.4 Permanent disconnect mid-game
- [ ] During active round, enable airplane mode and leave it on
- [ ] Verify "Reconnecting..." overlay shows initially
- [ ] After ~30 seconds, verify overlay changes to "Connection Lost"
- [ ] Verify "Return Home" button appears
- [ ] Tap "Return Home" → navigates to home screen

### 5.5 Permanent disconnect during reveal
- [ ] Same as 5.4 but triggered on reveal screen
- [ ] Verify same "Reconnecting..." → "Connection Lost" → "Return Home" flow

---

## 6. Connection Loss — Other Player

### 6.1 Guest disconnects mid-game
- [ ] Guest toggles airplane mode during round
- [ ] Host's game continues (timer still runs)
- [ ] Verify guest's answer counted as timeout if they don't reconnect
- [ ] Guest reconnects → verify they can continue playing next round

### 6.2 Host disconnects mid-game
- [ ] Host toggles airplane mode during round
- [ ] Guest's game should continue
- [ ] Verify round completes normally for both when host reconnects
- [ ] If host doesn't reconnect, verify game eventually ends or guest can leave

---

## 7. Reveal & Round Transitions

### 7.1 Auto-advance timing (party mode)
- [ ] On reveal, verify countdown shows "Next round in 5..."
- [ ] Verify it counts down 5→4→3→2→1
- [ ] At 0, both devices advance to next round
- [ ] Verify no "stuck on reveal" — both devices advance

### 7.2 Rapid round transitions
- [ ] Play 3+ rounds in a row answering as fast as possible
- [ ] Verify round counter increments correctly each time
- [ ] Verify no rounds are skipped
- [ ] Verify reveal shows correct results for each round

### 7.3 Final round → results transition
- [ ] On last round, answer and go through reveal
- [ ] Verify countdown completes and both devices navigate to results
- [ ] Verify results show correct final standings

---

## 8. Play Again Flow

### 8.1 Host initiates play again
- [ ] On results screen, host taps "Play Again"
- [ ] Both devices navigate back to lobby
- [ ] Verify player list is preserved
- [ ] Verify config is preserved
- [ ] Host can start a new game

### 8.2 Play again → full game
- [ ] After play again, play through entire second game
- [ ] Verify scores reset
- [ ] Verify round counter starts at 1
- [ ] Verify results show only current game's results

### 8.3 Guest leaves after game
- [ ] Guest taps "Leave" on results
- [ ] Verify guest returns to home screen
- [ ] Verify host's lobby shows guest removed

---

## 9. Edge Cases

### 9.1 Background/foreground during game
- [ ] During round, press home button (background app) for 5 seconds
- [ ] Return to app → verify game state is correct
- [ ] If WebSocket dropped, verify reconnection overlay appears and recovers

### 9.2 Background during reveal
- [ ] During reveal, background app for 10 seconds
- [ ] Return → verify reveal still showing or advanced correctly

### 9.3 Slow network
- [ ] Connect to slow/throttled network
- [ ] Play full party game
- [ ] Verify images load (shimmer placeholders visible while loading)
- [ ] Verify answers register even with latency
- [ ] Verify reveal transitions work despite lag

### 9.4 Different config values
- [ ] Create game with 4 rounds, 3 seconds
- [ ] Verify only 4 rounds play
- [ ] Verify timer counts from 3 (not 5)
- [ ] Create game with 10 rounds, 10 seconds
- [ ] Verify all 10 rounds play

---

## 10. Regression Checks

### 10.1 Solo classic — still works
- [ ] Play a full classic solo game (not party)
- [ ] Verify "Next" button appears (not just countdown)
- [ ] Verify results show correctly

### 10.2 Marathon — still works
- [ ] Play marathon, answer wrong intentionally
- [ ] Verify "GAME OVER" overlay shows
- [ ] Verify results show streak count

### 10.3 Ads not broken
- [ ] Verify banner ad on home screen
- [ ] Play 5+ games → verify interstitial shows after 5th
- [ ] Verify ads don't appear during gameplay

---

## Known Issues to Watch For

| Symptom | Likely Cause | Where to Look |
|---------|-------------|----------------|
| Stuck on reveal, countdown at 0 | Server didn't send next round | reveal_screen.dart _advanceToNext |
| Round skipped (e.g., 1→3) | Double endRound() race on server | GameRoom.js endRound() |
| "Connection Lost" during brief disconnect | WsClient bouncing to disconnected | ws_client.dart connect() catch |
| Player shows wrong score on reveal | Reconnect during round transition | GameRoom.js handleJoin() |
| Play Again doesn't return to lobby | ReturnToLobbyMessage never received | game_state_provider.dart |
| Timer keeps running behind overlay | _pauseTimerForReconnect not triggered | game_screen.dart listener |

---

## Pass Criteria

**v8 is ready to ship when:**
- [ ] All items in sections 1-3 pass (happy path)
- [ ] Section 5.1-5.5 pass (new connection loss overlay)
- [ ] Section 7.1-7.3 pass (no stuck reveals)
- [ ] Section 8.1-8.2 pass (play again works)
- [ ] Section 10 passes (no regressions)
- [ ] No crashes observed during any test
