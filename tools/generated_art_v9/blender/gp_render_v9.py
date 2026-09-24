"""Render generated-art v9 review packet with contact solver and attachment stress."""
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
sys.path.insert(0, str(ROOT / "tools"))

from generated_art_v6.outline import set_outlines_visible  # noqa: E402
from generated_art_v9.body_profiles import FIGHTER_IDS  # noqa: E402
from generated_art_v9.cameras import combat_preset_for, composition_score, frame_pair, frame_subject, mesh_bounds  # noqa: E402
from generated_art_v9.cel_materials import apply_review_color_management, assign, build_materials, mute_emission  # noqa: E402
from generated_art_v9.hero_poses import pose_v9  # noqa: E402
from generated_art_v9.impact_pair_solver import contact_spec, solve_from_armatures  # noqa: E402
from generated_art_v9.pair_scenes import defender_for, pair_offsets  # noqa: E402
from generated_art_v9.render_review import PACKET, STRESS_SHOTS  # noqa: E402
from generated_production_art.common import production_master_blend  # noqa: E402
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
        if obj.type == "ARMATURE" and not obj.name.startswith("AA_Def_"):
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
            if obj.name in cache and obj.name != "__world__":
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
    apply_review_color_management(scene)
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


def _apply_pose(arm, pose: dict) -> None:
    bpy.context.view_layer.objects.active = arm
    for bone_name, rot in pose.items():
        if bone_name.startswith("loc:"):
            pb = arm.pose.bones.get(bone_name.split(":", 1)[1])
            if pb is None:
                continue
            pb.location = rot
            continue
        pb = arm.pose.bones.get(bone_name)
        if pb is None:
            continue
        pb.rotation_mode = "XYZ"
        pb.rotation_euler = rot


def _clear_pair(tagged: list[str], attacker) -> None:
    _set_pair_visible(tagged, False)
    if attacker is not None:
        attacker.location = (0.0, 0.0, 0.0)
        attacker.rotation_euler = (0.0, 0.0, 0.0)


def _vfx_burst(enable: bool, cache: list, loc=(0.0, 0.22, 1.12)) -> None:
    if enable:
        cache.clear()
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.07, location=loc)
        burst = bpy.context.active_object
        burst.name = "AA_ContactVFX"
        mat = bpy.data.materials.new("AA_ContactVFX")
        mat.use_nodes = True
        nt = mat.node_tree
        nt.nodes.clear()
        out = nt.nodes.new("ShaderNodeOutputMaterial")
        emit = nt.nodes.new("ShaderNodeEmission")
        emit.inputs["Color"].default_value = (1.0, 0.92, 0.55, 1.0)
        emit.inputs["Strength"].default_value = 1.6
        nt.links.new(emit.outputs["Emission"], out.inputs["Surface"])
        if burst.data.materials:
            burst.data.materials[0] = mat
        else:
            burst.data.materials.append(mat)
        cache.append(burst.name)
    else:
        for name in cache:
            obj = bpy.data.objects.get(name)
            if obj is not None:
                bpy.data.objects.remove(obj, do_unlink=True)
        cache.clear()


_DEFENDER_CACHE: dict[str, list[str]] = {}
_CONTACT_ROWS: dict[str, dict] = {}


def _hide_imported_cameras(names: list[str]) -> None:
    for name in names:
        obj = bpy.data.objects.get(name)
        if obj is None:
            continue
        if obj.type in {"CAMERA", "LIGHT"}:
            obj.hide_render = True
            obj.hide_viewport = True


def _ensure_defender(fid: str) -> list[str]:
    if fid in _DEFENDER_CACHE:
        return _DEFENDER_CACHE[fid]
    defender_id = defender_for(fid)
    blend = production_master_blend(defender_id)
    tagged = []
    if blend.is_file():
        with bpy.data.libraries.load(str(blend), link=False) as (data_from, data_to):
            data_to.objects = list(data_from.objects)
        for obj in data_to.objects:
            if obj is None:
                continue
            skip = obj.type in {"CAMERA", "LIGHT"} or obj.name.startswith("AA_Ref") or "FrontMarker" in obj.name
            if skip:
                bpy.data.objects.remove(obj, do_unlink=True)
                continue
            try:
                bpy.context.collection.objects.link(obj)
            except RuntimeError:
                pass
            obj.name = f"AA_Def_{obj.name}"[:60]
            tagged.append(obj.name)
            if obj.type == "MESH" and (obj.name.lower().endswith("_open") or obj.name.lower().endswith("_guard") or obj.name.lower().endswith("_cast")):
                obj.hide_render = True
                obj.hide_viewport = True
        _hide_imported_cameras(tagged)
    _DEFENDER_CACHE[fid] = tagged
    return tagged


def _set_pair_visible(names: list[str], visible: bool) -> None:
    for name in names:
        obj = bpy.data.objects.get(name)
        if obj is None or obj.type in {"CAMERA", "LIGHT"}:
            continue
        obj.hide_render = not visible
        obj.hide_viewport = not visible


def _set_glove_variant(aim: str) -> None:
    show_open = aim == "glove_open"
    show_guard = aim == "glove_guard"
    show_cast = aim == "glove_cast"
    for obj in bpy.data.objects:
        if obj.type != "MESH":
            continue
        lowered = obj.name.lower()
        if lowered.startswith("hand_") and lowered.endswith("_open"):
            obj.hide_render = not show_open
            obj.hide_viewport = not show_open
        elif lowered.startswith("hand_") and lowered.endswith("_guard"):
            obj.hide_render = not show_guard
            obj.hide_viewport = not show_guard
        elif lowered.startswith("hand_") and lowered.endswith("_cast"):
            obj.hide_render = not show_cast
            obj.hide_viewport = not show_cast
        elif lowered in {"hand_l", "hand_r"}:
            hide = show_open or show_guard or show_cast
            obj.hide_render = hide
            obj.hide_viewport = hide


def _stage_pair(fid: str, attacker, label: str) -> tuple[list[str], dict]:
    tagged = _ensure_defender(fid)
    ax, dx = pair_offsets()
    attacker.location = (ax, 0.0, 0.0)
    attacker.rotation_euler = (0.0, 0.0, math.radians(90.0))
    _set_pair_visible(tagged, True)
    defender_id = defender_for(fid)
    def_arm = next((bpy.data.objects.get(name) for name in tagged if (bpy.data.objects.get(name) and bpy.data.objects.get(name).type == "ARMATURE")), None)
    contact = {}
    if def_arm is not None:
        def_arm.location = (dx, 0.0, 0.0)
        def_arm.rotation_euler = (0.0, 0.0, math.radians(-90.0))
        hurt = "hurt_peak" if "heavy" in label or "hurt" in label else "clash_lock"
        if label == "clash_lose":
            hurt = "clash_lose"
        if label == "clash_win":
            hurt = "clash_lock"
        if label == "clash_start":
            hurt = "clash_start"
        if label == "clash_push":
            hurt = "clash_push"
        if label in {"heavy_anticipation", "heavy_anticipation_pair"}:
            hurt = "hurt_pre"
        if label in {"heavy_follow", "follow_through"}:
            hurt = "launch"
        if label == "heavy_precontact":
            hurt = "hurt_pre"
        _apply_pose(def_arm, pose_v9(defender_id, hurt))
        spec = contact_spec(fid)
        contact = solve_from_armatures(
            attacker,
            def_arm,
            spec["socket"],
            spec["anchor"],
            tuple(spec.get("normal") or (1.0, 0.0, 0.0)),
            fid=fid,
        )
        contact["composition"] = composition_score(contact)
        _CONTACT_ROWS[label] = contact
    marker = bpy.data.objects.get("AA_ContactMarker")
    if marker is None:
        marker = bpy.data.objects.new("AA_ContactMarker", None)
        marker.empty_display_type = "SPHERE"
        marker.empty_display_size = 0.06
        bpy.context.collection.objects.link(marker)
        tagged.append(marker.name)
    if contact.get("attacker_socket_world"):
        marker.location = Vector(contact["attacker_socket_world"])
    else:
        marker.location = (0.0, 0.18, 1.10)
    marker.hide_render = "debug" not in label
    bpy.context.view_layer.update()
    return tagged, contact


def main() -> int:
    args = _parse()
    out_dir = Path(args["out_dir"])
    fid = args.get("fighter") or ""
    arm = _find_arm()
    if arm is None:
        print(json.dumps({"ok": False, "reason": "no_armature"}))
        return 1
    apply_review_color_management()
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
    emit_cache = {}
    vfx_cache = []
    orientation = {}
    camera_meta = {}
    (out_dir / fid).mkdir(parents=True, exist_ok=True)
    for label, action, frame, preset_name, sil, gray, outline, aim, pair, vfx, emission_off in PACKET:
        tagged = []
        contact = {}
        if action:
            arm.data.pose_position = "POSE"
            _set_action(arm, action, frame)
        else:
            if arm.animation_data:
                arm.animation_data.action = None
            arm.data.pose_position = "REST"
            bpy.context.scene.frame_set(1)
            bpy.context.view_layer.update()
        _set_glove_variant(aim)
        if pair:
            tagged, contact = _stage_pair(fid, arm, label)
            loc, target, lens, ortho = frame_pair(contact=contact, preset=combat_preset_for(fid, label))
        elif aim in {"glove", "glove_open", "glove_guard", "glove_cast", "boot", "head", "costume"}:
            cam_aim = "glove" if aim.startswith("glove") else aim
            loc, target, lens, ortho = frame_subject(cam_aim, preset_name, forward)
        else:
            preset = PRESETS[preset_name]
            loc = camera_location(preset, forward)
            target = camera_look_at(preset)
            lens, ortho = preset.lens, (2.4 if preset.ortho else 0.0)
        if cam is not None:
            _aim(cam, loc, target)
            if cam.data:
                cam.data.lens = lens
                if hasattr(cam.data, "type"):
                    cam.data.type = "ORTHO" if ortho else "PERSP"
                    if ortho:
                        cam.data.ortho_scale = ortho if ortho > 1.0 else 2.6
        set_outlines_visible(bool(outline))
        if sil:
            _blackout(True, sil_cache)
        if gray:
            _grayscale(True, gray_cache)
        if emission_off:
            mute_emission(True, emit_cache)
        if vfx:
            loc_vfx = tuple(contact.get("attacker_socket_world") or (0.0, 0.22, 1.12))
            _vfx_burst(True, vfx_cache, loc_vfx)
        scale = 0.72 if label in {"gameplay_scale", "gameplay_color", "gameplay_grayscale"} else 1.0
        dest = out_dir / fid / f"{label}.png"
        render_current(dest, scale)
        written.append(str(dest))
        if aim.startswith("glove") or aim in {"boot", "head"}:
            camera_meta[label] = {
                "aim": aim,
                "location": [round(v, 4) for v in loc],
                "bounds": bool(mesh_bounds(("hand_r",) if "glove" in aim else (("boot_r",) if aim == "boot" else ("head_shell",)))),
            }
        if label in {"front", "front_3q", "back"}:
            orientation[label] = {
                "preset": preset_name,
                "location": [round(v, 4) for v in loc],
                "forward": [round(v, 4) for v in forward],
                "front_facing": front_facing_ok(loc, forward),
                "back_facing": back_facing_ok(loc, forward),
                "three_q": three_q_ok(loc, forward),
            }
        if vfx:
            _vfx_burst(False, vfx_cache)
        if emission_off:
            mute_emission(False, emit_cache)
        if sil:
            _blackout(False, sil_cache)
        if gray:
            _grayscale(False, gray_cache)
        if pair:
            _clear_pair(tagged, arm)
        _set_glove_variant("")
        set_outlines_visible(False)
    stress_dir = out_dir / "attachment_stress" / fid
    stress_dir.mkdir(parents=True, exist_ok=True)
    for stress_label, action, frame in STRESS_SHOTS:
        arm.data.pose_position = "POSE"
        _set_action(arm, action, frame)
        preset = PRESETS["FRONT_3Q"]
        loc = camera_location(preset, forward)
        target = camera_look_at(preset)
        if cam is not None:
            _aim(cam, loc, target)
        dest = stress_dir / f"{stress_label}.png"
        render_current(dest)
        written.append(str(dest))
    payload = {
        "ok": True,
        "fighter": fid,
        "packet": written,
        "forward": list(forward),
        "marker_forward": [round(v, 4) for v in marker_forward],
        "front_marker": FRONT_MARKER_NAME,
        "orientation": orientation,
        "camera_meta": camera_meta,
        "defender": defender_for(fid) if fid in FIGHTER_IDS else "",
        "contact": _CONTACT_ROWS,
        "FRONT_CAMERA_CORRECT": bool(orientation.get("front", {}).get("front_facing")),
    }
    (out_dir / fid / "orientation.json").write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps(payload))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
