"""Create the canonical deform armature. Blender-only module."""
from __future__ import annotations

from typing import Any

REQUIRED = (
    "Root",
    "Hips",
    "Spine",
    "Chest",
    "Neck",
    "Head",
    "Shoulder_L",
    "UpperArm_L",
    "LowerArm_L",
    "Hand_L",
    "Shoulder_R",
    "UpperArm_R",
    "LowerArm_R",
    "Hand_R",
    "UpperLeg_L",
    "LowerLeg_L",
    "Foot_L",
    "Toes_L",
    "UpperLeg_R",
    "LowerLeg_R",
    "Foot_R",
    "Toes_R",
)

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

# Blender armature space: +Z up, +Y forward in our authoring (export flips to Godot +Y up).
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
    "Hand_L": ((0.54, 0.0, 0.94), (0.64, 0.0, 0.90)),
    "Shoulder_R": ((-0.06, 0.0, 1.36), (-0.16, 0.0, 1.36)),
    "UpperArm_R": ((-0.16, 0.0, 1.36), (-0.38, 0.0, 1.12)),
    "LowerArm_R": ((-0.38, 0.0, 1.12), (-0.54, 0.0, 0.94)),
    "Hand_R": ((-0.54, 0.0, 0.94), (-0.64, 0.0, 0.90)),
    "UpperLeg_L": ((0.10, 0.0, 0.92), (0.10, 0.0, 0.50)),
    "LowerLeg_L": ((0.10, 0.0, 0.50), (0.10, 0.0, 0.12)),
    "Foot_L": ((0.10, 0.0, 0.12), (0.10, 0.12, 0.04)),
    "Toes_L": ((0.10, 0.12, 0.04), (0.10, 0.20, 0.04)),
    "UpperLeg_R": ((-0.10, 0.0, 0.92), (-0.10, 0.0, 0.50)),
    "LowerLeg_R": ((-0.10, 0.0, 0.50), (-0.10, 0.0, 0.12)),
    "Foot_R": ((-0.10, 0.0, 0.12), (-0.10, 0.12, 0.04)),
    "Toes_R": ((-0.10, 0.12, 0.04), (-0.10, 0.20, 0.04)),
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


def build_deform_armature(bpy: Any, name: str = "AA_Deform") -> Any:
    arm = bpy.data.armatures.new(name)
    obj = bpy.data.objects.new(name, arm)
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    created = {}
    for bone_name in REQUIRED:
        eb = arm.edit_bones.new(bone_name)
        head, tail = REST[bone_name]
        eb.head = head
        eb.tail = tail
        eb.use_deform = True
        created[bone_name] = eb
    for bone_name, parent in PARENT.items():
        if parent:
            created[bone_name].parent = created[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    return obj


def attach_sockets(bpy: Any, armature_obj: Any) -> list[Any]:
    empties = []
    for sock, parent in SOCKETS.items():
        empty = bpy.data.objects.new(sock, None)
        empty.empty_display_type = "PLAIN_AXES"
        empty.empty_display_size = 0.05
        bpy.context.collection.objects.link(empty)
        empty.parent = armature_obj
        empty.parent_type = "BONE"
        empty.parent_bone = parent
        empties.append(empty)
    return empties


def build_skinned_proxy(bpy: Any, armature_obj: Any, color: tuple[float, float, float]) -> Any:
    """Simple skinned capsule so the export has real mesh weights, not an empty armature."""
    bpy.ops.mesh.primitive_cylinder_add(radius=0.18, depth=1.55, location=(0.0, 0.0, 0.90))
    mesh_obj = bpy.context.active_object
    mesh_obj.name = "AA_ProxyMesh"
    mat = bpy.data.materials.new("AA_ProxyMat")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (color[0], color[1], color[2], 1.0)
    mesh_obj.data.materials.append(mat)
    mod = mesh_obj.modifiers.new("AA_Armature", "ARMATURE")
    mod.object = armature_obj
    # Weight by height bands so limbs actually deform.
    vg_map = {
        "Hips": (0.80, 1.00),
        "Spine": (1.00, 1.18),
        "Chest": (1.18, 1.40),
        "Head": (1.45, 1.80),
        "UpperArm_L": (1.10, 1.40),
        "UpperArm_R": (1.10, 1.40),
        "UpperLeg_L": (0.40, 0.90),
        "UpperLeg_R": (0.40, 0.90),
    }
    for bone, (z0, z1) in vg_map.items():
        vg = mesh_obj.vertex_groups.new(name=bone)
        idxs = [v.index for v in mesh_obj.data.vertices if z0 <= v.co.z + 0.90 <= z1]
        if idxs:
            vg.add(idxs, 1.0, "REPLACE")
    if not mesh_obj.vertex_groups:
        vg = mesh_obj.vertex_groups.new(name="Hips")
        vg.add([v.index for v in mesh_obj.data.vertices], 1.0, "REPLACE")
    mesh_obj.parent = armature_obj
    return mesh_obj
