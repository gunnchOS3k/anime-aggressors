#!/usr/bin/env python3
"""Synthetic BVH fixture preview on procedural fighter (Wave013B fixture chain)."""
from __future__ import annotations

import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def main() -> int:
    steps = []
    ok = True
    for name, cmd in [
        ("normalize_fixture", [ "python3", "tools/motion_pipeline/user_upload/normalize_motion.py", "--fixture-bvh"]),
        ("retarget_ready", [ "python3", "tools/motion_pipeline/user_upload/retarget/retarget_to_canonical.py"]),
    ]:
        proc = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
        steps.append({"step": name, "exit_code": proc.returncode})
        ok = ok and proc.returncode == 0

    preview = {
        "classification": "SYNTHETIC_RETARGET_PREVIEW",
        "target_model": "content/fighters/ember-vale/model/ember-vale_procedural_proxy.glb",
        "fixture_only": True,
        "REAL_USER_MOTION_USED": False,
        "EDMUND_PERSONAL_MOTION_USED": False,
    }
    out = {
        "pass": ok,
        "SYNTHETIC_BVH_TO_PROCEDURAL_FIGHTER_PREVIEW_PASS": ok,
        "steps": steps,
        "preview": preview,
    }
    dest = ROOT / "artifacts/engineering_wave014/SYNTHETIC_BVH_PREVIEW.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
