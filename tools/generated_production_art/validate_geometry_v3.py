#!/usr/bin/env python3
"""Digital v3 craft checks. Does not replace owner visual review."""
from __future__ import annotations

import json
from pathlib import Path

from .body_v3 import (
    MAX_ATTACH_M,
    MAX_FOOT_GROUND_M,
    MIN_BOOT_PARTS,
    MIN_COSTUME_PARTS,
    MIN_HAND_PARTS,
    MIN_HEAD_PARTS,
    recipe,
    roster_hand_hierarchy,
    shape_profile,
)
from .common import ART_GEN, FIGHTER_IDS, REPORTS, write_json
from .validate_geometry_v2 import validate as validate_v2

MIN_TRIS = 8000
MAX_TRIS = 45000
REQUIRED_HEAD_STYLES = {
    "ember-vale": "ember_crest_heat_mask",
    "rook-ironside": "plate_helm_void",
    "juno-spark": "arc_crown_cap",
    "kaia-windrow": "ribbon_veil",
    "nix-calder": "crystal_facet_mask",
    "orion-vell": "authority_orbit_halo",
    "vesper-nyx": "smoke_cowl_void",
}


def _master_report(fid: str) -> dict:
    path = ART_GEN / fid / "master_report.json"
    if not path.is_file():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def evaluate_fighter(fid: str, report: dict) -> dict:
    geom = report.get("geometry") or report
    shape = geom.get("shape_profile") or {}
    accessories = list(geom.get("accessories") or [])
    names = {row.get("name", "") for row in accessories}
    rec = recipe(fid)
    required = {spec.name for spec in rec.accessories}
    present_required = {name for name in required if any(name in (row.get("name") or "") for row in accessories)}
    missing = sorted(required - present_required)
    head_rows = [row for row in accessories if "head" in (row.get("name") or "")]
    hand_rows = [row for row in accessories if str(row.get("name", "")).startswith("hand_")]
    boot_rows = [row for row in accessories if str(row.get("name", "")).startswith("boot_")]
    costume_rows = [
        row
        for row in accessories
        if row.get("classification") in {"ARMOR", "CLOTHING", "SECONDARY_MOTION", "ELEMENTAL_ORBIT_VFX"}
    ]
    islands = int(geom.get("body_connected_components") or 99)
    tris = int(geom.get("triangles") or 0)
    foot = float(geom["foot_ground_gap_m"]) if geom.get("foot_ground_gap_m") is not None else 99.0
    weight = geom.get("weight") or {}
    zero_w = 99 if weight.get("zero_weight_vertices") is None else int(weight["zero_weight_vertices"])
    unintentional = int(geom.get("unintentional_floating_accessories") or 0)
    designed = all(
        (
            geom.get("designed_head"),
            geom.get("designed_hands"),
            geom.get("designed_boots"),
            geom.get("designed_costume"),
        )
    )
    head_style_ok = shape.get("head_style") == REQUIRED_HEAD_STYLES[fid] or shape_profile(fid).head_style == REQUIRED_HEAD_STYLES[fid]
    hand_ok = len(hand_rows) >= 2 and bool(geom.get("designed_hands"))
    boot_ok = len(boot_rows) >= 2 and bool(geom.get("designed_boots"))
    head_ok = bool(head_rows) and bool(geom.get("designed_head")) and head_style_ok
    costume_ok = len(costume_rows) >= MIN_COSTUME_PARTS and unintentional == 0 and not missing
    gates = {
        "hands": hand_ok and islands == 1,
        "feet": boot_ok and foot <= MAX_FOOT_GROUND_M,
        "head_design": head_ok,
        "costume_craft": costume_ok,
        "material": int(geom.get("toon_bands") or 0) >= 2,
        "cohesive_body": islands == 1,
        "smooth_skinning": zero_w == 0 and bool(weight.get("smooth_skinning", False)),
        "topology_in_range": MIN_TRIS <= tris <= MAX_TRIS,
        "no_floaters": unintentional == 0,
        "designed_not_remesh_blob": designed,
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
        "head_parts": len(head_rows),
        "hand_parts": len(hand_rows),
        "boot_parts": len(boot_rows),
        "costume_parts": len(costume_rows),
        "head_style": shape.get("head_style") or shape_profile(fid).head_style,
        "boot_style": shape.get("boot_style") or shape_profile(fid).boot_style,
        "hand_default": shape.get("hand_default") or rec.hand_default,
        "hand_strength": shape_profile(fid).hand_strength,
        "accessories": accessories,
        "thresholds": {
            "max_attach_m": MAX_ATTACH_M,
            "max_foot_ground_m": MAX_FOOT_GROUND_M,
            "min_hand_parts": MIN_HAND_PARTS,
            "min_boot_parts": MIN_BOOT_PARTS,
            "min_head_parts": MIN_HEAD_PARTS,
            "min_tris": MIN_TRIS,
            "max_tris": MAX_TRIS,
        },
    }


def validate() -> dict:
    v2 = validate_v2()
    fighters = {}
    for fid in FIGHTER_IDS:
        fighters[fid] = evaluate_fighter(fid, _master_report(fid))
    hands = roster_hand_hierarchy()
    rook_ember_stronger = hands["rook-ironside"] > hands["juno-spark"] and hands["ember-vale"] > hands["kaia-windrow"]
    payload = {
        "ok": all(row.get("ok") for row in fighters.values()) if fighters else False,
        "fighters": fighters,
        "v2": {k: v2.get(k) for k in v2 if k.startswith("GEN_ART_V2") or k in {"ok", "UNINTENTIONAL_FLOATING_ACCESSORIES"}},
        "GEN_ART_V3_HANDS_PASS": all(row["gates"].get("hands") for row in fighters.values()) and rook_ember_stronger,
        "GEN_ART_V3_FEET_PASS": all(row["gates"].get("feet") for row in fighters.values()),
        "GEN_ART_V3_HEAD_DESIGN_PASS": all(row["gates"].get("head_design") for row in fighters.values()),
        "GEN_ART_V3_COSTUME_CRAFT_PASS": all(row["gates"].get("costume_craft") for row in fighters.values()),
        "GEN_ART_V3_MATERIAL_PASS": all(row["gates"].get("material") for row in fighters.values()),
        "rook_ember_hands_stronger": rook_ember_stronger,
        "hand_hierarchy": hands,
    }
    write_json(REPORTS / "GENERATED_PRODUCTION_GEOMETRY_V3.json", payload)
    return payload


if __name__ == "__main__":
    print(json.dumps(validate(), indent=2))
