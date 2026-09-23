"""Explicit key-pose templates. Production-grade, not subtle placeholders."""
from __future__ import annotations

import math
from typing import Dict, Iterable, Tuple

from .common import POSE_BONES
from .profiles import FighterProfile, profile

Euler = Tuple[float, float, float]
Pose = Dict[str, Euler]
Loc = Dict[str, Tuple[float, float, float]]

ZERO: Euler = (0.0, 0.0, 0.0)


def _e(x: float = 0.0, y: float = 0.0, z: float = 0.0) -> Euler:
    return (float(x), float(y), float(z))


def blank() -> Pose:
    return {bone: ZERO for bone in POSE_BONES}


def add(a: Pose, b: Pose, scale: float = 1.0) -> Pose:
    out = blank()
    for bone in POSE_BONES:
        ax, ay, az = a.get(bone, ZERO)
        bx, by, bz = b.get(bone, ZERO)
        out[bone] = (ax + bx * scale, ay + by * scale, az + bz * scale)
    return out


def mix(a: Pose, b: Pose, t: float) -> Pose:
    t = max(0.0, min(1.0, t))
    out = blank()
    for bone in POSE_BONES:
        ax, ay, az = a.get(bone, ZERO)
        bx, by, bz = b.get(bone, ZERO)
        out[bone] = (ax + (bx - ax) * t, ay + (by - ay) * t, az + (bz - az) * t)
    return out


def scale_pose(pose: Pose, amount: float) -> Pose:
    return {bone: (x * amount, y * amount, z * amount) for bone, (x, y, z) in pose.items()}


def identity_idle(fid: str) -> Pose:
    p = profile(fid)
    pose = blank()
    pose["Hips"] = _e(0.04 * p.lean, 0.10 * p.lean, 0.0)
    pose["Spine"] = _e(-0.08 - 0.18 * p.lean, 0.16 * p.lean, 0.04 * p.lean)
    pose["Chest"] = _e(-0.10 - 0.16 * p.lean, 0.20 * p.lean, 0.05 * p.lean)
    pose["Neck"] = _e(0.06, -0.04 * p.lean, 0.0)
    pose["Head"] = _e(0.08 + 0.06 * p.lean, 0.10 * p.lean, 0.0)
    pose["Shoulder_R"] = _e(0.04, -0.12, 0.10)
    pose["Shoulder_L"] = _e(0.04, 0.12, -0.10)
    pose["UpperArm_R"] = _e(0.22, -0.42 - 0.18 * p.lean, 0.34)
    pose["UpperArm_L"] = _e(0.20, 0.38 + 0.12 * p.lean, -0.30)
    pose["LowerArm_R"] = _e(0.18, -0.22, 0.10)
    pose["LowerArm_L"] = _e(0.16, 0.18, -0.08)
    pose["Hand_R"] = _e(0.10, -0.08, 0.16)
    pose["Hand_L"] = _e(0.08, 0.06, -0.12)
    pose["UpperLeg_R"] = _e(0.10 + 0.08 * p.weight, 0.04, 0.22 + 0.08 * p.weight)
    pose["UpperLeg_L"] = _e(0.06, -0.02, -0.24 - 0.06 * p.weight)
    pose["LowerLeg_R"] = _e(0.12 + 0.06 * p.weight, 0.0, 0.03)
    pose["LowerLeg_L"] = _e(0.10, 0.0, -0.03)
    pose["Foot_R"] = _e(-0.06, 0.04, 0.02)
    pose["Foot_L"] = _e(-0.04, -0.02, -0.02)
    if fid == "rook-ironside":
        pose["Chest"] = _e(0.06, 0.0, 0.0)
        pose["UpperArm_R"] = _e(0.34, -0.28, 0.48)
        pose["UpperArm_L"] = _e(0.34, 0.28, -0.48)
        pose["UpperLeg_R"] = _e(0.18, 0.06, 0.32)
        pose["UpperLeg_L"] = _e(0.16, -0.06, -0.32)
    elif fid == "juno-spark":
        pose["UpperArm_R"] = _e(0.08, -0.72, 0.18)
        pose["UpperArm_L"] = _e(-0.12, 0.64, -0.42)
        pose["Head"] = _e(0.16, -0.22, 0.08)
    elif fid == "kaia-windrow":
        pose["Spine"] = _e(-0.16, 0.08, 0.10)
        pose["UpperArm_L"] = _e(-0.28, 0.55, -0.22)
        pose["UpperLeg_L"] = _e(-0.12, 0.10, -0.16)
    elif fid == "nix-calder":
        pose["Spine"] = _e(0.02, 0.0, 0.0)
        pose["Chest"] = _e(0.0, 0.0, 0.0)
        pose["UpperArm_R"] = _e(0.12, -0.28, 0.22)
        pose["UpperArm_L"] = _e(0.12, 0.28, -0.22)
    elif fid == "orion-vell":
        pose["UpperArm_R"] = _e(-0.18, -0.52, 0.12)
        pose["UpperArm_L"] = _e(-0.22, 0.58, -0.16)
        pose["Hand_R"] = _e(0.22, -0.34, 0.28)
        pose["Hand_L"] = _e(0.22, 0.34, -0.28)
    elif fid == "vesper-nyx":
        pose["Hips"] = _e(0.08, 0.22, 0.10)
        pose["Chest"] = _e(-0.06, -0.24, 0.12)
        pose["UpperArm_R"] = _e(-0.20, -0.66, 0.18)
        pose["Head"] = _e(0.10, 0.28, -0.08)
    return pose


def charged_idle(fid: str) -> Pose:
    p = profile(fid)
    base = identity_idle(fid)
    delta = blank()
    delta["Hips"] = _e(-0.18, 0.0, 0.0)
    delta["Spine"] = _e(-0.38, 0.0, 0.0)
    delta["Chest"] = _e(-0.55, 0.12 * p.lean, 0.0)
    delta["Head"] = _e(-0.28, 0.0, 0.0)
    delta["UpperArm_R"] = _e(-0.48, -0.62, 0.48)
    delta["UpperArm_L"] = _e(-0.48, 0.62, -0.48)
    delta["LowerArm_R"] = _e(0.42, -0.22, 0.16)
    delta["LowerArm_L"] = _e(0.42, 0.22, -0.16)
    delta["UpperLeg_R"] = _e(0.22, 0.0, 0.14)
    delta["UpperLeg_L"] = _e(0.22, 0.0, -0.14)
    return add(base, delta, 1.05 + 0.20 * p.weight)


def personality_idle(fid: str) -> Pose:
    base = identity_idle(fid)
    extra = {
        "ember-vale": {"Chest": _e(-0.18, 0.28, 0.08), "UpperArm_R": _e(-0.12, -0.55, 0.40), "Head": _e(0.12, 0.18, 0.0)},
        "rook-ironside": {"Chest": _e(0.16, 0.0, 0.0), "UpperArm_R": _e(0.22, -0.12, 0.62), "Head": _e(-0.06, 0.0, 0.0)},
        "juno-spark": {"Head": _e(0.22, -0.42, 0.12), "UpperArm_L": _e(-0.40, 0.80, -0.22), "Hips": _e(0.0, 0.18, 0.0)},
        "kaia-windrow": {"Spine": _e(-0.24, 0.16, 0.18), "UpperArm_L": _e(-0.55, 0.72, -0.10), "Head": _e(0.16, 0.22, 0.0)},
        "nix-calder": {"Chest": _e(0.04, 0.0, 0.0), "Hand_R": _e(0.18, -0.22, 0.16), "Head": _e(0.04, 0.06, 0.0)},
        "orion-vell": {"UpperArm_R": _e(-0.44, -0.70, 0.18), "UpperArm_L": _e(-0.44, 0.70, -0.18), "Head": _e(-0.10, 0.0, 0.0)},
        "vesper-nyx": {"Hips": _e(0.12, 0.34, 0.16), "Head": _e(0.18, 0.40, -0.12), "UpperArm_R": _e(-0.38, -0.88, 0.10)},
    }[fid]
    return add(base, extra)


def heavy_sequence(fid: str) -> dict[str, Pose]:
    p = profile(fid)
    idle = identity_idle(fid)
    settle = idle
    anticipation = add(
        idle,
        {
            "Hips": _e(0.22 * p.weight, -0.18, 0.10),
            "Spine": _e(-0.55, -0.42, 0.16),
            "Chest": _e(-0.72, -0.55, 0.18),
            "Neck": _e(0.18, -0.10, 0.0),
            "Head": _e(0.22, -0.16, 0.0),
            "UpperArm_R": _e(-0.85, -1.65, 0.55),
            "LowerArm_R": _e(0.22, -1.05, 0.28),
            "Hand_R": _e(0.30, -0.72, 0.42),
            "UpperArm_L": _e(0.28, 0.55, -0.22),
            "UpperLeg_R": _e(0.42, 0.08, 0.18),
            "UpperLeg_L": _e(-0.18, -0.06, -0.12),
            "LowerLeg_R": _e(0.28, 0.0, 0.0),
        },
        0.85 + 0.35 * p.weight,
    )
    accel = add(
        idle,
        {
            "Hips": _e(-0.12, 0.22, 0.0),
            "Spine": _e(0.18, 0.34, 0.08),
            "Chest": _e(0.28, 0.48, 0.10),
            "UpperArm_R": _e(0.12, 0.22, 0.70),
            "LowerArm_R": _e(0.10, 0.18, 0.16),
        },
    )
    contact = add(
        idle,
        {
            "Hips": _e(-0.38 * p.weight, 0.62, 0.12),
            "Spine": _e(0.58, 0.72, 0.18),
            "Chest": _e(0.82, 0.88, 0.16),
            "Shoulder_R": _e(0.22, 0.34, 0.28),
            "UpperArm_R": _e(0.18, 1.05, 1.15),
            "LowerArm_R": _e(0.12, 0.48, 0.22),
            "Hand_R": _e(0.28, 0.36, 0.18),
            "UpperArm_L": _e(0.42, 0.22, -0.34),
            "UpperLeg_R": _e(0.55, 0.10, 0.22),
            "LowerLeg_R": _e(0.16, 0.0, 0.0),
            "UpperLeg_L": _e(-0.22, -0.08, -0.16),
            "Head": _e(-0.12, 0.28, 0.08),
        },
        0.90 + 0.28 * p.weight,
    )
    hitstop = contact
    overshoot = add(
        contact,
        {
            "Hips": _e(-0.12, 0.16, 0.0),
            "Chest": _e(0.18, 0.16, 0.0),
            "UpperArm_R": _e(0.10, 0.22, 0.18),
            "Head": _e(-0.08, 0.10, 0.0),
        },
    )
    follow = mix(contact, idle, 0.35)
    follow = add(follow, {"UpperArm_R": _e(0.08, 0.28, 0.12), "Spine": _e(0.16, 0.18, 0.0)})
    recovery = mix(follow, idle, 0.72)
    ret = mix(recovery, idle, 0.92)
    return {
        "SETTLE": settle,
        "ANTICIPATION": anticipation,
        "ACCELERATION": accel,
        "CONTACT": contact,
        "HITSTOP_HOLD": hitstop,
        "OVERSHOOT": overshoot,
        "FOLLOW_THROUGH": follow,
        "RECOVERY": recovery,
        "RETURN": ret,
    }


def hurt_heavy_sequence(fid: str) -> dict[str, Pose]:
    idle = identity_idle(fid)
    impact = add(
        idle,
        {
            "Hips": _e(0.28, -0.22, 0.10),
            "Spine": _e(0.72, -0.18, 0.12),
            "Chest": _e(0.95, -0.22, 0.16),
            "Neck": _e(0.42, -0.12, 0.08),
            "Head": _e(0.85, -0.28, 0.18),
            "UpperArm_R": _e(0.62, 0.55, 0.72),
            "UpperArm_L": _e(0.58, -0.48, -0.70),
            "LowerArm_R": _e(0.22, 0.18, 0.12),
            "LowerArm_L": _e(0.22, -0.16, -0.12),
            "Hand_R": _e(0.18, 0.22, 0.10),
            "Hand_L": _e(0.18, -0.22, -0.10),
            "UpperLeg_R": _e(0.34, 0.12, 0.16),
            "UpperLeg_L": _e(0.28, -0.10, -0.14),
            "LowerLeg_R": _e(0.22, 0.0, 0.0),
            "LowerLeg_L": _e(0.18, 0.0, 0.0),
        },
    )
    peak = add(
        impact,
        {
            "Head": _e(0.28, -0.12, 0.10),
            "Chest": _e(0.22, -0.08, 0.08),
            "UpperArm_R": _e(0.16, 0.18, 0.22),
            "UpperArm_L": _e(0.16, -0.18, -0.22),
            "Hips": _e(0.12, -0.08, 0.0),
        },
    )
    crumple = add(
        idle,
        {
            "Hips": _e(0.42, -0.16, 0.08),
            "Spine": _e(0.48, -0.10, 0.08),
            "Chest": _e(0.38, -0.08, 0.06),
            "Head": _e(0.32, -0.18, 0.10),
            "UpperArm_R": _e(0.28, 0.22, 0.34),
            "UpperArm_L": _e(0.26, -0.20, -0.32),
            "UpperLeg_R": _e(0.22, 0.08, 0.10),
            "UpperLeg_L": _e(0.18, -0.06, -0.08),
        },
    )
    launch = add(
        idle,
        {
            "Hips": _e(-0.22, 0.18, 0.0),
            "Spine": _e(-0.55, 0.22, 0.0),
            "Chest": _e(-0.62, 0.18, 0.0),
            "Head": _e(-0.48, 0.16, 0.0),
            "UpperArm_R": _e(-0.72, -0.44, 0.28),
            "UpperArm_L": _e(-0.70, 0.42, -0.26),
            "UpperLeg_R": _e(-0.38, 0.10, 0.12),
            "UpperLeg_L": _e(-0.34, -0.08, -0.10),
        },
    )
    return {
        "SETTLE": idle,
        "ANTICIPATION": idle,
        "ACCELERATION": impact,
        "CONTACT": impact,
        "HITSTOP_HOLD": peak,
        "OVERSHOOT": peak,
        "FOLLOW_THROUGH": crumple,
        "RECOVERY": launch,
        "RETURN": launch,
    }


def _loco_pose(fid: str, phase: float, kind: str) -> Pose:
    idle = identity_idle(fid)
    p = profile(fid)
    swing = math.sin(phase * math.tau)
    plant = math.cos(phase * math.tau)
    amp = 0.55 if kind == "run" else 0.32 if kind == "walk" else 0.78
    amp *= 0.75 + 0.35 * (1.2 - p.weight * 0.3)
    if kind == "dash":
        amp = 0.95
    delta = {
        "Hips": _e(0.04 * plant, 0.10 * swing * p.lean, 0.0),
        "Spine": _e(-0.08 - (0.16 if kind != "walk" else 0.04), 0.18 * swing, 0.06 * swing),
        "Chest": _e(-0.10 - (0.18 if kind == "run" else 0.04), 0.22 * swing, 0.08 * swing),
        "UpperArm_R": _e(0.08, -0.72 * swing * amp, 0.18),
        "UpperArm_L": _e(0.08, 0.72 * swing * amp, -0.18),
        "LowerArm_R": _e(0.12 + 0.18 * max(0.0, -swing), -0.16 * swing, 0.08),
        "LowerArm_L": _e(0.12 + 0.18 * max(0.0, swing), 0.16 * swing, -0.08),
        "UpperLeg_R": _e(0.55 * swing * amp, 0.0, 0.12),
        "UpperLeg_L": _e(-0.55 * swing * amp, 0.0, -0.12),
        "LowerLeg_R": _e(0.42 * max(0.0, -swing) * amp, 0.0, 0.0),
        "LowerLeg_L": _e(0.42 * max(0.0, swing) * amp, 0.0, 0.0),
        "Foot_R": _e(-0.10 * max(0.0, swing), 0.0, 0.0),
        "Foot_L": _e(-0.10 * max(0.0, -swing), 0.0, 0.0),
        "Head": _e(0.04, 0.08 * swing, 0.0),
    }
    if kind == "dash":
        delta["Spine"] = _e(-0.42, 0.12 * swing, 0.0)
        delta["Chest"] = _e(-0.55, 0.16 * swing, 0.0)
        delta["UpperArm_R"] = _e(-0.22, -1.05, 0.42)
        delta["UpperArm_L"] = _e(-0.18, 0.88, -0.28)
    return add(idle, delta)


def attack_pose(fid: str, style: str, side: str = "R") -> Pose:
    idle = identity_idle(fid)
    sign = 1.0 if side == "R" else -1.0
    styles = {
        "jab": {
            "Chest": _e(0.18, 0.42 * sign, 0.08),
            "UpperArm_R" if side == "R" else "UpperArm_L": _e(0.12, 0.95 * sign, 0.72),
            "LowerArm_R" if side == "R" else "LowerArm_L": _e(0.08, 0.28 * sign, 0.10),
            "Hips": _e(-0.08, 0.22 * sign, 0.0),
        },
        "tilt": {
            "Hips": _e(-0.16, 0.34 * sign, 0.0),
            "Spine": _e(0.28, 0.48 * sign, 0.10),
            "Chest": _e(0.42, 0.55 * sign, 0.12),
            "UpperArm_R" if side == "R" else "UpperArm_L": _e(0.10, 1.12 * sign, 0.88),
            "UpperLeg_R": _e(0.28, 0.08, 0.12),
        },
        "aura": {
            "Hips": _e(-0.22, 0.0, 0.0),
            "Spine": _e(-0.38, 0.18 * sign, 0.0),
            "Chest": _e(-0.55, 0.22 * sign, 0.0),
            "UpperArm_R": _e(-0.72, -0.55, 0.42),
            "UpperArm_L": _e(-0.72, 0.55, -0.42),
            "Head": _e(-0.22, 0.0, 0.0),
        },
        "super": {
            "Hips": _e(-0.28, 0.12 * sign, 0.0),
            "Spine": _e(-0.48, 0.22 * sign, 0.0),
            "Chest": _e(-0.62, 0.28 * sign, 0.0),
            "UpperArm_R": _e(-1.05, -0.42, 0.55),
            "UpperArm_L": _e(-0.92, 0.62, -0.38),
            "Head": _e(-0.34, 0.10 * sign, 0.0),
            "UpperLeg_R": _e(0.22, 0.0, 0.12),
            "UpperLeg_L": _e(-0.18, 0.0, -0.10),
        },
        "kick": {
            "Hips": _e(-0.12, -0.28 * sign, 0.0),
            "Chest": _e(0.18, 0.22 * sign, 0.0),
            "UpperLeg_R" if side == "R" else "UpperLeg_L": _e(-0.95, 0.18 * sign, 0.22 * sign),
            "LowerLeg_R" if side == "R" else "LowerLeg_L": _e(0.22, 0.0, 0.0),
            "UpperArm_L" if side == "R" else "UpperArm_R": _e(-0.28, 0.42 * sign, -0.18 * sign),
        },
        "grab": {
            "Chest": _e(-0.18, 0.0, 0.0),
            "UpperArm_R": _e(0.22, 0.62, 0.55),
            "UpperArm_L": _e(0.22, -0.62, -0.55),
            "LowerArm_R": _e(0.28, 0.22, 0.12),
            "LowerArm_L": _e(0.28, -0.22, -0.12),
        },
        "throw": {
            "Hips": _e(-0.18, 0.42 * sign, 0.0),
            "Chest": _e(0.34, 0.62 * sign, 0.16),
            "UpperArm_R": _e(-0.22, 0.88 * sign, 0.42),
            "UpperArm_L": _e(0.18, 0.55 * sign, -0.22),
        },
        "hurt_light": {
            "Chest": _e(0.28, -0.08, 0.04),
            "Head": _e(0.32, -0.12, 0.06),
            "UpperArm_R": _e(0.18, 0.16, 0.22),
            "UpperArm_L": _e(0.16, -0.14, -0.20),
        },
        "ko": {
            "Hips": _e(-0.42, 0.22, 0.18),
            "Spine": _e(-0.72, 0.28, 0.16),
            "Chest": _e(-0.85, 0.22, 0.12),
            "Head": _e(-0.62, 0.34, 0.18),
            "UpperArm_R": _e(-0.88, -0.42, 0.28),
            "UpperArm_L": _e(-0.82, 0.48, -0.24),
            "UpperLeg_R": _e(-0.22, 0.16, 0.18),
            "UpperLeg_L": _e(0.18, -0.12, -0.14),
        },
        "clash": {
            "Hips": _e(0.12, 0.0, 0.0),
            "Spine": _e(-0.28, 0.0, 0.0),
            "Chest": _e(-0.42, 0.0, 0.0),
            "UpperArm_R": _e(-0.55, -0.62, 0.55),
            "UpperArm_L": _e(-0.55, 0.62, -0.55),
            "Head": _e(-0.18, 0.0, 0.0),
            "UpperLeg_R": _e(0.28, 0.0, 0.16),
            "UpperLeg_L": _e(0.28, 0.0, -0.16),
        },
        "jump": {
            "Hips": _e(-0.08, 0.0, 0.0),
            "Spine": _e(-0.16, 0.0, 0.0),
            "UpperArm_R": _e(-0.55, -0.22, 0.18),
            "UpperArm_L": _e(-0.55, 0.22, -0.18),
            "UpperLeg_R": _e(-0.28, 0.08, 0.10),
            "UpperLeg_L": _e(-0.22, -0.08, -0.10),
        },
        "land": {
            "Hips": _e(0.28, 0.0, 0.0),
            "Spine": _e(0.22, 0.0, 0.0),
            "Chest": _e(0.18, 0.0, 0.0),
            "UpperLeg_R": _e(0.42, 0.0, 0.12),
            "UpperLeg_L": _e(0.40, 0.0, -0.12),
            "LowerLeg_R": _e(0.38, 0.0, 0.0),
            "LowerLeg_L": _e(0.36, 0.0, 0.0),
            "UpperArm_R": _e(0.22, -0.18, 0.16),
            "UpperArm_L": _e(0.22, 0.18, -0.16),
        },
    }
    return add(idle, styles.get(style, styles["jab"]))


def locations_for(fid: str, action: str, pose_name: str) -> Loc:
    p = profile(fid)
    loc: Loc = {}
    if action in {"heavy", "smash_forward", "smash_up", "signature_lane_burst", "signature_lane_finisher"}:
        table = {
            "SETTLE": (0.0, 0.0, 0.0),
            "ANTICIPATION": (-0.06 * p.weight, 0.0, -0.04),
            "ACCELERATION": (0.04, 0.0, 0.02),
            "CONTACT": (0.10 + 0.04 * p.weight, 0.0, 0.03),
            "HITSTOP_HOLD": (0.10 + 0.04 * p.weight, 0.0, 0.03),
            "OVERSHOOT": (0.14 + 0.05 * p.weight, 0.0, 0.02),
            "FOLLOW_THROUGH": (0.08, 0.0, 0.01),
            "RECOVERY": (0.03, 0.0, 0.0),
            "RETURN": (0.0, 0.0, 0.0),
        }
        loc["Hips"] = table.get(pose_name, (0.0, 0.0, 0.0))
    if action.startswith("hurt") or action in {"launch", "tumble", "ko"}:
        if pose_name in {"CONTACT", "HITSTOP_HOLD", "OVERSHOOT"}:
            loc["Hips"] = (-0.08, 0.0, 0.04)
            loc["Head"] = (-0.02, 0.0, 0.03)
        if pose_name in {"RECOVERY", "RETURN"} and action in {"launch", "tumble", "ko", "hurt_heavy"}:
            loc["Hips"] = (0.04, 0.0, 0.10)
    if action.startswith("charge") or action.startswith("charged"):
        rise = 0.04 + 0.03 * (1.0 if "full" in action or action == "charged_idle" else 0.5)
        loc["Hips"] = (0.0, 0.0, rise)
        loc["Chest"] = (0.0, 0.0, rise * 0.4)
    return loc


def phase_times(action: str, frames: int, p: FighterProfile) -> dict[str, int]:
    last = max(frames - 1, 8)
    if action in {"heavy", "smash_forward", "smash_up", "smash_down", "signature_lane_burst", "signature_lane_finisher"}:
        load = max(3, int(6 * p.timing))
        contact = max(load + 2, int(10 * p.timing))
        hold = contact + max(2, int(3 + 2 * p.weight))
        over = min(last - 4, hold + 3)
        follow = min(last - 2, over + 4)
        rec = min(last - 1, follow + 5)
        return {
            "SETTLE": 0,
            "ANTICIPATION": load,
            "ACCELERATION": max(load + 1, contact - 2),
            "CONTACT": contact,
            "HITSTOP_HOLD": hold,
            "OVERSHOOT": over,
            "FOLLOW_THROUGH": follow,
            "RECOVERY": rec,
            "RETURN": last,
        }
    if action.startswith("hurt") or action in {"launch", "tumble", "ko"}:
        return {
            "SETTLE": 0,
            "ANTICIPATION": 0,
            "ACCELERATION": 1,
            "CONTACT": 2,
            "HITSTOP_HOLD": 6,
            "OVERSHOOT": 8,
            "FOLLOW_THROUGH": 12,
            "RECOVERY": 16,
            "RETURN": last,
        }
    return {
        "SETTLE": 0,
        "ANTICIPATION": max(1, int(0.18 * last)),
        "ACCELERATION": max(2, int(0.32 * last)),
        "CONTACT": max(3, int(0.42 * last)),
        "HITSTOP_HOLD": max(4, int(0.50 * last)),
        "OVERSHOOT": max(5, int(0.60 * last)),
        "FOLLOW_THROUGH": max(6, int(0.72 * last)),
        "RECOVERY": max(7, int(0.86 * last)),
        "RETURN": last,
    }


def poses_for_action(fid: str, action: str) -> dict[str, Pose]:
    idle = identity_idle(fid)
    if action in {"heavy", "smash_forward"}:
        return heavy_sequence(fid)
    if action in {"hurt_heavy", "hurt_heavy_front", "hurt_stagger"}:
        return hurt_heavy_sequence(fid)
    if action == "hurt_heavy_back":
        seq = hurt_heavy_sequence(fid)
        return {k: add(v, {"Spine": _e(-0.22, 0.0, 0.0), "Chest": _e(-0.28, 0.0, 0.0)}) for k, v in seq.items()}
    if action == "personality_idle":
        beat = personality_idle(fid)
        return {k: mix(idle, beat, t) for k, t in {"SETTLE": 0.0, "ANTICIPATION": 0.35, "CONTACT": 1.0, "FOLLOW_THROUGH": 0.55, "RETURN": 0.0}.items()}
    if action == "charged_idle" or action == "charge_full":
        charged = charged_idle(fid)
        return {
            "SETTLE": idle,
            "ANTICIPATION": mix(idle, charged, 0.55),
            "CONTACT": charged,
            "FOLLOW_THROUGH": charged,
            "RETURN": charged,
        }
    if action == "charge_start":
        return {"SETTLE": idle, "CONTACT": mix(idle, charged_idle(fid), 0.45), "RETURN": mix(idle, charged_idle(fid), 0.55)}
    if action == "charge_low":
        return {"SETTLE": mix(idle, charged_idle(fid), 0.30), "RETURN": mix(idle, charged_idle(fid), 0.35)}
    if action == "charge_mid":
        return {"SETTLE": mix(idle, charged_idle(fid), 0.55), "RETURN": mix(idle, charged_idle(fid), 0.60)}
    if action == "charge_high":
        return {"SETTLE": mix(idle, charged_idle(fid), 0.80), "RETURN": mix(idle, charged_idle(fid), 0.85)}
    if action.startswith("charged_"):
        charged = charged_idle(fid)
        kind = action.replace("charged_", "")
        if kind in {"walk", "run", "dash"}:
            return {
                "SETTLE": add(charged, scale_pose(_loco_pose(fid, 0.0, kind), 0.0)),
                "CONTACT": add(charged, {b: (x * 0.7, y * 0.7, z * 0.7) for b, (x, y, z) in add(blank(), _loco_pose(fid, 0.25, kind)).items()}),
                "RETURN": charged,
            }
        return {"SETTLE": charged, "RETURN": charged}
    if action in {"walk", "run", "dash"}:
        return {
            "SETTLE": _loco_pose(fid, 0.00, action),
            "ANTICIPATION": _loco_pose(fid, 0.25, action),
            "CONTACT": _loco_pose(fid, 0.50, action),
            "FOLLOW_THROUGH": _loco_pose(fid, 0.75, action),
            "RETURN": _loco_pose(fid, 1.00, action),
        }
    if action in {"walk_start", "run_start"}:
        kind = "walk" if "walk" in action else "run"
        return {"SETTLE": idle, "CONTACT": _loco_pose(fid, 0.15, kind), "RETURN": _loco_pose(fid, 0.30, kind)}
    if action in {"walk_stop", "run_stop", "dash_stop"}:
        kind = "walk" if "walk" in action else "run" if "run" in action else "dash"
        return {"SETTLE": _loco_pose(fid, 0.2, kind), "CONTACT": mix(_loco_pose(fid, 0.1, kind), idle, 0.6), "RETURN": idle}
    if action in {"jump", "double_jump", "jump_apex"}:
        return {"SETTLE": attack_pose(fid, "land"), "CONTACT": attack_pose(fid, "jump"), "RETURN": attack_pose(fid, "jump")}
    if action in {"jump_squat", "landing", "land_soft", "land_hard", "charged_land"}:
        land = attack_pose(fid, "land")
        return {"SETTLE": idle, "CONTACT": land, "RETURN": mix(land, idle, 0.55)}
    if action in {"fall", "fast_fall", "charged_fall"}:
        return {"SETTLE": attack_pose(fid, "jump"), "RETURN": attack_pose(fid, "jump")}
    if action.startswith("jab"):
        wind = add(idle, {"UpperArm_R": _e(-0.42, -0.55, 0.22), "Chest": _e(-0.12, -0.18, 0.0)})
        hit = attack_pose(fid, "jab")
        return {"SETTLE": idle, "ANTICIPATION": wind, "CONTACT": hit, "FOLLOW_THROUGH": mix(hit, idle, 0.4), "RETURN": idle}
    if action.startswith("tilt") or action.startswith("aerial"):
        style = "kick" if action.endswith("down") or "back" in action else "tilt"
        wind = add(idle, {"Spine": _e(-0.28, -0.18, 0.0), "UpperArm_R": _e(-0.55, -0.72, 0.22)})
        hit = attack_pose(fid, style)
        return {"SETTLE": idle, "ANTICIPATION": wind, "CONTACT": hit, "OVERSHOOT": add(hit, {"Chest": _e(0.12, 0.10, 0.0)}), "RETURN": idle}
    if action.startswith("signature") or action in {"aura_signature", "aura_release"}:
        wind = attack_pose(fid, "aura")
        hit = add(wind, {"Chest": _e(0.85, 0.22, 0.0), "UpperArm_R": _e(0.95, 1.15, 0.42), "Hips": _e(-0.18, 0.28, 0.0)})
        return {"SETTLE": idle, "ANTICIPATION": wind, "CONTACT": hit, "HITSTOP_HOLD": hit, "FOLLOW_THROUGH": mix(hit, idle, 0.35), "RETURN": idle}
    if action in {"aura_burst_super_pose"}:
        wind = attack_pose(fid, "super")
        hit = add(wind, {"Chest": _e(1.05, 0.28, 0.0), "UpperArm_R": _e(0.72, 1.28, 0.55), "Head": _e(-0.22, 0.16, 0.0)})
        return {"SETTLE": idle, "ANTICIPATION": wind, "CONTACT": hit, "OVERSHOOT": add(hit, {"Hips": _e(-0.12, 0.0, 0.0)}), "RETURN": mix(hit, idle, 0.4)}
    if action.startswith("clash"):
        lock = attack_pose(fid, "clash")
        win = add(lock, {"Chest": _e(-0.18, 0.22, 0.0), "Hips": _e(-0.12, 0.16, 0.0)})
        lose = add(lock, {"Chest": _e(0.28, -0.16, 0.0), "Head": _e(0.22, -0.12, 0.0)})
        if "winning" in action:
            lock = win
        if "losing" in action:
            lock = lose
        return {"SETTLE": idle, "CONTACT": lock, "RETURN": mix(lock, idle, 0.3 if "break" in action else 0.0)}
    if action.startswith("hurt") or action in {"launch", "launch_tumble", "tumble", "ground_bounce", "wall_splat"}:
        return hurt_heavy_sequence(fid) if "heavy" in action or action in {"launch", "tumble"} else {
            "SETTLE": idle,
            "CONTACT": attack_pose(fid, "hurt_light"),
            "RETURN": idle,
        }
    if action in {"ko", "ko_reaction", "ko_launch", "defeat"}:
        return {"SETTLE": idle, "CONTACT": attack_pose(fid, "ko"), "RETURN": attack_pose(fid, "ko")}
    if action.startswith("throw") or action == "grab":
        return {"SETTLE": idle, "ANTICIPATION": attack_pose(fid, "grab"), "CONTACT": attack_pose(fid, "throw"), "RETURN": idle}
    if action in {"shield", "shield_hit_light", "shield_hit_heavy"}:
        guard = add(idle, {"UpperArm_R": _e(0.42, 0.55, 0.72), "UpperArm_L": _e(0.42, -0.55, -0.72), "Chest": _e(0.16, 0.0, 0.0)})
        return {"SETTLE": guard, "CONTACT": add(guard, {"Chest": _e(0.18, 0.0, 0.0)}), "RETURN": guard}
    if action.startswith("projectile"):
        return {
            "SETTLE": idle,
            "ANTICIPATION": add(idle, {"UpperArm_R": _e(-0.55, -0.72, 0.22), "Chest": _e(-0.16, -0.12, 0.0)}),
            "CONTACT": add(idle, {"UpperArm_R": _e(0.22, 0.82, 0.55), "Chest": _e(0.22, 0.28, 0.0)}),
            "RETURN": idle,
        }
    if action == "turn":
        return {"SETTLE": idle, "CONTACT": add(idle, {"Hips": _e(0.0, 0.55, 0.0), "Chest": _e(0.0, 0.72, 0.0)}), "RETURN": idle}
    if action == "crouch":
        return {"SETTLE": attack_pose(fid, "land"), "RETURN": attack_pose(fid, "land")}
    if action == "victory":
        return {"SETTLE": idle, "CONTACT": personality_idle(fid), "RETURN": personality_idle(fid)}
    if action in {"dodge", "air_dodge", "air_drift", "recovery"}:
        return {
            "SETTLE": idle,
            "CONTACT": add(idle, {"Hips": _e(-0.18, 0.28, 0.0), "Chest": _e(-0.22, 0.22, 0.0), "UpperArm_R": _e(-0.42, -0.55, 0.22)}),
            "RETURN": idle,
        }
    return {"SETTLE": idle, "CONTACT": idle, "RETURN": idle}


def pose_delta_metrics(a: Pose, b: Pose) -> dict:
    pelvis = math.dist(a.get("Hips", ZERO), b.get("Hips", ZERO))
    chest = math.dist(a.get("Chest", ZERO), b.get("Chest", ZERO))
    arm = math.dist(a.get("UpperArm_R", ZERO), b.get("UpperArm_R", ZERO))
    head = math.dist(a.get("Head", ZERO), b.get("Head", ZERO))
    silhouette = 0.0
    for bone in POSE_BONES:
        silhouette += math.dist(a.get(bone, ZERO), b.get(bone, ZERO))
    return {
        "pelvis_rotation": round(pelvis, 4),
        "chest_rotation": round(chest, 4),
        "arm_travel": round(arm, 4),
        "head_reaction": round(head, 4),
        "silhouette_delta": round(silhouette, 4),
    }
