"""v5 hero-pose overlays. Generated motion, not human acting."""
from __future__ import annotations

from generated_art_v5.body_profiles import load_hero_poses
from generated_production_art.hero_poses_v4 import charge_100_v4, idle_v4, super_pose_v4
from generated_production_art.hero_poses_v3 import heavy_sequence_v3, hurt_heavy_sequence_v3
from generated_production_art.pose_library import _e, add

GOALS = load_hero_poses()


def _goal(fid: str, action: str) -> dict:
    return (GOALS.get(fid) or {}).get(action) or {}


def apply_goal(pose: dict, fid: str, action: str) -> dict:
    goal = _goal(fid, action)
    if not goal:
        return pose
    extras = {}
    if "pelvis" in goal:
        extras["Hips"] = _e(*goal["pelvis"])
    if "chest" in goal:
        extras["Chest"] = _e(*goal["chest"])
    if "head" in goal:
        extras["Head"] = _e(*goal["head"])
    return add(pose, extras)


def idle_v5(fid: str):
    return apply_goal(idle_v4(fid), fid, "idle")


def charge_100_v5(fid: str):
    return apply_goal(charge_100_v4(fid), fid, "charge_100")


def super_pose_v5(fid: str):
    return apply_goal(super_pose_v4(fid), fid, "super")


def heavy_contact_v5(fid: str):
    seq = heavy_sequence_v3(fid)
    contact = apply_goal(seq.get("CONTACT", idle_v4(fid)), fid, "heavy_contact")
    seq = dict(seq)
    seq["CONTACT"] = contact
    seq["HITSTOP_HOLD"] = contact
    return seq


def hurt_heavy_v5(fid: str):
    seq = hurt_heavy_sequence_v3(fid)
    peak = apply_goal(seq.get("CONTACT", idle_v4(fid)), fid, "hurt_heavy")
    seq = dict(seq)
    seq["CONTACT"] = peak
    seq["HITSTOP_HOLD"] = peak
    return seq


def clash_lock_v5(fid: str):
    return apply_goal(
        add(
            idle_v4(fid),
            {
                "Hips": _e(-0.10, 0.08, 0.0),
                "Spine": _e(-0.22, 0.10, 0.0),
                "Chest": _e(-0.28, 0.16, 0.0),
                "UpperArm_R": _e(0.42, 0.55, 0.62),
                "UpperArm_L": _e(0.42, -0.55, -0.62),
                "Head": _e(-0.08, 0.08, 0.0),
                "UpperLeg_R": _e(0.22, 0.08, 0.18),
                "UpperLeg_L": _e(0.22, -0.08, -0.18),
            },
        ),
        fid,
        "clash_lock",
    )
