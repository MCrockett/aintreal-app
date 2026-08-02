# TRIAGE.md

Collection point for bugs, ideas, and issues for the AIn't Real mobile app.

## New

*Items added here will be reviewed during triage sessions.*

- [BUG] Party invite flow is self-defeating: host backgrounding the app to text the invite link triggers the forced WS teardown → instant `host_left` → session killed, so the link just sent is already dead. Playtest-confirmed (2026-08-01), consistently reproducible. Only workaround is reading the 4-char code aloud in the same room, which defeats remote invites. Root causes are known (tab-out teardown `ws_client.dart` ~:214 + no host-disconnect grace); fixes are tasks 5 + #18 grace window in CHANNEL2-FASTFOLLOW-PLAN.md — this finding raises their priority since it blocks the core share/viral loop. (Added: 2026-08-01, Priority: High)

---

## Active Issues

*Items being actively investigated.*

---

## Backlog

*Items deferred for later consideration.*

- Consider haptic feedback patterns for different events
- Evaluate animation performance on older devices

---

## Resolved

*Items that have been addressed.*

- Fixed reveal message parsing for round_reveal
- Fixed Play Again flow resetting properly
- iOS build configuration — submitted to App Store successfully (+9, +10, +11)
