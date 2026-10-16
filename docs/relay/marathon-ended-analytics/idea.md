# marathon-ended-analytics

Adopted from PR #21: feat(5.2): log marathon_ended analytics once per marathon

Calls the existing but unused \`AnalyticsService.logMarathonEnded\` from the \`MarathonEndedMessage\` handler.

- \`rounds_completed\` = server streak (rounds survived; 0 = first answer wrong or timed out, 26 = perfect run); \`score\` = streak × 100, as on the results screen.
- Logged once per marathon (skipped if the state is already finished).
- Logger injectable for tests.

Feeds the UpstreamPartners KPI \`marathon_round1_end_share\`. Tests: 3 new, 264 pass.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
