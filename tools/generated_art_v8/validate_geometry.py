"""v8 geometry/construction gates. File existence is not a visual pass."""
from __future__ import annotations

import json

from generated_art_v8.body_profiles import FIGHTER_IDS, ROOT
from generated_art_v8.render_review import REQUIRED_SHOTS, ROSTER_SHEETS

REVIEW = ROOT / "artifacts/vxp3/review/generated_art_v8"
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
    gloves = True
    boots = True
    masks = True
    masses = True
    hero = True
    suit = True
    tris_ok = True
    style = True
    attached = True
    for fid in FIGHTER_IDS:
        report = _master(fid)
        geom = report.get("geometry") or report
        construction = str(report.get("construction") or geom.get("construction") or "")
        used_remesh = bool(geom.get("used_voxel_remesh")) or (
            "voxel" in construction.lower() and "no_voxel" not in construction.lower()
        )
        remesh = remesh or used_remesh
        loft = loft and construction == "profile_loft_no_voxel_remesh" and not used_remesh
        style = style and str(report.get("visible_style") or geom.get("visible_style") or "") == "graphic_lowpoly_cel_combat"
        complete, missing = _packet_complete(fid)
        hand_parts = int(geom.get("hand_parts") or 0)
        boot_parts = int(geom.get("boot_parts") or 0)
        head_parts = int(geom.get("head_parts") or 0)
        costume_parts = int(geom.get("costume_parts") or 0)
        hero_parts = int(geom.get("hero_feature_parts") or 0)
        tris = int(geom.get("triangles") or 0)
        gloves = gloves and hand_parts >= 6 and bool(geom.get("glove_thumb"))
        boots = boots and boot_parts >= 6 and bool(geom.get("boot_sole"))
        masks = masks and head_parts >= 3
        masses = masses and costume_parts >= 6
        hero = hero and hero_parts >= 1
        suit = suit and bool(geom.get("undersuit"))
        tris_ok = tris_ok and 5000 <= tris <= 45000
        attached = attached and int(geom.get("unintentional_floating") or 0) == 0 and bool(geom.get("attachments"))
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
            "hero_feature_parts": hero_parts,
            "undersuit": bool(geom.get("undersuit")),
            "glove_family": geom.get("glove_family"),
            "attachment_count": len(geom.get("attachments") or []),
            "front_camera_correct": bool((REVIEW / fid / "orientation.json").is_file()),
        }
    sheets = {name: (REVIEW / "roster" / f"{name}.png").is_file() for name in ROSTER_SHEETS}
    payload = {
        "ok": loft and gloves and boots and masks and masses and suit and hero and attached and not remesh,
        "GEN_ART_V8_NO_VOXEL_REMESH": loft and not remesh,
        "GEN_ART_V8_STYLE_LOCK_DIGITAL": style and loft,
        "GEN_ART_V8_FULL_SUIT_COVERAGE_DIGITAL": suit,
        "GEN_ART_V8_GLOVE_READ_DIGITAL": gloves,
        "GEN_ART_V8_BOOT_READ_DIGITAL": boots,
        "GEN_ART_V8_MASK_HEAD_READ_DIGITAL": masks,
        "GEN_ART_V8_COSTUME_MASS_DIGITAL": masses,
        "GEN_ART_V8_HERO_FEATURE_DIGITAL": hero,
        "GEN_ART_V8_ATTACHMENT_RECORDS_DIGITAL": attached,
        "triangle_budget_ok": tris_ok,
        "roster_sheets": sheets,
        "fighters": fighters,
    }
    REPORTS.mkdir(parents=True, exist_ok=True)
    (REPORTS / "GENERATED_ART_V8_GEOMETRY.json").write_text(json.dumps(payload, indent=2) + "\n")
    return payload


if __name__ == "__main__":
    print(json.dumps(validate(), indent=2))
