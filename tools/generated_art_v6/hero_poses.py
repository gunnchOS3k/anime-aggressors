"""v6 graphic hero-pose overlays. Generated motion, not human acting."""
from __future__ import annotations

from generated_art_v6.body_profiles import load_hero_poses
from generated_production_art.hero_poses_v3 import heavy_sequence_v3, hurt_heavy_sequence_v3
from generated_production_art.hero_poses_v4 import charge_100_v4, idle_v4, super_pose_v4
from generated_production_art.pose_library import _e, add

GOALS = load_hero_poses()

BONE_KEYS = (
    "pelvis",
    "spine",
    "chest",
    "head",
    "UpperArm_L",
    "UpperArm_R",
    "LowerArm_L",
    "LowerArm_R",
    "Hand_L",
    "Hand_R",
    "UpperLeg_L",
    "UpperLeg_R",
    "LowerLeg_L",
    "LowerLeg_R",
    "Foot_L",
    "Foot_R",
)

BONE_MAP = {
    "pelvis": "Hips",
    "spine": "Spine",
    "chest": "Chest",
    "head": "Head",
}


def _goal(fid: str, action: str) -> dict:
    return (GOALS.get(fid) or {}).get(action) or {}


def apply_goal(pose: dict, fid: str, action: str) -> dict:
    goal = _goal(fid, action)
    if not goal:
        return pose
    out = dict(pose)
    for key in BONE_KEYS:
        raw = goal.get(key)
        if not raw:
            continue
        bone = BONE_MAP.get(key, key)
        out[bone] = _e(*raw[:3])
    return out


def idle_v6(fid: str):
    return apply_goal(idle_v4(fid), fid, "idle")


def charge_100_v6(fid: str):
    return apply_goal(charge_100_v4(fid), fid, "charge_100")


def super_pose_v6(fid: str):
    return apply_goal(super_pose_v4(fid), fid, "super")


def heavy_contact_v6(fid: str):
    seq = heavy_sequence_v3(fid)
    contact = apply_goal(seq.get("CONTACT", idle_v4(fid)), fid, "heavy_contact")
    seq = dict(seq)
    seq["CONTACT"] = contact
    seq["HITSTOP_HOLD"] = contact
    return seq


def hurt_heavy_v6(fid: str):
    seq = hurt_heavy_sequence_v3(fid)
    peak = apply_goal(seq.get("CONTACT", idle_v4(fid)), fid, "hurt_heavy")
    seq = dict(seq)
    seq["CONTACT"] = peak
    seq["HITSTOP_HOLD"] = peak
    return seq


def clash_lock_v6(fid: str):
    return apply_goal(
        add(
            idle_v4(fid),
            {
                "Hips": _e(-0.12, 0.10, 0.0),
                "Spine": _e(-0.26, 0.12, 0.0),
                "Chest": _e(-0.32, 0.18, 0.0),
                "UpperArm_R": _e(0.50, 0.60, 0.70),
                "UpperArm_L": _e(0.50, -0.60, -0.70),
                "Head": _e(-0.10, 0.10, 0.0),
                "UpperLeg_R": _e(0.26, 0.10, 0.20),
                "UpperLeg_L": _e(0.26, -0.10, -0.20),
            },
        ),
        fid,
        "clash_lock",
    )
