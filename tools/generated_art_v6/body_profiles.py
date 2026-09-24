"""Load v6 style profiles. v5 loft proportions remain the understructure."""
from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROFILES_PATH = ROOT / "game-godot/data/art/generated_v6/fighter_style_profiles.json"
POSE_PATH = ROOT / "game-godot/data/art/generated_v6/hero_pose_profiles.json"
PALETTE_PATH = ROOT / "game-godot/data/art/generated_v6/palette_blocking.json"
STYLE_LOCK = ROOT / "docs/art/GENERATED_ART_V6_STYLE_LOCK.md"

FIGHTER_IDS = (
    "ember-vale",
    "rook-ironside",
    "juno-spark",
    "kaia-windrow",
    "nix-calder",
    "orion-vell",
    "vesper-nyx",
)

GLOVE_FAMILIES = (
    "POWER_GAUNTLET",
    "SPEED_GLOVE",
    "AERIAL_GLOVE",
    "PRECISION_GLOVE",
    "GRAVITY_GLOVE",
    "VOID_GLOVE",
)


@dataclass(frozen=True)
class StyleProfile:
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
    glove_family: str = ""
    hand_default: str = "fist"
    costume_profile: str = ""
    silhouette_intent: str = ""
    hero_feature: str = ""


def _reject_human(payload: dict, label: str) -> None:
    if payload.get("HUMAN_AUTHORED_ART_PASS") or payload.get("HUMAN_AUTHORED_ANIMATION_PASS") or payload.get("human_authored"):
        raise ValueError(f"{label} must remain generated, not human-authored")


def load_style_profiles(path: Path | None = None) -> dict[str, StyleProfile]:
    payload = json.loads((path or PROFILES_PATH).read_text(encoding="utf-8"))
    _reject_human(payload, "v6 style profiles")
    out: dict[str, StyleProfile] = {}
    for fid, row in payload["fighters"].items():
        out[fid] = StyleProfile(
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
            glove_family=str(row["glove_family"]),
            hand_default=str(row["hand_default"]),
            costume_profile=str(row["costume_profile"]),
            silhouette_intent=str(row["silhouette_intent"]),
            hero_feature=str(row.get("hero_feature") or ""),
        )
    missing = set(FIGHTER_IDS) - set(out)
    extra = set(out) - set(FIGHTER_IDS)
    if missing or extra:
        raise ValueError(f"v6 style roster mismatch missing={sorted(missing)} extra={sorted(extra)}")
    return out


STYLE_PROFILES = load_style_profiles()


def style_profile(fid: str) -> StyleProfile:
    return STYLE_PROFILES[fid]


def load_hero_poses(path: Path | None = None) -> dict:
    payload = json.loads((path or POSE_PATH).read_text(encoding="utf-8"))
    _reject_human(payload, "v6 hero poses")
    return payload.get("fighters") or {}


def load_palettes(path: Path | None = None) -> dict:
    payload = json.loads((path or PALETTE_PATH).read_text(encoding="utf-8"))
    _reject_human(payload, "v6 palettes")
    return payload.get("fighters") or {}


def as_v5_body(profile: StyleProfile):
    """Adapter so v5 loft builders can consume v6 proportions."""
    from generated_art_v5.body_profiles import BodyProfile

    return BodyProfile(
        fighter_id=profile.fighter_id,
        display_name=profile.display_name,
        role=profile.role,
        element=profile.element,
        height=profile.height,
        shoulder_width=profile.shoulder_width,
        chest_depth=profile.chest_depth,
        waist_width=profile.waist_width,
        pelvis_width=profile.pelvis_width,
        upper_arm_mass=profile.upper_arm_mass,
        forearm_mass=profile.forearm_mass,
        thigh_mass=profile.thigh_mass,
        calf_mass=profile.calf_mass,
        hand_scale=profile.hand_scale,
        foot_scale=profile.foot_scale,
        neck_scale=profile.neck_scale,
        torso_taper=profile.torso_taper,
        limb_length=profile.limb_length,
        asymmetry=profile.asymmetry,
        head_style=profile.head_style,
        boot_style=profile.boot_style,
        hand_default=profile.hand_default,
        costume_profile=profile.costume_profile,
        silhouette_intent=profile.silhouette_intent,
    )
