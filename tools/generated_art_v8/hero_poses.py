"""v8 acting overlays. Keep v7 identity, strengthen hurt / clash / super / contact."""
from __future__ import annotations

from generated_art_v7.hero_poses import overlay_table as overlay_v7
from generated_art_v7.hero_poses import pose_delta_ok
from generated_art_v7.hero_poses import pose_v7 as pose_v7
from generated_production_art.pose_library import _e, add


def _sum_e(a, b):
    ax, ay, az = a if a is not None else (0.0, 0.0, 0.0)
    bx, by, bz = b
    return (ax + bx, ay + by, az + bz)

HURT_BONES = ("Head", "Chest", "Hips", "UpperArm_R", "UpperArm_L", "UpperLeg_R", "UpperLeg_L")
CHARGE_BONES = ("Chest", "Head", "Hips", "UpperArm_R", "UpperArm_L", "Spine")


def _boost(base: dict, extra: dict) -> dict:
    out = dict(base)
    out.update(extra)
    return out


def pose_v8(fid: str, action: str):
    base = pose_v7(fid, action)
    if action == "hurt_peak":
        if fid == "ember-vale":
            return _boost(base, {
                "Head": _e(0.78, -0.42, 0.18), "Chest": _e(0.96, -0.48, 0.20), "Hips": _e(0.42, -0.30, 0.16),
                "UpperArm_R": _e(-0.36, -0.92, 0.28), "UpperArm_L": _e(-0.28, 0.88, -0.26),
                "UpperLeg_R": _e(0.44, 0.14, 0.22), "LowerLeg_R": _e(0.24, 0.0, 0.08),
            })
        if fid == "rook-ironside":
            return _boost(base, {
                "Head": _e(0.28, 0.04, 0.0), "Chest": _e(0.38, 0.0, 0.0), "Hips": _e(0.16, 0.0, 0.0),
                "Spine": _e(0.22, 0.0, 0.0), "UpperArm_R": _e(-0.08, -0.48, 0.14), "UpperArm_L": _e(-0.08, 0.48, -0.14),
                "UpperLeg_R": _e(0.30, 0.12, 0.18),
            })
        if fid == "juno-spark":
            return _boost(base, {
                "Head": _e(0.70, -0.46, 0.20), "Chest": _e(0.86, -0.56, 0.18), "Hips": _e(0.34, -0.36, 0.14),
                "UpperArm_R": _e(-0.40, -1.02, 0.24), "UpperArm_L": _e(-0.34, 0.98, -0.22),
            })
        if fid == "kaia-windrow":
            return _boost(base, {
                "Head": _e(0.58, 0.30, 0.20), "Chest": _e(0.78, 0.34, 0.36), "Hips": _e(0.36, 0.20, 0.22),
                "UpperLeg_L": _e(-0.22, -0.20, -0.14), "UpperArm_L": _e(-0.22, 0.92, -0.20),
            })
        if fid == "nix-calder":
            return _boost(base, {
                "Head": _e(0.56, 0.0, 0.0), "Chest": _e(0.72, 0.0, 0.0), "Spine": _e(0.40, 0.0, 0.0),
                "Hips": _e(0.26, 0.0, 0.0), "UpperArm_R": _e(-0.22, -0.74, 0.18), "UpperArm_L": _e(-0.22, 0.74, -0.18),
            })
        if fid == "orion-vell":
            return _boost(base, {
                "Head": _e(0.62, 0.0, 0.0), "Chest": _e(0.82, 0.0, 0.0), "Spine": _e(0.48, 0.0, 0.0),
                "Hips": _e(0.32, 0.0, 0.0), "UpperArm_R": _e(-0.28, -0.84, 0.18), "UpperArm_L": _e(-0.22, 0.86, -0.16),
            })
        return _boost(base, {
            "Head": _e(0.64, 0.34, -0.22), "Chest": _e(0.80, -0.54, 0.24), "Hips": _e(0.34, -0.38, 0.18),
            "UpperArm_R": _e(-0.32, -0.90, 0.20), "UpperArm_L": _e(-0.26, 0.92, -0.18),
        })
    if action == "heavy_contact":
        if fid == "kaia-windrow":
            return _boost(base, {
                "UpperLeg_L": _e(1.10, -0.22, -0.14), "Hips": _e(-0.28, 0.26, 0.22),
                "Chest": _e(0.32, 0.48, 0.36), "UpperArm_L": _e(0.82, 0.56, -0.26),
            })
        return _boost(base, {
            "UpperArm_R": _e(1.02, -0.12, 1.18),
            "Chest": _sum_e(base.get("Chest"), _e(0.10, 0.08, 0.04)),
            "Hips": _sum_e(base.get("Hips"), _e(-0.06, 0.04, 0.02)),
        })
    if action == "super":
        if fid == "ember-vale":
            return _boost(base, {"Hips": _e(-0.46, 0.36, 0.16), "Chest": _e(1.04, 0.64, 0.22), "UpperArm_R": _e(1.34, -0.12, 0.42)})
        if fid == "rook-ironside":
            return _boost(base, {"Hips": _e(-0.30, 0.0, 0.0), "Chest": _e(0.56, 0.16, 0.0), "UpperArm_R": _e(1.36, -0.06, 0.22)})
        if fid == "juno-spark":
            return _boost(base, {"Hips": _e(-0.34, 0.76, 0.14), "Chest": _e(0.34, 1.18, 0.18), "UpperArm_R": _e(1.40, 0.22, 0.28)})
        if fid == "kaia-windrow":
            return _boost(base, {"Hips": _e(-0.28, 0.26, 0.28), "Chest": _e(-0.10, 0.54, 0.56), "UpperArm_L": _e(1.24, 0.44, -0.22), "UpperLeg_L": _e(0.86, -0.20, -0.12)})
        if fid == "nix-calder":
            return _boost(base, {"Hips": _e(-0.12, 0.0, 0.0), "Chest": _e(0.18, 0.08, 0.0), "Head": _e(-0.04, 0.06, 0.0), "UpperArm_R": _e(0.86, 0.22, 0.70), "UpperArm_L": _e(0.86, -0.22, -0.70)})
        if fid == "orion-vell":
            return _boost(base, {"Head": _e(-0.36, 0.0, 0.0), "UpperArm_R": _e(1.12, -0.50, 0.16), "UpperArm_L": _e(1.06, 0.52, -0.14)})
        return _boost(base, {"Hips": _e(-0.26, 0.48, 0.22), "Chest": _e(0.62, -0.42, 0.28), "UpperArm_R": _e(1.24, 0.18, 0.30), "UpperArm_L": _e(0.18, 0.92, -0.28)})
    if action == "clash_lock":
        return _boost(base, {
            "Hips": _sum_e(base.get("Hips"), _e(-0.08, 0.0, 0.0)),
            "Chest": _sum_e(base.get("Chest"), _e(-0.10, 0.0, 0.0)),
            "Head": _sum_e(base.get("Head"), _e(-0.06, 0.04, 0.0)),
            "UpperLeg_R": _sum_e(base.get("UpperLeg_R"), _e(0.08, 0.04, 0.06)),
            "UpperLeg_L": _sum_e(base.get("UpperLeg_L"), _e(0.08, -0.04, -0.06)),
        })
    if action == "personality_idle":
        return add(pose_v7(fid, "idle"), {"Head": _e(0.08, 0.10, 0.06), "Chest": _e(-0.06, 0.08, 0.04)})
    return base


def idle_v8(fid: str):
    return pose_v8(fid, "idle")


def charge_100_v8(fid: str):
    return pose_v8(fid, "charge")


def super_pose_v8(fid: str):
    return pose_v8(fid, "super")


def overlay_table(fid: str) -> dict:
    table = overlay_v7(fid)
    table["idle"] = {1: pose_v8(fid, "idle")}
    table["personality_idle"] = {8: pose_v8(fid, "personality_idle")}
    table["charged_idle"] = {12: pose_v8(fid, "charge")}
    table["charge_full"] = {12: pose_v8(fid, "charge")}
    table["heavy"] = {
        4: pose_v8(fid, "heavy_pre"),
        11: pose_v8(fid, "heavy_contact"),
        16: pose_v8(fid, "heavy_follow"),
    }
    table["hurt_heavy"] = {
        2: pose_v8(fid, "hurt_pre"),
        6: pose_v8(fid, "hurt_peak"),
        10: pose_v8(fid, "launch"),
    }
    table["launch"] = {4: pose_v8(fid, "launch")}
    table["clash_lock"] = {
        2: pose_v8(fid, "clash_start"),
        8: pose_v8(fid, "clash_lose"),
        12: pose_v8(fid, "clash_lock"),
        16: pose_v8(fid, "clash_push"),
        20: pose_v8(fid, "clash_win"),
        24: pose_v8(fid, "clash_break"),
    }
    table["signature_lane_finisher"] = {16: pose_v8(fid, "super")}
    table["aura_signature"] = {12: pose_v8(fid, "super")}
    table["aura_burst_super_pose"] = {16: pose_v8(fid, "super")}
    return table


STRESS_POSE_ALIASES = {
    "idle": ("idle", "idle"),
    "walk_extreme": ("walk", "walk"),
    "run_extreme": ("run", "run"),
    "dash": ("dash", "dash"),
    "heavy_anticipation": ("heavy_pre", "heavy_pre"),
    "heavy_contact": ("heavy_contact", "heavy_contact"),
    "heavy_follow": ("heavy_follow", "heavy_follow"),
    "hurt_heavy": ("hurt_peak", "hurt_peak"),
    "launch_start": ("launch", "launch"),
    "charge_100": ("charge", "charge"),
    "super": ("super", "super"),
    "clash_start": ("clash_start", "clash_start"),
    "clash_lock": ("clash_lock", "clash_lock"),
    "clash_push": ("clash_push", "clash_push"),
    "clash_win": ("clash_win", "clash_win"),
    "clash_lose": ("clash_lose", "clash_lose"),
    "KO": ("launch", "launch"),
}
