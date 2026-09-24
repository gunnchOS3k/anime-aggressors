"""Load per-fighter loft profiles. Do not derive all seven from one scaled body."""
from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROFILES_PATH = ROOT / "game-godot/data/art/generated_v5/fighter_body_profiles.json"
POSE_PATH = ROOT / "game-godot/data/art/generated_v5/hero_pose_profiles.json"

FIGHTER_IDS = (
    "ember-vale",
    "rook-ironside",
    "juno-spark",
    "kaia-windrow",
    "nix-calder",
    "orion-vell",
    "vesper-nyx",
)


@dataclass(frozen=True)
class BodyProfile:
    fighter_id: str
    display_name: str
    role: str
    element: str
    height: float
    shoulder_width: float
    chest_depth: float
    waist_width: float
    pelvis_width: float
    upper_arm_mass: float
    forearm_mass: float
    thigh_mass: float
    calf_mass: float
    hand_scale: float
    foot_scale: float
    neck_scale: float
    torso_taper: float
    limb_length: float
    asymmetry: dict = field(default_factory=dict)
    head_style: str = ""
    boot_style: str = ""
    hand_default: str = "fist"
    costume_profile: str = ""
    silhouette_intent: str = ""


def load_body_profiles(path: Path | None = None) -> dict[str, BodyProfile]:
    payload = json.loads((path or PROFILES_PATH).read_text(encoding="utf-8"))
    if payload.get("HUMAN_AUTHORED_ART_PASS") or payload.get("human_authored"):
        raise ValueError("v5 body profiles must remain generated, not human-authored")
    out: dict[str, BodyProfile] = {}
    for fid, row in payload["fighters"].items():
        out[fid] = BodyProfile(
            fighter_id=fid,
            display_name=str(row["display_name"]),
            role=str(row["role"]),
            element=str(row["element"]),
            height=float(row["height"]),
            shoulder_width=float(row["shoulder_width"]),
            chest_depth=float(row["chest_depth"]),
            waist_width=float(row["waist_width"]),
            pelvis_width=float(row["pelvis_width"]),
            upper_arm_mass=float(row["upper_arm_mass"]),
            forearm_mass=float(row["forearm_mass"]),
            thigh_mass=float(row["thigh_mass"]),
            calf_mass=float(row["calf_mass"]),
            hand_scale=float(row["hand_scale"]),
            foot_scale=float(row["foot_scale"]),
            neck_scale=float(row["neck_scale"]),
            torso_taper=float(row["torso_taper"]),
            limb_length=float(row["limb_length"]),
            asymmetry=dict(row.get("asymmetry") or {}),
            head_style=str(row["head_style"]),
            boot_style=str(row["boot_style"]),
            hand_default=str(row["hand_default"]),
            costume_profile=str(row["costume_profile"]),
            silhouette_intent=str(row["silhouette_intent"]),
        )
    missing = set(FIGHTER_IDS) - set(out)
    extra = set(out) - set(FIGHTER_IDS)
    if missing or extra:
        raise ValueError(f"v5 body profile roster mismatch missing={sorted(missing)} extra={sorted(extra)}")
    return out


BODY_PROFILES = load_body_profiles()


def body_profile(fid: str) -> BodyProfile:
    return BODY_PROFILES[fid]


def load_hero_poses(path: Path | None = None) -> dict:
    payload = json.loads((path or POSE_PATH).read_text(encoding="utf-8"))
    if payload.get("HUMAN_AUTHORED_ANIMATION_PASS") or payload.get("human_authored"):
        raise ValueError("v5 hero poses must remain generated, not human-authored")
    return payload.get("fighters") or {}
