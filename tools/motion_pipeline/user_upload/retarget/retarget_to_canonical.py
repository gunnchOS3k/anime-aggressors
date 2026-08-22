#!/usr/bin/env python3
"""Retarget normalized motion to canonical humanoid rig (stub — future-ready)."""
from __future__ import annotations

import json
from pathlib import Path

CANONICAL_BONES = [
    "Root", "Hips", "Spine", "Chest", "Neck", "Head",
    "Shoulder_L", "UpperArm_L", "LowerArm_L", "Hand_L",
    "Shoulder_R", "UpperArm_R", "LowerArm_R", "Hand_R",
    "UpperLeg_L", "LowerLeg_L", "Foot_L", "Toes_L",
    "UpperLeg_R", "LowerLeg_R", "Foot_R", "Toes_R",
]


def retarget(normalized_path: Path, out_path: Path) -> dict:
    payload = json.loads(normalized_path.read_text(encoding="utf-8"))
    result = {
        "schema_version": 1,
        "source": str(normalized_path.name),
        "target_rig": "canonical_humanoid_v1",
        "bones_mapped": CANONICAL_BONES,
        "retarget_status": "STUB_READY",
        "final_animation": False,
        "real_user_motion": payload.get("real_user_motion", True),
        "note": "Full retarget requires Blender/human review; pipeline hook only",
    }
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    return {"ok": True, "output": str(out_path)}


def main() -> int:
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.input is None:
        print(json.dumps({"ok": True, "mode": "ready", "bones": CANONICAL_BONES}))
        return 0
    result = retarget(args.input, args.output or args.input.with_suffix(".retarget.json"))
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
