"""v9 subject-aware + combat cameras. Cameras must not hide weak acting."""
from __future__ import annotations

from mathutils import Vector

from generated_art_v8.cameras import bounds_center, bounds_size, frame_subject, mesh_bounds
from generated_art_v9.body_profiles import action_line
from generated_production_art.review_cameras_v4 import CANONICAL_FORWARD, camera_location, camera_look_at


COMBAT_PRESETS = {
    "HEAVY_SIDE_3Q": {"offset": (0.85, -3.25, 1.28), "target_z": 1.10, "lens": 36, "ortho": 3.15},
    "HEAVY_LOW_3Q": {"offset": (0.70, -3.05, 0.72), "target_z": 0.96, "lens": 34, "ortho": 3.05},
    "SUPER_HERO": {"offset": (0.38, -3.15, 1.48), "target_z": 1.18, "lens": 32, "ortho": 3.05},
    "CLASH_WIDE": {"offset": (0.18, -3.45, 1.22), "target_z": 1.12, "lens": 30, "ortho": 3.35},
    "CLASH_CLOSE": {"offset": (0.42, -2.65, 1.20), "target_z": 1.14, "lens": 38, "ortho": 2.55},
}


def frame_pair(attacker_x=-0.22, defender_x=0.28, contact=None, preset="HEAVY_SIDE_3Q"):
    row = COMBAT_PRESETS.get(preset) or COMBAT_PRESETS["HEAVY_SIDE_3Q"]
    if contact and contact.get("attacker_socket_world"):
        cx, cy, cz = contact["attacker_socket_world"]
        ox, oy, oz = row["offset"]
        loc = (cx + ox, cy + oy, oz)
        target = (cx + 0.08, cy + 0.10, row["target_z"])
        return loc, target, row["lens"], row["ortho"]
    mid = (attacker_x + defender_x) * 0.5
    ox, oy, oz = row["offset"]
    loc = (mid + ox, oy, oz)
    target = (mid + 0.06, 0.08, row["target_z"])
    return loc, target, row["lens"], row["ortho"]


def combat_preset_for(fid: str, label: str) -> str:
    line = action_line(fid)
    if "clash" in label:
        return "CLASH_CLOSE" if "lock" in label or "win" in label or "lose" in label else "CLASH_WIDE"
    if "super" in label:
        return "SUPER_HERO"
    if line in {"short_crush_down", "inward_then_outward"}:
        return "HEAVY_LOW_3Q"
    if line in {"curved_sweep_arc", "offset_delayed_asymmetric"}:
        return "HEAVY_SIDE_3Q"
    return "HEAVY_SIDE_3Q"


def composition_score(contact: dict) -> dict:
    """Geometry + projected-bounds composition. Visual truth stays separate."""
    if not contact:
        return {"score": 0.0, "ok": False}
    att = contact.get("attacker_hips_world") or contact.get("attacker_socket_world") or (0, 0, 1)
    dfn = contact.get("defender_hips_world") or contact.get("defender_target_world") or (0.4, 0, 1)
    sock = contact.get("attacker_socket_world") or att
    tgt = contact.get("defender_target_world") or dfn
    center_offset = abs(att[0] - dfn[0]) + abs(att[1] - dfn[1])
    contact_clear = float(contact.get("contact_distance") or 99)
    overlap = float(contact.get("body_overlap") or 0)
    sep = float(contact.get("silhouette_separation") or center_offset)
    score = 0.0
    score += 1.0 if 0.18 <= center_offset <= 1.40 else 0.0
    score += 1.0 if contact_clear <= 0.16 else 0.0
    score += 1.0 if 0.28 <= overlap <= 1.35 else 0.0
    score += 1.0 if sep >= 0.22 else 0.0
    score += 1.0 if abs(sock[2] - tgt[2]) < 0.42 else 0.0
    return {
        "score": score,
        "ok": score >= 4.0,
        "center_offset": round(center_offset, 4),
        "silhouette_separation": round(sep, 4),
        "contact_distance": contact_clear,
        "body_overlap": overlap,
    }


__all__ = [
    "CANONICAL_FORWARD",
    "COMBAT_PRESETS",
    "bounds_center",
    "bounds_size",
    "camera_location",
    "camera_look_at",
    "combat_preset_for",
    "composition_score",
    "frame_pair",
    "frame_subject",
    "mesh_bounds",
]
