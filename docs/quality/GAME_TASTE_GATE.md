# Game Taste Gate — Master Doctrine

**Status:** Active infrastructure (not a polish wave)  
**Merge authority:** Edmund only  
**Automated tooling NEVER assigns Q5 / HUMAN_Q5**

Player-facing quality is required alongside functional correctness. Every future engineering wave must leave evidence for:

```
FUNCTION → PRESENTATION → GAME FEEL → HUMAN TASTE REVIEW
```

---

## Four layers (ordered)

| Layer | Question | Gate role |
|-------|----------|-----------|
| **FUNCTION** | Does the loop work? | Necessary; insufficient alone |
| **PRESENTATION** | Can the player read silhouette, VFX, UI hierarchy? | Blocks ship if unreadable |
| **GAME FEEL** | Hit stop, anticipation, recovery, juice timing? | Measured + human-judged |
| **HUMAN TASTE REVIEW** | Would Edmund ship this slice? | Sole Q5 / merge taste authority |

No layer skips the ones above. Automated detectors may fail FUNCTION/PRESENTATION; they may estimate GAME FEEL bands; they **cannot** pass HUMAN TASTE REVIEW.

---

## Quality ladder Q0–Q5

| Level | Meaning | Who may assign |
|-------|---------|----------------|
| **Q0** | Broken / missing player-facing identity (e.g. nameplate with no model) | Automated or human |
| **Q1** | Placeholder / greybox readable as prototype only | Automated or human |
| **Q2** | Coherent proxy art; not final fantasy | Automated estimate OK |
| **Q3** | Strong direction; intentional craft visible | Human review required to claim |
| **Q4** | Near-ship polish for the slice | Owner / designated taste reviewer |
| **Q5** | Ship-approved taste | **Edmund only** — tooling must never emit Q5 |

**Truth baseline (2026-08):** overall roster player-facing quality is estimated **Q1–Q2**. Do not claim Q3/Q4/Q5 for the roster without owner review.

---

## Severity T0–T3 (taste debt)

| Severity | Meaning | Merge impact |
|----------|---------|--------------|
| **T0** | Player-facing identity failure (missing model, wrong hierarchy, unapproved placeholder in production path) | Blocks taste-gate PASS |
| **T1** | Obvious placeholder / rough proxy (rect projectiles, procedural blockouts) | Must be registered; may block Golden Slice MEETS |
| **T2** | Far from final polish; coherent but unfinished | Tracked; does not alone invent fake Q |
| **T3** | Polish / delight debt | Optional backlog |

See `docs/quality/TASTE_DEBT_REGISTER.md`.

---

## Three-reference rule

Before claiming a system MEETS Golden Slice bar, cite **three** references:

1. **Internal Golden Slice** — `docs/design/GOLDEN_VERTICAL_SLICE.md` (Ember combat loop bar)
2. **Fighter fantasy** — `docs/design/fighter_fantasy/<fighter>.md`
3. **Reference board stub** — `docs/quality/reference_boards/` (projectile/VFX/silhouette grammar)

References are direction, not franchise copies. `DIRECT_1_TO_1_REFERENCE_MOVES=0` remains in force.

---

## Visual hierarchy (non-negotiable)

1. **Fighter silhouette / model** — primary readable subject  
2. **Attack / projectile / VFX** — secondary, lane-colored, never obscures identity  
3. **UI / nameplate / meters** — tertiary; must not substitute for a missing model  

**NAMEPLATE_VISIBLE_AND_MODEL_MISSING = failure (T0).**

---

## Game-taste loop (per wave)

1. Run functional gates (existing wave harnesses).  
2. Run `make taste-gate` (placeholder detector + report emit).  
3. Update Golden Slice gap matrix honestly (`BELOW` / `MEETS` / `EXCEEDS` / `HUMAN_REVIEW_REQUIRED`).  
4. Register new taste debt; do not close debt without evidence.  
5. Leave `OWNER_TASTE_REVIEW` fields for Edmund unanswered until he fills them.  
6. **Do not merge** without Edmund.

---

## Merge-gate report fields

`tools/quality/emit_taste_gate_report.py` emits (among others):

| Field | Constraint |
|-------|------------|
| `GAME_TASTE_GATE` | `FAIL` / `PASS_WITH_DEBT` / `PENDING_OWNER` — never invent PASS without detectors + debt honesty |
| `CURRENT_QUALITY_LEVEL` | Automated estimate ≤ Q2 unless owner overrides |
| `HUMAN_TARGET_QUALITY_APPROVAL` | always `false` until Edmund sets true |
| `OWNER_TASTE_REVIEW` | `PENDING` until Edmund completes `OWNER_TASTE_REVIEW.md` |
| `HUMAN_Q5` | always `false` from automation |
| `PLAYER_FACING_UNAPPROVED_PLACEHOLDER_VISUALS` | integer from placeholder check |
| `TASTE_DEBT_T0` / `T1` / `T2` / `T3` | open counts |
| `CURSOR_MERGED_NOTHING` | `true` on Cursor-authored PRs |

---

## Related paths

- Golden Slice: `docs/design/GOLDEN_VERTICAL_SLICE.md`
- Animation rubric: `docs/quality/ANIMATION_TASTE_RUBRIC.md`
- Taste debt: `docs/quality/TASTE_DEBT_REGISTER.md`
- Owner review: `docs/quality/OWNER_TASTE_REVIEW.md`
- Gap matrix: `content/quality/GOLDEN_SLICE_GAP_MATRIX.json`
- Contact sheet: `artifacts/taste_gate/contact_sheet/`
