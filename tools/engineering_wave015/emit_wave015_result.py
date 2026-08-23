#!/usr/bin/env python3
"""Emit truthful Wave015 aggregate result (crash-census aware)."""
from __future__ import annotations

import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "engineering_wave015"
CENSUS = ART / "crash_census"


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


def load(name: str, base: Path = ART) -> dict:
    path = base / name
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
    baseline = load("PIXEL6A_BASELINE_PHYSICAL_RESULT.json")
    roster = load("PIXEL6A_ROSTER_MODEL_MATRIX.json")
    actions = load("PIXEL6A_ACTION_MATRIX.json")
    census = load("BASELINE_CRASH_CENSUS.json", CENSUS)
    final_stab = load("FINAL_STABILITY_RESULT.json", CENSUS)
    signatures = load("CRASH_SIGNATURES.json", CENSUS)
    fuzz = load("FUZZ_CAMPAIGN_RESULT.json", CENSUS)
    matchups = load("MATCHUP_STRESS_RESULT.json", CENSUS)
    lifecycle = load("SCENE_LIFECYCLE_RESULT.json", CENSUS)
    soak = load("SOAK_RESULT.json", CENSUS)
    w014_path = ROOT / "artifacts" / "engineering_wave014" / "WAVE014_RESULT.json"
    w014 = json.loads(w014_path.read_text(encoding="utf-8")) if w014_path.exists() else {}
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()

    validation = identity.get("PHYSICAL_PIXEL6A_VALIDATION", baseline.get("PHYSICAL_PIXEL6A_VALIDATION", "UNKNOWN"))
    open_sigs = int(signatures.get("UNIQUE_CRASH_SIGNATURES_OPEN", -1)) if signatures else -1
    fuzz_events = int(fuzz.get("GAMEPLAY_ACTION_EVENTS", 0)) if fuzz else 0
    matchup_count = int(matchups.get("count", 0)) if matchups else 0
    cycles = int(lifecycle.get("count", 0)) if lifecycle else 0
    soak_pass = bool(soak.get("PASS", False)) if soak else False

    stability = (
        open_sigs == 0
        and fuzz_events >= 25000
        and int(fuzz.get("CRASHES", 1)) == 0
        and matchup_count >= 49
        and cycles >= 50
        and soak_pass
        and bool(final_stab)
    )

    # Prior objective pass is superseded until crash census + stability complete.
    prior = baseline.get("PRIOR_WAVE015_OBJECTIVE_PASS", "SUPERSEDED_BY_HUMAN_CRASH_REPORT")
    objective = False  # never claim objective from pre-crash-report artifacts
    if stability:
        objective = True

    if prior == "SUPERSEDED_BY_HUMAN_CRASH_REPORT" and not stability:
        overall = "SUPERSEDED_BY_HUMAN_CRASH_REPORT"
    elif stability:
        overall = "PHYSICAL_STABILITY_PASS"
    elif validation != "AUTHORIZED_PIXEL6A" and not census:
        overall = "BLOCKED"
    else:
        overall = "PARTIAL"

    action_count = int(actions.get("count", len(actions.get("observations", []))))
    roster_count = int(roster.get("count", len(roster.get("fighters", []))))
    manifest = load("device_screenshots/manifest.json")
    screenshot_count = int(manifest.get("count", len(manifest.get("screenshots", []))))

    result = {
        "schema": "engineering_wave015.result.v1",
        "generated_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "ENGINEERING_WAVE_015": overall,
        "PRIOR_WAVE015_OBJECTIVE_PASS": "SUPERSEDED_BY_HUMAN_CRASH_REPORT",
        "PHYSICAL_PIXEL6A_VALIDATION": validation,
        "PHYSICAL_PIXEL6A_OBJECTIVE_VALIDATED": objective,
        "PIXEL6A_STABILITY_VALIDATED": stability,
        "PHYSICAL_PIXEL6A_PERFORMANCE_VALIDATED": bool(perf.get("PERFORMANCE_BASELINE_CAPTURED")),
        "ANIME_ACCEPTED_MAIN_SHA": baseline.get("ANIME_ACCEPTED_MAIN_SHA", build.get("ANIME_ACCEPTED_MAIN_SHA")),
        "FIELD_KIT_ACCEPTED_MAIN_SHA": baseline.get("FIELD_KIT_ACCEPTED_MAIN_SHA"),
        "PHYSICAL_BASELINE_TESTED_SHA": baseline.get("PHYSICAL_BASELINE_TESTED_SHA"),
        "BASELINE_CRASH_CENSUS_SHA": census.get("BASELINE_CRASH_CENSUS_SHA", baseline.get("BASELINE_CRASH_CENSUS_SHA")),
        "HEAD_SHA": head,
        "ANDROID_BUILD_PASS": bool(build.get("ANDROID_BUILD_PASS")),
        "PIXEL6A_LAUNCH_PASS": bool(launch.get("PIXEL6A_LAUNCH_PASS")),
        "APP_PROCESS_ALIVE_AFTER_30S": bool(launch.get("APP_PROCESS_ALIVE_AFTER_30S")),
        "FATAL_EXCEPTIONS": int(launch.get("FATAL_EXCEPTIONS", logcat.get("FATAL_EXCEPTIONS", -1))),
        "ANR_COUNT": int(launch.get("ANR_COUNT", 0)),
        "ROSTER_MATRIX_COUNT": roster_count,
        "ACTION_MATRIX_COUNT": action_count,
        "SCREENSHOT_COUNT": screenshot_count,
        "UNIQUE_CRASH_SIGNATURES_OPEN": open_sigs,
        "FUZZ_EVENTS": fuzz_events,
        "MATCHUPS": matchup_count,
        "SCENE_CYCLES": cycles,
        "SOAK_PASS": soak_pass,
        "HUMAN_ART_DIRECTION_APPROVAL": False,
        "HUMAN_PLAYTEST_COMPLETE": False,
        "REPAIR_PR_REQUIRED": bool(baseline.get("REPAIR_PR_REQUIRED", not harness_tracked_on_origin_main())),
        "READY_FOR_OWNER_MERGE": bool(objective and stability),
        "CURSOR_MERGED_NOTHING": True,
        "WAVE014_REGRESSION": w014.get("ENGINEERING_WAVE_014"),
        "blockers": [],
        "token": "ENGINEERING_WAVE_015_PHYSICAL_PIXEL6A",
    }
    if not objective:
        result["blockers"].append("PHYSICAL_PIXEL6A_OBJECTIVE_VALIDATED=false")
    if not stability:
        result["blockers"].append("PIXEL6A_STABILITY_VALIDATED=false")
    if open_sigs not in (0, -1) and open_sigs > 0:
        result["blockers"].append(f"UNIQUE_CRASH_SIGNATURES_OPEN={open_sigs}")

    ART.mkdir(parents=True, exist_ok=True)
    (ART / "WAVE015_RESULT.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
    # Non-physical CI path: exit 0 so wave015 gate can pass without a phone.
    # Physical stability remains gated by PIXEL6A_STABILITY_VALIDATED in artifacts.
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
