# Before / After — Projectile

## Before
- `DebugRect` ColorRect forced `visible = true` as player-facing projectile art (TASTE-001).

## After (Wave016)
- Intentional ember teardrop silhouette (`Polygon2D` core + glow + trail + spawn flash).
- Tap / medium / full scale via aura tier.
- `DebugRect` remains in scene for engineers but is never auto-shown as primary art.

Evidence: `game-godot/scripts/combat/projectile.gd`, taste-gate placeholder count.
