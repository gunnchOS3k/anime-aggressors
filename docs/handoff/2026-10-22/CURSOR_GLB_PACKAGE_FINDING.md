# Cursor GLB package finding — October 22, 2026

Official V1 and RC2 remain NOT READY. This note does not accept art, gameplay, audio, or a release gate. B02 stays CRITICAL. No export filter was changed. No GLB bytes were regenerated.

## Classification

Form-acting GLBs were missing from the package as raw files. That was a packaging defect for the loader that hashes and parses those files. After `importer="keep"` sidecars, the same authored bytes are in the Web and Android packs and `GLTFDocument.append_from_file` builds a scene from the pack.

Scene-imported GLBs that already had a scene `.import` (sample: `pipeline_proof.glb`) are in the pack as PackedScene data. `load()` opens that scene from the pack. Their raw GLB bytes are not stored, and the runtime that uses `load()` does not need them.

## Sources

- Base at branch creation: `3ab7667ca0b22e50bb7acfe0b509ff6b4513daf5` (`origin/release/anime-v1-dialogue-and-elemental-performance` at the start of this check).
- Latest release tip observed after the packs were built: `bda5b5a57fec99fc2d0821ae8819248c1baf7f74`. Those five commits add controls evidence and scripts. They add no `.glb` files and do not touch `export_presets.cfg` or `form_acting_8c`.
- Ship presets are `game-godot/export_presets.cfg` presets **Web** and **Android**. Both use `export_filter="all_resources"`, `include_filter="*.json"`, `exclude_filter="assets/audio/story_temp/*"`.
- `game/godot/export_presets.cfg` is a separate project preset with an empty include filter. Pages and Android CI export `game-godot`.

## What is on the release tip

`git ls-tree -r -l 3ab7667c` found 250 `.glb` files. Inside `game-godot`, the runtime sets are:

| Set | Count | `.glb.import` before this branch | Godot type in the sidecar |
| --- | ---: | --- | --- |
| `assets/characters/form_acting_8c` | 36 | none | raw file; loader uses `GLTFDocument.append_from_file` |
| `assets/characters/collectible_v1` | 64 | yes | `PackedScene` |
| `assets/characters/procedural_final`, `proxy`, `authored` | 21 | yes | `PackedScene` |
| `assets/characters/golden_slice` | 2 | yes | `PackedScene` |
| `content/fighters` procedural proxies and `content/human_art_staging` | 14 | yes | `PackedScene` |

The 36 form files are 384,296 bytes total. All 36 paths are named by `game-godot/data/animation/form_acting_8c/*.json` attachments. `form_presentation_8c.gd` requires the raw `res://` file, a matching SHA-256, and a successful `GLTFDocument.append_from_file`.

`res://.godot/imported/` is not in git. A fresh export creates it.

## Package evidence

Local disk stayed at about 17 GiB free, under the 18 GiB reserve, so no local Godot import or export was run. CI run [39855642863](https://github.com/gunnchOS3k/anime-aggressors/actions/runs/39855642863) on `eng/cursor-v1-glb-package` built packs with Godot 4.3.stable (`77dcf97d8`, the Pages default) and Godot 4.5.stable (`876b29033`, the Android workflow pin and `project.godot` feature). Each pack used the Web and Android filter strings copied from `game-godot/export_presets.cfg`. The authored inputs were `EMBER_ASCENDED.glb` (18,344 bytes, SHA-256 `40ca126adc6136c89cd8944a387951163f2c66c5c5320fdf96f08e2d27db8456`) and `pipeline_proof.glb` (89,132 bytes).

The runtime launch used `--main-pack` from an empty directory, so it could not read the project folder.

Web results, Godot 4.5 (Android packs matched the same presence and byte counts):

| Case | Raw form GLB in pack | Isolated `append_from_file` | `load()` of form path |
| --- | --- | --- | --- |
| No sidecar, current tree | absent; 5,603-byte `.scn` plus `.import` only | file missing | PackedScene |
| Committed `importer="keep"` | 18,344 bytes, magic `glTF`, same SHA-256 | scene generated | null, because keep is not a scene |
| Committed scene import on `pipeline_proof.glb` | raw pipeline bytes absent; 33,563-byte `.scn` present | raw file missing | PackedScene |

Godot 4.3 Web matched that split: unimported form raw bytes absent; committed keep stored 18,344 `glTF` bytes and the isolated loader generated a scene. `extra/keep.json` was in every pack. `extra/skip.txt` was in none. `include_filter="*.json"` adds non-resource JSON. It does not strip resources, and adding `*.glb` would not have kept raw bytes after Godot imported the file as a scene.

## Fix

Smallest change on this branch: 36 `importer="keep"` sidecars beside the form-acting GLBs. Godot 4.5 does not reimport a keep file into a scene (`editor/file_system/editor_file_system.cpp`, keep returns before reimport). Export then stores the source bytes at the original path (`editor/export/editor_export_platform.cpp`, `importer == "keep"`).

No preset line changed. No mesh, animation, combat, VFX, or audio file changed.

## Not run

A full `game-godot` Web or Android export of the collectible set was not run. That import is hundreds of megabytes and the local volume is under the reserve. The probe covers the filter behavior and one real file from each loader class.
