"""Faceless combat masks/helmets/cowls. No generic primitive as the dominant read."""
from __future__ import annotations

from mathutils import Vector

from generated_art_v5.torso_loft import bone_pts
from generated_art_v6.body_profiles import StyleProfile
from generated_art_v6.geom import box_mesh, join_named, loft_stack


def _center(arm_obj):
    head_h, head_t = bone_pts(arm_obj, "Head")
    center = (head_h + head_t) * 0.5
    return Vector((center.x, center.y + 0.012, center.z + 0.018))


def build_mask(profile: StyleProfile, arm_obj):
    c = _center(arm_obj)
    hs = 1.34 * (0.90 + 0.18 * (profile.neck_scale * 0.4 + 0.6))
    hs *= 0.90 + 0.12 * (2.0 - profile.height)
    style = profile.head_style
    skull = loft_stack(
        "mask_skull",
        [
            (c + Vector((0.0, 0.0, -0.11 * hs)), 0.12 * hs, 0.11 * hs, 0.04, Vector((0.0, 0.0, 1.0))),
            (c + Vector((0.0, 0.03 * hs, -0.02 * hs)), 0.20 * hs, 0.18 * hs, 0.16, Vector((0.0, 0.0, 1.0))),
            (c + Vector((0.0, 0.02 * hs, 0.07 * hs)), 0.22 * hs, 0.19 * hs, 0.10, Vector((0.0, 0.0, 1.0))),
            (c + Vector((0.0, 0.0, 0.16 * hs)), 0.14 * hs, 0.13 * hs, 0.04, Vector((0.0, 0.0, 1.0))),
        ],
        n=12,
    )
    parts = [skull]
    if style == "ember_angular_mask":
        parts.append(box_mesh("mask_face", c + Vector((0.0, 0.10 * hs, 0.01)), (0.18 * hs, 0.05, 0.12 * hs)))
        parts.append(box_mesh("mask_crest_a", c + Vector((0.03 * hs, 0.02, 0.18 * hs)), (0.14 * hs, 0.10 * hs, 0.10 * hs)))
        parts.append(box_mesh("mask_crest_b", c + Vector((0.08 * hs, 0.01, 0.10 * hs)), (0.06 * hs, 0.08 * hs, 0.14 * hs)))
        parts.append(box_mesh("mask_vent", c + Vector((0.0, 0.11 * hs, -0.02)), (0.10 * hs, 0.03, 0.06 * hs)))
    elif style == "rook_armored_helm":
        parts.append(box_mesh("mask_helm", c + Vector((0.0, 0.02, 0.02)), (0.28 * hs, 0.24 * hs, 0.22 * hs)))
        parts.append(box_mesh("mask_brow", c + Vector((0.0, 0.12 * hs, 0.08 * hs)), (0.24 * hs, 0.06, 0.06 * hs)))
        parts.append(box_mesh("mask_void", c + Vector((0.0, 0.13 * hs, 0.0)), (0.14 * hs, 0.04, 0.08 * hs)))
        parts.append(box_mesh("mask_cheek_l", c + Vector((0.10 * hs, 0.08 * hs, -0.02)), (0.08 * hs, 0.08 * hs, 0.10 * hs)))
        parts.append(box_mesh("mask_cheek_r", c + Vector((-0.10 * hs, 0.08 * hs, -0.02)), (0.08 * hs, 0.08 * hs, 0.10 * hs)))
    elif style == "juno_speed_mask":
        parts.append(box_mesh("mask_face", c + Vector((0.0, 0.10 * hs, 0.01)), (0.14 * hs, 0.04, 0.10 * hs)))
        parts.append(loft_stack("mask_crown", [
            (c + Vector((0.02, 0.02, 0.14 * hs)), 0.24 * hs, 0.16 * hs, 0.08, Vector((0.0, 0.0, 1.0))),
            (c + Vector((0.06, 0.03, 0.20 * hs)), 0.18 * hs, 0.10 * hs, 0.06, Vector((0.0, 0.0, 1.0))),
        ], n=12))
        parts.append(box_mesh("mask_trim", c + Vector((0.08 * hs, 0.08 * hs, 0.04)), (0.04, 0.08, 0.10 * hs)))
    elif style == "kaia_veil_shell":
        parts.append(box_mesh("mask_face", c + Vector((0.0, 0.10 * hs, 0.01)), (0.13 * hs, 0.04, 0.09 * hs)))
        parts.append(loft_stack("mask_veil", [
            (c + Vector((0.04, 0.07, -0.02)), 0.08, 0.14, 0.10, Vector((0.2, 0.4, -0.6))),
            (c + Vector((0.08, 0.12, -0.16)), 0.06, 0.12, 0.08, Vector((0.2, 0.4, -0.6))),
            (c + Vector((0.11, 0.10, -0.30)), 0.05, 0.10, 0.06, Vector((0.2, 0.4, -0.6))),
        ], n=10))
        parts.append(box_mesh("mask_anchor", c + Vector((0.05, 0.06, 0.08 * hs)), (0.05, 0.05, 0.06)))
    elif style == "nix_crystal_mask":
        parts.append(box_mesh("mask_plane", c + Vector((0.0, 0.11 * hs, 0.02)), (0.16 * hs, 0.05, 0.12 * hs)))
        parts.append(box_mesh("mask_facet_l", c + Vector((0.07, 0.06, 0.08)), (0.08, 0.07, 0.08)))
        parts.append(box_mesh("mask_facet_r", c + Vector((-0.07, 0.06, 0.08)), (0.08, 0.07, 0.08)))
        parts.append(box_mesh("mask_crown", c + Vector((0.0, 0.02, 0.16 * hs)), (0.16 * hs, 0.10 * hs, 0.08 * hs)))
    elif style == "orion_authority_mask":
        parts.append(box_mesh("mask_face", c + Vector((0.0, 0.11 * hs, 0.01)), (0.16 * hs, 0.04, 0.11 * hs)))
        parts.append(loft_stack("mask_halo", [
            (c + Vector((0.04, 0.06, 0.15)), 0.26 * hs, 0.18 * hs, 0.06, Vector((0.0, 0.0, 1.0))),
            (c + Vector((0.05, 0.07, 0.18)), 0.24 * hs, 0.16 * hs, 0.04, Vector((0.0, 0.0, 1.0))),
        ], n=14))
        parts.append(box_mesh("mask_brow", c + Vector((0.0, 0.10 * hs, 0.07)), (0.18 * hs, 0.04, 0.05)))
    else:  # vesper_asymmetric_cowl
        parts.append(loft_stack("mask_cowl", [
            (c + Vector((0.04, 0.02, 0.02)), 0.24 * hs, 0.24 * hs, 0.16, Vector((0.0, 0.0, 1.0))),
            (c + Vector((0.08, 0.05, 0.12)), 0.22 * hs, 0.22 * hs, 0.14, Vector((0.0, 0.0, 1.0))),
            (c + Vector((0.11, 0.00, 0.20)), 0.14 * hs, 0.16 * hs, 0.10, Vector((0.0, 0.0, 1.0))),
        ], n=12))
        parts.append(box_mesh("mask_void_plane", c + Vector((-0.04, 0.12 * hs, 0.0)), (0.10 * hs, 0.04, 0.10 * hs)))
        parts.append(box_mesh("mask_split", c + Vector((0.08, 0.04, 0.06)), (0.08, 0.10, 0.12)))
    obj = join_named(parts, "head_shell")
    obj["aa_head_style"] = style
    obj["aa_head_parts"] = len(parts)
    obj["aa_mask"] = 1
    return obj
