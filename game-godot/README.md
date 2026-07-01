# Anime Aggressors — Godot Primary Runtime (`game-godot/`)

This directory is the **primary local gameplay runtime** for Anime Aggressors. The TypeScript/Web stack remains reference, spec, validation, and temporary preview tooling.

## Requirements

- [Godot 4.2+](https://godotengine.org/download) (Forward Plus / GL Compatibility)

## Run locally

1. Open Godot Engine.
2. **Import** this folder (`game-godot/project.godot`).
3. Press **F5** (main scene: `scenes/boot/BootScene.tscn`).

### Command line (if `godot` is on PATH)

```bash
godot4 --path game-godot
godot4 --path game-godot --headless --quit-after 1   # smoke import
```

If Godot CLI is not installed, use the editor for manual verification (see `docs/playtest/2026-07-01-godot-runtime-pivot-check.md`).

## Flow

`Boot → Main Menu → Start Battle → Ruleset → Fighter Select → Stage Select → Versus → Battle → Results → Rematch`

Also: `Training`, `Controls`, `Settings`, `Labs`.

## Structure

| Path | Purpose |
|------|---------|
| `scenes/` | Boot, menus, battle, fighters, UI |
| `scripts/` | GDScript gameplay and navigation |
| `data/fighters/` | Seven roster JSON files |
| `data/stages/` | Production stage JSON |
| `assets/placeholder/` | Original AA theme and placeholders |
| `tests/` | Reserved for Godot unit tests |
| `docs/` | Runtime-specific notes |

## Controls (P1)

| Action | Keyboard | Gamepad |
|--------|----------|---------|
| Move | A / D | Left stick |
| Jump | W | A |
| Attack | J | X |
| Special | K | B |
| Shield | L | Y |
| Dodge | I | — |
| Grab | U | (placeholder) |
| Menu back | Esc | B |

P2 defaults to CPU. Toggle on Fighter Select.

## Data validation

From repo root:

```bash
npm run validate:game-godot-primary
```

## IP / branding

All UI uses **original Anime Aggressors** identity. No Nintendo/Super Smash Bros. assets, trade dress, or copyrighted character art.

## Status

Foundation runtime: menu flow, roster/stage data, local 2P/CPU battle prototype (movement, combat, stocks, KO, rematch). See `docs/PRODUCTION_BLOCKERS.md` for P0/P1 gaps.
