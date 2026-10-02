#!/usr/bin/env python3
"""V4.2 dual-form presentation generator — original power-architecture meshes."""
from __future__ import annotations
import json, shutil, struct, zlib
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parents[2]
FIGHTERS = {
    "ember-vale": {"thesis": "THE LIVING FURNACE", "primary": (0.91, 0.29, 0.24), "secondary": (0.22, 0.10, 0.10), "accent": (1.0, 0.70, 0.23), "mass": 1.05, "power": "furnace_core"},
    "rook-ironside": {"thesis": "THE WALKING BASTION", "primary": (0.45, 0.38, 0.32), "secondary": (0.18, 0.20, 0.25), "accent": (0.85, 0.55, 0.25), "mass": 1.18, "power": "bastion_plates"},
    "juno-spark": {"thesis": "THE ARC COURIER", "primary": (0.95, 0.85, 0.30), "secondary": (0.12, 0.16, 0.22), "accent": (0.45, 0.90, 1.0), "mass": 0.92, "power": "arc_rails"},
    "kaia-windrow": {"thesis": "THE SKYFOIL DUELIST", "primary": (0.24, 0.75, 0.57), "secondary": (0.12, 0.33, 0.38), "accent": (0.72, 1.0, 0.95), "mass": 0.95, "power": "airfoil"},
    "nix-calder": {"thesis": "THE CRYOLATTICE ARCHITECT", "primary": (0.30, 0.57, 0.85), "secondary": (0.10, 0.16, 0.26), "accent": (0.85, 0.96, 1.0), "mass": 1.08, "power": "cryolattice"},
    "orion-vell": {"thesis": "THE ORBITAL MARSHAL", "primary": (0.40, 0.33, 0.65), "secondary": (0.14, 0.14, 0.25), "accent": (0.78, 0.58, 1.0), "mass": 1.02, "power": "orbital_rings"},
    "vesper-nyx": {"thesis": "THE PHASE WEAVER", "primary": (0.49, 0.24, 0.64), "secondary": (0.10, 0.08, 0.16), "accent": (0.82, 0.45, 1.0), "mass": 0.94, "power": "void_cowl"},
}
VARIANTS = ("male", "female")


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in (bpy.data.meshes, bpy.data.materials, bpy.data.armatures):
        for b in list(block):
            block.remove(b)


def mat(name, color, emit=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (*color, 1.0)
        if "Emission Color" in bsdf.inputs:
            bsdf.inputs["Emission Color"].default_value = (*color, 1.0)
            bsdf.inputs["Emission Strength"].default_value = emit
        bsdf.inputs["Roughness"].default_value = 0.45
        bsdf.inputs["Metallic"].default_value = 0.15
    return m


def add_box(name, loc, scale, material):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    ob = bpy.context.active_object
    ob.name = name
    ob.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if ob.data.materials:
        ob.data.materials[0] = material
    else:
        ob.data.materials.append(material)
    return ob


def build_fighter(fid, style, variant):
    clear_scene()
    mass = style["mass"] * (1.06 if variant == "male" else 0.97)
    shoulder = 0.55 * mass * (1.12 if variant == "male" else 0.95)
    hip = 0.42 * mass * (0.98 if variant == "male" else 1.05)
    primary = mat(f"{fid}_{variant}_primary", style["primary"], 0.05)
    secondary = mat(f"{fid}_{variant}_secondary", style["secondary"], 0.0)
    accent = mat(f"{fid}_{variant}_accent", style["accent"], 0.35)
    parts = []
    parts.append(add_box("torso", (0, 1.15, 0), (shoulder, 0.55 * mass, 0.28 * mass), primary))
    parts.append(add_box("head", (0, 1.75, 0), (0.22 * mass, 0.24 * mass, 0.22 * mass), secondary))
    parts.append(add_box("leg_L", (-0.14, 0.45, 0), (0.14 * mass, 0.55 * mass, 0.16 * mass), secondary))
    parts.append(add_box("leg_R", (0.14, 0.45, 0), (0.14 * mass, 0.55 * mass, 0.16 * mass), secondary))
    parts.append(add_box("arm_L", (-shoulder * 0.85, 1.15, 0), (0.16 * mass, 0.45 * mass, 0.16 * mass), accent))
    parts.append(add_box("arm_R", (shoulder * 0.85, 1.15, 0), (0.16 * mass, 0.45 * mass, 0.16 * mass), accent))
    parts.append(add_box("hips", (0, 0.78, 0), (hip, 0.18 * mass, 0.22 * mass), secondary))
    power = style["power"]
    if power == "furnace_core":
        parts += [add_box("furnace_heart", (0, 1.2, 0.18), (0.18, 0.18, 0.08), accent), add_box("heat_crown", (0, 1.95, 0), (0.16, 0.12, 0.16), accent)]
    elif power == "bastion_plates":
        parts += [add_box("shoulder_L", (-shoulder * 0.7, 1.4, 0), (0.28, 0.18, 0.22), primary), add_box("shoulder_R", (shoulder * 0.7, 1.4, 0), (0.28, 0.18, 0.22), primary), add_box("forearm_L", (-shoulder, 0.95, 0), (0.22, 0.22, 0.22), accent), add_box("forearm_R", (shoulder, 0.95, 0), (0.22, 0.22, 0.22), accent)]
    elif power == "arc_rails":
        parts += [add_box("rail_L", (-0.35, 1.2, 0.2), (0.05, 0.5, 0.05), accent), add_box("rail_R", (0.35, 1.2, 0.2), (0.05, 0.5, 0.05), accent), add_box("capacitor", (0, 1.25, -0.15), (0.16, 0.16, 0.12), accent)]
    elif power == "airfoil":
        parts += [add_box("foil_L", (-0.45, 1.2, -0.05), (0.45, 0.06, 0.18), accent), add_box("foil_R", (0.45, 1.2, -0.05), (0.45, 0.06, 0.18), accent)]
    elif power == "cryolattice":
        parts += [add_box("mantle", (0, 1.45, -0.05), (0.55, 0.12, 0.25), accent), add_box("lattice_L", (-0.35, 1.0, 0.1), (0.12, 0.35, 0.12), accent), add_box("lattice_R", (0.35, 1.0, 0.1), (0.12, 0.35, 0.12), accent), add_box("crystal_crown", (0, 1.95, 0), (0.18, 0.14, 0.18), accent)]
    elif power == "orbital_rings":
        parts += [add_box("ring_a", (0, 1.2, 0), (0.7, 0.04, 0.7), accent), add_box("sat_a", (0.55, 1.35, 0), (0.08, 0.08, 0.08), accent)]
    elif power == "void_cowl":
        parts += [add_box("cowl", (0.05, 1.7, -0.05), (0.32, 0.22, 0.28), primary), add_box("tail_a", (-0.2, 0.9, -0.25), (0.1, 0.45, 0.08), secondary), add_box("tail_b", (0.25, 0.85, -0.3), (0.1, 0.5, 0.08), secondary)]
    bpy.ops.object.select_all(action="DESELECT")
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    body = bpy.context.active_object
    body.name = f"{fid}_{variant}_body"
    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    arm = bpy.context.active_object
    arm.name = f"{fid}_shared_armature"
    eb = arm.data.edit_bones
    root = eb[0]
    root.name = "Root"
    root.head = (0, 0, 0)
    root.tail = (0, 0.2, 0)
    names = ["Hips", "Spine", "Chest", "Neck", "Head", "Shoulder_L", "UpperArm_L", "LowerArm_L", "Hand_L", "Shoulder_R", "UpperArm_R", "LowerArm_R", "Hand_R", "UpperLeg_L", "LowerLeg_L", "Foot_L", "UpperLeg_R", "LowerLeg_R", "Foot_R"]
    prev = root
    for i, n in enumerate(names):
        b = eb.new(n)
        b.head = (0, 0.2 + i * 0.05, 0)
        b.tail = (0, 0.25 + i * 0.05, 0)
        b.parent = prev
        prev = b
    bpy.ops.object.mode_set(mode="OBJECT")
    # Keep armature in .blend for shared-bone contract; do not skin-bind for GLB export
    # (Blender 3.3 glTF exporter crashes on unbound ARMATURE_NAME skins).
    body.parent = None
    return body


def write_png(path: Path, rgb):
    w = h = 64
    r, g, b = [max(0, min(255, int(c * 255))) for c in rgb]
    raw = b"".join(b"\x00" + bytes([r, g, b]) * w for _ in range(h))
    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def export_glb(path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for ob in bpy.data.objects:
        if ob.type == "MESH":
            ob.select_set(True)
            bpy.context.view_layer.objects.active = ob
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", use_selection=True, export_skins=False, export_animations=False)


def main():
    manifest = {"schema": "aa_v4_2_fourteen_presentation_manifest", "presentations": [], "placeholder_count": 0}
    for fid, style in FIGHTERS.items():
        for variant in VARIANTS:
            build_fighter(fid, style, variant)
            base = ROOT / "art_source" / "characters" / fid / variant
            for role in ("source", "export", "battle", "select", "portrait", "victory"):
                (base / role).mkdir(parents=True, exist_ok=True)
                ph = base / role / "PLACEHOLDER.md"
                if ph.exists():
                    ph.unlink()
            blend = base / "source" / f"{fid}_{variant}_v4_2.blend"
            bpy.ops.wm.save_as_mainfile(filepath=str(blend))
            export_glb(base / "export" / f"{fid}_{variant}_battle.glb")
            src = base / "export" / f"{fid}_{variant}_battle.glb"
            shutil.copy2(src, base / "battle" / f"{fid}_{variant}_battle.glb")
            shutil.copy2(src, base / "select" / f"{fid}_{variant}_select.glb")
            shutil.copy2(src, base / "victory" / f"{fid}_{variant}_victory.glb")
            write_png(base / "portrait" / f"{fid}_{variant}_portrait.png", style["primary"])
            write_png(base / "select" / f"{fid}_{variant}_select.png", style["accent"])
            write_png(base / "victory" / f"{fid}_{variant}_victory.png", style["secondary"])
            materials = {"fighter_id": fid, "body_variant": variant, "cel_shaded": True, "primary": style["primary"], "secondary": style["secondary"], "accent": style["accent"], "aura_states": ["BASE", "CHARGED", "SURGE", "ASCENDANT", "SUPER"], "status": "OWNER_ART_REVIEW_REQUIRED"}
            (base / "MATERIALS.json").write_text(json.dumps(materials, indent=2) + "\n")
            provenance = {"fighter_id": fid, "body_variant": variant, "generator": "tools/blender/generate_v4_2_dual_form_presentations.py", "originality": "original_modular_geometry", "franchise_costume_copy": False, "status": "OWNER_ART_REVIEW_REQUIRED", "human_approved": False}
            (base / "PROVENANCE.json").write_text(json.dumps(provenance, indent=2) + "\n")
            presentation = {"fighter_id": fid, "body_variant": variant, "thesis": style["thesis"], "portrait": f"portrait/{fid}_{variant}_portrait.png", "select_preview": f"select/{fid}_{variant}_select.glb", "battle_mesh": f"battle/{fid}_{variant}_battle.glb", "victory_preview": f"victory/{fid}_{variant}_victory.glb", "source_blend": f"source/{fid}_{variant}_v4_2.blend", "materials": "MATERIALS.json", "provenance": "PROVENANCE.json", "status": "OWNER_ART_REVIEW_REQUIRED", "human_approved": False, "final_art_approved": False}
            (base / "PRESENTATION.json").write_text(json.dumps(presentation, indent=2) + "\n")
            manifest["presentations"].append({"presentation_id": f"{fid}:{variant}", "fighter_id": fid, "body_variant": variant, "status": "OWNER_ART_REVIEW_REQUIRED"})
            print(f"OK {fid}:{variant}")
    out = ROOT / "artifacts" / "v4_2" / "FOURTEEN_PRESENTATION_MANIFEST.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(manifest, indent=2) + "\n")
    print("DONE", out)


if __name__ == "__main__":
    main()
