# Guess on open (1.1 home redesign)

**Problem.** Organic installs from Google and the Play Store are rising, but newcomers land on a menu of mode cards. Many play one game or none (2026-10-15 deep dive: 6 of 11 recent sign-ins played zero games). The Reddit splash already works the way we want: a pair on screen, "Which one is AI?", one tap.

**Who it is for.** New players arriving on the app home or on aint-real.com from search or a store listing.

**What we build.** On every surface the first thing you see is a pair you can guess with one tap. The hint reads "👆 Tap the image that AIn't Real", and Next pair appears only after a guess.
- **App.** The home pair comes from the demo pool. Guessing and then tapping Next pair starts a Classic game (last settings, or defaults) with round 1 filled in from that guess (no time score). Play continues at round 2, with rounds 2+ from the full pool. Opening the app and leaving creates nothing.
- **Web.** The game replaces the hero screenshots in the two-column hero, with the store badges on the left; on narrow views the game moves to the top. It has no score, rotates through demo pairs, and reminds about the app every 3 pairs.
- **Server.** Additive endpoints: a home pair without the answer, a server-checked guess, create-with-first-round, and neutral image URLs.

**Success.** A newcomer makes a guess within seconds of opening the app or the site without choosing anything. On the web, that first guess leads to the store badges.

Full design, written with the owner and builder-checked: `docs/superpowers/specs/2026-10-24-guess-on-open-design.md` (on this branch), with a clickable sketch next to it.
