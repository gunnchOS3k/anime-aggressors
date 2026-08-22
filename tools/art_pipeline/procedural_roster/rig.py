"""Canonical Wave012-compatible rig contract for procedural roster."""
from __future__ import annotations

CANONICAL_BONES = [
    "Root", "Hips", "Spine", "Chest", "Neck", "Head",
    "Shoulder_L", "UpperArm_L", "LowerArm_L", "Hand_L",
    "Shoulder_R", "UpperArm_R", "LowerArm_R", "Hand_R",
    "UpperLeg_L", "LowerLeg_L", "Foot_L", "Toes_L",
    "UpperLeg_R", "LowerLeg_R", "Foot_R", "Toes_R",
]

CANONICAL_SOCKETS = [
    "hand_l", "hand_r", "foot_l", "foot_r", "chest", "head", "back",
    "aura_root", "projectile_origin", "recovery_origin",
]


def rig_manifest(*, fighter_id: str, source: str) -> dict:
    return {
        "schema_version": 1,
        "fighter_id": fighter_id,
        "normalized": True,
        "wave012_compatible": True,
        "bones": list(CANONICAL_BONES),
        "sockets": list(CANONICAL_SOCKETS),
        "source": source,
        "root_motion_authority": "PHYSICS_AUTHORITATIVE",
        "competitive_gameplay_root_motion": "PHYSICS_AUTHORITATIVE",
    }
