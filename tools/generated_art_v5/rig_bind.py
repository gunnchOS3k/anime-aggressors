"""Bind lofted topology to the canonical 22-bone rig. No gameplay ID changes."""
from __future__ import annotations

import bpy
from mathutils import Vector


def bind_smooth(mesh_obj, arm_obj) -> dict:
    bpy.ops.object.select_all(action="DESELECT")
    mesh_obj.select_set(True)
    arm_obj.select_set(True)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    zero = 0
    bad_sum = 0
    total = len(mesh_obj.data.vertices)
    for vert in mesh_obj.data.vertices:
        wsum = sum(group.weight for group in vert.groups)
        if wsum <= 1e-5:
            zero += 1
        if abs(wsum - 1.0) > 0.15 and wsum > 0:
            bad_sum += 1
    return {
        "vertex_count": total,
        "zero_weight_vertices": zero,
        "unnormalized_vertices": bad_sum,
        "smooth_skinning": zero == 0,
    }


def bind_to_bone(obj, arm_obj, bone_name: str) -> None:
    bpy.ops.object.mode_set(mode="OBJECT")
    mw = obj.matrix_world.copy()
    obj.parent = arm_obj
    obj.parent_type = "BONE"
    obj.parent_bone = bone_name
    obj.matrix_world = mw


def add_corrective_shapes(mesh_obj) -> list[str]:
    """Lightweight generated correctives. Not human weight-paint."""
    if mesh_obj.data.shape_keys is None:
        mesh_obj.shape_key_add(name="Basis")
    names = []
    for name, axis, amount in (
        ("shoulder_raise", 2, 0.04),
        ("torso_twist", 0, 0.035),
        ("deep_crouch", 2, -0.03),
        ("heavy_hurt_bend", 1, -0.04),
        ("extreme_punch_reach", 1, 0.05),
    ):
        key = mesh_obj.shape_key_add(name=name)
        for vert in key.data:
            vert.co[axis] += amount
        names.append(name)
    return names


def bind_character(body, extras, arm_obj, bone_map: dict[str, str]) -> dict:
    weight = bind_smooth(body, arm_obj)
    correctives = add_corrective_shapes(body)
    for obj in extras:
        bone = bone_map.get(obj.name)
        if bone:
            bind_to_bone(obj, arm_obj, bone)
    return {"weight": weight, "correctives": correctives}


def default_bone_map(fid: str) -> dict[str, str]:
    mapping = {
        "head_shell": "Head",
        "hand_L": "Hand_L",
        "hand_R": "Hand_R",
        "boot_L": "Foot_L",
        "boot_R": "Foot_R",
        "torso_shell": "Chest",
        "coat_layer": "Chest",
        "gauntlet_r": "LowerArm_R",
        "gauntlet_l": "LowerArm_L",
        "forearm_plate_r": "LowerArm_R",
        "forearm_plate_l": "LowerArm_L",
        "glove_r": "LowerArm_R",
        "glove_l": "LowerArm_L",
        "heat_guard_r": "UpperLeg_R",
        "heat_guard_l": "UpperLeg_L",
        "thigh_shell_r": "UpperLeg_R",
        "thigh_shell_l": "UpperLeg_L",
        "shin_shell_r": "LowerLeg_R",
        "shin_shell_l": "LowerLeg_L",
        "shoulder_accent": "Shoulder_R",
        "shoulder_pad_l": "Shoulder_L",
        "shoulder_pad_r": "Shoulder_R",
        "belt_plate": "Hips",
        "back_plate": "Chest",
        "heat_vent": "Chest",
        "volt_panel_a": "Chest",
        "volt_panel_b": "Chest",
        "volt_sash": "Chest",
        "scarf_collar": "Neck",
        "scarf_fall": "Neck",
        "airfoil_l": "Shoulder_L",
        "airfoil_r": "Shoulder_R",
        "crystal_core": "Chest",
        "crystal_shoulder": "Shoulder_L",
        "authority_panel": "Chest",
        "orbit_trim": "Chest",
        "orbit_ring": "Chest",
        "coat_panel_l": "Hips",
        "coat_panel_r": "Hips",
        "coat_tail_l": "Hips",
        "coat_tail_r": "Hips",
        "void_trim": "Chest",
        "flame_tongue_r": "Hand_R",
        "flame_tongue_l": "Hand_L",
        "ribbon": "Head",
    }
    return mapping
