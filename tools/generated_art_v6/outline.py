"""Cheap inverted-hull outline for select/close views. Hidden in gameplay by default."""
from __future__ import annotations

import bmesh
import bpy
from mathutils import Vector

from generated_art_v6.cel_materials import assign


def add_outline_hull(src, mat, width=0.014):
    if src is None or src.type != "MESH":
        return None
    mesh = src.data.copy()
    obj = bpy.data.objects.new(f"{src.name}.outline", mesh)
    bpy.context.collection.objects.link(obj)
    obj.matrix_world = src.matrix_world.copy()
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bm.verts.ensure_lookup_table()
    bm.normal_update()
    for vert in bm.verts:
        vert.co += Vector(vert.normal) * width
    bmesh.ops.reverse_faces(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    assign(obj, mat)
    obj["aa_outline"] = 1
    obj.hide_render = True
    obj.hide_viewport = True
    return obj


def set_outlines_visible(visible: bool) -> None:
    for obj in bpy.data.objects:
        if obj.get("aa_outline"):
            obj.hide_render = not visible
            obj.hide_viewport = not visible
