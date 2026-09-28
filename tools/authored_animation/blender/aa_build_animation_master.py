"""Build a ready-to-animate master .blend per fighter.

Creates empty/WIP action slots and markers. Does not fabricate acting.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import bpy

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent))

from aa_canonical_skeleton import attach_sockets, build_deform_armature, build_skinned_proxy  # noqa: E402
from aa_control_rig import (  # noqa: E402
    add_gameplay_markers,
    configure_control_rig,
    create_named_action,
    reset_pose,
)
from aa_common import PRODUCTION_ACTIONS, frame_window  # noqa: E402

COLORS = {
    "ember-vale": (0.92, 0.38, 0.12),
    "rook-ironside": (0.45, 0.42, 0.38),
    "juno-spark": (0.95, 0.86, 0.20),
    "kaia-windrow": (0.35, 0.72, 0.55),
    "nix-calder": (0.55, 0.78, 0.92),
    "orion-vell": (0.42, 0.28, 0.62),
    "vesper-nyx": (0.28, 0.10, 0.38),
}


def _argv() -> list[str]:
    if "--" in sys.argv:
        return sys.argv[sys.argv.index("--") + 1 :]
    return sys.argv[1:]


def _parse() -> dict:
    args = _argv()
    out = {"fighter": "rook-ironside", "out_blend": "", "report": ""}
    i = 0
    while i < len(args):
        if args[i].startswith("--") and i + 1 < len(args) and not args[i + 1].startswith("--"):
            out[args[i][2:].replace("-", "_")] = args[i + 1]
            i += 2
        else:
            i += 1
    return out


def _collection(name: str):
    col = bpy.data.collections.get(name) or bpy.data.collections.new(name)
    if col.name not in bpy.context.scene.collection.children:
        bpy.context.scene.collection.children.link(col)
    return col


def _link(col, obj) -> None:
    if obj.name not in col.objects:
        col.objects.link(obj)
    if obj.name in bpy.context.scene.collection.objects:
        bpy.context.scene.collection.objects.unlink(obj)


def build(fid: str, out_blend: Path) -> dict:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    export_col = _collection("AA_EXPORT")
    control_col = _collection("AA_CONTROL")
    mesh_col = _collection("AA_MESH")
    socket_col = _collection("AA_SOCKETS")
    cam_col = _collection("AA_CAMERA_REF")
    light_col = _collection("AA_LIGHTING_REF")

    arm = build_deform_armature(bpy, "AA_Deform")
    sockets = attach_sockets(bpy, arm)
    mesh = build_skinned_proxy(bpy, arm, COLORS.get(fid, (0.6, 0.6, 0.6)))
    rig = configure_control_rig(bpy, arm)
    _link(export_col, arm)
    _link(mesh_col, mesh)
    _link(control_col, arm)
    for sock in sockets:
        _link(socket_col, sock)

    cam_data = bpy.data.cameras.new("AA_RefCamera")
    cam = bpy.data.objects.new("AA_RefCamera", cam_data)
    cam.location = (3.2, -4.4, 1.6)
    cam.rotation_euler = (1.2, 0.0, 0.6)
    _link(cam_col, cam)
    key = bpy.data.lights.new("AA_Key", "AREA")
    key.energy = 250
    key_obj = bpy.data.objects.new("AA_Key", key)
    key_obj.location = (2.4, -2.0, 3.2)
    _link(light_col, key_obj)
    fill = bpy.data.lights.new("AA_Fill", "AREA")
    fill.energy = 80
    fill_obj = bpy.data.objects.new("AA_Fill", fill)
    fill_obj.location = (-2.8, 1.4, 2.0)
    _link(light_col, fill_obj)
    ground = bpy.data.meshes.new("AA_RefGround")
    from mathutils import Vector

    verts = [Vector((-2, -2, 0)), Vector((2, -2, 0)), Vector((2, 2, 0)), Vector((-2, 2, 0))]
    ground.from_pydata(verts, [], [(0, 1, 2, 3)])
    ground_obj = bpy.data.objects.new("AA_RefGround", ground)
    _link(cam_col, ground_obj)

    bpy.context.scene.render.fps = 60
    bpy.context.scene.unit_settings.system = "METRIC"
    reset_pose(bpy)
    actions = []
    for action_id, _runtime, _brief in PRODUCTION_ACTIONS:
        win = frame_window(fid, action_id)
        create_named_action(bpy, action_id, int(win["frame_start"]), int(win["frame_end"]))
        add_gameplay_markers(
            bpy,
            int(win.get("active_start") or win["frame_start"]),
            int(win.get("active_end") or win["frame_end"]),
            int(win.get("contact_frame") or 0),
            extra={"AA_HITSTOP": int(win.get("hitstop_frames") or 0) or 1},
        )
        actions.append(
            {
                "action": action_id,
                "frame_range": [win["frame_start"], win["frame_end"]],
                "contact_frame": win.get("contact_frame", 0),
                "keys": 0,
                "status": "MISSING",
                "note": "Empty WIP slot. Not authored animation.",
            }
        )
    create_named_action(bpy, "neutral_reset", 1, 1)
    out_blend.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(out_blend))
    return {
        "fighter": fid,
        "blend": str(out_blend),
        "status": "READY_TO_ANIMATE_PROXY",
        "mesh": "skinned_proxy_cylinder",
        "mesh_binding": "MESH_BINDING_NEEDS_HUMAN_WEIGHT_PAINT",
        "real_mesh_bound": False,
        "control_rig": rig,
        "actions": actions,
        "collections": [
            "AA_EXPORT",
            "AA_CONTROL",
            "AA_MESH",
            "AA_SOCKETS",
            "AA_CAMERA_REF",
            "AA_LIGHTING_REF",
        ],
        "not_final_art": True,
        "human_approved": False,
        "blender": bpy.app.version_string,
    }


def main() -> int:
    args = _parse()
    fid = args.get("fighter", "rook-ironside")
    out_blend = Path(args.get("out_blend") or f"/tmp/{fid}_animation_master.blend")
    report = build(fid, out_blend)
    text = json.dumps(report, indent=2)
    if args.get("report"):
        Path(args["report"]).parent.mkdir(parents=True, exist_ok=True)
        Path(args["report"]).write_text(text + "\n")
    print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
