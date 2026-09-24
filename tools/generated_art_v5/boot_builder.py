"""Footwear by profile extrusion. Each fighter changes silhouette."""
from __future__ import annotations

import bmesh
from mathutils import Vector

from generated_art_v5.body_profiles import BodyProfile
from generated_art_v5.torso_loft import bone_pts, loft_rings, make_ring, mesh_from_bm


def _boot(name, loc, scale, style):
    loc = Vector(loc)
    fs = scale
    y = loc.y
    bm = bmesh.new()
    if style == "armored_heavy":
        sole = make_ring(bm, (loc.x, y + 0.06 * fs, 0.010), 0.18 * fs, 0.32 * fs, n=12, front_bias=0.20)
        body = make_ring(bm, (loc.x, y + 0.05 * fs, 0.055 * fs), 0.16 * fs, 0.24 * fs, n=12, front_bias=0.12)
        cuff = make_ring(bm, (loc.x, y + 0.02 * fs, 0.12 * fs), 0.14 * fs, 0.14 * fs, n=12, front_bias=0.04)
        shin = make_ring(bm, (loc.x, y + 0.01 * fs, 0.20 * fs), 0.13 * fs, 0.12 * fs, n=12, front_bias=0.02)
        loft_rings(bm, [sole, body, cuff, shin])
    elif style == "speed_shoe":
        sole = make_ring(bm, (loc.x, y + 0.07 * fs, 0.008), 0.10 * fs, 0.30 * fs, n=12, front_bias=0.35)
        body = make_ring(bm, (loc.x, y + 0.06 * fs, 0.028 * fs), 0.09 * fs, 0.22 * fs, n=12, front_bias=0.22)
        cuff = make_ring(bm, (loc.x, y + 0.02 * fs, 0.058 * fs), 0.074 * fs, 0.10 * fs, n=12, front_bias=0.04)
        loft_rings(bm, [sole, body, cuff])
    elif style == "aerial_boot":
        sole = make_ring(bm, (loc.x, y + 0.06 * fs, 0.008), 0.10 * fs, 0.26 * fs, n=12, front_bias=0.18)
        body = make_ring(bm, (loc.x, y + 0.05 * fs, 0.032 * fs), 0.092 * fs, 0.18 * fs, n=12, front_bias=0.10)
        cuff = make_ring(bm, (loc.x, y + 0.02 * fs, 0.078 * fs), 0.080 * fs, 0.10 * fs, n=12, front_bias=0.04)
        loft_rings(bm, [sole, body, cuff])
    elif style == "frost_geometric":
        sole = make_ring(bm, (loc.x, y + 0.05 * fs, 0.010), 0.14 * fs, 0.26 * fs, n=8, front_bias=0.08)
        body = make_ring(bm, (loc.x, y + 0.04 * fs, 0.048 * fs), 0.13 * fs, 0.18 * fs, n=8, front_bias=0.06)
        cuff = make_ring(bm, (loc.x, y + 0.02 * fs, 0.11 * fs), 0.11 * fs, 0.12 * fs, n=8, front_bias=0.02)
        loft_rings(bm, [sole, body, cuff])
    elif style == "cosmic_layered":
        sole = make_ring(bm, (loc.x, y + 0.05 * fs, 0.010), 0.13 * fs, 0.26 * fs, n=12, front_bias=0.14)
        body = make_ring(bm, (loc.x, y + 0.04 * fs, 0.046 * fs), 0.12 * fs, 0.18 * fs, n=12, front_bias=0.10)
        layer = make_ring(bm, (loc.x, y + 0.04 * fs, 0.070 * fs), 0.14 * fs, 0.20 * fs, n=12, front_bias=0.08)
        cuff = make_ring(bm, (loc.x, y + 0.02 * fs, 0.11 * fs), 0.10 * fs, 0.12 * fs, n=12, front_bias=0.04)
        loft_rings(bm, [sole, body, layer, cuff])
    elif style == "asymmetric_narrow":
        offset = 0.012 if "R" in name else -0.010
        sole = make_ring(bm, (loc.x + offset, y + 0.07 * fs, 0.008), 0.084 * fs, 0.28 * fs, n=12, front_bias=0.28, side_bias=0.16)
        body = make_ring(bm, (loc.x + offset, y + 0.05 * fs, 0.030 * fs), 0.076 * fs, 0.18 * fs, n=12, front_bias=0.12, side_bias=0.12)
        cuff = make_ring(bm, (loc.x, y + 0.02 * fs, 0.068 * fs), 0.068 * fs, 0.090 * fs, n=12, front_bias=0.04)
        loft_rings(bm, [sole, body, cuff])
    else:  # heat_resistant
        sole = make_ring(bm, (loc.x, y + 0.06 * fs, 0.010), 0.13 * fs, 0.28 * fs, n=12, front_bias=0.22)
        body = make_ring(bm, (loc.x, y + 0.05 * fs, 0.046 * fs), 0.12 * fs, 0.20 * fs, n=12, front_bias=0.14)
        cuff = make_ring(bm, (loc.x, y + 0.02 * fs, 0.10 * fs), 0.10 * fs, 0.12 * fs, n=12, front_bias=0.04)
        shin = make_ring(bm, (loc.x, y + 0.01 * fs, 0.16 * fs), 0.086 * fs, 0.090 * fs, n=12, front_bias=0.02)
        loft_rings(bm, [sole, body, cuff, shin])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    obj = mesh_from_bm(bm, name)
    bm.free()
    obj["aa_boot_style"] = style
    obj["aa_boot_parts"] = 4
    return obj


def build_boots(profile: BodyProfile, arm_obj):
    pieces = []
    for side in ("L", "R"):
        ft_h, _ft_t = bone_pts(arm_obj, f"Foot_{side}")
        loc = Vector((ft_h.x, ft_h.y, max(0.02, ft_h.z)))
        pieces.append(_boot(f"boot_{side}", loc, profile.foot_scale, profile.boot_style))
    return pieces
