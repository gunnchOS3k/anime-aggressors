"""Classify every visible non-body object. No fighter costume is WORLD_STATIC."""
from __future__ import annotations

from generated_art_v8.body_profiles import load_attachment_table

CLASSES = ("SKINNED_COSTUME", "BONE_RIGID", "SECONDARY_CHAIN", "VFX_ORBIT", "WORLD_STATIC")

NAME_RULES = (
    (("torso_shell", "coat_layer"), "SKINNED_COSTUME", "Chest", False),
    (("head_shell", "mask_"), "BONE_RIGID", "Head", False),
    (("hand_l", "glove_l"), "BONE_RIGID", "Hand_L", False),
    (("hand_r", "glove_r"), "BONE_RIGID", "Hand_R", False),
    (("boot_l",), "BONE_RIGID", "Foot_L", False),
    (("boot_r",), "BONE_RIGID", "Foot_R", False),
    (("forearm_mass_r", "forearm_plate_r", "gauntlet_r"), "BONE_RIGID", "LowerArm_R", False),
    (("forearm_mass_l", "forearm_plate_l", "gauntlet_l"), "BONE_RIGID", "LowerArm_L", False),
    (("thigh_mass_r", "heat_guard_r", "thigh_shell_r", "hip_panel_r"), "BONE_RIGID", "UpperLeg_R", False),
    (("thigh_mass_l", "heat_guard_l", "thigh_shell_l", "hip_panel_l"), "BONE_RIGID", "UpperLeg_L", False),
    (("shin_mass_r", "shin_facet_r", "shin_shell_r", "sharp_calf_r"), "BONE_RIGID", "LowerLeg_R", False),
    (("shin_mass_l", "shin_facet_l", "shin_shell_l", "sharp_calf_l"), "BONE_RIGID", "LowerLeg_L", False),
    (("shoulder_pad_r", "shoulder_heat_wedge", "frost_pauldron_r", "shoulder_wedge_r"), "BONE_RIGID", "UpperArm_R", False),
    (("shoulder_pad_l", "frost_pauldron_l", "airfoil_l"), "BONE_RIGID", "Shoulder_L", False),
    (("airfoil_r",), "BONE_RIGID", "Shoulder_R", False),
    (("scarf_collar",), "BONE_RIGID", "Neck", False),
    (("scarf_fall",), "SECONDARY_CHAIN", "Neck", False),
    (("coat_tail_l", "coat_tail_r", "coat_panel_l", "coat_panel_r", "coat_cowl"), "SECONDARY_CHAIN", "Hips", False),
    (("orbit_ring",), "VFX_ORBIT", "Chest", True),
    (
        (
            "heat_cuirass",
            "heat_vent",
            "frost_cuirass",
            "frost_plastron",
            "crystal_core",
            "crystal_trim",
            "authority_panel",
            "orbit_trim",
            "void_trim",
            "volt_sash",
            "volt_panel",
            "chest_mass",
            "belt_plate",
            "waist_band",
            "chest_panel",
            "speed_panel",
        ),
        "BONE_RIGID",
        "Chest",
        False,
    ),
)


def classify_name(name: str) -> tuple[str, str, bool] | None:
    lowered = name.lower()
    if lowered.startswith("aa_ref") or lowered.startswith("aa_ground") or "ground" in lowered and lowered.startswith("aa_"):
        return ("WORLD_STATIC", "", False)
    if lowered.startswith("aa_contact") or lowered.startswith("aa_front") or lowered.startswith("socket_"):
        return ("VFX_ORBIT", "Chest", True)
    table = load_attachment_table().get("defaults") or {}
    if name in table:
        cls, bone, floating = table[name]
        return (str(cls), str(bone), bool(floating))
    for keys, cls, bone, floating in NAME_RULES:
        if any(lowered == key or lowered.startswith(key) for key in keys):
            return (cls, bone, floating)
    if lowered.startswith("hand_"):
        return ("BONE_RIGID", "Hand_R" if "_r" in lowered else "Hand_L", False)
    if lowered.startswith("boot_"):
        return ("BONE_RIGID", "Foot_R" if "_r" in lowered else "Foot_L", False)
    return None


def tag_object(obj) -> tuple[str, str, bool]:
    classified = classify_name(obj.name)
    if classified is None:
        raise ValueError(f"unclassified attachment: {obj.name}")
    cls, bone, floating = classified
    if cls == "WORLD_STATIC" and not obj.name.startswith("AA_"):
        raise ValueError(f"fighter costume cannot be WORLD_STATIC: {obj.name}")
    obj["aa_attach_class"] = cls
    obj["aa_attach_bone"] = bone
    obj["aa_intentional_float"] = int(floating)
    return classified


def fallback_bone(name: str) -> str:
    classified = classify_name(name)
    if classified is None:
        raise ValueError(f"unclassified attachment: {name}")
    return classified[1]
