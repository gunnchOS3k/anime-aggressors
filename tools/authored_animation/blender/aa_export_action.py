"""Export one named action as deform-only GLB. Never marks approved."""
from __future__ import annotations

import json
import sys
from pathlib import Path

import bpy

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent))

from aa_canonical_skeleton import REQUIRED  # noqa: E402
from aa_export_glb import export_glb, hide_non_deform  # noqa: E402


def _argv() -> list[str]:
    if "--" in sys.argv:
        return sys.argv[sys.argv.index("--") + 1 :]
    return sys.argv[1:]


def _parse() -> dict:
    args = _argv()
    out: dict = {}
    i = 0
    while i < len(args):
        if args[i].startswith("--") and i + 1 < len(args) and not args[i + 1].startswith("--"):
            out[args[i][2:].replace("-", "_")] = args[i + 1]
            i += 2
        else:
            i += 1
    return out


def _armature():
    for obj in bpy.data.objects:
        if obj.type == "ARMATURE":
            return obj
    return None


def main() -> int:
    args = _parse()
    action_name = args.get("action", "")
    out_glb = Path(args.get("out_glb") or "/tmp/export.glb")
    report_path = Path(args.get("report") or "/tmp/export.json")
    fails = []
    arm = _armature()
    if arm is None:
        fails.append("no_armature")
    bones = [b.name for b in arm.data.bones] if arm else []
    missing = [b for b in REQUIRED if b not in bones]
    if missing:
        fails.append(f"missing_canonical_bones:{missing}")
    action = bpy.data.actions.get(action_name)
    if action is None:
        fails.append(f"action_missing:{action_name}")
    markers = {m.name: int(m.frame) for m in bpy.context.scene.timeline_markers}
    if action is not None:
        if arm.animation_data is None:
            arm.animation_data_create()
        arm.animation_data.action = action
        # Isolate one NLA clip named after the action.
        for track in list(arm.animation_data.nla_tracks):
            arm.animation_data.nla_tracks.remove(track)
        track = arm.animation_data.nla_tracks.new()
        track.name = action_name
        start = int(action.frame_range[0] if action.frame_range else 1)
        track.strips.new(action_name, start, action)
        bpy.context.scene.frame_start = int(action.frame_range[0] or 1)
        bpy.context.scene.frame_end = int(action.frame_range[1] or 24)
    if action is not None and int(action.frame_range[1] or 0) <= int(action.frame_range[0] or 0):
        fails.append("invalid_frame_range")
    if action_name and action is not None and action.name != action_name:
        fails.append("action_name_mismatch")
    if fails:
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(json.dumps({"ok": False, "failures": fails}, indent=2) + "\n")
        print(json.dumps({"ok": False, "failures": fails}))
        return 2
    hide_non_deform(arm)
    export_glb(bpy, out_glb, action_name)
    payload = {
        "ok": True,
        "action": action_name,
        "exported_glb": str(out_glb),
        "deform_bones": [b.name for b in arm.data.bones if b.use_deform],
        "markers": markers,
        "frame_range": [int(action.frame_range[0]), int(action.frame_range[1])],
        "keyframe_count": sum(len(fc.keyframe_points) for fc in action.fcurves) if action else 0,
        "status": "AUTHORED_WIP" if action and sum(len(fc.keyframe_points) for fc in action.fcurves) > 0 else "MISSING",
        "human_animation_approved": False,
        "not_final_art": True,
        "root_motion_authoritative": False,
    }
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps(payload, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
