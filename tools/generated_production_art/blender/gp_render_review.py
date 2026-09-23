"""Render generated production review stills and contact-sheet tiles."""
from __future__ import annotations

import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent.parent))

from generated_production_art.common import FIGHTER_IDS  # noqa: E402

SHOTS = (
    ("idle", 1),
    ("personality_idle", 16),
    ("walk", 8),
    ("run", 6),
    ("dash", 4),
    ("charged_idle", 12),
    ("heavy", 4),
    ("heavy", 11),
    ("heavy", 16),
    ("hurt_heavy", 6),
    ("signature_lane_burst", 14),
    ("signature_lane_finisher", 16),
    ("ko", 12),
)

SHOT_LABELS = (
    "idle",
    "personality_idle",
    "walk",
    "run",
    "dash",
    "charge_100",
    "heavy_anticipation",
    "heavy_contact",
    "heavy_follow",
    "hurt_heavy",
    "aura",
    "super",
    "ko",
)


def _argv() -> list[str]:
    if "--" in sys.argv:
        return sys.argv[sys.argv.index("--") + 1 :]
    return sys.argv[1:]


def _parse() -> dict:
    args = _argv()
    out = {"out_dir": "", "fighter": ""}
    i = 0
    while i < len(args):
        if args[i].startswith("--") and i + 1 < len(args):
            out[args[i][2:].replace("-", "_")] = args[i + 1]
            i += 2
        else:
            i += 1
    return out


def render_current(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 640
    scene.render.resolution_y = 800
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(path)
    scene.render.film_transparent = False
    bpy.ops.render.render(write_still=True)


def main() -> int:
    args = _parse()
    out_dir = Path(args["out_dir"])
    fid = args.get("fighter") or ""
    arm = None
    for obj in bpy.data.objects:
        if obj.type == "ARMATURE":
            arm = obj
            break
    if arm is None:
        print(json.dumps({"ok": False, "reason": "no_armature"}))
        return 1
    cam = bpy.context.scene.camera
    if cam is None:
        for obj in bpy.data.objects:
            if obj.type == "CAMERA":
                cam = obj
                bpy.context.scene.camera = cam
                break
    if cam is not None:
        target = Vector((0.0, 0.0, 0.95))
        cam.location = Vector((2.15, -3.35, 1.25))
        direction = target - cam.location
        cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
        if cam.data:
            cam.data.lens = 45
    written = []
    bpy.context.view_layer.objects.active = arm
    for (action, frame), label in zip(SHOTS, SHOT_LABELS):
        act = bpy.data.actions.get(action)
        if act is None:
            continue
        arm.animation_data_create()
        arm.animation_data.action = act
        bpy.context.scene.frame_set(frame)
        dest = out_dir / fid / f"{label}.png"
        render_current(dest)
        written.append(str(dest))
    print(json.dumps({"ok": True, "fighter": fid, "frames": written}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
