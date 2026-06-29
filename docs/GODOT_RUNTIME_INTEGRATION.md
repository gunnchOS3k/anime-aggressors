# Godot Runtime Integration

## Overview

Anime Aggressors uses a **split architecture**:

1. **`apps/web`** — TypeScript launcher (menus, routing, GitHub Pages)
2. **`game/godot`** — Godot 4 gameplay runtime (combat, animation, Derby)

## Web entry

- Route: `#/godot`
- Screen: `apps/web/src/screens/GodotRuntimeScreen.ts`
- Embed path: `apps/web/public/godot/index.html` (copied to `dist/godot/` on build)

## Local development

### TypeScript shell

```bash
npm run dev
```

Open `http://localhost:3000/anime-aggressors/#/godot`

### Godot editor

1. Install [Godot 4.2+](https://godotengine.org/)
2. Open `game/godot/project.godot`
3. Press F5 to run `scenes/Main.tscn`

### Export web build for embed

```bash
npm run godot:export:web
```

Requires `godot` on PATH. Output: `apps/web/public/godot/index.html`

## Modes in Godot

| Mode | Scene | Notes |
|------|-------|-------|
| Normal Battle | `BattleScene.tscn` | P1/P2 select → Skyline Arena |
| Impact Dummy Derby | `modes/ImpactDummyDerby.tscn` | Single fighter select required |

## Legacy prototype

**Start Match (Legacy Web Prototype)** in the main menu still launches the TypeScript/Three.js battle. It is not the primary combat engine going forward.

## CI behavior

`npm run build:pages` runs `godot:check` which:

- Verifies `game/godot/project.godot` exists
- Warns if Godot CLI is missing (does not fail deploy)
- Notes whether a web export artifact is present
