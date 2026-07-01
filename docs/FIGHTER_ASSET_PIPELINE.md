# Fighter Asset Pipeline

## Source layout

```
assets/blender/fighters/<fighter-id>/     # editable .blend
assets/exports/godot/fighters/<id>.glb    # Godot import
assets/exports/unreal/fighters/<id>.fbx   # Unreal R&D import
game/godot/assets/fighters/glb/           # runtime copy (symlink or copy on export)
```

## Per-fighter deliverables

1. Model mesh with readable silhouette
2. Armature with bones matching `FighterSocketMap`
3. Material palette (base, secondary, emissive aura)
4. Animation clips (see `FighterAssetContract.REQUIRED_ANIMATIONS`)
5. Socket empties: hands, feet, weapon, aura_core, hit_spark_center
6. Production spec in `docs/fighters/<NAME>_PRODUCTION_SPEC.md`

## Import (Godot)

1. Place `.glb` in `game/godot/assets/fighters/glb/<fighter-id>.glb`
2. `FighterAssetLoader` loads scene; `FighterAssetContract.validate()` must pass
3. If missing → **DEBUG FALLBACK** rig with visible failure banner

## Legal

- Original characters only
- No ripped assets, copyrighted moves, or unlicensed audio

See `assets/README.md` and `game/godot/scripts/fighter/FighterAssetContract.gd`.
