# Skeleton contract

Source of truth: `art_source/animation/shared/deform_skeleton/CANONICAL_DEFORM_SKELETON.json`

Required bones: `Root Hips Spine Chest Neck Head Shoulder_L/R UpperArm_L/R LowerArm_L/R Hand_L/R UpperLeg_L/R LowerLeg_L/R Foot_L/R Toes_L/R`

Optional twist: `TwistArm_L/R TwistLeg_L/R`

Optional secondary: `Hair_* Cape_* Coat_* Skirt_* Cloth_*`

Hierarchy: `Root → Hips → Spine → Chest → Neck → Head`. Arms from `Chest`. Legs from `Hips`.

- Units: meters. Up +Y. Forward after Godot import: −Z.
- Rest: A-pose preferred.
- Export deform bones only. No `CTRL_*` / `IK_*` / `MCH_*` in the runtime GLB.
- Visual root motion is **not** authoritative.
