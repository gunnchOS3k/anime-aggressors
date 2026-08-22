# Game Juice Event Contract

Canonical event bus for battle presentation. Normal battle HUD stays clean; debug overlays remain training-only.

## Event families

| Event | Payload keys | Default tier | Notes |
|-------|--------------|--------------|-------|
| `hitstop` | `tier`, `frames` | light/medium/heavy/aura/super | Driven by CombatFeedback |
| `camera_shake` | `tier`, `intensity`, `duration_s` | same tiers | Accessibility can zero |
| `impact_vfx` | `socket`, `element`, `tier` | sockets hand_l/r foot_l/r chest head | |
| `aura_buildup` | `fighter_id`, `level`, `pct` | 0..3 | charge personality per fighter |
| `projectile_trail` | `element`, `charge` | tap/medium/full | |
| `shield_flash` | `fighter_id` | — | |
| `dodge_phase` | `fighter_id`, `air` | — | Vesper-readable phase |
| `grab_flash` | `direction` | — | |
| `landing_dust` | `fighter_id` | — | |
| `recovery_trail` | `element` | — | |
| `ko_burst` | `fighter_id` | heavy | |
| `victory_presentation` | `fighter_id` | — | |
| `sfx` | `event_id`, `category` | — | AudioDirector / procedural bank |
| `rumble` | `strength`, `duration_ms` | optional | controller only |
| `accessibility_reduce` | `flash`, `shake`, `particles` | — | DeviceRoleRuntime |

## Godot hooks

- `game-godot/scripts/combat/combat_feedback.gd` — hitstop/shake/VFX/SFX
- `game-godot/scripts/juice/juice_event_bus.gd` — typed emit/subscribe
- Battle HUD: clean versus presentation
- Training: DebugHud only when competitive rules allow

## Do not

- Put frame-data debug on versus HUD
- Hardcode aggregate PASS for missing art
- Import fal.ai sprite paths into CORE
