#!/usr/bin/env python3
"""Reject weak generated motion. Thresholds calibrated from production poses."""
from __future__ import annotations

from .action_catalog import all_actions
from .common import FIGHTER_IDS, generated_anim_dir, load_json
from .pose_library import pose_delta_metrics, poses_for_action

# Calibrated from the generated hero poses, not tiny placeholder values.
HEAVY_MIN = {
    "pelvis_rotation": 0.35,
    "chest_rotation": 0.55,
    "arm_travel": 0.90,
    "silhouette_delta": 4.0,
}
HURT_MIN = {
    "head_reaction": 0.45,
    "chest_rotation": 0.55,
    "arm_travel": 0.40,
    "silhouette_delta": 3.5,
}
CHARGE_MIN = {
    "silhouette_delta": 1.6,
    "chest_rotation": 0.20,
}


def _metrics_for(fid: str, action: str) -> dict:
    poses = poses_for_action(fid, action)
    settle = poses.get("SETTLE") or poses.get("ANTICIPATION")
    peak = poses.get("CONTACT") or poses.get("HITSTOP_HOLD") or poses.get("OVERSHOOT")
    if not settle or not peak:
        return {}
    return pose_delta_metrics(settle, peak)


def _pass(metrics: dict, mins: dict) -> tuple[bool, list[str]]:
    fails = []
    for key, floor in mins.items():
        value = float(metrics.get(key, 0.0))
        if value < floor:
            fails.append(f"{key} {value:.3f} < {floor}")
    return (not fails, fails)


def validate() -> dict:
    failures: list[dict] = []
    checked = 0
    for fid in FIGHTER_IDS:
        heavy = _metrics_for(fid, "heavy")
        ok, fails = _pass(heavy, HEAVY_MIN)
        checked += 1
        if not ok:
            failures.append({"fighter": fid, "action": "heavy", "fails": fails, "metrics": heavy})
        hurt = _metrics_for(fid, "hurt_heavy")
        ok, fails = _pass(hurt, HURT_MIN)
        checked += 1
        if not ok:
            failures.append({"fighter": fid, "action": "hurt_heavy", "fails": fails, "metrics": hurt})
        charge = _metrics_for(fid, "charged_idle")
        ok, fails = _pass(charge, CHARGE_MIN)
        checked += 1
        if not ok:
            failures.append({"fighter": fid, "action": "charged_idle", "fails": fails, "metrics": charge})
        anim_dir = generated_anim_dir(fid)
        for action in ("heavy", "hurt_heavy", "charged_idle"):
            path = anim_dir / f"{action}.anim.json"
            if path.is_file():
                clip = load_json(path)
                if clip.get("kind") != "GENERATED_PRODUCTION_ANIMATION":
                    failures.append({"fighter": fid, "action": action, "fails": ["missing generated label"]})
    return {
        "ok": not failures,
        "checked": checked,
        "failures": failures,
        "catalog": len(all_actions()),
        "thresholds": {"heavy": HEAVY_MIN, "hurt": HURT_MIN, "charge": CHARGE_MIN},
    }


if __name__ == "__main__":
    import json

    print(json.dumps(validate(), indent=2))
