"""Anime/toon material stack. No flat clay look."""
from __future__ import annotations

import bpy

from generated_production_art.profiles import FighterProfile


def toon_mat(name, color, emit=0.05, bands=3, rim=0.32, metallic=0.04, rough=0.58, shadow_hue=None, slot="BODY"):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (760, 0)
    diffuse = nt.nodes.new("ShaderNodeBsdfDiffuse")
    diffuse.inputs["Color"].default_value = (color[0], color[1], color[2], 1.0)
    diffuse.inputs["Roughness"].default_value = rough
    to_rgb = nt.nodes.new("ShaderNodeShaderToRGB")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.interpolation = "CONSTANT"
    while len(ramp.color_ramp.elements) < bands:
        ramp.color_ramp.elements.new(0.5)
    stops = [0.14, 0.46, 0.78][:bands]
    hue = shadow_hue or (color[0] * 0.42, color[1] * 0.34, color[2] * 0.55)
    shades = [
        (hue[0] * 0.28, hue[1] * 0.26, hue[2] * 0.36, 1.0),
        (color[0] * 0.62, color[1] * 0.58, color[2] * 0.64, 1.0),
        (min(1.0, color[0] * 1.18), min(1.0, color[1] * 1.14), min(1.0, color[2] * 1.10), 1.0),
    ]
    for i, (pos, shade) in enumerate(zip(stops, shades)):
        ramp.color_ramp.elements[i].position = pos
        ramp.color_ramp.elements[i].color = shade
    emit_n = nt.nodes.new("ShaderNodeEmission")
    emit_n.inputs["Color"].default_value = (color[0], color[1], color[2], 1.0)
    emit_n.inputs["Strength"].default_value = emit
    add = nt.nodes.new("ShaderNodeAddShader")
    fresnel = nt.nodes.new("ShaderNodeFresnel")
    fresnel.inputs["IOR"].default_value = 1.48
    rim_n = nt.nodes.new("ShaderNodeEmission")
    rim_n.inputs["Color"].default_value = (
        min(1.0, color[0] * 1.40),
        min(1.0, color[1] * 1.40),
        min(1.0, color[2] * 1.40),
        1.0,
    )
    rim_n.inputs["Strength"].default_value = rim
    mix = nt.nodes.new("ShaderNodeMixShader")
    emission_from_ramp = nt.nodes.new("ShaderNodeEmission")
    emission_from_ramp.inputs["Strength"].default_value = 0.96
    nt.links.new(diffuse.outputs["BSDF"], to_rgb.inputs["Shader"])
    nt.links.new(to_rgb.outputs["Color"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], emission_from_ramp.inputs["Color"])
    nt.links.new(emission_from_ramp.outputs["Emission"], add.inputs[0])
    nt.links.new(emit_n.outputs["Emission"], add.inputs[1])
    nt.links.new(fresnel.outputs["Fac"], mix.inputs["Fac"])
    nt.links.new(add.outputs["Shader"], mix.inputs[1])
    nt.links.new(rim_n.outputs["Emission"], mix.inputs[2])
    nt.links.new(mix.outputs["Shader"], out.inputs["Surface"])
    mat.diffuse_color = (color[0], color[1], color[2], 1.0)
    mat["aa_toon_bands"] = bands
    mat["aa_slot"] = slot
    mat["aa_charge_ready"] = 1
    return mat


def build_materials(fid: str, p: FighterProfile) -> dict:
    return {
        "body": toon_mat(f"{fid}.mat.BODY", p.skin, 0.01, 3, 0.10, 0.0, 0.64, shadow_hue=(0.26, 0.14, 0.20), slot="BODY"),
        "cloth": toon_mat(f"{fid}.mat.BASE_CLOTH", p.primary, 0.04, 3, 0.22, 0.02, 0.56, shadow_hue=p.secondary, slot="BASE_CLOTH"),
        "secondary": toon_mat(f"{fid}.mat.SECONDARY_CLOTH", p.secondary, 0.03, 3, 0.18, 0.22, 0.40, slot="SECONDARY_CLOTH"),
        "armor": toon_mat(f"{fid}.mat.ARMOR", p.secondary, 0.04, 3, 0.20, 0.42, 0.28, slot="ARMOR"),
        "accent": toon_mat(f"{fid}.mat.ACCENT", p.accent, 0.16, 2, 0.26, 0.30, 0.30, slot="ACCENT"),
        "emit": toon_mat(f"{fid}.mat.EMISSION", p.charged, 0.42, 2, 0.18, 0.08, 0.22, slot="EMISSION"),
        "hair": toon_mat(f"{fid}.mat.HAIR_HEAD", p.hair, 0.06, 3, 0.20, 0.02, 0.44, slot="HAIR/HEAD"),
        "void": toon_mat(f"{fid}.mat.VOID_ENERGY", p.outline, 0.08, 2, 0.12, 0.05, 0.70, slot="VOID/ENERGY"),
    }


def assign(obj, mat):
    if not obj.data.materials:
        obj.data.materials.append(mat)
    else:
        obj.data.materials[0] = mat


def paint_body_regions(mesh_obj, arm_obj, mats: dict) -> None:
    """Body mesh is lofted skin; costume shells carry cloth/armor. Skin stays on body only."""
    mesh_obj.data.materials.clear()
    order = ["body", "cloth", "secondary", "accent", "hair"]
    for key in order:
        mesh_obj.data.materials.append(mats[key])
    index = {k: i for i, k in enumerate(order)}
    from mathutils.kdtree import KDTree

    bone_region = {
        "Head": "hair",
        "Neck": "body",
        "Chest": "body",
        "Spine": "body",
        "Hips": "body",
        "Shoulder_L": "body",
        "Shoulder_R": "body",
        "UpperArm_L": "body",
        "UpperArm_R": "body",
        "LowerArm_L": "body",
        "LowerArm_R": "body",
        "Hand_L": "accent",
        "Hand_R": "accent",
        "UpperLeg_L": "body",
        "UpperLeg_R": "body",
        "LowerLeg_L": "body",
        "LowerLeg_R": "body",
        "Foot_L": "accent",
        "Foot_R": "accent",
    }
    bones = [b for b in arm_obj.data.bones if b.name in bone_region]
    tree = KDTree(len(bones))
    for i, bone in enumerate(bones):
        mid = arm_obj.matrix_world @ ((bone.head_local + bone.tail_local) * 0.5)
        tree.insert(mid, i)
    tree.balance()
    mw = mesh_obj.matrix_world
    neck_h = arm_obj.matrix_world @ arm_obj.data.bones["Neck"].head_local
    for poly in mesh_obj.data.polygons:
        center = mw @ poly.center
        _co, idx, _dist = tree.find(center)
        key = bone_region[bones[idx].name]
        if center.z >= neck_h.z + 0.04:
            key = "hair"
        poly.material_index = index[key]
    mesh_obj.data.update()
