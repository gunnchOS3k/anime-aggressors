# Authored Animation Contracts

First-pass production contracts. Gameplay timing is authoritative. Animation late ≠ move the hitbox.

## 1. Source-art authority

1. Artist works in Blender `.blend` under `art_source/animation/fighters/<id>/source/`.
2. Export script writes glTF 2.0 binary `.glb` to `fighters/<id>/export/` and copies to `game-godot/assets/characters/authored/<id>/`.
3. Godot import (`*.glb.import`) produces a `PackedScene`.
4. Runtime mapping (`AuthoredClipLoader`) remaps canonical deform bones onto the live fighter skeleton.
5. Provenance sidecar decides whether the clip may override procedural fallback.

No JSON key dump may be labeled `AUTHORED_APPROVED` or `AUTHORED_WIP`.

## 2. Coordinate / scale

| Rule | Value |
|------|--------|
| Units | meters (1 Blender unit = 1 Godot meter) |
| Rest | A-pose documented per fighter; T-pose allowed if `rest_pose` sidecar says so |
| Forward after normalize | −Z |
| Up | +Y |
| Root motion | **Forbidden as authoritative movement.** Gameplay skeleton / CombatMath owns translation. Visual root may hold only presentation offsets that do not write `CharacterBody2D.velocity`. |
| FPS authoring | 60 (export may resample; events stay on frame-data frames) |

## 3. Canonical deform skeleton

Bones and sockets: `shared/deform_skeleton/CANONICAL_DEFORM_SKELETON.json`.

Must validate with `tools/authored_animation/validate_deform_skeleton.py` and the existing `tools/art_pipeline/validate_character_rig.py`.

Control-rig bones (`CTRL_*`, `IK_*`, `MCH_*`) **do not export** into the runtime GLB.

## 4. Control rig (tooling only)

`tools/authored_animation/blender/aa_control_rig.py` configures FK/IK, pole vectors, and copy-transform constraints.

Python **does not manufacture final acting**. It may:

- create bones, constraints, bone layers, custom shapes
- stamp rest pose / A-pose
- insert **pose-block** keys labeled `AUTHORED_WIP` for pipeline proof

It may **not**:

- set `AUTHORED_APPROVED`
- set any `HUMAN_*` or `MERGE_*` gate
- claim a generated clip is final authored animation

## 5. Export

Preset: `shared/export/EXPORT_PRESET.json`.

- Format: glTF 2.0 Binary
- Include: deform mesh, deform skeleton, skins, animations
- Apply modifiers
- No copyrighted third-party meshes
- Animation names = Wave A `action_id` or `pipeline_proof`
- One clip per export file for Wave A hero actions (proof clip is `pipeline_proof.glb`)

## 6. Godot import

- Path: `res://assets/characters/authored/<fighter-id>/<clip>.glb`
- `animation/import=true`, named skins, no root-motion bake onto gameplay
- Loader copies `Animation` resources and remaps tracks through `ProceduralBoneMap`
- Existing `CanonicalProceduralAnimationPlayer` stays the playback owner
- Embedded GLB `AnimationPlayer` nodes stay disabled after extract (current policy)

## 7. Event sync

`choreography.contact_frame` and hitbox windows stay on existing frame data. If authored acting is late, **do not** move gameplay timing. Flag `animation_late_vs_frame_data=true` on the sidecar.

## 8. IP

Original choreography only. No franchise reproduction.
