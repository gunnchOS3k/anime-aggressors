#!/usr/bin/env python3
"""Blender adapter: KayKit CC0 GLB → contract-named candidate GLB."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import bpy


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


def _argv() -> list[str]:
    if "--" in sys.argv:
        return sys.argv[sys.argv.index("--") + 1 :]
    return sys.argv[1:]


def _clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in list(bpy.data.actions):
        bpy.data.actions.remove(block)
    for block in list(bpy.data.armatures):
        bpy.data.armatures.remove(block)
    for block in list(bpy.data.meshes):
        bpy.data.meshes.remove(block)
    for block in list(bpy.data.materials):
        bpy.data.materials.remove(block)
    for block in list(bpy.data.images):
        bpy.data.images.remove(block)


def _armature() -> bpy.types.Object | None:
    for obj in bpy.data.objects:
        if obj.type == "ARMATURE":
            return obj
    return None


def _rename_bones(arm: bpy.types.Object, mapping: dict[str, str]) -> dict[str, str]:
    renamed = {}
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.context.view_layer.objects.active = arm
    for bone in arm.data.bones:
        key = bone.name
        if key in mapping and bone.name != mapping[key]:
            new = mapping[key]
            renamed[key] = new
            bone.name = new
    return renamed


def _insert_contract_bones(arm: bpy.types.Object) -> list[str]:
    added = []
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm.data.edit_bones
    if "Chest" in eb and "Head" in eb and "Neck" not in eb:
        chest = eb["Chest"]
        head = eb["Head"]
        neck = eb.new("Neck")
        neck.head = chest.tail.copy()
        neck.tail = head.head.copy()
        if (neck.tail - neck.head).length < 0.01:
            neck.tail = neck.head.copy()
            neck.tail.z += 0.08
        neck.parent = chest
        head.parent = neck
        added.append("Neck")
    if "Chest" in eb and "UpperArm_L" in eb and "Shoulder_L" not in eb:
        chest = eb["Chest"]
        upper = eb["UpperArm_L"]
        shoulder = eb.new("Shoulder_L")
        shoulder.head = chest.head.copy()
        shoulder.tail = upper.head.copy()
        if (shoulder.tail - shoulder.head).length < 0.01:
            shoulder.tail = shoulder.head.copy()
            shoulder.tail.x += 0.08
        shoulder.parent = chest
        upper.parent = shoulder
        added.append("Shoulder_L")
    if "Chest" in eb and "UpperArm_R" in eb and "Shoulder_R" not in eb:
        chest = eb["Chest"]
        upper = eb["UpperArm_R"]
        shoulder = eb.new("Shoulder_R")
        shoulder.head = chest.head.copy()
        shoulder.tail = upper.head.copy()
        if (shoulder.tail - shoulder.head).length < 0.01:
            shoulder.tail = shoulder.head.copy()
            shoulder.tail.x -= 0.08
        shoulder.parent = chest
        upper.parent = shoulder
        added.append("Shoulder_R")
    bpy.ops.object.mode_set(mode="OBJECT")
    return added


def _add_sockets(arm: bpy.types.Object) -> list[str]:
    created = []
    for socket, parent_bone in SOCKETS.items():
        if socket in bpy.data.objects:
            continue
        empty = bpy.data.objects.new(socket, None)
        empty.empty_display_type = "PLAIN_AXES"
        empty.empty_display_size = 0.04
        bpy.context.collection.objects.link(empty)
        if parent_bone in arm.data.bones:
            empty.parent = arm
            empty.parent_type = "BONE"
            empty.parent_bone = parent_bone
        else:
            empty.parent = arm
        created.append(socket)
    return created


def _action_key(name: str) -> str:
    key = name.split("|")[-1]
    if key.endswith("_Rig"):
        key = key[: -len("_Rig")]
    if key.endswith("_Armature"):
        key = key[: -len("_Armature")]
    return key


def _clear_animation_users() -> None:
    for obj in bpy.data.objects:
        ad = obj.animation_data
        if ad is None:
            continue
        for track in list(ad.nla_tracks):
            ad.nla_tracks.remove(track)
        ad.action = None


def _keep_mapped_actions(clips: dict[str, str]) -> dict[str, str]:
    """Rename mapped actions to contract ids and delete the rest."""
    kept = {}
    source_to_target = {src: dst for dst, src in clips.items()}
    _clear_animation_users()
    for action in list(bpy.data.actions):
        original = action.name
        key = _action_key(original)
        match = source_to_target.get(key)
        if match is None and original in source_to_target:
            match = source_to_target[original]
        if match:
            if action.name != match:
                action.name = match
            action.use_fake_user = True
            kept[match] = original
        else:
            action.user_clear()
            bpy.data.actions.remove(action)
    arm = _armature()
    if arm is not None:
        if arm.animation_data is None:
            arm.animation_data_create()
        for name, action in [(a.name, a) for a in bpy.data.actions]:
            track = arm.animation_data.nla_tracks.new()
            track.name = name
            start = 1
            track.strips.new(name, start, action)
    return kept


def _tint_materials(rgba: list[float]) -> int:
    count = 0
    r, g, b, a = rgba
    for mat in bpy.data.materials:
        if not mat.use_nodes:
            mat.diffuse_color = (r, g, b, a)
            count += 1
            continue
        tinted = False
        for node in mat.node_tree.nodes:
            if node.type == "BSDF_PRINCIPLED":
                base = node.inputs.get("Base Color")
                if base:
                    if base.is_linked:
                        mix = mat.node_tree.nodes.new("ShaderNodeMixRGB")
                        mix.blend_type = "MULTIPLY"
                        mix.inputs["Fac"].default_value = 1.0
                        mix.inputs["Color2"].default_value = (r, g, b, a)
                        link = base.links[0] if base.links else None
                        from_socket = link.from_socket if link else None
                        if from_socket is not None:
                            mat.node_tree.links.new(from_socket, mix.inputs["Color1"])
                        mat.node_tree.links.new(mix.outputs["Color"], base)
                    else:
                        col = list(base.default_value)
                        base.default_value = (col[0] * r, col[1] * g, col[2] * b, col[3] * a)
                    tinted = True
        if tinted:
            count += 1
    return count


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--config", required=True)
    parser.add_argument("--fighter", required=True)
    args = parser.parse_args(_argv())

    config = json.loads(Path(args.config).read_text(encoding="utf-8"))
    fighter = config["fighters"][args.fighter]
    clips = fighter["clips"]
    tint = fighter.get("tint") or [1, 1, 1, 1]
    bone_map = config["bone_rename"]

    _clear_scene()
    bpy.ops.import_scene.gltf(filepath=args.input)
    arm = _armature()
    if arm is None:
        print(json.dumps({"ok": False, "error": "no_armature"}))
        return 1
    arm.name = "Armature"
    renamed = _rename_bones(arm, bone_map)
    added_bones = _insert_contract_bones(arm)
    sockets = _add_sockets(arm)
    kept = _keep_mapped_actions(clips)
    tinted = _tint_materials([float(x) for x in tint])

    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(out),
        export_format="GLB",
        export_animations=True,
        export_nla_strips=True,
        export_force_sampling=True,
        export_skins=True,
        export_morph=False,
        export_cameras=False,
        export_lights=False,
        export_extras=True,
        export_yup=True,
    )
    report = {
        "ok": out.is_file(),
        "fighter": args.fighter,
        "input": args.input,
        "output": str(out),
        "renamed_bones": renamed,
        "added_bones": added_bones,
        "sockets": sockets,
        "kept_actions": kept,
        "tinted_materials": tinted,
        "bytes": out.stat().st_size if out.is_file() else 0,
    }
    print(json.dumps(report))
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
