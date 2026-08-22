#!/usr/bin/env python3
"""Validate character armature against canonical humanoid rig contract."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REQUIRED_BONES = [
    "Root", "Hips", "Spine", "Chest", "Neck", "Head",
    "Shoulder_L", "UpperArm_L", "LowerArm_L", "Hand_L",
    "Shoulder_R", "UpperArm_R", "LowerArm_R", "Hand_R",
    "UpperLeg_L", "LowerLeg_L", "Foot_L", "Toes_L",
    "UpperLeg_R", "LowerLeg_R", "Foot_R", "Toes_R",
]

REQUIRED_SOCKETS = [
    "hand_l", "hand_r", "foot_l", "foot_r", "chest", "head",
    "back", "projectile_origin", "aura_root",
]


def validate(manifest: dict) -> dict:
    bones = set(manifest.get("bones", []))
    sockets = set(manifest.get("sockets", []))
    missing_bones = [b for b in REQUIRED_BONES if b not in bones]
    missing_sockets = [s for s in REQUIRED_SOCKETS if s not in sockets]
    ok = not missing_bones and not missing_sockets
    return {
        "pass": ok,
        "missing_bones": missing_bones,
        "missing_sockets": missing_sockets,
        "bone_count": len(bones),
        "socket_count": len(sockets),
        "production_ready": ok and bool(manifest.get("normalized", False)),
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("manifest", type=Path, help="JSON describing bones/sockets")
    ap.add_argument("--out", type=Path, default=None)
    args = ap.parse_args()
    data = json.loads(args.manifest.read_text(encoding="utf-8"))
    result = validate(data)
    text = json.dumps(result, indent=2) + "\n"
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(text, encoding="utf-8")
    print(text)
    return 0 if result["pass"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
