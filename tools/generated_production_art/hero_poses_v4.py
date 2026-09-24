"""Fighter-specific hero poses for the v4 craft pass. Generated motion, not human acting."""
from __future__ import annotations

from .hero_poses_v3 import (  # noqa: F401 — keep v3 sequences as the exaggeration floor
    heavy_sequence_v3,
    hurt_heavy_sequence_v3,
    walk_contact_v3,
    walk_sequence_v3,
)
from .pose_library import _e, add, mix
from .hero_poses_v3 import idle_v3 as _idle_v3
from .hero_poses_v3 import charge_100_v3 as _charge_v3
from .hero_poses_v3 import super_pose_v3 as _super_v3


def idle_v4(fid: str):
    """No universal T-pose. Distinct center of mass per fighter."""
    base = _idle_v3(fid)
    extras = {
        "ember-vale": {
            "Hips": _e(0.10, 0.16, 0.06),
            "Spine": _e(-0.22, 0.20, 0.10),
            "Chest": _e(-0.28, 0.26, 0.12),
            "Head": _e(0.10, 0.18, 0.04),
            "UpperArm_R": _e(0.18, -0.62, 0.36),
            "UpperArm_L": _e(0.28, 0.22, -0.28),
            "LowerArm_R": _e(0.28, -0.22, 0.12),
            "UpperLeg_R": _e(0.20, 0.08, 0.22),
        },
        "rook-ironside": {
            "Chest": _e(0.08, 0.0, 0.0),
            "Head": _e(-0.06, 0.0, 0.0),
            "UpperArm_R": _e(0.55, -0.18, 0.42),
            "UpperArm_L": _e(0.55, 0.18, -0.42),
            "LowerArm_R": _e(0.22, -0.08, 0.10),
            "LowerArm_L": _e(0.22, 0.08, -0.10),
            "UpperLeg_R": _e(0.26, 0.10, 0.40),
            "UpperLeg_L": _e(0.24, -0.10, -0.40),
            "Foot_R": _e(-0.10, 0.08, 0.06),
            "Foot_L": _e(-0.10, -0.08, -0.06),
        },
        "juno-spark": {
            "Hips": _e(0.04, 0.22, 0.0),
            "Chest": _e(-0.12, 0.18, 0.08),
            "Head": _e(0.16, -0.32, 0.12),
            "UpperArm_R": _e(0.12, -0.95, 0.08),
            "UpperArm_L": _e(-0.08, 0.78, -0.42),
            "LowerArm_L": _e(0.28, 0.22, -0.10),
            "UpperLeg_L": _e(-0.14, 0.10, -0.22),
        },
        "kaia-windrow": {
            "Hips": _e(0.06, 0.10, 0.12),
            "Spine": _e(-0.28, 0.16, 0.20),
            "Chest": _e(-0.22, 0.18, 0.16),
            "UpperArm_L": _e(-0.48, 0.62, -0.16),
            "UpperArm_R": _e(0.22, -0.22, 0.18),
            "UpperLeg_L": _e(-0.22, 0.14, -0.16),
            "Head": _e(0.14, 0.22, 0.06),
        },
        "nix-calder": {
            "Spine": _e(0.02, 0.0, 0.0),
            "Chest": _e(0.04, 0.0, 0.0),
            "UpperArm_R": _e(0.42, -0.16, 0.18),
            "UpperArm_L": _e(0.42, 0.16, -0.18),
            "LowerArm_R": _e(0.28, -0.12, 0.16),
            "LowerArm_L": _e(0.28, 0.12, -0.16),
            "Hand_R": _e(0.16, -0.18, 0.22),
            "Hand_L": _e(0.16, 0.18, -0.22),
            "Head": _e(0.04, 0.02, 0.0),
        },
        "orion-vell": {
            "Chest": _e(-0.12, 0.0, 0.0),
            "UpperArm_R": _e(-0.18, -0.48, 0.12),
            "UpperArm_L": _e(-0.22, 0.52, -0.14),
            "Hand_R": _e(0.32, -0.46, 0.36),
            "Hand_L": _e(0.22, 0.28, -0.22),
            "Head": _e(-0.12, 0.0, 0.0),
        },
        "vesper-nyx": {
            "Hips": _e(0.12, 0.32, 0.14),
            "Chest": _e(-0.14, -0.34, 0.16),
            "UpperArm_R": _e(0.08, -0.42, 0.10),
            "UpperArm_L": _e(0.32, 0.16, -0.22),
            "Head": _e(0.12, 0.38, -0.12),
            "UpperLeg_R": _e(0.10, 0.12, 0.18),
        },
    }[fid]
    return add(base, extras)


def charge_100_v4(fid: str):
    idle = idle_v4(fid)
    extras = {
        "ember-vale": {
            "Hips": _e(-0.24, 0.12, 0.0), "Spine": _e(-0.52, 0.18, 0.10), "Chest": _e(-0.78, 0.24, 0.12),
            "Head": _e(-0.28, 0.14, 0.0), "UpperArm_R": _e(-0.42, -0.58, 0.48), "UpperArm_L": _e(-0.22, 0.32, -0.28),
            "Hand_R": _e(0.18, -0.22, 0.20), "UpperLeg_R": _e(0.30, 0.10, 0.20),
        },
        "rook-ironside": {
            "Hips": _e(-0.16, 0.0, 0.0), "Spine": _e(-0.28, 0.0, 0.0), "Chest": _e(-0.42, 0.0, 0.0),
            "Head": _e(-0.14, 0.0, 0.0), "UpperArm_R": _e(0.48, -0.12, 0.55), "UpperArm_L": _e(0.48, 0.12, -0.55),
            "UpperLeg_R": _e(0.34, 0.12, 0.30), "UpperLeg_L": _e(0.34, -0.12, -0.30),
        },
        "juno-spark": {
            "Hips": _e(-0.10, 0.20, 0.0), "Spine": _e(-0.46, 0.14, 0.0), "Chest": _e(-0.68, 0.20, 0.0),
            "Head": _e(-0.16, -0.18, 0.08), "UpperArm_R": _e(-0.55, -0.82, 0.18), "UpperArm_L": _e(-0.22, 0.72, -0.28),
            "UpperLeg_L": _e(-0.14, 0.12, -0.18),
        },
        "kaia-windrow": {
            "Hips": _e(-0.18, 0.10, 0.12), "Spine": _e(-0.42, 0.18, 0.20), "Chest": _e(-0.56, 0.22, 0.22),
            "Head": _e(-0.16, 0.18, 0.08), "UpperArm_L": _e(-0.72, 0.58, -0.14), "UpperArm_R": _e(-0.18, -0.28, 0.16),
            "UpperLeg_L": _e(-0.24, 0.14, -0.14),
        },
        "nix-calder": {
            "Hips": _e(-0.12, 0.0, 0.0), "Spine": _e(-0.32, 0.0, 0.0), "Chest": _e(-0.48, 0.0, 0.0),
            "Head": _e(-0.16, 0.0, 0.0), "UpperArm_R": _e(0.22, -0.28, 0.32), "UpperArm_L": _e(0.22, 0.28, -0.32),
            "Hand_R": _e(0.20, -0.24, 0.20), "Hand_L": _e(0.20, 0.24, -0.20),
        },
        "orion-vell": {
            "Hips": _e(0.16, 0.0, 0.0), "Spine": _e(-0.58, 0.0, 0.0), "Chest": _e(-0.72, 0.0, 0.0),
            "Head": _e(-0.24, 0.0, 0.0), "UpperArm_R": _e(-0.42, -0.52, 0.18), "UpperArm_L": _e(-0.42, 0.52, -0.18),
            "Hand_R": _e(0.28, -0.36, 0.28),
        },
        "vesper-nyx": {
            "Hips": _e(-0.10, 0.34, 0.16), "Spine": _e(-0.36, -0.24, 0.16), "Chest": _e(-0.50, -0.30, 0.18),
            "Head": _e(-0.10, 0.38, -0.12), "UpperArm_R": _e(0.06, -0.62, 0.12), "UpperArm_L": _e(0.28, 0.22, -0.28),
        },
    }[fid]
    return add(idle, extras, 1.08)


def super_pose_v4(fid: str):
    """No universal arms-up. Character-specific line of action."""
    idle = idle_v4(fid)
    extras = {
        "ember-vale": {
            "Hips": _e(-0.36, 0.28, 0.10), "Spine": _e(0.48, 0.42, 0.14), "Chest": _e(0.78, 0.52, 0.16),
            "UpperArm_R": _e(0.12, 1.08, 0.92), "LowerArm_R": _e(0.10, 0.28, 0.14),
            "UpperArm_L": _e(-0.42, 0.28, -0.32), "Head": _e(-0.16, 0.24, 0.08), "UpperLeg_R": _e(0.30, 0.10, 0.18),
        },
        "rook-ironside": {
            "Hips": _e(-0.18, 0.0, 0.0), "Spine": _e(0.22, 0.12, 0.0), "Chest": _e(0.38, 0.16, 0.0),
            "UpperArm_R": _e(0.42, 0.55, 0.95), "LowerArm_R": _e(0.18, 0.16, 0.12),
            "UpperArm_L": _e(0.48, 0.12, -0.42), "Head": _e(-0.12, 0.10, 0.0),
            "UpperLeg_R": _e(0.36, 0.12, 0.34), "UpperLeg_L": _e(0.28, -0.10, -0.30),
        },
        "juno-spark": {
            "Hips": _e(-0.24, 0.62, 0.08), "Spine": _e(0.16, 0.78, 0.12), "Chest": _e(0.22, 0.98, 0.14),
            "UpperArm_R": _e(-0.28, 1.32, 0.28), "UpperArm_L": _e(0.42, -0.62, -0.32),
            "Head": _e(0.10, 0.46, 0.10), "UpperLeg_L": _e(-0.32, -0.14, -0.20),
        },
        "kaia-windrow": {
            "Hips": _e(-0.20, 0.18, 0.20), "Spine": _e(-0.18, 0.32, 0.36), "Chest": _e(-0.08, 0.38, 0.40),
            "UpperArm_L": _e(-1.05, 0.68, -0.16), "UpperArm_R": _e(-0.28, -0.18, 0.22),
            "Head": _e(0.14, 0.24, 0.12), "UpperLeg_L": _e(-0.46, 0.20, -0.18),
        },
        "nix-calder": {
            "Hips": _e(-0.14, 0.0, 0.0), "Spine": _e(-0.06, 0.0, 0.0), "Chest": _e(0.22, 0.10, 0.0),
            "UpperArm_R": _e(0.18, 0.62, 0.58), "LowerArm_R": _e(0.16, 0.18, 0.14),
            "UpperArm_L": _e(0.38, 0.16, -0.28), "Head": _e(-0.06, 0.08, 0.0), "Hand_R": _e(0.20, 0.24, 0.18),
        },
        "orion-vell": {
            "Hips": _e(0.10, 0.0, 0.0), "Spine": _e(-0.38, 0.0, 0.0), "Chest": _e(-0.16, 0.0, 0.0),
            "UpperArm_R": _e(-0.62, -0.72, 0.16), "UpperArm_L": _e(-0.28, 0.42, -0.16),
            "Hand_R": _e(0.36, -0.52, 0.42), "Head": _e(-0.18, 0.0, 0.0),
        },
        "vesper-nyx": {
            "Hips": _e(-0.18, 0.42, 0.18), "Spine": _e(0.26, -0.22, 0.20), "Chest": _e(0.42, -0.32, 0.22),
            "UpperArm_R": _e(0.08, 0.72, 0.38), "UpperArm_L": _e(-0.38, -0.55, -0.18),
            "Head": _e(0.08, 0.46, -0.16), "UpperLeg_R": _e(0.14, 0.18, 0.20),
        },
    }[fid]
    return add(idle, extras)


def super_sequence_v4(fid: str) -> dict:
    idle = idle_v4(fid)
    hit = super_pose_v4(fid)
    wind = mix(idle, hit, 0.42)
    return {
        "SETTLE": idle,
        "ANTICIPATION": wind,
        "CONTACT": hit,
        "HITSTOP_HOLD": hit,
        "OVERSHOOT": add(hit, {"Hips": _e(-0.08, 0.0, 0.0)}),
        "FOLLOW_THROUGH": mix(hit, idle, 0.28),
        "RETURN": mix(hit, idle, 0.42),
    }


def personality_idle_v4(fid: str):
    idle = idle_v4(fid)
    extras = {
        "ember-vale": {"Chest": _e(-0.12, 0.18, 0.08), "Head": _e(0.10, 0.16, 0.06)},
        "rook-ironside": {"Chest": _e(0.08, 0.0, 0.0), "Head": _e(-0.08, 0.0, 0.0)},
        "juno-spark": {"Head": _e(0.22, -0.28, 0.10), "UpperArm_R": _e(0.08, -0.22, 0.08)},
        "kaia-windrow": {"Spine": _e(-0.10, 0.12, 0.10), "UpperArm_L": _e(-0.18, 0.16, -0.08)},
        "nix-calder": {"Head": _e(0.06, 0.04, 0.0), "Hand_R": _e(0.08, -0.10, 0.08)},
        "orion-vell": {"Hand_R": _e(0.16, -0.18, 0.16), "Head": _e(-0.08, 0.0, 0.0)},
        "vesper-nyx": {"Hips": _e(0.08, 0.16, 0.08), "Head": _e(0.10, 0.22, -0.08)},
    }[fid]
    return add(idle, extras)


# Compatibility aliases used by pose_library / validators.
idle_v3 = idle_v4
charge_100_v3 = charge_100_v4
super_pose_v3 = super_pose_v4
super_sequence_v3 = super_sequence_v4
