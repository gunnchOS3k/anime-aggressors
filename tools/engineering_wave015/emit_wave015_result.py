#!/usr/bin/env python3
"""Emit truthful Wave015 aggregate result (BattleScene + human-path aware)."""
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
    signatures = load("HUMAN_PATH_CRASH_SIGNATURES.json", CENSUS) or load("CRASH_SIGNATURES.json", CENSUS)
    human = load("HUMAN_PATH_CAPTURE_RESULT.json", CENSUS)
    bs_fuzz = load("BATTLESCENE_FUZZ_RESULT.json", CENSUS)
    bs_trans = load("BATTLESCENE_TRANSITION_RESULT.json", CENSUS)
    bs_match = load("BATTLESCENE_MATCHUP_RESULT.json", CENSUS)
    bs_life = load("BATTLESCENE_LIFECYCLE_RESULT.json", CENSUS)
    bs_soak = load("BATTLESCENE_SOAK_RESULT.json", CENSUS)
    owner_smoke = load("OWNER_STABILITY_SMOKE_RESULT.json", CENSUS)
    w014_path = ROOT / "artifacts" / "engineering_wave014" / "WAVE014_RESULT.json"
    w014 = json.loads(w014_path.read_text(encoding="utf-8")) if w014_path.exists() else {}
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()

    validation = identity.get("PHYSICAL_PIXEL6A_VALIDATION", baseline.get("PHYSICAL_PIXEL6A_VALIDATION", "UNKNOWN"))
    open_sigs = int(signatures.get("UNIQUE_CRASH_SIGNATURES_OPEN", signatures.get("HUMAN_PATH_CRASH_SIGNATURES_OPEN", -1))) if signatures else -1
    if "HUMAN_PATH_CRASH_SIGNATURES_OPEN" in human:
        open_sigs = int(human.get("HUMAN_PATH_CRASH_SIGNATURES_OPEN", open_sigs))

    fuzz_events = int(bs_fuzz.get("BATTLESCENE_FUZZ_EVENTS", 0)) if bs_fuzz else 0
    fuzz_deaths = int(bs_fuzz.get("BATTLESCENE_FUZZ_PROCESS_DEATHS", 1 if bs_fuzz else 1)) if bs_fuzz else 1
    matchup_attempted = int(bs_match.get("MATCHUPS_ATTEMPTED", 0)) if bs_match else 0
    matchup_ok = int(bs_match.get("MATCHUPS_COMPLETED_WITHOUT_CRASH", 0)) if bs_match else 0
    cycles = int(bs_life.get("REAL_BATTLESCENE_CYCLES", 0)) if bs_life else 0
    cycle_crashes = int(bs_life.get("REAL_BATTLESCENE_CYCLE_CRASHES", 1 if bs_life else 1)) if bs_life else 1
    soak_min = int(bs_soak.get("BATTLESCENE_SOAK_MIN", 0)) if bs_soak else 0
    soak_deaths = int(bs_soak.get("UNEXPECTED_PROCESS_DEATHS", 1 if bs_soak else 1)) if bs_soak else 1
    trans_crashes = int(bs_trans.get("BATTLESCENE_TRANSITION_CRASHES", 1 if bs_trans else 1)) if bs_trans else 1
    owner_min = float(owner_smoke.get("OWNER_SMOKE_DURATION_MIN", 0) or 0)
    owner_deaths = int(owner_smoke.get("OWNER_SMOKE_UNEXPECTED_TERMINATIONS", 1 if owner_smoke else 1)) if owner_smoke else 1

    # Do NOT accept legacy standalone FighterModel3D fuzz/soak as BattleScene stability.
    gate_fields_present = all(bool(x) for x in (bs_fuzz, bs_trans, bs_match, bs_life, bs_soak, owner_smoke, human))
    stability = (
        gate_fields_present
        and open_sigs == 0
        and fuzz_events >= 25000
        and fuzz_deaths == 0
        and trans_crashes == 0
        and matchup_attempted >= 49
        and matchup_ok >= 49
        and cycles >= 50
        and cycle_crashes == 0
        and soak_min >= 30
        and soak_deaths == 0
        and owner_min >= 10.0
        and owner_deaths == 0
        and final_stab.get("status") == "PHYSICAL_STABILITY_PASS"
    )

    objective = bool(stability)
    if not gate_fields_present:
        overall = "PARTIAL"
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
        "PRIOR_WAVE015_OBJECTIVE_PASS": "SUPERSEDED_BY_HUMAN_PATH_BATTLESCENE_GATE",
        "PRIOR_PHYSICAL_STABILITY_PASS": "SUPERSEDED_BY_HUMAN_PATH_BATTLESCENE_GATE",
        "PHYSICAL_PIXEL6A_VALIDATION": validation,
        "PHYSICAL_PIXEL6A_OBJECTIVE_VALIDATED": objective,
        "PIXEL6A_STABILITY_VALIDATED": stability,
        "OWNER_NORMAL_PLAY_CRASHES_REPRODUCED": bool(human.get("OWNER_NORMAL_PLAY_CRASHES_REPRODUCED", False)),
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
        "BATTLESCENE_FUZZ_EVENTS": fuzz_events,
        "MATCHUPS": matchup_attempted,
        "SCENE_CYCLES": cycles,
        "SOAK_PASS": soak_min >= 30 and soak_deaths == 0,
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
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
