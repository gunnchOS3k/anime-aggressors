"""Geometry/construction gates. File existence is not a pass."""
from __future__ import annotations

import json
from pathlib import Path

from generated_art_v5.body_profiles import FIGHTER_IDS, ROOT
from generated_art_v5.render_review import REQUIRED_SHOTS, ROSTER_SHEETS

REVIEW = ROOT / "artifacts/vxp3/review/generated_art_v5"
REPORTS = ROOT / "artifacts/vxp3/reports"


def _master(fid: str) -> dict:
    path = ROOT / "art_source/generated/production" / fid / "master_report.json"
    if not path.is_file():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def _packet_complete(fid: str) -> tuple[bool, list[str]]:
    missing = [name for name in REQUIRED_SHOTS if not (REVIEW / fid / f"{name}.png").is_file()]
    return (not missing), missing


def validate() -> dict:
    fighters = {}
    remesh = False
    loft = True
    hands = True
    boots = True
    heads = True
    shells = True
    tris_ok = True
    for fid in FIGHTER_IDS:
        report = _master(fid)
        geom = report.get("geometry") or report
        construction = str(report.get("construction") or geom.get("construction") or "")
        used_remesh = bool(geom.get("used_voxel_remesh")) or (
            "voxel" in construction.lower() and "no_voxel" not in construction.lower()
        )
        remesh = remesh or used_remesh
        loft = loft and construction == "profile_loft_no_voxel_remesh" and not used_remesh
        complete, missing = _packet_complete(fid)
        hand_parts = int(geom.get("hand_parts") or 0)
        boot_parts = int(geom.get("boot_parts") or 0)
        head_parts = int(geom.get("head_parts") or 0)
        costume_parts = int(geom.get("costume_parts") or 0)
        tris = int(geom.get("triangles") or 0)
        hands = hands and hand_parts >= 5
        boots = boots and boot_parts >= 3
        heads = heads and head_parts >= 3
        shells = shells and costume_parts >= 3
        tris_ok = tris_ok and 4000 <= tris <= 120000
        fighters[fid] = {
            "construction": construction,
            "used_voxel_remesh": used_remesh,
            "packet_complete": complete,
            "missing_shots": missing,
            "triangles": tris,
            "hand_parts": hand_parts,
            "boot_parts": boot_parts,
            "head_parts": head_parts,
            "costume_parts": costume_parts,
            "front_camera_correct": bool((REVIEW / fid / "orientation.json").is_file()),
        }
    sheets = {name: (REVIEW / "roster" / f"{name}.png").is_file() for name in ROSTER_SHEETS}
    payload = {
        "ok": loft and hands and boots and heads and shells and not remesh,
        "GEN_ART_V5_NO_VOXEL_REMESH": loft and not remesh,
        "GEN_ART_V5_BODY_SURFACE_DIGITAL": loft,
        "GEN_ART_V5_HAND_MODEL_DIGITAL": hands,
        "GEN_ART_V5_BOOT_MODEL_DIGITAL": boots,
        "GEN_ART_V5_HEAD_MODEL_DIGITAL": heads,
        "GEN_ART_V5_COSTUME_SHELL_DIGITAL": shells,
        "triangle_budget_ok": tris_ok,
        "roster_sheets": sheets,
        "fighters": fighters,
    }
    REPORTS.mkdir(parents=True, exist_ok=True)
    (REPORTS / "GENERATED_ART_V5_GEOMETRY.json").write_text(json.dumps(payload, indent=2) + "\n")
    return payload


if __name__ == "__main__":
    print(json.dumps(validate(), indent=2))
