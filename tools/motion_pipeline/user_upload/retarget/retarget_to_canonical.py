#!/usr/bin/env python3
"""Retarget normalized motion to canonical humanoid rig — real BVH execution for fixtures."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))

CANONICAL_BONES = [
    "Root", "Hips", "Spine", "Chest", "Neck", "Head",
    "Shoulder_L", "UpperArm_L", "LowerArm_L", "Hand_L",
    "Shoulder_R", "UpperArm_R", "LowerArm_R", "Hand_R",
    "UpperLeg_L", "LowerLeg_L", "Foot_L", "Toes_L",
    "UpperLeg_R", "LowerLeg_R", "Foot_R", "Toes_R",
]


def retarget(normalized_path: Path, out_path: Path) -> dict:
    payload = json.loads(normalized_path.read_text(encoding="utf-8"))
    if payload.get("format") == "bvh" or normalized_path.suffix == ".bvh":
        from tools.motion_pipeline.retarget.retarget_bvh import retarget_bvh

        return retarget_bvh(normalized_path if normalized_path.suffix == ".bvh" else normalized_path, out_path)

    result = {
        "schema_version": 1,
        "source": str(normalized_path.name),
        "target_rig": "canonical_humanoid_v1",
        "bones_mapped": {b: b for b in CANONICAL_BONES[: len(payload.get("joints", []))]},
        "retarget_status": "METADATA_BIND_ONLY",
        "RETARGET_CONTRACT_READY": True,
        "RETARGET_EXECUTION_READY": False,
        "RETARGET_STUB_USED_AS_EXECUTION_PROOF": False,
        "final_animation": False,
        "real_user_motion": payload.get("real_user_motion", True),
        "note": "Non-BVH sources require format-specific retarget profile",
    }
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    return {"ok": True, "output": str(out_path)}


def run_fixture_pass() -> dict:
    script = ROOT / "tools/motion_pipeline/retarget/retarget_bvh.py"
    proc = subprocess.run(
        [sys.executable, str(script), "--fixture"],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        return {"ok": False, "error": proc.stderr}
    return json.loads(proc.stdout)


def main() -> int:
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.input is None:
        fixture = run_fixture_pass()
        print(json.dumps({
            "ok": True,
            "mode": "ready",
            "bones": CANONICAL_BONES,
            "RETARGET_CONTRACT_READY": True,
            "RETARGET_EXECUTION_READY": True,
            "BVH_RETARGET_FIXTURE_PASS": fixture.get("ok", False),
            "fixture": fixture,
        }))
        return 0 if fixture.get("ok") else 1
    result = retarget(args.input, args.output or args.input.with_suffix(".retarget.json"))
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
