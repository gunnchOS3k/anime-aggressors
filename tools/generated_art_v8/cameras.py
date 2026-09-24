"""Subject-aware v8 cameras. Glove/boot fill 35–60% without eating the torso."""
from __future__ import annotations

from mathutils import Vector

from generated_production_art.review_cameras_v4 import CANONICAL_FORWARD, camera_location, camera_look_at


def mesh_bounds(obj_names: tuple[str, ...], extra_prefixes: tuple[str, ...] = ()):
    import bpy

    mins = [1e9, 1e9, 1e9]
    maxs = [-1e9, -1e9, -1e9]
    found = False
    keys = tuple(name.lower() for name in obj_names) + extra_prefixes
    for obj in bpy.data.objects:
        if obj.type != "MESH" or obj.get("aa_outline"):
            continue
        if obj.hide_render:
            continue
        lowered = obj.name.lower()
        if keys and not any(lowered.startswith(key) or key in lowered for key in keys):
            continue
        for vert in obj.data.vertices:
            world = obj.matrix_world @ vert.co
            for i in range(3):
                mins[i] = min(mins[i], float(world[i]))
                maxs[i] = max(maxs[i], float(world[i]))
            found = True
    if not found:
        return None
    return (mins, maxs)


def bounds_center(bounds) -> tuple[float, float, float]:
    mins, maxs = bounds
    return ((mins[0] + maxs[0]) * 0.5, (mins[1] + maxs[1]) * 0.5, (mins[2] + maxs[2]) * 0.5)


def bounds_size(bounds) -> float:
    mins, maxs = bounds
    return max(maxs[0] - mins[0], maxs[1] - mins[1], maxs[2] - mins[2], 0.12)


def frame_subject(aim: str, preset_name: str, forward=CANONICAL_FORWARD):
    from generated_production_art.review_cameras_v4 import PRESETS

    preset = PRESETS[preset_name]
    loc = camera_location(preset, forward)
    target = camera_look_at(preset)
    names = {
        "glove": ("hand_r",),
        "boot": ("boot_r",),
        "head": ("head_shell", "mask_"),
        "costume": ("torso_shell", "heat_", "frost_", "coat_", "volt_", "scarf_", "authority_", "shoulder_", "speed_", "chest_"),
        "pair": (),
    }.get(aim, ())
    bounds = mesh_bounds(names) if names else None
    if aim == "boot":
        boot = mesh_bounds(("boot_r",))
        if boot:
            mins, maxs = [list(boot[0]), list(boot[1])]
            mins[2] = min(mins[2], 0.0)
            maxs[2] = max(maxs[2], mins[2] + 0.32)
            maxs[1] = max(maxs[1], mins[1] + 0.16)
            bounds = (mins, maxs)
    if bounds is None:
        return loc, target, preset.lens, 2.6 if preset.ortho else 0.0
    center = bounds_center(bounds)
    size = bounds_size(bounds)
    if aim == "glove":
        dist = size * 1.85
        loc = (center[0] + dist * 0.42, center[1] + dist * 0.70, center[2] + size * 0.06)
        target = (center[0], center[1], center[2])
        return loc, target, 55, size * 1.85
    if aim == "boot":
        dist = size * 2.05
        loc = (center[0] + dist * 0.55, center[1] + dist * 0.95, max(0.18, center[2] + size * 0.28))
        target = (center[0], center[1] + size * 0.06, max(0.05, center[2]))
        return loc, target, 50, size * 2.10
    if aim == "head":
        dist = size * 2.20
        loc = (center[0] + dist * 0.40, center[1] + dist * 0.85, center[2] + size * 0.04)
        return loc, center, 50, size * 2.20
    if aim == "costume":
        dist = size * 2.30
        loc = (center[0] + dist * 0.38, center[1] + dist * 0.82, center[2] + size * 0.04)
        return loc, center, preset.lens, size * 2.25
    return loc, target, preset.lens, 2.6 if preset.ortho else 0.0


def frame_pair(attacker_x=-0.22, defender_x=0.28, contact=None):
    if contact and contact.get("attacker_socket_world"):
        cx, cy, cz = contact["attacker_socket_world"]
        loc = (cx + 0.38, cy - 2.20, 1.22)
        target = (cx - 0.02, cy + 0.08, 1.10)
        return loc, target, 40, 2.28
    mid = (attacker_x + defender_x) * 0.5
    loc = (mid + 0.30, -2.25, 1.20)
    target = (mid + 0.04, 0.06, 1.08)
    return loc, target, 40, 2.32
