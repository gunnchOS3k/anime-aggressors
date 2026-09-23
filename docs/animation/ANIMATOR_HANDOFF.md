# Animator Handoff — Wave A

**This package is a production pipeline + pose-block proof. It is not a finished animation drop.**

`HUMAN_ANIMATION_QUALITY_PASS=false`. Do not ship these clips as final.

## What already exists (keep)

- Impact profiles, hit-reaction resolver, synchronized hitstop
- Training Impact Lab (now also prints animation provenance)
- VFX / audio hooks, charge-state remaps
- Combat cinematic class routing: `NONE / IMPACT / HEAVY / AURA / SUPER / CLASH / KO`
- Aura clash director (high-commitment only, deterministic, no mash)
- Roster identity notes: `docs/vxp3/FIGHTER_MOTION_IDENTITY_BIBLE.md`

## What you own next

1. Open each fighter control-rig `.blend` (see LFS setup below).
2. Fill the pose bible stills in `art_source/animation/fighters/<id>/pose_bible/`.
3. Author the 14 Wave A hero actions per fighter (98 total). One clip per export file.
4. Export via `tools/authored_animation/run_export_action.py` (when added) or the documented glTF preset.
5. Do **not** move gameplay frame data if a shot is late. Flag the sidecar.

## Wave A hero set (14)

`idle walk run dash jump light medium heavy aura super hurt_heavy launch charge ko`

Manifest: `art_source/animation/manifests/WAVE_A_98_ACTIONS.json`

Current status of all 98: `PROCEDURAL_FALLBACK` (Godot pose-to-pose placeholders).  
Current authored proof: one `pipeline_proof` GLB per fighter, `AUTHORED_WIP`.

## Rig

- Canonical deform: `art_source/animation/shared/deform_skeleton/CANONICAL_DEFORM_SKELETON.json`
- Control rig is FK-default, IK optional. Control bones do not export.
- No visual root motion as movement.

## Style

See `docs/animation/STYLE_GUIDE.md` and the identity bible. Original choreography only.

## Roles

See `docs/animation/PRODUCTION_ROLE_NEEDS.md`.

## Source storage

Git LFS is installed locally but the GitHub LFS remote is **not authenticated** in this environment (`AccessUpload=none`).  
`BLENDER_SOURCE_STORAGE_SETUP_REQUIRED=true` until a human enables LFS push for `*.blend`.

Exported `pipeline_proof.glb` files are versioned under `game-godot/assets/characters/authored/` (small, original, legal to keep).
