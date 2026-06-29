# Godot Export Guide

## Prerequisites

- Godot **4.3+** with Web export templates
- Templates install automatically via `scripts/install-godot-templates.sh`, or use Godot Editor → Manage Export Templates

## Export from CLI

```bash
# From repo root
npm run godot:export:web
```

Requires `godot` on PATH or `GODOT_BIN=/path/to/godot`. Output lands in `apps/web/public/godot/`:

| File | Role |
|------|------|
| `index.html` | Godot web shell |
| `index.js` | Engine loader |
| `index.wasm` | WebAssembly runtime |
| `index.pck` | Packed game data |

Equivalent manual command:

```bash
godot --headless --path game/godot --export-release "Web" apps/web/public/godot/index.html
```

## GitHub Pages compatibility

Use the **Web** export preset with **single-threaded** export (`variant/thread_support=false` in `game/godot/export_presets.cfg`).

| Requirement | Why |
|-------------|-----|
| `thread_support=false` | Threaded exports need COOP/COEP headers and SharedArrayBuffer |
| Relative asset paths | Hosted under `/anime-aggressors/godot/` on project Pages |
| No placeholder HTML | `npm run assert:godot-export` fails the build if only the gradient placeholder exists |

**Do not** enable threaded Web export for GitHub Pages — Pages does not set cross-origin isolation headers.

## Verify project

```bash
godot --headless --path game/godot --check-only
```

## CI / GitHub Pages

The Pages workflow (`.github/workflows/pages.yml`):

1. Installs Godot 4.3 CLI + export templates on Ubuntu
2. Runs `npm run godot:export:web`
3. Runs `npm run build:web && npm run assert:godot-export && npm run finalize:pages`
4. Deploys `apps/web/dist/` including `dist/godot/`

Live URL: `https://gunnchos3k.github.io/anime-aggressors/godot/index.html`

## Local Pages build

```bash
npm run build:pages
```

This exports Godot, builds the Vite app, asserts real wasm/pck/js artifacts exist in `apps/web/dist/godot/`, and writes deploy metadata.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `Godot CLI was not found` | Install Godot 4.3+ or set `GODOT_BIN` |
| Missing `web_nothreads_*` templates | Run `bash scripts/install-godot-templates.sh` |
| Export preset missing | `export_presets.cfg` is checked in; open project in editor once if needed |
| Blue gradient placeholder on Pages | Run `npm run godot:export:web`, commit artifacts, rebuild |
| `assert:godot-export` fails | Ensure `index.html` is a real Godot export, not the hand-written placeholder |
