# Post-#116 authored-animation CI migration

## Cause

PR #116 forward-ported `.github/workflows/authored-animation-production.yml` from the VXP3 / #106 line. That workflow still called:

- `tools/generated_production_art/tests/test_body_v2.py`
- `generated_production_art.validate_geometry_v2`

`tools/generated_*` was classified **EXPERIMENT_ONLY** in `docs/art/PR106_SALVAGE_MANIFEST.md` and was intentionally not salvaged onto main. CI failed with `No such file or directory`.

## Replacement (semantic coverage)

| Obsolete (generated art) | Current-main equivalent |
|--------------------------|-------------------------|
| `test_body_v2.py` (roster body recipe unit checks) | `tools/authored_animation/validate_deform_skeleton.py` (canonical deform skeleton + authored proof GLBs) |
| `validate_geometry_v2` (cohesive body / skinning reports) | `tools/authored_animation/audit_mesh_deform.py` (proxy + authored proof skins / WEIGHTS_0; not final art) |

Human / originality / final-art gates remain false. Blender LFS setup remains owner-required.

## Guardrail

`tools/authored_animation/audit_workflow_referenced_paths.py` fails CI when a workflow `run:` step references a missing repo file (`WORKFLOW_REFERENCED_PATHS_EXIST_PASS`).
