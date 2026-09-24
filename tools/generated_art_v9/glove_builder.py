"""v9 silhouette-first gloves. FIST/OPEN/GUARD/CAST must read in black."""
from __future__ import annotations

from mathutils import Vector

from generated_art_v5.torso_loft import bone_pts
from generated_art_v6.body_profiles import StyleProfile
from generated_art_v6.geom import box_mesh, join_named, loft_stack, wedge_mesh
from generated_art_v9.attachment_map import tag_object


def _glove(name, wrist, tip, side_sign, scale, family, style):
    wrist = Vector(wrist)
    tip = Vector(tip)
    axis = tip - wrist
    if axis.length < 1e-4:
        axis = Vector((side_sign, 0.42, 0.0))
    axis = axis.normalized()
    hs = scale * 1.64
    palm_c = wrist + axis * (0.058 * hs)
    knuckle_c = wrist + axis * (0.108 * hs)
    finger_c = wrist + axis * (0.168 * hs)
    thumb_c = palm_c + Vector((0.102 * side_sign * hs, 0.034 * hs, 0.024 * hs))
    cuff_c = wrist - axis * (0.028 * hs)
    forearm = wrist - axis * (0.072 * hs)

    if style == "open":
        open_w = 0.178 * hs
        palm_y, palm_z = 0.118 * hs, 0.072 * hs
        fingers = box_mesh(f"{name}_fingers", finger_c + Vector((0.0, 0.058 * hs, -0.012 * hs)), (open_w, 0.168 * hs, 0.028 * hs))
    elif style == "guard":
        open_w = 0.132 * hs
        palm_y, palm_z = 0.078 * hs, 0.092 * hs
        fingers = box_mesh(f"{name}_fingers", knuckle_c + Vector((0.0, 0.018 * hs, 0.052 * hs)), (open_w * 0.94, 0.062 * hs, 0.102 * hs))
    elif style == "cast":
        open_w = 0.164 * hs
        palm_y, palm_z = 0.096 * hs, 0.070 * hs
        fingers = box_mesh(f"{name}_fingers", finger_c + Vector((0.034 * side_sign * hs, 0.028 * hs, 0.018 * hs)), (open_w * 0.78, 0.122 * hs, 0.034 * hs))
    else:
        open_w = 0.124 * hs
        palm_y, palm_z = 0.092 * hs, 0.078 * hs
        fingers = box_mesh(f"{name}_fingers", finger_c + Vector((0.0, 0.008 * hs, 0.010 * hs)), (0.112 * hs, 0.086 * hs, 0.074 * hs))

    palm = box_mesh(f"{name}_palm", palm_c, (open_w, palm_y, palm_z))
    knuckle = box_mesh(
        f"{name}_knuckle",
        knuckle_c + Vector((0.0, 0.020 * hs, 0.028 * hs)),
        (open_w * 0.96, 0.042 * hs, 0.038 * hs),
    )
    thumb = wedge_mesh(
        f"{name}_thumb",
        thumb_c,
        Vector((side_sign, 0.72, 0.28)),
        0.118 * hs,
        0.058 * hs,
        0.046 * hs,
        taper=0.32,
    )
    cuff = loft_stack(
        f"{name}_cuff",
        [
            (cuff_c, 0.102 * hs, 0.088 * hs, 0.04, axis),
            (wrist + axis * (0.018 * hs), 0.084 * hs, 0.072 * hs, 0.04, axis),
        ],
        n=10,
    )
    sleeve = loft_stack(
        f"{name}_forearm",
        [
            (forearm, 0.090 * hs, 0.080 * hs, 0.03, axis),
            (cuff_c, 0.098 * hs, 0.084 * hs, 0.03, axis),
        ],
        n=8,
    )
    extras = [sleeve]
    if family == "POWER_GAUNTLET":
        extras.append(box_mesh(f"{name}_plate", palm_c + Vector((0.0, 0.034 * hs, 0.034 * hs)), (0.138 * hs, 0.052 * hs, 0.040 * hs)))
        extras.append(box_mesh(f"{name}_knurl", knuckle_c + Vector((0.0, 0.028 * hs, 0.036 * hs)), (0.108 * hs, 0.026 * hs, 0.022 * hs)))
    elif family == "SPEED_GLOVE":
        extras.append(wedge_mesh(f"{name}_fin", knuckle_c + Vector((0.0, 0.026 * hs, 0.036 * hs)), axis, 0.078 * hs, 0.040 * hs, 0.020 * hs, 0.24))
    elif family == "AERIAL_GLOVE":
        extras.append(box_mesh(f"{name}_panel", palm_c + Vector((0.026 * side_sign * hs, 0.024 * hs, 0.024 * hs)), (0.048 * hs, 0.094 * hs, 0.020 * hs)))
    elif family == "PRECISION_GLOVE":
        extras.append(box_mesh(f"{name}_facet", knuckle_c + Vector((0.0, 0.022 * hs, 0.028 * hs)), (0.082 * hs, 0.030 * hs, 0.024 * hs)))
        extras.append(box_mesh(f"{name}_edge", palm_c + Vector((0.036 * side_sign * hs, 0.010 * hs, 0.014 * hs)), (0.024 * hs, 0.064 * hs, 0.020 * hs)))
    elif family == "GRAVITY_GLOVE":
        extras.append(
            loft_stack(
                f"{name}_ring",
                [
                    (palm_c + Vector((0.0, 0.046 * hs, 0.024 * hs)), 0.116 * hs, 0.090 * hs, 0.016, axis),
                    (palm_c + Vector((0.0, 0.060 * hs, 0.034 * hs)), 0.100 * hs, 0.078 * hs, 0.016, axis),
                ],
                n=12,
            )
        )
    elif family == "VOID_GLOVE":
        extras.append(box_mesh(f"{name}_void", palm_c + Vector((0.024 * side_sign * hs, 0.020 * hs, 0.024 * hs)), (0.056 * hs, 0.068 * hs, 0.032 * hs)))
    obj = join_named([palm, knuckle, fingers, thumb, cuff, *extras], name)
    obj["aa_hand_style"] = style
    obj["aa_glove_family"] = family
    obj["aa_hand_parts"] = 6 + len(extras)
    obj["aa_thumb"] = 1
    obj["aa_knuckle"] = 1
    obj["aa_cuff"] = 1
    obj["aa_forearm_read"] = 1
    tag_object(obj)
    return obj


def build_gloves(profile: StyleProfile, arm_obj, style: str | None = None, suffix: str = ""):
    style = style or profile.hand_default
    pieces = []
    for side, sgn in (("L", 1.0), ("R", -1.0)):
        hd_h, hd_t = bone_pts(arm_obj, f"Hand_{side}")
        pieces.append(_glove(f"hand_{side}{suffix}", hd_h, hd_t, sgn, profile.hand_scale, profile.glove_family, style))
    return pieces


def build_open_gloves(profile: StyleProfile, arm_obj):
    return build_gloves(profile, arm_obj, style="open", suffix="_open")


def build_guard_gloves(profile: StyleProfile, arm_obj):
    return build_gloves(profile, arm_obj, style="guard", suffix="_guard")


def build_cast_gloves(profile: StyleProfile, arm_obj):
    return build_gloves(profile, arm_obj, style="cast", suffix="_cast")
