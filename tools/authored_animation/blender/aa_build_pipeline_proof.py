"""Build canonical rig + pose-block pipeline_proof action + export GLB.

Honest label: AUTHORED_WIP pose-block for import-path proof. Not final acting.
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import bpy

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

from aa_canonical_skeleton import build_deform_armature, attach_sockets, build_skinned_proxy  # noqa: E402
from aa_control_rig import configure_control_rig  # noqa: E402
from aa_export_glb import hide_non_deform, export_glb  # noqa: E402

FIGHTERS = {
    "ember-vale": {
        "color": (0.92, 0.38, 0.12),
        "pose": {
            "Chest": (0.18, 0.06, 0.04),
            "UpperArm_R": (-0.55, -0.20, 0.35),
            "UpperArm_L": (-0.40, 0.22, -0.28),
            "UpperLeg_R": (0.12, 0.0, 0.18),
            "UpperLeg_L": (0.08, 0.0, -0.16),
        },
    },
    "rook-ironside": {
        "color": (0.45, 0.42, 0.38),
        "pose": {
            "Chest": (-0.06, 0.0, 0.10),
            "UpperArm_R": (0.35, -0.45, 0.12),
            "UpperArm_L": (0.32, 0.42, -0.12),
            "UpperLeg_R": (0.18, 0.0, 0.28),
            "UpperLeg_L": (0.18, 0.0, -0.28),
        },
    },
    "juno-spark": {
        "color": (0.95, 0.86, 0.20),
        "pose": {
            "Chest": (0.04, -0.18, 0.02),
            "UpperArm_R": (-0.85, -0.10, 0.55),
            "UpperArm_L": (0.15, 0.35, -0.20),
            "UpperLeg_R": (0.05, 0.0, 0.10),
            "UpperLeg_L": (0.22, 0.0, -0.12),
        },
    },
    "kaia-windrow": {
        "color": (0.35, 0.72, 0.55),
        "pose": {
            "Chest": (0.22, 0.12, -0.08),
            "Spine": (0.10, 0.08, 0.0),
            "UpperArm_R": (-0.25, -0.55, 0.40),
            "UpperArm_L": (-0.30, 0.60, -0.35),
            "UpperLeg_R": (0.06, 0.0, 0.22),
            "UpperLeg_L": (-0.04, 0.0, -0.20),
        },
    },
    "nix-calder": {
        "color": (0.55, 0.78, 0.92),
        "pose": {
            "Chest": (-0.04, 0.02, 0.0),
            "UpperArm_R": (0.20, -0.28, 0.08),
            "UpperArm_L": (0.20, 0.28, -0.08),
            "UpperLeg_R": (0.04, 0.0, 0.08),
            "UpperLeg_L": (0.04, 0.0, -0.08),
        },
    },
    "orion-vell": {
        "color": (0.42, 0.28, 0.62),
        "pose": {
            "Spine": (0.16, 0.0, 0.06),
            "Chest": (0.10, 0.0, 0.08),
            "UpperArm_R": (0.28, -0.30, 0.16),
            "UpperArm_L": (0.28, 0.30, -0.16),
            "UpperLeg_R": (0.20, 0.0, 0.16),
            "UpperLeg_L": (0.20, 0.0, -0.16),
        },
    },
    "vesper-nyx": {
        "color": (0.28, 0.10, 0.38),
        "pose": {
            "Chest": (0.08, 0.22, 0.12),
            "Head": (0.0, 0.18, 0.06),
            "UpperArm_R": (-0.15, -0.70, 0.45),
            "UpperArm_L": (0.40, 0.15, -0.10),
            "UpperLeg_R": (0.10, 0.08, 0.20),
            "UpperLeg_L": (0.02, -0.06, -0.10),
        },
    },
}


def _argv() -> list[str]:
    if "--" in sys.argv:
        return sys.argv[sys.argv.index("--") + 1 :]
    return sys.argv[1:]


def _parse() -> dict:
    args = _argv()
    out = {"fighter": "ember-vale", "out_glb": "", "out_blend": "", "report": ""}
    i = 0
    while i < len(args):
        if args[i] in out and i + 1 < len(args):
            out[args[i].lstrip("-").replace("-", "_") if False else args[i][2:].replace("-", "_")] = args[i + 1]
            i += 2
            continue
        if args[i].startswith("--"):
            key = args[i][2:].replace("-", "_")
            if i + 1 < len(args) and not args[i + 1].startswith("--"):
                out[key] = args[i + 1]
                i += 2
                continue
        i += 1
    return out


def _clear_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def _key_pose(arm_obj, pose: dict, frame: int, scale: float = 1.0) -> None:
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode="POSE")
    for bone_name, euler in pose.items():
        pb = arm_obj.pose.bones.get(bone_name)
        if pb is None:
            continue
        pb.rotation_mode = "XYZ"
        pb.rotation_euler = (euler[0] * scale, euler[1] * scale, euler[2] * scale)
        pb.keyframe_insert(data_path="rotation_euler", frame=frame)
    bpy.ops.object.mode_set(mode="OBJECT")


def build_one(fid: str, out_glb: Path, out_blend: Path | None) -> dict:
    spec = FIGHTERS[fid]
    _clear_scene()
    arm = build_deform_armature(bpy, "AA_Deform")
    attach_sockets(bpy, arm)
    build_skinned_proxy(bpy, arm, spec["color"])
    rig_info = configure_control_rig(bpy, arm)

    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")
    action = bpy.data.actions.new("pipeline_proof")
    if arm.animation_data is None:
        arm.animation_data_create()
    arm.animation_data.action = action
    # NLA strip name survives glTF export (Blender 3.3 otherwise names it "Animation").
    track = arm.animation_data.nla_tracks.new()
    track.name = "pipeline_proof"
    track.strips.new("pipeline_proof", 1, action)
    bpy.ops.object.mode_set(mode="OBJECT")

    # Pose-block: rest → identity pose → rest. Not final acting.
    _key_pose(arm, spec["pose"], 1, 0.0)
    _key_pose(arm, spec["pose"], 20, 1.0)
    _key_pose(arm, spec["pose"], 40, 0.35)
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = 40
    bpy.context.scene.render.fps = 60

    hide_non_deform(arm)
    export_glb(bpy, out_glb, "pipeline_proof")
    if out_blend:
        out_blend.parent.mkdir(parents=True, exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=str(out_blend))

    bones = [b.name for b in arm.data.bones if b.use_deform]
    return {
        "fighter_id": fid,
        "action": "pipeline_proof",
        "status": "AUTHORED_WIP",
        "not_final_art": True,
        "human_approved": False,
        "kind": "blender_glb_export_pose_block",
        "export_glb": str(out_glb),
        "export_blend": str(out_blend) if out_blend else None,
        "deform_bones": bones,
        "control_rig": rig_info,
        "frame_range": [1, 40],
        "fps": 60,
        "visual_root_motion": False,
        "final_acting": False,
    }


def main() -> int:
    args = _parse()
    fid = args.get("fighter", "ember-vale")
    if fid not in FIGHTERS:
        print("unknown fighter", fid, file=sys.stderr)
        return 2
    out_glb = Path(args.get("out_glb") or f"/tmp/{fid}_pipeline_proof.glb")
    blend_arg = args.get("out_blend") or ""
    out_blend = Path(blend_arg) if blend_arg else None
    report = build_one(fid, out_glb, out_blend)
    text = json.dumps(report, indent=2)
    if args.get("report"):
        p = Path(args["report"])
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text + "\n")
    print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
