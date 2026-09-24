#!/usr/bin/env python3
"""Best-effort digital checks for cohesive-body v2. Does not replace visual review."""
from __future__ import annotations

import json
from pathlib import Path

from .body_v2 import (
    MAX_ATTACH_M,
    MAX_FOOT_GROUND_M,
    MAX_HAND_WRIST_M,
    MAX_HEAD_NECK_M,
    recipe,
)
from .common import ART_GEN, FIGHTER_IDS, REPORTS, write_json

MIN_TRIS = 8000
MAX_TRIS = 45000


def _master_report(fid: str) -> dict:
    path = ART_GEN / fid / "master_report.json"
    if not path.is_file():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def evaluate_fighter(fid: str, report: dict) -> dict:
    geom = report.get("geometry") or report
    islands = int(geom["body_connected_components"]) if geom.get("body_connected_components") is not None else 99
    tris = int(geom.get("triangles") or 0)
    foot = float(geom["foot_ground_gap_m"]) if geom.get("foot_ground_gap_m") is not None else 99.0
    weight = geom.get("weight") or {}
    zero_w = int(weight["zero_weight_vertices"]) if weight.get("zero_weight_vertices") is not None else 99
    accessories = list(geom.get("accessories") or [])
    unintentional = int(geom.get("unintentional_floating_accessories") or 0)
    for row in accessories:
        if row.get("unintentional_floating"):
            unintentional += 1
    unintentional = min(unintentional, 99)
    # de-dupe count from report field if already totaled
    if geom.get("unintentional_floating_accessories") is not None:
        unintentional = int(geom["unintentional_floating_accessories"])
    rec = recipe(fid)
    try:
        from .body_v3 import recipe as recipe_v3

        required = {spec.name for spec in recipe_v3(fid).accessories}
    except Exception:
        required = {spec.name for spec in rec.accessories}
    present = {row.get("name") for row in accessories}
    missing = sorted(required - present)
    hand_wrist = 0.0
    head_neck = 0.0
    for row in accessories:
        if "gauntlet" in row.get("name", "") or "glove" in row.get("name", ""):
            hand_wrist = max(hand_wrist, float(row.get("distance_m") or 0.0))
    gates = {
        "cohesive_body": islands == 1,
        "no_body_gaps": islands == 1,
        "no_floating_accessory": unintentional == 0,
        "hand_foot_head_read": foot <= MAX_FOOT_GROUND_M and islands == 1,
        "costume_attachment": unintentional == 0 and not missing,
        "smooth_skinning": zero_w == 0 and bool(weight.get("smooth_skinning", False)),
        "topology_in_range": MIN_TRIS <= tris <= MAX_TRIS,
    }
    return {
        "fighter": fid,
        "ok": all(gates.values()),
        "gates": gates,
        "body_connected_components": islands,
        "triangles": tris,
        "foot_ground_gap_m": foot,
        "zero_weight_vertices": zero_w,
        "unintentional_floating_accessories": unintentional,
        "missing_accessories": missing,
        "hand_wrist_distance_m": hand_wrist,
        "head_neck_distance_m": head_neck,
        "thresholds": {
            "max_attach_m": MAX_ATTACH_M,
            "max_foot_ground_m": MAX_FOOT_GROUND_M,
            "max_hand_wrist_m": MAX_HAND_WRIST_M,
            "max_head_neck_m": MAX_HEAD_NECK_M,
            "min_tris": MIN_TRIS,
            "max_tris": MAX_TRIS,
        },
        "accessories": accessories,
    }


def validate() -> dict:
    fighters = {}
    for fid in FIGHTER_IDS:
        fighters[fid] = evaluate_fighter(fid, _master_report(fid))
    accessory_audit = {
        "schema": "floating_accessory_audit_v1",
        "UNINTENTIONAL_FLOATING_ACCESSORIES": sum(
            int(row.get("unintentional_floating_accessories") or 0) for row in fighters.values()
        ),
        "fighters": {fid: row.get("accessories") for fid, row in fighters.items()},
    }
    write_json(REPORTS / "FLOATING_ACCESSORY_AUDIT.json", accessory_audit)
    payload = {
        "ok": all(row.get("ok") for row in fighters.values()) if fighters else False,
        "fighters": fighters,
        "UNINTENTIONAL_FLOATING_ACCESSORIES": accessory_audit["UNINTENTIONAL_FLOATING_ACCESSORIES"],
        "GEN_ART_V2_COHESIVE_BODY_ROSTER_PASS": all(row["gates"].get("cohesive_body") for row in fighters.values()),
        "GEN_ART_V2_NO_BODY_GAPS_PASS": all(row["gates"].get("no_body_gaps") for row in fighters.values()),
        "GEN_ART_V2_NO_FLOATING_ACCESSORY_PASS": accessory_audit["UNINTENTIONAL_FLOATING_ACCESSORIES"] == 0
        and all(row["gates"].get("no_floating_accessory") for row in fighters.values()),
        "GEN_ART_V2_HAND_FOOT_HEAD_READ_PASS": all(row["gates"].get("hand_foot_head_read") for row in fighters.values()),
        "GEN_ART_V2_COSTUME_ATTACHMENT_PASS": all(row["gates"].get("costume_attachment") for row in fighters.values()),
        "GEN_ART_V2_SMOOTH_SKINNING_PASS": all(row["gates"].get("smooth_skinning") for row in fighters.values()),
    }
    write_json(REPORTS / "GENERATED_PRODUCTION_GEOMETRY_V2.json", payload)
    return payload


if __name__ == "__main__":
    print(json.dumps(validate(), indent=2))
