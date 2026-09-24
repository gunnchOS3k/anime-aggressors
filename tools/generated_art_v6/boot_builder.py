"""Integrated boots: sole on ground, toe, heel, ankle cuff, shin overlap."""
from __future__ import annotations

from mathutils import Vector

from generated_art_v5.torso_loft import bone_pts
from generated_art_v6.body_profiles import StyleProfile
from generated_art_v6.geom import box_mesh, join_named, loft_stack


def _boot(name, loc, scale, style):
    loc = Vector(loc)
    fs = scale
    x, y = loc.x, loc.y
    # Sole sits on the ground plane. snap_to_ground may still nudge the group.
    sole = box_mesh(f"{name}_sole", (x, y + 0.055 * fs, 0.012 * fs), (0.16 * fs, 0.30 * fs, 0.024 * fs))
    toe = box_mesh(f"{name}_toe", (x, y + 0.14 * fs, 0.032 * fs), (0.13 * fs, 0.12 * fs, 0.040 * fs))
    heel = box_mesh(f"{name}_heel", (x, y - 0.02 * fs, 0.034 * fs), (0.13 * fs, 0.08 * fs, 0.050 * fs))
    cuff = loft_stack(
        f"{name}_cuff",
        [
            ((x, y + 0.02 * fs, 0.070 * fs), 0.12 * fs, 0.12 * fs, 0.04, Vector((0.0, 0.0, 1.0))),
            ((x, y + 0.015 * fs, 0.12 * fs), 0.11 * fs, 0.11 * fs, 0.03, Vector((0.0, 0.0, 1.0))),
        ],
        n=10,
    )
    shin_h = 0.22 * fs if style in {"armored_planted", "heat_aggressive"} else 0.16 * fs
    shin = loft_stack(
        f"{name}_shin",
        [
            ((x, y + 0.012 * fs, 0.11 * fs), 0.11 * fs, 0.11 * fs, 0.04, Vector((0.0, 0.0, 1.0))),
            ((x, y + 0.008 * fs, 0.11 * fs + shin_h), 0.090 * fs, 0.088 * fs, 0.02, Vector((0.0, 0.0, 1.0))),
        ],
        n=10,
    )
    extras = []
    if style == "armored_planted":
        extras.append(box_mesh(f"{name}_plate", (x, y + 0.04 * fs, 0.16 * fs), (0.16 * fs, 0.14 * fs, 0.10 * fs)))
    elif style == "speed_blade":
        extras.append(box_mesh(f"{name}_blade", (x, y + 0.18 * fs, 0.024 * fs), (0.06 * fs, 0.14 * fs, 0.018 * fs)))
    elif style == "light_aerial":
        extras.append(box_mesh(f"{name}_fin", (x, y + 0.02 * fs, 0.10 * fs), (0.04 * fs, 0.10 * fs, 0.08 * fs)))
    elif style == "geometric_planted":
        extras.append(box_mesh(f"{name}_facet", (x, y + 0.06 * fs, 0.08 * fs), (0.14 * fs, 0.10 * fs, 0.06 * fs)))
    elif style == "cosmic_layered":
        extras.append(box_mesh(f"{name}_layer", (x, y + 0.04 * fs, 0.09 * fs), (0.15 * fs, 0.16 * fs, 0.04 * fs)))
    elif style == "narrow_offset":
        off = 0.016 if "R" in name else -0.014
        extras.append(box_mesh(f"{name}_offset", (x + off, y + 0.10 * fs, 0.04 * fs), (0.07 * fs, 0.16 * fs, 0.03 * fs)))
    else:  # heat_aggressive
        extras.append(box_mesh(f"{name}_vent", (x, y + 0.05 * fs, 0.14 * fs), (0.08 * fs, 0.06 * fs, 0.08 * fs)))
    obj = join_named([sole, toe, heel, cuff, shin, *extras], name)
    obj["aa_boot_style"] = style
    obj["aa_boot_parts"] = 5 + len(extras)
    obj["aa_sole"] = 1
    obj["aa_toe"] = 1
    obj["aa_heel"] = 1
    obj["aa_cuff"] = 1
    return obj


def build_boots(profile: StyleProfile, arm_obj):
    pieces = []
    for side in ("L", "R"):
        ft_h, _ft_t = bone_pts(arm_obj, f"Foot_{side}")
        loc = Vector((ft_h.x, ft_h.y, max(0.02, ft_h.z)))
        pieces.append(_boot(f"boot_{side}", loc, profile.foot_scale, profile.boot_style))
    return pieces
