"""Continuous torso surface from explicit cross-section rings. No voxel remesh."""
from __future__ import annotations

import math

import bmesh
import bpy
from mathutils import Vector

from generated_art_v5.body_profiles import BodyProfile

RING_COUNT = 20


def _basis(direction: Vector):
    axis = direction.normalized()
    up = Vector((0.0, 0.0, 1.0))
    if abs(axis.dot(up)) > 0.92:
        up = Vector((0.0, 1.0, 0.0))
    right = axis.cross(up).normalized()
    fwd = right.cross(axis).normalized()
    return right, fwd


def make_ring(bm, center, width, depth, n=RING_COUNT, front_bias=0.0, side_bias=0.0, direction=None):
    """Ellipse in the plane perpendicular to direction. +Y is canonical front when direction is +Z."""
    center = Vector(center)
    if direction is None:
        direction = Vector((0.0, 0.0, 1.0))
    right, fwd = _basis(Vector(direction))
    # Align "fwd" toward world +Y so chest volume reads as front.
    if fwd.dot(Vector((0.0, 1.0, 0.0))) < 0:
        fwd = -fwd
        right = -right
    verts = []
    for i in range(n):
        t = 2.0 * math.pi * i / n
        x = (width * 0.5) * math.cos(t)
        y = (depth * 0.5) * math.sin(t)
        if y > 0.0:
            y *= 1.0 + front_bias
        if x > 0.0:
            x *= 1.0 + side_bias
        else:
            x *= 1.0 - side_bias * 0.35
        verts.append(bm.verts.new(center + right * x + fwd * y))
    return verts


def loft_rings(bm, rings):
    faces = []
    for a, b in zip(rings[:-1], rings[1:]):
        n = min(len(a), len(b))
        for i in range(n):
            j = (i + 1) % n
            faces.append(bm.faces.new((a[i], a[j], b[j], b[i])))
    return faces


def cap_ring(bm, ring, center, inward=True):
    c = bm.verts.new(Vector(center))
    n = len(ring)
    for i in range(n):
        j = (i + 1) % n
        if inward:
            bm.faces.new((c, ring[j], ring[i]))
        else:
            bm.faces.new((c, ring[i], ring[j]))
    return c


def mesh_from_bm(bm, name: str):
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return obj


def bone_pts(arm_obj, name):
    bone = arm_obj.data.bones[name]
    mw = arm_obj.matrix_world
    return mw @ bone.head_local, mw @ bone.tail_local


def torso_stations(profile: BodyProfile, arm_obj):
    h = profile.height
    sw = profile.shoulder_width
    cd = profile.chest_depth
    ww = profile.waist_width
    pw = profile.pelvis_width
    taper = profile.torso_taper
    neck = profile.neck_scale
    asy = float(profile.asymmetry.get("shoulder_r") or profile.asymmetry.get("coat_l") or 0.0)
    neck_h, neck_t = bone_pts(arm_obj, "Neck")
    chest_h, chest_t = bone_pts(arm_obj, "Chest")
    spine_h, _spine_t = bone_pts(arm_obj, "Spine")
    hips_h, _hips_t = bone_pts(arm_obj, "Hips")
    return [
        {"name": "neck", "center": (0.0, 0.01 * h, neck_t.z), "width": 0.11 * neck, "depth": 0.10 * neck, "front": 0.04, "side": 0.0},
        {"name": "upper_chest", "center": (0.0, 0.03 * h, chest_t.z - 0.02 * h), "width": 0.30 * sw, "depth": 0.17 * cd, "front": 0.18, "side": asy * 0.25},
        {"name": "chest", "center": (0.0, 0.045 * h, (chest_h.z + chest_t.z) * 0.5), "width": 0.34 * sw, "depth": 0.22 * cd, "front": 0.28, "side": asy * 0.20},
        {"name": "ribcage", "center": (0.0, 0.03 * h, chest_h.z), "width": 0.28 * sw * (0.92 + 0.08 * taper), "depth": 0.17 * cd, "front": 0.16, "side": asy * 0.08},
        {"name": "waist", "center": (0.0, 0.02 * h, spine_h.z + 0.04 * h), "width": 0.20 * ww * taper, "depth": 0.14 * cd, "front": 0.08, "side": 0.0},
        {"name": "upper_pelvis", "center": (0.0, 0.02 * h, hips_h.z + 0.08 * h), "width": 0.24 * pw, "depth": 0.16 * pw, "front": 0.10, "side": 0.0},
        {"name": "pelvis", "center": (0.0, 0.015 * h, hips_h.z), "width": 0.26 * pw, "depth": 0.18 * pw, "front": 0.12, "side": 0.0},
    ]


def build_torso(profile: BodyProfile, arm_obj, name: str):
    bm = bmesh.new()
    rings = []
    for station in torso_stations(profile, arm_obj):
        rings.append(
            make_ring(
                bm,
                station["center"],
                station["width"],
                station["depth"],
                front_bias=station["front"],
                side_bias=station["side"],
            )
        )
    loft_rings(bm, rings)
    cap_ring(bm, rings[0], (0.0, 0.01, rings[0][0].co.z + 0.01), inward=False)
    cap_ring(bm, rings[-1], (0.0, 0.01, rings[-1][0].co.z - 0.02), inward=True)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    obj = mesh_from_bm(bm, name)
    bm.free()
    obj["aa_loft"] = "torso"
    obj["aa_no_remesh"] = 1
    return obj, rings
