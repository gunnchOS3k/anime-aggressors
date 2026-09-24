# Human Art Replacement Contract

Generated production art ships for this release. Future human artists replace sources without changing gameplay.

## Stable logical IDs

| ID | Pattern | Runtime meaning |
|---|---|---|
| fighter mesh id | `<fighter>.mesh` | Godot model path resolver key |
| fighter material id | `<fighter>.material` | Toon/material family |
| fighter skeleton id | `<fighter>.skeleton` | Canonical deform bone set |
| fighter animation action id | `<fighter>.<action>` | Clip name / Wave A action |
| fighter VFX family id | `<fighter>.vfx` | Palettes + socket-aligned effects |
| fighter audio family id | `<fighter>.audio` | Original SFX family |

Fighter IDs: `ember-vale`, `rook-ironside`, `juno-spark`, `kaia-windrow`, `nix-calder`, `orion-vell`, `vesper-nyx`.

## Replacement path

```text
generated master
↓
human master
↓
same exported IDs / sockets / action names
↓
Godot import
↓
gameplay unchanged
```

1. Replace `art_source/animation/fighters/<id>/source/<id>_production_master.blend`.
2. Keep the canonical deform skeleton and sockets.
3. Export the same action names (`idle`, `heavy`, `hurt_heavy`, `signature_lane_burst`, …).
4. Write the same runtime files:
   - `game-godot/content/fighters/<id>/model/<id>_generated_production.glb` (or a later human path that the resolver prefers)
   - `game-godot/content/fighters/<id>/animations/generated_production/<clip>.anim.json` or equivalent GLB clips
5. Do not change CombatMath, hitboxes, or frame-data windows. If acting is late, flag the sidecar. Do not move contact frames.

## Gameplay must never depend on

- Blender object names beyond this export contract
- generated topology or vertex counts
- generated material node internals
- texture filenames outside the resolver contract

## Labels

Generated work is `GENERATED_PRODUCTION_ART` / `GENERATED_PRODUCTION_ANIMATION`.

These stay false until a human artist earns them:

```text
HUMAN_AUTHORED_ART_PASS=false
HUMAN_AUTHORED_ANIMATION_PASS=false
HUMAN_ART_DIRECTION_APPROVAL=false
```
