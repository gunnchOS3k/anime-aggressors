# Authored animation tools

```bash
python3 tools/authored_animation/generate_source_layout.py
python3 tools/authored_animation/build_production_program.py
python3 tools/authored_animation/build_animation_masters.py
python3 tools/authored_animation/run_pipeline_proof.py
python3 tools/authored_animation/export_action.py --fighter rook-ironside --action heavy
python3 tools/authored_animation/validate_deform_skeleton.py
python3 tools/authored_animation/validate_export_import.py
python3 tools/authored_animation/validate_provenance.py
python3 tools/authored_animation/validate_production_infra.py
python3 tools/authored_animation/audit_mesh_deform.py
python3 tools/authored_animation/emit_authored_gates.py
npm run anim:preview -- --fighter rook-ironside --action heavy
npm run anim:render-review -- --fighter rook-ironside --action heavy
npm run anim:submit-check -- --fighter rook-ironside --action heavy
```

Production Blender: **3.3.1** (`ANIMATION_PRODUCTION_BLENDER_VERSION=3.3.1`).
`BLENDER_BIN` or `/Applications/Blender.app/Contents/MacOS/Blender`.

These scripts configure the pipeline and may emit `AUTHORED_WIP` pose-blocks. They never set `AUTHORED_APPROVED` or `HUMAN_*` gates.
