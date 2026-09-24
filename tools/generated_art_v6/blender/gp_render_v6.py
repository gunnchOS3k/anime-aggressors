"""Render generated-art v6 review packet. Aim detail cameras at actual meshes."""
from __future__ import annotations

import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent.parent))
sys.path.insert(0, str(HERE.parents[2] / "tools"))

from generated_art_v6.outline import set_outlines_visible  # noqa: E402
from generated_art_v6.render_review import PACKET  # noqa: E402
from generated_production_art.review_cameras_v4 import (  # noqa: E402
    CANONICAL_FORWARD,
    FRONT_MARKER_NAME,
    PRESETS,
    back_facing_ok,
    camera_location,
    camera_look_at,
    front_facing_ok,
    three_q_ok,
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


def _marker_forward(arm):
    marker = bpy.data.objects.get(FRONT_MARKER_NAME)
    if marker is not None:
        world = marker.matrix_world.to_3x3() @ Vector((0.0, 1.0, 0.0))
        if world.length > 1e-5:
            world.normalize()
            return (float(world.x), float(world.y), float(world.z))
    return CANONICAL_FORWARD


def _aim(cam, loc, target):
    cam.location = Vector(loc)
    cam.rotation_euler = (Vector(target) - cam.location).to_track_quat("-Z", "Y").to_euler()


def _bounds_center(names):
    mins = [1e9, 1e9, 1e9]
    maxs = [-1e9, -1e9, -1e9]
    found = False
    for obj in bpy.data.objects:
        if obj.type != "MESH":
            continue
        lowered = obj.name.lower()
        if not any(lowered.startswith(key) for key in names):
            continue
        if obj.get("aa_outline"):
            continue
        for vert in obj.data.vertices:
            world = obj.matrix_world @ vert.co
            for i in range(3):
                mins[i] = min(mins[i], world[i])
                maxs[i] = max(maxs[i], world[i])
            found = True
    if not found:
        return None
    return ((mins[0] + maxs[0]) * 0.5, (mins[1] + maxs[1]) * 0.5, (mins[2] + maxs[2]) * 0.5)


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
                if node.type == "EMISSION" and "Color" in node.inputs:
                    color = [c for c in node.inputs["Color"].default_value]
                    luma = 0.2126 * color[0] + 0.7152 * color[1] + 0.0722 * color[2]
                    cache.setdefault(mat.name, []).append((node, color, node.inputs["Strength"].default_value if "Strength" in node.inputs else 0.0))
                    node.inputs["Color"].default_value = (luma, luma, luma, 1.0)
    else:
        for mat in bpy.data.materials:
            for item in cache.get(mat.name, []):
                node, color, strength = item
                node.inputs["Color"].default_value = (color[0], color[1], color[2], color[3] if len(color) > 3 else 1.0)
                if "Strength" in node.inputs:
                    node.inputs["Strength"].default_value = strength


def render_current(path: Path, scale: float = 1.0) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = int(640 * scale)
    scene.render.resolution_y = int(800 * scale)
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
    arm = _find_arm()
    if arm is None:
        print(json.dumps({"ok": False, "reason": "no_armature"}))
        return 1
    forward = CANONICAL_FORWARD
    marker_forward = _marker_forward(arm)
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
    orientation = {}
    (out_dir / fid).mkdir(parents=True, exist_ok=True)
    for label, action, frame, preset_name, sil, gray, outline, aim in PACKET:
        if action:
            arm.data.pose_position = "POSE"
            _set_action(arm, action, frame)
        else:
            if arm.animation_data:
                arm.animation_data.action = None
            arm.data.pose_position = "REST"
            bpy.context.scene.frame_set(1)
            bpy.context.view_layer.update()
        preset = PRESETS[preset_name]
        loc = camera_location(preset, forward)
        target = camera_look_at(preset)
        if aim == "glove":
            center = _bounds_center(("hand_r",))
            if center:
                target = center
                loc = (center[0] + 0.55, center[1] + 0.85, center[2] + 0.22)
        elif aim == "boot":
            center = _bounds_center(("boot_r",))
            if center:
                target = center
                loc = (center[0] + 0.60, center[1] + 0.95, max(0.18, center[2] + 0.22))
        elif aim == "head":
            center = _bounds_center(("head_shell",))
            if center:
                target = center
                loc = (center[0] + 0.40, center[1] + 0.75, center[2] + 0.10)
        if cam is not None:
            _aim(cam, loc, target)
            if cam.data:
                cam.data.lens = preset.lens
                if hasattr(cam.data, "type"):
                    cam.data.type = "ORTHO" if preset.ortho else "PERSP"
                    if preset.ortho:
                        cam.data.ortho_scale = 2.4
        set_outlines_visible(bool(outline))
        if sil:
            _blackout(True, sil_cache)
        if gray:
            _grayscale(True, gray_cache)
        scale = 0.72 if label == "gameplay_scale" else 1.0
        dest = out_dir / fid / f"{label}.png"
        render_current(dest, scale)
        written.append(str(dest))
        if label in {"front", "front_3q", "back"}:
            orientation[label] = {
                "preset": preset_name,
                "location": [round(v, 4) for v in loc],
                "forward": [round(v, 4) for v in forward],
                "front_facing": front_facing_ok(loc, forward),
                "back_facing": back_facing_ok(loc, forward),
                "three_q": three_q_ok(loc, forward),
            }
        if sil:
            _blackout(False, sil_cache)
        if gray:
            _grayscale(False, gray_cache)
        set_outlines_visible(False)
    payload = {
        "ok": True,
        "fighter": fid,
        "packet": written,
        "forward": list(forward),
        "marker_forward": [round(v, 4) for v in marker_forward],
        "front_marker": FRONT_MARKER_NAME,
        "orientation": orientation,
        "FRONT_CAMERA_CORRECT": bool(orientation.get("front", {}).get("front_facing")),
    }
    (out_dir / fid / "orientation.json").write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps(payload))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
