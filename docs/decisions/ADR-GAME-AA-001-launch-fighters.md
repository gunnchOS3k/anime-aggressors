# ADR-GAME-AA-001 — Launch fighters

**Status:** Accepted (digital Beta content freeze)  
**Date:** 2026-08-08  
**Context:** Full-product Beta content bar for Anime Aggressors (Godot path).

## Decision

Launch playable fighters = **7** (full roster):

| ID | Display | Element |
|----|---------|---------|
| ember-vale | Ember Vale | Flame |
| rook-ironside | Rook Ironside | Impact |
| juno-spark | Juno Spark | Volt |
| kaia-windrow | Kaia Windrow | Gale |
| nix-calder | Nix Calder | Frost |
| orion-vell | Orion Vell | Gravity |
| vesper-nyx | Vesper Nyx | Void |

Each fighter must be authored with unique silhouette, model presentation, animations, VFX events, audio events, aura identity, move graph, hitboxes, CPU tags, training display, and victory presentation. Automated move-graph uniqueness must reject palette-swap aliases.

## Consequences

- Roster size is frozen at 7 for Beta / RC digital claims.
- Launch shippable presentation is `PROCEDURAL_FINAL` (Blender procedural meshes + stylized runtime). Optional painted remasters are out of digital token scope.
- No copyrighted franchise names or assets.
