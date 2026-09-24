#!/usr/bin/env python3
"""One-command action export.

python3 tools/authored_animation/export_action.py --fighter rook-ironside --action heavy
Never marks AUTHORED_APPROVED.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

from aa_common import (
    AUTOMATION_MAY_WRITE,
    FIGHTER_IDS,
    GODOT_AUTHORED,
    PRODUCTION_ACTIONS,
    ROOT,
    empty_provenance,
    find_blender,
    frame_window,
    load_json,
    master_blend,
    write_json,
)

VALID_ACTIONS = {a[0] for a in PRODUCTION_ACTIONS} | {"pipeline_proof"}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--fighter", required=True)
    parser.add_argument("--action", required=True)
    parser.add_argument("--blender-bin", default="")
    args = parser.parse_args()
    fid = args.fighter
    action = args.action
    fails = []
    if fid not in FIGHTER_IDS:
        fails.append(f"unknown_fighter:{fid}")
    if action not in VALID_ACTIONS:
        fails.append(f"unknown_action:{action}")
    blend = master_blend(fid)
    if not blend.is_file():
        alt = ROOT / "art_source/animation/fighters" / fid / "source" / f"{fid}_pipeline_proof.blend"
        blend = alt if alt.is_file() else blend
    if not blend.is_file():
        fails.append(f"missing_source_blend:{blend}")
        fails.append("BLENDER_SOURCE_STORAGE_SETUP_REQUIRED")
    blender = args.blender_bin or find_blender()
    if not blender:
        fails.append("blender_not_found")
    godot_glb = GODOT_AUTHORED / fid / f"{action}.glb"
    export_glb = ROOT / "art_source/animation/fighters" / fid / "export" / f"{action}.glb"
    report = ROOT / "artifacts/vxp3/authored" / f"{fid}_{action}_export.json"
    if fails:
        write_json(report, {"ok": False, "failures": fails, "status": "MISSING"})
        print(json.dumps({"ok": False, "failures": fails}, indent=2))
        return 2
    cmd = [
        blender,
        "--background",
        str(blend),
        "--python",
        str(ROOT / "tools/authored_animation/blender/aa_export_action.py"),
        "--",
        "--action",
        action,
        "--out-glb",
        str(export_glb),
        "--report",
        str(report),
    ]
    proc = subprocess.run(cmd, cwd=ROOT, check=False)
    if proc.returncode != 0:
        return proc.returncode
    if export_glb.is_file():
        godot_glb.parent.mkdir(parents=True, exist_ok=True)
        godot_glb.write_bytes(export_glb.read_bytes())
    win = frame_window(fid, action)
    sidecar = empty_provenance(
        fid,
        action,
        {
            "exported_glb": str(godot_glb.relative_to(ROOT)) if godot_glb.is_file() else "",
            "status": "AUTHORED_WIP" if godot_glb.is_file() and int((load_json(report) or {}).get("keyframe_count", 0) or 0) > 0 else "MISSING",
            "source_blend": str(blend.relative_to(ROOT)),
            "notes": "Export produced. Human review still required. Automation must not set AUTHORED_APPROVED.",
            "contact_frame": win.get("contact_frame", 0),
            "active_start": win.get("active_start", 0),
            "active_end": win.get("active_end", 0),
        },
    )
    if sidecar["status"] not in AUTOMATION_MAY_WRITE:
        sidecar["status"] = "AUTHORED_WIP"
    sidecar["human_animation_approved"] = False
    sidecar["pose_bible_approved"] = False
    write_json(godot_glb.with_suffix(".provenance.json"), sidecar)
    write_json(
        ROOT / "art_source/animation/fighters" / fid / "actions" / action / "ACTION.json",
        {
            "fighter_id": fid,
            "action_id": action,
            "runtime_clip": action,
            "status": sidecar["status"],
            "authored_source": str(blend.relative_to(ROOT)),
            "export_glb": sidecar["exported_glb"] or None,
            "not_final_art": True,
            "human_approved": False,
        },
    )
    # Optional Godot import dry-run if GODOT_BIN is set.
    godot = find_godot()
    import_ok = None
    if godot and godot_glb.is_file():
        import_ok = subprocess.run(
            [godot, "--headless", "--path", str(ROOT / "game-godot"), "--import", "--quit"],
            cwd=ROOT,
            check=False,
        ).returncode == 0
    payload = {
        "ok": godot_glb.is_file(),
        "fighter": fid,
        "action": action,
        "glb": str(godot_glb.relative_to(ROOT)) if godot_glb.is_file() else "",
        "provenance": str(godot_glb.with_suffix(".provenance.json").relative_to(ROOT)),
        "status": sidecar["status"],
        "human_animation_approved": False,
        "godot_import": import_ok,
        "not_final_art": True,
    }
    print(json.dumps(payload, indent=2))
    return 0 if payload["ok"] else 1


def find_godot() -> str | None:
    import os
    import shutil

    candidates = (
        os.environ.get("GODOT_BIN"),
        shutil.which("godot"),
        "/Applications/Godot.app/Contents/MacOS/Godot",
    )
    for c in candidates:
        if c and Path(c).is_file():
            return c
    return None


if __name__ == "__main__":
    raise SystemExit(main())
