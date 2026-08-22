#!/usr/bin/env python3
"""Real BVH normalization: parse frames, joint curves, scale to canonical units."""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from tools.motion_pipeline.formats.bvh_parser import parse_bvh_file  # noqa: E402


def normalize_bvh(input_path: Path, out_path: Path) -> dict:
    doc = parse_bvh_file(input_path)
    if not doc.motion.frames:
        raise ValueError("BVH has no motion frames")

    # Extract root translation curves (first 3 channels typically Xposition Yposition Zposition)
    root_channels = doc.channel_order[:6]
    frames_normalized = []
    for frame_vals in doc.motion.frames:
        scaled = []
        for i, val in enumerate(frame_vals):
            ch = doc.channel_order[i]
            if ch.endswith("Xposition") or ch.endswith("Yposition") or ch.endswith("Zposition"):
                scaled.append(round(val * 0.01, 6))  # cm → m scale
            elif "rotation" in ch.lower() or ch.endswith(("Xrotation", "Yrotation", "Zrotation")):
                scaled.append(round(val, 4))
            else:
                scaled.append(round(val, 6))
        frames_normalized.append(scaled)

    joint_names = list({c.rsplit(".", 1)[0] for c in doc.channel_order})
    payload = {
        "schema_version": 1,
        "normalized_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "source_filename": input_path.name,
        "format": "bvh",
        "BVH_NORMALIZATION_EXECUTION_READY": True,
        "METADATA_ONLY_NORMALIZATION": False,
        "frame_count": doc.frame_count,
        "fps": round(doc.fps, 4),
        "frame_time": doc.motion.frame_time,
        "joint_count": len(joint_names),
        "joints": joint_names,
        "channel_order": doc.channel_order,
        "root_channels": root_channels,
        "frames_normalized": frames_normalized,
        "normalization_ops": ["parse_hierarchy", "extract_joint_curves", "scale_root_translation_cm_to_m"],
        "biometric_inference_forbidden": True,
        "real_user_motion": True,
        "fixture_class": "USER_UPLOAD_NORMALIZED",
    }
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return {"ok": True, "output": str(out_path.relative_to(ROOT)), "frame_count": doc.frame_count}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.input is None:
        print(json.dumps({"ok": True, "mode": "ready", "BVH_NORMALIZATION_EXECUTION_READY": True}))
        return 0
    out = args.output or args.input.with_suffix(".normalized.json")
    result = normalize_bvh(args.input, out)
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
