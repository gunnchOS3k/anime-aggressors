"""Render generated-art v3 review packet, silhouettes, and design sheets."""
from __future__ import annotations

import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent.parent))

PACKET_SHOTS = (
    ("idle", "idle", 1, (2.15, 3.35, 1.25), 45, False, False),
    ("walk", "walk", 8, (2.15, 3.35, 1.25), 45, False, False),
    ("run", "run", 6, (2.15, 3.35, 1.25), 45, False, False),
    ("close_body_3q", "idle", 1, (1.15, 1.55, 1.25), 55, False, False),
    ("silhouette", "idle", 1, (0.05, 3.4, 1.05), 45, True, False),
    ("head_detail", "idle", 1, (0.55, 0.85, 1.62), 85, False, False),
    ("hand_detail", "idle", 1, (0.85, 1.05, 1.05), 90, False, False),
    ("foot_detail", "idle", 1, (0.55, 1.15, 0.28), 90, False, False),
    ("costume_detail", "idle", 1, (0.85, 1.15, 1.35), 70, False, False),
    ("heavy_anticipation", "heavy", 4, (2.15, 3.35, 1.25), 45, False, False),
    ("heavy_contact", "heavy", 11, (2.15, 3.35, 1.25), 45, False, False),
    ("heavy_follow", "heavy", 16, (2.15, 3.35, 1.25), 45, False, False),
    ("hurt_heavy", "hurt_heavy", 6, (2.15, 3.35, 1.25), 45, False, False),
    ("charge_100_vfx_on", "charged_idle", 12, (2.15, 3.35, 1.25), 45, False, False),
    ("charge_100_vfx_off", "charged_idle", 12, (2.15, 3.35, 1.25), 45, False, True),
    ("super", "signature_lane_finisher", 16, (2.15, 3.35, 1.25), 45, False, False),
    ("KO", "ko", 12, (2.15, 3.35, 1.25), 45, False, False),
)

SILHOUETTE_SHOTS = (
    ("neutral", "idle", 1),
    ("walk", "walk", 8),
    ("heavy_anticipation", "heavy", 4),
    ("heavy_contact", "heavy", 11),
    ("charge_100", "charged_idle", 12),
)

DESIGN_SHEETS = (
    ("front", "idle", 1, (0.0, 3.4, 1.05), 45),
    ("side", "idle", 1, (3.4, 0.05, 1.05), 45),
    ("back", "idle", 1, (0.0, -3.4, 1.05), 45),
    ("3q", "idle", 1, (2.15, 3.35, 1.25), 45),
    ("silhouette", "idle", 1, (0.05, 3.4, 1.05), 45),
    ("head_detail", "idle", 1, (0.55, 0.85, 1.62), 85),
    ("hand_foot_detail", "idle", 1, (0.75, 1.15, 0.72), 70),
    ("costume_detail", "idle", 1, (0.85, 1.15, 1.35), 70),
    ("charge_100", "charged_idle", 12, (2.15, 3.35, 1.25), 45),
    ("heavy_contact", "heavy", 11, (2.15, 3.35, 1.25), 45),
)


def _argv() -> list[str]:
    if "--" in sys.argv:
        return sys.argv[sys.argv.index("--") + 1 :]
    return sys.argv[1:]


def _parse() -> dict:
    args = _argv()
    out = {"out_dir": "", "fighter": "", "sheet_dir": ""}
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


def _bone_world(arm, name):
    bone = arm.pose.bones.get(name)
    if bone is None:
        return Vector((0.0, 0.0, 0.95))
    return arm.matrix_world @ bone.head


def _aim(cam, loc, target=None):
    cam.location = Vector(loc)
    aim = target or Vector((0.0, 0.0, 0.95))
    cam.rotation_euler = (aim - cam.location).to_track_quat("-Z", "Y").to_euler()


def _detail_camera(label, loc, arm):
    target = None
    if label in {"head_detail"}:
        target = _bone_world(arm, "Head")
        loc = (target.x + 0.45, target.y - 0.55, target.z + 0.12)
    elif label in {"hand_detail", "hand_foot_detail"}:
        target = _bone_world(arm, "Hand_R")
        loc = (target.x + 0.38, target.y - 0.48, target.z + 0.14)
    elif label in {"foot_detail"}:
        target = _bone_world(arm, "Foot_R")
        loc = (target.x + 0.38, target.y - 0.48, target.z + 0.20)
    return loc, target


def _blackout(enable: bool, cache: dict) -> None:
    if enable:
        cache.clear()
        for obj in bpy.data.objects:
            if obj.type != "MESH" or obj.name.startswith("AA_Ref"):
                continue
            cache[obj.name] = [slot.material for slot in obj.material_slots]
            black = bpy.data.materials.get("AA_Silhouette") or bpy.data.materials.new("AA_Silhouette")
            black.use_nodes = True
            nt = black.node_tree
            nt.nodes.clear()
            out = nt.nodes.new("ShaderNodeOutputMaterial")
            emit = nt.nodes.new("ShaderNodeEmission")
            emit.inputs["Color"].default_value = (0.0, 0.0, 0.0, 1.0)
            emit.inputs["Strength"].default_value = 0.0
            nt.links.new(emit.outputs["Emission"], out.inputs["Surface"])
            black.diffuse_color = (0.0, 0.0, 0.0, 1.0)
            for i in range(len(obj.material_slots)):
                obj.material_slots[i].material = black
        world = bpy.context.scene.world
        if world and world.use_nodes:
            bg = world.node_tree.nodes.get("Background")
            if bg:
                cache["__world__"] = list(bg.inputs[0].default_value)
                bg.inputs[0].default_value = (0.92, 0.92, 0.90, 1.0)
                bg.inputs[1].default_value = 1.0
    else:
        for obj in bpy.data.objects:
            if obj.name in cache:
                for i, mat in enumerate(cache[obj.name]):
                    if i < len(obj.material_slots):
                        obj.material_slots[i].material = mat
        if "__world__" in cache and bpy.context.scene.world and bpy.context.scene.world.use_nodes:
            bg = bpy.context.scene.world.node_tree.nodes.get("Background")
            if bg:
                col = cache["__world__"]
                bg.inputs[0].default_value = (col[0], col[1], col[2], 1.0)
                bg.inputs[1].default_value = 0.35


def _grayscale(enable: bool, cache: dict) -> None:
    if enable:
        cache.clear()
        for mat in bpy.data.materials:
            if not mat.use_nodes:
                continue
            for node in mat.node_tree.nodes:
                if node.type in {"EMISSION"}:
                    cache.setdefault(mat.name, []).append((node, [c for c in node.inputs["Color"].default_value], node.inputs["Strength"].default_value if "Strength" in node.inputs else 0.0))
                    node.inputs["Color"].default_value = (0.55, 0.55, 0.55, 1.0)
                    if "Strength" in node.inputs:
                        node.inputs["Strength"].default_value = min(node.inputs["Strength"].default_value, 0.08)
        for obj in bpy.data.objects:
            if "orbit" in obj.name.lower() or "flame" in obj.name.lower() or "tongue" in obj.name.lower():
                cache[f"hide:{obj.name}"] = (obj.hide_render, obj.hide_viewport)
                obj.hide_render = True
                obj.hide_viewport = True
    else:
        for mat in bpy.data.materials:
            for item in cache.get(mat.name, []):
                node, color, strength = item
                node.inputs["Color"].default_value = (color[0], color[1], color[2], color[3])
                if "Strength" in node.inputs:
                    node.inputs["Strength"].default_value = strength
        for key, value in cache.items():
            if key.startswith("hide:"):
                obj = bpy.data.objects.get(key.split(":", 1)[1])
                if obj:
                    obj.hide_render, obj.hide_viewport = value


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
    sheet_dir = Path(args["sheet_dir"]) if args.get("sheet_dir") else out_dir / "design_sheets"
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
    sil_cache = {}
    gray_cache = {}
    for label, action, frame, loc, lens, sil, gray in PACKET_SHOTS:
        if action and not _set_action(arm, action, frame):
            continue
        if cam is not None:
            loc, target = _detail_camera(label, loc, arm)
            _aim(cam, loc, target)
            if cam.data:
                cam.data.lens = lens
        if sil:
            _blackout(True, sil_cache)
        if gray:
            _grayscale(True, gray_cache)
        dest = out_dir / fid / f"{label}.png"
        render_current(dest)
        written.append(str(dest))
        if sil:
            _blackout(False, sil_cache)
        if gray:
            _grayscale(False, gray_cache)
    sil_written = []
    for label, action, frame in SILHOUETTE_SHOTS:
        if action and not _set_action(arm, action, frame):
            continue
        if cam is not None:
            _aim(cam, (0.05, 3.4, 1.05))
            if cam.data:
                cam.data.lens = 45
        _blackout(True, sil_cache)
        dest = out_dir / fid / f"silhouette_{label}.png"
        render_current(dest)
        sil_written.append(str(dest))
        _blackout(False, sil_cache)
    sheet_written = []
    for label, action, frame, loc, lens in DESIGN_SHEETS:
        if action and not _set_action(arm, action, frame):
            continue
        if cam is not None:
            loc, target = _detail_camera(label, loc, arm)
            _aim(cam, loc, target)
            if cam.data:
                cam.data.lens = lens
        if label == "silhouette":
            _blackout(True, sil_cache)
        dest = sheet_dir / fid / f"{label}.png"
        render_current(dest)
        sheet_written.append(str(dest))
        if label == "silhouette":
            _blackout(False, sil_cache)
    print(json.dumps({"ok": True, "fighter": fid, "packet": written, "silhouettes": sil_written, "sheets": sheet_written}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
