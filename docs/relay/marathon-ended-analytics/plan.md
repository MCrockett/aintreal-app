# Plan: log marathon_ended analytics (1.0.2)

Requested by the UpstreamPartners kpi-goals feature (metric `marathon_round1_end_share`
= share of marathons with rounds_completed == 0).

## Task
- `GameStateNotifier` handles `MarathonEndedMessage` by calling
  `AnalyticsService.logMarathonEnded(roundsCompleted: streak, score: streak * 100)`.
  `streak` is rounds survived (server `endMarathon`): 0 = first answer wrong or timed out,
  26 = perfect run. Score matches the FinalRanking the results screen shows.
- Once per marathon: skip when state is already `finished` (a repeated message).
  `connect()` resets status to lobby for the next marathon.
- Logger injectable through an optional constructor parameter for tests; default is the
  AnalyticsService singleton. No other call sites change.

## Tests
- `test/unit/marathon_ended_analytics_test.dart`: 0 on round-1 miss, 26 on a perfect run,
  one event when the message arrives twice.
- Gates: `flutter test` (264 pass), `flutter analyze` on changed files clean. Repo has no CI.

Out of scope: registering rounds_completed as a GA4 custom dimension (owner, later).
