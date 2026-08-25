# WAVE018 — Roster Visual Propagation + Model Visibility Hardening

**Accepted main (PR #88):** `2d2dafd16905009441e012ba2abbd2fd586a6621`  
**Merge authority:** Edmund only — Cursor never merges.  
**Do not claim Q3 / final art.**

## Track A — Visibility

Invariant: `fighter_logic_active && fighter_should_be_present => exactly_one_visible_body_representation`

- Select preview: generation tokens, cache reuse, recreate-on-failure, teardown before stage/battle
- Model3D: configure races, immediate controller free, heal on stuck visibility, stylized recoverable fallback
- BattleScene: post-spawn ensure/heal, select_mode off

Desktop stress: transitions=1050, ghosts=0, battle_zero=0

## Track B — Roster uplift v1

Character-like Blender body philosophy propagated beyond Ember to all 7 fighters (not parity, not final art).  
Non-primitive reads: 7

## Truth

FINAL_CHARACTER_ART_PASS=false · HUMAN_ART_DIRECTION_APPROVAL=false · CURSOR_DECLARED_Q3=false · CURSOR_MERGED_NOTHING=true
