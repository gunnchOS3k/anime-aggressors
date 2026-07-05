# Combat Architecture

Anime Aggressors production combat runs in `game-godot/` on Godot 4.2+.

## Runtime Stack

```
BattleSim (60 Hz)
  └─ AAFighter.tick_combat_frame()
       ├─ MoveRunner — startup / active / recovery phases
       ├─ ProjectileSpawner — aura-scaled projectiles
       └─ HitResolver — knockback, shield, feedback
            └─ CombatFeedback — hitstop, camera, VFX/SFX hooks
```

## Core Modules

| Module | Path | Role |
|--------|------|------|
| Fighter | `scripts/fighters/fighter.gd` | Input, movement, state, move start |
| State machine | `scripts/fighters/fighter_state_machine.gd` | Enter/update for 47 states |
| Move runner | `scripts/combat/move_runner.gd` | Frame-accurate move phases |
| Hit resolver | `scripts/combat/hit_resolver.gd` | Damage, knockback, hit gating |
| Aura scaler | `scripts/combat/aura_scaler.gd` | Aura level + move scaling |
| Projectile | `scripts/combat/projectile.gd` | Area2D projectile runtime |
| Projectile spawner | `scripts/combat/projectile_spawner.gd` | Spawn from move data |
| Throw resolver | `scripts/combat/throw_resolver.gd` | Directional throw reading |
| Combat feedback | `scripts/combat/combat_feedback.gd` | Data-driven hit feel |
| Data loader | `scripts/data/data_loader.gd` | JSON manifest loading |

## Move Schema

Move manifests use **schema_version 2**. Each fighter has 23 required moves with `move_type`, `direction`, `aura_scaling`, and `feedback`. Projectile and throw moves include conditional `projectile` / `throw` blocks.

## Data Flow

1. Input resolves to `input_command` (e.g. `attack_forward`, `special_neutral`).
2. `DataLoader.find_move_by_input()` selects the move; jab chain overrides for `attack_neutral`.
3. `AuraScaler.apply_to_move()` scales damage, hitboxes, projectiles, cancel windows.
4. `MoveRunner` ticks phases at 60 Hz; active phase enables hitboxes or spawns projectiles.
5. Overlap triggers `HitResolver.resolve()` → `CombatFeedback.apply_hit()` → `receive_hit()`.

## Training Mode

Training battle exposes full combat state via `DebugHud` and F-key toggles. See `docs/TRAINING_DEBUG_SUPPORT.md`.

## Validation

`npm run validate:full-scope-production` enforces schema v2, unique fighter identity, combat modules, and documentation.
