# Authored Animation Contracts

Gameplay timing is authoritative. Animation late ≠ move the hitbox.

## 1. Source-art authority

1. Artist works in Blender `.blend` under `art_source/animation/fighters/<id>/source/`.
2. Export writes glTF 2.0 binary `.glb` to `fighters/<id>/export/`.
3. Human candidates import to `game-godot/content/human_art_staging/<id>/` with `HUMAN_ART_STAGING=0` by default.
4. Production resolver does **not** pick staging or generated research assets automatically.
5. Provenance sidecar decides whether a clip may later override accepted art — only after owner approval.

## 2. Coordinate / scale

| Rule | Value |
|------|--------|
| Units | meters |
| Rest | A-pose documented; T-pose allowed if sidecar says so |
| Forward after normalize | −Z (Godot). Review cameras use skeleton forward `(0, 1, 0)` in Blender export space. |
| Up | +Y |
| Root motion | **Forbidden as authoritative movement.** CombatMath owns translation. |
| FPS | 60 |

## 3. Canonical deform skeleton

Bones and sockets: `shared/deform_skeleton/CANONICAL_DEFORM_SKELETON.json`.

Control-rig bones (`CTRL_*`, `IK_*`, `MCH_*`) **do not export**.

## 4. Event sync

`choreography.contact_frame` and hitbox windows stay on existing frame data.
If acting is late, flag `animation_late_vs_frame_data=true`. Do not move gameplay.

## 5. IP

Original choreography only. No franchise reproduction.
