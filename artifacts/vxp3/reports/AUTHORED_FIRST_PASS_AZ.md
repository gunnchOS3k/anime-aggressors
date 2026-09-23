# Authored Animation First Pass — A–Z

Draft PR #106. Do not merge. Not final authored animation.

## A — current #106 head/base

- Branch: `vxp/vxp-3-combat-impact-nix-rook`
- Reported start head: `c26e7c16c967c0b5f3117af030ed83fac3cd1b71`
- Base / accepted main: `6cd1b3100a7e467c2c991394576891660deb1162`
- RC1 `v1.0.0-rc.1` untouched
- This pass is a new commit on the same draft branch

## B — procedural / current animation audit

#106 already ships a useful combat stack: impact profiles, reaction resolver, synced hitstop, Training Impact Lab, VFX/audio hooks, charge-state remaps, camera a11y hooks, roster identity data, uniqueness validators.

Playback is `FighterAnimationController` loading Godot `.anim.json` pose-to-pose placeholders (`PROCEDURAL_RUNTIME_ANIMATION`). ~106 clips per fighter. These remain **fallback / blockout / regression fixtures**. They are not final authored animation.

## C — authored source layout

`art_source/animation/` now holds contracts, canonical deform skeleton, control-rig spec, export preset, per-fighter folders (source / pose_bible / actions / export), Wave A manifest, and provenance roster.

## D — Git LFS / source storage

- git-lfs 3.7.1 is installed
- `.gitattributes` tracks `*.blend`
- GitHub LFS remote auth is **none** (`AccessUpload=none`)
- `BLENDER_SOURCE_STORAGE_SETUP_REQUIRED=true`
- `.blend` files are generated locally and **not** committed
- Exported `pipeline_proof.glb` files are versioned (~89KB each)

## E — canonical deform skeleton

22 required bones + 9 sockets. Rest A-pose, meters, −Z forward after export, +Y up. No visual root motion as movement. Validated against all seven proof GLBs. Compatible with existing `ProceduralBoneMap` aliases.

## F — Blender control rig

`tools/authored_animation/blender/aa_control_rig.py` creates `CTRL_FK_*`, IK handles, pole vectors, and FK copy-rotation. IK constraints stay off until an animator enables them (avoids FK/IK cycles). Python configures tools; it does not manufacture final acting.

## G — mesh deformation audit

Procedural proxy GLBs have skins + WEIGHTS_0 (not final art). Authored proof GLBs are skinned cylinders with 23 joints + weights for import-path proof. `AUTHORED_HURT_PASS` / final weights stay false.

## H — export pipeline

Blender 3.3.1 background: deform armature + sockets + skinned proxy + `pipeline_proof` NLA action → glTF 2.0 binary. Control bones do not export as deform.

## I — Godot import pipeline

Copies live at `game-godot/assets/characters/authored/<id>/pipeline_proof.glb`. Godot 4.7.1 `--import` succeeded for all seven. `AuthoredClipLoader` remaps rotation tracks onto the live skeleton. Embedded GLB players stay disabled after extract.

## J — animation provenance

Labels: `AUTHORED_APPROVED` / `AUTHORED_WIP` / `PROCEDURAL_FALLBACK` / `MISSING`. Automation may write the last three only. Training Impact Lab prints clip + provenance. Hero set is `PROCEDURAL_FALLBACK`. Proof clips are `AUTHORED_WIP`.

## K — Wave A 98-action roster manifest

14 × 7 defined in `art_source/animation/manifests/WAVE_A_98_ACTIONS.json`: idle, walk, run, dash, jump, light, medium, heavy, aura, super, hurt_heavy, launch, charge, ko. `authored_complete_count=0`. Not fake-complete.

## L–R — authored test action per fighter

Each is a real Blender GLB (magic `glTF`, JSON+BIN, skin, `pipeline_proof` animation), imported by Godot. Pose-block only. `AUTHORED_WIP`. Not final acting.

| Fighter | GLB | Bytes | Status |
|---------|-----|-------|--------|
| L Ember Vale | `.../ember-vale/pipeline_proof.glb` | 89132 | AUTHORED_WIP |
| M Rook Ironside | `.../rook-ironside/pipeline_proof.glb` | 89132 | AUTHORED_WIP |
| N Juno Spark | `.../juno-spark/pipeline_proof.glb` | 89132 | AUTHORED_WIP |
| O Kaia Windrow | `.../kaia-windrow/pipeline_proof.glb` | 89128 | AUTHORED_WIP |
| P Nix Calder | `.../nix-calder/pipeline_proof.glb` | 89128 | AUTHORED_WIP |
| Q Orion Vell | `.../orion-vell/pipeline_proof.glb` | 89132 | AUTHORED_WIP |
| R Vesper Nyx | `.../vesper-nyx/pipeline_proof.glb` | 89132 | AUTHORED_WIP |

## S — pose-bible templates

Templates for all seven under `art_source/animation/fighters/<id>/pose_bible/`. Slots listed, stills empty. `AUTHORED_POSE_BIBLE_PASS=false`.

## T — secondary-motion architecture

Prefix contract + `SecondaryMotionLayer` spring fallback. Reduce-motion disables it. No authored hair/cloth. `AUTHORED_SECONDARY_PASS=false`.

## U — AuraClashDirector vertical slice

High-commitment only (aura/super/beam/explicit). Jabs never clash. Deterministic score, no mash. Mixed identities flagged. Training lab **Debug aura clash**. Wired into `HitResolver` (non-attacker-win cancels the incoming confirm).

## V — cinematic director integration

Classes: `NONE / IMPACT / HEAVY / AURA / SUPER / CLASH / KO`. Camera still a11y-gated. Existing light-skip / heavy-warrant behavior preserved.

## W — Pixel performance preflight

Pixel 6a attached (`PIXEL_USB_DEVICE_1`). No authored-combat APK rebuild/profile. `PIXEL_AUTHORED_COMBAT_PERF_PASS=false`. Motion was not deleted to save perf.

## X — animator handoff package

`docs/animation/ANIMATOR_HANDOFF.md`, `STYLE_GUIDE.md`, `PRODUCTION_ROLE_NEEDS.md`, `AURA_CLASH.md`, plus pose bibles and Wave A manifest.

## Y — human / final-art gate states

| Gate | Value |
|------|-------|
| AUTHORED_RIG_PIPELINE_PASS | true |
| AUTHORED_EXPORT_IMPORT_PASS | true |
| AUTHORED_HERO_SET_ROSTER_PASS | false |
| AUTHORED_POSE_BIBLE_PASS | false |
| AUTHORED_HURT_PASS | false |
| AUTHORED_CHARGE_PASS | false |
| AUTHORED_SECONDARY_PASS | false |
| AURA_CLASH_SYSTEM_PASS | true |
| CINEMATIC_COMBAT_DIRECTOR_PASS | true |
| PIXEL_AUTHORED_COMBAT_PERF_PASS | false |
| HUMAN_ANIMATION_QUALITY_PASS | false |
| HUMAN_COMBAT_FEEL_PASS | false |
| HUMAN_AURA_CLASH_PASS | false |
| HUMAN_CLIP_WORTHY_PASS | false |
| MERGE_AUTHORIZED | false |
| FINAL_AUTHORED_ANIMATION_PASS | false |

## Z — exact human Blender work required next

1. Enable Git LFS push on the GitHub remote; check in control-rig `.blend` sources.
2. Bind real character meshes to the canonical deform skeleton (current proof mesh is a cylinder).
3. Fill pose-bible stills for all seven (neutral, charge 0/50/100, light/heavy contact, hurt, launch, KO, signature).
4. Author Wave A 14 hero actions per fighter (98). Export one GLB per action. Do not move frame data if acting is late.
5. Author charge presence, hurt families, and secondary (hair/coat/cape) as later waves.
6. Author clash pair acting (high-commitment only) for mixed-identity reads.
7. Human playtest on Pixel 6a Training Impact Lab; only then may a human set HUMAN_* / MERGE gates.

**Stop.** Pipeline + representative authored-import proof only. Hero set is not complete.
