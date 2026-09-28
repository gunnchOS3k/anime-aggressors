#!/usr/bin/env python3
"""Run Blender pipeline-proof export for all seven fighters."""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "tools" / "authored_animation" / "blender" / "aa_build_pipeline_proof.py"
FIGHTERS = (
    "ember-vale",
    "rook-ironside",
    "juno-spark",
    "kaia-windrow",
    "nix-calder",
    "orion-vell",
    "vesper-nyx",
)


def find_blender() -> str | None:
    candidates = (
        os.environ.get("BLENDER_BIN"),
        shutil.which("blender"),
        "/Applications/Blender.app/Contents/MacOS/Blender",
        str(Path.home() / "Applications" / "Blender.app" / "Contents" / "MacOS" / "Blender"),
    )
    for c in candidates:
        if c and Path(c).is_file():
            return c
    return None


def main() -> int:
    blender = find_blender()
    if not blender:
        print("Blender not found", file=sys.stderr)
        return 2
    reports = []
    for fid in FIGHTERS:
        export_dir = ROOT / "art_source" / "animation" / "fighters" / fid / "export"
        godot_dir = ROOT / "game-godot" / "assets" / "characters" / "authored" / fid
        source_dir = ROOT / "art_source" / "animation" / "fighters" / fid / "source"
        export_dir.mkdir(parents=True, exist_ok=True)
        godot_dir.mkdir(parents=True, exist_ok=True)
        source_dir.mkdir(parents=True, exist_ok=True)
        glb = export_dir / "pipeline_proof.glb"
        blend = source_dir / f"{fid}_pipeline_proof.blend"
        report = ROOT / "artifacts" / "vxp3" / "authored" / f"{fid}_pipeline_proof.json"
        cmd = [
            blender,
            "--background",
            "--factory-startup",
            "--python",
            str(SCRIPT),
            "--",
            "--fighter",
            fid,
            "--out-glb",
            str(glb),
            "--out-blend",
            str(blend),
            "--report",
            str(report),
        ]
        print("RUN", " ".join(cmd), flush=True)
        proc = subprocess.run(cmd, cwd=ROOT, check=False)
        if proc.returncode != 0:
            return proc.returncode
        dest = godot_dir / "pipeline_proof.glb"
        if glb.is_file():
            dest.write_bytes(glb.read_bytes())
        reports.append(
            {
                "fighter_id": fid,
                "glb": str(glb.relative_to(ROOT)),
                "godot": str(dest.relative_to(ROOT)),
                "bytes": glb.stat().st_size if glb.is_file() else 0,
                "ok": glb.is_file(),
            }
        )
    out = {
        "ok": all(r["ok"] for r in reports),
        "blender": blender,
        "fighters": reports,
        "not_final_art": True,
        "status": "AUTHORED_WIP",
        "human_approved": False,
    }
    dest = ROOT / "artifacts" / "vxp3" / "reports" / "AUTHORED_EXPORT_IMPORT.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(out, indent=2) + "\n")
    print(json.dumps(out, indent=2))
    return 0 if out["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
