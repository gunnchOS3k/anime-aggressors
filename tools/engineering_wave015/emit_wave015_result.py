#!/usr/bin/env python3
"""Emit truthful Wave015 aggregate result."""
from __future__ import annotations

import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "engineering_wave015"


def harness_tracked_on_origin_main() -> bool:
    try:
        tracked = subprocess.check_output(
            ["git", "ls-tree", "-r", "origin/main", "--name-only"],
            cwd=ROOT,
            text=True,
        )
    except subprocess.CalledProcessError:
        return False
    return "game-godot/scripts/rc/wave015_physical_harness.gd" in tracked


def load(name: str) -> dict:
    path = ART / name
    if path.exists():
        try:
            return json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            return {"_error": str(exc)}
    return {}


def main() -> int:
    identity = load("PIXEL6A_DEVICE_IDENTITY.json")
    build = load("ANDROID_BUILD_PROVENANCE.json")
    install = load("PIXEL6A_INSTALL_RESULT.json")
    launch = load("PIXEL6A_LAUNCH_RESULT.json")
    logcat = load("PIXEL6A_LOGCAT_RESULT.json")
    perf = load("PIXEL6A_PERFORMANCE_RESULT.json")
    thermal = load("PIXEL6A_THERMAL_BATTERY_RESULT.json")
    input_r = load("PIXEL6A_INPUT_RESULT.json")
    lifecycle = load("PIXEL6A_LIFECYCLE_RESULT.json")
    a11y = load("PIXEL6A_ACCESSIBILITY_RESULT.json")
    baseline = load("PIXEL6A_BASELINE_PHYSICAL_RESULT.json")
    roster = load("PIXEL6A_ROSTER_MODEL_MATRIX.json")
    actions = load("PIXEL6A_ACTION_MATRIX.json")
    w014_path = ROOT / "artifacts" / "engineering_wave014" / "WAVE014_RESULT.json"
    w014 = json.loads(w014_path.read_text(encoding="utf-8")) if w014_path.exists() else {}
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()

    validation = identity.get("PHYSICAL_PIXEL6A_VALIDATION", "BLOCKED_DEVICE_NOT_CONNECTED")
    objective = bool(baseline.get("PHYSICAL_PIXEL6A_OBJECTIVE_VALIDATED", False))
    action_count = int(actions.get("count", len(actions.get("observations", []))))
    roster_count = int(roster.get("count", len(roster.get("fighters", []))))
    manifest = load("device_screenshots/manifest.json")
    screenshot_count = int(manifest.get("count", len(manifest.get("screenshots", []))))

    overall = "PHYSICAL_OBJECTIVE_PASS" if objective else ("BLOCKED" if validation != "AUTHORIZED_PIXEL6A" else "PARTIAL")

    result = {
        "schema": "engineering_wave015.result.v1",
        "generated_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "ENGINEERING_WAVE_015": overall,
        "PHYSICAL_PIXEL6A_VALIDATION": validation,
        "PHYSICAL_PIXEL6A_OBJECTIVE_VALIDATED": objective,
        "PHYSICAL_PIXEL6A_PERFORMANCE_VALIDATED": bool(perf.get("PERFORMANCE_BASELINE_CAPTURED")),
        "ANIME_ACCEPTED_MAIN_SHA": baseline.get("ANIME_ACCEPTED_MAIN_SHA", build.get("ANIME_ACCEPTED_MAIN_SHA")),
        "FIELD_KIT_ACCEPTED_MAIN_SHA": baseline.get("FIELD_KIT_ACCEPTED_MAIN_SHA"),
        "PHYSICAL_BASELINE_TESTED_SHA": baseline.get("PHYSICAL_BASELINE_TESTED_SHA"),
        "HEAD_SHA": head,
        "ANDROID_BUILD_PASS": bool(build.get("ANDROID_BUILD_PASS")),
        "PIXEL6A_LAUNCH_PASS": bool(launch.get("PIXEL6A_LAUNCH_PASS")),
        "APP_PROCESS_ALIVE_AFTER_30S": bool(launch.get("APP_PROCESS_ALIVE_AFTER_30S")),
        "FATAL_EXCEPTIONS": int(launch.get("FATAL_EXCEPTIONS", logcat.get("FATAL_EXCEPTIONS", -1))),
        "ANR_COUNT": int(launch.get("ANR_COUNT", 0)),
        "ROSTER_MATRIX_COUNT": roster_count,
        "ACTION_MATRIX_COUNT": action_count,
        "SCREENSHOT_COUNT": screenshot_count,
        "HUMAN_ART_DIRECTION_APPROVAL": False,
        "HUMAN_PLAYTEST_COMPLETE": False,
        "REPAIR_PR_REQUIRED": bool(baseline.get("REPAIR_PR_REQUIRED", not harness_tracked_on_origin_main())),
        "READY_FOR_OWNER_MERGE": objective,
        "CURSOR_MERGED_NOTHING": True,
        "WAVE014_REGRESSION": w014.get("ENGINEERING_WAVE_014"),
        "blockers": [],
        "token": "ENGINEERING_WAVE_015_PHYSICAL_PIXEL6A",
    }
    if not objective:
        result["blockers"].append("PHYSICAL_PIXEL6A_OBJECTIVE_VALIDATED=false")
    if validation != "AUTHORIZED_PIXEL6A":
        result["blockers"].append(f"PHYSICAL_PIXEL6A_VALIDATION={validation}")
    if action_count < 112:
        result["blockers"].append(f"ACTION_MATRIX_COUNT={action_count}<112")
    if screenshot_count < 24:
        result["blockers"].append(f"SCREENSHOT_COUNT={screenshot_count}<24")

    ART.mkdir(parents=True, exist_ok=True)
    (ART / "WAVE015_RESULT.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
    return 0 if objective else 1


if __name__ == "__main__":
    raise SystemExit(main())
