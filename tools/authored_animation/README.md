# Authored animation tools

Reusable infrastructure only. These scripts never set `HUMAN_*`, `AUTHORED_APPROVED`, or `MERGE_AUTHORIZED`.

```bash
python3 tools/authored_animation/validate_deform_skeleton.py
python3 tools/authored_animation/validate_provenance.py
python3 tools/authored_animation/submit_check.py --fighter rook-ironside --action heavy
npm run art:validate-human -- --fighter rook-ironside --asset <path>
npm run art:review-human -- --fighter rook-ironside --asset <path>
```

Production Blender: **3.3.1**. `BLENDER_BIN` or `/Applications/Blender.app/Contents/MacOS/Blender`.

Parameterize every tool for arbitrary human-authored meshes. Do not assume generated V2–V9 object names.
