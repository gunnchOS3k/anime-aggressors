# Golden Vertical Slice

**Purpose:** One-fighter quality reference bar for the full combat loop.  
**Fighter:** Ember Vale (OK as the slice subject)  
**Not:** Final content, ship art, or Q5 approval.

This document defines what **MEETS** means for presentation and game feel on a single fighter so the rest of the roster can be scored against a concrete bar. Functional correctness alone does not MEET.

---

## Scope of the slice

Ember must demonstrate, in BattleScene (desktop Godot first; Pixel campaign separately documented):

| Beat | FUNCTION | PRESENTATION | GAME FEEL |
|------|----------|--------------|-----------|
| Idle / walk / run | Locomotion states fire | Silhouette readable; model visible (not nameplate-only) | Weight + heat lean readable |
| Jump / aerial | Air state valid | Body readable mid-air | Anticipation / hang not floaty mush |
| Jab / tilt / heavy | Hitboxes resolve | Attack poses distinct from idle | Hit confirm readable |
| Aura charge | Charge levels scale | Aura VFX secondary to silhouette | Build anticipation |
| Projectile special | Spawns, hits, expires | **Not** naked ColorRect/BoxMesh as primary art | Lane-colored ember projectile fantasy |
| Grab / throw | Loop completes | Throw arcs readable | Impact + release timing |
| Dodge / recovery | I-frames / recovery correct | Motion distinct | Snappy, not mushy |
| Hurt / KO | States enter | Hurt pose / KO readable | Feedback not silent |

---

## MEETS bar (honest)

A system **MEETS** only if:

1. Three-reference rule satisfied (`GAME_TASTE_GATE.md`).  
2. No T0 open for that system.  
3. Presentation is intentional proxy or better — not unapproved placeholder as the player-facing primary.  
4. Human has not rejected the beat in `OWNER_TASTE_REVIEW.md`.

**Current truth:** most Ember systems are **BELOW** presentation/feel bar (rect projectiles, procedural rough models, overall polish gap). Gap matrix: `content/quality/GOLDEN_SLICE_GAP_MATRIX.json`.

---

## EXCEEDS / HUMAN_REVIEW_REQUIRED

- **EXCEEDS:** Rare; requires clear craft above the slice bar with evidence.  
- **HUMAN_REVIEW_REQUIRED:** Automated tooling thinks MEETS-ish but must not claim Q3+ without Edmund.

---

## Campaign requirements

### Desktop / BattleScene (automatable)

- Model loaded + procedural proxy visible for Ember in BattleScene.  
- `NAMEPLATE_VISIBLE_AND_MODEL_MISSING` must be **false**.  
- Harness: `game-godot/tests/quality/TasteGateModelVisibility.gd`  
- Static/CI helper: `tools/quality/check_model_visibility_reliability.py`

### Pixel 6a (physical — do not invent evidence)

- Owner/device campaign must capture: nameplate + model co-visibility, projectile readability, Golden Slice beats on device.  
- Until captured and linked here, Pixel rows remain `HUMAN_REVIEW_REQUIRED` / unvalidated — **never fabricate**.

---

## Out of scope

- Replacing the full roster art in this gate PR.  
- Claiming HUMAN_Q5 or OWNER_TASTE_REVIEW=PASS.  
- Inflating gap matrix to MEETS without screenshots / harness truth.
