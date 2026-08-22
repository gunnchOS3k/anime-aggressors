# Ember Vale Free Art Pipeline Vertical Slice

Milestone token: `EMBER_FREE_ART_PIPELINE_VERTICAL_SLICE_PASS` is **PARTIAL** until human VRoid GUI art lands.

## Pipeline stages

| Stage | Status |
|-------|--------|
| brief | PASS (docs) |
| authored/generated model source | `HUMAN_GUI_REQUIRED` / anyCreature pilot LIMITED |
| Blender cleanup automation | PASS (scripts present; Blender 3.3 CLI smoke) |
| canonical rig | PASS (spec + validator) |
| animations | `REQUIRES_ART_PRODUCTION` (choreography authored) |
| GLB | existing procedural_final proxy only — not final VRoid art |
| Godot import | PASS for existing procedural assets |
| hitbox/hurtbox alignment | PASS hooks on current runtime |
| aura/VFX/SFX/camera hooks | PASS (juice contract + CombatFeedback deepen) |
| playable BattleScene | PASS (Wave011 accepted main) |

## Truthful flags
- `EMBER_MODEL_SOURCE=HUMAN_GUI_REQUIRED`
- `EMBER_DIGITAL_PREPARATION_PASS=true`
- `EMBER_FINAL_ART_RUNTIME_PASS=false`
