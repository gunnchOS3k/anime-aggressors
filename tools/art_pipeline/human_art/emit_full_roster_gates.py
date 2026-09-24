#!/usr/bin/env python3
"""Emit truthful full-roster staging gates. Never promotes HUMAN_* or MERGE."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import (  # noqa: E402
    FIGHTER_IDS,
    HUMAN_GATES_FALSE,
    HUMAN_ROSTER_GATES_FALSE,
    ROOT,
    STAGING,
    candidate_manifest_path,
    write_json,
)

SCRIPTS = (
    ("FULL_ROSTER_VALIDATOR_PASS", "validate_human_roster.py"),
    ("FULL_ROSTER_REVIEW_TOOL_PASS", "review_human_roster.py"),
    ("FULL_ROSTER_IMPACT_MATRIX_PASS", "full_roster_impact_matrix.py"),
)


def run_script(name: str) -> dict:
    script = Path(__file__).resolve().parent / name
    proc = subprocess.run([sys.executable, str(script)], cwd=ROOT, text=True, capture_output=True)
    payload = {}
    if proc.stdout.strip():
        try:
            payload = json.loads(proc.stdout)
        except json.JSONDecodeError:
            payload = {"ok": proc.returncode == 0, "stdout": proc.stdout[-400:]}
    payload.setdefault("ok", proc.returncode == 0)
    return payload


def resolver_pass() -> tuple[bool, list[str]]:
    text = (ROOT / "game-godot/scripts/visual/fighter_asset_resolver.gd").read_text(encoding="utf-8")
    fails = []
    if "HUMAN_ART_FULL_ROSTER_REVIEW" not in text:
        fails.append("resolver_missing_HUMAN_ART_FULL_ROSTER_REVIEW")
    if "GENERATED_EXPERIMENT" not in text or "never" not in text.lower():
        if "GENERATED_EXPERIMENT_EXCLUDED" not in text:
            fails.append("resolver_missing_generated_exclusion")
    if "HUMAN_APPROVED" not in text or "HUMAN_CANDIDATE" not in text:
        fails.append("resolver_missing_staging_priority")
    if "CURRENT_ACCEPTED_ART" not in text:
        fails.append("resolver_missing_current_accepted_art")
    if "art_source_public_label" not in text:
        fails.append("resolver_missing_public_label")
    return not fails, fails


def staging_isolated() -> bool:
    for fid in FIGHTER_IDS:
        if not (STAGING / fid).is_dir():
            return False
        if not candidate_manifest_path(fid).is_file():
            return False
    return True


def pixel_route_pass() -> bool:
    router = (ROOT / "game-godot/scripts/core/SceneRouter.gd").read_text(encoding="utf-8")
    scene = ROOT / "game-godot/scenes/labs/FullRosterArtReviewScene.tscn"
    script = ROOT / "game-godot/scripts/labs/full_roster_art_review_scene.gd"
    return "roster_art_review" in router and scene.is_file() and script.is_file()


def main() -> int:
    results = {}
    resolver_ok, resolver_fails = resolver_pass()
    gates = {
        "FULL_ROSTER_MANIFEST_PASS": all(candidate_manifest_path(fid).is_file() for fid in FIGHTER_IDS),
        "FULL_ROSTER_STAGING_ISOLATED_PASS": staging_isolated(),
        "FULL_ROSTER_RESOLVER_PASS": resolver_ok,
        "FULL_ROSTER_VALIDATOR_PASS": False,
        "FULL_ROSTER_REVIEW_TOOL_PASS": False,
        "FULL_ROSTER_IMPACT_MATRIX_PASS": False,
        "FULL_ROSTER_PIXEL_ROUTE_PASS": pixel_route_pass(),
        "GENERATED_EXPERIMENT_NOT_SELECTED_PASS": resolver_ok,
        "FULL_ROSTER_HUMAN_CANDIDATE_CONTRACT_PASS": False,
        "FULL_ROSTER_HUMAN_CANDIDATES_COMPLETE": False,
        "HUMAN_ART_STAGING": 0,
        "HUMAN_ART_FULL_ROSTER_REVIEW": 0,
        "HUMAN_CANDIDATE_RIGHTS_READY": False,
        "Mode_B_eligible": False,
    }
    gates.update(HUMAN_GATES_FALSE)
    gates.update(HUMAN_ROSTER_GATES_FALSE)
    for gate, script in SCRIPTS:
        row = run_script(script)
        results[script] = {"ok": row.get("ok"), "complete": row.get("complete") or row.get("FULL_ROSTER_HUMAN_CANDIDATES_COMPLETE")}
        gates[gate] = bool(row.get("ok"))
        if script == "validate_human_roster.py":
            gates["FULL_ROSTER_HUMAN_CANDIDATE_CONTRACT_PASS"] = bool(row.get("complete"))
            gates["FULL_ROSTER_HUMAN_CANDIDATES_COMPLETE"] = bool(row.get("complete"))
    results["resolver"] = {"ok": resolver_ok, "failures": resolver_fails}
    required = (
        "FULL_ROSTER_MANIFEST_PASS",
        "FULL_ROSTER_STAGING_ISOLATED_PASS",
        "FULL_ROSTER_RESOLVER_PASS",
        "FULL_ROSTER_VALIDATOR_PASS",
        "FULL_ROSTER_REVIEW_TOOL_PASS",
        "FULL_ROSTER_IMPACT_MATRIX_PASS",
        "FULL_ROSTER_PIXEL_ROUTE_PASS",
        "GENERATED_EXPERIMENT_NOT_SELECTED_PASS",
    )
    payload = {
        "ok": all(gates[k] for k in required),
        "gates": gates,
        "results": results,
        "HUMAN_ART_DIRECTION_APPROVAL": False,
        "FINAL_AUTHORED_ANIMATION_PASS": False,
        "MERGE_AUTHORIZED": False,
        "note": "Infrastructure only. Human quality remains false until an owner sets it after Pixel review.",
    }
    write_json(ROOT / "artifacts/art_pipeline/FULL_ROSTER_GATES.json", payload)
    print(json.dumps(payload, indent=2))
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
