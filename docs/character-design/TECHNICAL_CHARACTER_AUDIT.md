# Technical Character Audit

Branch: `cursor/character-life-and-final-product-pass`  
Date: 2026-07-15

## Anime Aggressors

| Check | Status | Notes |
| --- | --- | --- |
| Skeleton hierarchy | PASS | Procedural `StylizedFighter` Hip→Torso→Chest→Neck→Head + L/R limbs |
| Bone naming | PASS | Godot node names (Hip, Chest, LUpperArm, …) |
| Root motion | N/A | Combat is 2D physics; 3D is presentation SubViewport |
| Mesh weighting | N/A | Hierarchical mesh instances (no skim skinning) |
| Shoulder/elbow/hip/knee | PASS | Capsule/sphere joints; procedural pose API |
| Foot contact | PARTIAL | Presentation feet; no IK |
| Facial rig | PASS | Eye spheres + brows + mouth; `set_expression` morphs readable at phone scale |
| Animation looping | PASS | Procedural `animate_pose` + personality timing offsets |
| Transitions | PARTIAL | Clip restart + optional hidden GLB AnimationPlayer blend |
| Model scale | PASS | Camera framed by per-fighter height scale |
| Collision alignment | PASS | Separate 2D hurt/hit boxes |
| Materials | PASS | Primary/secondary/accent from fighter data + profile |
| Diagnostic labels | PASS | Tier watermark forced off in release presentation |
| Select silhouettes | PASS (vector) | Distinct `FighterSilhouetteCard` shapes per fighter |
| Title cameo | PASS (code) | Boot rotates fighters with silhouette + stylized model |
| Visible GLB proxy | REMOVED | Proxy may load hidden; stylized meshes are the body |

## Pedestrian Pursuit

| Check | Status | Notes |
| --- | --- | --- |
| Modular runners | PASS | Procedural limb/accent topology by archetype |
| Rear readability | PASS (code) | Jacket panel / scarf / backpack / kinetic ring accents |
| Foot sliding | PARTIAL | Cadence synced to speed; no grounded IK |
| Gait identity | PASS | Stride/cadence/lean/bounce scales driven by profile |
| Selection UI | PASS | MainMenu RunnerPicker + SubViewport preview |
| Stumble/recovery | PARTIAL | Distinct pose branches; not skinned dance |
| Podium | PARTIAL | Medal text + finish body poses; no elevated stage mesh |

## Open defects to watch on Pixel

1. Foot contact without IK at high speed.
2. Procedural cloth/hair is static mesh (no cloth sim) — silhouette still distinct via proportions + accessories.
3. GLB proxy remains on disk for asset validators; confirm it stays invisible in release builds.
