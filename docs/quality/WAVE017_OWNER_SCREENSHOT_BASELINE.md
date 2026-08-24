# WAVE017 — Owner Screenshot Baseline (Pixel play)

**Status:** Owner-observed weaknesses locked as taste debt baseline.  
**Do not erase these because automated detectors PASS.**  
**Owner:** Edmund (sole merge / Q3–Q5 authority)  
**Automation must leave human approval fields false / PENDING.**

---

## Baseline flags (Wave017 start)

| Field | Value |
|-------|-------|
| `OWNER_TASTE_REVIEW` (baseline before delivery) | `CHANGES_REQUESTED` |
| `HUMAN_VISIBLE_QUALITY_BEFORE` | `Q1_FUNCTIONAL_PROTOTYPE` |
| `HUMAN_Q2_APPROVAL` | `false` |
| `HUMAN_Q3_APPROVAL` | `false` |
| `HUMAN_ART_DIRECTION_APPROVAL` | `false` |
| Post-delivery `OWNER_TASTE_REVIEW` | `PENDING` (await Edmund re-review) |

---

## Owner-observed weaknesses (Pixel campaign)

These were observed or inferred from owner Pixel play of the pre-Wave017 build. Automated PASS does **not** close them without owner sign-off.

1. **Ghost / missing fighter body** — nameplate or empty space where a fighter should be (TASTE-T0-MODEL-VISIBILITY-001).
2. **PROCEDURAL PRODUCTION PROXY / PROXY / DEBUG labels** visible in player builds.
3. **Ember reads as blockout cubes**, not a character with head/face/hair/clothing/fire motifs.
4. **Static camera** — empty sky, weak framing, no separation zoom.
5. **Full display names overlapping bodies** — unreadable mid-combat.
6. **Projectiles still under-crafted** vs fantasy (need distinct tap/medium/full).
7. **Ember Courtyard** feels flat / greybox despite procedural geometry.
8. **Combat juice** uneven (hitstop/shake/flash/particles).
9. **HUD / touch** functional but not taste-directed.
10. **Versus / victory** thin; developer-adjacent presentation risk.
11. **Animation readability** for Ember moves needs anticipation/weight (Wave016 mappings preserved).

---

## Required AFTER capture cases (Pixel)

Capture contact-sheet slots for:

1. Ember idle readable silhouette  
2. Ember vs opponent both bodies visible  
3. Close-up Ember face/hair/torso  
4. No proxy/debug labels in frame  
5. Camera framing mid-stage  
6. Camera zoomed out on separation  
7. Projectile tap  
8. Projectile medium  
9. Projectile full + impact  
10. Ember Courtyard depth layers  
11. HUD stocks/damage/aura clean  
12. Touch controls iconographic  
13. Versus entry  
14. Victory / results  
15. Light hit juice  
16. Heavy / launch juice  
17. KO → respawn both visible  
18. Arcade ladder transition bodies present  
19. Pause/resume bodies present  
20. After bg/fg or restart bodies present  

---

## Honesty rules

- Cursor must not declare Q3 / HUMAN_Q3.  
- Leave owner ratings `OWNER_PENDING`.  
- If model disappears during owner-style play: `WAVE017=FAIL`.  
- Pixel evidence must be authentic or marked `BLOCKED_PIXEL6A` / not invented.
