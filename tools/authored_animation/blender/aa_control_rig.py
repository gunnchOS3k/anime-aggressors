"""FK / IK control-rig tooling. Configures tools; does not author final acting."""
from __future__ import annotations

from typing import Any

FK_TARGETS = (
    "Hips",
    "Spine",
    "Chest",
    "Neck",
    "Head",
    "UpperArm_L",
    "LowerArm_L",
    "Hand_L",
    "UpperArm_R",
    "LowerArm_R",
    "Hand_R",
    "UpperLeg_L",
    "LowerLeg_L",
    "Foot_L",
    "UpperLeg_R",
    "LowerLeg_R",
    "Foot_R",
)


def configure_control_rig(bpy: Any, armature_obj: Any) -> dict:
    """Add CTRL_FK bones + copy-rotation constraints. IK stubs with ik_fk_blend."""
    arm = armature_obj.data
    bpy.context.view_layer.objects.active = armature_obj
    armature_obj.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    created = []
    for tgt in FK_TARGETS:
        src = arm.edit_bones.get(tgt)
        if src is None:
            continue
        name = f"CTRL_FK_{tgt}"
        if arm.edit_bones.get(name):
            continue
        eb = arm.edit_bones.new(name)
        eb.head = src.head.copy()
        eb.tail = src.tail.copy()
        eb.use_deform = False
        # Parent controls to Root, not the deform chain — avoids IK/FK cycles.
        root = arm.edit_bones.get("Root")
        if root is not None:
            eb.parent = root
        created.append(name)
    # IK handles
    for side in ("L", "R"):
        hand = arm.edit_bones.get(f"Hand_{side}")
        foot = arm.edit_bones.get(f"Foot_{side}")
        if hand and not arm.edit_bones.get(f"CTRL_IK_Hand_{side}"):
            ik = arm.edit_bones.new(f"CTRL_IK_Hand_{side}")
            ik.head = hand.tail.copy()
            ik.tail = (hand.tail.x, hand.tail.y + 0.08, hand.tail.z)
            ik.use_deform = False
            created.append(ik.name)
        if foot and not arm.edit_bones.get(f"CTRL_IK_Foot_{side}"):
            ik = arm.edit_bones.new(f"CTRL_IK_Foot_{side}")
            ik.head = foot.head.copy()
            ik.tail = (foot.head.x, foot.head.y + 0.10, foot.head.z)
            ik.use_deform = False
            created.append(ik.name)
        if hand and not arm.edit_bones.get(f"CTRL_PV_Elbow_{side}"):
            pv = arm.edit_bones.new(f"CTRL_PV_Elbow_{side}")
            mid = (hand.head + arm.edit_bones[f"UpperArm_{side}"].head) * 0.5
            pv.head = (mid.x, mid.y + 0.25, mid.z)
            pv.tail = (mid.x, mid.y + 0.35, mid.z)
            pv.use_deform = False
            created.append(pv.name)
    bpy.ops.object.mode_set(mode="POSE")
    for tgt in FK_TARGETS:
        pb = armature_obj.pose.bones.get(tgt)
        ctrl = armature_obj.pose.bones.get(f"CTRL_FK_{tgt}")
        if pb is None or ctrl is None:
            continue
        if "AA_FK_COPY" in pb.constraints:
            continue
        con = pb.constraints.new("COPY_ROTATION")
        con.name = "AA_FK_COPY"
        con.target = armature_obj
        con.subtarget = ctrl.name
        con.mix_mode = "REPLACE"
        con.target_space = "LOCAL"
        con.owner_space = "LOCAL"
    # IK handles exist as tooling. Constraints are left for the animator to enable
    # so FK copy-rotation and IK solvers do not form a dependency cycle.
    for side in ("L", "R"):
        for name in (f"CTRL_IK_Hand_{side}", f"CTRL_IK_Foot_{side}"):
            pb = armature_obj.pose.bones.get(name)
            if pb is not None:
                pb["ik_fk_blend"] = 0.0
    bpy.ops.object.mode_set(mode="OBJECT")
    return {
        "controls_created": created,
        "final_acting_authored": False,
        "note": "Tooling only. FK copy-rotation live. IK handles present, constraints off until animator enables them.",
    }
