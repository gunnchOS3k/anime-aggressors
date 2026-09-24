#!/usr/bin/env python3
"""Generate ready-to-animate master .blend files (local). Gitignored until LFS auth."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

from aa_common import FIGHTER_IDS, ROOT, find_blender, master_blend, write_json

SCRIPT = ROOT / "tools/authored_animation/blender/aa_build_animation_master.py"


def main() -> int:
    blender = find_blender()
    if not blender:
        print("Blender not found", file=sys.stderr)
        return 2
    reports = []
    for fid in FIGHTER_IDS:
        blend = master_blend(fid)
        report = ROOT / "artifacts/vxp3/authored" / f"{fid}_animation_master.json"
        cmd = [
            blender,
            "--background",
            "--factory-startup",
            "--python",
            str(SCRIPT),
            "--",
            "--fighter",
            fid,
            "--out-blend",
            str(blend),
            "--report",
            str(report),
        ]
        print("RUN", fid, flush=True)
        proc = subprocess.run(cmd, cwd=ROOT, check=False)
        reports.append(
            {
                "fighter": fid,
                "ok": proc.returncode == 0 and blend.is_file(),
                "blend": str(blend.relative_to(ROOT)) if blend.is_file() else "",
                "bytes": blend.stat().st_size if blend.is_file() else 0,
            }
        )
        if proc.returncode != 0:
            return proc.returncode
    payload = {
        "ok": all(r["ok"] for r in reports),
        "blender": blender,
        "fighters": reports,
        "committed": False,
        "reason": "art_source/animation/**/*.blend is gitignored until LFS remote auth exists",
        "not_final_art": True,
        "MESH_BINDING_NEEDS_HUMAN_WEIGHT_PAINT": True,
    }
    write_json(ROOT / "artifacts/vxp3/reports/ANIMATION_MASTERS.json", payload)
    print(json.dumps(payload, indent=2))
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
