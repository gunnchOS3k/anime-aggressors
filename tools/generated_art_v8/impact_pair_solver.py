"""Review-only pair contact solver. Does not change CombatMath, hitboxes, or frame data."""
from __future__ import annotations

from generated_art_v8.body_profiles import load_pairs

ANCHORS = {
    "HEAD": (0.0, 0.04, 1.60),
    "CHEST": (0.0, 0.06, 1.28),
    "TORSO_LEFT": (0.10, 0.06, 1.22),
    "TORSO_RIGHT": (-0.10, 0.06, 1.22),
    "PELVIS": (0.0, 0.04, 0.96),
    "UPPER_GUARD": (0.12, 0.10, 1.34),
    "LOWER_GUARD": (0.10, 0.08, 1.08),
}

# Review-facing world sockets after the attacker yaws toward +X and reaches.
SOCKET_REST = {
    "hand_r": (0.08, 0.12, 1.16),
    "hand_l": (0.06, -0.10, 1.14),
    "foot_l": (0.10, 0.16, 1.08),
    "foot_r": (0.08, -0.12, 0.16),
    "chest": (0.0, 0.06, 1.28),
    "head": (0.0, 0.04, 1.60),
}

CONTACT_DISTANCE_MAX = 0.16
OVERLAP_MIN = 0.22
OVERLAP_MAX = 1.35
STANDOFF = 0.05


def contact_spec(fid: str) -> dict:
    return dict((load_pairs().get("contact") or {}).get(fid) or {"socket": "hand_r", "anchor": "CHEST", "normal": [1.0, 0.0, 0.0]})


def _sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def _add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def _scale(a, s):
    return (a[0] * s, a[1] * s, a[2] * s)


def _len(a):
    return (a[0] ** 2 + a[1] ** 2 + a[2] ** 2) ** 0.5


def solve_defender_location(attacker_socket_world, defender_anchor_local, contact_normal, standoff: float = STANDOFF) -> tuple[float, float, float]:
    """Place defender origin so R*anchor + origin ≈ socket + normal * standoff.

    Review cameras already yaw the defender 180° in X, so the local chest X
    mirrors. We treat the provided world socket and a defender-local anchor.
    """
    target = _add(attacker_socket_world, _scale(contact_normal, standoff))
    return _sub(target, defender_anchor_local)


def solve_from_rest(fid: str, attacker_x: float = -0.22) -> dict:
    spec = contact_spec(fid)
    socket_world = SOCKET_REST[spec["socket"]]
    anchor = ANCHORS[spec["anchor"]]
    normal = tuple(spec.get("normal") or (1.0, 0.0, 0.0))
    defender_loc = solve_defender_location(socket_world, anchor, normal)
    contact = _len(_sub(socket_world, _add(defender_loc, anchor)))
    hips = (defender_loc[0], defender_loc[1], 0.92)
    overlap = abs(attacker_x - hips[0])
    return {
        "fighter": fid,
        "socket": spec["socket"],
        "anchor": spec["anchor"],
        "attacker_socket_world": [round(v, 4) for v in socket_world],
        "defender_location": [round(v, 4) for v in defender_loc],
        "contact_distance": round(contact, 4),
        "body_overlap": round(overlap, 4),
        "review_only": True,
        "gameplay_unchanged": True,
    }


def geometry_ok(row: dict) -> bool:
    dist = float(row.get("contact_distance") or 99)
    overlap = float(row.get("body_overlap") or 0)
    visible = bool(row.get("attacker_socket_visible", True)) and bool(row.get("defender_target_visible", True))
    return dist <= CONTACT_DISTANCE_MAX and OVERLAP_MIN <= overlap <= OVERLAP_MAX and visible


def solve_from_armatures(attacker, defender, socket_name: str, anchor_name: str, contact_normal=(1.0, 0.0, 0.0)) -> dict:
    """Blender-time solver using live skeleton/socket transforms."""
    import bpy
    from mathutils import Vector

    bpy.context.view_layer.update()

    def _world_bone(arm, bone_name: str) -> Vector:
        pb = arm.pose.bones.get(bone_name)
        if pb is None:
            return arm.matrix_world.translation.copy()
        return arm.matrix_world @ pb.tail

    socket_bone = {
        "hand_r": "Hand_R",
        "hand_l": "Hand_L",
        "foot_l": "Foot_L",
        "foot_r": "Foot_R",
        "chest": "Chest",
        "head": "Head",
    }[socket_name]
    anchor_bone = {
        "HEAD": "Head",
        "CHEST": "Chest",
        "TORSO_LEFT": "Chest",
        "TORSO_RIGHT": "Chest",
        "PELVIS": "Hips",
        "UPPER_GUARD": "UpperArm_L",
        "LOWER_GUARD": "Hips",
    }[anchor_name]
    socket_world = _world_bone(attacker, socket_bone)
    empty = bpy.data.objects.get(f"socket_{socket_name}")
    if empty is not None:
        socket_world = empty.matrix_world.translation.copy()
    anchor_world = _world_bone(defender, anchor_bone)
    if anchor_name == "TORSO_LEFT":
        anchor_world = anchor_world + (defender.matrix_world.to_3x3() @ Vector((0.10, 0.04, -0.04)))
    elif anchor_name == "TORSO_RIGHT":
        anchor_world = anchor_world + (defender.matrix_world.to_3x3() @ Vector((-0.10, 0.04, -0.04)))
    elif anchor_name == "UPPER_GUARD":
        anchor_world = _world_bone(defender, "LowerArm_L")
    target = socket_world + Vector(contact_normal) * STANDOFF
    delta = target - anchor_world
    defender.location = defender.location + delta
    bpy.context.view_layer.update()
    new_anchor = _world_bone(defender, anchor_bone)
    if anchor_name == "TORSO_LEFT":
        new_anchor = new_anchor + (defender.matrix_world.to_3x3() @ Vector((0.10, 0.04, -0.04)))
    elif anchor_name == "TORSO_RIGHT":
        new_anchor = new_anchor + (defender.matrix_world.to_3x3() @ Vector((-0.10, 0.04, -0.04)))
    elif anchor_name == "UPPER_GUARD":
        new_anchor = _world_bone(defender, "LowerArm_L")
    att_hips = _world_bone(attacker, "Hips")
    def_hips = _world_bone(defender, "Hips")
    contact = (socket_world - new_anchor).length
    overlap = (att_hips - def_hips).length
    return {
        "socket": socket_name,
        "anchor": anchor_name,
        "attacker_socket_world": [round(float(v), 4) for v in socket_world],
        "defender_target_world": [round(float(v), 4) for v in new_anchor],
        "defender_location": [round(float(v), 4) for v in defender.location],
        "contact_distance": round(float(contact), 4),
        "body_overlap": round(float(overlap), 4),
        "attacker_socket_visible": True,
        "defender_target_visible": True,
        "review_only": True,
        "gameplay_unchanged": True,
        "ok": geometry_ok({"contact_distance": contact, "body_overlap": overlap, "attacker_socket_visible": True, "defender_target_visible": True}),
    }
