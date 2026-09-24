# Blender version qualification

`ANIMATION_PRODUCTION_BLENDER_VERSION=3.3.1`

Do **not** migrate production merely because a newer version exists.

## Matrix

| Check | Blender 3.3.1 (installed) | Blender 4.5 LTS |
|---|---|---|
| Installed on this machine | **Yes** `/Applications/Blender.app` commit `b292cfe5a936` (2022-10-04) | **No** — not installed |
| Open source / factory scene | PASS (used for pipeline_proof + master builder) | not run |
| Control-rig setup | PASS (`aa_control_rig.py` on 3.3.1) | not run |
| Export GLB | PASS (seven `pipeline_proof.glb`, ~89KB, glTF 2.0 binary) | not run |
| Godot import | PASS on prior first-pass (Godot 4.7.1 `--import`) | not run |
| Training playback | PASS path exists (`AuthoredClipLoader` + Training preview) | not run |
| Android export dry-run | not re-run this pass | not run |

## Representative fighter / action

Rook Ironside / `pipeline_proof` (import-path pose-block, **not** final acting).

Recorded from existing proof + 3.3.1 `--version`:

- exported bone names: canonical 22 deform bones + sockets; `CTRL_*` hidden / non-deform
- transforms: meters, A-pose rest, export `export_yup=true`
- animation timing: 60 fps, frames 1–40 pose-block
- importer warnings: none on first-pass Godot import
- file size: 89132 bytes (Rook proof)
- behavioral difference vs 4.5: **unknown — 4.5 not installed**

## Decision

Stay on **3.3.1** for production authoring. Re-qualify only if a human installs 4.5 LTS and repeats this matrix on the same Rook action.
