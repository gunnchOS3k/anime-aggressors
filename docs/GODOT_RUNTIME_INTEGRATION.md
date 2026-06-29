# Godot Runtime Integration

## Overview

Anime Aggressors uses a **split architecture**:

1. **`apps/web`** — TypeScript launcher (menus, routing, GitHub Pages)
2. **`game/godot`** — Godot 4 gameplay runtime (combat, animation, Derby)

## Web entry

- Route: `#/godot`
- Screen: `apps/web/src/screens/GodotRuntimeScreen.ts`
- Embed path: `apps/web/public/godot/index.html` (copied to `dist/godot/` on build)
- Direct URL: `https://gunnchos3k.github.io/anime-aggressors/godot/index.html`

The runtime screen probes the export at load time. If the export is missing or still the placeholder gradient page, it shows an explicit error instead of pretending the shell is playable.

## Local development

### TypeScript shell

```bash
npm run dev
```

Open `http://localhost:3000/anime-aggressors/#/godot`

### Godot editor

1. Install [Godot 4.3+](https://godotengine.org/)
2. Open `game/godot/project.godot`
3. Press F5 to run `scenes/Main.tscn`

### Export web build for embed

```bash
npm run godot:export:web
```

Requires Godot CLI on PATH or `GODOT_BIN`. Output: `apps/web/public/godot/` (html, js, wasm, pck).

The export uses **single-threaded** Web mode for GitHub Pages compatibility (no COOP/COEP headers required).

## Modes in Godot

| Mode | Scene | Notes |
|------|-------|-------|
| Normal Battle | `BattleScene.tscn` | P1/P2 select → Skyline Arena |
| Impact Dummy Derby | `modes/ImpactDummyDerby.tscn` | Single fighter select required |

## Legacy prototype

**Start Match (Legacy Web Prototype)** in the main menu still launches the TypeScript/Three.js battle. It is not the primary combat engine going forward.

## CI behavior

`npm run build:pages`:

1. `npm run godot:export:web` — exports real Godot Web build in CI
2. `npm run build:web` — Vite build copies `public/godot/` to `dist/godot/`
3. `npm run assert:godot-export` — fails if placeholder or missing wasm/pck/js
4. `npm run finalize:pages` — writes deploy metadata

`npm run godot:check` is a lightweight local diagnostic (project exists, optional CLI detection).
