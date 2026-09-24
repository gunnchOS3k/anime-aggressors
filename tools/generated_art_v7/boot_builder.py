"""v7 integrated boots. Toe, sole, heel, cuff, shin, and plant must stay in frame."""
from __future__ import annotations

from mathutils import Vector

from generated_art_v5.torso_loft import bone_pts
from generated_art_v6.body_profiles import StyleProfile
from generated_art_v6.geom import box_mesh, join_named, loft_stack


def _boot(name, loc, scale, style):
    loc = Vector(loc)
    fs = scale
    x, y = loc.x, loc.y
    sole = box_mesh(f"{name}_sole", (x, y + 0.058 * fs, 0.010 * fs), (0.150 * fs, 0.28 * fs, 0.020 * fs))
    toe = box_mesh(f"{name}_toe", (x, y + 0.148 * fs, 0.030 * fs), (0.122 * fs, 0.110 * fs, 0.036 * fs))
    heel = box_mesh(f"{name}_heel", (x, y - 0.018 * fs, 0.032 * fs), (0.122 * fs, 0.074 * fs, 0.046 * fs))
    cuff = loft_stack(
        f"{name}_cuff",
        [
            ((x, y + 0.018 * fs, 0.066 * fs), 0.112 * fs, 0.112 * fs, 0.04, Vector((0.0, 0.0, 1.0))),
            ((x, y + 0.014 * fs, 0.118 * fs), 0.100 * fs, 0.100 * fs, 0.03, Vector((0.0, 0.0, 1.0))),
        ],
        n=10,
    )
    shin_h = 0.26 * fs if style in {"armored_planted", "heat_aggressive"} else 0.18 * fs
    shin = loft_stack(
        f"{name}_shin",
        [
            ((x, y + 0.012 * fs, 0.108 * fs), 0.100 * fs, 0.100 * fs, 0.04, Vector((0.0, 0.0, 1.0))),
            ((x, y + 0.008 * fs, 0.108 * fs + shin_h), 0.082 * fs, 0.080 * fs, 0.02, Vector((0.0, 0.0, 1.0))),
        ],
        n=10,
    )
    extras = []
    if style == "armored_planted":
        extras.append(box_mesh(f"{name}_plate", (x, y + 0.036 * fs, 0.168 * fs), (0.168 * fs, 0.150 * fs, 0.110 * fs)))
        extras.append(box_mesh(f"{name}_block", (x, y + 0.020 * fs, 0.086 * fs), (0.160 * fs, 0.120 * fs, 0.050 * fs)))
    elif style == "speed_blade":
        extras.append(box_mesh(f"{name}_blade", (x, y + 0.186 * fs, 0.020 * fs), (0.048 * fs, 0.150 * fs, 0.014 * fs)))
        extras.append(box_mesh(f"{name}_slash", (x, y + 0.110 * fs, 0.048 * fs), (0.036 * fs, 0.160 * fs, 0.016 * fs)))
    elif style == "light_aerial":
        extras.append(box_mesh(f"{name}_fin", (x, y + 0.018 * fs, 0.104 * fs), (0.034 * fs, 0.110 * fs, 0.086 * fs)))
        extras.append(box_mesh(f"{name}_lift", (x, y + 0.090 * fs, 0.026 * fs), (0.040 * fs, 0.080 * fs, 0.014 * fs)))
    elif style == "geometric_planted":
        extras.append(box_mesh(f"{name}_facet", (x, y + 0.058 * fs, 0.078 * fs), (0.136 * fs, 0.096 * fs, 0.054 * fs)))
        extras.append(box_mesh(f"{name}_edge", (x, y + 0.120 * fs, 0.044 * fs), (0.090 * fs, 0.070 * fs, 0.022 * fs)))
    elif style == "cosmic_layered":
        extras.append(box_mesh(f"{name}_layer", (x, y + 0.038 * fs, 0.090 * fs), (0.146 * fs, 0.154 * fs, 0.036 * fs)))
        extras.append(box_mesh(f"{name}_ring", (x, y + 0.016 * fs, 0.130 * fs), (0.120 * fs, 0.120 * fs, 0.018 * fs)))
    elif style == "narrow_offset":
        off = 0.018 if "R" in name else -0.016
        extras.append(box_mesh(f"{name}_offset", (x + off, y + 0.104 * fs, 0.038 * fs), (0.062 * fs, 0.168 * fs, 0.026 * fs)))
        extras.append(box_mesh(f"{name}_split", (x + off * 0.5, y + 0.040 * fs, 0.070 * fs), (0.040 * fs, 0.090 * fs, 0.050 * fs)))
    else:
        extras.append(box_mesh(f"{name}_vent", (x, y + 0.048 * fs, 0.142 * fs), (0.074 * fs, 0.056 * fs, 0.078 * fs)))
        extras.append(box_mesh(f"{name}_wedge", (x + 0.030 * fs, y + 0.020 * fs, 0.110 * fs), (0.040 * fs, 0.080 * fs, 0.060 * fs)))
    obj = join_named([sole, toe, heel, cuff, shin, *extras], name)
    obj["aa_boot_style"] = style
    obj["aa_boot_parts"] = 5 + len(extras)
    obj["aa_sole"] = 1
    obj["aa_toe"] = 1
    obj["aa_heel"] = 1
    obj["aa_cuff"] = 1
    obj["aa_shin"] = 1
    return obj


def build_boots(profile: StyleProfile, arm_obj):
    pieces = []
    for side in ("L", "R"):
        ft_h, _ft_t = bone_pts(arm_obj, f"Foot_{side}")
        loc = Vector((ft_h.x, ft_h.y, max(0.02, ft_h.z)))
        pieces.append(_boot(f"boot_{side}", loc, profile.foot_scale, profile.boot_style))
    return pieces
