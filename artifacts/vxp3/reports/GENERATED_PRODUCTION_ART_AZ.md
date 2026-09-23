# Generated Production Art — A–Z

Draft PR #106. Do not merge. Not human-authored final art. RC1 `v1.0.0-rc.1` untouched.

## A — current head/base

- PR: https://github.com/gunnchOS3k/anime-aggressors/pull/106
- Branch: `vxp/vxp-3-combat-impact-nix-rook`
- Start head: `002fddc6bcdb39f4f5af139faa0ba25b26f9002b`
- Base / accepted main: `6cd1b3100a7e467c2c991394576891660deb1162`
- This pass adds a new commit on the same draft branch (head SHA after push)

## B — master files

Seven generated production masters at:

`art_source/animation/fighters/<id>/source/<id>_production_master.blend`

Fighters: ember-vale, rook-ironside, juno-spark, kaia-windrow, nix-calder, orion-vell, vesper-nyx.

Each master includes production mesh, canonical deform rig, accessory chains, materials, action library, sockets, review camera/lights. SHA256 recorded in `GENERATED_PRODUCTION_MASTERS.json`. Blends stay gitignored (LFS remote auth still unavailable).

## C — source-storage status

- git-lfs installed; `*.blend` tracked in `.gitattributes`
- GitHub LFS upload still not configured
- Masters generated locally, SHA256 recorded, not committed
- Committed: deterministic generator + exported GLBs + JSON clips + audio + VFX + review stills
- `GENERATED_MASTER_REPRODUCIBLE=true` for equivalent export contracts from the committed generator

## D — roster mesh summary

Stylized segmented mannequins (not cylinders). Per-fighter body scale, costume pieces, palettes. Runtime:

`game-godot/content/fighters/<id>/model/<id>_generated_production.glb` (~4.5 MB each, mesh + 113 actions).

Honest visual: readable as distinct blockout characters, **not** finished anime sculpts. Some accessory blocks float off limb ends. Owner Q1 is likely “no”.

## E — roster material summary

Original generated principled/toon slots: skin, cloth, accent emission, hair, secondary. Charged palette is brighter accent. No third-party textures. `GENERATED_PRODUCTION_MATERIAL_ROSTER_PASS` automated true.

## F — roster rig summary

Canonical 22 deform bones + sockets + fighter accessory bones (`Cloth_*`, `Coat_*`, `Hair_*`). Rigid per-part vertex groups. `MESH_BINDING_NEEDS_HUMAN_WEIGHT_PAINT=false` for this generated method. Extreme poses still show gaps/floaters.

## G — Ember Vale

Flame rushdown. Warm cloth, ember hair block, gauntlet cubes, chest vent. Forward-lean idle, explosive heavy, flame-follow arms. 113 generated clips.

## H — Rook Ironside

Impact bruiser. Broad torso, back plate, heavy boots. Planted stance, slow-load / huge-release heavy. Strongest mass silhouette of the seven.

## I — Juno Spark

Volt speed. Lean yellow body, cyan panels, hair spike. Staccato idle, snap attacks, fast recovery timing profile.

## J — Kaia Windrow

Gale aerial. Teal body, scarf/ribbon/airfoil extras. Arc/buoyancy loco, cloth secondary bone `Cloth_Scarf`.

## K — Nix Calder

Frost precision. Compact cool silhouette, crystal extras, strong glove/boot accents. Tight motion, stiffness-on-impact hurt.

## L — Orion Vell

Gravity control. Purple layered cloth, orbit torus on `Cloth_Orbit`. Hand-led / delayed-body timing.

## M — Vesper Nyx

Void trickster. Asymmetric coat panels, hood. False-start / delayed-tell motion profile.

## N — full animation coverage matrix

113 unique actions × 7 fighters written to `content/fighters/<id>/animations/generated_production/`.

Covers: existing 52 gameplay clips + locomotion extras + charge family + hurt family + clash acting + Wave A aliases.

Wave A 98 labeled `GENERATED_PRODUCTION_ANIMATION` in `art_source/animation/manifests/WAVE_A_GENERATED_PRODUCTION_98.json`. Not `AUTHORED_APPROVED`. Resolver prefers generated_production over procedural placeholders.

## O — hurt coverage

hurt_light/mid/high/low, medium front/back, heavy front/back, launch family, tumble, ground_bounce, wall_splat, shield hits, grabbed/throw victim, ko_launch. Exaggeration guard passed (head/chest/arm/silhouette floors).

## P — charge coverage

charge_start/low/mid/high/full/release + charged loco. Base vs 100% charged_idle exceeds calibrated silhouette/chest floors.

## Q — secondary-motion coverage

Accessory bones on all seven. Runtime `SecondaryMotionLayer` prefixes include Cloth/Coat/Hair. Provenance `GENERATED_PRODUCTION_SECONDARY`. Spring fallback remains; not human cloth sim.

## R — VFX coverage

`game-godot/data/vfx/generated_production/` palettes + clash mix presets (Rook/Orion, Juno/Kaia, Ember/Nix, Vesper/Ember, Nix/Rook). Short-lived, socket-aligned, a11y-reducible descriptors. No third-party plates.

## S — audio coverage

41 original WAV files under `assets/audio/generated_production/` (whoosh, hit tiers, charge tiers, clash bed/resolution, per-fighter element layers). No copyrighted samples. Resolver prefers generated paths.

## T — super coverage

Per-fighter `signature_lane_finisher` / `aura_burst_super_pose` with distinct pose templates (not one color-swap cinematic). Camera classes already exist; HUMAN cinematic approval stays false.

## U — Aura Clash coverage

Acting hooks `clash_start/lock/push/winning/losing/break` generated per fighter. Director + mixed-identity presets remain. `HUMAN_AURA_CLASH_PASS=false`.

## V — generated-art manifest

`artifacts/vxp3/reports/GENERATED_PRODUCTION_ART_MANIFEST.json`

Every asset: generator, version, source_master, sha256 (GLB), `GENERATED_PRODUCTION_*`, `future_human_replaceable=true`.

## W — performance results

No Pixel profile this pass (no device attached). Art is low-poly segmented meshes + short VFX/audio. Do not treat as `PIXEL_*_PASS`. Motion was not deleted for perf.

## X — APK path + SHA256

Not built this pass. `export_presets.cfg` has Android/gradle, but no device and no owner-review APK export was completed. Path target remains `anime-aggressors-generated-production-art-owner-review.apk` when a human/CI Android export runs. RC1 not touched. `adb install -r` not run.

## Y — owner / human gate states

| Gate | Value |
|------|-------|
| GENERATED_PRODUCTION_MODEL_ROSTER_PASS | true (automated) |
| GENERATED_PRODUCTION_RIG_ROSTER_PASS | true (automated) |
| GENERATED_PRODUCTION_MATERIAL_ROSTER_PASS | true (automated) |
| GENERATED_PRODUCTION_ANIMATION_ROSTER_PASS | true (automated) |
| GENERATED_PRODUCTION_HURT_ROSTER_PASS | true (automated) |
| GENERATED_PRODUCTION_CHARGE_ROSTER_PASS | true (automated) |
| GENERATED_PRODUCTION_SECONDARY_ROSTER_PASS | true (automated) |
| GENERATED_PRODUCTION_VFX_ROSTER_PASS | true (automated) |
| GENERATED_PRODUCTION_AUDIO_ROSTER_PASS | true (automated) |
| GENERATED_PRODUCTION_SUPER_ROSTER_PASS | true (automated) |
| GENERATED_PRODUCTION_AURA_CLASH_PASS | true (automated) |
| GENERATED_PRODUCTION_ART_PASS | true (automated only) |
| HUMAN_AUTHORED_ART_PASS | false |
| HUMAN_AUTHORED_ANIMATION_PASS | false |
| HUMAN_ART_DIRECTION_APPROVAL | false |
| HUMAN_ANIMATION_QUALITY_PASS | false |
| HUMAN_COMBAT_FEEL_PASS | false |
| HUMAN_AURA_CLASH_PASS | false |
| HUMAN_CLIP_WORTHY_PASS | false |
| MERGE_AUTHORIZED | false |
| FINAL_AUTHORED_ANIMATION_PASS | false |

Owner questions 1–12 unanswered. Review stills: `artifacts/vxp3/review/generated_production/<id>/*.png`.

## Z — remaining defects / next human step

Defects:

1. Meshes are mannequin blockouts with floating accessory cubes — not finished anime characters.
2. No Pixel install / combat recording / APK.
3. Git LFS still cannot push `.blend` masters.
4. Owner visual/feel gates cannot be automated.

**Exact next human step:** Open PR #106 review stills (especially idle + heavy_contact + hurt_heavy + charge_100 for all seven). Answer owner questions 1–12. If the mannequin roster is acceptable as generated production while planning v1.1 human art, say so explicitly. Do **not** set HUMAN_* / MERGE_AUTHORIZED until that answer. Then export/install `anime-aggressors-generated-production-art-owner-review.apk` with `adb install -r` (do not uninstall, do not touch RC1).
