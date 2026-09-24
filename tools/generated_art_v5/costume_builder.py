"""Fitted costume shells from offset torso/limb rings. Not thin plates on a nude body."""
from __future__ import annotations

import bmesh
from mathutils import Vector

from generated_art_v5.body_profiles import BodyProfile
from generated_art_v5.torso_loft import bone_pts, loft_rings, make_ring, mesh_from_bm, torso_stations


def _shell_from_stations(name, stations, scale=1.12, thickness=0.018, start=1, end=6):
    bm = bmesh.new()
    outer = []
    inner = []
    subset = stations[start:end]
    for station in subset:
        w = station["width"] * scale
        d = station["depth"] * scale
        outer.append(
            make_ring(
                bm,
                station["center"],
                w,
                d,
                front_bias=station["front"] * 0.7,
                side_bias=station["side"],
            )
        )
        inner.append(
            make_ring(
                bm,
                station["center"],
                max(0.04, w - thickness * 2.0),
                max(0.04, d - thickness * 2.0),
                front_bias=station["front"] * 0.4,
                side_bias=station["side"],
            )
        )
    loft_rings(bm, outer)
    loft_rings(bm, list(reversed(inner)))
    n = min(len(outer[0]), len(inner[0]))
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((outer[0][i], outer[0][j], inner[0][j], inner[0][i]))
        bm.faces.new((outer[-1][j], outer[-1][i], inner[-1][i], inner[-1][j]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    obj = mesh_from_bm(bm, name)
    bm.free()
    obj["aa_costume_shell"] = 1
    return obj


def _limb_guard(name, a, b, radius, extra=0.02):
    mid = (Vector(a) + Vector(b)) * 0.5
    direction = Vector(b) - Vector(a)
    length = max(0.06, direction.length + extra)
    bm = bmesh.new()
    n = 10
    r0 = make_ring(bm, a, radius * 2.0, radius * 1.8, n=n, front_bias=0.06, direction=direction)
    r1 = make_ring(bm, mid, radius * 2.15, radius * 1.9, n=n, front_bias=0.08, direction=direction)
    r2 = make_ring(bm, b, radius * 1.7, radius * 1.5, n=n, front_bias=0.04, direction=direction)
    loft_rings(bm, [r0, r1, r2])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    obj = mesh_from_bm(bm, name)
    bm.free()
    return obj


def _panel(name, loc, w, d, h, front=0.08):
    bm = bmesh.new()
    a = make_ring(bm, Vector(loc) + Vector((0.0, 0.0, -h * 0.5)), w, d, n=10, front_bias=front)
    b = make_ring(bm, Vector(loc) + Vector((0.0, 0.0, h * 0.5)), w * 0.92, d * 0.92, n=10, front_bias=front * 0.7)
    loft_rings(bm, [a, b])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    obj = mesh_from_bm(bm, name)
    bm.free()
    return obj


def build_costume(profile: BodyProfile, arm_obj, mats: dict):
    stations = torso_stations(profile, arm_obj)
    pieces = []
    fid = profile.fighter_id

    def add(obj, mat_key="armor"):
        if obj.data.materials:
            obj.data.materials[0] = mats.get(mat_key, mats["armor"])
        else:
            obj.data.materials.append(mats.get(mat_key, mats["armor"]))
        pieces.append(obj)
        return obj

    # Every fighter gets a torso shell that actually wraps the body.
    add(_shell_from_stations("torso_shell", stations, scale=1.18 if fid == "rook-ironside" else 1.14, thickness=0.024, start=1, end=7), "armor" if fid in {"rook-ironside", "nix-calder"} else "cloth")

    la_h, la_t = bone_pts(arm_obj, "LowerArm_R")
    la_hl, la_tl = bone_pts(arm_obj, "LowerArm_L")
    ul_h, ul_t = bone_pts(arm_obj, "UpperLeg_R")
    ul_hl, ul_tl = bone_pts(arm_obj, "UpperLeg_L")
    add(_limb_guard("thigh_shell_r", ul_h, ul_t, 0.072 * profile.thigh_mass, 0.06), "secondary")
    add(_limb_guard("thigh_shell_l", ul_hl, ul_tl, 0.072 * profile.thigh_mass, 0.06), "secondary")
    ll_h, ll_t = bone_pts(arm_obj, "LowerLeg_R")
    ll_hl, ll_tl = bone_pts(arm_obj, "LowerLeg_L")
    add(_limb_guard("shin_shell_r", ll_h, ll_t, 0.048 * profile.calf_mass, 0.04), "secondary")
    add(_limb_guard("shin_shell_l", ll_hl, ll_tl, 0.048 * profile.calf_mass, 0.04), "secondary")
    chest_h, chest_t = bone_pts(arm_obj, "Chest")
    hips_h, _hips_t = bone_pts(arm_obj, "Hips")

    if fid == "ember-vale":
        add(_limb_guard("gauntlet_r", la_h, la_t, 0.055 * profile.forearm_mass, 0.05), "armor")
        add(_limb_guard("gauntlet_l", la_hl, la_tl, 0.048 * profile.forearm_mass, 0.04), "armor")
        add(_limb_guard("heat_guard_r", ul_h, ul_t, 0.078, 0.08), "secondary")
        add(_limb_guard("heat_guard_l", ul_hl, ul_tl, 0.078, 0.08), "secondary")
        add(_panel("shoulder_accent", chest_t + Vector((-0.16, 0.04, 0.02)), 0.12, 0.10, 0.10, 0.10), "accent")
        add(_panel("heat_vent", (chest_h + chest_t) * 0.5 + Vector((0.0, 0.08, 0.0)), 0.16, 0.06, 0.12, 0.04), "emit")
    elif fid == "rook-ironside":
        sl_h, sl_t = bone_pts(arm_obj, "Shoulder_L")
        sr_h, sr_t = bone_pts(arm_obj, "Shoulder_R")
        add(_panel("shoulder_pad_l", sl_t + Vector((0.04, 0.02, 0.03)), 0.22, 0.16, 0.16, 0.06), "armor")
        add(_panel("shoulder_pad_r", sr_t + Vector((-0.04, 0.02, 0.03)), 0.22, 0.16, 0.16, 0.06), "armor")
        add(_limb_guard("forearm_plate_r", la_h, la_t, 0.062, 0.04), "armor")
        add(_limb_guard("forearm_plate_l", la_hl, la_tl, 0.062, 0.04), "armor")
        add(_panel("belt_plate", hips_h + Vector((0.0, 0.04, 0.02)), 0.30, 0.14, 0.10, 0.08), "accent")
        add(_panel("back_plate", (chest_h + chest_t) * 0.5 + Vector((0.0, -0.08, 0.0)), 0.28, 0.10, 0.20, 0.02), "armor")
    elif fid == "juno-spark":
        mid = (chest_h + chest_t) * 0.5 + Vector((0.0, 0.07, 0.0))
        add(_panel("volt_panel_a", mid + Vector((0.08, 0.02, 0.02)), 0.12, 0.07, 0.16, 0.06), "accent")
        add(_panel("volt_panel_b", mid + Vector((-0.06, 0.01, -0.02)), 0.10, 0.06, 0.14, 0.06), "accent")
        add(_panel("volt_sash", mid + Vector((0.02, 0.03, 0.0)), 0.28, 0.06, 0.08, 0.10), "emit")
        add(_limb_guard("glove_r", la_h, la_t, 0.038, 0.03), "secondary")
        add(_limb_guard("glove_l", la_hl, la_tl, 0.038, 0.03), "secondary")
    elif fid == "kaia-windrow":
        nh, nt = bone_pts(arm_obj, "Neck")
        sl_h, sl_t = bone_pts(arm_obj, "Shoulder_L")
        sr_h, sr_t = bone_pts(arm_obj, "Shoulder_R")
        scarf0 = _panel("scarf_collar", nt + Vector((0.0, 0.02, 0.0)), 0.16, 0.10, 0.08, 0.10)
        scarf1 = _panel("scarf_fall", nt + Vector((0.05, 0.06, -0.18)), 0.07, 0.10, 0.30, 0.12)
        add(scarf0, "accent")
        add(scarf1, "accent")
        add(_panel("airfoil_l", sl_t + Vector((0.05, 0.02, 0.10)), 0.10, 0.05, 0.22, 0.16), "accent")
        add(_panel("airfoil_r", sr_t + Vector((-0.05, 0.02, 0.10)), 0.10, 0.05, 0.22, 0.16), "accent")
        add(_limb_guard("glove_r", la_h, la_t, 0.036, 0.03), "secondary")
        add(_limb_guard("glove_l", la_hl, la_tl, 0.036, 0.03), "secondary")
    elif fid == "nix-calder":
        add(_panel("crystal_core", (chest_h + chest_t) * 0.5 + Vector((0.0, 0.08, 0.02)), 0.10, 0.08, 0.10, 0.04), "emit")
        add(_limb_guard("forearm_plate_r", la_h, la_t, 0.046, 0.03), "armor")
        add(_limb_guard("forearm_plate_l", la_hl, la_tl, 0.046, 0.03), "armor")
        sl_h, sl_t = bone_pts(arm_obj, "Shoulder_L")
        add(_panel("crystal_shoulder", sl_t + Vector((0.0, 0.03, 0.02)), 0.10, 0.08, 0.08, 0.04), "accent")
    elif fid == "orion-vell":
        add(_shell_from_stations("coat_layer", stations, scale=1.22, thickness=0.016, start=1, end=7), "secondary")
        add(_panel("authority_panel", (chest_h + chest_t) * 0.5 + Vector((0.0, 0.09, 0.0)), 0.16, 0.06, 0.14, 0.06), "accent")
        add(_panel("orbit_trim", (chest_h + chest_t) * 0.5 + Vector((0.0, 0.02, 0.08)), 0.22, 0.18, 0.04, 0.04), "emit")
        add(_limb_guard("glove_r", la_h, la_t, 0.042, 0.03), "armor")
        add(_limb_guard("glove_l", la_hl, la_tl, 0.042, 0.03), "armor")
    elif fid == "vesper-nyx":
        add(_panel("coat_panel_l", hips_h + Vector((0.12, 0.04, 0.10)), 0.14, 0.10, 0.26, 0.16), "secondary")
        add(_panel("coat_panel_r", hips_h + Vector((-0.06, 0.03, 0.08)), 0.10, 0.08, 0.20, 0.10), "secondary")
        add(_panel("coat_tail_l", hips_h + Vector((0.14, 0.02, -0.08)), 0.07, 0.14, 0.28, 0.12), "secondary")
        add(_panel("coat_tail_r", hips_h + Vector((-0.07, 0.01, -0.06)), 0.05, 0.10, 0.22, 0.08), "secondary")
        add(_panel("void_trim", (chest_h + chest_t) * 0.5 + Vector((0.0, 0.08, 0.0)), 0.12, 0.05, 0.12, 0.04), "void")
        add(_limb_guard("glove_r", la_h, la_t, 0.038, 0.03), "armor")
        add(_limb_guard("glove_l", la_hl, la_tl, 0.038, 0.03), "armor")
    return pieces
