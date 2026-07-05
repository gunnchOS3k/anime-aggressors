# Aura System

Aura is a universal mechanic with fighter-specific scaling behavior.

## Levels

| Aura | Level | Name |
|------|-------|------|
| 0–24 | 0 | Base combat |
| 25–49 | 1 | Slight enhancement |
| 50–74 | 2 | Behavior changes |
| 75–99 | 3 | Strong modifiers |
| 100 | 4 | Super ready |

Resolved by `AuraScaler.aura_level()` in `scripts/combat/aura_scaler.gd`.

## Charge Input

Hold **Shield + Special** to charge aura. At 100%, press **Attack** for `aura_burst` (consumes 100 aura).

## Scaling Dimensions

Aura scaling is **not** flat damage only. Each move's `aura_scaling` block can modify:

- Damage and knockback multipliers
- Hitbox scale and extra active frames
- Cancel windows
- Element effect strength
- Armor frames (e.g. Rook Ironside)
- Projectile speed, size, lifetime, behavior
- Feedback tier escalation

## Fighter Identity

| Fighter | Aura Fantasy |
|---------|-------------|
| Ember Vale | Burn trails, flame burst finishers |
| Rook Ironside | Armor frames, quake knockback |
| Juno Spark | Stun extension, dash cancel windows |
| Kaia Windrow | Air drift cancels, wind hitbox linger |
| Nix Calder | Chill/freeze strength, ice armor |
| Orion Vell | Pull strength, combo angle bias |
| Vesper Nyx | Void mark, phase cancel windows |

## Runtime

`AAFighter._start_move_dict()` calls `AuraScaler.apply_to_move()` before starting the move runner. Projectiles read aura at spawn via `ProjectileSpawner.spawn_from_move()`.
