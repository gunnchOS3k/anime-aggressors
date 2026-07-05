# Projectile System

Projectiles express fighter identity and scale by aura level.

## Scene

`scenes/combat/Projectile2D.tscn` — Area2D with collision layer 4, mask 2.

## Scripts

- `scripts/combat/projectile.gd` — `AAProjectile` runtime
- `scripts/combat/projectile_spawner.gd` — spawns from move `projectile` config

## Supported Behaviors

| Behavior | Description |
|----------|-------------|
| `straight` | Standard forward shot |
| `beam` | Multi-frame active hitbox path |
| `lob` | Arcing trajectory |
| `boomerang` | Returns at half lifetime |
| `delayed_orb` | Delay before movement (Vesper) |
| `trap` | Planted / delayed activation (Nix, Vesper) |
| `pull_orb` | Slow gravity orb (Orion) |
| `shockwave` | Short-range burst (Rook) |
| `curving_blade` | Curved path (Kaia) |

## Move Config

Projectile moves include:

```json
"projectile": {
  "spawn_frame": 0,
  "speed_by_aura": [],
  "damage_by_aura": [],
  "size_by_aura": [],
  "lifetime_frames_by_aura": [],
  "behavior_by_aura": []
}
```

## Ownership Tracking

Each projectile tracks: owner fighter, fighter ID, move ID, aura level at spawn, hit targets, team slot, lifetime, collision state.

## Hit Routing

Projectile `area_entered` routes through the owner's `HitResolver.resolve()` — same gating as melee (`can_hit_target`).

## Debug

Training mode F11 toggles projectile box overlay via `DebugHud`.
