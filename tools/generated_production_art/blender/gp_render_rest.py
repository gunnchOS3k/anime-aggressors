"""Render the current scene rest pose for generator iteration."""
from __future__ import annotations

import sys
from pathlib import Path

import bpy
from mathutils import Vector


def _argv() -> list[str]:
    if "--" in sys.argv:
        return sys.argv[sys.argv.index("--") + 1 :]
    return sys.argv[1:]


def main() -> int:
    args = _argv()
    out = Path(args[args.index("--out") + 1] if "--out" in args else "/tmp/rest.png")
    cam = bpy.context.scene.camera
    if cam is None:
        for obj in bpy.data.objects:
            if obj.type == "CAMERA":
                cam = obj
                bpy.context.scene.camera = cam
                break
    if cam is not None:
        target = Vector((0.0, 0.0, 0.95))
        front = "--front" in args
        cam.location = Vector((2.15, 3.35 if front else -3.35, 1.25))
        cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
        if cam.data:
            cam.data.lens = 45
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 640
    scene.render.resolution_y = 800
    scene.render.image_settings.file_format = "PNG"
    out.parent.mkdir(parents=True, exist_ok=True)
    scene.render.filepath = str(out)
    bpy.ops.render.render(write_still=True)
    print(str(out))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
