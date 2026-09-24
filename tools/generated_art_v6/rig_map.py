"""Bone parenting map for v6 visible parts. Same 22-bone contract."""
from __future__ import annotations

from generated_art_v5.rig_bind import default_bone_map as v5_map


def bone_map(fid: str) -> dict[str, str]:
    mapping = dict(v5_map(fid))
    mapping.update(
        {
            "mask_skull": "Head",
            "forearm_mass_r": "LowerArm_R",
            "forearm_mass_l": "LowerArm_L",
            "thigh_mass_r": "UpperLeg_R",
            "thigh_mass_l": "UpperLeg_L",
            "shin_mass_r": "LowerLeg_R",
            "shin_mass_l": "LowerLeg_L",
            "heat_cuirass": "Chest",
            "frost_cuirass": "Chest",
            "shoulder_wedge_r": "UpperArm_R",
            "sharp_calf_r": "LowerLeg_R",
            "sharp_calf_l": "LowerLeg_L",
        }
    )
    return mapping
