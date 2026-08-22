#!/usr/bin/env python3
"""Behavioral sabotage checks for Wave014 truth model (section 33 — 12+ cases)."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def _load(rel: str) -> dict:
    p = ROOT / rel
    return json.loads(p.read_text(encoding="utf-8")) if p.exists() else {}


CHECKS = [
    ("procedural_not_final_art", lambda: _load("vendor_pins/WAVE014_TOOL_PINS.json").get("flags", {}).get("FINAL_CHARACTER_ART_PASS") is False),
    ("procedural_animation_not_final", lambda: _load("vendor_pins/WAVE014_TOOL_PINS.json").get("flags", {}).get("FINAL_HUMAN_AUTHORED_ANIMATION_PASS") is False),
    ("human_art_direction_false", lambda: _load("vendor_pins/WAVE014_TOOL_PINS.json").get("flags", {}).get("HUMAN_ART_DIRECTION_APPROVAL") is False),
    ("real_user_motion_false", lambda: _load("vendor_pins/WAVE014_TOOL_PINS.json").get("flags", {}).get("REAL_USER_MOTION_LIBRARY_PRESENT") is False),
    ("edmund_motion_false", lambda: _load("vendor_pins/WAVE014_TOOL_PINS.json").get("flags", {}).get("EDMUND_PERSONAL_MOTION_USED") is False),
    ("zero_cost", lambda: int(_load("vendor_pins/WAVE014_TOOL_PINS.json").get("CORE_PIPELINE_MONETARY_COST_USD", 1)) == 0),
    ("physics_authoritative_root_motion", lambda: "PHYSICS_AUTHORITATIVE" in (ROOT / "tools/art_pipeline/procedural_roster/rig.py").read_text(encoding="utf-8")),
    ("asset_resolver_exists", lambda: (ROOT / "game-godot/scripts/visual/fighter_asset_resolver.gd").exists()),
    ("animation_observes_not_manufactures", lambda: "does not author gameplay" in (ROOT / "game-godot/scripts/visual/fighter_animation_controller.gd").read_text(encoding="utf-8").lower()),
    ("no_hardcoded_wave014_pass_in_production", lambda: "ENGINEERING_WAVE_014=PASS" not in (ROOT / "game-godot/scripts/fighters/fighter.gd").read_text(encoding="utf-8", errors="ignore") if (ROOT / "game-godot/scripts/fighters/fighter.gd").exists() else True),
    ("seven_distinct_silhouettes", lambda: _load("artifacts/engineering_wave014/SILHOUETTE_DISTINCTNESS.json").get("MODEL_LEVEL_VISUAL_COLLISION_PAIRS", 1) == 0),
    ("animation_curve_collisions_zero", lambda: _load("artifacts/engineering_wave014/ANIMATION_DISTINCTNESS.json").get("IDENTICAL_RUNTIME_ANIMATION_CURVE_COLLISIONS", 1) == 0),
    ("procedural_proxy_status", lambda: _load("artifacts/engineering_wave014/PROCEDURAL_CHARACTER_RESULT.json").get("status") == "PROCEDURAL_PRODUCTION_PROXY"),
    ("clip_count_minimum", lambda: int(_load("artifacts/engineering_wave014/PROCEDURAL_ANIMATION_RESULT.json").get("total_clips", 0)) >= 315),
    ("signature_clip_minimum", lambda: int(_load("artifacts/engineering_wave014/PROCEDURAL_ANIMATION_RESULT.json").get("signature_clips", 0)) >= 56),
    ("physical_pixel6a_not_claimed", lambda: _load("artifacts/engineering_wave014/PERFORMANCE_SMOKE.json").get("PHYSICAL_PIXEL6A_VALIDATED") is False),
]


def main() -> int:
    results = []
    invalid = 0
    for name, fn in CHECKS:
        try:
            ok = bool(fn())
        except Exception as exc:  # noqa: BLE001
            ok = False
            err = str(exc)
            invalid += 1
        else:
            err = None
            if not ok:
                invalid += 1
        results.append({"check": name, "pass": ok, "error": err})
    passed = sum(1 for r in results if r["pass"])
    out = {
        "checks": results,
        "passed": passed,
        "total": len(results),
        "INVALID_SABOTAGE_CASES": invalid,
        "pass": passed == len(results) and len(results) >= 12 and invalid == 0,
    }
    dest = ROOT / "artifacts/engineering_wave014/SABOTAGE_CHECKS.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    return 0 if out["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
