"""Stylized low-poly hands: palm, thumb wedge, grouped fingers, knuckle break."""
from __future__ import annotations

import bmesh
from mathutils import Vector

from generated_art_v5.body_profiles import BodyProfile
from generated_art_v5.torso_loft import bone_pts, loft_rings, make_ring, mesh_from_bm


def _hand_mesh(name, wrist, tip, side_sign, scale, style):
    wrist = Vector(wrist)
    tip = Vector(tip)
    axis = tip - wrist
    if axis.length < 1e-4:
        axis = Vector((side_sign, 0.35, 0.0))
    hs = scale * 1.45
    bm = bmesh.new()
    # Loft along the hand bone so a front camera sees a fist lump, not a +Y paddle.
    p0 = wrist
    p1 = wrist + axis.normalized() * (0.045 * hs)
    p2 = wrist + axis.normalized() * (0.080 * hs)
    p3 = wrist + axis.normalized() * (0.115 * hs)
    if style == "fist":
        rings = [
            make_ring(bm, p0, 0.072 * hs, 0.064 * hs, n=10, front_bias=0.06, direction=axis),
            make_ring(bm, p1, 0.098 * hs, 0.086 * hs, n=10, front_bias=0.14, direction=axis),
            make_ring(bm, p2, 0.094 * hs, 0.090 * hs, n=10, front_bias=0.18, direction=axis),
            make_ring(bm, p3, 0.078 * hs, 0.074 * hs, n=10, front_bias=0.10, direction=axis),
        ]
    elif style == "open":
        rings = [
            make_ring(bm, p0, 0.064 * hs, 0.056 * hs, n=10, front_bias=0.04, direction=axis),
            make_ring(bm, p1, 0.086 * hs, 0.048 * hs, n=10, front_bias=0.08, direction=axis),
            make_ring(bm, p2, 0.080 * hs, 0.036 * hs, n=10, front_bias=0.06, direction=axis),
            make_ring(bm, wrist + axis.normalized() * (0.145 * hs), 0.070 * hs, 0.024 * hs, n=10, front_bias=0.04, direction=axis),
        ]
    else:
        rings = [
            make_ring(bm, p0, 0.068 * hs, 0.060 * hs, n=10, front_bias=0.05, direction=axis),
            make_ring(bm, p1, 0.090 * hs, 0.070 * hs, n=10, front_bias=0.10, direction=axis),
            make_ring(bm, p2, 0.086 * hs, 0.062 * hs, n=10, front_bias=0.12, direction=axis),
            make_ring(bm, p3, 0.070 * hs, 0.048 * hs, n=10, front_bias=0.08, direction=axis),
        ]
    loft_rings(bm, rings)
    thumb_dir = Vector((side_sign, 0.45, 0.15))
    thumb0 = make_ring(bm, p1 + Vector((0.042 * side_sign * hs, 0.008, 0.010)), 0.034 * hs, 0.028 * hs, n=8, front_bias=0.06, direction=thumb_dir)
    thumb1 = make_ring(bm, p1 + Vector((0.068 * side_sign * hs, 0.022, 0.014)), 0.026 * hs, 0.022 * hs, n=8, front_bias=0.04, direction=thumb_dir)
    loft_rings(bm, [thumb0, thumb1])
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.008)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    obj = mesh_from_bm(bm, name)
    bm.free()
    obj["aa_hand_style"] = style
    obj["aa_hand_parts"] = 5
    return obj


def build_hands(profile: BodyProfile, arm_obj, style: str | None = None):
    style = style or profile.hand_default
    pieces = []
    for side, sgn in (("L", 1.0), ("R", -1.0)):
        hd_h, hd_t = bone_pts(arm_obj, f"Hand_{side}")
        pieces.append(_hand_mesh(f"hand_{side}", hd_h, hd_t, sgn, profile.hand_scale, style))
    return pieces
