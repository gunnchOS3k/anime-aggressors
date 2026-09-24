"""Armature-owned costume bind. No loose world-space costume parenting."""
from __future__ import annotations

import bpy
from mathutils import Vector

from generated_art_v5.rig_bind import add_corrective_shapes, bind_smooth
from generated_art_v9.attachment_map import tag_object


def bone_world_anchor(arm_obj, bone_name: str) -> Vector:
    bone = arm_obj.pose.bones.get(bone_name) or arm_obj.data.bones.get(bone_name)
    if bone is None:
        return arm_obj.matrix_world.translation.copy()
    tail = getattr(bone, "tail", None)
    if tail is None:
        tail = bone.tail_local
    return arm_obj.matrix_world @ Vector(tail)


def bind_to_bone_rigid(obj, arm_obj, bone_name: str) -> dict:
    bpy.context.view_layer.update()
    mw = obj.matrix_world.copy()
    anchor = bone_world_anchor(arm_obj, bone_name)
    centroid = Vector(obj.matrix_world.translation)
    rest = (centroid - anchor).length
    obj.parent = None
    bpy.context.view_layer.update()
    obj.parent = arm_obj
    obj.parent_type = "BONE"
    obj.parent_bone = bone_name
    obj.matrix_world = mw
    bpy.context.view_layer.update()
    obj["aa_rest_anchor_distance"] = rest
    offset = [round(float(v), 4) for v in obj.location]
    obj["aa_local_offset"] = offset
    return {
        "name": obj.name,
        "class": str(obj.get("aa_attach_class") or ""),
        "bone": bone_name,
        "rest_anchor_distance": round(float(rest), 4),
        "local_offset": offset,
        "intentional_floating": bool(obj.get("aa_intentional_float")),
    }


def bind_skinned(obj, arm_obj) -> dict:
    info = bind_smooth(obj, arm_obj)
    obj["aa_attach_class"] = "SKINNED_COSTUME"
    return {"name": obj.name, "class": "SKINNED_COSTUME", "weight": info}


def bind_character_v8(body, extras, arm_obj) -> dict:
    weight = bind_smooth(body, arm_obj)
    correctives = add_corrective_shapes(body)
    records = []
    for obj in extras:
        if obj.get("aa_outline"):
            continue
        cls, bone, floating = tag_object(obj)
        if cls == "SKINNED_COSTUME":
            records.append(bind_skinned(obj, arm_obj))
        elif cls in {"BONE_RIGID", "SECONDARY_CHAIN", "VFX_ORBIT"}:
            records.append(bind_to_bone_rigid(obj, arm_obj, bone))
        else:
            raise ValueError(f"illegal attachment class for costume: {obj.name} {cls}")
    return {
        "weight": weight,
        "correctives": correctives,
        "attachments": records,
        "unintentional_floating": 0,
    }
