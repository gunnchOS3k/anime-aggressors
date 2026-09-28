#!/usr/bin/env python3
"""Animator submission validator.

npm run anim:submit-check -- --fighter rook-ironside --action heavy
Status remains AUTHORED_WIP until a human approves.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from aa_common import (
    FIGHTER_IDS,
    GODOT_AUTHORED,
    ROOT,
    frame_window,
    load_json,
    master_blend,
    write_json,
)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--fighter", required=True)
    parser.add_argument("--action", required=True)
    args = parser.parse_args()
    fid, action = args.fighter, args.action
    fails = []
    if fid not in FIGHTER_IDS:
        fails.append("unknown_fighter")
    blend = master_blend(fid)
    if not blend.is_file():
        fails.append("source_blend_missing_or_lfs_blocked")
    action_json = ROOT / "art_source/animation/fighters" / fid / "actions" / action / "ACTION.json"
    if not action_json.is_file():
        fails.append("action_sidecar_missing")
    sidecar = GODOT_AUTHORED / fid / f"{action}.provenance.json"
    glb = GODOT_AUTHORED / fid / f"{action}.glb"
    prov = load_json(sidecar) if sidecar.is_file() else {}
    if not sidecar.is_file():
        fails.append("provenance_sidecar_missing")
    if prov.get("status") == "AUTHORED_APPROVED":
        fails.append("WIP_CANNOT_MASQUERADE_AS_APPROVED")
    if bool(prov.get("human_animation_approved")):
        fails.append("automation_or_submit_cannot_set_human_approved")
    win = frame_window(fid, action)
    contact = int(prov.get("contact_frame", win.get("contact_frame") or 0) or 0)
    active_start = int(prov.get("active_start", win.get("active_start") or 0) or 0)
    active_end = int(prov.get("active_end", win.get("active_end") or 0) or 0)
    if contact and active_start and active_end:
        if contact < active_start - 2 or contact > active_end + 2:
            fails.append("contact_frame_outside_active_window")
    if bool(prov.get("root_motion_authoritative")):
        fails.append("root_motion_authority_forbidden")
    renders = ROOT / "artifacts/animation_review" / fid / action
    render_ok = renders.is_dir() and any(renders.glob("*.png"))
    payload = {
        "ok": not fails,
        "failures": fails,
        "fighter": fid,
        "action": action,
        "source_exists": blend.is_file(),
        "action_exists": action_json.is_file(),
        "provenance_exists": sidecar.is_file(),
        "glb_exists": glb.is_file(),
        "contact_sync": "contact_frame_outside_active_window" not in fails,
        "preview_renders": render_ok,
        "status": prov.get("status", "MISSING"),
        "human_animation_approved": False,
        "note": "Submit-check never promotes status to AUTHORED_APPROVED.",
    }
    write_json(ROOT / "artifacts/vxp3/reports" / f"SUBMIT_CHECK_{fid}_{action}.json", payload)
    print(json.dumps(payload, indent=2))
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
