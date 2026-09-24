"""v9 graphic boots. Sole, toe direction, heel break, cuff, shin overlap."""
from __future__ import annotations

from mathutils import Vector

from generated_art_v5.torso_loft import bone_pts
from generated_art_v6.body_profiles import StyleProfile
from generated_art_v6.geom import box_mesh, join_named, loft_stack
from generated_art_v9.attachment_map import tag_object


def _boot(name, loc, scale, style):
    loc = Vector(loc)
    fs = scale * 1.22
    x, y = loc.x, loc.y
    sole = box_mesh(f"{name}_sole", (x, y + 0.078 * fs, 0.016 * fs), (0.188 * fs, 0.36 * fs, 0.032 * fs))
    toe = box_mesh(f"{name}_toe", (x, y + 0.198 * fs, 0.040 * fs), (0.148 * fs, 0.142 * fs, 0.048 * fs))
    heel = box_mesh(f"{name}_heel", (x, y - 0.032 * fs, 0.046 * fs), (0.150 * fs, 0.098 * fs, 0.066 * fs))
    cuff = loft_stack(
        f"{name}_cuff",
        [
            ((x, y + 0.020 * fs, 0.086 * fs), 0.136 * fs, 0.136 * fs, 0.04, Vector((0.0, 0.0, 1.0))),
            ((x, y + 0.016 * fs, 0.152 * fs), 0.118 * fs, 0.118 * fs, 0.03, Vector((0.0, 0.0, 1.0))),
        ],
        n=10,
    )
    shin_h = 0.38 * fs if style in {"armored_planted", "heat_aggressive", "geometric_planted"} else 0.26 * fs
    shin = loft_stack(
        f"{name}_shin",
        [
            ((x, y + 0.014 * fs, 0.136 * fs), 0.122 * fs, 0.122 * fs, 0.04, Vector((0.0, 0.0, 1.0))),
            ((x, y + 0.010 * fs, 0.136 * fs + shin_h), 0.096 * fs, 0.094 * fs, 0.02, Vector((0.0, 0.0, 1.0))),
        ],
        n=10,
    )
    extras = []
    if style == "armored_planted":
        extras.append(box_mesh(f"{name}_plate", (x, y + 0.042 * fs, 0.210 * fs), (0.208 * fs, 0.186 * fs, 0.142 * fs)))
        extras.append(box_mesh(f"{name}_block", (x, y + 0.024 * fs, 0.108 * fs), (0.196 * fs, 0.152 * fs, 0.064 * fs)))
    elif style == "speed_blade":
        extras.append(box_mesh(f"{name}_blade", (x, y + 0.242 * fs, 0.024 * fs), (0.058 * fs, 0.196 * fs, 0.016 * fs)))
        extras.append(box_mesh(f"{name}_slash", (x, y + 0.142 * fs, 0.062 * fs), (0.042 * fs, 0.198 * fs, 0.020 * fs)))
    elif style == "light_aerial":
        extras.append(box_mesh(f"{name}_fin", (x, y + 0.022 * fs, 0.132 * fs), (0.042 * fs, 0.142 * fs, 0.112 * fs)))
        extras.append(box_mesh(f"{name}_lift", (x, y + 0.116 * fs, 0.032 * fs), (0.050 * fs, 0.102 * fs, 0.018 * fs)))
    elif style == "geometric_planted":
        extras.append(box_mesh(f"{name}_facet", (x, y + 0.074 * fs, 0.100 * fs), (0.168 * fs, 0.122 * fs, 0.070 * fs)))
        extras.append(box_mesh(f"{name}_edge", (x, y + 0.152 * fs, 0.056 * fs), (0.112 * fs, 0.090 * fs, 0.028 * fs)))
    elif style == "cosmic_layered":
        extras.append(box_mesh(f"{name}_layer", (x, y + 0.048 * fs, 0.114 * fs), (0.176 * fs, 0.188 * fs, 0.046 * fs)))
        extras.append(box_mesh(f"{name}_ring", (x, y + 0.018 * fs, 0.164 * fs), (0.146 * fs, 0.146 * fs, 0.022 * fs)))
    elif style == "narrow_offset":
        off = 0.026 if "R" in name else -0.024
        extras.append(box_mesh(f"{name}_offset", (x + off, y + 0.132 * fs, 0.046 * fs), (0.074 * fs, 0.206 * fs, 0.032 * fs)))
        extras.append(box_mesh(f"{name}_split", (x + off * 0.5, y + 0.052 * fs, 0.086 * fs), (0.050 * fs, 0.112 * fs, 0.062 * fs)))
    else:
        extras.append(box_mesh(f"{name}_vent", (x, y + 0.058 * fs, 0.178 * fs), (0.092 * fs, 0.072 * fs, 0.098 * fs)))
        extras.append(box_mesh(f"{name}_wedge", (x + 0.038 * fs, y + 0.026 * fs, 0.136 * fs), (0.052 * fs, 0.102 * fs, 0.076 * fs)))
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
