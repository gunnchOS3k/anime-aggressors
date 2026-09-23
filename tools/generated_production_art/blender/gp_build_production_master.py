"""Build one generated production master per fighter and export the runtime GLB."""
from __future__ import annotations

import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent.parent))

from generated_production_art.action_catalog import all_actions, duration_for  # noqa: E402
from generated_production_art.body_v2 import recipe  # noqa: E402
from generated_production_art.common import (  # noqa: E402
    CANONICAL_BONES,
    GENERATOR,
    GENERATOR_REVISION,
    GENERATOR_VERSION,
    generated_model_glb,
    production_master_blend,
)
from generated_production_art.pose_library import locations_for, phase_times, poses_for_action  # noqa: E402
from generated_production_art.profiles import profile  # noqa: E402

from gp_body_v2 import _toon_mat, _assign, build_cohesive_fighter  # noqa: E402

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
    "ember-vale": (("Cloth_Flame_R", "Hand_R", (0.04, 0.02, 0.01)), ("Cloth_Flame_L", "Hand_L", (-0.04, 0.02, 0.01))),
    "rook-ironside": (("Cloth_ArmorFlap", "Chest", (0.0, -0.08, -0.04)),),
    "juno-spark": (("Cloth_VoltTag", "Chest", (0.07, 0.06, 0.02)),),
    "kaia-windrow": (("Cloth_Scarf", "Neck", (0.0, -0.10, -0.02)), ("Hair_Ribbon", "Head", (0.04, -0.10, 0.0))),
    "nix-calder": (("Cloth_Crystal", "Chest", (0.0, 0.08, 0.02)),),
    "orion-vell": (("Cloth_Orbit", "Chest", (0.0, 0.0, 0.08)),),
    "vesper-nyx": (("Coat_Panel_L", "Hips", (0.10, -0.08, 0.04)), ("Coat_Panel_R", "Hips", (-0.07, -0.06, 0.04))),
}

SOCKETS = {
    "hand_l": "Hand_L",
    "hand_r": "Hand_R",
    "foot_l": "Foot_L",
    "foot_r": "Foot_R",
    "chest": "Chest",
    "head": "Head",
    "back": "Chest",
    "projectile_origin": "Hand_R",
    "aura_root": "Hips",
}

TWIST = {
    "TwistArm_L": ("UpperArm_L", "LowerArm_L"),
    "TwistArm_R": ("UpperArm_R", "LowerArm_R"),
    "TwistLeg_L": ("UpperLeg_L", "LowerLeg_L"),
    "TwistLeg_R": ("UpperLeg_R", "LowerLeg_R"),
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
    for twist_name, (parent_name, child_name) in TWIST.items():
        parent_eb = created[parent_name]
        child_eb = created[child_name]
        eb = arm.edit_bones.new(twist_name)
        mid_head = (Vector(parent_eb.head) + Vector(parent_eb.tail)) * 0.5
        eb.head = mid_head
        eb.tail = Vector(parent_eb.tail)
        if (eb.tail - eb.head).length < 0.04:
            eb.tail = Vector(child_eb.head)
        eb.use_deform = True
        eb.parent = parent_eb
        created[twist_name] = eb
        extra.append(twist_name)
    for acc_name, parent, offset in ACCESSORIES[fid]:
        parent_eb = created[parent]
        eb = arm.edit_bones.new(acc_name)
        base = Vector(parent_eb.tail)
        off = Vector(offset)
        eb.head = base + off
        eb.tail = base + off + Vector((0.0, -0.08, -0.02))
        eb.use_deform = True
        eb.parent = parent_eb
        extra.append(acc_name)
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.mode_set(mode="POSE")
    for twist_name, (parent_name, child_name) in TWIST.items():
        pb = obj.pose.bones.get(twist_name)
        if pb is None:
            continue
        con = pb.constraints.new("COPY_ROTATION")
        con.target = obj
        con.subtarget = child_name
        con.use_x = False
        con.use_y = True
        con.use_z = False
        con.mix_mode = "BEFORE"
        con.influence = 0.45
        con.target_space = "LOCAL"
        con.owner_space = "LOCAL"
    bpy.ops.object.mode_set(mode="OBJECT")
    return obj, extra


def add_sockets(arm_obj) -> list[str]:
    names = []
    for sock, parent in SOCKETS.items():
        empty = bpy.data.objects.new(f"socket_{sock}", None)
        empty.empty_display_type = "PLAIN_AXES"
        empty.empty_display_size = 0.04
        bpy.context.collection.objects.link(empty)
        empty.parent = arm_obj
        empty.parent_type = "BONE"
        empty.parent_bone = parent
        empty.location = (0.0, 0.0, 0.0)
        names.append(empty.name)
    return names


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
        export_apply=False,
        export_yup=True,
        export_cameras=False,
        export_lights=False,
        export_def_bones=True,
        export_anim_single_armature=True,
    )


def setup_review_camera() -> None:
    world = bpy.data.worlds.new("AA_World")
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = (0.03, 0.03, 0.035, 1.0)
        bg.inputs[1].default_value = 0.35
    bpy.context.scene.world = world
    if hasattr(bpy.context.scene, "eevee"):
        bpy.context.scene.eevee.use_bloom = True
        bpy.context.scene.eevee.bloom_intensity = 0.12
    cam_data = bpy.data.cameras.new("AA_ReviewCam")
    cam_data.lens = 50
    cam = bpy.data.objects.new("AA_ReviewCam", cam_data)
    cam.location = (1.55, -2.15, 1.05)
    cam.rotation_euler = (1.28, 0.0, 0.58)
    bpy.context.collection.objects.link(cam)
    bpy.context.scene.camera = cam
    key = bpy.data.lights.new("AA_Key", "AREA")
    key.energy = 620
    key_obj = bpy.data.objects.new("AA_Key", key)
    key_obj.location = (1.6, -1.4, 2.4)
    bpy.context.collection.objects.link(key_obj)
    rim = bpy.data.lights.new("AA_Rim", "AREA")
    rim.energy = 340
    rim_obj = bpy.data.objects.new("AA_Rim", rim)
    rim_obj.location = (-1.6, 1.2, 2.0)
    bpy.context.collection.objects.link(rim_obj)
    fill = bpy.data.lights.new("AA_Fill", "AREA")
    fill.energy = 160
    fill_obj = bpy.data.objects.new("AA_Fill", fill)
    fill_obj.location = (0.0, 2.0, 1.6)
    bpy.context.collection.objects.link(fill_obj)
    bpy.ops.mesh.primitive_plane_add(size=6.0, location=(0.0, 0.0, 0.0))
    ground = bpy.context.active_object
    ground.name = "AA_RefGround"
    _assign(ground, _toon_mat("AA_Ground", (0.10, 0.10, 0.11), 0.0, 0.0, 0.92))


def build(fid: str, out_blend: Path, out_glb: Path, skip_anim: bool) -> dict:
    p = profile(fid)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.render.fps = 60
    bpy.context.scene.unit_settings.system = "METRIC"
    export_col = _collection("AA_EXPORT")
    mesh_col = _collection("AA_MESH")
    arm, extras = build_armature(fid, p)
    _link(export_col, arm)
    body, costume, geom = build_cohesive_fighter(fid, p, arm)
    _link(mesh_col, body)
    for obj in costume:
        _link(mesh_col, obj)
    sockets = add_sockets(arm)
    setup_review_camera()
    actions = [] if skip_anim else apply_animations(fid, arm)
    out_blend.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(out_blend))
    export_glb(out_glb)
    return {
        "fighter": fid,
        "status": "GENERATED_PRODUCTION_ART",
        "generator": GENERATOR,
        "generator_version": GENERATOR_VERSION,
        "generator_revision": GENERATOR_REVISION,
        "blend": str(out_blend),
        "glb": str(out_glb),
        "triangles": geom.get("triangles"),
        "body_connected_components": geom.get("body_connected_components"),
        "material_count": geom.get("material_count"),
        "bones": [b.name for b in arm.data.bones],
        "secondary_bones": extras,
        "sockets": sockets,
        "actions": actions,
        "action_count": len(actions),
        "geometry": geom,
        "recipe": recipe(fid).head_style,
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
