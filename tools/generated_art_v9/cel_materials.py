"""v8 cel materials. Same shader, stronger midtone contrast. No emission-dependent split."""
from __future__ import annotations

import bpy

from generated_art_v9.body_profiles import load_palettes


def _rgb(color) -> tuple[float, float, float]:
    return (float(color[0]), float(color[1]), float(color[2]))


def apply_review_color_management(scene=None) -> None:
    scene = scene or bpy.context.scene
    view = scene.view_settings
    view.view_transform = "Standard"
    view.look = "None"
    view.exposure = 0.0
    view.gamma = 1.0
    if hasattr(scene, "eevee"):
        scene.eevee.use_bloom = False


def hard_emit(name, color, slot="UNDERSUIT"):
    color = _rgb(color)
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    emit = nt.nodes.new("ShaderNodeEmission")
    emit.inputs["Color"].default_value = (color[0], color[1], color[2], 1.0)
    emit.inputs["Strength"].default_value = 1.0
    nt.links.new(emit.outputs["Emission"], out.inputs["Surface"])
    mat.diffuse_color = (color[0], color[1], color[2], 1.0)
    mat["aa_slot"] = slot
    mat["aa_cel"] = 1
    mat["aa_hard_value"] = 1
    return mat


def cel_mat(name, color, emit=0.02, bands=3, rim=0.16, slot="ARMOR", shadow=None):
    color = _rgb(color)
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (640, 0)
    geo = nt.nodes.new("ShaderNodeNewGeometry")
    light = nt.nodes.new("ShaderNodeVectorMath")
    light.operation = "DOT_PRODUCT"
    light.inputs[1].default_value = (-0.22, 0.58, 0.76)
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.interpolation = "CONSTANT"
    while len(ramp.color_ramp.elements) < bands:
        ramp.color_ramp.elements.new(0.5)
    shade = shadow or (color[0] * 0.34, color[1] * 0.30, color[2] * 0.36)
    mid = (color[0] * 0.92, color[1] * 0.90, color[2] * 0.94)
    hi = (min(1.0, color[0] * 1.10), min(1.0, color[1] * 1.08), min(1.0, color[2] * 1.06))
    for i, (pos, val) in enumerate(zip([0.18, 0.50, 0.78][:bands], [(*shade, 1.0), (*mid, 1.0), (*hi, 1.0)])):
        ramp.color_ramp.elements[i].position = pos
        ramp.color_ramp.elements[i].color = val
    band_emit = nt.nodes.new("ShaderNodeEmission")
    band_emit.inputs["Strength"].default_value = 0.96 + emit
    fresnel = nt.nodes.new("ShaderNodeFresnel")
    fresnel.inputs["IOR"].default_value = 1.28
    rim_n = nt.nodes.new("ShaderNodeEmission")
    rim_n.inputs["Color"].default_value = (
        min(1.0, color[0] * 1.18 + 0.03),
        min(1.0, color[1] * 1.18 + 0.03),
        min(1.0, color[2] * 1.18 + 0.03),
        1.0,
    )
    rim_n.inputs["Strength"].default_value = rim
    mix = nt.nodes.new("ShaderNodeMixShader")
    nt.links.new(geo.outputs["Normal"], light.inputs[0])
    nt.links.new(light.outputs["Value"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], band_emit.inputs["Color"])
    nt.links.new(fresnel.outputs["Fac"], mix.inputs["Fac"])
    nt.links.new(band_emit.outputs["Emission"], mix.inputs[1])
    nt.links.new(rim_n.outputs["Emission"], mix.inputs[2])
    nt.links.new(mix.outputs["Shader"], out.inputs["Surface"])
    mat.diffuse_color = (color[0], color[1], color[2], 1.0)
    mat["aa_toon_bands"] = bands
    mat["aa_slot"] = slot
    mat["aa_cel"] = 1
    return mat


def outline_mat(name="AA_Outline"):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    emit = nt.nodes.new("ShaderNodeEmission")
    emit.inputs["Color"].default_value = (0.03, 0.02, 0.04, 1.0)
    emit.inputs["Strength"].default_value = 0.85
    nt.links.new(emit.outputs["Emission"], out.inputs["Surface"])
    mat.diffuse_color = (0.03, 0.02, 0.04, 1.0)
    mat["aa_outline"] = 1
    try:
        mat.use_backface_culling = True
    except Exception:
        pass
    return mat


def build_materials(fid: str) -> dict:
    pal = load_palettes()[fid]
    secondary = pal.get("secondary") or pal["glove"]
    return {
        "undersuit": hard_emit(f"{fid}.mat.UNDERSUIT", pal["undersuit"], "UNDERSUIT"),
        "body": hard_emit(f"{fid}.mat.UNDERSUIT_BODY", pal["undersuit"], "UNDERSUIT"),
        "cloth": cel_mat(f"{fid}.mat.CLOTH", pal["undersuit"], 0.01, 3, 0.10, "CLOTH"),
        "armor": cel_mat(f"{fid}.mat.ARMOR", pal["armor"], 0.02, 3, 0.14, "ARMOR"),
        "secondary": cel_mat(f"{fid}.mat.SECONDARY", secondary, 0.02, 3, 0.12, "SECONDARY"),
        "accent": cel_mat(f"{fid}.mat.ACCENT", pal["accent"], 0.08, 2, 0.16, "ACCENT"),
        "pale": hard_emit(f"{fid}.mat.PALE", pal["accent"] if fid != "nix-calder" else pal["armor"], "ARMOR"),
        "emit": cel_mat(f"{fid}.mat.EMISSION", pal["emission"], 0.22, 2, 0.10, "EMISSION"),
        "mask": hard_emit(f"{fid}.mat.MASK", pal["mask"], "MASK") if fid == "nix-calder" else cel_mat(f"{fid}.mat.MASK", pal["mask"], 0.03, 3, 0.14, "MASK"),
        "glove": cel_mat(f"{fid}.mat.GLOVE", pal["glove"], 0.03, 3, 0.12, "GLOVE"),
        "boot": cel_mat(f"{fid}.mat.BOOT", pal["boot"], 0.02, 3, 0.10, "BOOT"),
        "void": cel_mat(f"{fid}.mat.VOID", pal["undersuit"], 0.04, 2, 0.08, "VOID"),
        "hair": cel_mat(f"{fid}.mat.MASK_HAIR", pal["mask"], 0.02, 3, 0.10, "MASK"),
        "outline": outline_mat(f"{fid}.mat.OUTLINE"),
    }


def assign(obj, mat):
    if not obj.data.materials:
        obj.data.materials.append(mat)
    else:
        obj.data.materials[0] = mat


def paint_undersuit(mesh_obj, mats: dict) -> None:
    mesh_obj.data.materials.clear()
    mesh_obj.data.materials.append(mats["undersuit"])
    for poly in mesh_obj.data.polygons:
        poly.material_index = 0
    mesh_obj.data.update()
    mesh_obj.active_material = mats["undersuit"]
    mesh_obj["aa_undersuit"] = 1
    mesh_obj["aa_no_skin"] = 1


def mute_emission(enable: bool, cache: dict) -> None:
    if enable:
        cache.clear()
        for mat in bpy.data.materials:
            if mat.get("aa_slot") != "EMISSION" or not mat.use_nodes:
                continue
            for node in mat.node_tree.nodes:
                if node.type == "EMISSION" and "Strength" in node.inputs:
                    cache.setdefault(mat.name, []).append((node, node.inputs["Strength"].default_value))
                    node.inputs["Strength"].default_value = 0.0
    else:
        for mat in bpy.data.materials:
            for node, strength in cache.get(mat.name, []):
                if "Strength" in node.inputs:
                    node.inputs["Strength"].default_value = strength
