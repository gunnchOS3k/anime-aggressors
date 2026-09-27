# Full-roster Pixel review form

Owner-only. Automation does not fill these answers. Mode A feedback is workflow/feel. Mode B feedback is art.

Device alias: `PIXEL_REVIEW_DEVICE` (never print raw serials).

Build under review:

- [ ] Mode A — `anime-aggressors-full-roster-integration-baseline.apk` (accepted/fallback art)
- [ ] Mode B — `anime-aggressors-full-roster-human-candidates-review.apk` (7/7 HUMAN_CANDIDATE required)

`FULL_ROSTER_HUMAN_CANDIDATES_COMPLETE` is computed by the roster validator. This pass stages CC0 candidates; owner boxes stay empty.

## Per fighter

Copy this block for Ember Vale, Rook Ironside, Juno Spark, Kaia Windrow, Nix Calder, Orion Vell, Vesper Nyx.

**Fighter:** _______________
**ART SOURCE shown:** HUMAN_CANDIDATE / CURRENT_ACCEPTED_ART / PROCEDURAL_FALLBACK

1. Does the character look intentionally designed?
2. Is the silhouette distinct?
3. Does the costume/head read clearly on the Pixel?
4. Do idle/walk/run communicate personality?
5. Does charge look powerful?
6. Does the heavy attack feel weighty?
7. Does the victim visibly hurt before launch?
8. Does the super look screenshot-worthy?
9. Does clash acting show force?
10. Any clipping/detachment?
11. Any performance/readability issue?
12. Keep / revise / replace?

## Roster-level

- Does the roster look like one coherent game?
- Are any fighters visually too similar?
- Which fighter is strongest?
- Which fighter is weakest?
- Which attack feels best?
- Which attack feels worst?
- Is this full-roster art good enough to continue toward release?

These answers are owner feedback, not CI outputs. Do not set `HUMAN_ROSTER_*` true from this file alone.
