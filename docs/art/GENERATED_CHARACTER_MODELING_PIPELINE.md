# Generated Character Modeling Pipeline

Deterministic Blender/BMesh production roster. Original designs only.

## Command

```text
python3 -m tools.generated_production_art.run_pipeline
```

Blender 3.3.1 (`/Applications/Blender.app/Contents/MacOS/Blender` or `BLENDER_BIN`).

## Inputs

- `tools/generated_production_art/profiles.py` — proportions, palettes, accessories, timing
- Canonical deform skeleton + sockets
- Gameplay frame windows (animation late ≠ move hitboxes)

## Mesh method

1. Primitive-driven body parts (cubes, capsules, spheres) at rest-bone positions
2. Fighter-specific costume pieces (gauntlets, scarf, rings, coat panels, crystals)
3. Join to one production mesh
4. Proximity/region vertex weights against deform + accessory bones
5. Normalize weights; no third-party topology

## Materials

Original generated toon/principled slots:

- skin, cloth, accent (emission), hair, secondary
- charged palette is a brighter accent, not a second character
- no external texture libraries

## Rig

Canonical 22 deform bones + fighter accessory chains (`Cloth_*`, `Coat_*`, `Hair_*`).

Sockets: `hand_l/r`, `foot_l/r`, `chest`, `head`, `back`, `projectile_origin`, `aura_root`.

Control-rig bones do not export.

## Outputs

| Artifact | Path |
|---|---|
| Master (local) | `art_source/animation/fighters/<id>/source/<id>_production_master.blend` |
| Runtime GLB | `game-godot/content/fighters/<id>/model/<id>_generated_production.glb` |
| Review stills | `artifacts/vxp3/review/generated_production/<id>/` |
| Manifest | `artifacts/vxp3/reports/GENERATED_PRODUCTION_ART_MANIFEST.json` |

Masters stay gitignored while Git LFS remote auth is unavailable. The generator + exported GLBs are the committed source of truth.

## Mobile

Low-to-mid poly, LOD on import, short-lived VFX, no permanent full-screen effects.
