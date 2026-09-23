#!/usr/bin/env python3
"""Deterministic roster contact-sheet pose dumps. Automation does not set human PASS."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GODOT = ROOT / "game-godot"
FIGHTERS = (
    "ember-vale",
    "rook-ironside",
    "juno-spark",
    "kaia-windrow",
    "nix-calder",
    "orion-vell",
    "vesper-nyx",
)
SHOTS = [
    "idle",
    "charged_idle",
    "walk",
    "run",
    "heavy",
    "hurt_heavy",
    "signature_lane_burst",
    "ko",
]


def pose(data: dict, frame: int) -> dict:
    out = {}
    for bone, keys in data.get("bone_tracks", {}).items():
        chosen = keys[0] if keys else {"rotation_rad": [0, 0, 0]}
        for key in keys:
            if int(key.get("frame", 0)) <= frame:
                chosen = key
        out[bone] = chosen.get("rotation_rad", [0, 0, 0])
    return out


def main() -> int:
    sheets = {"per_fighter": {}, "comparisons": {}, "human_pass": False, "automation_sets_human_pass": False}
    for fid in FIGHTERS:
        row = {}
        for name in SHOTS:
            p = GODOT / "content" / "fighters" / fid / "animations" / "procedural" / f"{name}.anim.json"
            data = json.loads(p.read_text())
            frames = int(data.get("duration_frames", 12))
            if name == "heavy":
                frames = max(2, frames // 3)
            elif name == "hurt_heavy":
                frames = max(2, frames // 2)
            row[name] = {
                "clip": name,
                "signature": data.get("curve_signature"),
                "pose": pose(data, frames),
                "not_final_art": True,
            }
        sheets["per_fighter"][fid] = row
    for name in ("walk", "run", "idle", "charged_idle", "heavy", "hurt_heavy"):
        sheets["comparisons"][name] = {fid: sheets["per_fighter"][fid][name if name != "idle" else "idle"]["signature"][:16] for fid in FIGHTERS}
    out = ROOT / "artifacts" / "vxp3" / "reports" / "VXP3_CONTACT_SHEETS.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(sheets, indent=2) + "\n")
    print(json.dumps({"ok": True, "fighters": len(FIGHTERS), "shots": len(SHOTS), "human_pass": False}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
