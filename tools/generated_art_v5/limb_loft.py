"""Tapered lofted limbs. No rigid cylinders, no remesh."""
from __future__ import annotations

import bmesh
from mathutils import Vector

from generated_art_v5.body_profiles import BodyProfile
from generated_art_v5.torso_loft import bone_pts, cap_ring, loft_rings, make_ring, mesh_from_bm


def _lerp(a: Vector, b: Vector, t: float) -> Vector:
    return a + (b - a) * t


def loft_limb(name, stations):
    bm = bmesh.new()
    rings = []
    for center, direction, rx, ry, front in stations:
        rings.append(make_ring(bm, center, rx * 2.0, ry * 2.0, front_bias=front, direction=direction))
    loft_rings(bm, rings)
    cap_ring(bm, rings[0], rings[0][0].co + (Vector(stations[0][1]).normalized() * -0.01), inward=True)
    cap_ring(bm, rings[-1], rings[-1][0].co + (Vector(stations[-1][1]).normalized() * 0.01), inward=False)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    obj = mesh_from_bm(bm, name)
    bm.free()
    obj["aa_loft"] = "limb"
    obj["aa_no_remesh"] = 1
    return obj


def build_arm(profile: BodyProfile, arm_obj, side: str):
    mass_u = profile.upper_arm_mass
    mass_f = profile.forearm_mass
    length = profile.limb_length
    asy = 1.0 + (0.06 if side == "R" and profile.asymmetry.get("shoulder_r") else 0.0)
    sh_h, sh_t = bone_pts(arm_obj, f"Shoulder_{side}")
    ua_h, ua_t = bone_pts(arm_obj, f"UpperArm_{side}")
    la_h, la_t = bone_pts(arm_obj, f"LowerArm_{side}")
    hd_h, _hd_t = bone_pts(arm_obj, f"Hand_{side}")
    dir_sh = (sh_t - sh_h) if (sh_t - sh_h).length > 1e-4 else Vector((1.0 if side == "L" else -1.0, 0.0, 0.0))
    dir_ua = ua_t - ua_h
    dir_la = la_t - la_h
    # Stretch slightly along limb_length without changing sockets.
    def stretch(a, b, t):
        return a + (b - a) * t * (0.92 + 0.08 * length)

    stations = [
        (sh_t, dir_sh, 0.092 * profile.shoulder_width * asy, 0.082 * profile.shoulder_width, 0.10),
        (stretch(ua_h, ua_t, 0.28), dir_ua, 0.074 * mass_u, 0.066 * mass_u, 0.06),
        (ua_t, dir_ua, 0.062 * mass_u, 0.058 * mass_u, 0.04),
        (stretch(la_h, la_t, 0.40), dir_la, 0.060 * mass_f, 0.052 * mass_f, 0.08),
        (la_t, dir_la, 0.046 * mass_f, 0.040 * mass_f, 0.04),
    ]
    return loft_limb(f"arm_{side}", stations)


def build_leg(profile: BodyProfile, arm_obj, side: str):
    thigh = profile.thigh_mass
    calf = profile.calf_mass
    length = profile.limb_length
    ul_h, ul_t = bone_pts(arm_obj, f"UpperLeg_{side}")
    ll_h, ll_t = bone_pts(arm_obj, f"LowerLeg_{side}")
    ft_h, _ft_t = bone_pts(arm_obj, f"Foot_{side}")
    dir_ul = ul_t - ul_h
    dir_ll = ll_t - ll_h
    def stretch(a, b, t):
        return a + (b - a) * t * (0.92 + 0.08 * length)

    stations = [
        (ul_h, dir_ul, 0.096 * profile.pelvis_width, 0.086 * profile.pelvis_width, 0.08),
        (stretch(ul_h, ul_t, 0.42), dir_ul, 0.086 * thigh, 0.076 * thigh, 0.06),
        (ul_t, dir_ul, 0.068 * thigh, 0.064 * calf, 0.04),
        (stretch(ll_h, ll_t, 0.38), dir_ll, 0.058 * calf, 0.050 * calf, 0.10),
        (ll_t, dir_ll, 0.044 * calf, 0.038 * calf, 0.04),
    ]
    return loft_limb(f"leg_{side}", stations)


def build_limbs(profile: BodyProfile, arm_obj):
    return [
        build_arm(profile, arm_obj, "L"),
        build_arm(profile, arm_obj, "R"),
        build_leg(profile, arm_obj, "L"),
        build_leg(profile, arm_obj, "R"),
    ]
