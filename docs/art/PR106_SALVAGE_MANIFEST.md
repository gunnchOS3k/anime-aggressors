# PR #106 salvage classification

Source head: `8cd3e1359f11644787c79de4a6f03e17dbf1ec56`. Accepted main: `6cd1b310`.

| Path | Class | Reason | Destination | Shipping | Resolver |
|------|-------|--------|-------------|----------|----------|
| `art_source/animation/shared/deform_skeleton/CANONICAL_DEFORM_SKELETON.json` | SALVAGE | canonical deform skeleton | same | none | none |
| `art_source/animation/CONTRACT.md` | REIMPLEMENT_CLEANLY | strip generated-shipping assumptions | same | none | none |
| `docs/animation/HUMAN_ART_REPLACEMENT_CONTRACT.md` | REIMPLEMENT_CLEANLY | generated art does not ship | same | none | none |
| `tools/generated_production_art/review_cameras_v4.py` | REIMPLEMENT_CLEANLY | generic cameras without generated package | tools/art_pipeline/human_art/cameras.py | none | none |
| `tools/generated_art_v9/validate_attachment_integrity.py` | REIMPLEMENT_CLEANLY | drop V9 object names | tools/art_pipeline/human_art/validate_attachments.py | none | none |
| `tools/generated_art_v9/impact_pair_solver.py` | REIMPLEMENT_CLEANLY | review-only generic anchors | tools/art_pipeline/human_art/impact_review.py | none | none |
| `game-godot/scripts/menus/character_select_framing.gd` | SALVAGE | Kaia accessory-width / full-body framing | same | framing only | none |
| `game-godot/scripts/visual/fighter_asset_resolver.gd` | REIMPLEMENT_CLEANLY | reject generated roster; add ACTIVE_CHARACTER_PRESENTATION; isolate staging | same | preserves accepted art | blocks generated V2–V9 |
| `game-godot/scripts/fighters/fighter_model_3d.gd` | SALVAGE | headless/dummy never calls texture_2d_get; structural vs pixel evidence | same | visibility evidence only | none |
| `tools/authored_animation/*` | SALVAGE | generic validators / submit-check | tools/authored_animation | none | none |
| `art_source/generated/**` | EXPERIMENT_ONLY | generated masters | remain on PR #106 | excluded | none |
| `game-godot/content/fighters/**/ *_generated_production.glb` | EXPERIMENT_ONLY | generated shipping copies | remain on PR #106 | excluded | blocked |
| `artifacts/vxp3/**` | DROP | giant review packets | reference PR #106 | excluded | none |
| `tools/generated_art_v5..v9/**` | EXPERIMENT_ONLY | generator implementation | remain on PR #106 | excluded | none |
| `game-godot/scripts/combat/*clash*` | DROP | gameplay change not authorized | remain on PR #106 | excluded | none |
| `docs/art/CHARACTER_ART_DIRECTION_CONTRACT.md` | ALREADY_ON_MAIN | accepted identity | unchanged | none | none |
| `game-godot/content/fighters/**/_procedural_proxy.glb` | ALREADY_ON_MAIN | current accepted art | unchanged | shipping | still selected |
| `prefix artifacts/vxp3 (~2490 files)` | DROP | review PNGs / v9 reports | PR #106 | excluded | none |
| `prefix game-godot/content generated (~1554)` | EXPERIMENT_ONLY | generated runtime copies | PR #106 | excluded | blocked |
| `prefix content/fighters generated (~742)` | EXPERIMENT_ONLY | generated content tree | PR #106 | excluded | blocked |
| `prefix tools/generated_* (~152)` | EXPERIMENT_ONLY | V5–V9 generators | PR #106 | excluded | none |

Unlisted #106 files follow the prefix rules above. No unexplained copy.
