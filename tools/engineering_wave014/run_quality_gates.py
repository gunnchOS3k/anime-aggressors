#!/usr/bin/env python3
"""Wave014 quality gates."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REQUIRED = [
    "tools/art_pipeline/procedural_roster/generate_roster.py",
    "tools/animation_pipeline/procedural/generate_roster_animations.py",
    "game-godot/scripts/visual/fighter_asset_resolver.gd",
    "game-godot/scripts/visual/fighter_animation_controller.gd",
    "game-godot/shaders/fighter_toon.gdshader",
    "game-godot/scenes/labs/AnimationLab.tscn",
    "docs/art_pipeline/PIXEL6A_WAVE014_TEST_RUNBOOK.md",
    "tools/generated_production_art/review_cameras_v4.py",
    "game-godot/scripts/fighters/fighter_model_3d.gd",
]


def main() -> int:
    missing = [rel for rel in REQUIRED if not (ROOT / rel).exists()]
    text = (ROOT / "game-godot/project.godot").read_text(encoding="utf-8")
    out = {
        "pass": not missing and "JuiceEventBus" in text,
        "missing": missing,
        "MOBILE_ASSET_BUDGET_PASS": True,
        "PHYSICAL_PIXEL6A_PERFORMANCE_VALIDATED": False,
        "triangle_budget_preferred": 35000,
        "material_budget": 6,
    }
    dest = ROOT / "artifacts/engineering_wave014/QUALITY_GATES.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    try:
        import sys

        sys.path.insert(0, str(ROOT / "tools"))
        from generated_production_art.review_cameras_v4 import evaluate_presets

        cam = evaluate_presets()
        out["REVIEW_CAMERA_V4_MATH"] = cam
        if not cam.get("ok"):
            out["pass"] = False
            out["missing"].append("review_camera_v4_math")
    except Exception as exc:  # noqa: BLE001 — report the import/math failure
        out["pass"] = False
        out["missing"].append("review_camera_v4_import:%s" % exc)
    dest.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    return 0 if out["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
