"""Render generated production review stills, extra v2 shots, and deformation sheets."""
from __future__ import annotations

import json
import sys
from pathlib import Path

import bpy
from mathutils import Euler, Vector

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent.parent))

SHOTS = (
    ("idle", 1),
    ("personality_idle", 16),
    ("walk", 8),
    ("run", 6),
    ("dash", 4),
    ("charged_idle", 12),
    ("heavy", 4),
    ("heavy", 11),
    ("heavy", 16),
    ("hurt_heavy", 6),
    ("signature_lane_burst", 14),
    ("signature_lane_finisher", 16),
    ("ko", 12),
)

SHOT_LABELS = (
    "idle",
    "personality_idle",
    "walk",
    "run",
    "dash",
    "charge_100",
    "heavy_anticipation",
    "heavy_contact",
    "heavy_follow",
    "hurt_heavy",
    "aura",
    "super",
    "ko",
)

EXTRA_SHOTS = (
    ("close_body_3q", "idle", 1, (1.15, 1.55, 1.25), 55),
    ("silhouette", "idle", 1, (0.05, 3.4, 1.05), 45),
    ("costume_detail", "idle", 1, (0.85, 1.15, 1.35), 70),
    ("deformation_stress", "heavy", 11, (1.8, 2.6, 1.15), 45),
)

DEFORM = (
    ("neutral_front", "idle", 1, (0.0, 3.2, 1.05)),
    ("neutral_3q", "idle", 1, (2.15, 3.35, 1.25)),
    ("arms_overhead", None, 1, (2.0, 3.1, 1.2)),
    ("punch_extension", "heavy", 11, (2.0, 3.1, 1.15)),
    ("torso_twist", None, 1, (2.0, 3.1, 1.15)),
    ("crouch", "idle", 1, (2.0, 3.0, 0.85)),
    ("run_stride", "run", 6, (2.0, 3.1, 1.15)),
    ("jump_tuck", "jump", 6, (2.0, 3.1, 1.25)),
    ("heavy_anticipation", "heavy", 4, (2.0, 3.1, 1.15)),
    ("heavy_contact", "heavy", 11, (2.0, 3.1, 1.15)),
    ("hurt_heavy", "hurt_heavy", 6, (2.0, 3.1, 1.15)),
    ("charge_100", "charged_idle", 12, (2.0, 3.1, 1.15)),
)

MANUAL_POSE = {
    "arms_overhead": {
        "UpperArm_L": (0.15, 0.2, 2.5),
        "UpperArm_R": (0.15, -0.2, -2.5),
        "LowerArm_L": (0.4, 0.0, 0.2),
        "LowerArm_R": (0.4, 0.0, -0.2),
    },
    "torso_twist": {
        "Hips": (0.05, 0.35, 0.1),
        "Spine": (0.1, 0.55, 0.15),
        "Chest": (0.12, 0.75, 0.18),
        "Head": (0.05, -0.25, 0.0),
    },
    "crouch": {
        "Hips": (0.35, 0.0, 0.0),
        "UpperLeg_L": (1.05, 0.0, -0.15),
        "UpperLeg_R": (1.05, 0.0, 0.15),
        "LowerLeg_L": (1.35, 0.0, 0.0),
        "LowerLeg_R": (1.35, 0.0, 0.0),
        "Spine": (0.25, 0.0, 0.0),
    },
}


def _argv() -> list[str]:
    if "--" in sys.argv:
        return sys.argv[sys.argv.index("--") + 1 :]
    return sys.argv[1:]


def _parse() -> dict:
    args = _argv()
    out = {"out_dir": "", "fighter": "", "deform_dir": ""}
    i = 0
    while i < len(args):
        if args[i].startswith("--") and i + 1 < len(args):
            out[args[i][2:].replace("-", "_")] = args[i + 1]
            i += 2
        else:
            i += 1
    return out


def _find_arm():
    for obj in bpy.data.objects:
        if obj.type == "ARMATURE":
            return obj
    return None


def _aim(cam, loc, target=None):
    cam.location = Vector(loc)
    aim = target or Vector((0.0, 0.0, 0.95))
    cam.rotation_euler = (aim - cam.location).to_track_quat("-Z", "Y").to_euler()


def _blackout(enable: bool, cache: dict) -> None:
    if enable:
        cache.clear()
        for obj in bpy.data.objects:
            if obj.type != "MESH" or obj.name.startswith("AA_Ref"):
                continue
            cache[obj.name] = [slot.material for slot in obj.material_slots]
            black = bpy.data.materials.get("AA_Silhouette") or bpy.data.materials.new("AA_Silhouette")
            black.use_nodes = True
            bsdf = black.node_tree.nodes.get("Principled BSDF")
            if bsdf:
                bsdf.inputs["Base Color"].default_value = (0.01, 0.01, 0.01, 1.0)
                if "Emission Strength" in bsdf.inputs:
                    bsdf.inputs["Emission Strength"].default_value = 0.0
            for i in range(len(obj.material_slots)):
                obj.material_slots[i].material = black
    else:
        for obj in bpy.data.objects:
            if obj.name in cache:
                for i, mat in enumerate(cache[obj.name]):
                    if i < len(obj.material_slots):
                        obj.material_slots[i].material = mat


def render_current(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 640
    scene.render.resolution_y = 800
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(path)
    scene.render.film_transparent = False
    bpy.ops.render.render(write_still=True)


def _clear_pose(arm) -> None:
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")
    for pb in arm.pose.bones:
        pb.rotation_mode = "XYZ"
        pb.rotation_euler = (0.0, 0.0, 0.0)
        pb.location = (0.0, 0.0, 0.0)
    bpy.ops.object.mode_set(mode="OBJECT")


def _apply_manual(arm, pose: dict) -> None:
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")
    for name, rot in pose.items():
        pb = arm.pose.bones.get(name)
        if pb is None:
            continue
        pb.rotation_mode = "XYZ"
        pb.rotation_euler = Euler(rot)
    bpy.ops.object.mode_set(mode="OBJECT")


def _set_action(arm, action_name, frame) -> bool:
    act = bpy.data.actions.get(action_name) if action_name else None
    if act is None:
        return False
    arm.animation_data_create()
    arm.animation_data.action = act
    bpy.context.scene.frame_set(frame)
    return True


def main() -> int:
    args = _parse()
    out_dir = Path(args["out_dir"])
    fid = args.get("fighter") or ""
    deform_dir = Path(args["deform_dir"]) if args.get("deform_dir") else out_dir.parent.parent / "deformation_v2"
    arm = _find_arm()
    if arm is None:
        print(json.dumps({"ok": False, "reason": "no_armature"}))
        return 1
    cam = bpy.context.scene.camera
    if cam is None:
        for obj in bpy.data.objects:
            if obj.type == "CAMERA":
                cam = obj
                bpy.context.scene.camera = cam
                break
    written = []
    bpy.context.view_layer.objects.active = arm
    if cam is not None:
        _aim(cam, (2.15, 3.35, 1.25))
        if cam.data:
            cam.data.lens = 45
    for (action, frame), label in zip(SHOTS, SHOT_LABELS):
        if not _set_action(arm, action, frame):
            continue
        dest = out_dir / fid / f"{label}.png"
        render_current(dest)
        written.append(str(dest))
    cache = {}
    for label, action, frame, loc, lens in EXTRA_SHOTS:
        if action and not _set_action(arm, action, frame):
            continue
        if cam is not None:
            _aim(cam, loc)
            if cam.data:
                cam.data.lens = lens
        if label == "silhouette":
            _blackout(True, cache)
        dest = out_dir / fid / f"{label}.png"
        render_current(dest)
        written.append(str(dest))
        if label == "silhouette":
            _blackout(False, cache)
    if cam is not None:
        _aim(cam, (2.15, 3.35, 1.25))
        if cam.data:
            cam.data.lens = 45
    deform_written = []
    for label, action, frame, loc in DEFORM:
        if cam is not None:
            _aim(cam, loc, Vector((0.0, 0.0, 0.90)))
        if label in MANUAL_POSE:
            if arm.animation_data:
                arm.animation_data.action = None
            _clear_pose(arm)
            _apply_manual(arm, MANUAL_POSE[label])
        elif action:
            if not _set_action(arm, action, frame):
                continue
        dest = deform_dir / fid / f"{label}.png"
        render_current(dest)
        deform_written.append(str(dest))
    print(json.dumps({"ok": True, "fighter": fid, "frames": written, "deformation": deform_written}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
