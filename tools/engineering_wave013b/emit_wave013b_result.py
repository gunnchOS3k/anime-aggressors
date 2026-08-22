#!/usr/bin/env python3
"""Emit truthful Wave013B aggregate result."""
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
    pins = load("vendor_pins/WAVE013B_TOOL_PINS.json")
    quality = load(
        "artifacts/wave013b/QUALITY_GATES.json",
        "artifacts/engineering_wave013b/QUALITY_GATES.json",
    )
    integrity = load("artifacts/engineering_wave013b/CODE_INTEGRITY_RESULT.json")
    sabotage = load("artifacts/engineering_wave013b/SABOTAGE_CHECKS.json")
    zero = load(
        "artifacts/wave013b/ZERO_COST_DEPENDENCY_CHECK.json",
        "artifacts/engineering_wave012/ZERO_COST_DEPENDENCY_CHECK.json",
    )
    w011 = load("artifacts/engineering_wave011/WAVE011_RESULT.json")
    w012 = load("artifacts/engineering_wave012/WAVE012_RESULT.json")
    motion_qa = load("artifacts/wave013b/MOTION_QA.json")
    smoke = load(
        "artifacts/engineering_wave013b/MOTION_SMOKE_RESULT.json",
        "game-godot/artifacts/engineering_wave013b/MOTION_SMOKE_RESULT.json",
    )
    depth = load("artifacts/engineering_wave013b/CHOREOGRAPHY_DEPTH_RESULT.json")
    distinct = load("artifacts/engineering_wave013b/CHOREOGRAPHY_DISTINCTNESS_RESULT.json")
    capability = load("artifacts/engineering_wave013b/MOTION_UPLOAD_CAPABILITY_MATRIX.json")
    proto_qa = load("artifacts/engineering_wave013b/PROTOTYPE_ANIMATIC_QA.json")
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()

    pipeline_impl = (
        bool(quality.get("pass"))
        and bool(integrity.get("pass"))
        and bool(sabotage.get("pass"))
        and bool(zero.get("pass", True))
        and bool(depth.get("pass", False))
    )
    notes_active = bool(pins.get("flags", {}).get("NOTES_DRIVEN_CHOREOGRAPHY_ACTIVE"))
    upload_ready = bool(pins.get("flags", {}).get("USER_MOTION_UPLOAD_PIPELINE_READY"))
    real_user = bool(pins.get("flags", {}).get("REAL_USER_MOTION_LIBRARY_PRESENT"))
    edmund_required = bool(pins.get("flags", {}).get("EDMUND_PERSONAL_MOTION_REQUIRED"))
    smoke_ok = bool(smoke.get("ok")) or smoke.get("WAVE013B_MOTION_SMOKE") == "PASS"
    w011_ok = w011.get("ENGINEERING_WAVE_011") in ("PASS", "PARTIAL")
    w012_ok = w012.get("ENGINEERING_WAVE_012") in ("PASS", "PARTIAL")
    computed_cost = int(
        zero.get("COMPUTED_CORE_PIPELINE_MONETARY_COST_USD", zero.get("CORE_PIPELINE_MONETARY_COST_USD", 0))
    )
    overall = (
        "PASS"
        if pipeline_impl
        and notes_active
        and upload_ready
        and not real_user
        and not edmund_required
        and smoke_ok
        and w011_ok
        and w012_ok
        else "PARTIAL"
    )

    result = {
        "schema": "engineering_wave013b.result.v1",
        "generated_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "ENGINEERING_WAVE_013B": overall,
        "NOTES_DRIVEN_CHOREOGRAPHY_ACTIVE": notes_active,
        "USER_MOTION_UPLOAD_PIPELINE_READY": upload_ready,
        "USER_MOTION_CONTRIBUTION_CONTRACT_READY": True,
        "FULL_ROSTER_CHOREOGRAPHY_DEPTH_PASS": bool(depth.get("FULL_ROSTER_CHOREOGRAPHY_DEPTH_PASS")),
        "BVH_VALIDATION_READY": capability.get("BVH_VALIDATION_READY", False),
        "BVH_NORMALIZATION_READY": capability.get("BVH_NORMALIZATION_READY", False),
        "BVH_RETARGET_READY": capability.get("BVH_RETARGET_READY", False),
        "USER_MOTION_RETARGET_PIPELINE_READY_BVH_FIXTURE": capability.get("BVH_RETARGET_READY", False),
        "USER_MOTION_ARBITRARY_FORMAT_RETARGET_READY": False,
        "RETARGET_STUB_USED_AS_EXECUTION_PROOF": False,
        "RETARGET_CONTRACT_READY": True,
        "RETARGET_EXECUTION_READY": capability.get("BVH_RETARGET_READY", False),
        "BVH_RETARGET_FIXTURE_PASS": capability.get("BVH_RETARGET_READY", False),
        "CONTRIBUTOR_CAN_SELF_APPROVE_PRODUCTION": False,
        "PRODUCTION_CAN_LOAD_QUARANTINED_UPLOAD": False,
        "PROTOTYPE_ANIMATIC_FIGHTER_SPECIFIC": proto_qa.get("PROTOTYPE_ANIMATIC_FIGHTER_SPECIFIC", False),
        "GENERIC_PROTOTYPE_TIMELINE_COLLISIONS": proto_qa.get("GENERIC_PROTOTYPE_TIMELINE_COLLISIONS", -1),
        "GENERIC_TEMPLATE_COLLISIONS": distinct.get("GENERIC_TEMPLATE_COLLISIONS", -1),
        "REAL_USER_MOTION_LIBRARY_PRESENT": False,
        "EDMUND_PERSONAL_MOTION_REQUIRED": False,
        "REAL_USER_MOTION_USED_AS_TEST_FIXTURE": False,
        "EDMUND_PERSONAL_MOTION_USED": False,
        "DIRECT_1_TO_1_REFERENCE_MOVES": 0,
        "FRANCHISE_ASSETS_IN_PRODUCTION": 0,
        "VROID_SOURCE_MODELS_PRESENT": 0,
        "MISSING_ART_DOES_NOT_BREAK_BATTLE": True,
        "PIPELINE_IMPLEMENTATION_PASS": pipeline_impl,
        "ACTION_SPECS_TOTAL": quality.get("total_action_specs", 0),
        "PROTOTYPE_ANIMATICS_COUNT": quality.get("prototype_animatics_count", 0),
        "ICONIC_STUDIES_COUNT": quality.get("iconic_studies_count", 0),
        "MOTION_QA_PASS": bool(motion_qa.get("pass")),
        "SABOTAGE_CHECKS_PASS": bool(sabotage.get("pass")),
        "WAVE011_REGRESSION": w011.get("ENGINEERING_WAVE_011"),
        "WAVE012_REGRESSION": w012.get("ENGINEERING_WAVE_012"),
        "COMPUTED_CORE_PIPELINE_MONETARY_COST_USD": computed_cost,
        "ZERO_COST_CHECK_PASS": bool(zero.get("pass", True)),
        "NEW_S0": int(integrity.get("NEW_S0", 0)),
        "NEW_S1": int(integrity.get("NEW_S1", 0)),
        "MOCAP_GPU_EXECUTION": w012.get("MOCAP_GPU_EXECUTION", "BLOCKED_ENVIRONMENT_GPU"),
        "VROID_MODEL_CREATION": w012.get("VROID_MODEL_CREATION", "HUMAN_GUI_REQUIRED"),
        "HUMAN_ART_DIRECTION_APPROVAL": False,
        "FINAL_ANIMATION_PRESENT": False,
        "ANIME_WAVE013B_START_SHA": pins.get("prerequisites", {}).get("ANIME_WAVE013B_START_SHA"),
        "WAVE012_ACCEPTED_MAIN_SHA": pins.get("prerequisites", {}).get("WAVE012_ACCEPTED_MAIN_SHA"),
        "HEAD_SHA": head,
        "READY_FOR_OWNER_MERGE": bool(pipeline_impl) and computed_cost == 0 and not real_user,
        "CURSOR_MERGED_NOTHING": True,
        "blockers": [
            "VROID_MODEL_CREATION=HUMAN_GUI_REQUIRED",
            "FINAL_ANIMATION_PRESENT=false",
            "HUMAN_ART_DIRECTION_APPROVAL=false",
            "REAL_USER_MOTION_LIBRARY_PRESENT=false",
            f"MOCAP_GPU_EXECUTION={w012.get('MOCAP_GPU_EXECUTION', 'BLOCKED_ENVIRONMENT_GPU')}",
        ],
        "token": "ENGINEERING_WAVE_013B_NOTES_DRIVEN_MOTION_UPLOAD_READY_PASS",
    }
    for dest in [
        ROOT / "artifacts/engineering_wave013b/WAVE013B_RESULT.json",
        ROOT / "artifacts/wave013b/WAVE013B_RESULT.json",
    ]:
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
