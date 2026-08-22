# Canonical Humanoid Rig

Production characters must validate against `tools/art_pipeline/validate_character_rig.py`.

## Required bones
`Root`, `Hips`, `Spine`, `Chest`, `Neck`, `Head`,
`Shoulder_L`, `UpperArm_L`, `LowerArm_L`, `Hand_L`,
`Shoulder_R`, `UpperArm_R`, `LowerArm_R`, `Hand_R`,
`UpperLeg_L`, `LowerLeg_L`, `Foot_L`, `Toes_L`,
`UpperLeg_R`, `LowerLeg_R`, `Foot_R`, `Toes_R`

## Optional bones
Finger chains, twist bones, skirt/cape/hair chains, weapon props.

## Axes / rest pose
- Rest: T-pose or A-pose documented per asset
- Forward: -Z after Blender normalize; Up: +Y; meters

## Attachment / VFX sockets (required markers or empty nodes)
`hand_l`, `hand_r`, `foot_l`, `foot_r`, `chest`, `head`, `back`, `projectile_origin`, `aura_root`

## Policy
No model is production-ready without validation PASS.
`art_source/` holds authoring; production GLBs live under `game-godot/assets/characters/`.
