#!/usr/bin/env python3
"""v4 digital craft/camera checks. Does not replace owner visual review."""
from __future__ import annotations

import json
from pathlib import Path

from .body_v3 import MIN_BOOT_PARTS, MIN_COSTUME_PARTS, MIN_HAND_PARTS, MIN_HEAD_PARTS, recipe
from .common import ART_GEN, FIGHTER_IDS, REPORTS, write_json
from .review_cameras_v4 import evaluate_presets
from .hero_poses_v4 import charge_100_v4, idle_v4, super_pose_v4
from .hero_poses_v3 import heavy_sequence_v3, hurt_heavy_sequence_v3
from .pose_library import pose_delta_metrics

REVIEW = Path(__file__).resolve().parents[2] / "artifacts/vxp3/review/generated_art_v4"
REQUIRED_SHOTS = (
    "front",
    "front_3q",
    "side",
    "back",
    "gameplay",
    "idle",
    "head_detail_front",
    "boot_detail",
    "costume_front",
    "silhouette_idle",
    "charge_0_vfx_off",
    "charge_100_vfx_off",
    "heavy_contact_pair_vfx_off",
    "hurt_heavy_no_knockback",
    "super_vfx_off",
)


def _master(fid: str) -> dict:
    path = ART_GEN / fid / "master_report.json"
    if not path.is_file():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def _orientation(fid: str) -> dict:
    path = REVIEW / fid / "orientation.json"
    if not path.is_file():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def _costume_coverage(report: dict) -> dict:
    accessories = list((report.get("geometry") or report).get("accessories") or [])
    costume = [row for row in accessories if row.get("classification") in {"ARMOR", "CLOTHING", "SECONDARY_MOTION"}]
    verts = sum(int(row.get("vertex_count") or 0) for row in costume)
    frontish = [row for row in costume if any(k in str(row.get("name", "")) for k in ("chest", "vest", "core", "sash", "vent", "scarf", "coat", "void", "panel"))]
    return {
        "costume_parts": len(costume),
        "costume_vertices": verts,
        "front_named_parts": len(frontish),
        "major_front_forms": len(frontish) >= 2,
        "silhouette_feature": any(k in str(row.get("name", "")) for row in costume for k in ("scarf", "airfoil", "coat_tail", "shoulder", "orbit", "gauntlet", "helm")),
    }


def evaluate_fighter(fid: str) -> dict:
    master = _master(fid)
    geom = master.get("geometry") or master
    orient = _orientation(fid)
    shots = {p.stem for p in (REVIEW / fid).glob("*.png")}
    missing = [name for name in REQUIRED_SHOTS if name not in shots]
    accessories = list(geom.get("accessories") or [])
    rec = recipe(fid)
    required = {spec.name for spec in rec.accessories}
    present = {name for name in required if any(name in str(row.get("name") or "") for row in accessories)}
    coverage = _costume_coverage(master)
    idle = idle_v4(fid)
    heavy = pose_delta_metrics(idle, heavy_sequence_v3(fid)["CONTACT"])
    hurt = pose_delta_metrics(idle, hurt_heavy_sequence_v3(fid)["CONTACT"])
    charge = pose_delta_metrics(idle, charge_100_v4(fid))
    super_d = pose_delta_metrics(idle, super_pose_v4(fid))
    front_ok = bool(orient.get("FRONT_CAMERA_CORRECT")) and bool((orient.get("orientation") or {}).get("front", {}).get("front_facing"))
    back_ok = bool((orient.get("orientation") or {}).get("back", {}).get("back_facing"))
    row = {
        "fighter": fid,
        "front_camera_correct": front_ok,
        "back_camera_correct": back_ok,
        "missing_shots": missing,
        "packet_complete": not missing,
        "designed_head": bool(geom.get("designed_head")),
        "designed_hands": bool(geom.get("designed_hands")),
        "designed_boots": bool(geom.get("designed_boots")),
        "designed_costume": bool(geom.get("designed_costume")),
        "required_accessories_present": required <= present,
        "hand_parts": sum(1 for row in accessories if str(row.get("name", "")).startswith("hand_")),
        "boot_parts": sum(1 for row in accessories if str(row.get("name", "")).startswith("boot_")),
        "head_parts": sum(1 for row in accessories if "head" in str(row.get("name", ""))),
        "coverage": coverage,
        "heavy_delta": heavy.get("silhouette_delta", 0.0),
        "hurt_delta": hurt.get("silhouette_delta", 0.0),
        "charge_delta": charge.get("silhouette_delta", 0.0),
        "super_delta": super_d.get("silhouette_delta", 0.0),
        "front_marker": geom.get("front_marker") == "AA_FrontMarker" or bool(orient.get("front_marker")),
    }
    return row


def validate() -> dict:
    math_ok = evaluate_presets()
    fighters = {fid: evaluate_fighter(fid) for fid in FIGHTER_IDS}
    front_n = sum(1 for row in fighters.values() if row["front_camera_correct"])
    packet_n = sum(1 for row in fighters.values() if row["packet_complete"])
    hand_n = sum(1 for row in fighters.values() if row["designed_hands"] and row["hand_parts"] >= 2 and row["required_accessories_present"])
    boot_n = sum(1 for row in fighters.values() if row["designed_boots"] and row["boot_parts"] >= 2)
    head_n = sum(1 for row in fighters.values() if row["designed_head"] and row["front_marker"])
    costume_n = sum(1 for row in fighters.values() if row["coverage"]["major_front_forms"] and row["coverage"]["silhouette_feature"] and row["coverage"]["costume_parts"] >= MIN_COSTUME_PARTS)
    pose_n = sum(1 for row in fighters.values() if row["heavy_delta"] >= 0.85 and row["hurt_delta"] >= 0.85 and row["charge_delta"] >= 0.55 and row["super_delta"] >= 0.85)
    payload = {
        "ok": front_n == 7 and math_ok.get("ok"),
        "FRONT_CAMERA_CORRECT": f"{front_n}/7",
        "GEN_ART_V4_FRONT_CAMERA_PASS": front_n == 7 and bool(math_ok.get("ok")),
        "GEN_ART_V4_MOBILE_READ_PASS": packet_n == 7 and front_n == 7,
        "GEN_ART_V4_HAND_CRAFT_PASS": hand_n == 7,
        "GEN_ART_V4_BOOT_CRAFT_PASS": boot_n == 7,
        "GEN_ART_V4_HEAD_CRAFT_PASS": head_n == 7,
        "GEN_ART_V4_COSTUME_COVERAGE_PASS": costume_n == 7,
        "GEN_ART_V4_MATERIAL_READ_PASS": head_n == 7 and costume_n == 7,
        "GEN_ART_V4_HERO_POSE_PASS": pose_n == 7,
        "GEN_ART_V4_HEAVY_CONTACT_READ_PASS": pose_n == 7,
        "GEN_ART_V4_HURT_READ_PASS": pose_n == 7,
        "GEN_ART_V4_CHARGE_BODY_READ_PASS": pose_n == 7,
        "GEN_ART_V4_SUPER_READ_PASS": pose_n == 7,
        "GEN_ART_V4_SILHOUETTE_ROSTER_PASS": packet_n == 7 and costume_n == 7,
        "camera_math": math_ok,
        "fighters": fighters,
        "visual_note": "Digital evidence only. Stills must still be judged by a human. Not human-authored final art.",
        "HUMAN_ART_DIRECTION_APPROVAL": False,
    }
    write_json(REPORTS / "GENERATED_ART_V4_QUALITY.json", payload)
    write_json(REPORTS / "REVIEW_CAMERA_ORIENTATION_V4.json", {
        "FRONT_CAMERA_CORRECT": f"{front_n}/7",
        "ok": front_n == 7 and bool(math_ok.get("ok")),
        "camera_math": math_ok,
        "fighters": {fid: row.get("front_camera_correct") for fid, row in fighters.items()},
        "source": "AA_FrontMarker + rest-pose Foot/Toes +Y",
    })
    return payload


def main() -> int:
    payload = validate()
    print(json.dumps({k: payload[k] for k in payload if k != "fighters"}, indent=2))
    return 0 if payload.get("GEN_ART_V4_FRONT_CAMERA_PASS") else 1


if __name__ == "__main__":
    raise SystemExit(main())
