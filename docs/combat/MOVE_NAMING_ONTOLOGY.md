# Move Naming Ontology

Wave016 defines four parallel ID spaces. Prefer **explicit mapping** (`content/runtime/move_clip_alias_map.json`) over mass renames.

## Spaces

| Space | Example | Owner |
|-------|---------|-------|
| **Input command** | `attack_forward`, `attack_air_back`, `special_neutral` | `Fighter._resolve_*_command` + `docs/CONTROLS.md` |
| **Gameplay move ID** | `forward_tilt`, `back_air`, `neutral_special_projectile` | `game-godot/data/moves/*.json` |
| **Choreography action ID** | `ember-vale.tilt_forward` | `content/choreography/<fighter>/<clip>.json` |
| **Procedural clip ID** | `tilt_forward`, `jab_chain_3` | `*/animations/procedural/*.anim.json` |
| **Signature display name** | `Flare Step Rush` | `game-godot/data/runtime/signature_move_names.json` |

## Canonical tilt / aerial naming

Gameplay historically used Smash-like `forward_tilt` / `neutral_air`.  
Procedural / choreography used verb-first `tilt_forward` / `aerial_neutral`.

| Gameplay move ID | Clip / choreography |
|------------------|---------------------|
| `forward_tilt` | `tilt_forward` |
| `up_tilt` | `tilt_up` |
| `down_tilt` | `tilt_down` |
| `neutral_air` | `aerial_neutral` |
| `forward_air` | `aerial_forward` |
| `back_air` | `aerial_back` |
| `up_air` | `aerial_up` |
| `down_air` | `aerial_down` |
| `jab_1` | `jab` |
| `jab_2` | `jab_chain_2` |
| `jab_finisher` | `jab_chain_3` |
| `heavy_attack` | `heavy` (DESIGN_ONLY control) |
| `aura_burst` | `signature_lane_burst` (deliberate signature bind) |

## Truth chain

`PLAYER INPUT -> input_command -> gameplay_move_id -> timing/hitboxes -> choreography_action_id -> procedural clip -> VFX/SFX/camera -> interaction`

`RuntimeMoveResolver` is the single runtime consumer of the alias map.

## Design-only names

`smash_forward`, `smash_up`, `smash_down`, `air_drift` exist as clips without distinct CONTROLS inputs → `DESIGN_ONLY`.
