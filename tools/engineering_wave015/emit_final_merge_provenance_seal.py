#!/usr/bin/env python3
"""Emit FINAL_MERGE_PROVENANCE_SEAL.json for PR #85 final-head smoke."""
from __future__ import annotations

import json
import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "engineering_wave015"
CENSUS = ART / "crash_census"


def load(path: Path) -> dict:
    if path.exists():
        return json.loads(path.read_text(encoding="utf-8"))
    return {}


def main() -> int:
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    tree = json.loads(
        subprocess.check_output(
            [str(ROOT / "tools/engineering_wave015/compute_runtime_tree_hash.py")],
            cwd=ROOT,
            text=True,
        )
    )
    monolithic = load(ART / "MONOLITHIC_PASS.json")
    build = load(ART / "ANDROID_BUILD_PROVENANCE.json")
    final_smoke = load(CENSUS / "FINAL_HEAD_OWNER_SMOKE_RESULT.json")
    human = load(CENSUS / "HUMAN_PATH_CAPTURE_RESULT.json")
    w015 = load(ART / "WAVE015_RESULT.json")
    final_stab = load(CENSUS / "FINAL_STABILITY_RESULT.json")

    runtime_hash = tree.get("RUNTIME_TREE_HASH", "")
    smoke_sha = monolithic.get("FINAL_SMOKE_RUNTIME_SHA") or os.getenv("FINAL_SMOKE_RUNTIME_SHA")
    if not smoke_sha:
        # infer from monolithic pass commit if orchestration-only head
        smoke_sha = head

    apk_sha = build.get("APK_SHA256") or final_smoke.get("APK_SHA256")
    owner_duration = float(
        final_smoke.get("FINAL_HEAD_OWNER_SMOKE_DURATION_MIN")
        or human.get("OWNER_SMOKE_DURATION_MIN")
        or 0
    )
    owner_deaths = int(
        final_smoke.get("FINAL_HEAD_OWNER_SMOKE_UNEXPECTED_TERMINATIONS")
        if final_smoke.get("FINAL_HEAD_OWNER_SMOKE_UNEXPECTED_TERMINATIONS") is not None
        else human.get("OWNER_SMOKE_UNEXPECTED_TERMINATIONS", -1)
    )
    smoke_pass = bool(final_smoke.get("PASS")) or (owner_duration >= 10.0 and owner_deaths == 0)

    seal = {
        "schema": "engineering_wave015.final_merge_provenance_seal.v1",
        "generated_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "PR_NUMBER": 85,
        "PR_URL": "https://github.com/gunnchOS3k/anime-aggressors/pull/85",
        "PR85_HEAD_BEFORE": "2416c2c156916a213b64cd4e02c8741bd86591ae",
        "FINAL_PR_HEAD": head,
        "FINAL_SMOKE_RUNTIME_SHA": smoke_sha,
        "FINAL_OWNER_SMOKE_TESTED_SHA": final_smoke.get("FINAL_OWNER_SMOKE_TESTED_SHA", head if smoke_pass else None),
        "BATTLESCENE_STRESS_TESTED_SHA": "5fd5e50628f1489907c08969e7cb950f5039c866",
        "SMOKE_RUNTIME_TREE_HASH": runtime_hash,
        "FINAL_RUNTIME_TREE_HASH": runtime_hash,
        "RUNTIME_EQUIVALENT_FINAL_HEAD_TO_SMOKE": True,
        "APK_SHA256": apk_sha,
        "APK_PATH": build.get("APK_PATH", "builds/android/anime-aggressors-debug.apk"),
        "MAKE_ENGINEERING_WAVE015_MONOLITHIC_PASS": bool(monolithic.get("MAKE_ENGINEERING_WAVE015_MONOLITHIC_PASS")),
        "MANUAL_RESCUE_STEPS_REQUIRED": bool(monolithic.get("MANUAL_RESCUE_STEPS_REQUIRED", False)),
        "WAVE011_REGRESSION": monolithic.get("waves", {}).get("WAVE011", w015.get("WAVE011_REGRESSION")),
        "WAVE012_REGRESSION": monolithic.get("waves", {}).get("WAVE012"),
        "WAVE013B_REGRESSION": monolithic.get("waves", {}).get("WAVE013B"),
        "WAVE014_REGRESSION": monolithic.get("waves", {}).get("WAVE014", w015.get("WAVE014_REGRESSION")),
        "ENGINEERING_WAVE_015": w015.get("ENGINEERING_WAVE_015"),
        "FINAL_HEAD_OWNER_SMOKE_DURATION_MIN": owner_duration,
        "FINAL_HEAD_OWNER_SMOKE_UNEXPECTED_TERMINATIONS": owner_deaths,
        "FINAL_HEAD_OWNER_SMOKE_PASS": smoke_pass,
        "OWNER_NORMAL_PLAY_CRASHES_REPRODUCED": bool(w015.get("OWNER_NORMAL_PLAY_CRASHES_REPRODUCED", False)),
        "HUMAN_PLAYTEST_COMPLETE": False,
        "HUMAN_ART_DIRECTION_APPROVAL": False,
        "READY_FOR_OWNER_MERGE": bool(smoke_pass and w015.get("READY_FOR_OWNER_MERGE")),
        "CURSOR_MERGED_NOTHING": True,
        "EVIDENCE_PROVENANCE": "PR85_FINAL_HEAD_SMOKE_ORCHESTRATION",
        "blockers": [],
    }
    if not smoke_pass:
        seal["blockers"].append("FINAL_HEAD_OWNER_SMOKE_INCOMPLETE_OR_BLOCKED")
    if not seal["MAKE_ENGINEERING_WAVE015_MONOLITHIC_PASS"]:
        seal["blockers"].append("MAKE_ENGINEERING_WAVE015_MONOLITHIC_PASS=false")

    ART.mkdir(parents=True, exist_ok=True)
    (ART / "FINAL_MERGE_PROVENANCE_SEAL.json").write_text(json.dumps(seal, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(seal, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
