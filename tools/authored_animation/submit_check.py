#!/usr/bin/env python3
"""Animator submission validator. Never promotes HUMAN_APPROVED."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from aa_common import FIGHTER_IDS, GODOT_AUTHORED, ROOT, load_json, master_blend, write_json


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
    action_json = ROOT / "art_source/animation/fighters" / fid / "actions" / action / "ACTION.json"
    sidecar = GODOT_AUTHORED / fid / f"{action}.provenance.json"
    glb = GODOT_AUTHORED / fid / f"{action}.glb"
    staging = ROOT / "game-godot/content/human_art_staging" / fid / f"{fid}.glb"
    prov = load_json(sidecar) if sidecar.is_file() else {}
    if prov.get("status") in ("AUTHORED_APPROVED", "HUMAN_APPROVED"):
        fails.append("WIP_CANNOT_MASQUERADE_AS_APPROVED")
    if bool(prov.get("human_animation_approved")):
        fails.append("automation_or_submit_cannot_set_human_approved")
    if bool(prov.get("root_motion_authoritative")):
        fails.append("root_motion_authority_forbidden")
    payload = {
        "ok": not fails,
        "failures": fails,
        "fighter": fid,
        "action": action,
        "source_exists": blend.is_file(),
        "action_exists": action_json.is_file(),
        "provenance_exists": sidecar.is_file(),
        "glb_exists": glb.is_file() or staging.is_file(),
        "status": prov.get("status", "MISSING"),
        "human_animation_approved": False,
        "note": "Submit-check never promotes status to HUMAN_APPROVED.",
    }
    write_json(ROOT / "artifacts/art_pipeline" / f"SUBMIT_CHECK_{fid}_{action}.json", payload)
    print(json.dumps(payload, indent=2))
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
