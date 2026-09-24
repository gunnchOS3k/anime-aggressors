"""Subject-aware review cameras. Detail shots must include attachment, not crop."""
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
    """Return (location, target, lens, ortho_scale) pulled back enough to keep the subject inside."""
    from generated_production_art.review_cameras_v4 import PRESETS

    preset = PRESETS[preset_name]
    loc = camera_location(preset, forward)
    target = camera_look_at(preset)
    names = {
        "glove": ("hand_r", "forearm_mass_r"),
        "boot": ("boot_r", "shin_mass_r"),
        "head": ("head_shell", "mask_"),
        "costume": ("torso_shell", "heat_", "frost_", "coat_", "volt_", "scarf_", "authority_", "shoulder_"),
        "pair": (),
    }.get(aim, ())
    extra = ("aa_refground",) if aim == "boot" else ()
    bounds = mesh_bounds(names) if names else None
    if aim == "boot":
        boot = mesh_bounds(("boot_r",))
        if boot:
            mins, maxs = [list(boot[0]), list(boot[1])]
            mins[2] = min(mins[2], 0.0)
            maxs[2] = max(maxs[2], mins[2] + 0.28)
            maxs[1] = max(maxs[1], mins[1] + 0.18)
            bounds = (mins, maxs)
    if bounds is None:
        return loc, target, preset.lens, 2.6 if preset.ortho else 0.0
    center = bounds_center(bounds)
    size = bounds_size(bounds)
    margin = 0.38 if aim in {"glove", "boot", "head"} else 0.28
    dist = size * (2.8 if aim in {"glove", "boot"} else 2.4) * (1.0 + margin)
    if aim == "glove":
        dist = size * 2.15
        loc = (center[0] + dist * 0.48, center[1] + dist * 0.82, center[2] + size * 0.12)
        target = (center[0], center[1], center[2])
    elif aim == "boot":
        loc = (center[0] + dist * 0.60, center[1] + dist * 1.05, max(0.22, center[2] + size * 0.35))
        target = (center[0], center[1] + size * 0.08, max(0.06, center[2]))
    elif aim == "head":
        loc = (center[0] + dist * 0.45, center[1] + dist * 0.90, center[2] + size * 0.08)
        target = center
    elif aim == "costume":
        loc = (center[0] + dist * 0.40, center[1] + dist * 0.85, center[2] + size * 0.05)
        target = center
    ortho = size * 2.35 * (1.0 + margin)
    return loc, target, 50 if aim in {"glove", "boot"} else preset.lens, ortho


def frame_pair(attacker_x=-0.62, defender_x=0.62):
    mid = (attacker_x + defender_x) * 0.5
    loc = (mid + 0.15, -3.35, 1.28)
    target = (mid, 0.18, 1.02)
    return loc, target, 40, 3.4


def crop_ok(bounds, frame_w=640, frame_h=800, margin=0.08) -> bool:
    """Digital stand-in: world AABB must have positive volume and not be a sliver."""
    if bounds is None:
        return False
    mins, maxs = bounds
    dx, dy, dz = maxs[0] - mins[0], maxs[1] - mins[1], maxs[2] - mins[2]
    if min(dx, dy, dz) < 0.02:
        return False
    return max(dx, dy, dz) / max(min(dx, dy, dz), 1e-4) < 18.0
