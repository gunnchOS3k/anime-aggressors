"""Build one v6 graphic fighter and export the runtime GLB. No voxel remesh."""
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

from generated_art_v5.joint_blends import apply_subdiv, assemble_body, connected_components, snap_to_ground  # noqa: E402
from generated_art_v5.limb_loft import build_limbs  # noqa: E402
from generated_art_v5.rig_bind import bind_character, bind_to_bone  # noqa: E402
from generated_art_v5.torso_loft import build_torso  # noqa: E402
from generated_art_v6.body_profiles import as_v5_body, style_profile  # noqa: E402
from generated_art_v6.boot_builder import build_boots  # noqa: E402
from generated_art_v6.cel_materials import assign, build_materials, paint_undersuit  # noqa: E402
from generated_art_v6.costume_masses import build_costume  # noqa: E402
from generated_art_v6.export_runtime import export_glb, report_payload  # noqa: E402
from generated_art_v6.glove_builder import build_gloves  # noqa: E402
from generated_art_v6.hero_poses import charge_100_v6, clash_lock_v6, hurt_heavy_v6, idle_v6, super_pose_v6  # noqa: E402
from generated_art_v6.mask_builder import build_mask  # noqa: E402
from generated_art_v6.outline import add_outline_hull  # noqa: E402
from generated_art_v6.rig_map import bone_map  # noqa: E402
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
from gp_body_v2 import _assign  # noqa: E402
from gp_body_v3 import _toon_mat_v3  # noqa: E402


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


def build_v6_fighter(fid: str, p, arm):
    bp = style_profile(fid)
    v5 = as_v5_body(bp)
    mats = build_materials(fid)
    torso, _rings = build_torso(v5, arm, f"{fid}.torso")
    limbs = build_limbs(v5, arm)
    body = assemble_body(torso, limbs, f"{fid}.mesh")
    apply_subdiv(body, 1)
    paint_undersuit(body, mats)
    head = build_mask(bp, arm)
    assign(head, mats["mask"])
    hands = build_gloves(bp, arm)
    for hand in hands:
        assign(hand, mats["glove"])
    boots = build_boots(bp, arm)
    for boot in boots:
        assign(boot, mats["boot"])
    costume = build_costume(bp, arm, mats)
    extras = [head] + hands + boots + costume
    outlines = []
    for src in extras + [body]:
        hull = add_outline_hull(src, mats["outline"], width=0.012)
        if hull is not None:
            outlines.append(hull)
    meshes = [body] + extras
    gap = snap_to_ground(meshes + outlines)
    bind_info = bind_character(body, extras, arm, bone_map(fid))
    paint_undersuit(body, mats)
    for hull in outlines:
        # Keep outline with the body so it does not fight gameplay LOD.
        hull.parent = body
    marker = bpy.data.objects.new("AA_FrontMarker", None)
    marker.empty_display_type = "ARROWS"
    marker.empty_display_size = 0.18
    chest = arm.data.bones["Chest"]
    mid = arm.matrix_world @ ((chest.head_local + chest.tail_local) * 0.5)
    marker.location = mid + Vector((0.0, 0.16, 0.0))
    marker["aa_forward"] = (0.0, 1.0, 0.0)
    bpy.context.collection.objects.link(marker)
    bind_to_bone(marker, arm, "Chest")
    keep = {body.name, marker.name, *[obj.name for obj in extras], *[obj.name for obj in outlines]}
    _purge_stray(keep)
    if any(mod.type == "REMESH" for obj in meshes for mod in obj.modifiers):
        raise RuntimeError("v6 must not use remesh modifiers")
    tris = sum(len(obj.data.polygons) for obj in meshes)
    return body, extras, {
        "construction": "profile_loft_no_voxel_remesh",
        "visible_style": "graphic_lowpoly_cel_combat",
        "used_voxel_remesh": False,
        "triangles": tris,
        "body_triangles": len(body.data.polygons),
        "body_connected_components": connected_components(body),
        "material_count": len({slot.material.name for obj in meshes for slot in obj.material_slots if slot.material}),
        "hand_parts": int(hands[0].get("aa_hand_parts") or 0),
        "boot_parts": int(boots[0].get("aa_boot_parts") or 0),
        "head_parts": int(head.get("aa_head_parts") or 0),
        "costume_parts": len(costume),
        "undersuit": True,
        "glove_thumb": True,
        "boot_sole": True,
        "outline_hulls": len(outlines),
        "foot_ground_gap_m": round(gap, 4),
        "weight": bind_info["weight"],
        "correctives": bind_info["correctives"],
        "head_style": bp.head_style,
        "boot_style": bp.boot_style,
        "glove_family": bp.glove_family,
        "hand_default": bp.hand_default,
        "costume_profile": bp.costume_profile,
    }


def _overlay_v6_hero_poses(fid: str, arm) -> None:
    overlays = {
        "idle": {1: idle_v6(fid)},
        "personality_idle": {8: idle_v6(fid)},
        "charged_idle": {12: charge_100_v6(fid)},
        "charge_full": {12: charge_100_v6(fid)},
        "hurt_heavy": {6: hurt_heavy_v6(fid).get("CONTACT")},
        "clash_lock": {12: clash_lock_v6(fid)},
        "signature_lane_finisher": {16: super_pose_v6(fid)},
        "aura_signature": {12: super_pose_v6(fid)},
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
    body, costume, geom = build_v6_fighter(fid, p, arm)
    _link(mesh_col, body)
    for obj in costume:
        _link(mesh_col, obj)
    sockets = add_sockets(arm)
    setup_review_camera()
    ground = bpy.data.objects.get("AA_RefGround")
    if ground is None:
        bpy.ops.mesh.primitive_plane_add(size=6.0, location=(0.0, 0.0, 0.0))
        ground = bpy.context.active_object
        ground.name = "AA_RefGround"
        _assign(ground, _toon_mat_v3("AA_Ground", (0.10, 0.10, 0.11), 0.0, 2, 0.04, 0.0, 0.92))
    actions = [] if skip_anim else apply_animations(fid, arm)
    if not skip_anim:
        _overlay_v6_hero_poses(fid, arm)
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
