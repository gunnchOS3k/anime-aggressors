"""Cohesive anatomical body v2: overlapping volumes → voxel remesh → smooth weights."""
from __future__ import annotations

import bmesh
import bpy
from mathutils import Vector
from mathutils.kdtree import KDTree

from generated_production_art.body_v2 import MAX_ATTACH_M, recipe
from generated_production_art.profiles import FighterProfile


def _active():
    return bpy.context.active_object


def _apply(obj=None) -> None:
    obj = obj or _active()
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)


def _prim_sphere(loc, radius, name, segs=14):
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=max(0.012, radius), location=loc, segments=segs, ring_count=max(8, segs // 2)
    )
    obj = _active()
    obj.name = name
    return obj


def _prim_ico(loc, radius, name, subdiv=2):
    bpy.ops.mesh.primitive_ico_sphere_add(radius=max(0.012, radius), location=loc, subdivisions=subdiv)
    obj = _active()
    obj.name = name
    return obj


def _prim_cube(loc, scale, name):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    obj = _active()
    obj.name = name
    obj.scale = scale
    _apply(obj)
    return obj


def _prim_cylinder(loc, radius, depth, name, rot=None, verts=12):
    bpy.ops.mesh.primitive_cylinder_add(
        radius=max(0.01, radius), depth=max(0.02, depth), location=loc, vertices=verts
    )
    obj = _active()
    obj.name = name
    if rot is not None:
        obj.rotation_euler = rot
        _apply(obj)
    return obj


def _prim_cone(loc, r1, r2, depth, name, rot=None):
    bpy.ops.mesh.primitive_cone_add(
        vertices=8, radius1=max(0.008, r1), radius2=max(0.002, r2), depth=max(0.02, depth), location=loc
    )
    obj = _active()
    obj.name = name
    if rot is not None:
        obj.rotation_euler = rot
        _apply(obj)
    return obj


def _prim_torus(loc, major, minor, name):
    bpy.ops.mesh.primitive_torus_add(location=loc, major_radius=major, minor_radius=minor)
    obj = _active()
    obj.name = name
    return obj


def _capsule(p0, p1, radius, name, segs=12):
    p0 = Vector(p0)
    p1 = Vector(p1)
    d = p1 - p0
    length = max(d.length, 0.02)
    mid = (p0 + p1) * 0.5
    rot = d.to_track_quat("Z", "Y").to_euler()
    cyl = _prim_cylinder(mid, radius, length, name, rot=rot, verts=segs)
    a = _prim_sphere(p0, radius, name + "_cap_a", segs=segs)
    b = _prim_sphere(p1, radius, name + "_cap_b", segs=segs)
    return [cyl, a, b]


def _bone_pts(arm_obj, name):
    bone = arm_obj.data.bones[name]
    return arm_obj.matrix_world @ bone.head_local, arm_obj.matrix_world @ bone.tail_local


def _toon_mat(name, color, emit=0.04, metallic=0.04, rough=0.58):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Base Color"].default_value = (color[0], color[1], color[2], 1.0)
    if "Roughness" in bsdf.inputs:
        bsdf.inputs["Roughness"].default_value = rough
    if "Metallic" in bsdf.inputs:
        bsdf.inputs["Metallic"].default_value = metallic
    if "Specular" in bsdf.inputs:
        bsdf.inputs["Specular"].default_value = 0.28
    if "Emission" in bsdf.inputs:
        bsdf.inputs["Emission"].default_value = (color[0], color[1], color[2], 1.0)
    if "Emission Strength" in bsdf.inputs:
        bsdf.inputs["Emission Strength"].default_value = emit
    fresnel = nt.nodes.new("ShaderNodeFresnel")
    fresnel.inputs["IOR"].default_value = 1.55
    rim = nt.nodes.new("ShaderNodeEmission")
    rim.inputs["Color"].default_value = (min(1.0, color[0] * 1.35), min(1.0, color[1] * 1.35), min(1.0, color[2] * 1.35), 1.0)
    rim.inputs["Strength"].default_value = 0.22
    mix = nt.nodes.new("ShaderNodeMixShader")
    mix.inputs["Fac"].default_value = 0.18
    nt.links.new(fresnel.outputs["Fac"], mix.inputs["Fac"])
    nt.links.new(bsdf.outputs["BSDF"], mix.inputs[1])
    nt.links.new(rim.outputs["Emission"], mix.inputs[2])
    nt.links.new(mix.outputs["Shader"], out.inputs["Surface"])
    mat.diffuse_color = (color[0], color[1], color[2], 1.0)
    return mat


def _assign(obj, mat) -> None:
    if obj.data.materials:
        obj.data.materials[0] = mat
    else:
        obj.data.materials.append(mat)


def _join(parts, name):
    bpy.ops.object.select_all(action="DESELECT")
    for part in parts:
        if part and part.name in bpy.data.objects:
            part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    body = _active()
    body.name = name
    return body


def _voxel_remesh(obj, size=0.018) -> None:
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode="OBJECT")
    obj.data.remesh_voxel_size = size
    if hasattr(obj.data, "remesh_voxel_adaptivity"):
        obj.data.remesh_voxel_adaptivity = 0.04
    if hasattr(obj.data, "use_remesh_preserve_volume"):
        obj.data.use_remesh_preserve_volume = True
    try:
        bpy.ops.object.voxel_remesh()
    except Exception:
        # Keep the joined overlapping volume mesh if remesh is unavailable.
        pass


def _smooth_and_decimate(obj, target_tris=22000) -> None:
    bpy.context.view_layer.objects.active = obj
    shade = obj.modifiers.new("AA_Smooth", "SMOOTH")
    shade.factor = 0.55
    shade.iterations = 8
    bpy.ops.object.modifier_apply(modifier=shade.name)
    tris = len(obj.data.polygons)
    if tris > 35000:
        dec = obj.modifiers.new("AA_Decimate", "DECIMATE")
        dec.ratio = max(0.25, target_tris / max(tris, 1))
        bpy.ops.object.modifier_apply(modifier=dec.name)
    elif tris < 8000:
        sub = obj.modifiers.new("AA_Subdiv", "SUBSURF")
        sub.levels = 1
        sub.render_levels = 1
        bpy.ops.object.modifier_apply(modifier=sub.name)
    bpy.ops.object.shade_smooth()


def _connected_components(obj) -> int:
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.verts.ensure_lookup_table()
    seen = set()
    islands = 0
    for v in bm.verts:
        if v.index in seen:
            continue
        islands += 1
        stack = [v]
        seen.add(v.index)
        while stack:
            cur = stack.pop()
            for e in cur.link_edges:
                other = e.other_vert(cur)
                if other.index not in seen:
                    seen.add(other.index)
                    stack.append(other)
    bm.free()
    return islands


def _head_volumes(fid, p, r, head_h, head_t, lean):
    parts = []
    center = (head_h + head_t) * 0.5
    center = Vector((center.x, center.y + 0.02 * lean, center.z))
    hs = p.head_scale
    style = r.head_style
    if style == "ember_cap":
        head = _prim_ico(center, 0.145 * hs, "head_core", 2)
        for v in head.data.vertices:
            co = v.co
            co.x *= 1.16
            co.y *= 0.78
            co.z *= 0.90
            if co.y < -0.01:
                co.y *= 0.55
            v.co = co
        parts.append(head)
        parts.append(_prim_cube((center.x, center.y - 0.05, center.z + 0.01), (0.12 * hs, 0.025, 0.045), "visor_band"))
        parts.append(
            _prim_cone((center.x, center.y - 0.02, center.z + 0.14 * hs), 0.07, 0.01, 0.20 * hs, "ember_crest")
        )
        parts.append(_prim_cone((center.x + 0.05, center.y - 0.01, center.z + 0.10), 0.03, 0.006, 0.10, "crest_fin"))
    elif style == "plate_helm":
        parts.append(_prim_sphere(center, 0.13 * hs, "helm_round"))
        parts.append(_prim_cube(center, (0.16 * hs, 0.14 * hs, 0.14 * hs), "helm"))
        parts.append(_prim_cube((center.x, center.y - 0.07, center.z + 0.01), (0.11, 0.02, 0.04), "visor_void"))
        parts.append(_prim_cube((center.x, center.y, center.z + 0.12 * hs), (0.14, 0.11, 0.045), "helm_brow"))
        parts.append(_prim_cylinder((center.x, center.y, center.z - 0.11), 0.09, 0.08, "helm_neck_ring"))
    elif style == "arc_crown":
        parts.append(_prim_ico(center, 0.12 * hs, "head_core", 2))
        parts.append(_prim_torus((center.x, center.y, center.z + 0.11 * hs), 0.11 * hs, 0.018, "arc_crown"))
        parts.append(_prim_cone((center.x, center.y, center.z + 0.16 * hs), 0.035, 0.006, 0.10, "arc_spike"))
    elif style == "ribbon_veil":
        head = _prim_ico(center, 0.125 * hs, "head_core", 2)
        for v in head.data.vertices:
            v.co.z *= 1.10
            v.co.x *= 0.90
        parts.append(head)
        parts.append(_prim_sphere((center.x, center.y + 0.08, center.z - 0.02), 0.08 * hs, "veil_volume"))
        parts.append(_prim_capsule_like((center.x, center.y + 0.12, center.z - 0.08), 0.045, 0.16, "veil_fall"))
    elif style == "crystal_facet":
        crystal = _prim_ico(center, 0.135 * hs, "head_core", 1)
        for v in crystal.data.vertices:
            v.co *= 1.12
            v.co.z *= 1.16
        parts.append(crystal)
        parts.append(_prim_ico((center.x, center.y - 0.03, center.z + 0.05), 0.065, "facet_accent", 1))
    elif style == "orbit_halo":
        head = _prim_ico(center, 0.128 * hs, "head_core", 2)
        for v in head.data.vertices:
            v.co.z *= 1.14
        parts.append(head)
        parts.append(_prim_torus((center.x, center.y, center.z + 0.09), 0.125 * hs, 0.014, "halo_brow"))
    else:  # smoke_cowl
        cowl = _prim_ico(center + Vector((0.0, 0.04, 0.03)), 0.16 * hs, "cowl", 2)
        for v in cowl.data.vertices:
            v.co.y *= 1.22
            v.co.z *= 1.12
            if v.co.y < -0.03:
                v.co.y *= 0.50
        parts.append(cowl)
        parts.append(_prim_sphere(center, 0.11 * hs, "cowl_core"))
        parts.append(_prim_sphere((center.x, center.y - 0.06, center.z), 0.05, "cowl_void"))
    return parts


def _prim_capsule_like(loc, radius, depth, name):
    return _prim_cylinder(loc, radius, depth, name, verts=14)


def _mitten(loc, side_sign, hs, name):
    palm = _prim_sphere(loc, 0.048 * hs, name + "_palm", segs=12)
    fingers = _prim_sphere(
        (loc[0] + 0.008 * side_sign, loc[1] + 0.055 * hs, loc[2] - 0.004),
        0.038 * hs,
        name + "_fingers",
        segs=12,
    )
    thumb = _prim_sphere(
        (loc[0] + 0.042 * side_sign, loc[1] + 0.012, loc[2] + 0.008),
        0.024 * hs,
        name + "_thumb",
        segs=10,
    )
    return [palm, fingers, thumb]


def _boot(loc, fs, name):
    mid = (loc[0], loc[1] + 0.07 * fs, 0.048 * fs)
    body = _prim_sphere(mid, 0.048 * fs, name + "_body", segs=12)
    body.scale = (0.95, 1.45, 0.88)
    _apply(body)
    heel = _prim_sphere((loc[0], loc[1] - 0.01, 0.024 * fs), 0.032 * fs, name + "_heel", segs=10)
    toe = _prim_sphere((loc[0], loc[1] + 0.13 * fs, 0.020 * fs), 0.030 * fs, name + "_toe", segs=10)
    sole = _prim_sphere((loc[0], loc[1] + 0.05 * fs, 0.010), 0.022 * fs, name + "_sole", segs=10)
    return [body, heel, toe, sole]


def build_construction_volumes(fid: str, p: FighterProfile, arm_obj):
    r = recipe(fid)
    sx, _sy, sz = p.body_scale
    tw = p.torso_width
    lean = p.lean
    parts = []

    hips_h, hips_t = _bone_pts(arm_obj, "Hips")
    spine_h, spine_t = _bone_pts(arm_obj, "Spine")
    chest_h, chest_t = _bone_pts(arm_obj, "Chest")
    neck_h, neck_t = _bone_pts(arm_obj, "Neck")
    head_h, head_t = _bone_pts(arm_obj, "Head")

    def lean_y(z):
        return 0.04 * lean * (z / max(sz, 0.01))

    pelvis_r = 0.145 * tw * r.pelvis
    waist_r = 0.120 * tw * r.waist
    chest_rx = 0.175 * tw * r.chest
    neck_r = 0.058 * r.neck
    parts.extend(_capsule(hips_h, spine_h, pelvis_r, "pelvis"))
    parts.append(_prim_sphere((0.0, lean_y(hips_h.z), hips_h.z), pelvis_r * 1.05, "pelvis_ball"))
    parts.extend(_capsule(spine_h, chest_h, waist_r, "waist"))
    chest = _prim_sphere((0.0, 0.03 * lean + lean_y(chest_h.z), (chest_h.z + chest_t.z) * 0.5), chest_rx, "chest_ball")
    chest.scale = (1.25, 0.72, 1.08)
    _apply(chest)
    parts.append(chest)
    parts.extend(_capsule(chest_t, neck_t, neck_r, "neck"))
    parts += _head_volumes(fid, p, r, head_h, head_t, lean)

    for side, sgn in (("L", 1.0), ("R", -1.0)):
        sh_h, sh_t = _bone_pts(arm_obj, f"Shoulder_{side}")
        ua_h, ua_t = _bone_pts(arm_obj, f"UpperArm_{side}")
        la_h, la_t = _bone_pts(arm_obj, f"LowerArm_{side}")
        hd_h, hd_t = _bone_pts(arm_obj, f"Hand_{side}")
        ul_h, ul_t = _bone_pts(arm_obj, f"UpperLeg_{side}")
        ll_h, ll_t = _bone_pts(arm_obj, f"LowerLeg_{side}")
        ft_h, _ft_t = _bone_pts(arm_obj, f"Foot_{side}")

        shoulder_r = 0.085 * r.shoulder * (1.08 if side == "R" and fid == "rook-ironside" else 1.0)
        parts.append(_prim_sphere(sh_t, shoulder_r, f"shoulder_{side}"))
        parts.extend(_capsule(ua_h, ua_t, 0.058 * r.arm, f"upper_arm_{side}"))
        parts.append(_prim_sphere(ua_t, 0.052 * r.arm, f"elbow_{side}"))
        parts.extend(_capsule(la_h, la_t, 0.048 * r.forearm, f"forearm_{side}"))
        parts.append(_prim_sphere(la_t, 0.040 * r.forearm, f"wrist_{side}"))
        parts += _mitten((hd_h.x, hd_h.y, hd_h.z), sgn, p.hand_scale, f"hand_{side}")
        parts.append(_prim_sphere(hd_h, 0.038 * p.hand_scale, f"hand_join_{side}"))

        parts.extend(_capsule(ul_h, ul_t, 0.078 * tw * r.thigh, f"thigh_{side}"))
        parts.append(_prim_sphere(ul_t, 0.062 * r.thigh, f"knee_{side}"))
        parts.extend(_capsule(ll_h, ll_t, 0.052 * r.shin, f"shin_{side}"))
        parts.append(_prim_sphere(ll_t, 0.042 * r.shin, f"ankle_{side}"))
        parts += _boot((ft_h.x, ft_h.y, ft_h.z), p.foot_scale * min(r.boot_height, 1.06), f"foot_{side}")
        if r.gauntlet_scale > 1.05:
            parts.extend(_capsule(la_t, hd_t, 0.055 * r.gauntlet_scale, f"gauntlet_vol_{side}"))

    # Torso taper fill so chest/waist/pelvis cannot separate.
    parts.append(_prim_sphere((0.0, lean_y(1.12 * sz), 1.12 * sz), 0.13 * tw * r.waist, "torso_fill"))
    parts.append(_prim_sphere((0.18 * sx, lean_y(1.34 * sz), 1.34 * sz), 0.07 * r.shoulder, "clav_l"))
    parts.append(_prim_sphere((-0.18 * sx, lean_y(1.34 * sz), 1.34 * sz), 0.07 * r.shoulder, "clav_r"))
    return parts


def build_costume(fid: str, p: FighterProfile, arm_obj, mats: dict):
    r = recipe(fid)
    pieces = []
    records = []

    def add(obj, spec_name, mat_key="accent"):
        spec = next((s for s in r.accessories if s.name == spec_name), None)
        _assign(obj, mats.get(mat_key, mats["accent"]))
        pieces.append((obj, spec))
        return obj

    if fid == "ember-vale":
        _hr, ht = _bone_pts(arm_obj, "Hand_R")
        _hl, hlt = _bone_pts(arm_obj, "Hand_L")
        _ch, ct = _bone_pts(arm_obj, "Chest")
        add(_prim_sphere(ht, 0.055 * r.gauntlet_scale, "gauntlet_r"), "gauntlet_r", "accent")
        add(_prim_sphere(hlt, 0.048 * r.gauntlet_scale, "gauntlet_l"), "gauntlet_l", "accent")
        add(_prim_sphere((0.0, ct.y + 0.08, ct.z - 0.02), 0.055, "chest_vent"), "chest_vent", "accent")
        add(_prim_cone((ht.x + 0.03, ht.y + 0.03, ht.z + 0.03), 0.028, 0.005, 0.11, "flame_tongue_r"), "flame_tongue_r", "charged")
        add(_prim_cone((hlt.x - 0.03, hlt.y + 0.03, hlt.z + 0.03), 0.022, 0.004, 0.09, "flame_tongue_l"), "flame_tongue_l", "charged")
    elif fid == "rook-ironside":
        _ch, ct = _bone_pts(arm_obj, "Chest")
        _sl, slt = _bone_pts(arm_obj, "Shoulder_L")
        _sr, srt = _bone_pts(arm_obj, "Shoulder_R")
        add(_prim_sphere((0.0, ct.y + 0.09, ct.z - 0.02), 0.12, "chest_plate"), "chest_plate", "secondary")
        add(_prim_sphere(slt, 0.10, "shoulder_pad_l"), "shoulder_pad_l", "secondary")
        add(_prim_sphere(srt, 0.10, "shoulder_pad_r"), "shoulder_pad_r", "secondary")
        add(_prim_sphere((0.0, ct.y - 0.09, ct.z - 0.03), 0.09, "back_plate"), "back_plate", "secondary")
    elif fid == "juno-spark":
        _ch, ct = _bone_pts(arm_obj, "Chest")
        add(_prim_sphere((0.07, ct.y + 0.06, ct.z - 0.01), 0.045, "volt_panel_a"), "volt_panel_a", "accent")
        add(_prim_sphere((-0.06, ct.y + 0.01, ct.z - 0.06), 0.04, "volt_panel_b"), "volt_panel_b", "accent")
        add(_prim_sphere((0.06, ct.y + 0.08, ct.z + 0.02), 0.03, "volt_tag"), "volt_tag", "charged")
    elif fid == "kaia-windrow":
        _nh, nt = _bone_pts(arm_obj, "Neck")
        _hh, ht = _bone_pts(arm_obj, "Head")
        _ch, ct = _bone_pts(arm_obj, "Chest")
        add(_prim_sphere(nt, 0.05, "scarf"), "scarf", "accent")
        add(_prim_sphere(ht, 0.045, "ribbon"), "ribbon", "accent")
        add(_prim_sphere((0.0, ct.y - 0.08, ct.z), 0.06, "airfoil"), "airfoil", "accent")
    elif fid == "nix-calder":
        _ch, ct = _bone_pts(arm_obj, "Chest")
        _sl, slt = _bone_pts(arm_obj, "Shoulder_L")
        _hr, ht = _bone_pts(arm_obj, "Hand_R")
        _hl, hlt = _bone_pts(arm_obj, "Hand_L")
        add(_prim_ico((0.0, ct.y + 0.08, ct.z), 0.055, "crystal_core", 1), "crystal_core", "accent")
        add(_prim_ico((slt.x, slt.y + 0.03, slt.z + 0.02), 0.04, "crystal_shoulder", 1), "crystal_shoulder", "accent")
        add(_prim_sphere(ht, 0.045, "glove_plate_r"), "glove_plate_r", "accent")
        add(_prim_sphere(hlt, 0.045, "glove_plate_l"), "glove_plate_l", "accent")
    elif fid == "orion-vell":
        _ch, ct = _bone_pts(arm_obj, "Chest")
        add(_prim_sphere((0.0, ct.y + 0.03, ct.z - 0.03), 0.10, "vest_layer"), "vest_layer", "secondary")
        add(_prim_torus((0.0, 0.0, ct.z + 0.04), 0.22, 0.012, "orbit_ring"), "orbit_ring", "charged")
    elif fid == "vesper-nyx":
        hp, _ht = _bone_pts(arm_obj, "Hips")
        _ch, ct = _bone_pts(arm_obj, "Chest")
        add(_prim_sphere((0.08, hp.y - 0.05, hp.z + 0.06), 0.08, "coat_panel_l"), "coat_panel_l", "secondary")
        add(_prim_sphere((-0.06, hp.y - 0.04, hp.z + 0.05), 0.07, "coat_panel_r"), "coat_panel_r", "secondary")

    for obj, spec in pieces:
        if spec:
            records.append(
                {
                    "name": obj.name,
                    "classification": spec.classification,
                    "parent_bone": spec.parent_bone,
                    "intentional_float": spec.intentional_float,
                }
            )
    return pieces, records


def paint_regions(mesh_obj, arm_obj, mats: dict) -> None:
    mesh_obj.data.materials.clear()
    order = ["skin", "cloth", "secondary", "accent", "hair"]
    for key in order:
        mesh_obj.data.materials.append(mats[key])
    index = {k: i for i, k in enumerate(order)}
    bone_region = {
        "Head": "hair",
        "Neck": "skin",
        "Chest": "cloth",
        "Spine": "cloth",
        "Hips": "cloth",
        "Shoulder_L": "cloth",
        "Shoulder_R": "cloth",
        "UpperArm_L": "skin",
        "UpperArm_R": "skin",
        "LowerArm_L": "skin",
        "LowerArm_R": "skin",
        "Hand_L": "accent",
        "Hand_R": "accent",
        "UpperLeg_L": "secondary",
        "UpperLeg_R": "secondary",
        "LowerLeg_L": "secondary",
        "LowerLeg_R": "secondary",
        "Foot_L": "accent",
        "Foot_R": "accent",
        "Toes_L": "accent",
        "Toes_R": "accent",
    }
    bones = [b for b in arm_obj.data.bones if b.name in bone_region]
    tree = KDTree(len(bones))
    for i, bone in enumerate(bones):
        mid = arm_obj.matrix_world @ ((bone.head_local + bone.tail_local) * 0.5)
        tree.insert(mid, i)
    tree.balance()
    mw = mesh_obj.matrix_world
    for poly in mesh_obj.data.polygons:
        center = mw @ poly.center
        _co, idx, _dist = tree.find(center)
        poly.material_index = index[bone_region[bones[idx].name]]


def bind_smooth(mesh_obj, arm_obj) -> dict:
    bpy.ops.object.select_all(action="DESELECT")
    mesh_obj.select_set(True)
    arm_obj.select_set(True)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    zero = 0
    bad_sum = 0
    total = len(mesh_obj.data.vertices)
    for vert in mesh_obj.data.vertices:
        wsum = sum(group.weight for group in vert.groups)
        if wsum <= 1e-5:
            zero += 1
        if abs(wsum - 1.0) > 0.15 and wsum > 0:
            bad_sum += 1
    return {
        "vertex_count": total,
        "zero_weight_vertices": zero,
        "unnormalized_vertices": bad_sum,
        "smooth_skinning": zero == 0,
    }


def audit_accessories(arm_obj, piece_pairs) -> list[dict]:
    rows = []
    unintentional = 0
    for obj, spec in piece_pairs:
        if spec is None:
            continue
        bone = arm_obj.data.bones.get(spec.parent_bone)
        if bone is None:
            continue
        attach = arm_obj.matrix_world @ bone.tail_local
        dist = min((obj.matrix_world @ vert.co - attach).length for vert in obj.data.vertices)
        floating = (not spec.intentional_float) and dist > MAX_ATTACH_M
        if floating:
            unintentional += 1
        rows.append(
            {
                "name": obj.name,
                "classification": spec.classification,
                "parent_bone": spec.parent_bone,
                "distance_m": round(dist, 4),
                "intentional_float": spec.intentional_float,
                "unintentional_floating": floating,
            }
        )
    return rows, unintentional


def foot_ground_gap(mesh_obj) -> float:
    zs = [(mesh_obj.matrix_world @ v.co).z for v in mesh_obj.data.vertices]
    return abs(min(zs)) if zs else 99.0


def snap_to_ground(mesh_obj) -> float:
    mw = mesh_obj.matrix_world
    zs = [(mw @ v.co).z for v in mesh_obj.data.vertices]
    if not zs:
        return 99.0
    minz = min(zs)
    if minz >= -0.002:
        return abs(min(0.0, minz)) if minz < 0 else minz
    inv = mw.inverted()
    delta = inv.to_3x3() @ Vector((0.0, 0.0, -minz))
    for vert in mesh_obj.data.vertices:
        vert.co += delta
    mesh_obj.data.update()
    return foot_ground_gap(mesh_obj)


def build_cohesive_fighter(fid: str, p: FighterProfile, arm_obj):
    mats = {
        "skin": _toon_mat(f"{fid}.mat.skin", p.skin, 0.03, 0.0, 0.52),
        "cloth": _toon_mat(f"{fid}.mat.cloth", p.primary, 0.06, 0.04, 0.64),
        "secondary": _toon_mat(f"{fid}.mat.secondary", p.secondary, 0.03, 0.14, 0.70),
        "accent": _toon_mat(f"{fid}.mat.accent", p.accent, 0.42, 0.18, 0.38),
        "hair": _toon_mat(f"{fid}.mat.hair", p.hair, 0.10, 0.02, 0.48),
        "charged": _toon_mat(f"{fid}.mat.charged", p.charged, 0.70, 0.10, 0.32),
    }
    construction = build_construction_volumes(fid, p, arm_obj)
    body = _join(construction, f"{fid}.mesh")
    _voxel_remesh(body, 0.013)
    if len(body.data.vertices) < 200:
        _voxel_remesh(body, 0.010)
    _smooth_and_decimate(body, target_tris=24000)
    islands = _connected_components(body)
    if islands > 1:
        _voxel_remesh(body, 0.018)
        _smooth_and_decimate(body, target_tris=24000)
        islands = _connected_components(body)
    paint_regions(body, arm_obj, mats)
    snap_to_ground(body)
    weight_info = bind_smooth(body, arm_obj)
    costume_pairs, costume_meta = build_costume(fid, p, arm_obj, mats)
    costume_weight = []
    for obj, _spec in costume_pairs:
        costume_weight.append(bind_smooth(obj, arm_obj))
    accessory_rows, unintentional = audit_accessories(arm_obj, costume_pairs)
    tris = len(body.data.polygons)
    for obj, _spec in costume_pairs:
        tris += len(obj.data.polygons)
    report = {
        "fighter": fid,
        "generator_revision": "cohesive_body_v2_remesh",
        "body_connected_components": islands,
        "triangles": tris,
        "body_triangles": len(body.data.polygons),
        "material_count": len(body.data.materials) + len({obj.name for obj, _ in costume_pairs}),
        "foot_ground_gap_m": round(foot_ground_gap(body), 4),
        "weight": weight_info,
        "accessories": accessory_rows,
        "unintentional_floating_accessories": unintentional,
        "costume_meta": costume_meta,
    }
    return body, [obj for obj, _ in costume_pairs], report
