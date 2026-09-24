"""Weld overlapping loft rings at shoulders/hips. Authored topology, not voxel remesh."""
from __future__ import annotations

import bmesh
import bpy
from mathutils import Vector


def _active():
    return bpy.context.view_layer.objects.active


def join_objects(objects, name: str):
    objects = [obj for obj in objects if obj is not None]
    if not objects:
        raise ValueError("join_objects requires at least one mesh")
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    if len(objects) > 1:
        bpy.ops.object.join()
    body = _active()
    body.name = name
    return body


def weld_seams(obj, distance=0.028):
    """Merge overlapping joint verts. This is a topological weld, not a voxel remesh."""
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    bm = bmesh.from_edit_mesh(obj.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=distance)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bmesh.update_edit_mesh(obj.data)
    bpy.ops.object.mode_set(mode="OBJECT")
    return obj


def smooth_deform_zones(obj, iterations=4, factor=0.42):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    bm = bmesh.from_edit_mesh(obj.data)
    bmesh.ops.smooth_vert(bm, verts=bm.verts, factor=factor, use_axis_x=True, use_axis_y=True, use_axis_z=True)
    for _ in range(max(0, iterations - 1)):
        bmesh.ops.smooth_vert(bm, verts=bm.verts, factor=factor * 0.55, use_axis_x=True, use_axis_y=True, use_axis_z=True)
    bmesh.update_edit_mesh(obj.data)
    bpy.ops.object.mode_set(mode="OBJECT")
    return obj


def connected_components(obj) -> int:
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.verts.ensure_lookup_table()
    seen = set()
    islands = 0
    for vert in bm.verts:
        if vert.index in seen:
            continue
        islands += 1
        stack = [vert]
        seen.add(vert.index)
        while stack:
            cur = stack.pop()
            for e in cur.link_edges:
                other = e.other_vert(cur)
                if other.index not in seen:
                    seen.add(other.index)
                    stack.append(other)
    bm.free()
    return islands


def apply_subdiv(obj, levels=1):
    """Catmull-Clark on authored loft topology. Not voxel remesh."""
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    sub = obj.modifiers.new("AA_Subdiv", "SUBSURF")
    sub.levels = levels
    sub.render_levels = levels
    bpy.ops.object.modifier_apply(modifier=sub.name)
    return obj


def assemble_body(torso, limbs, name: str):
    body = join_objects([torso] + list(limbs), name)
    weld_seams(body, 0.034)
    smooth_deform_zones(body, 2, 0.28)
    apply_subdiv(body, 1)
    body.name = name
    body["aa_construction"] = "loft_weld"
    body["aa_no_remesh"] = 1
    if any(mod.type == "REMESH" for mod in body.modifiers):
        raise RuntimeError("v5 body must not carry a remesh modifier")
    return body


def snap_to_ground(meshes) -> float:
    zs = []
    for obj in meshes:
        if obj is None or obj.type != "MESH":
            continue
        zs.extend((obj.matrix_world @ v.co).z for v in obj.data.vertices)
    if not zs:
        return 99.0
    minz = min(zs)
    if abs(minz) <= 0.002:
        return abs(minz)
    for obj in meshes:
        if obj is None or obj.type != "MESH":
            continue
        inv = obj.matrix_world.inverted()
        delta = inv.to_3x3() @ Vector((0.0, 0.0, -minz))
        for vert in obj.data.vertices:
            vert.co += delta
        obj.data.update()
    zs = []
    for obj in meshes:
        zs.extend((obj.matrix_world @ v.co).z for v in obj.data.vertices)
    return abs(min(zs)) if zs else 99.0
