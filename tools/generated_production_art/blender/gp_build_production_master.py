"""Build one generated production master per fighter and export the runtime GLB."""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(HERE.parent.parent))

from generated_production_art.action_catalog import all_actions, duration_for  # noqa: E402
from generated_production_art.common import (  # noqa: E402
    CANONICAL_BONES,
    GENERATOR,
    GENERATOR_VERSION,
    generated_model_glb,
    production_master_blend,
)
from generated_production_art.pose_library import locations_for, phase_times, poses_for_action  # noqa: E402
from generated_production_art.profiles import profile  # noqa: E402

PARENT = {
    "Root": None,
    "Hips": "Root",
    "Spine": "Hips",
    "Chest": "Spine",
    "Neck": "Chest",
    "Head": "Neck",
    "Shoulder_L": "Chest",
    "UpperArm_L": "Shoulder_L",
    "LowerArm_L": "UpperArm_L",
    "Hand_L": "LowerArm_L",
    "Shoulder_R": "Chest",
    "UpperArm_R": "Shoulder_R",
    "LowerArm_R": "UpperArm_R",
    "Hand_R": "LowerArm_R",
    "UpperLeg_L": "Hips",
    "LowerLeg_L": "UpperLeg_L",
    "Foot_L": "LowerLeg_L",
    "Toes_L": "Foot_L",
    "UpperLeg_R": "Hips",
    "LowerLeg_R": "UpperLeg_R",
    "Foot_R": "LowerLeg_R",
    "Toes_R": "Foot_R",
}

REST = {
    "Root": ((0.0, 0.0, 0.0), (0.0, 0.0, 0.08)),
    "Hips": ((0.0, 0.0, 0.92), (0.0, 0.0, 1.02)),
    "Spine": ((0.0, 0.0, 1.02), (0.0, 0.0, 1.18)),
    "Chest": ((0.0, 0.0, 1.18), (0.0, 0.0, 1.38)),
    "Neck": ((0.0, 0.0, 1.38), (0.0, 0.0, 1.50)),
    "Head": ((0.0, 0.0, 1.50), (0.0, 0.0, 1.72)),
    "Shoulder_L": ((0.06, 0.0, 1.36), (0.16, 0.0, 1.36)),
    "UpperArm_L": ((0.16, 0.0, 1.36), (0.38, 0.0, 1.12)),
    "LowerArm_L": ((0.38, 0.0, 1.12), (0.54, 0.0, 0.94)),
    "Hand_L": ((0.54, 0.0, 0.94), (0.68, 0.0, 0.90)),
    "Shoulder_R": ((-0.06, 0.0, 1.36), (-0.16, 0.0, 1.36)),
    "UpperArm_R": ((-0.16, 0.0, 1.36), (-0.38, 0.0, 1.12)),
    "LowerArm_R": ((-0.38, 0.0, 1.12), (-0.54, 0.0, 0.94)),
    "Hand_R": ((-0.54, 0.0, 0.94), (-0.68, 0.0, 0.90)),
    "UpperLeg_L": ((0.10, 0.0, 0.92), (0.10, 0.0, 0.50)),
    "LowerLeg_L": ((0.10, 0.0, 0.50), (0.10, 0.0, 0.12)),
    "Foot_L": ((0.10, 0.0, 0.12), (0.10, 0.14, 0.04)),
    "Toes_L": ((0.10, 0.14, 0.04), (0.10, 0.22, 0.04)),
    "UpperLeg_R": ((-0.10, 0.0, 0.92), (-0.10, 0.0, 0.50)),
    "LowerLeg_R": ((-0.10, 0.0, 0.50), (-0.10, 0.0, 0.12)),
    "Foot_R": ((-0.10, 0.0, 0.12), (-0.10, 0.14, 0.04)),
    "Toes_R": ((-0.10, 0.14, 0.04), (-0.10, 0.22, 0.04)),
}

ACCESSORIES = {
    "ember-vale": (("Cloth_Flame_R", "Hand_R", (0.08, 0.0, 0.0)), ("Cloth_Flame_L", "Hand_L", (-0.08, 0.0, 0.0))),
    "rook-ironside": (("Cloth_ArmorFlap", "Chest", (0.0, -0.12, -0.08)),),
    "juno-spark": (("Cloth_VoltTag", "Chest", (0.10, 0.08, 0.04)),),
    "kaia-windrow": (("Cloth_Scarf", "Neck", (0.0, -0.18, 0.02)), ("Hair_Ribbon", "Head", (0.0, -0.16, 0.08))),
    "nix-calder": (("Cloth_Crystal", "Chest", (0.0, 0.10, 0.06)),),
    "orion-vell": (("Cloth_Orbit", "Chest", (0.0, 0.0, 0.16)),),
    "vesper-nyx": (("Coat_Panel_L", "Chest", (0.16, -0.18, -0.04)), ("Coat_Panel_R", "Chest", (-0.10, -0.12, -0.02))),
}


def _argv() -> list[str]:
    if "--" in sys.argv:
        return sys.argv[sys.argv.index("--") + 1 :]
    return sys.argv[1:]


def _parse() -> dict:
    args = _argv()
    out = {"fighter": "ember-vale", "out_blend": "", "out_glb": "", "report": "", "skip_anim": "0"}
    i = 0
    while i < len(args):
        if args[i].startswith("--") and i + 1 < len(args) and not args[i + 1].startswith("--"):
            out[args[i][2:].replace("-", "_")] = args[i + 1]
            i += 2
        else:
            i += 1
    return out


def _collection(name: str):
    col = bpy.data.collections.get(name) or bpy.data.collections.new(name)
    if col.name not in bpy.context.scene.collection.children:
        bpy.context.scene.collection.children.link(col)
    return col


def _link(col, obj) -> None:
    if obj.name not in col.objects:
        col.objects.link(obj)
    if obj.name in bpy.context.scene.collection.objects:
        bpy.context.scene.collection.objects.unlink(obj)


def _mat(name: str, color, emit=0.0, metallic=0.0, rough=0.62):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (color[0], color[1], color[2], 1.0)
        if "Roughness" in bsdf.inputs:
            bsdf.inputs["Roughness"].default_value = rough
        if "Metallic" in bsdf.inputs:
            bsdf.inputs["Metallic"].default_value = metallic
        if "Emission" in bsdf.inputs:
            bsdf.inputs["Emission"].default_value = (color[0], color[1], color[2], 1.0)
        if "Emission Strength" in bsdf.inputs:
            bsdf.inputs["Emission Strength"].default_value = emit
    mat.diffuse_color = (color[0], color[1], color[2], 1.0)
    return mat


def _prim(kind: str, loc, scale, name: str):
    if kind == "cube":
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    elif kind == "sphere":
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.5, location=loc, segments=16, ring_count=10)
    else:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.5, depth=1.0, location=loc, vertices=12)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return obj


def _assign_mat(obj, mat) -> None:
    if obj.data.materials:
        obj.data.materials[0] = mat
    else:
        obj.data.materials.append(mat)


def build_armature(fid: str, p):
    arm = bpy.data.armatures.new(f"{fid}.skeleton")
    obj = bpy.data.objects.new(f"{fid}.skeleton", arm)
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    sx, sy, sz = p.body_scale
    bpy.ops.object.mode_set(mode="EDIT")
    created = {}
    for name in CANONICAL_BONES:
        eb = arm.edit_bones.new(name)
        head, tail = REST[name]
        eb.head = (head[0] * sx, head[1] * sy, head[2] * sz)
        eb.tail = (tail[0] * sx, tail[1] * sy, tail[2] * sz)
        eb.use_deform = True
        created[name] = eb
    for name, parent in PARENT.items():
        if parent:
            created[name].parent = created[parent]
    extra = []
    for acc_name, parent, offset in ACCESSORIES[fid]:
        parent_eb = created[parent]
        eb = arm.edit_bones.new(acc_name)
        base = Vector(parent_eb.tail)
        off = Vector(offset)
        eb.head = base + off
        eb.tail = base + off + Vector((0.0, -0.12, -0.04))
        eb.use_deform = True
        eb.parent = parent_eb
        extra.append(acc_name)
    bpy.ops.object.mode_set(mode="OBJECT")
    return obj, extra


def build_mesh(fid: str, p, arm_obj):
    sx, sy, sz = p.body_scale
    tw = p.torso_width
    skin = _mat(f"{fid}.mat.skin", p.skin, 0.02, 0.0, 0.55)
    cloth = _mat(f"{fid}.mat.cloth", p.primary, 0.04, 0.05, 0.68)
    accent = _mat(f"{fid}.mat.accent", p.accent, 0.35, 0.15, 0.42)
    hair_m = _mat(f"{fid}.mat.hair", p.hair, 0.08, 0.0, 0.5)
    dark = _mat(f"{fid}.mat.secondary", p.secondary, 0.02, 0.12, 0.7)
    parts = []

    def add(kind, loc, scale, name, mat, bone):
        obj = _prim(kind, loc, scale, name)
        _assign_mat(obj, mat)
        vg = obj.vertex_groups.new(name=bone)
        vg.add([v.index for v in obj.data.vertices], 1.0, "REPLACE")
        parts.append(obj)
        return obj

    add("cube", (0.0, 0.02 * p.lean, 0.96 * sz), (0.18 * tw, 0.14, 0.12 * sz), "hips", cloth, "Hips")
    add("cube", (0.0, 0.03 * p.lean, 1.12 * sz), (0.20 * tw, 0.14, 0.18 * sz), "waist", cloth, "Spine")
    add("cube", (0.0, 0.04 * p.lean, 1.30 * sz), (0.24 * tw, 0.16, 0.22 * sz), "chest", cloth, "Chest")
    add("sphere", (0.0, 0.04, 1.62 * sz), (0.15 * p.head_scale, 0.16 * p.head_scale, 0.16 * p.head_scale), "head", skin, "Head")
    add("cube", (0.0, 0.02, 1.48 * sz), (0.08, 0.08, 0.08), "neck", skin, "Neck")
    add("cube", (0.0, 0.03, 1.72 * sz), (0.16 * p.head_scale, 0.18 * p.head_scale, 0.11), "hair", hair_m, "Head")
    add("sphere", (0.04, 0.12, 1.64 * sz), (0.025, 0.018, 0.018), "eye_l", dark, "Head")
    add("sphere", (-0.04, 0.12, 1.64 * sz), (0.025, 0.018, 0.018), "eye_r", dark, "Head")
    for side, sgn in (("L", 1.0), ("R", -1.0)):
        add("cube", (0.20 * sx * sgn, 0.0, 1.36 * sz), (0.09, 0.08, 0.07), f"shoulder_{side}", cloth, f"Shoulder_{side}")
        add("cylinder", (0.28 * sx * sgn, 0.0, 1.24 * sz), (0.06, 0.06, 0.28 * sz), f"upper_arm_{side}", skin, f"UpperArm_{side}")
        add("cylinder", (0.44 * sx * sgn, 0.0, 1.04 * sz), (0.05, 0.05, 0.24 * sz), f"lower_arm_{side}", skin, f"LowerArm_{side}")
        add("cube", (0.58 * sx * sgn, 0.02, 0.92 * sz), (0.09 * p.hand_scale, 0.07 * p.hand_scale, 0.06), f"hand_{side}", accent, f"Hand_{side}")
        add("cylinder", (0.11 * sx * sgn, 0.0, 0.70 * sz), (0.08 * tw, 0.08, 0.40 * sz), f"upper_leg_{side}", dark, f"UpperLeg_{side}")
        add("cylinder", (0.11 * sx * sgn, 0.0, 0.32 * sz), (0.06, 0.06, 0.34 * sz), f"lower_leg_{side}", dark, f"LowerLeg_{side}")
        add("cube", (0.11 * sx * sgn, 0.09, 0.05), (0.10 * p.foot_scale, 0.18 * p.foot_scale, 0.07), f"foot_{side}", accent, f"Foot_{side}")
    # Costume silhouettes.
    if fid == "ember-vale":
        add("cube", (0.0, 0.12, 1.28 * sz), (0.12, 0.05, 0.18), "vent", accent, "Chest")
        add("cube", (0.60 * sx, 0.0, 0.92 * sz), (0.12, 0.09, 0.08), "gauntlet_r", accent, "Hand_R")
        add("cube", (-0.60 * sx, 0.0, 0.92 * sz), (0.12, 0.09, 0.08), "gauntlet_l", accent, "Hand_L")
    elif fid == "rook-ironside":
        add("cube", (0.0, 0.14, 1.32 * sz), (0.30, 0.09, 0.24), "plating", dark, "Chest")
        add("cube", (0.0, -0.14, 1.18 * sz), (0.22, 0.07, 0.20), "backplate", dark, "Cloth_ArmorFlap")
        add("cube", (0.13 * sx, 0.12, 0.06), (0.13, 0.22, 0.09), "boot_r", accent, "Foot_R")
        add("cube", (-0.13 * sx, 0.12, 0.06), (0.13, 0.22, 0.09), "boot_l", accent, "Foot_L")
    elif fid == "juno-spark":
        add("cube", (0.16, 0.08, 1.34 * sz), (0.05, 0.13, 0.20), "panel_a", accent, "Cloth_VoltTag")
        add("cube", (-0.10, -0.06, 1.20 * sz), (0.04, 0.11, 0.16), "panel_b", accent, "Chest")
        add("cube", (0.0, 0.16, 1.74 * sz), (0.05, 0.12, 0.05), "hair_spike", hair_m, "Head")
    elif fid == "kaia-windrow":
        add("cube", (0.0, -0.22, 1.36 * sz), (0.06, 0.32, 0.09), "scarf", accent, "Cloth_Scarf")
        add("cube", (0.16, -0.24, 1.18 * sz), (0.05, 0.26, 0.05), "ribbon", accent, "Hair_Ribbon")
        add("cube", (-0.12, 0.12, 1.42 * sz), (0.18, 0.04, 0.09), "airfoil", accent, "Chest")
    elif fid == "nix-calder":
        add("cube", (0.0, 0.14, 1.36 * sz), (0.11, 0.07, 0.11), "crystal", accent, "Cloth_Crystal")
        add("cube", (0.08, 0.12, 1.48 * sz), (0.06, 0.06, 0.09), "crystal_b", accent, "Chest")
        add("cube", (0.58 * sx, 0.0, 0.92 * sz), (0.11, 0.08, 0.08), "glove_r", accent, "Hand_R")
    elif fid == "orion-vell":
        bpy.ops.mesh.primitive_torus_add(location=(0.0, 0.0, 1.34 * sz), major_radius=0.30, minor_radius=0.02)
        ring = bpy.context.active_object
        ring.name = "orbit_ring"
        _assign_mat(ring, accent)
        vg = ring.vertex_groups.new(name="Cloth_Orbit")
        vg.add([v.index for v in ring.data.vertices], 1.0, "REPLACE")
        parts.append(ring)
        add("cube", (0.0, 0.0, 1.22 * sz), (0.22, 0.17, 0.05), "layer", dark, "Chest")
    elif fid == "vesper-nyx":
        add("cube", (0.18, -0.18, 1.20 * sz), (0.12, 0.24, 0.32), "coat_l", dark, "Coat_Panel_L")
        add("cube", (-0.08, -0.12, 1.26 * sz), (0.08, 0.16, 0.20), "coat_r", dark, "Coat_Panel_R")
        add("cube", (0.10, 0.08, 1.74 * sz), (0.14, 0.12, 0.09), "hood", hair_m, "Head")

    bpy.ops.object.select_all(action="DESELECT")
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    body = bpy.context.active_object
    body.name = f"{fid}.mesh"
    _armature_mod(body, arm_obj)
    body.parent = arm_obj
    return body


def _armature_mod(mesh_obj, arm_obj) -> None:
    bpy.context.view_layer.objects.active = mesh_obj
    mod = mesh_obj.modifiers.new("AA_Armature", "ARMATURE")
    mod.object = arm_obj
    mod.use_vertex_groups = True


def apply_animations(fid: str, arm_obj) -> list[str]:
    names = []
    p = profile(fid)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode="POSE")
    for action_name in all_actions():
        poses = poses_for_action(fid, action_name)
        frames = duration_for(action_name)
        times = phase_times(action_name, frames, p)
        act = bpy.data.actions.new(name=action_name)
        arm_obj.animation_data_create()
        arm_obj.animation_data.action = act
        for phase, pose in poses.items():
            frame = times.get(phase, 1)
            bpy.context.scene.frame_set(max(1, frame + 1))
            for bone_name, rot in pose.items():
                pb = arm_obj.pose.bones.get(bone_name)
                if pb is None:
                    continue
                pb.rotation_mode = "XYZ"
                pb.rotation_euler = rot
                pb.keyframe_insert(data_path="rotation_euler", frame=max(1, frame + 1))
            for bone_name, loc in locations_for(fid, action_name, phase).items():
                pb = arm_obj.pose.bones.get(bone_name)
                if pb is None:
                    continue
                pb.location = loc
                pb.keyframe_insert(data_path="location", frame=max(1, frame + 1))
        names.append(action_name)
    bpy.ops.object.mode_set(mode="OBJECT")
    return names


def export_glb(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in bpy.context.scene.objects:
        if obj.type in {"ARMATURE", "MESH", "EMPTY"} and not obj.name.startswith("AA_Ref"):
            obj.select_set(True)
            if obj.type == "ARMATURE":
                bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(
        filepath=str(path),
        export_format="GLB",
        use_selection=True,
        export_animations=True,
        export_nla_strips=True,
        export_skins=True,
        export_morph=False,
        export_apply=True,
        export_yup=True,
        export_cameras=False,
        export_lights=False,
        export_def_bones=True,
        export_anim_single_armature=True,
    )


def setup_review_camera() -> None:
    cam_data = bpy.data.cameras.new("AA_ReviewCam")
    cam_data.lens = 50
    cam = bpy.data.objects.new("AA_ReviewCam", cam_data)
    cam.location = (1.55, -2.15, 1.05)
    cam.rotation_euler = (1.28, 0.0, 0.58)
    bpy.context.collection.objects.link(cam)
    bpy.context.scene.camera = cam
    key = bpy.data.lights.new("AA_Key", "AREA")
    key.energy = 500
    key_obj = bpy.data.objects.new("AA_Key", key)
    key_obj.location = (1.6, -1.4, 2.4)
    bpy.context.collection.objects.link(key_obj)
    rim = bpy.data.lights.new("AA_Rim", "AREA")
    rim.energy = 260
    rim_obj = bpy.data.objects.new("AA_Rim", rim)
    rim_obj.location = (-1.6, 1.2, 2.0)
    bpy.context.collection.objects.link(rim_obj)
    fill = bpy.data.lights.new("AA_Fill", "AREA")
    fill.energy = 120
    fill_obj = bpy.data.objects.new("AA_Fill", fill)
    fill_obj.location = (0.0, 2.0, 1.6)
    bpy.context.collection.objects.link(fill_obj)
    bpy.ops.mesh.primitive_plane_add(size=6.0, location=(0.0, 0.0, 0.0))
    ground = bpy.context.active_object
    ground.name = "AA_RefGround"
    _assign_mat(ground, _mat("AA_Ground", (0.08, 0.08, 0.09), 0.0, 0.0, 0.9))


def build(fid: str, out_blend: Path, out_glb: Path, skip_anim: bool) -> dict:
    p = profile(fid)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.render.fps = 60
    bpy.context.scene.unit_settings.system = "METRIC"
    export_col = _collection("AA_EXPORT")
    mesh_col = _collection("AA_MESH")
    arm, extras = build_armature(fid, p)
    _link(export_col, arm)
    mesh = build_mesh(fid, p, arm)
    _link(mesh_col, mesh)
    setup_review_camera()
    actions = [] if skip_anim else apply_animations(fid, arm)
    out_blend.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(out_blend))
    export_glb(out_glb)
    tris = len(mesh.data.polygons)
    return {
        "fighter": fid,
        "status": "GENERATED_PRODUCTION_ART",
        "generator": GENERATOR,
        "generator_version": GENERATOR_VERSION,
        "blend": str(out_blend),
        "glb": str(out_glb),
        "triangles": tris,
        "bones": [b.name for b in arm.data.bones],
        "secondary_bones": extras,
        "actions": actions,
        "human_authored": False,
        "future_human_replaceable": True,
        "blender": bpy.app.version_string,
    }


def main() -> int:
    args = _parse()
    fid = args["fighter"]

    def _abs(path_like) -> Path:
        path = Path(path_like)
        if not path.is_absolute():
            path = ROOT / path
        return path.resolve()

    out_blend = _abs(args["out_blend"] or production_master_blend(fid))
    out_glb = _abs(args["out_glb"] or generated_model_glb(fid))
    report = build(fid, out_blend, out_glb, args.get("skip_anim") == "1")
    text = json.dumps(report, indent=2)
    if args.get("report"):
        Path(args["report"]).write_text(text + "\n")
    print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
