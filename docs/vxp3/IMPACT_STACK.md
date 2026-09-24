# VXP-3 Impact Stack

Presentation stack only. `CombatMath` remains authoritative for knockback.

## Tiers

`light | medium | heavy | aura | super | ko`

Each profile sets **the same** attacker and defender hitstop frames. Camera impulse is warranted only for heavy / aura / super / ko. Accessibility (`DeviceRoleRuntime` reduce-motion + JuiceEventBus reduce flash/shake) can disable shake, flash, and sparks.

## Resolve order

1. Training force tier
2. Explicit `move.impact_profile`
3. `move.feedback.tier`
4. KO upgrade
5. Aura upgrade for burst/charge
6. Move-type default (never generic `special`)

## Contact

`choreography.contact_frame` must sit inside the move hitbox window. Sparks spawn at `contact_socket` (hand/foot/chest), not a fixed HUD point.

## HUD-hidden classes

`whiff | shield | light | medium | heavy | aura | ko` travel on JuiceEventBus `impact_class`. Battle HUD stays clean. Training debug HUD prints the class.

## Victim reactions

Library families: flinch, stagger, crumple, launch, tumble, spike, freeze_stiffness, body_snap, shield_recoil, ground_bounce, wall_splat, ko_spin.

Gameplay still enters `hurt_light` / `hurt_heavy` / `launched` so competitive state locks do not change. The clip is the family performance.

## Roster-wide presentation (placeholders, not final art)

All seven fighters have unique pose-to-pose clips: locomotion start/loop/stop, charged loco, charge bands 0/25/50/75/100, distinct heavy / aura / super, and a 12-family hurt library. Training Impact Lab is Pixel-touch and Training-only.

## Hooks

- `charged_animation_layer.gd` — READY=true (presentation remap only)
- `combat_cinematic_director.gd` — camera still a11y-gated
- `impact_vfx_director.gd` — short-lived fighter palettes at contact
- `anime_timing` / `choreography` metadata on moves
