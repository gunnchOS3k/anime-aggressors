"""Cohesive-body v2 construction recipes. Original designs only."""
from __future__ import annotations

from dataclasses import dataclass, field


ACCESSORY_CLASSES = (
    "BODY",
    "CLOTHING",
    "ARMOR",
    "PROP",
    "SECONDARY_MOTION",
    "ELEMENTAL_ORBIT_VFX",
)

MAX_ATTACH_M = 0.14
MAX_FOOT_GROUND_M = 0.035
MAX_HEAD_NECK_M = 0.12
MAX_HAND_WRIST_M = 0.10


@dataclass(frozen=True)
class AccessorySpec:
    name: str
    classification: str
    parent_bone: str
    intentional_float: bool = False


@dataclass(frozen=True)
class BodyV2Recipe:
    """Per-fighter silhouette and costume language for the remesh generator."""

    head_style: str
    shoulder: float
    chest: float
    waist: float
    pelvis: float
    neck: float
    thigh: float
    shin: float
    arm: float
    forearm: float
    boot_height: float
    gauntlet_scale: float
    accessories: tuple[AccessorySpec, ...] = field(default_factory=tuple)


RECIPES: dict[str, BodyV2Recipe] = {
    "ember-vale": BodyV2Recipe(
        head_style="ember_cap",
        shoulder=1.08,
        chest=1.00,
        waist=0.90,
        pelvis=0.96,
        neck=0.96,
        thigh=0.98,
        shin=0.94,
        arm=1.02,
        forearm=1.10,
        boot_height=1.06,
        gauntlet_scale=1.28,
        accessories=(
            AccessorySpec("gauntlet_r", "ARMOR", "Hand_R"),
            AccessorySpec("gauntlet_l", "ARMOR", "Hand_L"),
            AccessorySpec("chest_vent", "ARMOR", "Chest"),
            AccessorySpec("flame_tongue_r", "ELEMENTAL_ORBIT_VFX", "Hand_R", True),
            AccessorySpec("flame_tongue_l", "ELEMENTAL_ORBIT_VFX", "Hand_L", True),
        ),
    ),
    "rook-ironside": BodyV2Recipe(
        head_style="plate_helm",
        shoulder=1.28,
        chest=1.32,
        waist=1.18,
        pelvis=1.22,
        neck=1.20,
        thigh=1.18,
        shin=1.14,
        arm=1.20,
        forearm=1.28,
        boot_height=1.32,
        gauntlet_scale=1.20,
        accessories=(
            AccessorySpec("chest_plate", "ARMOR", "Chest"),
            AccessorySpec("shoulder_pad_l", "ARMOR", "Shoulder_L"),
            AccessorySpec("shoulder_pad_r", "ARMOR", "Shoulder_R"),
            AccessorySpec("back_plate", "ARMOR", "Chest"),
        ),
    ),
    "juno-spark": BodyV2Recipe(
        head_style="arc_crown",
        shoulder=0.92,
        chest=0.86,
        waist=0.78,
        pelvis=0.86,
        neck=0.90,
        thigh=0.88,
        shin=0.92,
        arm=0.90,
        forearm=0.94,
        boot_height=0.92,
        gauntlet_scale=0.92,
        accessories=(
            AccessorySpec("volt_panel_a", "CLOTHING", "Chest"),
            AccessorySpec("volt_panel_b", "CLOTHING", "Chest"),
            AccessorySpec("volt_tag", "CLOTHING", "Chest"),
        ),
    ),
    "kaia-windrow": BodyV2Recipe(
        head_style="ribbon_veil",
        shoulder=0.90,
        chest=0.84,
        waist=0.80,
        pelvis=0.86,
        neck=0.88,
        thigh=0.86,
        shin=0.84,
        arm=0.88,
        forearm=0.86,
        boot_height=0.90,
        gauntlet_scale=0.90,
        accessories=(
            AccessorySpec("scarf", "SECONDARY_MOTION", "Neck"),
            AccessorySpec("ribbon", "SECONDARY_MOTION", "Head"),
            AccessorySpec("airfoil", "CLOTHING", "Chest"),
        ),
    ),
    "nix-calder": BodyV2Recipe(
        head_style="crystal_facet",
        shoulder=1.00,
        chest=0.98,
        waist=0.94,
        pelvis=0.98,
        neck=0.96,
        thigh=0.96,
        shin=0.98,
        arm=0.98,
        forearm=1.02,
        boot_height=1.08,
        gauntlet_scale=1.10,
        accessories=(
            AccessorySpec("crystal_core", "ARMOR", "Chest"),
            AccessorySpec("crystal_shoulder", "ARMOR", "Shoulder_L"),
            AccessorySpec("glove_plate_r", "ARMOR", "Hand_R"),
            AccessorySpec("glove_plate_l", "ARMOR", "Hand_L"),
        ),
    ),
    "orion-vell": BodyV2Recipe(
        head_style="orbit_halo",
        shoulder=1.06,
        chest=1.08,
        waist=0.96,
        pelvis=1.00,
        neck=1.00,
        thigh=1.00,
        shin=0.98,
        arm=1.04,
        forearm=1.00,
        boot_height=1.04,
        gauntlet_scale=1.00,
        accessories=(
            AccessorySpec("vest_layer", "CLOTHING", "Chest"),
            AccessorySpec("orbit_ring", "ELEMENTAL_ORBIT_VFX", "Chest", True),
        ),
    ),
    "vesper-nyx": BodyV2Recipe(
        head_style="smoke_cowl",
        shoulder=0.94,
        chest=0.90,
        waist=0.84,
        pelvis=0.90,
        neck=0.98,
        thigh=0.90,
        shin=0.88,
        arm=0.92,
        forearm=0.90,
        boot_height=1.00,
        gauntlet_scale=1.00,
        accessories=(
            AccessorySpec("coat_panel_l", "SECONDARY_MOTION", "Hips"),
            AccessorySpec("coat_panel_r", "SECONDARY_MOTION", "Hips"),
        ),
    ),
}


def recipe(fid: str) -> BodyV2Recipe:
    return RECIPES[fid]


def classify_float(spec: AccessorySpec, distance_m: float) -> bool:
    """True when an accessory is an unintentional floater."""
    if spec.intentional_float and spec.classification == "ELEMENTAL_ORBIT_VFX":
        return False
    return distance_m > MAX_ATTACH_M
