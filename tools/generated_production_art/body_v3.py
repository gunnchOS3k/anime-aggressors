"""Character-craft v3 recipes. Designed extremities stay off the remesh blob."""
from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path

from .body_v2 import ACCESSORY_CLASSES, AccessorySpec, classify_float
from .common import FIGHTER_IDS, ROOT

SHAPE_PROFILES_PATH = ROOT / "game-godot/data/art/generated_v3/fighter_shape_profiles.json"

MAX_ATTACH_M = 0.14
MAX_FOOT_GROUND_M = 0.035
MAX_HAND_WRIST_M = 0.10
MAX_HEAD_NECK_M = 0.12
MIN_HAND_PARTS = 4
MIN_BOOT_PARTS = 4
MIN_HEAD_PARTS = 3
MIN_COSTUME_PARTS = 3


@dataclass(frozen=True)
class ShapeProfile:
    fighter_id: str
    shoulder_width: float
    chest_depth: float
    waist_width: float
    pelvis_width: float
    limb_taper: float
    forearm_mass: float
    calf_shape: float
    hand_scale: float
    hand_strength: float
    foot_boot_scale: float
    neck_thickness: float
    head_scale: float
    asymmetry: float
    head_style: str
    boot_style: str
    hand_default: str
    costume_profile: str
    silhouette_intent: str


@dataclass(frozen=True)
class BodyV3Recipe:
    head_style: str
    boot_style: str
    hand_default: str
    costume_profile: str
    accessories: tuple[AccessorySpec, ...] = field(default_factory=tuple)
    hand_shapes: tuple[str, ...] = ("neutral", "fist", "open")


def load_shape_profiles(path: Path | None = None) -> dict[str, ShapeProfile]:
    payload = json.loads((path or SHAPE_PROFILES_PATH).read_text(encoding="utf-8"))
    if payload.get("HUMAN_AUTHORED_ART_PASS") or payload.get("human_authored"):
        raise ValueError("shape profiles must remain generated, not human-authored")
    out: dict[str, ShapeProfile] = {}
    for fid, row in payload["fighters"].items():
        out[fid] = ShapeProfile(
            fighter_id=fid,
            shoulder_width=float(row["shoulder_width"]),
            chest_depth=float(row["chest_depth"]),
            waist_width=float(row["waist_width"]),
            pelvis_width=float(row["pelvis_width"]),
            limb_taper=float(row["limb_taper"]),
            forearm_mass=float(row["forearm_mass"]),
            calf_shape=float(row["calf_shape"]),
            hand_scale=float(row["hand_scale"]),
            hand_strength=float(row["hand_strength"]),
            foot_boot_scale=float(row["foot_boot_scale"]),
            neck_thickness=float(row["neck_thickness"]),
            head_scale=float(row["head_scale"]),
            asymmetry=float(row["asymmetry"]),
            head_style=str(row["head_style"]),
            boot_style=str(row["boot_style"]),
            hand_default=str(row["hand_default"]),
            costume_profile=str(row["costume_profile"]),
            silhouette_intent=str(row["silhouette_intent"]),
        )
    missing = set(FIGHTER_IDS) - set(out)
    extra = set(out) - set(FIGHTER_IDS)
    if missing or extra:
        raise ValueError(f"shape profile roster mismatch missing={sorted(missing)} extra={sorted(extra)}")
    return out


SHAPE_PROFILES = load_shape_profiles()


RECIPES: dict[str, BodyV3Recipe] = {
    "ember-vale": BodyV3Recipe(
        head_style="ember_crest_heat_mask",
        boot_style="heat_resistant",
        hand_default="fist",
        costume_profile="heat_vent_gauntlets",
        accessories=(
            AccessorySpec("head_shell", "BODY", "Head"),
            AccessorySpec("hand_R", "BODY", "Hand_R"),
            AccessorySpec("hand_L", "BODY", "Hand_L"),
            AccessorySpec("boot_R", "BODY", "Foot_R"),
            AccessorySpec("boot_L", "BODY", "Foot_L"),
            AccessorySpec("gauntlet_r", "ARMOR", "Hand_R"),
            AccessorySpec("gauntlet_l", "ARMOR", "Hand_L"),
            AccessorySpec("chest_vent", "ARMOR", "Chest"),
            AccessorySpec("heat_guard_r", "ARMOR", "UpperLeg_R"),
            AccessorySpec("heat_guard_l", "ARMOR", "UpperLeg_L"),
            AccessorySpec("shoulder_accent", "ARMOR", "Shoulder_R"),
            AccessorySpec("flame_tongue_r", "ELEMENTAL_ORBIT_VFX", "Hand_R", True),
            AccessorySpec("flame_tongue_l", "ELEMENTAL_ORBIT_VFX", "Hand_L", True),
        ),
    ),
    "rook-ironside": BodyV3Recipe(
        head_style="plate_helm_void",
        boot_style="armored_heavy",
        hand_default="fist",
        costume_profile="plated_tank",
        accessories=(
            AccessorySpec("head_shell", "BODY", "Head"),
            AccessorySpec("hand_R", "BODY", "Hand_R"),
            AccessorySpec("hand_L", "BODY", "Hand_L"),
            AccessorySpec("boot_R", "BODY", "Foot_R"),
            AccessorySpec("boot_L", "BODY", "Foot_L"),
            AccessorySpec("chest_plate", "ARMOR", "Chest"),
            AccessorySpec("shoulder_pad_l", "ARMOR", "Shoulder_L"),
            AccessorySpec("shoulder_pad_r", "ARMOR", "Shoulder_R"),
            AccessorySpec("forearm_plate_l", "ARMOR", "LowerArm_L"),
            AccessorySpec("forearm_plate_r", "ARMOR", "LowerArm_R"),
            AccessorySpec("belt_plate", "ARMOR", "Hips"),
            AccessorySpec("back_plate", "ARMOR", "Chest"),
        ),
    ),
    "juno-spark": BodyV3Recipe(
        head_style="arc_crown_cap",
        boot_style="speed_shoe",
        hand_default="open",
        costume_profile="sharp_speed_panels",
        accessories=(
            AccessorySpec("head_shell", "BODY", "Head"),
            AccessorySpec("hand_R", "BODY", "Hand_R"),
            AccessorySpec("hand_L", "BODY", "Hand_L"),
            AccessorySpec("boot_R", "BODY", "Foot_R"),
            AccessorySpec("boot_L", "BODY", "Foot_L"),
            AccessorySpec("volt_panel_a", "CLOTHING", "Chest"),
            AccessorySpec("volt_panel_b", "CLOTHING", "Chest"),
            AccessorySpec("volt_sash", "CLOTHING", "Chest"),
            AccessorySpec("volt_tag", "CLOTHING", "Chest"),
        ),
    ),
    "kaia-windrow": BodyV3Recipe(
        head_style="ribbon_veil",
        boot_style="aerial_boot",
        hand_default="open",
        costume_profile="scarf_airfoil",
        accessories=(
            AccessorySpec("head_shell", "BODY", "Head"),
            AccessorySpec("hand_R", "BODY", "Hand_R"),
            AccessorySpec("hand_L", "BODY", "Hand_L"),
            AccessorySpec("boot_R", "BODY", "Foot_R"),
            AccessorySpec("boot_L", "BODY", "Foot_L"),
            AccessorySpec("scarf", "SECONDARY_MOTION", "Neck"),
            AccessorySpec("ribbon", "SECONDARY_MOTION", "Head"),
            AccessorySpec("airfoil_l", "CLOTHING", "Shoulder_L"),
            AccessorySpec("airfoil_r", "CLOTHING", "Shoulder_R"),
            AccessorySpec("core_panel", "CLOTHING", "Chest"),
        ),
    ),
    "nix-calder": BodyV3Recipe(
        head_style="crystal_facet_mask",
        boot_style="frost_geometric",
        hand_default="guard",
        costume_profile="crystal_control",
        accessories=(
            AccessorySpec("head_shell", "BODY", "Head"),
            AccessorySpec("hand_R", "BODY", "Hand_R"),
            AccessorySpec("hand_L", "BODY", "Hand_L"),
            AccessorySpec("boot_R", "BODY", "Foot_R"),
            AccessorySpec("boot_L", "BODY", "Foot_L"),
            AccessorySpec("crystal_core", "ARMOR", "Chest"),
            AccessorySpec("chest_plate", "ARMOR", "Chest"),
            AccessorySpec("crystal_shoulder", "ARMOR", "Shoulder_L"),
            AccessorySpec("forearm_plate_r", "ARMOR", "LowerArm_R"),
            AccessorySpec("forearm_plate_l", "ARMOR", "LowerArm_L"),
        ),
    ),
    "orion-vell": BodyV3Recipe(
        head_style="authority_orbit_halo",
        boot_style="cosmic_layered",
        hand_default="open",
        costume_profile="layered_orbit_vest",
        accessories=(
            AccessorySpec("head_shell", "BODY", "Head"),
            AccessorySpec("hand_R", "BODY", "Hand_R"),
            AccessorySpec("hand_L", "BODY", "Hand_L"),
            AccessorySpec("boot_R", "BODY", "Foot_R"),
            AccessorySpec("boot_L", "BODY", "Foot_L"),
            AccessorySpec("vest_layer", "CLOTHING", "Chest"),
            AccessorySpec("coat_layer", "CLOTHING", "Chest"),
            AccessorySpec("orbit_trim", "CLOTHING", "Chest"),
            AccessorySpec("orbit_ring", "ELEMENTAL_ORBIT_VFX", "Chest", True),
        ),
    ),
    "vesper-nyx": BodyV3Recipe(
        head_style="smoke_cowl_void",
        boot_style="asymmetric_narrow",
        hand_default="guard",
        costume_profile="split_coat_cowl",
        accessories=(
            AccessorySpec("head_shell", "BODY", "Head"),
            AccessorySpec("hand_R", "BODY", "Hand_R"),
            AccessorySpec("hand_L", "BODY", "Hand_L"),
            AccessorySpec("boot_R", "BODY", "Foot_R"),
            AccessorySpec("boot_L", "BODY", "Foot_L"),
            AccessorySpec("coat_panel_l", "SECONDARY_MOTION", "Hips"),
            AccessorySpec("coat_panel_r", "SECONDARY_MOTION", "Hips"),
            AccessorySpec("coat_tail_l", "SECONDARY_MOTION", "Hips"),
            AccessorySpec("coat_tail_r", "SECONDARY_MOTION", "Hips"),
            AccessorySpec("void_trim", "CLOTHING", "Chest"),
        ),
    ),
}


def recipe(fid: str) -> BodyV3Recipe:
    return RECIPES[fid]


def shape_profile(fid: str) -> ShapeProfile:
    return SHAPE_PROFILES[fid]


def roster_hand_hierarchy() -> dict[str, float]:
    return {fid: shape_profile(fid).hand_strength for fid in FIGHTER_IDS}


__all__ = [
    "ACCESSORY_CLASSES",
    "AccessorySpec",
    "BodyV3Recipe",
    "MAX_ATTACH_M",
    "MAX_FOOT_GROUND_M",
    "MAX_HAND_WRIST_M",
    "MAX_HEAD_NECK_M",
    "MIN_BOOT_PARTS",
    "MIN_COSTUME_PARTS",
    "MIN_HAND_PARTS",
    "MIN_HEAD_PARTS",
    "RECIPES",
    "SHAPE_PROFILES",
    "SHAPE_PROFILES_PATH",
    "ShapeProfile",
    "classify_float",
    "load_shape_profiles",
    "recipe",
    "roster_hand_hierarchy",
    "shape_profile",
]
