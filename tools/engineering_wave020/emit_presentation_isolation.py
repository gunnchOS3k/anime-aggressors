#!/usr/bin/env python3
"""Emit Wave020 presentation isolation contract artifacts."""
from __future__ import annotations

import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "engineering_wave020"
ACCEPTED_MAIN = "5697f078d3f698c583e09f2b753d433e35fc3eed"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def git_head() -> str:
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    except Exception:
        return "UNKNOWN"


def read_json(name: str) -> dict:
    p = ART / name
    if not p.is_file():
        return {}
    return json.loads(p.read_text())


def main() -> None:
    ART.mkdir(parents=True, exist_ok=True)
    select = read_json("SELECT_LIFECYCLE_DIAGNOSTIC_RESULT.json")
    material = read_json("MATERIAL_PERSISTENCE_DIAGNOSTIC_RESULT.json")
    transform = read_json("TRANSFORM_ISOLATION_DIAGNOSTIC_RESULT.json")
    reg014 = read_json("OWNER_REG_014_015_RESULT.json")

    transform_contract = {
        "wave": "WAVE020_PRESENTATION_STATE_ISOLATION",
        "ACCEPTED_MAIN_SHA": ACCEPTED_MAIN,
        "HEAD": git_head(),
        "architecture": "IMMUTABLE_CANONICAL_ASSET -> CONTEXT_LOCAL_INSTANCE -> CONTEXT_LOCAL_WRAPPER",
        "contexts": [
            "SELECT_CARD",
            "SELECT_PREVIEW",
            "VERSUS",
            "BATTLE_P1",
            "BATTLE_P2_CPU",
            "MOVE_PREVIEW",
            "VICTORY",
            "TRAINING",
        ],
        "rules": [
            "never_mutate_shared_source_resources_at_runtime",
            "never_scale_model_root_for_preview",
            "camera_and_display_wrapper_only",
            "context_owns_live_instance_generation_token",
        ],
        "contracts": {
            "BATTLE_DISPLAY_SCALE": {"x": 0.85, "y": 0.85},
            "SELECT_PREVIEW_DISPLAY_SCALE": {"x": 1.35, "y": 1.35},
            "MOVE_PREVIEW_DISPLAY_SCALE": {"x": 1.05, "y": 1.05},
            "MODEL_ROOT_SCALE": {"x": 1.0, "y": 1.0, "z": 1.0},
            "MAX_BATTLE_DISPLAY_SCALE": 1.05,
            "MAX_PREVIEW_DISPLAY_SCALE": 1.45,
        },
        "diagnostic_transform_leaks": transform.get("CROSS_CONTEXT_SCALE_LEAKS", None),
        "emitted_at": now(),
    }
    (ART / "PRESENTATION_CONTEXT_TRANSFORM_CONTRACT.json").write_text(
        json.dumps(transform_contract, indent=2) + "\n"
    )

    material_contract = {
        "wave": "WAVE020_PRESENTATION_STATE_ISOLATION",
        "ACCEPTED_MAIN_SHA": ACCEPTED_MAIN,
        "HEAD": git_head(),
        "rules": [
            "duplicate_materials_on_bind",
            "resource_local_to_scene_on_mesh_override",
            "texture_cache_immutable_bakes_only",
            "no_shared_mutable_material_controller_across_contexts",
        ],
        "MIN_MATERIAL_LUMA": 0.08,
        "diagnostic_whiteout_cases": material.get("UNEXPECTED_WHITEOUT_CASES", None),
        "diagnostic_material_mismatches": material.get("MATERIAL_IDENTITY_MISMATCHES", None),
        "witness_v2_fields": [
            "FINAL_SCREEN_BODY_PRESENT_PASS",
            "FINAL_SCREEN_IDENTITY_MATCH_PASS",
            "FINAL_SCREEN_MATERIAL_IDENTITY_PASS",
            "FINAL_SCREEN_SCALE_CONTRACT_PASS",
        ],
        "emitted_at": now(),
    }
    (ART / "FIGHTER_MATERIAL_IDENTITY_CONTRACT.json").write_text(
        json.dumps(material_contract, indent=2) + "\n"
    )

    cache_audit = {
        "wave": "WAVE020_PRESENTATION_STATE_ISOLATION",
        "ACCEPTED_MAIN_SHA": ACCEPTED_MAIN,
        "HEAD": git_head(),
        "cache_policy": {
            "live_subviewport": "one_per_context_owner_freed_on_exit_tree",
            "texture_cache": "fighter_id::context immutable ImageTexture bakes only",
            "cross_context_reuse": "forbidden_for_live_nodes",
            "generation_tokens": ["configure_generation", "preview_generation", "bake_generation"],
        },
        "select_lifecycle": {
            "roster_sweeps": select.get("SELECT_DIAGNOSTIC_ROSTER_SWEEPS", 0),
            "transitions": select.get("SELECT_DIAGNOSTIC_TRANSITIONS", 0),
            "disappearance_cases": select.get("SELECT_DISAPPEARANCE_CASES", 0),
        },
        "owner_reg_014_015": reg014,
        "emitted_at": now(),
    }
    (ART / "PRESENTATION_CACHE_LIFECYCLE_AUDIT.json").write_text(
        json.dumps(cache_audit, indent=2) + "\n"
    )
    print(json.dumps({"ok": True, "artifacts": 3}, indent=2))


if __name__ == "__main__":
    main()
