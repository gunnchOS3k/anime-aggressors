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


## Pixel 6a

- Device serial: `27211JEGR06194`
- Status: **PASS** (authentic)
- PIXEL_DEVICE_AVAILABLE: true
- APK SHA-256: `f408676881deb2ccc470704ffc5cafe3fe1b4cc26f74e2ca6ff80dd9c453df7e`
- PIXEL_SOURCE_SHA: `32558493894eca1d4f208fabd63722bc8ce240eb`
- Select ghosts: 0 · Battle ghosts: 0
- Smoke: 10.051 min · fatal=0 · ANR=0 · deaths=0
- AA-only foreground guard kept
