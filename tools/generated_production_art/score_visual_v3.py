#!/usr/bin/env python3
"""Internal digital scoring. Must not claim human taste or owner approval."""
from __future__ import annotations

from .body_v3 import recipe, shape_profile
from .common import FIGHTER_IDS, REPORTS, write_json
from .hero_poses_v3 import charge_100_v3, heavy_sequence_v3, hurt_heavy_sequence_v3, idle_v3, super_pose_v3
from .pose_library import pose_delta_metrics
from .validate_geometry_v3 import validate as validate_geom


def _class_for(score: float) -> str:
    if score >= 0.86:
        return "Q3-like"
    if score >= 0.72:
        return "Q3-direction"
    if score >= 0.58:
        return "Q2+"
    return "Q2"


def score_fighter(fid: str, geom_row: dict) -> dict:
    gates = geom_row.get("gates") or {}
    idle = idle_v3(fid)
    heavy = heavy_sequence_v3(fid)
    hurt = hurt_heavy_sequence_v3(fid)
    heavy_d = pose_delta_metrics(idle, heavy["CONTACT"])
    hurt_d = pose_delta_metrics(idle, hurt["CONTACT"])
    charge_d = pose_delta_metrics(idle, charge_100_v3(fid))
    super_d = pose_delta_metrics(idle, super_pose_v3(fid))
    shape = shape_profile(fid)
    rec = recipe(fid)
    body = 1.0 if gates.get("cohesive_body") else 0.3
    sil = 0.85 if shape.asymmetry >= 0.0 else 0.4
    head = 1.0 if gates.get("head_design") else 0.35
    hand_foot = 1.0 if gates.get("hands") and gates.get("feet") else 0.35
    attach = 1.0 if gates.get("no_floaters") else 0.2
    costume = 1.0 if gates.get("costume_craft") else 0.4
    heavy_pose = min(1.0, heavy_d["silhouette_delta"] / 6.5)
    hurt_pose = min(1.0, hurt_d["silhouette_delta"] / 5.5)
    charge_body = min(1.0, charge_d["silhouette_delta"] / 3.2)
    super_u = min(1.0, super_d["silhouette_delta"] / 5.8)
    scores = {
        "body cohesion": round(body, 3),
        "silhouette uniqueness": round(0.55 + 0.45 * min(1.0, abs(shape.asymmetry) + abs(shape.shoulder_width - 1.0)), 3),
        "head uniqueness": round(head, 3),
        "hand/foot completeness": round(hand_foot, 3),
        "costume attachment": round(attach, 3),
        "costume intentionality": round(costume, 3),
        "heavy pose delta": round(heavy_pose, 3),
        "hurt pose delta": round(hurt_pose, 3),
        "charge body delta": round(charge_body, 3),
        "super pose uniqueness": round(super_u, 3),
    }
    mean = sum(scores.values()) / len(scores)
    return {
        "fighter": fid,
        "class": _class_for(mean),
        "mean": round(mean, 3),
        "scores": scores,
        "head_style": rec.head_style,
        "boot_style": rec.boot_style,
        "hand_default": rec.hand_default,
        "metrics": {
            "heavy": heavy_d,
            "hurt": hurt_d,
            "charge": charge_d,
            "super": super_d,
        },
        "human_taste": False,
        "note": "Digital structural score only. Not human art-direction approval.",
    }


def score() -> dict:
    geom = validate_geom()
    fighters = {fid: score_fighter(fid, geom["fighters"][fid]) for fid in FIGHTER_IDS}
    classes = [row["class"] for row in fighters.values()]
    roster = "Q3-like" if all(c in {"Q3-like", "Q3-direction"} for c in classes) else "Q2+/Q3-direction mixed"
    payload = {
        "schema": "generated_art_v3_digital_score",
        "human_authored": False,
        "HUMAN_ART_DIRECTION_APPROVAL": False,
        "target": "Q3-like visible direction",
        "roster": roster,
        "fighters": fighters,
        "finished_anime": False,
        "generated_only": True,
    }
    write_json(REPORTS / "GENERATED_ART_V3_QUALITY.json", payload)
    return payload


if __name__ == "__main__":
    import json

    print(json.dumps(score(), indent=2))
