#!/usr/bin/env python3
"""Final merge-head 10-minute monitored owner smoke on authorized Pixel 6a."""
from __future__ import annotations

import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CENSUS = ROOT / "artifacts" / "engineering_wave015" / "crash_census"
CAPTURE = ROOT / "tools" / "engineering_wave015" / "capture_human_play_crash.py"


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def main() -> int:
    print("\n" + "=" * 72)
    print("FINAL MERGE-HEAD SMOKE: Play normally for 10 minutes...")
    print("=" * 72 + "\n", flush=True)

    proc = subprocess.run(
        [
            sys.executable,
            str(CAPTURE),
            "--duration-min",
            "10",
            "--owner-smoke",
            "--skip-build",
        ],
        cwd=ROOT,
    )
    human = {}
    owner = {}
    human_path = CENSUS / "HUMAN_PATH_CAPTURE_RESULT.json"
    owner_path = CENSUS / "OWNER_STABILITY_SMOKE_RESULT.json"
    if human_path.exists():
        human = json.loads(human_path.read_text(encoding="utf-8"))
    if owner_path.exists():
        owner = json.loads(owner_path.read_text(encoding="utf-8"))

    duration = float(
        owner.get("OWNER_SMOKE_DURATION_MIN")
        or human.get("OWNER_SMOKE_DURATION_MIN")
        or human.get("DURATION_MIN")
        or 0
    )
    deaths = int(
        owner.get("OWNER_SMOKE_UNEXPECTED_TERMINATIONS")
        if owner.get("OWNER_SMOKE_UNEXPECTED_TERMINATIONS") is not None
        else human.get("OWNER_SMOKE_UNEXPECTED_TERMINATIONS", 0) or 0
    )
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    result = {
        "schema": "engineering_wave015.final_head_owner_smoke.v1",
        "generated_at_utc": utc_now(),
        "FINAL_HEAD_OWNER_SMOKE_DURATION_MIN": round(duration, 3),
        "FINAL_HEAD_OWNER_SMOKE_UNEXPECTED_TERMINATIONS": deaths,
        "FINAL_OWNER_SMOKE_TESTED_SHA": head,
        "PASS": duration >= 10.0 and deaths == 0 and proc.returncode == 0,
        "HUMAN_PLAYTEST_COMPLETE": False,
        "HUMAN_ART_DIRECTION_APPROVAL": False,
        "CURSOR_MERGED_NOTHING": True,
    }
    CENSUS.mkdir(parents=True, exist_ok=True)
    out_path = CENSUS / "FINAL_HEAD_OWNER_SMOKE_RESULT.json"
    out_path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
    return 0 if result["PASS"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
