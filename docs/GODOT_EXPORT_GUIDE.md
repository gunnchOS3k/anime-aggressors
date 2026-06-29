# Godot Export Guide

## Prerequisites

- Godot **4.2** or newer
- Web export templates installed in Godot (Editor → Manage Export Templates)

## Export from CLI

```bash
# From repo root
npm run godot:export:web
```

Equivalent manual command:

```bash
godot --headless --path game/godot --export-release "Web" apps/web/public/godot/index.html
```

## Verify project

```bash
godot --headless --path game/godot --check-only
```

## CI / GitHub Pages

The Pages workflow does **not** install Godot by default. Options:

1. **Local export + commit** `apps/web/public/godot/` artifacts (large binaries — use sparingly)
2. **Placeholder** — current default; `#/godot` shows instructions until export exists
3. **Future** — add Godot to CI with export templates cached

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `godot: command not found` | Install Godot and add to PATH |
| Export preset missing | Open project in editor once; `export_presets.cfg` is included |
| Blank iframe on Pages | Run export locally; rebuild with `npm run build:pages` |
