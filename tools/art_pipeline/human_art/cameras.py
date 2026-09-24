"""Deterministic review cameras. Geometry-agnostic; forward comes from the skeleton contract."""
from __future__ import annotations

import math
from dataclasses import dataclass

# Rest-pose Foot/Toes travel +Y. glTF Y-up export maps that to Godot -Z.
CANONICAL_FORWARD = (0.0, 1.0, 0.0)
FRONT_MARKER_NAME = "AA_FrontMarker"

# Prompt names plus the proven v4 aliases they map onto.
PRESET_ALIASES = {
    "FRONT": "FRONT_ORTHO",
    "FRONT_3Q": "FRONT_3Q",
    "SIDE": "SIDE",
    "BACK": "BACK",
    "GAMEPLAY": "GAMEPLAY_LEFT",
    "SELECT_PREVIEW": "FRONT_3Q",
    "HEAD_DETAIL": "DETAIL_HEAD",
    "HAND_DETAIL": "DETAIL_HANDS",
    "BOOT_DETAIL": "DETAIL_FEET",
    "COSTUME_DETAIL": "DETAIL_COSTUME",
    "HEAVY_PAIR": "HEAVY_PAIR",
    "CLASH_PAIR": "CLASH_PAIR",
}


@dataclass(frozen=True)
class CameraPreset:
    name: str
    yaw_from_forward_deg: float
    pitch_deg: float
    distance: float
    height: float
    lens: float
    ortho: bool
    look_height: float
    look_x: float = 0.0
    look_y: float = 0.0


PRESETS: dict[str, CameraPreset] = {
    "FRONT_ORTHO": CameraPreset("FRONT_ORTHO", 0.0, 6.0, 3.35, 1.08, 45, True, 0.98),
    "FRONT_3Q": CameraPreset("FRONT_3Q", 38.0, 8.0, 3.45, 1.16, 45, False, 1.02),
    "SIDE": CameraPreset("SIDE", 90.0, 4.0, 3.35, 1.08, 45, False, 0.98),
    "BACK": CameraPreset("BACK", 180.0, 6.0, 3.35, 1.08, 45, True, 0.98),
    "GAMEPLAY_LEFT": CameraPreset("GAMEPLAY_LEFT", 18.0, 10.0, 3.20, 1.12, 40, False, 0.96),
    "GAMEPLAY_RIGHT": CameraPreset("GAMEPLAY_RIGHT", -18.0, 10.0, 3.20, 1.12, 40, False, 0.96),
    "DETAIL_HEAD": CameraPreset("DETAIL_HEAD", 22.0, 8.0, 1.15, 1.62, 85, False, 1.58),
    "DETAIL_HANDS": CameraPreset("DETAIL_HANDS", 32.0, -8.0, 1.15, 1.10, 90, False, 1.08, 0.42, 0.10),
    "DETAIL_FEET": CameraPreset("DETAIL_FEET", 28.0, -12.0, 1.20, 0.38, 90, False, 0.10, 0.10, 0.16),
    "DETAIL_COSTUME": CameraPreset("DETAIL_COSTUME", 32.0, 6.0, 1.55, 1.22, 70, False, 1.18),
    "SILHOUETTE": CameraPreset("SILHOUETTE", 0.0, 4.0, 3.40, 1.05, 45, True, 0.98),
    "HEAVY_PAIR": CameraPreset("HEAVY_PAIR", 28.0, 8.0, 3.55, 1.16, 36, False, 1.08),
    "CLASH_PAIR": CameraPreset("CLASH_PAIR", 18.0, 8.0, 3.65, 1.18, 32, False, 1.12),
}


def resolve_preset(name: str) -> CameraPreset:
    key = PRESET_ALIASES.get(name, name)
    if key not in PRESETS:
        raise KeyError(f"unknown review camera {name}")
    return PRESETS[key]


def _rot_yaw(forward: tuple[float, float, float], yaw_deg: float) -> tuple[float, float, float]:
    fx, fy, fz = forward
    rad = math.radians(yaw_deg)
    c, s = math.cos(rad), math.sin(rad)
    return (fx * c - fy * s, fx * s + fy * c, fz)


def camera_location(preset: CameraPreset, forward: tuple[float, float, float] = CANONICAL_FORWARD) -> tuple[float, float, float]:
    hx, hy, hz = _rot_yaw(forward, preset.yaw_from_forward_deg)
    length = math.sqrt(hx * hx + hy * hy + hz * hz) or 1.0
    hx, hy, hz = hx / length, hy / length, hz / length
    pitch = math.radians(preset.pitch_deg)
    lift = math.sin(pitch) * preset.distance
    run = math.cos(pitch) * preset.distance
    return (hx * run, hy * run, preset.height + lift)


def camera_look_at(preset: CameraPreset) -> tuple[float, float, float]:
    return (preset.look_x, preset.look_y, preset.look_height)


def front_facing_ok(cam_loc: tuple[float, float, float], forward: tuple[float, float, float] = CANONICAL_FORWARD) -> bool:
    return (cam_loc[0] * forward[0] + cam_loc[1] * forward[1]) > 0.25


def back_facing_ok(cam_loc: tuple[float, float, float], forward: tuple[float, float, float] = CANONICAL_FORWARD) -> bool:
    return (cam_loc[0] * forward[0] + cam_loc[1] * forward[1]) < -0.25


def three_q_ok(cam_loc: tuple[float, float, float], forward: tuple[float, float, float] = CANONICAL_FORWARD) -> bool:
    fx, fy = forward[0], forward[1]
    cx, cy = cam_loc[0], cam_loc[1]
    cam_yaw = math.degrees(math.atan2(cy, cx)) if (cx or cy) else 0.0
    fwd_yaw = math.degrees(math.atan2(fy, fx))
    delta = abs((cam_yaw - fwd_yaw + 180.0) % 360.0 - 180.0)
    return 25.0 <= delta <= 55.0


def evaluate_presets(forward: tuple[float, float, float] = CANONICAL_FORWARD) -> dict:
    rows = {}
    for name, preset in PRESETS.items():
        loc = camera_location(preset, forward)
        rows[name] = {
            "location": [round(v, 4) for v in loc],
            "look_at": [round(v, 4) for v in camera_look_at(preset)],
            "yaw_from_forward_deg": preset.yaw_from_forward_deg,
            "front_facing": front_facing_ok(loc, forward),
            "back_facing": back_facing_ok(loc, forward),
            "three_q": three_q_ok(loc, forward),
        }
    front_ok = bool(rows["FRONT_ORTHO"]["front_facing"] and not rows["FRONT_ORTHO"]["back_facing"])
    back_ok = bool(rows["BACK"]["back_facing"] and not rows["BACK"]["front_facing"])
    q_ok = bool(rows["FRONT_3Q"]["three_q"] and rows["FRONT_3Q"]["front_facing"])
    return {
        "forward": list(forward),
        "front_marker": FRONT_MARKER_NAME,
        "presets": rows,
        "FRONT_ORTHO_FACES_MARKER": front_ok,
        "BACK_OPPOSITE": back_ok,
        "FRONT_3Q_DETERMINISTIC": q_ok,
        "REVIEW_CAMERA_FRONT_CORRECT_PASS": front_ok,
        "ok": front_ok and back_ok and q_ok,
    }
