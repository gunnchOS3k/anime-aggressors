#!/usr/bin/env python3
"""Attachment integrity validator. Structural + posed blender probe."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT / "tools") not in sys.path:
    sys.path.insert(0, str(ROOT / "tools"))

from generated_art_v9.attachment_map import classify_name  # noqa: E402
from generated_art_v9.body_profiles import FIGHTER_IDS, load_attachment_table  # noqa: E402
from generated_production_art.common import find_blender, production_master_blend, write_json  # noqa: E402

REPORTS = ROOT / "artifacts/vxp3/reports"
OUT = REPORTS / "GENERATED_ART_V9_ATTACHMENT_INTEGRITY.json"
STRESS_POSES = load_attachment_table().get("stress_actions") or []
MAX_RIGID = 0.26
MAX_CHAIN = 0.32


def _master(fid: str) -> dict:
    path = ROOT / "art_source/generated/production" / fid / "master_report.json"
    if not path.is_file():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def _structural(fid: str) -> dict:
    report = _master(fid)
    geom = report.get("geometry") or report
    attachments = list(geom.get("attachments") or [])
    rows = []
    fails = []
    unclassified = 0
    floating = 0
    for row in attachments:
        name = str(row.get("name") or "")
        cls = str(row.get("class") or "")
        bone = str(row.get("bone") or "")
        classified = classify_name(name)
        if classified is None:
            unclassified += 1
            fails.append(f"{name}:unclassified")
            continue
        expect_cls, expect_bone, floating_flag = classified
        if cls and cls != expect_cls:
            fails.append(f"{name}:class {cls}!={expect_cls}")
        if expect_cls == "WORLD_STATIC":
            fails.append(f"{name}:costume_world_static")
        if expect_cls != "SKINNED_COSTUME" and expect_bone and bone and bone != expect_bone:
            fails.append(f"{name}:bone {bone}!={expect_bone}")
        if floating_flag:
            floating += 1
        rows.append(
            {
                "name": name,
                "class": expect_cls,
                "owning_bone": expect_bone or bone,
                "rest_anchor_distance": row.get("rest_anchor_distance"),
                "intentional_floating": floating_flag,
            }
        )
    if not attachments:
        fails.append("no_attachment_records")
    return {
        "fighter": fid,
        "attachments": rows,
        "unclassified": unclassified,
        "intentional_floating": floating,
        "fails": fails,
        "ok": not fails and unclassified == 0,
    }


def _posed_blender() -> dict:
    blender = find_blender()
    if not blender:
        return {"ok": False, "reason": "blender_missing", "fighters": {}}
    script = ROOT / "tools/generated_art_v9/blender/gp_validate_attachments.py"
    if not script.is_file():
        return {"ok": False, "reason": "validator_script_missing", "fighters": {}}
    fighters = {}
    for fid in FIGHTER_IDS:
        blend = production_master_blend(fid).resolve()
        if not blend.is_file():
            fighters[fid] = {"ok": False, "reason": "blend_missing"}
            continue
        out = REPORTS / f"GENERATED_ART_V9_ATTACHMENT_{fid}.json"
        proc = subprocess.run(
            [blender, "--background", str(blend), "--python", str(script), "--", "--fighter", fid, "--out", str(out)],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )
        payload = json.loads(out.read_text(encoding="utf-8")) if out.is_file() else {"ok": False, "stderr": (proc.stderr or "")[-800:]}
        fighters[fid] = payload
    return {"ok": all(row.get("ok") for row in fighters.values()), "blender": blender, "fighters": fighters}


def validate() -> dict:
    REPORTS.mkdir(parents=True, exist_ok=True)
    structural = {fid: _structural(fid) for fid in FIGHTER_IDS}
    posed = _posed_blender()
    fails = []
    for fid, row in structural.items():
        fails.extend(f"{fid}:{item}" for item in row.get("fails") or [])
        if not row.get("ok"):
            fails.append(f"{fid}:structural")
    posed_ok = bool(posed.get("ok"))
    if posed.get("reason") == "blender_missing":
        posed_ok = False
        fails.append("posed:blender_missing")
    elif not posed_ok:
        fails.append("posed:fail")
    unintentional = 0
    for fid, row in (posed.get("fighters") or {}).items():
        unintentional += int(row.get("unintentional_floating") or 0)
        if row.get("ok") is False:
            fails.append(f"{fid}:posed")
    payload = {
        "ok": not fails and unintentional == 0,
        "GEN_ART_V9_ATTACHMENT_INTEGRITY_PASS": not fails and unintentional == 0,
        "UNINTENTIONAL_FLOATING_ART_PARTS": unintentional,
        "stress_actions": STRESS_POSES,
        "max_rigid_displacement_m": MAX_RIGID,
        "max_chain_displacement_m": MAX_CHAIN,
        "structural": structural,
        "posed": posed,
        "fails": fails,
        "human_authored": False,
    }
    write_json(OUT, payload)
    return payload


if __name__ == "__main__":
    print(json.dumps(validate(), indent=2))
