# Anime Aggressors — Godot Production Runtime

**This is the shipping gameplay runtime.** All production combat, menus, training, and assets belong here.

- Open `project.godot` in Godot 4.2+ and press **F5**
- Main scene: `scenes/boot/BootScene.tscn`
- Policy: [../../docs/RUNTIME_SOURCE_OF_TRUTH.md](../../docs/RUNTIME_SOURCE_OF_TRUTH.md)

## Production flow

`Boot → Main Menu → Mode Select → Ruleset → Fighter Select → Stage Select → Versus → Battle → Results`

Training: `Main Menu → Training → Training Battle` (debug instrumentation)

## Commands (from repo root)

```bash
npm run validate:full-scope-production
npm run generate:godot-full-scope
```

## Folder map

| Folder | Purpose |
|--------|---------|
| `scenes/` | Boot, menus, battle, training, UI |
| `scripts/` | Core, combat, movement, fighters, AI, debug |
| `data/` | Fighters, moves, stages, rulesets, balance |
| `assets/` | Characters, stages, VFX, audio, UI |
| `tests/` | Godot unit tests (future) |
| `docs/` | Runtime-specific notes |

## Status

Foundation active — see [FULL_SCOPE_PRODUCTION_PLAN.md](../../docs/FULL_SCOPE_PRODUCTION_PLAN.md). Proxy/placeholder art is labeled in debug HUD.
