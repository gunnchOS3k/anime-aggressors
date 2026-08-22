#!/usr/bin/env python3
"""Host performance smoke for Wave014 (no physical Pixel 6a claim)."""
from __future__ import annotations

import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def main() -> int:
    glb_count = len(list((ROOT / "game-godot/content/fighters").glob("*/model/*_procedural_proxy.glb")))
    anim_count = len(list((ROOT / "game-godot/content/fighters").glob("*/animations/procedural/*.anim.json")))
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    out = {
        "pass": glb_count >= 7 and anim_count >= 315,
        "HOST_PERFORMANCE_SMOKE_PASS": glb_count >= 7 and anim_count >= 315,
        "PHYSICAL_PIXEL6A_VALIDATED": False,
        "PHYSICAL_PIXEL6A_PERFORMANCE_VALIDATED": False,
        "glb_count": glb_count,
        "anim_count": anim_count,
        "HEAD_SHA": head,
    }
    dest = ROOT / "artifacts/engineering_wave014/PERFORMANCE_SMOKE.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    return 0 if out["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
