#!/usr/bin/env python3
"""Pixel spectacle perf instrumentation scaffold.

Does not claim PIXEL_AUTHORED_COMBAT_PERF_PASS. No authored-combat APK this pass.
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "artifacts/vxp3/reports/PIXEL_SPECTACLE_PERF.json"

SCENES = (
    "normal_fight_baseline",
    "both_aura_100",
    "aura_clash",
    "super",
    "clash_resolution_explosion",
    "ko",
)


def main() -> None:
    rows = []
    for name in SCENES:
        rows.append(
            {
                "scene": name,
                "avg_fps": None,
                "pct1_low": None,
                "worst_frame_ms": None,
                "particle_count": None,
                "dynamic_lights": None,
                "draw_calls": None,
                "memory_delta_mb": None,
                "device": "Pixel 6a reference (not profiled this pass)",
                "measured": False,
            }
        )
    payload = {
        "PIXEL_AUTHORED_COMBAT_PERF_PASS": False,
        "PIXEL_SPECTACLE_PERF_PASS": False,
        "reason": "No authored-combat Pixel profile. Instrumentation schema only. Do not delete authored animation quality to chase frames.",
        "scenes": rows,
        "lod_policy": "If slow: LOD spectacle. Never remove authored acting quality.",
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps(payload, indent=2))


if __name__ == "__main__":
    main()
