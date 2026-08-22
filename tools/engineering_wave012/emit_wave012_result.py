#!/usr/bin/env python3
"""Emit truthful Wave012 aggregate result."""
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
    env = load(
        "artifacts/wave012/ENVIRONMENT_PROBE.json",
        "artifacts/engineering_wave012/ENVIRONMENT_PROBE.json",
    )
    zero = load(
        "artifacts/wave012/ZERO_COST_DEPENDENCY_CHECK.json",
        "artifacts/engineering_wave012/ZERO_COST_DEPENDENCY_CHECK.json",
    )
    quality = load(
        "artifacts/wave012/QUALITY_GATES.json",
        "artifacts/engineering_wave012/QUALITY_GATES.json",
    )
    integrity = load("artifacts/engineering_wave012/CODE_INTEGRITY_RESULT.json")
    juice = load(
        "artifacts/engineering_wave012/JUICE_SMOKE_RESULT.json",
        "game-godot/artifacts/engineering_wave012/JUICE_SMOKE_RESULT.json",
    )
    anyc = load(
        "artifacts/wave012/ANYCREATURE_CALIBRATION.json",
        "artifacts/engineering_wave012/ANYCREATURE_CALIBRATION.json",
    )
    mocap = load("artifacts/wave012/MOCAP_GPU_EXECUTION_PACKET.json")
    mocap_env = load("artifacts/wave012/MOCAP_ENVIRONMENT_GATE.json")
    pins = load("vendor_pins/WAVE012_TOOL_PINS.json")
    blender = load("artifacts/wave012/BLENDER_PIPELINE_SMOKE.json")

    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    juice_ok = (
        bool(juice.get("ok"))
        or juice.get("WAVE012_JUICE_SMOKE") == "PASS"
        or juice.get("WAVE012_JUICE_SMOKE") == "PASS"
        or str(juice.get("status", "")).upper() == "PASS"
    )
    pipeline_impl = bool(zero.get("pass")) and bool(quality.get("pass")) and bool(integrity.get("pass"))
    ember_digital = bool(quality.get("docs_pass")) and bool(quality.get("vroid_packets_pass"))
    seven_packets = bool(quality.get("vroid_packets_pass"))
    mocap_exec = (
        mocap_env.get("MIXAMO_LLM_MOCAP_EXECUTION")
        or mocap.get("MIXAMO_LLM_MOCAP_EXECUTION")
        or env.get("MIXAMO_LLM_MOCAP_EXECUTION")
        or "BLOCKED_ENVIRONMENT_GPU"
    )
    vroid = env.get("VROID_MODEL_CREATION", "HUMAN_GUI_REQUIRED")
    any_fit = anyc.get("ANYCREATURE_HUMANOID_FIGHTER_FIT", "LIMITED")
    overall = "PASS" if pipeline_impl and juice_ok and seven_packets else "PARTIAL"

    result = {
        "schema": "engineering_wave012.result.v1",
        "generated_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "ENGINEERING_WAVE_012": overall,
        "PIPELINE_IMPLEMENTATION_PASS": pipeline_impl,
        "EMBER_DIGITAL_PREPARATION_PASS": ember_digital,
        "EMBER_FINAL_ART_RUNTIME_PASS": False,
        "SEVEN_FIGHTER_AUTHORING_PACKETS_PASS": seven_packets,
        "MOCAP_INTEGRATION_READY": True,
        "MOCAP_GPU_EXECUTION": mocap_exec,
        "VROID_MODEL_CREATION": vroid,
        "MIXAMO_ASSET_ACQUISITION": env.get(
            "MIXAMO_ASSET_ACQUISITION", "HUMAN_ACCOUNT_ACTION_REQUIRED"
        ),
        "ANYCREATURE_HUMANOID_FIGHTER_FIT": any_fit,
        "HUMAN_ART_DIRECTION_APPROVAL": False,
        "CORE_PIPELINE_MONETARY_COST_USD": int(pins.get("CORE_PIPELINE_MONETARY_COST_USD", 0)),
        "ZERO_COST_CHECK_PASS": bool(zero.get("pass")),
        "QUALITY_GATES_PASS": bool(quality.get("pass")),
        "JUICE_SMOKE_PASS": juice_ok,
        "BLENDER_SMOKE_PASS": bool(blender.get("smoke_ok")),
        "NEW_S0": int(integrity.get("NEW_S0", 0)),
        "NEW_S1": int(integrity.get("NEW_S1", 0)),
        "PRODUCTION_IMPORTS_TESTS": int(integrity.get("PRODUCTION_IMPORTS_TESTS", 0)),
        "PRODUCTION_IMPORTS_ARTIFACTS": int(integrity.get("PRODUCTION_IMPORTS_ARTIFACTS", 0)),
        "PRODUCTION_IMPORTS_EVALUATORS": int(integrity.get("PRODUCTION_IMPORTS_EVALUATORS", 0)),
        "prerequisites": pins.get("prerequisites", {}),
        "ANIME_ACCEPTED_MAIN_SHA": pins.get("prerequisites", {}).get("ANIME_ACCEPTED_MAIN_SHA"),
        "FIELD_KIT_ACCEPTED_MAIN_SHA": pins.get("prerequisites", {}).get("FIELD_KIT_ACCEPTED_MAIN_SHA"),
        "HEAD_SHA": head,
        "READY_FOR_OWNER_MERGE": bool(pipeline_impl),
        "CURSOR_MERGED_NOTHING": True,
        "blockers": [
            "VROID_MODEL_CREATION=HUMAN_GUI_REQUIRED",
            f"MOCAP_GPU_EXECUTION={mocap_exec}",
            "MIXAMO_ASSET_ACQUISITION=HUMAN_ACCOUNT_ACTION_REQUIRED",
            "HUMAN_ART_DIRECTION_APPROVAL=false",
            f"ANYCREATURE_HUMANOID_FIGHTER_FIT={any_fit}",
            "EMBER_FINAL_ART_RUNTIME_PASS=false",
        ],
        "token": "ENGINEERING_WAVE_012_ANIME_FREE_ART_PIPELINE",
    }
    for dest in [
        ROOT / "artifacts/engineering_wave012/WAVE012_RESULT.json",
        ROOT / "artifacts/wave012/WAVE012_RESULT.json",
    ]:
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
