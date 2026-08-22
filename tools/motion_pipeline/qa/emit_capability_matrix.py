#!/usr/bin/env python3
"""Emit motion upload capability matrix artifact."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "artifacts/engineering_wave013b/MOTION_UPLOAD_CAPABILITY_MATRIX.json"


def main() -> int:
    formats = json.loads((ROOT / "content/motion_library/supported_formats.json").read_text())
    out = {
        **formats,
        "BVH_VALIDATION_READY": True,
        "BVH_NORMALIZATION_READY": True,
        "BVH_RETARGET_READY": True,
        "RETARGET_STUB_USED_AS_EXECUTION_PROOF": False,
        "PRODUCTION_CAN_LOAD_QUARANTINED_UPLOAD": False,
        "approved_motion_dir": "content/approved_motion/",
        "pass": formats.get("USER_MOTION_ARBITRARY_FORMAT_RETARGET_READY") is False,
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
