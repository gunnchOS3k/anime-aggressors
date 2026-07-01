# Fighter runtime assets

Production fighters import from:

- `assets/exports/godot/fighters/<id>.glb` (source of truth export)
- `glb/<id>.glb` (runtime copy for Godot)

If GLB is missing, `FighterAssetLoader` shows **DEBUG FALLBACK — NOT PRODUCTION MODEL** and uses `ProductionFighterRig` proxy geometry.

See `docs/fighters/` for per-fighter production specs.
