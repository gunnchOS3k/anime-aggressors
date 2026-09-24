"""Fighter-specific hero poses for the v3 craft pass. Generated motion, not human acting."""
from __future__ import annotations

from .pose_library import _e, add, identity_idle, mix
from .profiles import profile


def idle_v3(fid: str):
    base = identity_idle(fid)
    extras = {
        "ember-vale": {
            "Hips": _e(0.06, 0.12, 0.04),
            "Spine": _e(-0.16, 0.18, 0.08),
            "Chest": _e(-0.22, 0.24, 0.10),
            "Head": _e(0.14, 0.16, 0.06),
            "UpperArm_R": _e(0.10, -0.55, 0.48),
            "LowerArm_R": _e(0.22, -0.28, 0.16),
            "Hand_R": _e(0.18, -0.16, 0.22),
            "UpperLeg_R": _e(0.16, 0.06, 0.18),
        },
        "rook-ironside": {
            "Chest": _e(0.10, 0.0, 0.0),
            "Head": _e(-0.08, 0.0, 0.0),
            "UpperArm_R": _e(0.42, -0.22, 0.62),
            "UpperArm_L": _e(0.42, 0.22, -0.62),
            "UpperLeg_R": _e(0.22, 0.08, 0.36),
            "UpperLeg_L": _e(0.20, -0.08, -0.36),
            "Foot_R": _e(-0.08, 0.06, 0.04),
            "Foot_L": _e(-0.08, -0.06, -0.04),
        },
        "juno-spark": {
            "Hips": _e(0.0, 0.16, 0.0),
            "Head": _e(0.20, -0.28, 0.10),
            "UpperArm_R": _e(0.04, -0.82, 0.12),
            "UpperArm_L": _e(-0.18, 0.72, -0.48),
            "LowerArm_L": _e(0.22, 0.18, -0.12),
            "UpperLeg_L": _e(-0.10, 0.08, -0.18),
        },
        "kaia-windrow": {
            "Spine": _e(-0.22, 0.12, 0.16),
            "Chest": _e(-0.18, 0.14, 0.12),
            "UpperArm_L": _e(-0.42, 0.68, -0.18),
            "UpperArm_R": _e(0.08, -0.28, 0.22),
            "UpperLeg_L": _e(-0.18, 0.12, -0.14),
            "Head": _e(0.18, 0.20, 0.04),
        },
        "nix-calder": {
            "Spine": _e(0.04, 0.0, 0.0),
            "Chest": _e(0.02, 0.0, 0.0),
            "UpperArm_R": _e(0.16, -0.24, 0.28),
            "UpperArm_L": _e(0.16, 0.24, -0.28),
            "Hand_R": _e(0.12, -0.16, 0.18),
            "Hand_L": _e(0.12, 0.16, -0.18),
            "Head": _e(0.06, 0.04, 0.0),
        },
        "orion-vell": {
            "Chest": _e(-0.08, 0.0, 0.0),
            "UpperArm_R": _e(-0.28, -0.58, 0.18),
            "UpperArm_L": _e(-0.32, 0.64, -0.20),
            "Hand_R": _e(0.28, -0.40, 0.32),
            "Hand_L": _e(0.28, 0.40, -0.32),
            "Head": _e(-0.10, 0.0, 0.0),
        },
        "vesper-nyx": {
            "Hips": _e(0.10, 0.28, 0.12),
            "Chest": _e(-0.10, -0.30, 0.14),
            "UpperArm_R": _e(-0.28, -0.78, 0.16),
            "UpperArm_L": _e(0.18, 0.22, -0.28),
            "Head": _e(0.14, 0.34, -0.10),
            "UpperLeg_R": _e(0.08, 0.10, 0.16),
        },
    }[fid]
    return add(base, extras)


def walk_contact_v3(fid: str):
    idle = idle_v3(fid)
    extras = {
        "ember-vale": {"Chest": _e(-0.12, 0.18, 0.06), "UpperArm_R": _e(0.08, 0.55, 0.12), "UpperLeg_L": _e(0.42, 0.0, -0.08)},
        "rook-ironside": {"Hips": _e(0.06, 0.0, 0.0), "UpperLeg_R": _e(0.28, 0.0, 0.10), "Chest": _e(0.04, 0.06, 0.0)},
        "juno-spark": {"UpperArm_R": _e(0.04, 0.72, 0.08), "UpperLeg_L": _e(0.55, 0.0, -0.06), "Head": _e(0.08, -0.12, 0.0)},
        "kaia-windrow": {"Spine": _e(-0.10, 0.12, 0.10), "UpperArm_L": _e(-0.16, 0.42, -0.08), "UpperLeg_R": _e(0.38, 0.08, 0.06)},
        "nix-calder": {"Chest": _e(0.02, 0.06, 0.0), "UpperArm_R": _e(0.04, 0.22, 0.08), "UpperLeg_L": _e(0.28, 0.0, -0.04)},
        "orion-vell": {"UpperArm_R": _e(-0.08, 0.18, 0.10), "UpperLeg_L": _e(0.24, 0.0, -0.06), "Head": _e(-0.04, 0.0, 0.0)},
        "vesper-nyx": {"Hips": _e(0.04, 0.12, 0.06), "UpperArm_R": _e(-0.10, 0.48, 0.08), "UpperLeg_L": _e(0.36, 0.08, -0.08)},
    }[fid]
    return add(idle, extras)


def heavy_sequence_v3(fid: str) -> dict:
    p = profile(fid)
    idle = idle_v3(fid)
    if fid == "ember-vale":
        anticipation = add(idle, {
            "Hips": _e(0.18, -0.22, 0.08), "Spine": _e(-0.62, -0.48, 0.14), "Chest": _e(-0.82, -0.62, 0.16),
            "Head": _e(0.18, -0.20, 0.0), "UpperArm_R": _e(-0.95, -1.72, 0.62), "LowerArm_R": _e(0.18, -1.12, 0.28),
            "Hand_R": _e(0.32, -0.70, 0.40), "UpperLeg_R": _e(0.38, 0.10, 0.16),
        }, 1.05)
        contact = add(idle, {
            "Hips": _e(-0.42, 0.72, 0.10), "Spine": _e(0.62, 0.78, 0.16), "Chest": _e(0.95, 0.95, 0.18),
            "UpperArm_R": _e(0.22, 1.18, 1.22), "LowerArm_R": _e(0.10, 0.42, 0.18), "Hand_R": _e(0.22, 0.28, 0.16),
            "UpperArm_L": _e(0.38, 0.28, -0.28), "Head": _e(-0.16, 0.32, 0.08), "UpperLeg_R": _e(0.48, 0.08, 0.18),
        }, 1.12)
    elif fid == "rook-ironside":
        anticipation = add(idle, {
            "Hips": _e(0.28, -0.08, 0.06), "Spine": _e(-0.42, -0.22, 0.08), "Chest": _e(-0.55, -0.28, 0.08),
            "UpperArm_R": _e(-1.15, -0.55, 0.88), "LowerArm_R": _e(0.10, -0.42, 0.18), "UpperLeg_R": _e(0.48, 0.10, 0.28),
            "UpperLeg_L": _e(0.22, -0.08, -0.24), "Head": _e(0.10, 0.0, 0.0),
        }, 1.18)
        contact = add(idle, {
            "Hips": _e(-0.22, 0.42, 0.08), "Spine": _e(0.48, 0.38, 0.10), "Chest": _e(0.72, 0.48, 0.10),
            "UpperArm_R": _e(0.55, 0.62, 1.28), "LowerArm_R": _e(0.18, 0.22, 0.16), "Hand_R": _e(0.16, 0.18, 0.12),
            "UpperLeg_R": _e(0.62, 0.12, 0.28), "LowerLeg_R": _e(0.12, 0.0, 0.0), "Head": _e(-0.08, 0.12, 0.0),
        }, 1.22)
    elif fid == "juno-spark":
        anticipation = add(idle, {
            "Hips": _e(0.08, -0.28, 0.10), "Spine": _e(-0.38, -0.62, 0.18), "Chest": _e(-0.48, -0.78, 0.20),
            "UpperArm_R": _e(-0.55, -1.88, 0.28), "LowerArm_R": _e(0.28, -0.88, 0.16), "Head": _e(0.22, -0.34, 0.10),
        }, 0.95)
        contact = add(idle, {
            "Hips": _e(-0.28, 0.82, 0.08), "Spine": _e(0.42, 0.95, 0.16), "Chest": _e(0.58, 1.12, 0.18),
            "UpperArm_R": _e(0.08, 1.42, 0.72), "LowerArm_R": _e(0.06, 0.62, 0.12), "Head": _e(-0.08, 0.42, 0.08),
            "UpperLeg_L": _e(-0.22, -0.12, -0.18),
        }, 1.00)
    elif fid == "kaia-windrow":
        anticipation = add(idle, {
            "Hips": _e(0.12, -0.16, 0.16), "Spine": _e(-0.55, -0.38, 0.28), "Chest": _e(-0.62, -0.42, 0.32),
            "UpperArm_R": _e(-0.72, -1.42, 0.22), "UpperArm_L": _e(-0.55, 0.82, -0.18), "Head": _e(0.16, -0.18, 0.12),
            "UpperLeg_L": _e(-0.28, 0.16, -0.18),
        }, 1.00)
        contact = add(idle, {
            "Hips": _e(-0.32, 0.55, 0.18), "Spine": _e(0.48, 0.72, 0.28), "Chest": _e(0.62, 0.88, 0.32),
            "UpperArm_R": _e(-0.18, 1.28, 0.55), "UpperArm_L": _e(-0.42, 0.95, -0.22),
            "Head": _e(-0.10, 0.28, 0.14), "UpperLeg_R": _e(0.22, 0.18, 0.16),
        }, 1.04)
    elif fid == "nix-calder":
        anticipation = add(idle, {
            "Hips": _e(0.10, -0.08, 0.0), "Spine": _e(-0.28, -0.22, 0.06), "Chest": _e(-0.38, -0.28, 0.06),
            "UpperArm_R": _e(-0.62, -1.05, 0.42), "LowerArm_R": _e(0.32, -0.55, 0.18), "Head": _e(0.08, -0.10, 0.0),
        }, 1.00)
        contact = add(idle, {
            "Hips": _e(-0.22, 0.38, 0.04), "Spine": _e(0.38, 0.48, 0.08), "Chest": _e(0.52, 0.58, 0.08),
            "UpperArm_R": _e(0.12, 0.95, 0.88), "LowerArm_R": _e(0.08, 0.28, 0.12), "Hand_R": _e(0.18, 0.22, 0.16),
            "Head": _e(-0.06, 0.14, 0.04),
        }, 1.02)
    elif fid == "orion-vell":
        anticipation = add(idle, {
            "Hips": _e(0.22, 0.0, 0.0), "Spine": _e(-0.72, 0.0, 0.0), "Chest": _e(-0.88, 0.0, 0.0),
            "UpperArm_R": _e(-0.82, -0.72, 0.42), "UpperArm_L": _e(-0.82, 0.72, -0.42), "Head": _e(-0.22, 0.0, 0.0),
            "UpperLeg_R": _e(0.28, 0.0, 0.12),
        }, 1.08)
        contact = add(idle, {
            "Hips": _e(-0.38, 0.18, 0.0), "Spine": _e(0.62, 0.28, 0.08), "Chest": _e(0.85, 0.34, 0.08),
            "UpperArm_R": _e(0.28, 0.82, 0.72), "UpperArm_L": _e(-0.18, 0.55, -0.28),
            "Head": _e(-0.18, 0.12, 0.0),
        }, 1.10)
    else:  # vesper delayed snap
        anticipation = add(idle, {
            "Hips": _e(0.16, 0.22, 0.12), "Spine": _e(-0.28, -0.18, 0.16), "Chest": _e(-0.22, -0.34, 0.18),
            "UpperArm_R": _e(-0.42, -1.05, 0.18), "Head": _e(0.18, 0.28, -0.10),
        }, 1.00)
        contact = add(idle, {
            "Hips": _e(-0.34, 0.68, 0.10), "Spine": _e(0.55, 0.88, 0.16), "Chest": _e(0.72, 1.05, 0.18),
            "UpperArm_R": _e(0.10, 1.32, 0.82), "LowerArm_R": _e(0.08, 0.48, 0.16),
            "Head": _e(-0.12, 0.38, 0.08), "UpperArm_L": _e(0.22, -0.28, -0.22),
        }, 1.08)
    follow = add(contact, {"Chest": _e(0.12, 0.10, 0.0), "UpperArm_R": _e(0.08, 0.16, 0.10), "Head": _e(-0.06, 0.08, 0.0)})
    return {
        "SETTLE": idle,
        "ANTICIPATION": anticipation,
        "ACCELERATION": mix(anticipation, contact, 0.55),
        "CONTACT": contact,
        "HITSTOP_HOLD": contact,
        "OVERSHOOT": follow,
        "FOLLOW_THROUGH": mix(contact, idle, 0.32),
        "RECOVERY": mix(contact, idle, 0.68),
        "RETURN": mix(contact, idle, 0.90),
    }


def hurt_heavy_sequence_v3(fid: str) -> dict:
    idle = idle_v3(fid)
    if fid == "ember-vale":
        impact = add(idle, {
            "Hips": _e(0.32, -0.18, 0.08), "Spine": _e(0.88, -0.12, 0.10), "Chest": _e(1.12, -0.16, 0.12),
            "Head": _e(0.95, -0.22, 0.16), "UpperArm_R": _e(0.72, 0.48, 0.62), "UpperArm_L": _e(0.68, -0.42, -0.60),
            "UpperLeg_R": _e(0.38, 0.10, 0.12),
        })
    elif fid == "rook-ironside":
        impact = add(idle, {
            "Hips": _e(0.18, -0.28, 0.06), "Spine": _e(0.42, -0.22, 0.08), "Chest": _e(0.58, -0.26, 0.10),
            "Head": _e(0.52, -0.18, 0.08), "UpperArm_R": _e(0.38, 0.28, 0.48), "UpperArm_L": _e(0.38, -0.28, -0.48),
            "UpperLeg_R": _e(0.28, 0.12, 0.22), "UpperLeg_L": _e(0.26, -0.12, -0.20),
        })
    elif fid == "juno-spark":
        impact = add(idle, {
            "Hips": _e(0.12, 0.42, 0.16), "Spine": _e(0.55, 0.62, 0.22), "Chest": _e(0.72, 0.78, 0.24),
            "Head": _e(0.68, 0.55, 0.20), "UpperArm_R": _e(0.82, 0.72, 0.88), "UpperArm_L": _e(-0.22, -0.62, -0.55),
            "UpperLeg_L": _e(-0.18, -0.16, -0.22),
        })
    elif fid == "kaia-windrow":
        impact = add(idle, {
            "Hips": _e(0.22, -0.16, 0.22), "Spine": _e(0.62, -0.28, 0.34), "Chest": _e(0.78, -0.32, 0.38),
            "Head": _e(0.92, -0.42, 0.28), "UpperArm_L": _e(-0.55, 0.88, -0.22), "UpperArm_R": _e(0.48, 0.22, 0.42),
            "UpperLeg_L": _e(-0.32, 0.18, -0.16),
        })
    elif fid == "nix-calder":
        impact = add(idle, {
            "Hips": _e(0.28, -0.08, 0.04), "Spine": _e(0.62, -0.10, 0.06), "Chest": _e(0.82, -0.12, 0.08),
            "Head": _e(0.72, -0.16, 0.10), "UpperArm_R": _e(0.48, 0.32, 0.48), "UpperArm_L": _e(0.48, -0.32, -0.48),
            "UpperLeg_R": _e(0.28, 0.08, 0.10), "UpperLeg_L": _e(0.24, -0.06, -0.08),
            "LowerArm_R": _e(0.16, 0.12, 0.08), "LowerArm_L": _e(0.16, -0.12, -0.08),
        })
    elif fid == "orion-vell":
        impact = add(idle, {
            "Hips": _e(0.38, 0.0, 0.0), "Spine": _e(0.82, 0.0, 0.0), "Chest": _e(1.05, 0.0, 0.0),
            "Head": _e(0.72, 0.0, 0.0), "UpperArm_R": _e(0.55, 0.42, 0.55), "UpperArm_L": _e(0.55, -0.42, -0.55),
            "UpperLeg_R": _e(0.32, 0.0, 0.10), "UpperLeg_L": _e(0.32, 0.0, -0.10),
        })
    else:
        impact = add(idle, {
            "Hips": _e(0.16, -0.38, 0.18), "Spine": _e(0.42, -0.48, 0.22), "Chest": _e(0.55, -0.62, 0.24),
            "Head": _e(0.48, -0.55, 0.20), "UpperArm_R": _e(-0.22, -0.72, 0.18), "UpperArm_L": _e(0.62, 0.28, -0.42),
            "UpperLeg_R": _e(0.18, 0.16, 0.20),
        })
    peak = add(impact, {"Head": _e(0.22, -0.10, 0.08), "Chest": _e(0.16, -0.08, 0.06), "Hips": _e(0.10, -0.06, 0.0)})
    crumple = mix(impact, idle, 0.35)
    launch = add(idle, {
        "Hips": _e(-0.22, 0.16, 0.0), "Spine": _e(-0.52, 0.18, 0.0), "Chest": _e(-0.58, 0.16, 0.0),
        "Head": _e(-0.42, 0.14, 0.0), "UpperArm_R": _e(-0.62, -0.38, 0.22), "UpperArm_L": _e(-0.60, 0.36, -0.20),
    })
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


def charge_100_v3(fid: str):
    idle = idle_v3(fid)
    extras = {
        "ember-vale": {
            "Hips": _e(-0.22, 0.10, 0.0), "Spine": _e(-0.48, 0.16, 0.08), "Chest": _e(-0.72, 0.22, 0.10),
            "Head": _e(-0.32, 0.12, 0.0), "UpperArm_R": _e(-0.62, -0.72, 0.62), "UpperArm_L": _e(-0.52, 0.58, -0.48),
            "UpperLeg_R": _e(0.28, 0.08, 0.18), "UpperLeg_L": _e(0.22, -0.06, -0.14),
        },
        "rook-ironside": {
            "Hips": _e(-0.12, 0.0, 0.0), "Spine": _e(-0.22, 0.0, 0.0), "Chest": _e(-0.38, 0.0, 0.0),
            "Head": _e(-0.16, 0.0, 0.0), "UpperArm_R": _e(0.22, -0.18, 0.82), "UpperArm_L": _e(0.22, 0.18, -0.82),
            "UpperLeg_R": _e(0.32, 0.10, 0.28), "UpperLeg_L": _e(0.32, -0.10, -0.28),
        },
        "juno-spark": {
            "Hips": _e(-0.08, 0.18, 0.0), "Spine": _e(-0.42, 0.12, 0.0), "Chest": _e(-0.62, 0.18, 0.0),
            "Head": _e(-0.18, -0.16, 0.08), "UpperArm_R": _e(-0.72, -0.88, 0.28), "UpperArm_L": _e(-0.55, 0.95, -0.32),
            "UpperLeg_L": _e(-0.12, 0.10, -0.16),
        },
        "kaia-windrow": {
            "Hips": _e(-0.16, 0.08, 0.10), "Spine": _e(-0.38, 0.16, 0.18), "Chest": _e(-0.52, 0.20, 0.20),
            "Head": _e(-0.18, 0.16, 0.08), "UpperArm_L": _e(-0.82, 0.72, -0.16), "UpperArm_R": _e(-0.28, -0.42, 0.22),
            "UpperLeg_L": _e(-0.22, 0.12, -0.12),
        },
        "nix-calder": {
            "Hips": _e(-0.10, 0.0, 0.0), "Spine": _e(-0.28, 0.0, 0.0), "Chest": _e(-0.42, 0.0, 0.0),
            "Head": _e(-0.18, 0.0, 0.0), "UpperArm_R": _e(-0.38, -0.42, 0.42), "UpperArm_L": _e(-0.38, 0.42, -0.42),
            "Hand_R": _e(0.16, -0.22, 0.18), "Hand_L": _e(0.16, 0.22, -0.18),
        },
        "orion-vell": {
            "Hips": _e(0.18, 0.0, 0.0), "Spine": _e(-0.62, 0.0, 0.0), "Chest": _e(-0.82, 0.0, 0.0),
            "Head": _e(-0.28, 0.0, 0.0), "UpperArm_R": _e(-0.72, -0.68, 0.28), "UpperArm_L": _e(-0.72, 0.68, -0.28),
            "UpperLeg_R": _e(0.22, 0.0, 0.10),
        },
        "vesper-nyx": {
            "Hips": _e(-0.08, 0.32, 0.14), "Spine": _e(-0.34, -0.22, 0.16), "Chest": _e(-0.48, -0.28, 0.18),
            "Head": _e(-0.12, 0.36, -0.12), "UpperArm_R": _e(-0.55, -0.95, 0.18), "UpperArm_L": _e(0.22, 0.28, -0.32),
        },
    }[fid]
    return add(idle, extras, 1.08)


def super_pose_v3(fid: str):
    idle = idle_v3(fid)
    extras = {
        "ember-vale": {
            "Hips": _e(-0.32, 0.22, 0.08), "Spine": _e(0.42, 0.38, 0.12), "Chest": _e(0.72, 0.48, 0.14),
            "UpperArm_R": _e(0.18, 1.22, 1.05), "LowerArm_R": _e(0.08, 0.32, 0.16),
            "UpperArm_L": _e(-0.55, 0.42, -0.38), "Head": _e(-0.18, 0.22, 0.08), "UpperLeg_R": _e(0.28, 0.08, 0.16),
        },
        "rook-ironside": {
            "Hips": _e(-0.12, 0.0, 0.0), "Spine": _e(-0.18, 0.0, 0.0), "Chest": _e(0.22, 0.0, 0.0),
            "UpperArm_R": _e(0.72, -0.18, 1.05), "UpperArm_L": _e(0.72, 0.18, -1.05),
            "LowerArm_R": _e(0.22, 0.0, 0.12), "LowerArm_L": _e(0.22, 0.0, -0.12),
            "Head": _e(-0.16, 0.0, 0.0), "UpperLeg_R": _e(0.32, 0.10, 0.32), "UpperLeg_L": _e(0.32, -0.10, -0.32),
        },
        "juno-spark": {
            "Hips": _e(-0.22, 0.55, 0.08), "Spine": _e(0.18, 0.72, 0.12), "Chest": _e(0.28, 0.92, 0.14),
            "UpperArm_R": _e(-0.22, 1.48, 0.42), "UpperArm_L": _e(0.32, -0.55, -0.38),
            "Head": _e(0.12, 0.42, 0.10), "UpperLeg_L": _e(-0.28, -0.12, -0.18),
        },
        "kaia-windrow": {
            "Hips": _e(-0.18, 0.16, 0.18), "Spine": _e(-0.22, 0.28, 0.32), "Chest": _e(-0.12, 0.34, 0.36),
            "UpperArm_L": _e(-1.12, 0.72, -0.18), "UpperArm_R": _e(-0.42, -0.28, 0.28),
            "Head": _e(0.16, 0.22, 0.12), "UpperLeg_L": _e(-0.42, 0.18, -0.16), "UpperLeg_R": _e(0.18, 0.08, 0.12),
        },
        "nix-calder": {
            "Hips": _e(-0.12, 0.0, 0.0), "Spine": _e(-0.08, 0.0, 0.0), "Chest": _e(0.18, 0.12, 0.0),
            "UpperArm_R": _e(0.08, 0.88, 0.72), "LowerArm_R": _e(0.12, 0.22, 0.16),
            "UpperArm_L": _e(0.28, 0.22, -0.38), "Head": _e(-0.08, 0.10, 0.0), "Hand_R": _e(0.18, 0.22, 0.16),
        },
        "orion-vell": {
            "Hips": _e(0.12, 0.0, 0.0), "Spine": _e(-0.42, 0.0, 0.0), "Chest": _e(-0.22, 0.0, 0.0),
            "UpperArm_R": _e(-0.88, -0.82, 0.22), "UpperArm_L": _e(-0.88, 0.82, -0.22),
            "Hand_R": _e(0.32, -0.48, 0.38), "Hand_L": _e(0.32, 0.48, -0.38),
            "Head": _e(-0.22, 0.0, 0.0),
        },
        "vesper-nyx": {
            "Hips": _e(-0.16, 0.38, 0.16), "Spine": _e(0.22, -0.18, 0.18), "Chest": _e(0.38, -0.28, 0.20),
            "UpperArm_R": _e(0.18, 1.18, 0.55), "UpperArm_L": _e(-0.42, -0.62, -0.22),
            "Head": _e(0.10, 0.42, -0.14), "UpperLeg_R": _e(0.12, 0.16, 0.18),
        },
    }[fid]
    return add(idle, extras)


def super_sequence_v3(fid: str) -> dict:
    idle = idle_v3(fid)
    hit = super_pose_v3(fid)
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


def walk_sequence_v3(fid: str) -> dict:
    idle = idle_v3(fid)
    contact = walk_contact_v3(fid)
    opposite = add(
        idle,
        {
            "UpperArm_R": _e(0.04, 0.42, 0.08),
            "UpperArm_L": _e(0.04, -0.42, -0.08),
            "UpperLeg_R": _e(0.32, 0.0, 0.06),
            "UpperLeg_L": _e(-0.32, 0.0, -0.06),
        },
    )
    return {
        "SETTLE": idle,
        "ANTICIPATION": mix(idle, contact, 0.85),
        "CONTACT": contact,
        "FOLLOW_THROUGH": opposite,
        "RETURN": idle,
    }
