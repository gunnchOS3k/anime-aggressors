"""Shared helpers for procedural runtime animation generation."""
from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[3]

BONES = [
    "Spine", "Chest", "UpperArm_R", "LowerArm_R", "Hand_R",
    "UpperArm_L", "LowerArm_L", "UpperLeg_R", "LowerLeg_R", "UpperLeg_L", "LowerLeg_L",
]

FIGHTERS = [
    "ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
    "nix-calder", "orion-vell", "vesper-nyx",
]


def load_blueprints() -> dict:
    return json.loads((ROOT / "content/choreography/fighter_motion_blueprints.json").read_text(encoding="utf-8"))


def fighter_seed(fighter_id: str, action_id: str, extra: str = "") -> float:
    digest = hashlib.sha256(f"{fighter_id}:{action_id}:{extra}".encode("utf-8")).hexdigest()
    return int(digest[:8], 16) / 0xFFFFFFFF


def blueprint_for(fighter_id: str, blueprints: dict) -> dict:
    return blueprints.get("fighters", {}).get(fighter_id, {})


def generate_bone_tracks(spec: dict, blueprint: dict) -> dict[str, list[dict[str, Any]]]:
    fighter_id = spec.get("fighter_id", "")
    action_id = spec.get("action_id", "")
    timing = spec.get("timing", {})
    total = max(int(timing.get("total_frames", 24)), 8)
    antic = int(timing.get("anticipation_frames", 3))
    active = int(timing.get("active_frames", 4))
    tempo = float(blueprint.get("timing", {}).get("tempo_scale", 1.0))
    root_style = str(blueprint.get("root_motion", {}).get("style", "neutral"))
    lane_offset = fighter_seed(fighter_id, action_id, root_style) * 0.8 + 0.2
    category = str(spec.get("category", "neutral"))

    tracks: dict[str, list[dict[str, Any]]] = {}
    for bone in BONES:
        keys: list[dict[str, Any]] = []
        base = fighter_seed(fighter_id, action_id, bone) * math.pi
        amp = 0.08 + fighter_seed(fighter_id, bone, category) * 0.35
        if bone.endswith("_R") and "hand" in str(spec.get("motion_grammar", {}).get("contact_points", ["hand_r"])[0]):
            amp += 0.18
        if "signature" in action_id:
            amp += 0.22 * tempo
        for frame in (0, antic, antic + active // 2, antic + active, total):
            t = frame / 60.0
            phase = frame / max(total, 1)
            rot_x = math.sin(base + phase * math.pi * 2.0) * amp * lane_offset
            rot_y = math.cos(base * 1.3 + phase * math.pi) * amp * 0.6
            rot_z = math.sin(base * 0.7 + phase * math.pi * 1.5) * amp * (1.1 if root_style == "burst_forward" else 0.8)
            if bone == "Spine":
                rot_x *= 0.5
            keys.append({"frame": frame, "time_s": round(t, 4), "rotation_rad": [round(rot_x, 5), round(rot_y, 5), round(rot_z, 5)]})
        tracks[bone] = keys
    return tracks


def curve_signature(tracks: dict) -> str:
    flat = []
    for bone, keys in sorted(tracks.items()):
        for key in keys:
            flat.extend(key["rotation_rad"])
    return hashlib.sha256(",".join(f"{v:.5f}" for v in flat).encode("utf-8")).hexdigest()
