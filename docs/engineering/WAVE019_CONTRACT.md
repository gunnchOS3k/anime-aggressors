# WAVE019 Engineering Contract — Roster Identity + Combat Presentation Convergence

**Wave:** WAVE019  
**Branch:** `eng/wave019-roster-identity-convergence`  
**Accepted-main prerequisite:** PR #89 MERGED (Wave018 visibility hardening + roster uplift + telemetry)  
**Merge authority:** Edmund only — Cursor never merges  
**Do not start:** Wave020  
**Do not claim:** Q3 / final art / final animation from automation  

---

## 1. OWNER OUTCOME

Edmund can select **any** of the seven fighters and immediately tell:

1. who the fighter is;
2. what physical / power fantasy they represent;
3. which attacks belong to that fighter;
4. what their projectile / power language is;
5. that their animation is visibly distinct from the rest of the roster;
6. that they are more than recolored versions of the same procedural mannequin.

Target direction (human-facing, not automation-assigned Q3+):

```text
ROSTER_HUMAN_VISIBLE_DIRECTION = STRONGLY_DISTINCT_NONFINAL_CANDIDATES
```

Wave019 does **not** mean final art. Human approval remains `PENDING`.

Quality ladder goals:

- no fighter remains a Q1 visual proxy;
- move every fighter toward Q2+;
- automation may report only `AUTOMATED_Q3_READINESS` where evidence supports it;
- automation must never assign human Q3 / Q4 / Q5.

Preserve Wave018 accepted identity directions unless a clearly better original direction replaces them:

| Fighter | Preserve |
|---------|----------|
| Ember Vale | angular ember crest + asymmetric flame gauntlets |
| Rook Ironside | broad pauldrons + helmet brow + heavy boots |
| Juno Spark | compact frame + bolt tufts + volt scarf |
| Kaia Windrow | wing sleeves + gale sash |
| Nix Calder | frost mantle + shoulder crystals |
| Orion Vell | gravity rings + orbit nodes |
| Vesper Nyx | void hood + asymmetric cape |

Do **not** copy Ember’s visual design onto the other six.

---

## 2. CANONICAL PLAYER PATHS

These are the player-visible paths Wave019 must improve and prove:

### Path A — Character Select Identity

1. Enter fighter select.
2. Cycle all seven fighters repeatedly (including confirm/back and random reselection).
3. Observe: readable name, power/role descriptor, fighter-specific accent, reliable preview model, no debug labels, no Wave018 ghost regression.

### Path B — Select → Battle Continuity

1. Select fighter → launch battle.
2. Confirm selected fighter body is visible and correct (not wrong roster model, not ghost).
3. Repeat for all seven.

### Path C — Combat Identity (Motion + Power)

1. In battle / training, exercise at least: idle, run, jump/fall, jab/neutral, forward tilt, dash attack, one aerial, neutral/side/down special, aura charge, one signature, grab, one throw, recovery, hurt/launch, KO, victory.
2. Confirm anticipation, pose shape, tempo, center of gravity, arcs, secondary motion, and VFX sync read as fighter-specific.
3. Confirm projectile / power objects differ in silhouette, motion, trail/material, impact, charge tiers (where applicable), and miss/despawn — not color-only recolors of the same mesh/capsule/rectangle.

### Path D — Versus + Victory

1. Versus intro shows fighter-specific pose/accent.
2. Victory/result shows fighter-specific pose/identity when a dedicated clip exists (no shared generic pose preference over a fighter-specific clip).

### Path E — Move List / Command Guide / Move Preview (20A)

1. Open MOVE LIST / COMMAND GUIDE from pause (battle), training, and character-select details where practical.
2. Browse categories generated from **canonical gameplay data** (no hand-written drift list).
3. See display names (not internal IDs), input glyphs (touch/gamepad/keyboard), SIMPLE / ADVANCED views.
4. Highlight a move → preview uses actual fighter model + actual mapped animation + actual VFX family; auto-loop + replay at minimum.
5. Beginner summary + CORE MOVES present; lab signatures never shown as ordinary playable.
6. From training: move-list access + pinned input reminder architecture (success detection only if real).

### Path F — Pixel 6a Physical Review

1. Install exact candidate APK.
2. Cycle all seven; battle each; captures A–E (state-verified; ≥28).
3. Move-list open/close ≥50; browse 7; preview ≥10/fighter or categories.
4. ≥10-minute mixed-roster smoke.
5. Ghosts / invariant violations / process deaths / fatal / ANR / OOM = 0 for Wave019 campaign.

If Pixel unavailable/unauthorized: `WAVE019=BLOCKED_PIXEL6A`, `READY_FOR_OWNER_MERGE=false`. Desktop must not substitute.

---

## 3. FAILURE CONDITIONS

Wave019 **FAILS** (or cannot claim merge-ready) if any of the following hold:

1. PR #89 not on accepted main / Wave018 visibility regressions removed or broken.
2. Any fighter remains a Q1 visual proxy with no material identity uplift.
3. Body proportions are effectively the same mannequin ×7 (color/hat swaps only).
4. Motion language is file-different but visually interchangeable across fighters.
5. Primary projectile / power presentation is recolored shared mesh, shared capsule/sphere, or rectangle/cube debug.
6. Select preview present but battle uses wrong / missing / ghost body.
7. Player-facing debug / proxy labels visible in player build.
8. Move list drifts from canonical gameplay data (false playable, missing playable, input mismatch, animation mismatch).
9. Lab-only signatures presented as normal-match playable.
10. Move preview uses fake clips / wrong fighter / generic jab fallback when dedicated mapping exists.
11. Pixel campaign unavailable and merge-ready claimed anyway; or Pixel ghosts/crashes/ANR/OOM/deaths > 0.
12. Forbidden proofs used as sole evidence for PASS.
13. Any claim of final art / final animation / human Q3+ / shipping / store / console cert.
14. Cursor merges the PR.

---

## 4. FORBIDDEN PROOFS

Do **not** use any of the following as **sole** proof of Wave019 success:

| Shortcut | Why forbidden |
|----------|----------------|
| “GLB exists” | Existence ≠ readable character identity |
| “material names differ” | Names ≠ visible distinct materials |
| “animation files differ” | Files ≠ visible motion personality |
| “projectile resources differ” | Resources ≠ visible power language |
| “model node exists” | Node ≠ fighter visible / correct body |
| Desktop screenshot alone | Not Pixel presentation proof |
| Seven `true` rows in JSON | Not human quality approval |
| taste-gate CI green alone | Not Edmund taste pass |
| Shared geometry with palette swap | Not distinct proportions/silhouette |
| Unlabeled silhouette sheet graded by Cursor | Blind test is owner-only |

Allowed evidence must include player-visible paths, adversarial checks, Pixel physical proof (when authorized), and honest claim boundaries.

---

## 5. PRE-MORTEM

≥10 false-PASS modes and the adversarial proof that must catch each:

| # | False-PASS mode | Adversarial proof path |
|---|-----------------|------------------------|
| 1 | Models technically distinct but visually similar | Labeled + unlabeled silhouette sheets at same scale; owner blind ID; `shared_geometry_ratio` + proportion fingerprints must not collapse to one body |
| 2 | Silhouette difference only visible up close | Capture full-body Pixel/desktop sheets at gameplay camera distance; reject “macro-only” diffs |
| 3 | Animation files differ but motions look the same | Side-by-side motion contact sheet for idle/run/jab/specials; tempo/pose-shape checklist in `FIGHTER_MOTION_IDENTITY_RESULT.json` |
| 4 | Projectiles differ by color only | Power identity matrix requires silhouette + trail + impact + despawn diffs; fail if mesh family identical across ≥3 fighters |
| 5 | Select preview loads but battle uses wrong model | Select→battle continuity test per fighter; compare `fighter_id` telemetry + visible mesh identity |
| 6 | VFX obscure fighters | Capture signature/power states; fail if body mesh count drops to 0 or silhouette unreadable under VFX |
| 7 | Uplift exists only in screenshots, not gameplay | Prefer live select/battle paths + Pixel campaign over static art renders |
| 8 | One fighter (Ember) gets most of the improvement | Per-fighter quality ladder + distinctness counts; fail if <7 fighters show material identity evidence |
| 9 | Pixel camera makes details unreadable | Pixel A–E captures at real gameplay scale; readability notes required |
| 10 | Ghost-model regression returns | Preserve Wave018 visibility telemetry + stress; require ghost/invariant = 0 |
| 11 | Move list hand-written and drifts | Accuracy harness vs canonical move/input/animation tables; require false/missing/input/anim mismatches = 0 |
| 12 | Lab signatures listed as playable | Signature binding audit: only 21 input-bound signatures as playable; lab labeled or omitted |
| 13 | Preview uses generic fallback animation | Preview authenticity: preview clip == gameplay clip for mapped moves |
| 14 | Desktop green claimed as Pixel ready | If Pixel missing → `BLOCKED_PIXEL6A`; never substitute |

---

## 6. ADVERSARIAL TESTS

Minimum adversarial suite Wave019 must run or encode:

1. **Silhouette blind sheet** — shuffled unlabeled seven; Cursor does not grade.
2. **Rapid select stress** — full roster sweeps + confirm/back + random; ghosts = 0.
3. **Select→battle wrong-model probe** — each fighter battles; body matches selection.
4. **Same-body proportion probe** — body proportion fingerprints must differ across roster.
5. **Color-only projectile probe** — primary power visuals must differ beyond albedo.
6. **Motion interchangeability probe** — required move set contact evidence per fighter.
7. **Signature matrix** — 7×3 from currently input-bound signatures only (not inflate with 35 lab).
8. **Move-list drift** — false playable / missing / input / animation mismatch counters.
9. **Preview authenticity** — model/clip/VFX family match gameplay.
10. **Move-list open/close stress** — ≥50 cycles; no battle corruption; no ghost; no crash.
11. **Debug label scan** — player build visible debug/proxy labels = 0.
12. **Wave018 regression intact** — visibility telemetry + wave018 tests still active and green.
13. **Pixel mixed-roster smoke** — ≥10 minutes when device authorized.
14. **Claim boundary lint** — final-art / human-Q3 / shipping flags remain false.

---

## 7. TARGET HARDWARE GATE

**Device:** Pixel 6a (authorized physical device only).

Requirements when available:

- Exact candidate APK (provenance: source SHA + APK SHA256).
- AA-only package guards after BACK (never drive launcher/other apps).
- Cycle all 7; battle each; captures A–E (≥28 state-verified).
- Ghosts / visibility invariant violations / fallback-policy honesty / process deaths / fatal / ANR / OOM tracked.
- ≥10-minute mixed-roster smoke.
- Move-list Pixel QA (open/close ≥50, browse 7, preview ≥10/fighter or categories).
- Performance tradeoffs reported honestly (frame-time, memory, thermal, particle/projectile/mesh high-water) — do not blandify roster solely for arbitrary metrics.

If unavailable:

```text
WAVE019 = BLOCKED_PIXEL6A
READY_FOR_OWNER_MERGE = false
```

Desktop evidence may support development but **cannot** clear the hardware gate.

---

## 8. HUMAN TASTE GATE

Automation may prepare evidence and `AUTOMATED_Q3_READINESS`.

Edmund rates (blank until owner fills):

Per fighter: READABILITY, IDENTITY, MOTION_PERSONALITY, POWER_IDENTITY, EXCITEMENT, POLISH (/5 each).  
Roster: CAST_COHESION, CAST_DISTINCTIVENESS (/5 each).

Owner questions live in `docs/quality/WAVE019_OWNER_ROSTER_TASTE_REVIEW.md`.

Move-list taste (`OWNER_MOVE_LIST_APPROVAL`) remains `PENDING` until Edmund reviews.

Cursor must leave human ratings blank and must not self-approve taste.

---

## 9. CLAIM BOUNDARY

**Must remain false:**

- `FINAL_CHARACTER_ART_PASS`
- `FINAL_HUMAN_AUTHORED_ANIMATION_PASS`
- `HUMAN_ART_DIRECTION_APPROVAL`
- `HUMAN_PLAYTEST_COMPLETE`
- `HUMAN_Q3_ROSTER_APPROVAL`
- `SHIPPING_PRODUCT`
- `STORE_APPROVED`
- `CONSOLE_CERTIFIED`

**May report:**

- `AUTOMATED_Q3_READINESS` per fighter (evidence-backed only)
- `OWNER_REVIEW_PENDING` / `OWNER_TASTE_REVIEW=PENDING`
- `OWNER_MOVE_LIST_APPROVAL=PENDING`
- `ROSTER_HUMAN_VISIBLE_DIRECTION=STRONGLY_DISTINCT_NONFINAL_CANDIDATES` as **target direction**, not human approval

**Merge authority:** Edmund. `CURSOR_MERGED_NOTHING=true` always for this wave.

`READY_FOR_OWNER_MERGE=true` only if section-25 + move-list merge gates are honestly met (owner taste approval is **not** required for engineering merge-ready).

---

## 10. OWNER-REGRESSION MEMORY

Wave019 must create/update `docs/quality/OWNER_REGRESSION_MEMORY.md` and keep these active:

| ID | Regression |
|----|------------|
| OWNER-REG-001 | Nameplate/HUD visible while fighter body absent |
| OWNER-REG-002 | Rapid character cycling causes preview models to disappear |
| OWNER-REG-003 | Battle begins with invisible selected fighter after select cycling |
| OWNER-REG-004 | Gameplay move exists but generic animation appears |
| OWNER-REG-005 | Projectile looks like a moving rectangle/capsule placeholder |
| OWNER-REG-006 | Development/proxy labels visible in player build |
| OWNER-REG-007 | Character models are too similar / procedural-mannequin-like |

Every future player-facing wave must reference this memory. Wave019 adversarial tests must explicitly cover 001–007.

---

## Implementation order (binding)

1. This contract exists (`docs/engineering/WAVE019_CONTRACT.md`) — **done before production code**.
2. Identity/quality docs + owner regression memory + taste packet.
3. Model / motion / power / select / versus / victory convergence.
4. Move List / Command Guide / Move Preview (20A) from canonical data.
5. Artifacts + desktop visual QA sheets.
6. Pixel campaign (if authorized) + move-list Pixel QA.
7. CI: preserve wave011–018; add wave019; final-head SUCCESS for required workflows.
8. One draft PR only — STOP for Edmund.

---

*Contract written before production implementation per Wave019 critical order.*
