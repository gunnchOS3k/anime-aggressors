"""v6 cel materials: 2–3 hard bands, undersuit never peach, armor/cloth split."""
from __future__ import annotations

from pathlib import Path

import bpy

from generated_art_v6.body_profiles import PALETTE_PATH, load_palettes


def _rgb(color) -> tuple[float, float, float]:
    return (float(color[0]), float(color[1]), float(color[2]))


def cel_mat(name, color, emit=0.04, bands=3, rim=0.28, slot="UNDERSUIT", shadow=None, metallic=0.0):
    color = _rgb(color)
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (640, 0)
    geo = nt.nodes.new("ShaderNodeNewGeometry")
    geo.location = (-520, 80)
    light = nt.nodes.new("ShaderNodeVectorMath")
    light.operation = "DOT_PRODUCT"
    light.location = (-280, 80)
    light.inputs[1].default_value = (-0.25, 0.55, 0.80)
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.location = (-40, 80)
    ramp.color_ramp.interpolation = "CONSTANT"
    while len(ramp.color_ramp.elements) < bands:
        ramp.color_ramp.elements.new(0.5)
    shade = shadow or (color[0] * 0.38, color[1] * 0.34, color[2] * 0.42)
    mid = (color[0] * 0.78, color[1] * 0.76, color[2] * 0.80)
    hi = (min(1.0, color[0] * 1.12), min(1.0, color[1] * 1.10), min(1.0, color[2] * 1.08))
    stops = [0.22, 0.55, 0.82][:bands]
    shades = [(*shade, 1.0), (*mid, 1.0), (*hi, 1.0)]
    for i, (pos, val) in enumerate(zip(stops, shades)):
        ramp.color_ramp.elements[i].position = pos
        ramp.color_ramp.elements[i].color = val
    band_emit = nt.nodes.new("ShaderNodeEmission")
    band_emit.location = (260, 80)
    band_emit.inputs["Strength"].default_value = 0.92 + emit
    fresnel = nt.nodes.new("ShaderNodeFresnel")
    fresnel.inputs["IOR"].default_value = 1.35
    rim_n = nt.nodes.new("ShaderNodeEmission")
    rim_n.inputs["Color"].default_value = (
        min(1.0, color[0] * 1.25 + 0.04),
        min(1.0, color[1] * 1.25 + 0.04),
        min(1.0, color[2] * 1.25 + 0.04),
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
    mat["aa_metallic_hint"] = metallic
    return mat


def outline_mat(name="AA_Outline"):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    emit = nt.nodes.new("ShaderNodeEmission")
    emit.inputs["Color"].default_value = (0.04, 0.03, 0.05, 1.0)
    emit.inputs["Strength"].default_value = 0.85
    nt.links.new(emit.outputs["Emission"], out.inputs["Surface"])
    mat.diffuse_color = (0.04, 0.03, 0.05, 1.0)
    mat["aa_outline"] = 1
    try:
        mat.use_backface_culling = True
    except Exception:
        pass
    return mat


def build_materials(fid: str) -> dict:
    palettes = load_palettes()
    pal = palettes[fid]
    return {
        "undersuit": hard_emit(f"{fid}.mat.UNDERSUIT", pal["undersuit"]),
        "body": hard_emit(f"{fid}.mat.UNDERSUIT_BODY", pal["undersuit"]),
        "cloth": cel_mat(f"{fid}.mat.CLOTH", pal["undersuit"], 0.02, 3, 0.16, "CLOTH"),
        "armor": cel_mat(f"{fid}.mat.ARMOR", pal["armor"], 0.04, 3, 0.22, "ARMOR", metallic=0.35),
        "secondary": cel_mat(f"{fid}.mat.SECONDARY", pal["glove"], 0.03, 3, 0.18, "SECONDARY"),
        "accent": cel_mat(f"{fid}.mat.ACCENT", pal["accent"], 0.14, 2, 0.24, "ACCENT"),
        "emit": cel_mat(f"{fid}.mat.EMISSION", pal["emission"], 0.38, 2, 0.16, "EMISSION"),
        "mask": cel_mat(f"{fid}.mat.MASK", pal["mask"], 0.05, 3, 0.20, "MASK"),
        "glove": cel_mat(f"{fid}.mat.GLOVE", pal["glove"], 0.05, 3, 0.18, "GLOVE"),
        "boot": cel_mat(f"{fid}.mat.BOOT", pal["boot"], 0.03, 3, 0.16, "BOOT"),
        "void": cel_mat(f"{fid}.mat.VOID", pal["undersuit"], 0.06, 2, 0.12, "VOID"),
        "hair": cel_mat(f"{fid}.mat.MASK_HAIR", pal["mask"], 0.04, 3, 0.16, "MASK"),
        "outline": outline_mat(f"{fid}.mat.OUTLINE"),
    }


def assign(obj, mat):
    if not obj.data.materials:
        obj.data.materials.append(mat)
    else:
        obj.data.materials[0] = mat


def hard_emit(name, color):
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
    mat["aa_slot"] = "UNDERSUIT"
    mat["aa_cel"] = 1
    return mat


def paint_undersuit(mesh_obj, mats: dict) -> None:
    """Entire loft body reads as undersuit. Peach/skin is forbidden."""
    mesh_obj.data.materials.clear()
    mesh_obj.data.materials.append(mats["undersuit"])
    for poly in mesh_obj.data.polygons:
        poly.material_index = 0
    mesh_obj.data.update()
    if mesh_obj.data.materials:
        mesh_obj.active_material = mats["undersuit"]
    mesh_obj["aa_undersuit"] = 1
    mesh_obj["aa_no_skin"] = 1


def palette_has_three_groups(fid: str) -> bool:
    pal = load_palettes()[fid]
    groups = pal.get("value_groups") or []
    return len(groups) >= 3


def palette_source_sha() -> str:
    return Path(PALETTE_PATH).read_text(encoding="utf-8")
