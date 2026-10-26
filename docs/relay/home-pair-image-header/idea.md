# home-pair-image-header

Home pair images are refused (403) on device: send the X-Mobile-App header like game images; ship as 1.1.1+17

## Added by the owner, 2026-10-26 (before 1.1.1 ships)

1. Party, Classic and Marathon look the same. The red Party card read as selected.
2. Sign-in on the home screen, using the empty space around the pair. Owner picked layout C
   from the drafts (https://claude.ai/artifact/2tyrhdNqL9TNBCHn6bVo5H), "with a bit more space
   between elements":
   - Guests: a card at the bottom, "Save your stats and streaks", "You're playing as <name>",
     Google and (iOS only, as on the sign-in screen) Apple buttons. Same auth calls as the
     sign-in screen. A failure says so and allows a retry.
   - Signed in: a strip with name, games, accuracy (party + classic) and best Marathon from
     the existing profile endpoint; tapping it opens Profile. No server change.
   - Join a party becomes a text link.
   - Screens under 720 px tall get a one-row card and a smaller pair; nothing overflows down
     to 600 px.
3. Reveal colors (owner): "Correct is green, wrong is gray." Only the picked image gets a border,
   green when right and gray when wrong; result line green or gray; AI / REAL labels are the
   game screen's gray pills. No red on the home reveal.
