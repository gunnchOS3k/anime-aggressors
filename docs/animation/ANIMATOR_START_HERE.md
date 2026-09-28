# Animator start here

1. Clone `gunnchOS3k/anime-aggressors`, branch `vxp/vxp-3-combat-impact-nix-rook` (draft PR #106).
2. Install Git LFS. Ask the owner to enable GitHub LFS write (see `BLENDER_SOURCE_STORAGE.md`). Until then `BLENDER_SOURCE_STORAGE_SETUP_REQUIRED=true`.
3. Install **Blender 3.3.1** (`ANIMATION_PRODUCTION_BLENDER_VERSION=3.3.1`). See `BLENDER_VERSION_QUALIFICATION.md`.
4. Open `art_source/animation/fighters/rook-ironside/source/rook-ironside_animation_master.blend` (generate locally if LFS is blocked: `python3 tools/authored_animation/build_animation_masters.py`).
5. Select `AA_Deform`. Pose FK controls. Reset / mirror / markers live in `aa_control_rig.py`.
6. Animate **empty WIP slots** — do not treat pipeline_proof as acting.
7. Export: `python3 tools/authored_animation/export_action.py --fighter rook-ironside --action heavy`
8. Preview: `npm run anim:preview -- --fighter rook-ironside --action heavy`
9. Submit: `npm run anim:submit-check -- --fighter rook-ironside --action heavy`
10. Evidence stays `AUTHORED_WIP` until a human director approves.

RC1 `v1.0.0-rc.1` is immutable. Do not retag it.
