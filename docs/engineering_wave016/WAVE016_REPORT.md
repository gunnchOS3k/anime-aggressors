# Wave016 Final Report

```
token = ENGINEERING_WAVE_016_MOVE_ANIMATION_APPLICATION
WAVE016_MOVE_ANIMATION_APPLICATION = PASS
ACCEPTED_MAIN_SHA = b8da943b46e1460723603ea2216f646146180aa3
HEAD = abbe75c962c79882b092f1349c391c8dbde184c2
PR = https://github.com/gunnchOS3k/anime-aggressors/pull/87
CI = wave016=success;taste-gate=success
PROCEDURAL_CLIPS_GENERATED = 357
NORMAL_PLAYER_INPUT_REACHABLE_CLIPS = 287
GAMEPLAY_STATE_REACHABLE_CLIPS = 287
LAB_ONLY_CLIPS = 42
DESIGN_ONLY_CLIPS = 28
GAMEPLAY_MOVES_TOTAL = 168
GAMEPLAY_MOVES_WITH_DEDICATED_CLIP = 161
GAMEPLAY_MOVES_EXACTLY_MAPPED = 42
GAMEPLAY_MOVES_ALIASED = 119
GENERIC_FALLBACK_GAMEPLAY_MOVES = 0
UNMAPPED_GAMEPLAY_MOVES = 0
SIGNATURES_DESIGNED = 56
SIGNATURES_WITH_PROCEDURAL_CLIP = 56
SIGNATURES_GAMEPLAY_IMPLEMENTED = 21
SIGNATURES_BOUND_TO_INPUT = 21
SIGNATURES_NORMAL_MATCH_VISIBLE = 21
SIGNATURES_LAB_ONLY = 35
SIGNATURES_DESIGN_ONLY = 0
EMBER_MOVE_SET_TESTED = 23
EMBER_GENERIC_FALLBACKS = 0
EMBER_PLAYER_FACING_PLACEHOLDERS = 0
EMBER_MODEL_VISIBILITY_FAILURES = 0
EMBER_PROJECTILE_TAP_QUALITY = Q2_PROCEDURAL_INTENTIONAL
EMBER_PROJECTILE_MEDIUM_QUALITY = Q2_PROCEDURAL_INTENTIONAL
EMBER_PROJECTILE_FULL_QUALITY = Q2_PROCEDURAL_INTENTIONAL
INSPIRED_CHOREOGRAPHY_RUNTIME_ALIGNMENT = True
GOLDEN_SLICE_MOVE_APPLICATION_E2E = True
NO_GENERIC_ATTACK_FALLBACKS_IN_GOLDEN_SLICE = True
PIXEL_GOLDEN_SLICE_CAPTURE = CAPTURED
CURRENT_QUALITY_LEVEL = Q2
GOLDEN_SLICE_AUTOMATED_Q3_READINESS = False
OWNER_TASTE_REVIEW = PENDING
FINAL_HUMAN_AUTHORED_ANIMATION_PASS = False
HUMAN_ART_DIRECTION_APPROVAL = False
HUMAN_PLAYTEST_COMPLETE = False
WAVE011_REGRESSION = SKIPPED_CI_LIGHT
WAVE012_REGRESSION = SKIPPED_CI_LIGHT
WAVE013B_REGRESSION = SKIPPED_CI_LIGHT
WAVE014_REGRESSION = SKIPPED_CI_LIGHT
WAVE015_REGRESSION = SKIPPED_CI_LIGHT
TASTE_GATE = PENDING_OWNER
NEW_S0 = 0
NEW_S1 = 0
READY_FOR_OWNER_MERGE = True
CURSOR_MERGED_NOTHING = True
animation_class = PROCEDURAL_RUNTIME_ANIMATION
PHYSICAL_SMOKE = PIXEL_CONTACT_SHEET_CAPTURED
```

## Explain

1. **Before Wave016:** Wave014 generated 357 procedural clips and choreography specs, but RuntimeMoveResolver collapsed many attacks to jab_1/special/throw_forward; tilts used mismatched names (`forward_tilt` vs `tilt_forward`).
2. **Why not visible:** Attack states without mapped move_id fell back to generic jab; DESIGN_ONLY flags treated loaded tilt/aerial clips as unplayable; projectiles used ColorRect DebugRect as primary art.
3. **Naming mismatches:** forward_tilt→tilt_forward, up/down tilt, aerial_* vs *_air, jab_1→jab, jab_2→jab_chain_2, jab_finisher→jab_chain_3, heavy_attack→heavy, aura_burst→signature_lane_burst, special→projectile tiers.
4. **Now player-visible:** Ember normal set (jab chain, tilts, dash share, aerials including back air, specials, throws, dodge/air dodge, recovery, aura, signature via aura burst) maps to exact/aliased clips.
5. **Signature truth:** 56 designed+animated; 21 bound via aura_burst/side/down special (3 lanes × 7); remainder lab/training — not jammed onto awkward buttons.
6. **Golden Slice:** Ember-focused mapping + intentional projectile family + model visibility ensure; Q3 readiness false; OWNER_TASTE_REVIEW=PENDING.
7. **Remaining:** smash_* DESIGN_ONLY; heavy_attack unbound; final authored animation; human Q5; roster-wide Golden Slice propagation blocked until Edmund reviews Ember.
8. **Owner action:** Review draft PR #87; confirm Pixel contact sheet; merge authority Edmund only — Cursor merges nothing.
