# Godot Vertical Slice QA

## Automated

- `npm run verify:godot-public`
- `npm run validate:godot-rig`
- `npm run validate:godot-animation`
- `npm run validate:godot-vfx`
- `npm run test:web`

## Manual browser QA (after Pages deploy)

| Step | Expected |
|------|----------|
| Open `#/godot` normally (no hard refresh) | Godot boot shell loads |
| Build badge | `Godot Build: <id> · Commit: <sha>` |
| Character select | Ember (P1) / Juno (P2) defaults |
| Fighters in battle | Volumetric meshes, distinct silhouettes |
| Skyline Arena intro | Stage name → Ready → Fight |
| Jump / attack / aura | Limbs move; aura on chest socket |
| Hit land | Sparks + camera impulse |
| KO | Results with WINNER, rematch, select |

## Visual notes (manual)

- Ember: red/orange gauntlets, flame aura
- Juno: yellow/black scarf accent, electric sparks
- Skyline: layered skyline, thick platforms, side platforms
- Rescue runtime must only appear as labeled fallback, not primary gameplay

Public URL: https://gunnchos3k.github.io/anime-aggressors/#/godot
