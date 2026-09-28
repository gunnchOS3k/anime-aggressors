#!/usr/bin/env python3
"""CI for authored-animation production infrastructure.

Does not require unavailable .blend files. Fails with a truthful LFS setup gate.
Never auto-passes HUMAN_* or AUTHORED_APPROVED.
"""
from __future__ import annotations

import json
import subprocess
from pathlib import Path

from aa_common import (
    ANIM,
    AUTOMATION_MAY_WRITE,
    CANONICAL_BONES,
    FIGHTER_IDS,
    GODOT_AUTHORED,
    PRODUCTION_ACTIONS,
    ROOT,
    load_json,
)

SKEL = ROOT / "art_source/animation/shared/deform_skeleton/CANONICAL_DEFORM_SKELETON.json"


def lfs_upload_ready() -> bool:
    try:
        env = subprocess.check_output(["git", "lfs", "env"], cwd=ROOT, text=True)
    except Exception:
        return False
    return "AccessUpload=basic" in env or "AccessUpload=lfs-standalone-file" in env


def gitattributes_ok() -> bool:
    text = (ROOT / ".gitattributes").read_text()
    return "*.blend filter=lfs" in text


def main() -> int:
    fails = []
    warns = []
    if not gitattributes_ok():
        fails.append("gitattributes_missing_blend_lfs")
    lfs = lfs_upload_ready()
    if not lfs:
        warns.append("BLENDER_SOURCE_STORAGE_SETUP_REQUIRED")
    skel = load_json(SKEL)
    bones = tuple(skel.get("required_bones", ()))
    if bones != CANONICAL_BONES:
        fails.append("canonical_bones_mismatch")
    board = load_json(ANIM / "manifests" / "WAVE_A_PRODUCTION_98.json")
    actions = board.get("actions", [])
    if len(actions) != 98:
        fails.append(f"production_board_count:{len(actions)}")
    approved = [a for a in actions if a.get("status") == "AUTHORED_APPROVED" or a.get("human_approved")]
    if approved:
        fails.append("WIP_CANNOT_MASQUERADE_AS_APPROVED")
    for fid in FIGHTER_IDS:
        layout = ANIM / "fighters" / fid
        for sub in ("source", "pose_bible", "actions", "export"):
            if not (layout / sub).exists():
                fails.append(f"missing_layout:{fid}/{sub}")
        proof = GODOT_AUTHORED / fid / "pipeline_proof.glb"
        if not proof.is_file():
            fails.append(f"missing_pipeline_proof_glb:{fid}")
        sidecar = GODOT_AUTHORED / fid / "pipeline_proof.json"
        if sidecar.is_file():
            status = load_json(sidecar).get("status")
            if status == "AUTHORED_APPROVED":
                fails.append(f"proof_masquerades_approved:{fid}")
            if status not in AUTOMATION_MAY_WRITE and status != "AUTHORED_WIP":
                fails.append(f"bad_proof_status:{fid}:{status}")
        for action_id, _rt, _brief in PRODUCTION_ACTIONS:
            act = layout / "actions" / action_id / "ACTION.json"
            if not act.is_file():
                fails.append(f"missing_action_sidecar:{fid}.{action_id}")
            else:
                row = load_json(act)
                if row.get("status") == "AUTHORED_APPROVED":
                    fails.append(f"action_masquerades_approved:{fid}.{action_id}")
                if row.get("human_approved"):
                    fails.append(f"human_approved_set_by_automation:{fid}.{action_id}")
    gates = load_json(ROOT / "artifacts/vxp3/reports/VXP3_AUTHORED_ANIMATION_GATES.json")
    for key in (
        "HUMAN_ANIMATION_QUALITY_PASS",
        "HUMAN_COMBAT_FEEL_PASS",
        "HUMAN_AURA_CLASH_PASS",
        "HUMAN_CLIP_WORTHY_PASS",
        "MERGE_AUTHORIZED",
        "FINAL_AUTHORED_ANIMATION_PASS",
    ):
        if bool(gates.get(key)):
            fails.append(f"human_gate_auto_pass:{key}")
    payload = {
        "ok": not fails,
        "failures": fails,
        "warnings": warns,
        "BLENDER_SOURCE_STORAGE_SETUP_REQUIRED": not lfs,
        "lfs_upload_ready": lfs,
        "not_final_art": True,
    }
    out = ROOT / "artifacts/vxp3/reports/AUTHORED_PRODUCTION_INFRA.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps(payload, indent=2))
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
