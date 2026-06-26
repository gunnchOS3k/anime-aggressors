# Asset pipeline

## Layout

```
assets/
  manifest.json
  characters/
  stages/
  props/
  animations/
```

## Gate

**SHIP BLOCKED** until first original GLB fighter + stage prop are committed and loaded in the demo.

Placeholders in `apps/web/src/renderer-three/` remain the fallback.

## Blender → GLB

1. Model in Blender (original Anime Aggressors designs only)
2. Export glTF Binary (.glb)
3. Place under `assets/characters/` or `assets/stages/`
4. Register in `assets/manifest.json`
5. `AssetLoader` resolves manifest paths under `/anime-aggressors/assets/`

## Manifest

See `assets/manifest.json` for character/stage entries and fallback flags.
