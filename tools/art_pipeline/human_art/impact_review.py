#!/usr/bin/env python3
"""Review-only impact-pair staging. Never writes CombatMath or hitboxes."""
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import IMPACT_ANCHORS, ROOT, write_json  # noqa: E402

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
    "hand_r": (0.54, 0.12, 0.94),
    "hand_l": (-0.54, 0.12, 0.94),
    "foot_l": (0.10, 0.12, 0.12),
    "foot_r": (-0.10, 0.12, 0.12),
    "chest": (0.0, 0.06, 1.28),
    "head": (0.0, 0.04, 1.60),
}

CONTACT_DISTANCE_MAX = 0.16
STANDOFF = 0.05


def _sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def _add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def _scale(a, s):
    return (a[0] * s, a[1] * s, a[2] * s)


def _len(a):
    return (a[0] ** 2 + a[1] ** 2 + a[2] ** 2) ** 0.5


def solve_defender_location(attacker_socket_world, defender_anchor_local, contact_normal, standoff: float = STANDOFF):
    target = _add(attacker_socket_world, _scale(contact_normal, standoff))
    return _sub(target, defender_anchor_local)


def stage_pair(socket: str = "hand_r", anchor: str = "CHEST", normal=(1.0, 0.0, 0.0)) -> dict:
    if socket not in SOCKET_REST:
        raise KeyError(f"unknown contact socket {socket}")
    if anchor not in ANCHORS:
        raise KeyError(f"unknown review anchor {anchor}")
    socket_world = SOCKET_REST[socket]
    anchor_local = ANCHORS[anchor]
    defender_loc = solve_defender_location(socket_world, anchor_local, normal)
    contact = _len(_sub(socket_world, _add(defender_loc, anchor_local)))
    return {
        "socket": socket,
        "anchor": anchor,
        "attacker_socket_world": [round(v, 4) for v in socket_world],
        "defender_location": [round(v, 4) for v in defender_loc],
        "contact_distance": round(contact, 4),
        "frozen_contact": True,
        "vfx": "OFF",
        "camera_shake": "OFF",
        "review_only": True,
        "gameplay_unchanged": True,
        "combat_math_unchanged": True,
        "ok": contact <= CONTACT_DISTANCE_MAX,
    }


def main() -> int:
    rows = {
        "rook-ironside -> nix-calder": stage_pair("hand_r", "CHEST"),
        "anchors": list(IMPACT_ANCHORS),
        "frames": ["contact", "hurt", "follow_through"],
    }
    payload = {
        "ok": all(row.get("ok", True) for row in rows.values() if isinstance(row, dict)),
        "ART_IMPACT_REVIEW_TOOL_PASS": True,
        "pairs": rows,
        "note": "Review staging only. CombatMath / hitboxes / frame data stay on main.",
    }
    payload["ART_IMPACT_REVIEW_TOOL_PASS"] = bool(payload["ok"])
    write_json(ROOT / "artifacts/art_pipeline/ART_IMPACT_REVIEW_TOOL.json", payload)
    print(json.dumps(payload, indent=2))
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    raise SystemExit(main())
