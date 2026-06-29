# Engine Decision Record — Anime Aggressors

## Status

**Accepted** — Godot 4 becomes the primary gameplay runtime prototype.

## Context

Anime Aggressors started as a TypeScript monorepo with a Three.js web renderer and a fixed-point `game-core` simulation package. That stack works well for:

- GitHub Pages deployment
- Menus, routing, and match setup flows
- Career/save/replay metadata
- Input profiles and docs
- Rapid UI iteration

It does **not** work well as a full fighting-game engine without building animation state machines, rig tooling, camera choreography, particles, and combat feel systems from scratch in the browser.

The user described the prior approach as *digging a swimming pool with a spoon* — menus and aura meter improved, but character movement and combat still did not feel like a platform fighter.

## Decision

Adopt a **split architecture**:

| Layer | Technology | Responsibility |
|-------|------------|----------------|
| Web shell | TypeScript + Vite | Launcher, menus, docs, career metadata, `#/godot` embed |
| Gameplay runtime | Godot 4 + GDScript | Movement, combat, animation, camera, VFX, Derby loop |
| Legacy prototype | TypeScript `game-core` + Three.js | Fallback while Godot runtime matures |

**We are replacing the spoon with the proper crew and proper equipment.**

## Consequences

### Positive

- Real `CharacterBody2D` physics lane with coyote time, jump buffer, air drift
- Limb-based visual rig with procedural animation library
- Hitstop, hitstun, knockback, blast zones, camera impulse in engine-native code
- Godot exports to Web, desktop, and mobile from one project
- TypeScript app remains the public GitHub Pages entry point

### Negative / tradeoffs

- Two runtimes to maintain during migration
- CI cannot export Godot web builds without Godot CLI (checked-in placeholder + local export)
- Rollback netplay must eventually bridge Godot state or remain on legacy sim

## Non-goals (this pass)

- Deleting the TypeScript combat prototype
- Porting every mode (Flagline, career battle, netplay) to Godot
- Copying copyrighted SSF/Brawl assets or frame data

## References

- `game/godot/` — Godot project
- `docs/GODOT_RUNTIME_INTEGRATION.md`
- `docs/GODOT_EXPORT_GUIDE.md`
- `#/godot` — web launcher route
