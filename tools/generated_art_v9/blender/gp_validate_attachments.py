"""Pose every stress action and measure attachment anchors. Review-only."""
from __future__ import annotations

import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(HERE.parent.parent))
sys.path.insert(0, str(ROOT / "tools"))

from generated_art_v9.body_profiles import load_attachment_table  # noqa: E402
from generated_art_v9.hero_poses import STRESS_POSE_ALIASES, pose_v9  # noqa: E402
from generated_art_v9.rig_bind_v8 import bone_world_anchor  # noqa: E402
from generated_art_v9.validate_attachment_integrity import MAX_CHAIN, MAX_RIGID  # noqa: E402


def _argv() -> list[str]:
    if "--" in sys.argv:
        return sys.argv[sys.argv.index("--") + 1 :]
    return sys.argv[1:]


def _parse() -> dict:
    args = _argv()
    out = {"fighter": "", "out": ""}
    i = 0
    while i < len(args):
        if args[i].startswith("--") and i + 1 < len(args):
            out[args[i][2:].replace("-", "_")] = args[i + 1]
            i += 2
        else:
            i += 1
    return out


def _arm():
    for obj in bpy.data.objects:
        if obj.type == "ARMATURE" and not obj.name.startswith("AA_Def_"):
            return obj
    return None


def _centroid(obj) -> Vector:
    acc = Vector((0.0, 0.0, 0.0))
    if obj.type != "MESH" or not obj.data.vertices:
        return obj.matrix_world.translation.copy()
    for vert in obj.data.vertices:
        acc += obj.matrix_world @ vert.co
    return acc / len(obj.data.vertices)


def main() -> int:
    args = _parse()
    arm = _arm()
    if arm is None:
        Path(args["out"]).write_text(json.dumps({"ok": False, "reason": "no_armature"}) + "\n")
        return 1
    actions = load_attachment_table().get("stress_actions") or list(STRESS_POSE_ALIASES)
    rest = {}
    bpy.context.view_layer.update()
    rows = []
    unintentional = 0
    fails = []
    for obj in bpy.data.objects:
        if obj.type != "MESH" or obj.name.startswith("AA_Ref") or obj.get("aa_outline") or obj.get("aa_review_variant"):
            continue
        if obj.get("aa_undersuit") or obj.name.endswith(".mesh"):
            continue
        cls = obj.get("aa_attach_class")
        bone = obj.get("aa_attach_bone")
        if not cls:
            unintentional += 1
            fails.append(f"{obj.name}:unclassified")
            continue
        if cls == "WORLD_STATIC":
            fails.append(f"{obj.name}:world_static_costume")
            continue
        rest[obj.name] = (_centroid(obj) - bone_world_anchor(arm, bone)).length if bone else 0.0
    for label in actions:
        pose_key = (STRESS_POSE_ALIASES.get(label) or (label, label))[0]
        pose = pose_v9(args["fighter"], pose_key)
        arm.data.pose_position = "POSE"
        if arm.animation_data:
            arm.animation_data.action = None
        bpy.context.view_layer.objects.active = arm
        for bone_name, rot in pose.items():
            pb = arm.pose.bones.get(bone_name)
            if pb is None:
                continue
            pb.rotation_mode = "XYZ"
            pb.rotation_euler = rot
        bpy.context.view_layer.update()
        for obj in bpy.data.objects:
            if obj.name not in rest:
                continue
            cls = obj.get("aa_attach_class")
            bone = obj.get("aa_attach_bone")
            floating = bool(obj.get("aa_intentional_float"))
            posed = (_centroid(obj) - bone_world_anchor(arm, bone)).length if bone else 99.0
            disp = abs(posed - rest[obj.name])
            limit = MAX_CHAIN if cls == "SECONDARY_CHAIN" else MAX_RIGID
            ok = True
            if cls == "SKINNED_COSTUME":
                ok = True
            elif cls == "VFX_ORBIT" and floating:
                ok = True
            elif disp > limit:
                ok = False
                fails.append(f"{obj.name}:{label}:disp={disp:.3f}")
            rows.append(
                {
                    "name": obj.name,
                    "class": cls,
                    "owning_bone": bone,
                    "action": label,
                    "rest_anchor_distance": round(float(rest[obj.name]), 4),
                    "posed_anchor_distance": round(float(posed), 4),
                    "max_displacement": round(float(disp), 4),
                    "intentional_floating": floating,
                    "ok": ok,
                }
            )
    payload = {
        "ok": not fails and unintentional == 0,
        "fighter": args["fighter"],
        "unintentional_floating": unintentional,
        "fails": fails,
        "records": rows,
    }
    Path(args["out"]).parent.mkdir(parents=True, exist_ok=True)
    Path(args["out"]).write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps({"ok": payload["ok"], "fails": fails[:12]}))
    return 0 if payload["ok"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
