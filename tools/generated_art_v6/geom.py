"""Graphic primitives for v6. Facets are intentional. No voxel remesh."""
from __future__ import annotations

import bmesh
from mathutils import Vector

from generated_art_v5.torso_loft import loft_rings, make_ring, mesh_from_bm


def box_mesh(name, center, size, yaw=0.0):
    """Axis-aligned graphic block. size=(x,y,z)."""
    import math

    bm = bmesh.new()
    cx, cy, cz = Vector(center)
    sx, sy, sz = size
    hx, hy, hz = sx * 0.5, sy * 0.5, sz * 0.5
    corners = [
        (-hx, -hy, -hz),
        (hx, -hy, -hz),
        (hx, hy, -hz),
        (-hx, hy, -hz),
        (-hx, -hy, hz),
        (hx, -hy, hz),
        (hx, hy, hz),
        (-hx, hy, hz),
    ]
    c = math.cos(yaw)
    s = math.sin(yaw)
    verts = []
    for x, y, z in corners:
        rx = x * c - y * s
        ry = x * s + y * c
        verts.append(bm.verts.new((cx + rx, cy + ry, cz + z)))
    faces = (
        (0, 1, 2, 3),
        (4, 7, 6, 5),
        (0, 4, 5, 1),
        (3, 2, 6, 7),
        (0, 3, 7, 4),
        (1, 5, 6, 2),
    )
    for ids in faces:
        bm.faces.new([verts[i] for i in ids])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    obj = mesh_from_bm(bm, name)
    bm.free()
    obj["aa_graphic_box"] = 1
    return obj


def wedge_mesh(name, origin, direction, length, width, height, taper=0.45):
    direction = Vector(direction)
    if direction.length < 1e-4:
        direction = Vector((0.0, 1.0, 0.0))
    direction = direction.normalized()
    bm = bmesh.new()
    r0 = make_ring(bm, origin, width, height, n=8, front_bias=0.08, direction=direction)
    tip = Vector(origin) + direction * length
    r1 = make_ring(bm, tip, width * taper, height * taper, n=8, front_bias=0.04, direction=direction)
    loft_rings(bm, [r0, r1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    obj = mesh_from_bm(bm, name)
    bm.free()
    obj["aa_graphic_wedge"] = 1
    return obj


def loft_stack(name, stations, n=12):
    bm = bmesh.new()
    rings = []
    for center, width, depth, front, direction in stations:
        rings.append(
            make_ring(
                bm,
                center,
                width,
                depth,
                n=n,
                front_bias=front,
                direction=direction or Vector((0.0, 0.0, 1.0)),
            )
        )
    loft_rings(bm, rings)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    obj = mesh_from_bm(bm, name)
    bm.free()
    return obj


def join_named(objects, name: str):
    from generated_art_v5.joint_blends import join_objects

    obj = join_objects(objects, name)
    obj.name = name
    if obj.data is not None:
        obj.data.name = name
    return obj
