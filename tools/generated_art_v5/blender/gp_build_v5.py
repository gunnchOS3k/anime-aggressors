"""Build one v5 lofted fighter and export the runtime GLB. No voxel remesh."""
from __future__ import annotations

import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent.parent))
sys.path.insert(0, str(ROOT / "tools"))
sys.path.insert(0, str(ROOT / "tools/generated_production_art/blender"))

from generated_art_v5.accessory_builder import build_accessories  # noqa: E402
from generated_art_v5.body_profiles import body_profile  # noqa: E402
from generated_art_v5.boot_builder import build_boots  # noqa: E402
from generated_art_v5.costume_builder import build_costume  # noqa: E402
from generated_art_v5.export_runtime import export_glb, report_payload  # noqa: E402
from generated_art_v5.hand_builder import build_hands  # noqa: E402
from generated_art_v5.head_builder import build_head  # noqa: E402
from generated_art_v5.joint_blends import assemble_body, connected_components, snap_to_ground  # noqa: E402
from generated_art_v5.limb_loft import build_limbs  # noqa: E402
from generated_art_v5.rig_bind import bind_character, bind_to_bone, default_bone_map  # noqa: E402
from generated_art_v5.torso_loft import build_torso  # noqa: E402
from generated_art_v5.hero_poses import clash_lock_v5, hurt_heavy_v5, idle_v5, charge_100_v5, super_pose_v5  # noqa: E402
from generated_art_v5.uv_material_builder import assign, build_materials, paint_body_regions  # noqa: E402
from generated_production_art.common import generated_model_glb, production_master_blend  # noqa: E402
from generated_production_art.profiles import profile  # noqa: E402

from gp_build_production_master import (  # noqa: E402
    _collection,
    _link,
    _parse,
    add_sockets,
    apply_animations,
    build_armature,
    setup_review_camera,
)
from gp_body_v3 import _toon_mat_v3  # noqa: E402
from gp_body_v2 import _assign  # noqa: E402


def _abs(path_like) -> Path:
    path = Path(path_like)
    if not path.is_absolute():
        path = ROOT / path
    return path.resolve()


def _purge_stray(keep: set[str]) -> None:
    for obj in list(bpy.data.objects):
        if obj.type != "MESH":
            continue
        if obj.name.startswith("AA_Ref") or obj.name in keep:
            continue
        bpy.data.objects.remove(obj, do_unlink=True)


def build_v5_fighter(fid: str, p, arm):
    bp = body_profile(fid)
    mats = build_materials(fid, p)
    torso, _rings = build_torso(bp, arm, f"{fid}.torso")
    limbs = build_limbs(bp, arm)
    body = assemble_body(torso, limbs, f"{fid}.mesh")
    paint_body_regions(body, arm, mats)
    head = build_head(bp, arm)
    assign(head, mats["hair"])
    hands = build_hands(bp, arm)
    for hand in hands:
        assign(hand, mats["accent"])
    boots = build_boots(bp, arm)
    for boot in boots:
        assign(boot, mats["armor"])
    costume = build_costume(bp, arm, mats)
    accessories = build_accessories(bp, arm, mats)
    extras = [head] + hands + boots + costume + accessories
    meshes = [body] + extras
    gap = snap_to_ground(meshes)
    bind_info = bind_character(body, extras, arm, default_bone_map(fid))
    marker = bpy.data.objects.new("AA_FrontMarker", None)
    marker.empty_display_type = "ARROWS"
    marker.empty_display_size = 0.18
    chest = arm.data.bones["Chest"]
    mid = arm.matrix_world @ ((chest.head_local + chest.tail_local) * 0.5)
    marker.location = mid + Vector((0.0, 0.16, 0.0))
    marker["aa_forward"] = (0.0, 1.0, 0.0)
    bpy.context.collection.objects.link(marker)
    bind_to_bone(marker, arm, "Chest")
    keep = {body.name, marker.name, *[obj.name for obj in extras]}
    _purge_stray(keep)
    if any(mod.type == "REMESH" for obj in meshes for mod in obj.modifiers):
        raise RuntimeError("v5 must not use remesh modifiers")
    tris = sum(len(obj.data.polygons) for obj in meshes)
    return body, extras, {
        "construction": "profile_loft_no_voxel_remesh",
        "used_voxel_remesh": False,
        "triangles": tris,
        "body_triangles": len(body.data.polygons),
        "body_connected_components": connected_components(body),
        "material_count": len({slot.material.name for obj in meshes for slot in obj.material_slots if slot.material}),
        "hand_parts": 5,
        "boot_parts": 4,
        "head_parts": 4,
        "costume_parts": len(costume),
        "foot_ground_gap_m": round(gap, 4),
        "weight": bind_info["weight"],
        "correctives": bind_info["correctives"],
        "head_style": bp.head_style,
        "boot_style": bp.boot_style,
        "hand_default": bp.hand_default,
        "costume_profile": bp.costume_profile,
    }


def _overlay_v5_hero_poses(fid: str, arm) -> None:
    overlays = {
        "idle": {1: idle_v5(fid)},
        "charged_idle": {12: charge_100_v5(fid)},
        "charge_full": {12: charge_100_v5(fid)},
        "hurt_heavy": {6: hurt_heavy_v5(fid).get("CONTACT")},
        "clash_lock": {12: clash_lock_v5(fid)},
        "signature_lane_finisher": {16: super_pose_v5(fid)},
        "aura_signature": {12: super_pose_v5(fid)},
    }
    bpy.ops.object.mode_set(mode="POSE")
    for action_name, frames in overlays.items():
        act = bpy.data.actions.get(action_name)
        if act is None:
            continue
        arm.animation_data_create()
        arm.animation_data.action = act
        for frame, pose in frames.items():
            if not pose:
                continue
            bpy.context.scene.frame_set(frame)
            for bone_name, rot in pose.items():
                pb = arm.pose.bones.get(bone_name)
                if pb is None:
                    continue
                pb.rotation_mode = "XYZ"
                pb.rotation_euler = rot
                pb.keyframe_insert(data_path="rotation_euler", frame=frame)
    bpy.ops.object.mode_set(mode="OBJECT")


def build(fid: str, out_blend: Path, out_glb: Path, skip_anim: bool) -> dict:
    p = profile(fid)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.render.fps = 60
    bpy.context.scene.unit_settings.system = "METRIC"
    export_col = _collection("AA_EXPORT")
    mesh_col = _collection("AA_MESH")
    arm, extras_bones = build_armature(fid, p)
    _link(export_col, arm)
    body, costume, geom = build_v5_fighter(fid, p, arm)
    _link(mesh_col, body)
    for obj in costume:
        _link(mesh_col, obj)
    sockets = add_sockets(arm)
    setup_review_camera()
    # Ground plane uses v3 toon so review lighting matches prior packets.
    ground = bpy.data.objects.get("AA_RefGround")
    if ground is None:
        bpy.ops.mesh.primitive_plane_add(size=6.0, location=(0.0, 0.0, 0.0))
        ground = bpy.context.active_object
        ground.name = "AA_RefGround"
        _assign(ground, _toon_mat_v3("AA_Ground", (0.10, 0.10, 0.11), 0.0, 2, 0.04, 0.0, 0.92))
    actions = [] if skip_anim else apply_animations(fid, arm)
    if not skip_anim:
        _overlay_v5_hero_poses(fid, arm)
    out_blend.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(out_blend))
    export_glb(out_glb)
    payload = report_payload(fid, out_blend, out_glb, geom)
    payload.update(
        {
            "bones": [b.name for b in arm.data.bones],
            "secondary_bones": extras_bones,
            "sockets": sockets,
            "actions": actions,
            "action_count": len(actions),
            "blender": bpy.app.version_string,
        }
    )
    return payload


def main() -> int:
    args = _parse()
    fid = args["fighter"]
    out_blend = _abs(args["out_blend"] or production_master_blend(fid))
    out_glb = _abs(args["out_glb"] or generated_model_glb(fid))
    report = build(fid, out_blend, out_glb, args.get("skip_anim") == "1")
    text = json.dumps(report, indent=2)
    if args.get("report"):
        Path(args["report"]).write_text(text + "\n")
    print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
