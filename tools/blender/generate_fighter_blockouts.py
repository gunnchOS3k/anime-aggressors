#!/usr/bin/env python3
"""Build the seven original Anime Aggressors 3D proxy fighters.

Run through Blender, not system Python:

    blender --background --python tools/blender/generate_fighter_blockouts.py

The generated assets are deliberately called ``proxy`` assets. They are original,
rigged, animated production blockouts that make the real Godot/Android path 3D;
they are not a substitute for an art-direction and manual animation sign-off.
"""

from __future__ import annotations

import hashlib
import json
import math
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, Mapping, Sequence, Tuple

try:
    import bpy  # type: ignore
except ImportError:
    print("This generator must run inside Blender (bpy is unavailable).", file=sys.stderr)
    raise SystemExit(2)


ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = ROOT / "assets" / "blender" / "fighters"
EXPORT_DIR = ROOT / "assets" / "exports" / "godot" / "fighters"
RUNTIME_DIR = ROOT / "game-godot" / "assets" / "characters" / "proxy"
PIPELINE_VERSION = 1

Vec3 = Tuple[float, float, float]


@dataclass(frozen=True)
class FighterStyle:
    fighter_id: str
    display_name: str
    lane: str
    primary: str
    secondary: str
    accent: str
    outline: str
    body_scale: Vec3 = (1.0, 1.0, 1.0)
    head_scale: float = 1.0
    hand_scale: float = 1.0
    boot_scale: float = 1.0
    accessory: str = "crest"


STYLES: Sequence[FighterStyle] = (
    FighterStyle("ember-vale", "Ember Vale", "flame rushdown", "E84A3C", "6C2630", "FFB33B", "241922", hand_scale=1.22, accessory="flame_gauntlets"),
    FighterStyle("rook-ironside", "Rook Ironside", "impact armor", "8C5A3C", "30384A", "E28A36", "181A20", body_scale=(1.18, 1.10, 1.05), head_scale=0.95, hand_scale=1.18, boot_scale=1.28, accessory="impact_armor"),
    FighterStyle("juno-spark", "Juno Spark", "lightning speed", "F4D94E", "202839", "72E6FF", "12151D", body_scale=(0.90, 0.94, 0.92), head_scale=1.06, accessory="volt_scarf"),
    FighterStyle("kaia-windrow", "Kaia Windrow", "wind aerial control", "3CBF91", "1F5360", "B8FFF1", "15262B", body_scale=(0.94, 0.98, 0.92), head_scale=1.03, accessory="gale_sash"),
    FighterStyle("nix-calder", "Nix Calder", "frost stage control", "4C91D8", "D8F4FF", "83E8FF", "172A42", body_scale=(1.08, 1.06, 1.04), boot_scale=1.12, accessory="frost_mantle"),
    FighterStyle("orion-vell", "Orion Vell", "gravity vector control", "6554A6", "252340", "C795FF", "161522", body_scale=(1.02, 1.0, 0.98), accessory="gravity_rings"),
    FighterStyle("vesper-nyx", "Vesper Nyx", "void phase trickster", "7C3EA2", "1D1830", "D272FF", "0D0B14", body_scale=(0.94, 0.98, 0.94), head_scale=1.05, accessory="void_hood"),
)

CLIPS: Sequence[str] = (
    "idle", "walk", "run", "dash", "jump", "fall", "land", "jab_1",
    "jab_2", "heavy_attack", "special", "shield", "hurt_light",
    "hurt_heavy", "launched", "aura_charge", "aura_burst",
    "throw_forward", "ko",
)


def hex_color(value: str, alpha: float = 1.0) -> Tuple[float, float, float, float]:
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) / 255.0 for i in (0, 2, 4)) + (alpha,)


def material(name: str, color: str, emission: float = 0.0):
    mat = bpy.data.materials.new(name)
    rgba = hex_color(color)
    mat.diffuse_color = rgba
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf is not None:
        bsdf.inputs["Base Color"].default_value = rgba
        bsdf.inputs["Roughness"].default_value = 0.68
        if emission > 0.0:
            # Blender 3.3 uses the pre-4.x emission socket names.
            if "Emission" in bsdf.inputs:
                bsdf.inputs["Emission"].default_value = rgba
            if "Emission Strength" in bsdf.inputs:
                bsdf.inputs["Emission Strength"].default_value = emission
    return mat


def clear_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.render.engine = "BLENDER_EEVEE"
    bpy.context.scene.render.film_transparent = True
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 1.0


def add_bone(armature, name: str, head: Vec3, tail: Vec3, parent: str | None = None):
    bone = armature.edit_bones.new(name)
    bone.head = head
    bone.tail = tail
    bone.use_deform = True
    if parent:
        bone.parent = armature.edit_bones[parent]
    return bone


def create_armature(style: FighterStyle):
    data = bpy.data.armatures.new(f"{style.display_name} Rig")
    armature = bpy.data.objects.new("FighterRig", data)
    bpy.context.scene.collection.objects.link(armature)
    armature.show_in_front = True
    armature["fighter_id"] = style.fighter_id
    armature["asset_tier"] = "proxy_3d"
    armature["pipeline_version"] = PIPELINE_VERSION

    bpy.context.view_layer.objects.active = armature
    armature.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    add_bone(data, "root", (0, 0, 0.03), (0, 0, 0.28))
    add_bone(data, "pelvis", (0, 0, 0.72), (0, 0, 1.02), "root")
    add_bone(data, "spine", (0, 0, 1.0), (0, 0, 1.38), "pelvis")
    add_bone(data, "chest", (0, 0, 1.34), (0, 0, 1.68), "spine")
    add_bone(data, "neck", (0, 0, 1.66), (0, 0, 1.84), "chest")
    add_bone(data, "head", (0, 0, 1.82), (0, 0, 2.17), "neck")
    add_bone(data, "upper_arm.L", (-0.28, 0, 1.55), (-0.56, 0, 1.31), "chest")
    add_bone(data, "lower_arm.L", (-0.56, 0, 1.31), (-0.70, 0, 1.03), "upper_arm.L")
    add_bone(data, "hand.L", (-0.70, 0, 1.03), (-0.74, -0.01, 0.86), "lower_arm.L")
    add_bone(data, "upper_arm.R", (0.28, 0, 1.55), (0.56, 0, 1.31), "chest")
    add_bone(data, "lower_arm.R", (0.56, 0, 1.31), (0.70, 0, 1.03), "upper_arm.R")
    add_bone(data, "hand.R", (0.70, 0, 1.03), (0.74, -0.01, 0.86), "lower_arm.R")
    add_bone(data, "upper_leg.L", (-0.16, 0, 0.78), (-0.18, 0, 0.43), "pelvis")
    add_bone(data, "lower_leg.L", (-0.18, 0, 0.43), (-0.18, 0, 0.13), "upper_leg.L")
    add_bone(data, "foot.L", (-0.18, 0, 0.13), (-0.18, -0.24, 0.07), "lower_leg.L")
    add_bone(data, "upper_leg.R", (0.16, 0, 0.78), (0.18, 0, 0.43), "pelvis")
    add_bone(data, "lower_leg.R", (0.18, 0, 0.43), (0.18, 0, 0.13), "upper_leg.R")
    add_bone(data, "foot.R", (0.18, 0, 0.13), (0.18, -0.24, 0.07), "lower_leg.R")
    bpy.ops.object.mode_set(mode="POSE")
    for pose_bone in armature.pose.bones:
        pose_bone.rotation_mode = "XYZ"
    bpy.ops.object.mode_set(mode="OBJECT")
    return armature


def rigid_bind(obj, armature, bone_name: str) -> None:
    obj.parent = armature
    modifier = obj.modifiers.new("FighterRig", "ARMATURE")
    modifier.object = armature
    group = obj.vertex_groups.new(name=bone_name)
    group.add(range(len(obj.data.vertices)), 1.0, "REPLACE")
    obj["rig_bone"] = bone_name


def apply_material(obj, mat) -> None:
    if len(obj.data.materials) == 0:
        obj.data.materials.append(mat)
    else:
        obj.data.materials[0] = mat


def cube_part(name: str, location: Vec3, scale: Vec3, mat, armature, bone: str, bevel: float = 0.06):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0:
        modifier = obj.modifiers.new("SoftBevel", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
        modifier.affect = "EDGES"
    apply_material(obj, mat)
    rigid_bind(obj, armature, bone)
    return obj


def sphere_part(name: str, location: Vec3, scale: Vec3, mat, armature, bone: str):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=1.0, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    apply_material(obj, mat)
    rigid_bind(obj, armature, bone)
    return obj


def cone_part(name: str, location: Vec3, radius: float, depth: float, mat, armature, bone: str, rotation: Vec3 = (0, 0, 0)):
    bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=radius, radius2=0.0, depth=depth, location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    apply_material(obj, mat)
    rigid_bind(obj, armature, bone)
    return obj


def torus_part(name: str, location: Vec3, major_radius: float, minor_radius: float, mat, armature, bone: str, rotation: Vec3 = (0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_segments=16, minor_segments=4, location=location, major_radius=major_radius, minor_radius=minor_radius, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    apply_material(obj, mat)
    rigid_bind(obj, armature, bone)
    return obj


def add_socket(name: str, world_location: Vec3, armature, bone: str):
    empty = bpy.data.objects.new(name, None)
    empty.empty_display_type = "PLAIN_AXES"
    empty.empty_display_size = 0.08
    bpy.context.scene.collection.objects.link(empty)
    empty.location = world_location
    world_matrix = empty.matrix_world.copy()
    empty.parent = armature
    empty.parent_type = "BONE"
    empty.parent_bone = bone
    empty.matrix_world = world_matrix
    empty["socket"] = True
    return empty


def create_base_model(style: FighterStyle, armature):
    sx, sy, sz = style.body_scale
    mats = {
        "primary": material(f"{style.fighter_id}_primary", style.primary),
        "secondary": material(f"{style.fighter_id}_secondary", style.secondary),
        "accent": material(f"{style.fighter_id}_accent", style.accent, 0.18),
        "outline": material(f"{style.fighter_id}_outline", style.outline),
        "skin": material(f"{style.fighter_id}_skin", "E5B28F"),
        "eye": material(f"{style.fighter_id}_eye", "F7FBFF", 0.12),
    }

    cube_part("hips_mesh", (0, 0, 0.84), (0.29 * sx, 0.19 * sy, 0.20 * sz), mats["secondary"], armature, "pelvis")
    cube_part("torso_mesh", (0, 0, 1.35), (0.38 * sx, 0.22 * sy, 0.43 * sz), mats["primary"], armature, "chest")
    sphere_part("head_mesh", (0, -0.01, 2.01), (0.30 * style.head_scale, 0.28 * style.head_scale, 0.32 * style.head_scale), mats["skin"], armature, "head")

    for side, sign in (("L", -1.0), ("R", 1.0)):
        cube_part(f"upper_arm_{side}", (0.42 * sign, 0, 1.43), (0.14 * sx, 0.14 * sy, 0.28 * sz), mats["primary"], armature, f"upper_arm.{side}")
        cube_part(f"lower_arm_{side}", (0.63 * sign, 0, 1.16), (0.12 * sx, 0.13 * sy, 0.25 * sz), mats["secondary"], armature, f"lower_arm.{side}")
        sphere_part(f"hand_{side}", (0.72 * sign, -0.01, 0.93), (0.17 * style.hand_scale, 0.15 * style.hand_scale, 0.18 * style.hand_scale), mats["accent"], armature, f"hand.{side}")
        cube_part(f"upper_leg_{side}", (0.17 * sign, 0, 0.59), (0.16 * sx, 0.17 * sy, 0.30 * sz), mats["secondary"], armature, f"upper_leg.{side}")
        cube_part(f"lower_leg_{side}", (0.18 * sign, 0, 0.27), (0.14 * sx, 0.15 * sy, 0.27 * sz), mats["primary"], armature, f"lower_leg.{side}")
        cube_part(f"boot_{side}", (0.18 * sign, -0.12, 0.08), (0.18 * style.boot_scale, 0.29 * style.boot_scale, 0.11 * style.boot_scale), mats["outline"], armature, f"foot.{side}")
        # Eyes are deliberately graphic and oversized for phone-size readability.
        sphere_part(f"eye_{side}", (0.105 * sign, -0.266, 2.055), (0.045, 0.025, 0.075), mats["eye"], armature, "head")

    create_accessory(style, mats, armature)
    return mats


def create_accessory(style: FighterStyle, mats: Mapping[str, object], armature) -> None:
    accent = style.accessory
    if accent == "flame_gauntlets":
        for side, sign in (("L", -1.0), ("R", 1.0)):
            cone_part(f"flame_fin_{side}", (0.74 * sign, 0.02, 1.10), 0.12, 0.34, mats["accent"], armature, f"hand.{side}")
        for idx, x in enumerate((-0.14, 0.0, 0.14)):
            cone_part(f"ember_crest_{idx}", (x, 0.02, 2.34 + abs(x) * 0.2), 0.10, 0.34, mats["accent"], armature, "head")
    elif accent == "impact_armor":
        cube_part("pauldron_L", (-0.48, 0, 1.58), (0.25, 0.25, 0.18), mats["accent"], armature, "upper_arm.L")
        cube_part("pauldron_R", (0.48, 0, 1.58), (0.25, 0.25, 0.18), mats["accent"], armature, "upper_arm.R")
        cube_part("helmet_brow", (0, -0.22, 2.15), (0.33, 0.08, 0.10), mats["outline"], armature, "head")
    elif accent == "volt_scarf":
        cube_part("volt_scarf", (0.18, 0.12, 1.70), (0.42, 0.06, 0.08), mats["accent"], armature, "chest")
        cone_part("bolt_tuft_L", (-0.11, 0.01, 2.33), 0.08, 0.34, mats["accent"], armature, "head", (0, 0.25, -0.20))
        cone_part("bolt_tuft_R", (0.11, 0.01, 2.31), 0.08, 0.30, mats["accent"], armature, "head", (0, -0.25, 0.20))
    elif accent == "gale_sash":
        cube_part("gale_sash", (-0.08, 0.10, 1.12), (0.48, 0.055, 0.09), mats["accent"], armature, "spine")
        cube_part("wing_sleeve_L", (-0.47, 0.02, 1.45), (0.20, 0.06, 0.34), mats["accent"], armature, "upper_arm.L")
        cube_part("wing_sleeve_R", (0.47, 0.02, 1.45), (0.20, 0.06, 0.34), mats["accent"], armature, "upper_arm.R")
    elif accent == "frost_mantle":
        cube_part("frost_mantle", (0, 0.08, 1.66), (0.55, 0.26, 0.12), mats["secondary"], armature, "chest")
        cone_part("ice_shard_L", (-0.38, 0.02, 1.84), 0.11, 0.36, mats["accent"], armature, "chest")
        cone_part("ice_shard_R", (0.38, 0.02, 1.84), 0.11, 0.36, mats["accent"], armature, "chest")
    elif accent == "gravity_rings":
        torus_part("orbit_ring_0", (0, 0, 1.18), 0.48, 0.035, mats["accent"], armature, "spine", (math.pi / 2, 0.25, 0))
        torus_part("orbit_ring_1", (0, 0, 1.52), 0.54, 0.035, mats["accent"], armature, "chest", (math.pi / 2, -0.30, 0.35))
        sphere_part("gravity_orb_L", (-0.48, 0.04, 1.30), (0.08, 0.08, 0.08), mats["accent"], armature, "chest")
        sphere_part("gravity_orb_R", (0.48, 0.04, 1.55), (0.08, 0.08, 0.08), mats["accent"], armature, "chest")
    elif accent == "void_hood":
        sphere_part("void_hood", (0, 0.04, 2.09), (0.38, 0.34, 0.40), mats["secondary"], armature, "head")
        cube_part("void_cape", (0, 0.18, 1.30), (0.40, 0.07, 0.55), mats["secondary"], armature, "chest")
        cone_part("void_cape_tip", (0, 0.18, 0.78), 0.38, 0.42, mats["secondary"], armature, "chest", (0, 0, math.pi))


def create_sockets(armature) -> None:
    socket_defs = {
        "root": ((0, 0, 0.0), "root"),
        "chest": ((0, -0.02, 1.50), "chest"),
        "head": ((0, -0.02, 2.22), "head"),
        "left_hand": ((-0.76, -0.02, 0.88), "hand.L"),
        "right_hand": ((0.76, -0.02, 0.88), "hand.R"),
        "left_foot": ((-0.18, -0.28, 0.04), "foot.L"),
        "right_foot": ((0.18, -0.28, 0.04), "foot.R"),
        "weapon_tip": ((0.82, -0.02, 0.86), "hand.R"),
        "aura_core": ((0, -0.18, 1.45), "chest"),
        "hit_spark_center": ((0, -0.24, 1.35), "chest"),
    }
    for name, (position, bone) in socket_defs.items():
        add_socket(name, position, armature, bone)


def reset_pose(armature) -> None:
    for bone in armature.pose.bones:
        bone.location = (0, 0, 0)
        bone.rotation_euler = (0, 0, 0)
        bone.scale = (1, 1, 1)


def key_pose(armature, frame: int, rotations: Mapping[str, Vec3] | None = None, locations: Mapping[str, Vec3] | None = None, scales: Mapping[str, Vec3] | None = None) -> None:
    rotations = rotations or {}
    locations = locations or {}
    scales = scales or {}
    for bone in armature.pose.bones:
        bone.rotation_euler = rotations.get(bone.name, (0, 0, 0))
        bone.location = locations.get(bone.name, (0, 0, 0))
        bone.scale = scales.get(bone.name, (1, 1, 1))
        bone.keyframe_insert(data_path="rotation_euler", frame=frame, group=bone.name)
        bone.keyframe_insert(data_path="location", frame=frame, group=bone.name)
        bone.keyframe_insert(data_path="scale", frame=frame, group=bone.name)


def animation_poses(name: str):
    r = math.radians
    neutral = {}
    if name == "idle":
        return 36, [(1, neutral, {}, {}), (18, {"chest": (0, r(3), 0)}, {"root": (0, 0, 0.025)}, {}), (36, neutral, {}, {})]
    if name in ("walk", "run"):
        angle = r(24 if name == "walk" else 42)
        stride = 18 if name == "walk" else 12
        a = {"upper_leg.L": (angle, 0, 0), "upper_leg.R": (-angle, 0, 0), "upper_arm.L": (-angle * 0.65, 0, 0), "upper_arm.R": (angle * 0.65, 0, 0)}
        b = {"upper_leg.L": (-angle, 0, 0), "upper_leg.R": (angle, 0, 0), "upper_arm.L": (angle * 0.65, 0, 0), "upper_arm.R": (-angle * 0.65, 0, 0)}
        return stride * 2, [(1, a, {}, {}), (stride, b, {}, {}), (stride * 2, a, {}, {})]
    if name == "dash":
        return 14, [(1, {}, {}, {}), (5, {"spine": (0, r(18), 0), "upper_leg.L": (r(34), 0, 0), "upper_leg.R": (-r(24), 0, 0)}, {"root": (0.12, 0, 0)}, {}), (14, {}, {}, {})]
    if name == "jump":
        return 20, [(1, {}, {}, {}), (7, {"upper_leg.L": (r(28), 0, 0), "upper_leg.R": (r(28), 0, 0), "lower_leg.L": (-r(38), 0, 0), "lower_leg.R": (-r(38), 0, 0)}, {"root": (0, 0, 0.12)}, {}), (20, {}, {}, {})]
    if name == "fall":
        return 24, [(1, {"upper_arm.L": (0, 0, -r(24)), "upper_arm.R": (0, 0, r(24))}, {}, {}), (24, {"upper_arm.L": (0, 0, -r(30)), "upper_arm.R": (0, 0, r(30))}, {}, {})]
    if name == "land":
        return 12, [(1, {}, {}, {}), (4, {"upper_leg.L": (r(28), 0, 0), "upper_leg.R": (r(28), 0, 0)}, {"root": (0, 0, -0.06)}, {"pelvis": (1.08, 1.08, 0.82)}), (12, {}, {}, {})]
    if name in ("jab_1", "jab_2"):
        side = "R" if name == "jab_1" else "L"
        sign = 1 if side == "R" else -1
        strike = {f"upper_arm.{side}": (0, -r(68), r(72) * sign), f"lower_arm.{side}": (0, -r(18), 0), "chest": (0, r(8) * sign, 0)}
        return 14, [(1, {}, {}, {}), (5, strike, {}, {}), (8, strike, {}, {}), (14, {}, {}, {})]
    if name == "heavy_attack":
        windup = {"upper_arm.R": (0, r(45), -r(55)), "lower_arm.R": (0, r(30), 0), "spine": (0, -r(12), 0)}
        strike = {"upper_arm.R": (0, -r(75), r(80)), "lower_arm.R": (0, -r(20), 0), "spine": (0, r(18), 0)}
        return 28, [(1, {}, {}, {}), (8, windup, {}, {}), (15, strike, {"root": (0.08, 0, 0)}, {}), (20, strike, {}, {}), (28, {}, {}, {})]
    if name == "special":
        cast = {"upper_arm.L": (0, -r(50), -r(58)), "upper_arm.R": (0, -r(50), r(58)), "chest": (0, 0, r(3))}
        return 30, [(1, {}, {}, {}), (10, cast, {}, {}), (20, cast, {}, {"chest": (1.08, 1.08, 1.08)}), (30, {}, {}, {})]
    if name == "shield":
        guard = {"upper_arm.L": (0, -r(45), -r(42)), "lower_arm.L": (0, 0, -r(55)), "upper_arm.R": (0, -r(45), r(42)), "lower_arm.R": (0, 0, r(55))}
        return 24, [(1, guard, {}, {}), (24, guard, {}, {})]
    if name == "hurt_light":
        recoil = {"spine": (0, -r(12), 0), "head": (0, r(10), 0)}
        return 12, [(1, {}, {}, {}), (4, recoil, {"root": (-0.04, 0, 0)}, {}), (12, {}, {}, {})]
    if name == "hurt_heavy":
        recoil = {"spine": (0, -r(30), 0), "head": (0, r(18), 0), "upper_arm.L": (0, 0, -r(28)), "upper_arm.R": (0, 0, r(28))}
        return 20, [(1, {}, {}, {}), (6, recoil, {"root": (-0.12, 0, 0.04)}, {}), (20, {}, {}, {})]
    if name == "launched":
        spin = {"root": (0, r(170), r(35)), "upper_arm.L": (r(20), 0, -r(35)), "upper_arm.R": (-r(20), 0, r(35))}
        return 24, [(1, {}, {}, {}), (12, spin, {"root": (0, 0, 0.12)}, {}), (24, {"root": (0, r(340), r(70))}, {}, {})]
    if name == "aura_charge":
        charge = {"upper_arm.L": (0, r(22), -r(18)), "upper_arm.R": (0, r(22), r(18)), "spine": (0, -r(8), 0)}
        return 36, [(1, charge, {}, {}), (18, charge, {"root": (0, 0, -0.035)}, {"chest": (1.05, 1.05, 1.05)}), (36, charge, {}, {})]
    if name == "aura_burst":
        burst = {"upper_arm.L": (0, 0, -r(80)), "upper_arm.R": (0, 0, r(80)), "spine": (0, r(10), 0)}
        return 28, [(1, {}, {}, {}), (10, burst, {}, {"root": (1.12, 1.12, 1.12)}), (18, burst, {}, {}), (28, {}, {}, {})]
    if name == "throw_forward":
        grab = {"upper_arm.R": (0, -r(50), r(50)), "lower_arm.R": (0, -r(25), 0)}
        release = {"upper_arm.R": (0, -r(72), r(88)), "spine": (0, r(16), 0)}
        return 26, [(1, {}, {}, {}), (8, grab, {}, {}), (15, release, {"root": (0.08, 0, 0)}, {}), (26, {}, {}, {})]
    if name == "ko":
        return 36, [(1, {}, {}, {}), (18, {"root": (0, 0, r(55)), "spine": (0, -r(20), 0)}, {"root": (-0.10, 0, -0.10)}, {}), (36, {"root": (0, 0, r(88))}, {"root": (-0.18, 0, -0.28)}, {})]
    return 1, [(1, {}, {}, {})]


def create_animations(armature) -> None:
    armature.animation_data_create()
    for clip in CLIPS:
        reset_pose(armature)
        action = bpy.data.actions.new(clip)
        action.use_fake_user = True
        armature.animation_data.action = action
        end_frame, poses = animation_poses(clip)
        for frame, rotations, locations, scales in poses:
            key_pose(armature, frame, rotations, locations, scales)
        track = armature.animation_data.nla_tracks.new()
        track.name = clip
        strip = track.strips.new(clip, 1, action)
        strip.action_frame_start = 1
        strip.action_frame_end = end_frame
        strip.frame_end = end_frame
    armature.animation_data.action = None
    reset_pose(armature)


def configure_export_scene(style: FighterStyle) -> None:
    scene = bpy.context.scene
    scene["fighter_id"] = style.fighter_id
    scene["display_name"] = style.display_name
    scene["combat_lane"] = style.lane
    scene["original_design"] = True
    scene["asset_tier"] = "proxy_3d"
    scene["required_clips"] = json.dumps(list(CLIPS))
    scene.render.fps = 60
    scene.frame_start = 1
    scene.frame_end = 36


def build_fighter(style: FighterStyle) -> Dict[str, object]:
    clear_scene()
    armature = create_armature(style)
    create_base_model(style, armature)
    create_sockets(armature)
    create_animations(armature)
    configure_export_scene(style)

    source_folder = SOURCE_DIR / style.fighter_id
    source_folder.mkdir(parents=True, exist_ok=True)
    EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    blend_path = source_folder / f"{style.fighter_id}.blend"
    export_path = EXPORT_DIR / f"{style.fighter_id}.glb"
    runtime_path = RUNTIME_DIR / f"{style.fighter_id}.glb"

    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path), compress=True)
    bpy.ops.export_scene.gltf(
        filepath=str(export_path),
        export_format="GLB",
        export_animations=True,
        export_nla_strips=True,
        export_yup=True,
        export_extras=True,
    )
    shutil.copy2(export_path, runtime_path)
    digest = hashlib.sha256(export_path.read_bytes()).hexdigest()
    print(f"Built {style.display_name}: {export_path} ({export_path.stat().st_size} bytes)")
    return {
        "fighter_id": style.fighter_id,
        "display_name": style.display_name,
        "combat_lane": style.lane,
        "source": str(blend_path.relative_to(ROOT)),
        "export": str(export_path.relative_to(ROOT)),
        "runtime": str(runtime_path.relative_to(ROOT)),
        "sha256": digest,
        "size_bytes": export_path.stat().st_size,
        "clips": list(CLIPS),
        "asset_tier": "proxy_3d",
    }


def main() -> int:
    records = [build_fighter(style) for style in STYLES]
    manifest = {
        "schema_version": 1,
        "pipeline_version": PIPELINE_VERSION,
        "generator": "tools/blender/generate_fighter_blockouts.py",
        "original_design_policy": "docs/ORIGINAL_CHARACTER_DESIGN_POLICY.md",
        "fighters": records,
    }
    manifest_path = EXPORT_DIR / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    runtime_manifest = RUNTIME_DIR / "manifest.json"
    shutil.copy2(manifest_path, runtime_manifest)
    print(f"Wrote {manifest_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
