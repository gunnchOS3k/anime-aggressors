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

## Hooks (not fully authored this PR)

- `charged_animation_layer.gd` — READY=false
- `combat_cinematic_director.gd` — READY=false
- `anime_timing` / `choreography` metadata on moves
