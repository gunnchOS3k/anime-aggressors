"""v7 graphic gloves. Thumb, finger group, cuff, and knuckle must read at gameplay scale."""
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
        axis = Vector((side_sign, 0.42, 0.0))
    axis = axis.normalized()
    hs = scale * 1.38
    palm_c = wrist + axis * (0.048 * hs)
    knuckle_c = wrist + axis * (0.088 * hs)
    finger_c = wrist + axis * (0.138 * hs)
    thumb_c = palm_c + Vector((0.070 * side_sign * hs, 0.022 * hs, 0.016 * hs))
    cuff_c = wrist - axis * (0.018 * hs)
    forearm = wrist - axis * (0.055 * hs)

    open_w = 0.122 * hs if style in {"open", "cast"} else 0.096 * hs
    palm = box_mesh(f"{name}_palm", palm_c, (open_w, 0.078 * hs if style != "open" else 0.094 * hs, 0.062 * hs))
    knuckle = box_mesh(
        f"{name}_knuckle",
        knuckle_c + Vector((0.0, 0.014 * hs, 0.018 * hs)),
        (open_w * 0.92, 0.030 * hs, 0.026 * hs),
    )
    if style == "open":
        fingers = box_mesh(f"{name}_fingers", finger_c + Vector((0.0, 0.036 * hs, -0.008 * hs)), (open_w, 0.118 * hs, 0.024 * hs))
    elif style == "guard":
        fingers = box_mesh(f"{name}_fingers", knuckle_c + Vector((0.0, 0.018 * hs, 0.032 * hs)), (open_w * 0.94, 0.050 * hs, 0.066 * hs))
    elif style == "cast":
        fingers = box_mesh(f"{name}_fingers", finger_c + Vector((0.0, 0.020 * hs, 0.012 * hs)), (open_w * 0.86, 0.090 * hs, 0.030 * hs))
    else:
        fingers = box_mesh(f"{name}_fingers", finger_c, (0.090 * hs, 0.062 * hs, 0.056 * hs))
    thumb = wedge_mesh(
        f"{name}_thumb",
        thumb_c,
        Vector((side_sign, 0.62, 0.22)),
        0.078 * hs,
        0.042 * hs,
        0.034 * hs,
        taper=0.40,
    )
    cuff = loft_stack(
        f"{name}_cuff",
        [
            (cuff_c, 0.082 * hs, 0.072 * hs, 0.04, axis),
            (wrist + axis * (0.016 * hs), 0.070 * hs, 0.062 * hs, 0.04, axis),
        ],
        n=10,
    )
    sleeve = loft_stack(
        f"{name}_forearm",
        [
            (forearm, 0.074 * hs, 0.066 * hs, 0.03, axis),
            (cuff_c, 0.080 * hs, 0.070 * hs, 0.03, axis),
        ],
        n=8,
    )
    extras = [sleeve]
    if family == "POWER_GAUNTLET":
        extras.append(box_mesh(f"{name}_plate", palm_c + Vector((0.0, 0.026 * hs, 0.026 * hs)), (0.108 * hs, 0.040 * hs, 0.032 * hs)))
        extras.append(box_mesh(f"{name}_knurl", knuckle_c + Vector((0.0, 0.020 * hs, 0.028 * hs)), (0.086 * hs, 0.018 * hs, 0.016 * hs)))
    elif family == "SPEED_GLOVE":
        extras.append(wedge_mesh(f"{name}_fin", knuckle_c + Vector((0.0, 0.018 * hs, 0.028 * hs)), axis, 0.055 * hs, 0.032 * hs, 0.016 * hs, 0.28))
    elif family == "AERIAL_GLOVE":
        extras.append(box_mesh(f"{name}_panel", palm_c + Vector((0.018 * side_sign * hs, 0.018 * hs, 0.018 * hs)), (0.036 * hs, 0.072 * hs, 0.016 * hs)))
    elif family == "PRECISION_GLOVE":
        extras.append(box_mesh(f"{name}_facet", knuckle_c + Vector((0.0, 0.016 * hs, 0.022 * hs)), (0.066 * hs, 0.024 * hs, 0.018 * hs)))
        extras.append(box_mesh(f"{name}_edge", palm_c + Vector((0.028 * side_sign * hs, 0.008 * hs, 0.010 * hs)), (0.018 * hs, 0.050 * hs, 0.016 * hs)))
    elif family == "GRAVITY_GLOVE":
        extras.append(
            loft_stack(
                f"{name}_ring",
                [
                    (palm_c + Vector((0.0, 0.036 * hs, 0.018 * hs)), 0.092 * hs, 0.074 * hs, 0.016, axis),
                    (palm_c + Vector((0.0, 0.046 * hs, 0.026 * hs)), 0.082 * hs, 0.064 * hs, 0.016, axis),
                ],
                n=12,
            )
        )
    elif family == "VOID_GLOVE":
        extras.append(box_mesh(f"{name}_void", palm_c + Vector((0.016 * side_sign * hs, 0.014 * hs, 0.018 * hs)), (0.044 * hs, 0.054 * hs, 0.026 * hs)))
    obj = join_named([palm, knuckle, fingers, thumb, cuff, *extras], name)
    obj["aa_hand_style"] = style
    obj["aa_glove_family"] = family
    obj["aa_hand_parts"] = 6 + len(extras)
    obj["aa_thumb"] = 1
    obj["aa_knuckle"] = 1
    obj["aa_cuff"] = 1
    obj["aa_forearm_read"] = 1
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


def build_cast_gloves(profile: StyleProfile, arm_obj):
    return build_gloves(profile, arm_obj, style="cast")
