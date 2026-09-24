# Generated Character Modeling Pipeline

Deterministic Blender/BMesh production roster. Original designs only.

## Command

```text
python3 -m tools.generated_production_art.run_pipeline
```

Blender 3.3.1 (`/Applications/Blender.app/Contents/MacOS/Blender` or `BLENDER_BIN`).

## Inputs

- `game-godot/data/art/generated_v3/fighter_shape_profiles.json` — versioned per-fighter shape control
- `tools/generated_production_art/profiles.py` — palettes, timing, motion notes
- `tools/generated_production_art/body_v3.py` — designed extremity and costume recipes
- Canonical deform skeleton + sockets
- Gameplay frame windows (animation late ≠ move hitboxes)

## Mesh method (v3 character craft)

1. Primitive-driven **body core** at rest-bone positions (torso, limbs, connection stubs)
2. Voxel remesh + smooth the core only so the body stays one cohesive island
3. Attach designed (not remeshed) head shells, hands, boots, and costume plates
4. Hands: palm block + thumb wedge + grouped fingers + knuckle + wrist cuff
5. Boots: heel / toe / sole / ankle, fighter-specific silhouette
6. Heads stay faceless/abstract with fighter-specific silhouette language
7. Proximity/region vertex weights against deform + accessory bones
8. Normalize weights; no third-party topology

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
