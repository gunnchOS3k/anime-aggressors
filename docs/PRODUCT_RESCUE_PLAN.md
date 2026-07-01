# Product Rescue Plan

Anime Aggressors moves from **prototype code generation** to a **real production workflow**.

## Wrong pattern (stop)

- Procedural placeholder fighters as "final"
- Code-generated rigs without Blender source
- Code-only animation without authored clips
- Small patches per complaint
- Menus improved before core combat quality
- No asset source-of-truth
- No production acceptance gate

## Correct pattern (adopt)

- Source art and animation assets (Blender)
- Skeletal rigs with named sockets
- Authored animation clips per move state
- Combat move choreography (animation + hitbox + VFX + camera + audio)
- VFX sockets and hitbox sockets
- Camera rules and sound hooks
- QA gates and release criteria

## Architecture

```
TypeScript shell (Pages) → Godot web runtime → Blender assets
                              ↑                      ↑
                         playtest target      source of truth
Unreal R&D (parallel) ── lessons ──────────────→ Godot import
```

## Milestones

| ID | Gate |
|----|------|
| M0 | Rescue infrastructure (this PR) |
| M1 | Web-playable Godot boot stable |
| M2 | One production-quality fighter asset pipeline |
| M3 | Two fighters with authored animations |
| M4 | One complete match loop |
| M5 | Impact Dummy Derby complete |
| M6 | Full 7-fighter roster production pass |
| M7 | Complete stage roster |
| M8 | Full product polish (audio, VFX, results, replay) |
| M9 | Public playtest release |

## This PR (M0)

Install docs, asset contract, choreography model, Unreal scaffold, product-quality validator, production role ownership, and fighter specs for all seven roster members.
