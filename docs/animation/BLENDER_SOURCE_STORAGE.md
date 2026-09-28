# Blender source storage — owner instructions

Local `git-lfs` 3.7.1 is installed. `.gitattributes` tracks `*.blend`.

This environment reports `AccessUpload=none` against `github.com/gunnchOS3k/anime-aggressors`.
**`BLENDER_SOURCE_STORAGE_SETUP_REQUIRED=true`.** Do not fake readiness.

## Owner steps
1. GitHub repo → Settings → Billing / Git LFS: enable the free LFS quota (do not buy paid storage unless you choose to).
2. `git lfs install` on the machine that will push.
3. Authenticate `gh auth login` / HTTPS or SSH with LFS transfer allowed.
4. Generate masters: `python3 tools/authored_animation/build_animation_masters.py`
5. Confirm pointer: `git lfs pointer --file art_source/animation/fighters/rook-ironside/source/rook-ironside_animation_master.blend`
6. Push a tiny sentinel only after auth works. Never commit a >100MB ordinary blob.
7. Until that push verifies, keep `.blend` gitignored (`art_source/animation/**/*.blend`).

Exported `pipeline_proof.glb` files stay in normal git (~89KB, original).
