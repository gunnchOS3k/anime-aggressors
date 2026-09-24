"""FK / IK control-rig tooling. Configures tools; does not author final acting.

Animator operators (no proprietary add-ons):
select rig, reset pose, mirror, copy/paste, FK/IK switch + snaps, foot roll,
hand/foot scale cheat, torso squash, shoulder overshoot, named actions,
frame range, contact/gameplay markers, stepped preview, pose thumbnail.
"""
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

_POSE_CLIPBOARD: dict[str, dict] = {}
_MIRROR = {
    "L": "R",
    "R": "L",
}


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
    # Extra animator properties on the armature.
    armature_obj["aa_stepped_preview"] = False
    armature_obj["aa_rig_ready"] = True
    return {
        "controls_created": created,
        "final_acting_authored": False,
        "note": "Tooling only. FK copy-rotation live. IK handles present, constraints off until animator enables them.",
        "operators": [
            "select_rig",
            "reset_pose",
            "mirror_pose",
            "copy_pose",
            "paste_pose",
            "set_ik_fk",
            "snap_fk_to_ik",
            "snap_ik_to_fk",
            "foot_roll",
            "scale_cheat",
            "torso_squash",
            "shoulder_overshoot",
            "create_named_action",
            "set_action_frame_range",
            "add_contact_marker",
            "add_gameplay_markers",
            "set_stepped_preview",
            "export_pose_thumbnail",
        ],
    }


def _active_armature(bpy: Any) -> Any:
    obj = bpy.context.object
    if obj is not None and obj.type == "ARMATURE":
        return obj
    for cand in bpy.context.selected_objects:
        if cand.type == "ARMATURE":
            return cand
    for cand in bpy.data.objects:
        if cand.type == "ARMATURE" and cand.get("aa_rig_ready"):
            return cand
    return None


def select_rig(bpy: Any) -> dict:
    arm = _active_armature(bpy)
    if arm is None:
        return {"ok": False, "reason": "no_armature"}
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="DESELECT")
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")
    return {"ok": True, "armature": arm.name}


def reset_pose(bpy: Any) -> dict:
    arm = _active_armature(bpy)
    if arm is None:
        return {"ok": False}
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.pose.select_all(action="SELECT")
    bpy.ops.pose.transforms_clear()
    return {"ok": True}


def _mirror_name(name: str) -> str:
    if name.endswith("_L"):
        return name[:-2] + "_R"
    if name.endswith("_R"):
        return name[:-2] + "_L"
    if "_L_" in name:
        return name.replace("_L_", "_R_")
    if "_R_" in name:
        return name.replace("_R_", "_L_")
    return name


def mirror_pose(bpy: Any) -> dict:
    arm = _active_armature(bpy)
    if arm is None:
        return {"ok": False}
    bpy.ops.object.mode_set(mode="POSE")
    snapshot = {}
    for pb in arm.pose.bones:
        snapshot[pb.name] = (
            tuple(pb.location),
            tuple(pb.rotation_euler),
            tuple(pb.scale),
        )
    for name, (loc, rot, scl) in snapshot.items():
        other = arm.pose.bones.get(_mirror_name(name))
        if other is None or other.name == name:
            continue
        other.location = (-loc[0], loc[1], loc[2])
        other.rotation_mode = "XYZ"
        other.rotation_euler = (rot[0], -rot[1], -rot[2])
        other.scale = scl
    return {"ok": True, "mirrored": True}


def copy_pose(bpy: Any) -> dict:
    arm = _active_armature(bpy)
    if arm is None:
        return {"ok": False}
    _POSE_CLIPBOARD.clear()
    for pb in arm.pose.bones:
        if pb.bone.select:
            _POSE_CLIPBOARD[pb.name] = {
                "location": tuple(pb.location),
                "rotation_euler": tuple(pb.rotation_euler),
                "scale": tuple(pb.scale),
            }
    return {"ok": True, "bones": list(_POSE_CLIPBOARD)}


def paste_pose(bpy: Any) -> dict:
    arm = _active_armature(bpy)
    if arm is None:
        return {"ok": False}
    for name, data in _POSE_CLIPBOARD.items():
        pb = arm.pose.bones.get(name)
        if pb is None:
            continue
        pb.location = data["location"]
        pb.rotation_mode = "XYZ"
        pb.rotation_euler = data["rotation_euler"]
        pb.scale = data["scale"]
    return {"ok": True, "bones": list(_POSE_CLIPBOARD)}


def set_ik_fk(bpy: Any, blend: float) -> dict:
    arm = _active_armature(bpy)
    if arm is None:
        return {"ok": False}
    for side in ("L", "R"):
        for name in (f"CTRL_IK_Hand_{side}", f"CTRL_IK_Foot_{side}"):
            pb = arm.pose.bones.get(name)
            if pb is not None:
                pb["ik_fk_blend"] = float(blend)
    return {"ok": True, "ik_fk_blend": float(blend)}


def snap_fk_to_ik(bpy: Any) -> dict:
    """Copy IK handle world matrix onto matching FK controls."""
    arm = _active_armature(bpy)
    if arm is None:
        return {"ok": False}
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")
    snapped = []
    pairs = (
        ("CTRL_IK_Hand_L", "CTRL_FK_Hand_L"),
        ("CTRL_IK_Hand_R", "CTRL_FK_Hand_R"),
        ("CTRL_IK_Foot_L", "CTRL_FK_Foot_L"),
        ("CTRL_IK_Foot_R", "CTRL_FK_Foot_R"),
    )
    for src_name, dst_name in pairs:
        src = arm.pose.bones.get(src_name)
        dst = arm.pose.bones.get(dst_name)
        if src is None or dst is None:
            continue
        dst.matrix = src.matrix.copy()
        snapped.append(dst_name)
    return {"ok": True, "snapped": snapped}


def snap_ik_to_fk(bpy: Any) -> dict:
    arm = _active_armature(bpy)
    if arm is None:
        return {"ok": False}
    bpy.ops.object.mode_set(mode="POSE")
    snapped = []
    pairs = (
        ("CTRL_FK_Hand_L", "CTRL_IK_Hand_L"),
        ("CTRL_FK_Hand_R", "CTRL_IK_Hand_R"),
        ("CTRL_FK_Foot_L", "CTRL_IK_Foot_L"),
        ("CTRL_FK_Foot_R", "CTRL_IK_Foot_R"),
    )
    for src_name, dst_name in pairs:
        src = arm.pose.bones.get(src_name)
        dst = arm.pose.bones.get(dst_name)
        if src is None or dst is None:
            continue
        dst.matrix = src.matrix.copy()
        snapped.append(dst_name)
    return {"ok": True, "snapped": snapped}


def foot_roll(bpy: Any, side: str, degrees: float) -> dict:
    arm = _active_armature(bpy)
    if arm is None:
        return {"ok": False}
    bone = arm.pose.bones.get(f"CTRL_IK_Foot_{side}") or arm.pose.bones.get(f"Foot_{side}")
    if bone is None:
        return {"ok": False, "reason": "missing_foot"}
    bone.rotation_mode = "XYZ"
    bone.rotation_euler[0] = float(degrees) * 0.017453292519943295
    return {"ok": True, "side": side, "degrees": float(degrees)}


def scale_cheat(bpy: Any, target: str, scale: float) -> dict:
    arm = _active_armature(bpy)
    if arm is None:
        return {"ok": False}
    pb = arm.pose.bones.get(target)
    if pb is None:
        return {"ok": False, "reason": "missing_bone"}
    pb.scale = (scale, scale, scale)
    return {"ok": True, "target": target, "scale": scale}


def torso_squash(bpy: Any, amount: float) -> dict:
    arm = _active_armature(bpy)
    if arm is None:
        return {"ok": False}
    spine = arm.pose.bones.get("CTRL_FK_Spine") or arm.pose.bones.get("Spine")
    chest = arm.pose.bones.get("CTRL_FK_Chest") or arm.pose.bones.get("Chest")
    if spine:
        spine.scale = (1.0 + amount * 0.15, 1.0 + amount * 0.15, 1.0 - amount * 0.25)
    if chest:
        chest.scale = (1.0 + amount * 0.10, 1.0 + amount * 0.10, 1.0 - amount * 0.18)
    return {"ok": True, "amount": amount}


def shoulder_overshoot(bpy: Any, side: str, amount: float) -> dict:
    arm = _active_armature(bpy)
    if arm is None:
        return {"ok": False}
    name = f"Shoulder_{side}"
    pb = arm.pose.bones.get(f"CTRL_FK_{name}") or arm.pose.bones.get(name)
    if pb is None:
        return {"ok": False}
    pb.rotation_mode = "XYZ"
    pb.rotation_euler[2] += float(amount)
    return {"ok": True, "side": side}


def create_named_action(bpy: Any, name: str, frame_start: int, frame_end: int) -> dict:
    arm = _active_armature(bpy)
    if arm is None:
        return {"ok": False}
    action = bpy.data.actions.get(name) or bpy.data.actions.new(name)
    action.use_fake_user = True
    if arm.animation_data is None:
        arm.animation_data_create()
    arm.animation_data.action = action
    action.frame_range = (frame_start, frame_end)
    bpy.context.scene.frame_start = int(frame_start)
    bpy.context.scene.frame_end = int(frame_end)
    return {"ok": True, "action": name, "frame_range": [frame_start, frame_end], "keys": 0}


def set_action_frame_range(bpy: Any, frame_start: int, frame_end: int) -> dict:
    bpy.context.scene.frame_start = int(frame_start)
    bpy.context.scene.frame_end = int(frame_end)
    arm = _active_armature(bpy)
    if arm and arm.animation_data and arm.animation_data.action:
        arm.animation_data.action.frame_range = (frame_start, frame_end)
    return {"ok": True, "frame_range": [frame_start, frame_end]}


def add_timeline_marker(bpy: Any, name: str, frame: int) -> dict:
    scene = bpy.context.scene
    existing = scene.timeline_markers.get(name)
    if existing:
        existing.frame = int(frame)
    else:
        scene.timeline_markers.new(name, frame=int(frame))
    return {"ok": True, "marker": name, "frame": int(frame)}


def add_contact_marker(bpy: Any, frame: int) -> dict:
    return add_timeline_marker(bpy, "AA_CONTACT", frame)


def add_gameplay_markers(bpy: Any, active_start: int, active_end: int, contact: int, extra: dict | None = None) -> dict:
    marks = [
        add_timeline_marker(bpy, "AA_ACTIVE_START", active_start),
        add_timeline_marker(bpy, "AA_ACTIVE_END", active_end),
        add_contact_marker(bpy, contact),
    ]
    if extra:
        for name, frame in extra.items():
            marks.append(add_timeline_marker(bpy, str(name), int(frame)))
    return {"ok": True, "markers": marks}


def set_stepped_preview(bpy: Any, enabled: bool) -> dict:
    interp = "CONSTANT" if enabled else "BEZIER"
    arm = _active_armature(bpy)
    if arm and arm.animation_data and arm.animation_data.action:
        for fcurve in arm.animation_data.action.fcurves:
            for kp in fcurve.keyframe_points:
                kp.interpolation = interp
    bpy.context.scene.render.fps = 60
    return {"ok": True, "stepped": enabled}


def export_pose_thumbnail(bpy: Any, dest: str, size: int = 256) -> dict:
    scene = bpy.context.scene
    scene.render.resolution_x = size
    scene.render.resolution_y = size
    scene.render.filepath = dest
    scene.render.image_settings.file_format = "PNG"
    bpy.ops.render.opengl(write_still=True)
    return {"ok": True, "path": dest, "not_human_quality": True}
