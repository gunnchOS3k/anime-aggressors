"""Designed faceless heads. Lofted skull plus fighter structure — not a leftover primitive."""
from __future__ import annotations

import bmesh
from mathutils import Vector

from generated_art_v5.body_profiles import BodyProfile
from generated_art_v5.torso_loft import bone_pts, loft_rings, make_ring, mesh_from_bm


def _skull(bm, center, hs):
    neck = make_ring(bm, center + Vector((0.0, 0.0, -0.10 * hs)), 0.10 * hs, 0.09 * hs, n=12, front_bias=0.04)
    jaw = make_ring(bm, center + Vector((0.0, 0.02 * hs, -0.02 * hs)), 0.16 * hs, 0.14 * hs, n=12, front_bias=0.18)
    cranium = make_ring(bm, center + Vector((0.0, 0.01 * hs, 0.06 * hs)), 0.18 * hs, 0.16 * hs, n=12, front_bias=0.10)
    crown = make_ring(bm, center + Vector((0.0, 0.0, 0.14 * hs)), 0.12 * hs, 0.11 * hs, n=12, front_bias=0.04)
    loft_rings(bm, [neck, jaw, cranium, crown])
    return neck, jaw, cranium, crown


def _add_box_ring_stack(bm, origin, w, d, h0, h1, n=10, front=0.06):
    a = make_ring(bm, origin + Vector((0.0, 0.0, h0)), w, d, n=n, front_bias=front)
    b = make_ring(bm, origin + Vector((0.0, 0.0, h1)), w * 0.86, d * 0.86, n=n, front_bias=front * 0.6)
    loft_rings(bm, [a, b])
    return a, b


def build_head(profile: BodyProfile, arm_obj):
    head_h, head_t = bone_pts(arm_obj, "Head")
    center = (head_h + head_t) * 0.5
    center = Vector((center.x, center.y + 0.01, center.z + 0.02))
    hs = 1.28 * (0.92 + 0.16 * (profile.neck_scale * 0.4 + 0.6))
    # Keep head size readable vs body height.
    hs *= 0.92 + 0.10 * (2.0 - profile.height)
    bm = bmesh.new()
    _skull(bm, center, hs)
    style = profile.head_style
    if style == "ember_crest_heat_mask":
        _add_box_ring_stack(bm, center + Vector((0.0, 0.08 * hs, 0.0)), 0.16 * hs, 0.05, -0.03, 0.05, front=0.02)
        _add_box_ring_stack(bm, center + Vector((0.04 * hs, 0.02, 0.12 * hs)), 0.12 * hs, 0.10 * hs, 0.0, 0.10 * hs, front=0.08)
        _add_box_ring_stack(bm, center + Vector((0.08 * hs, 0.01, 0.04)), 0.04, 0.08, -0.04, 0.08, n=8, front=0.04)
    elif style == "plate_helm_void":
        _add_box_ring_stack(bm, center + Vector((0.0, 0.02, 0.0)), 0.22 * hs, 0.20 * hs, -0.08, 0.12 * hs, n=8, front=0.04)
        _add_box_ring_stack(bm, center + Vector((0.0, 0.10 * hs, 0.08 * hs)), 0.20 * hs, 0.05, -0.02, 0.04, n=8, front=0.0)
        _add_box_ring_stack(bm, center + Vector((0.0, 0.12 * hs, 0.0)), 0.12 * hs, 0.03, -0.03, 0.03, n=8, front=0.0)
    elif style == "arc_crown_cap":
        _add_box_ring_stack(bm, center + Vector((0.0, 0.08 * hs, 0.02)), 0.12 * hs, 0.04, -0.03, 0.04, n=10, front=0.0)
        arc0 = make_ring(bm, center + Vector((0.0, 0.02, 0.14 * hs)), 0.22 * hs, 0.16 * hs, n=14, front_bias=0.08)
        arc1 = make_ring(bm, center + Vector((0.0, 0.02, 0.18 * hs)), 0.18 * hs, 0.13 * hs, n=14, front_bias=0.06)
        loft_rings(bm, [arc0, arc1])
    elif style == "ribbon_veil":
        _add_box_ring_stack(bm, center + Vector((0.0, 0.08 * hs, 0.02)), 0.11 * hs, 0.04, -0.03, 0.04, n=10, front=0.0)
        veil0 = make_ring(bm, center + Vector((0.04, 0.06, -0.04)), 0.06, 0.12, n=10, front_bias=0.10)
        veil1 = make_ring(bm, center + Vector((0.07, 0.10, -0.16)), 0.05, 0.10, n=10, front_bias=0.08)
        veil2 = make_ring(bm, center + Vector((0.09, 0.08, -0.28)), 0.04, 0.08, n=10, front_bias=0.06)
        loft_rings(bm, [veil0, veil1, veil2])
    elif style == "crystal_facet_mask":
        _add_box_ring_stack(bm, center + Vector((0.0, 0.09 * hs, 0.02)), 0.12 * hs, 0.04, -0.03, 0.05, n=6, front=0.0)
        _add_box_ring_stack(bm, center + Vector((0.06, 0.04, 0.08)), 0.07, 0.06, -0.02, 0.05, n=6, front=0.04)
    elif style == "authority_orbit_halo":
        _add_box_ring_stack(bm, center + Vector((0.0, 0.09 * hs, 0.02)), 0.12 * hs, 0.04, -0.03, 0.04, n=10, front=0.0)
        halo0 = make_ring(bm, center + Vector((0.04, 0.06, 0.14)), 0.22 * hs, 0.16 * hs, n=16, front_bias=0.06)
        halo1 = make_ring(bm, center + Vector((0.05, 0.07, 0.16)), 0.20 * hs, 0.14 * hs, n=16, front_bias=0.04)
        loft_rings(bm, [halo0, halo1])
    else:  # smoke_cowl_void
        cowl0 = make_ring(bm, center + Vector((0.03, 0.02, 0.02)), 0.20 * hs, 0.22 * hs, n=12, front_bias=0.16, side_bias=0.22)
        cowl1 = make_ring(bm, center + Vector((0.06, 0.04, 0.10)), 0.18 * hs, 0.20 * hs, n=12, front_bias=0.12, side_bias=0.28)
        cowl2 = make_ring(bm, center + Vector((0.08, 0.00, 0.16)), 0.12 * hs, 0.14 * hs, n=12, front_bias=0.08, side_bias=0.20)
        loft_rings(bm, [cowl0, cowl1, cowl2])
        _add_box_ring_stack(bm, center + Vector((-0.02, 0.10 * hs, 0.0)), 0.10 * hs, 0.03, -0.04, 0.04, n=8, front=0.0)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.006)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    obj = mesh_from_bm(bm, "head_shell")
    bm.free()
    obj["aa_head_style"] = style
    obj["aa_head_parts"] = 4
    return obj
