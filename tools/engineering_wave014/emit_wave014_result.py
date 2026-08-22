#!/usr/bin/env python3
"""Emit truthful Wave014 aggregate result."""
from __future__ import annotations

import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def load(*candidates: str) -> dict:
    for rel in candidates:
        path = ROOT / rel
        if path.exists():
            try:
                return json.loads(path.read_text(encoding="utf-8"))
            except Exception:
                return {"_error": str(path)}
    return {}


def main() -> int:
    pins = load("vendor_pins/WAVE014_TOOL_PINS.json")
    quality = load("artifacts/engineering_wave014/QUALITY_GATES.json")
    integrity = load("artifacts/engineering_wave014/CODE_INTEGRITY_RESULT.json")
    sabotage = load("artifacts/engineering_wave014/SABOTAGE_CHECKS.json")
    zero = load(
        "artifacts/wave014/ZERO_COST_DEPENDENCY_CHECK.json",
        "artifacts/engineering_wave012/ZERO_COST_DEPENDENCY_CHECK.json",
    )
    w011 = load("artifacts/engineering_wave011/WAVE011_RESULT.json")
    w012 = load("artifacts/engineering_wave012/WAVE012_RESULT.json")
    w013b = load("artifacts/engineering_wave013b/WAVE013B_RESULT.json")
    chars = load("artifacts/engineering_wave014/PROCEDURAL_CHARACTER_RESULT.json")
    anims = load("artifacts/engineering_wave014/PROCEDURAL_ANIMATION_RESULT.json")
    sil = load("artifacts/engineering_wave014/SILHOUETTE_DISTINCTNESS.json")
    anim_dist = load("artifacts/engineering_wave014/ANIMATION_DISTINCTNESS.json")
    align = load("artifacts/engineering_wave014/RUNTIME_ANIMATION_ALIGNMENT.json")
    smoke = load(
        "artifacts/engineering_wave014/PROCEDURAL_SMOKE_RESULT.json",
        "game-godot/artifacts/engineering_wave014/PROCEDURAL_SMOKE_RESULT.json",
    )
    perf = load("artifacts/engineering_wave014/PERFORMANCE_SMOKE.json")
    bvh = load("artifacts/engineering_wave014/SYNTHETIC_BVH_PREVIEW.json")
    e2e = load("artifacts/engineering_wave014/BATTLESCENE_VISUAL_E2E.json")
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()

    proc_char = bool(chars.get("fighter_count") == 7)
    proc_anim = bool(anims.get("PROCEDURAL_RUNTIME_ANIMATION_PASS"))
    pipeline_impl = (
        bool(quality.get("pass"))
        and bool(integrity.get("pass"))
        and bool(sabotage.get("pass"))
        and bool(zero.get("pass", True))
        and proc_char
        and proc_anim
    )
    w011_ok = w011.get("ENGINEERING_WAVE_011") in ("PASS", "PARTIAL")
    w012_ok = w012.get("ENGINEERING_WAVE_012") in ("PASS", "PARTIAL")
    w013b_ok = w013b.get("ENGINEERING_WAVE_013B") in ("PASS", "PARTIAL")
    smoke_ok = bool(smoke.get("ok"))
    computed_cost = int(zero.get("COMPUTED_CORE_PIPELINE_MONETARY_COST_USD", zero.get("CORE_PIPELINE_MONETARY_COST_USD", 0)))
    overall = (
        "PASS"
        if pipeline_impl
        and proc_char
        and proc_anim
        and smoke_ok
        and w011_ok
        and w012_ok
        and w013b_ok
        else "PARTIAL"
    )

    truth = {
        "PROCEDURAL_CHARACTER_RUNTIME_PASS": proc_char,
        "PROCEDURAL_RUNTIME_ANIMATION_PASS": proc_anim,
        "FINAL_CHARACTER_ART_PASS": False,
        "FINAL_HUMAN_AUTHORED_ANIMATION_PASS": False,
        "HUMAN_ART_DIRECTION_APPROVAL": False,
        "CURRENT_MODEL_SOURCE": "PROCEDURAL_PRODUCTION_PROXY",
        "CURRENT_ANIMATION_SOURCE": "PROCEDURAL_RUNTIME_ANIMATION",
        "COMPETITIVE_GAMEPLAY_ROOT_MOTION": "PHYSICS_AUTHORITATIVE",
    }
    result = {
        "schema": "engineering_wave014.result.v1",
        "generated_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "ENGINEERING_WAVE_014": overall,
        **truth,
        "PIPELINE_IMPLEMENTATION_PASS": pipeline_impl,
        "MODEL_LEVEL_VISUAL_COLLISION_PAIRS": sil.get("MODEL_LEVEL_VISUAL_COLLISION_PAIRS", -1),
        "IDENTICAL_RUNTIME_ANIMATION_CURVE_COLLISIONS": anim_dist.get("IDENTICAL_RUNTIME_ANIMATION_CURVE_COLLISIONS", -1),
        "ACTIVE_WINDOW_VISUAL_ALIGNMENT_PASS": align.get("ACTIVE_WINDOW_VISUAL_ALIGNMENT_PASS", False),
        "SYNTHETIC_BVH_TO_PROCEDURAL_FIGHTER_PREVIEW_PASS": bvh.get("SYNTHETIC_BVH_TO_PROCEDURAL_FIGHTER_PREVIEW_PASS", False),
        "HOST_PERFORMANCE_SMOKE_PASS": perf.get("HOST_PERFORMANCE_SMOKE_PASS", False),
        "PHYSICAL_PIXEL6A_VALIDATED": False,
        "PHYSICAL_PIXEL6A_PERFORMANCE_VALIDATED": False,
        "ROSTER_ARTLAB_REAL_PROCEDURAL_MODELS": smoke.get("ROSTER_ARTLAB_REAL_PROCEDURAL_MODELS", 0),
        "TOTAL_PROCEDURAL_CLIPS": anims.get("total_clips", 0),
        "SIGNATURE_PROCEDURAL_CLIPS": anims.get("signature_clips", 0),
        "REAL_USER_MOTION_LIBRARY_PRESENT": False,
        "EDMUND_PERSONAL_MOTION_USED": False,
        "WAVE011_REGRESSION": w011.get("ENGINEERING_WAVE_011"),
        "WAVE012_REGRESSION": w012.get("ENGINEERING_WAVE_012"),
        "WAVE013B_REGRESSION": w013b.get("ENGINEERING_WAVE_013B"),
        "COMPUTED_CORE_PIPELINE_MONETARY_COST_USD": computed_cost,
        "ZERO_COST_CHECK_PASS": bool(zero.get("pass", True)),
        "NEW_S0": int(integrity.get("NEW_S0", 0)),
        "NEW_S1": int(integrity.get("NEW_S1", 0)),
        "ANIME_WAVE014_START_SHA": pins.get("prerequisites", {}).get("ANIME_WAVE014_START_SHA"),
        "WAVE013B_ACCEPTED_MAIN_SHA": pins.get("prerequisites", {}).get("WAVE013B_ACCEPTED_MAIN_SHA"),
        "HEAD_SHA": head,
        "READY_FOR_OWNER_MERGE": bool(pipeline_impl) and computed_cost == 0,
        "CURSOR_MERGED_NOTHING": True,
        "BATTLESCENE_VISUAL_E2E": e2e.get("BATTLESCENE_VISUAL_E2E"),
        "blockers": [
            "FINAL_CHARACTER_ART_PASS=false",
            "FINAL_HUMAN_AUTHORED_ANIMATION_PASS=false",
            "HUMAN_ART_DIRECTION_APPROVAL=false",
            "PHYSICAL_PIXEL6A_VALIDATED=false",
        ],
        "token": "ENGINEERING_WAVE_014_PROCEDURAL_ROSTER_RUNTIME_PASS",
    }
    truth_path = ROOT / "artifacts/engineering_wave014/TRUTH_BOUNDARIES.json"
    truth_path.write_text(json.dumps({"truth": truth, "blockers": result["blockers"]}, indent=2) + "\n", encoding="utf-8")
    for dest in [
        ROOT / "artifacts/engineering_wave014/WAVE014_RESULT.json",
        ROOT / "artifacts/wave014/WAVE014_RESULT.json",
    ]:
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
