"""OpenGL review stills. Not a quality claim."""
from __future__ import annotations

import sys
from pathlib import Path

import bpy

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from aa_control_rig import export_pose_thumbnail  # noqa: E402


def _argv() -> list[str]:
    if "--" in sys.argv:
        return sys.argv[sys.argv.index("--") + 1 :]
    return sys.argv[1:]


def _parse() -> dict:
    args = _argv()
    out = {}
    i = 0
    while i < len(args):
        if args[i].startswith("--") and i + 1 < len(args):
            out[args[i][2:].replace("-", "_")] = args[i + 1]
            i += 2
        else:
            i += 1
    return out


def main() -> int:
    args = _parse()
    dest = Path(args.get("out_dir") or "/tmp/review")
    dest.mkdir(parents=True, exist_ok=True)
    action_name = args.get("action", "")
    action = bpy.data.actions.get(action_name)
    if action is not None:
        for obj in bpy.data.objects:
            if obj.type == "ARMATURE":
                if obj.animation_data is None:
                    obj.animation_data_create()
                obj.animation_data.action = action
    frames = {
        "front": 1,
        "side": 1,
        "gameplay_3q": 1,
        "silhouette": 1,
        "anticipation": max(1, int(bpy.context.scene.frame_start)),
        "contact": int(bpy.context.scene.frame_current or 1),
        "follow_through": int(bpy.context.scene.frame_end or 1),
        "passing_pose": 12,
        "contact_pose": 16,
        "extreme_pose": 20,
    }
    for name, frame in frames.items():
        bpy.context.scene.frame_set(int(frame))
        export_pose_thumbnail(bpy, str(dest / f"{name}.png"), 512)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
