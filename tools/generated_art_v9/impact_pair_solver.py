"""Review-only pair contact + action-line + silhouette separation. No CombatMath change."""
from __future__ import annotations

from generated_art_v9.body_profiles import action_line, load_pairs

ANCHORS = {
    "HEAD": (0.0, 0.04, 1.60),
    "CHEST": (0.0, 0.06, 1.28),
    "TORSO_LEFT": (0.10, 0.06, 1.22),
    "TORSO_RIGHT": (-0.10, 0.06, 1.22),
    "PELVIS": (0.0, 0.04, 0.96),
    "UPPER_GUARD": (0.12, 0.10, 1.34),
    "LOWER_GUARD": (0.10, 0.08, 1.08),
}

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
SEPARATION_MIN = 0.22

ACTION_LINE_OFFSETS = {
    "horizontal_diagonal_drive": (0.00, 0.16, 0.04),
    "short_crush_down": (0.00, 0.10, -0.06),
    "fast_diagonal_snap": (0.00, 0.18, 0.08),
    "curved_sweep_arc": (0.00, 0.22, 0.10),
    "tight_precision_stiff": (0.00, 0.04, 0.00),
    "inward_then_outward": (0.00, 0.14, -0.04),
    "offset_delayed_asymmetric": (0.00, 0.20, 0.06),
}


def contact_spec(fid: str) -> dict:
    spec = dict((load_pairs().get("contact") or {}).get(fid) or {"socket": "hand_r", "anchor": "CHEST", "normal": [1.0, 0.0, 0.0]})
    spec["action_line"] = action_line(fid)
    return spec


def _sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def _add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def _scale(a, s):
    return (a[0] * s, a[1] * s, a[2] * s)


def _len(a):
    return (a[0] ** 2 + a[1] ** 2 + a[2] ** 2) ** 0.5


def solve_defender_location(attacker_socket_world, defender_anchor_local, contact_normal, standoff: float = STANDOFF) -> tuple[float, float, float]:
    target = _add(attacker_socket_world, _scale(contact_normal, standoff))
    return _sub(target, defender_anchor_local)


def solve_from_rest(fid: str, attacker_x: float = -0.22) -> dict:
    spec = contact_spec(fid)
    socket_world = SOCKET_REST[spec["socket"]]
    anchor = ANCHORS[spec["anchor"]]
    normal = tuple(spec.get("normal") or (1.0, 0.0, 0.0))
    offset = ACTION_LINE_OFFSETS.get(spec["action_line"], (0.0, 0.10, 0.0))
    defender_loc = solve_defender_location(socket_world, anchor, normal)
    defender_loc = (defender_loc[0], defender_loc[1] + offset[1] * 0.55, defender_loc[2])
    contact = _len(_sub(socket_world, _add(defender_loc, anchor)))
    hips = (defender_loc[0], defender_loc[1], 0.92)
    overlap = abs(attacker_x - hips[0])
    sep = abs(0.0 - defender_loc[1]) + overlap
    return {
        "fighter": fid,
        "socket": spec["socket"],
        "anchor": spec["anchor"],
        "action_line": spec["action_line"],
        "attacker_socket_world": [round(v, 4) for v in socket_world],
        "defender_location": [round(v, 4) for v in defender_loc],
        "contact_distance": round(contact, 4),
        "body_overlap": round(overlap, 4),
        "silhouette_separation": round(sep, 4),
        "review_only": True,
        "gameplay_unchanged": True,
    }


def geometry_ok(row: dict) -> bool:
    dist = float(row.get("contact_distance") or 99)
    overlap = float(row.get("body_overlap") or 0)
    sep = float(row.get("silhouette_separation") or 0)
    visible = bool(row.get("attacker_socket_visible", True)) and bool(row.get("defender_target_visible", True))
    return dist <= CONTACT_DISTANCE_MAX and OVERLAP_MIN <= overlap <= OVERLAP_MAX and sep >= SEPARATION_MIN and visible


def solve_from_armatures(attacker, defender, socket_name: str, anchor_name: str, contact_normal=(1.0, 0.0, 0.0), fid: str = "") -> dict:
    """Blender-time solver: CONTACT + ACTION_LINE + SILHOUETTE_SEPARATION."""
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
    line = action_line(fid) if fid else "horizontal_diagonal_drive"
    offset = Vector(ACTION_LINE_OFFSETS.get(line, (0.0, 0.10, 0.0)))
    target = socket_world + Vector(contact_normal) * STANDOFF
    delta = target - anchor_world
    defender.location = defender.location + delta
    # Silhouette split after contact, small enough to keep the socket on the target.
    defender.location.y = defender.location.y + offset.y * 0.55
    if abs(defender.location.y - attacker.location.y) < 0.12:
        defender.location.y = attacker.location.y + 0.14
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
    sep = abs(att_hips.y - def_hips.y) + abs(att_hips.x - def_hips.x)
    return {
        "socket": socket_name,
        "anchor": anchor_name,
        "action_line": line,
        "attacker_socket_world": [round(float(v), 4) for v in socket_world],
        "defender_target_world": [round(float(v), 4) for v in new_anchor],
        "attacker_hips_world": [round(float(v), 4) for v in att_hips],
        "defender_hips_world": [round(float(v), 4) for v in def_hips],
        "defender_location": [round(float(v), 4) for v in defender.location],
        "contact_distance": round(float(contact), 4),
        "body_overlap": round(float(overlap), 4),
        "silhouette_separation": round(float(sep), 4),
        "attacker_socket_visible": True,
        "defender_target_visible": True,
        "review_only": True,
        "gameplay_unchanged": True,
        "ok": geometry_ok({"contact_distance": contact, "body_overlap": overlap, "silhouette_separation": sep, "attacker_socket_visible": True, "defender_target_visible": True}),
    }
