"""v8 boots. Toe, sole, heel, cuff, shin overlap, and ground contact must read."""
from __future__ import annotations

from mathutils import Vector

from generated_art_v5.torso_loft import bone_pts
from generated_art_v6.body_profiles import StyleProfile
from generated_art_v6.geom import box_mesh, join_named, loft_stack
from generated_art_v8.attachment_map import tag_object


def _boot(name, loc, scale, style):
    loc = Vector(loc)
    fs = scale * 1.08
    x, y = loc.x, loc.y
    sole = box_mesh(f"{name}_sole", (x, y + 0.062 * fs, 0.014 * fs), (0.162 * fs, 0.30 * fs, 0.028 * fs))
    toe = box_mesh(f"{name}_toe", (x, y + 0.158 * fs, 0.034 * fs), (0.130 * fs, 0.118 * fs, 0.040 * fs))
    heel = box_mesh(f"{name}_heel", (x, y - 0.022 * fs, 0.038 * fs), (0.130 * fs, 0.082 * fs, 0.054 * fs))
    cuff = loft_stack(
        f"{name}_cuff",
        [
            ((x, y + 0.018 * fs, 0.072 * fs), 0.118 * fs, 0.118 * fs, 0.04, Vector((0.0, 0.0, 1.0))),
            ((x, y + 0.014 * fs, 0.128 * fs), 0.104 * fs, 0.104 * fs, 0.03, Vector((0.0, 0.0, 1.0))),
        ],
        n=10,
    )
    shin_h = 0.30 * fs if style in {"armored_planted", "heat_aggressive"} else 0.22 * fs
    shin = loft_stack(
        f"{name}_shin",
        [
            ((x, y + 0.012 * fs, 0.116 * fs), 0.106 * fs, 0.106 * fs, 0.04, Vector((0.0, 0.0, 1.0))),
            ((x, y + 0.008 * fs, 0.116 * fs + shin_h), 0.086 * fs, 0.084 * fs, 0.02, Vector((0.0, 0.0, 1.0))),
        ],
        n=10,
    )
    extras = []
    if style == "armored_planted":
        extras.append(box_mesh(f"{name}_plate", (x, y + 0.036 * fs, 0.176 * fs), (0.176 * fs, 0.158 * fs, 0.118 * fs)))
        extras.append(box_mesh(f"{name}_block", (x, y + 0.020 * fs, 0.090 * fs), (0.168 * fs, 0.128 * fs, 0.054 * fs)))
    elif style == "speed_blade":
        extras.append(box_mesh(f"{name}_blade", (x, y + 0.198 * fs, 0.022 * fs), (0.052 * fs, 0.162 * fs, 0.016 * fs)))
        extras.append(box_mesh(f"{name}_slash", (x, y + 0.118 * fs, 0.052 * fs), (0.038 * fs, 0.168 * fs, 0.018 * fs)))
    elif style == "light_aerial":
        extras.append(box_mesh(f"{name}_fin", (x, y + 0.018 * fs, 0.112 * fs), (0.038 * fs, 0.118 * fs, 0.094 * fs)))
        extras.append(box_mesh(f"{name}_lift", (x, y + 0.096 * fs, 0.028 * fs), (0.044 * fs, 0.086 * fs, 0.016 * fs)))
    elif style == "geometric_planted":
        extras.append(box_mesh(f"{name}_facet", (x, y + 0.062 * fs, 0.084 * fs), (0.144 * fs, 0.102 * fs, 0.058 * fs)))
        extras.append(box_mesh(f"{name}_edge", (x, y + 0.126 * fs, 0.048 * fs), (0.096 * fs, 0.076 * fs, 0.024 * fs)))
    elif style == "cosmic_layered":
        extras.append(box_mesh(f"{name}_layer", (x, y + 0.040 * fs, 0.096 * fs), (0.152 * fs, 0.162 * fs, 0.040 * fs)))
        extras.append(box_mesh(f"{name}_ring", (x, y + 0.016 * fs, 0.138 * fs), (0.126 * fs, 0.126 * fs, 0.020 * fs)))
    elif style == "narrow_offset":
        off = 0.020 if "R" in name else -0.018
        extras.append(box_mesh(f"{name}_offset", (x + off, y + 0.110 * fs, 0.040 * fs), (0.066 * fs, 0.176 * fs, 0.028 * fs)))
        extras.append(box_mesh(f"{name}_split", (x + off * 0.5, y + 0.044 * fs, 0.074 * fs), (0.044 * fs, 0.096 * fs, 0.054 * fs)))
    else:
        extras.append(box_mesh(f"{name}_vent", (x, y + 0.050 * fs, 0.150 * fs), (0.078 * fs, 0.060 * fs, 0.082 * fs)))
        extras.append(box_mesh(f"{name}_wedge", (x + 0.032 * fs, y + 0.022 * fs, 0.116 * fs), (0.044 * fs, 0.086 * fs, 0.064 * fs)))
    obj = join_named([sole, toe, heel, cuff, shin, *extras], name)
    obj["aa_boot_style"] = style
    obj["aa_boot_parts"] = 5 + len(extras)
    obj["aa_sole"] = 1
    obj["aa_toe"] = 1
    obj["aa_heel"] = 1
    obj["aa_cuff"] = 1
    obj["aa_shin"] = 1
    tag_object(obj)
    return obj


def build_boots(profile: StyleProfile, arm_obj):
    pieces = []
    for side in ("L", "R"):
        ft_h, _ft_t = bone_pts(arm_obj, f"Foot_{side}")
        loc = Vector((ft_h.x, ft_h.y, max(0.02, ft_h.z)))
        pieces.append(_boot(f"boot_{side}", loc, profile.foot_scale, profile.boot_style))
    return pieces
