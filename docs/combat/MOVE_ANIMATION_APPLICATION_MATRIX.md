# Move Animation Application Matrix

Wave016 canonical truth chain:
`PLAYER INPUT -> command -> move_id -> timing/hitboxes -> choreography action_id -> visible clip -> VFX/SFX/camera -> interaction`

- PROCEDURAL_CLIPS_GENERATED: **357**
- NORMAL_PLAYER_INPUT_REACHABLE_CLIPS: **287**
- GAMEPLAY_STATE_REACHABLE_CLIPS: **287**
- LAB_ONLY_CLIPS: **42**
- DESIGN_ONLY_CLIPS: **28**

Full machine-readable matrix: `content/runtime/move_animation_application_matrix.json`

## Ember Vale (Golden Slice) gameplay moves

| move_id | input | clip | status | normal_reachable |
|---------|-------|------|--------|------------------|
| `jab_1` | `attack_neutral` | `jab` | ALIASED | True |
| `jab_2` | `attack_neutral` | `jab_chain_2` | ALIASED | True |
| `jab_finisher` | `attack_neutral` | `jab_chain_3` | ALIASED | True |
| `forward_tilt` | `attack_forward` | `tilt_forward` | ALIASED | True |
| `up_tilt` | `attack_up` | `tilt_up` | ALIASED | True |
| `down_tilt` | `attack_down` | `tilt_down` | ALIASED | True |
| `dash_attack` | `attack_dash` | `heavy` | ALIASED | True |
| `heavy_attack` | `attack_heavy` | `heavy` | DESIGN_ONLY | False |
| `neutral_air` | `attack_air_neutral` | `aerial_neutral` | ALIASED | True |
| `forward_air` | `attack_air_forward` | `aerial_forward` | ALIASED | True |
| `back_air` | `attack_air_back` | `aerial_back` | ALIASED | True |
| `up_air` | `attack_air_up` | `aerial_up` | ALIASED | True |
| `down_air` | `attack_air_down` | `aerial_down` | ALIASED | True |
| `neutral_special_projectile` | `special_neutral` | `projectile_full` | ALIASED | True |
| `side_special` | `special_forward` | `signature_lane_feint` | ALIASED | True |
| `up_special_recovery` | `special_up` | `recovery` | ALIASED | True |
| `down_special` | `special_down` | `signature_lane_trap` | ALIASED | True |
| `grab` | `grab` | `grab` | EXACT | True |
| `throw_forward` | `throw_forward` | `throw_forward` | EXACT | True |
| `throw_back` | `throw_back` | `throw_back` | EXACT | True |
| `throw_up` | `throw_up` | `throw_up` | EXACT | True |
| `throw_down` | `throw_down` | `throw_down` | EXACT | True |
| `aura_charge` | `aura_charge` | `aura_charge` | EXACT | True |
| `aura_burst` | `aura_burst` | `signature_lane_burst` | ALIASED | True |
| `signature_lane_confirm` | `` | `signature_lane_confirm` | SIGNATURE_NOT_BOUND_TO_INPUT | False |
| `signature_lane_control` | `` | `signature_lane_control` | SIGNATURE_NOT_BOUND_TO_INPUT | False |
| `signature_lane_counter` | `` | `signature_lane_counter` | SIGNATURE_NOT_BOUND_TO_INPUT | False |
| `signature_lane_finisher` | `` | `signature_lane_finisher` | SIGNATURE_NOT_BOUND_TO_INPUT | False |
| `signature_lane_launch` | `` | `signature_lane_launch` | SIGNATURE_NOT_BOUND_TO_INPUT | False |

## Mapping statuses

EXACT, ALIASED, MISSING_CLIP, MISSING_GAMEPLAY_MOVE, DESIGN_ONLY, SIGNATURE_NOT_BOUND_TO_INPUT, GENERIC_FALLBACK, BROKEN.

Reachability is honest: generated ≠ reachable. 357 is LOADED/GENERATED only.

