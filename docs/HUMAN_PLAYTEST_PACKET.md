# Human playtest packet — Anime Aggressors

**Status:** `HUMAN_QA_PENDING`

Automated tests and Device Lab notes are not human playtests. Do not fabricate participant evidence. Do not call this product a finished vertical slice.

## Why blocked

No signed human session exists on this branch for Anime Aggressors.

## Prerequisite

A real player (not the CI agent) on desktop and, separately, on an **authorized** Pixel 6a.

## Journey to run

1. Open **Godot 4** on `game-godot/project.godot` (production). Do not use `apps/web` Three.js battle as the playtest.
2. Boot → Main Menu → Versus → fighter + stage → battle.
3. Confirm attack, special, shield, dodge, grab, jump, CPU opponent, pause/resume, results.
4. Training: dummy modes, move list, exit.
5. Touch overlay (if touchscreen) or gamepad P1.
6. Do **not** treat GitHub Pages `#/battle` as production.


## Record (no PII in public git)

Date, device, duration, crashes, unplayable steps. Store anonymized notes under `artifacts/human_qa/` privately if needed.

## Status transition

Documented playtest may drop “unsigned playtest” language. It does **not** become telecom/RQ evidence unless imported into a frozen experiment. Pixel 6a remains blocked until `docs/PIXEL_6A_ACCEPTANCE.md` is no longer unauthorized.
