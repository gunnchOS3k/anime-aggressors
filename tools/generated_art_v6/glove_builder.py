"""Stylized glove/gauntlet families. Fist must read as fist at gameplay scale."""
from __future__ import annotations

from mathutils import Vector

from generated_art_v5.torso_loft import bone_pts
from generated_art_v6.body_profiles import StyleProfile
from generated_art_v6.geom import box_mesh, join_named, loft_stack, wedge_mesh


def _glove(name, wrist, tip, side_sign, scale, family, style):
    wrist = Vector(wrist)
    tip = Vector(tip)
    axis = tip - wrist
    if axis.length < 1e-4:
        axis = Vector((side_sign, 0.40, 0.0))
    axis = axis.normalized()
    hs = scale * 1.72
    palm_c = wrist + axis * (0.055 * hs)
    knuckle_c = wrist + axis * (0.095 * hs)
    finger_c = wrist + axis * (0.145 * hs)
    thumb_c = palm_c + Vector((0.062 * side_sign * hs, 0.018 * hs, 0.012 * hs))
    cuff_c = wrist - axis * (0.012 * hs)

    palm = box_mesh(
        f"{name}_palm",
        palm_c,
        (0.11 * hs, 0.090 * hs if style != "open" else 0.10 * hs, 0.070 * hs),
    )
    knuckle = box_mesh(f"{name}_knuckle", knuckle_c + Vector((0.0, 0.012 * hs, 0.016 * hs)), (0.10 * hs, 0.034 * hs, 0.028 * hs))
    if style == "open":
        fingers = box_mesh(f"{name}_fingers", finger_c + Vector((0.0, 0.030 * hs, -0.006 * hs)), (0.10 * hs, 0.12 * hs, 0.028 * hs))
    elif style == "guard":
        fingers = box_mesh(f"{name}_fingers", knuckle_c + Vector((0.0, 0.020 * hs, 0.034 * hs)), (0.10 * hs, 0.055 * hs, 0.070 * hs))
    else:
        fingers = box_mesh(f"{name}_fingers", finger_c, (0.096 * hs, 0.070 * hs, 0.062 * hs))
    thumb = wedge_mesh(
        f"{name}_thumb",
        thumb_c,
        Vector((side_sign, 0.55, 0.18)),
        0.072 * hs,
        0.046 * hs,
        0.038 * hs,
        taper=0.42,
    )
    cuff = loft_stack(
        f"{name}_cuff",
        [
            (cuff_c, 0.088 * hs, 0.078 * hs, 0.04, axis),
            (wrist + axis * (0.018 * hs), 0.078 * hs, 0.070 * hs, 0.04, axis),
        ],
        n=10,
    )
    extras = []
    if family == "POWER_GAUNTLET":
        extras.append(box_mesh(f"{name}_plate", palm_c + Vector((0.0, 0.028 * hs, 0.028 * hs)), (0.12 * hs, 0.046 * hs, 0.036 * hs)))
    elif family == "SPEED_GLOVE":
        extras.append(wedge_mesh(f"{name}_fin", knuckle_c + Vector((0.0, 0.02 * hs, 0.03 * hs)), axis, 0.06 * hs, 0.04 * hs, 0.02 * hs, 0.3))
    elif family == "AERIAL_GLOVE":
        extras.append(box_mesh(f"{name}_panel", palm_c + Vector((0.02 * side_sign * hs, 0.02 * hs, 0.02 * hs)), (0.04 * hs, 0.08 * hs, 0.02 * hs)))
    elif family == "PRECISION_GLOVE":
        extras.append(box_mesh(f"{name}_facet", knuckle_c + Vector((0.0, 0.018 * hs, 0.024 * hs)), (0.072 * hs, 0.028 * hs, 0.022 * hs)))
    elif family == "GRAVITY_GLOVE":
        extras.append(loft_stack(f"{name}_ring", [(palm_c + Vector((0.0, 0.04 * hs, 0.02 * hs)), 0.10 * hs, 0.08 * hs, 0.02, axis), (palm_c + Vector((0.0, 0.05 * hs, 0.03 * hs)), 0.09 * hs, 0.07 * hs, 0.02, axis)], n=12))
    elif family == "VOID_GLOVE":
        extras.append(box_mesh(f"{name}_void", palm_c + Vector((0.018 * side_sign * hs, 0.016 * hs, 0.02 * hs)), (0.05 * hs, 0.06 * hs, 0.03 * hs)))
    obj = join_named([palm, knuckle, fingers, thumb, cuff, *extras], name)
    obj["aa_hand_style"] = style
    obj["aa_glove_family"] = family
    obj["aa_hand_parts"] = 5 + len(extras)
    obj["aa_thumb"] = 1
    obj["aa_knuckle"] = 1
    return obj


def build_gloves(profile: StyleProfile, arm_obj, style: str | None = None):
    style = style or profile.hand_default
    pieces = []
    for side, sgn in (("L", 1.0), ("R", -1.0)):
        hd_h, hd_t = bone_pts(arm_obj, f"Hand_{side}")
        pieces.append(_glove(f"hand_{side}", hd_h, hd_t, sgn, profile.hand_scale, profile.glove_family, style))
    return pieces


def build_open_gloves(profile: StyleProfile, arm_obj):
    return build_gloves(profile, arm_obj, style="open")
