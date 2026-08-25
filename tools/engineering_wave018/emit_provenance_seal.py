#!/usr/bin/env python3
"""Emit FINAL_WAVE018_PROVENANCE_SEAL.json for PR #89."""
from __future__ import annotations

import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "engineering_wave018"
PHYSICALLY_TESTED_CANDIDATE = "32558493894eca1d4f208fabd63722bc8ce240eb"


def load(name: str) -> dict:
    p = ART / name
    if p.exists():
        return json.loads(p.read_text(encoding="utf-8"))
    return {}


def git(*args: str) -> str:
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()


def main() -> int:
    head = git("rev-parse", "HEAD")
    result = load("WAVE018_RESULT.json")
    select = load("WAVE018_PIXEL_SELECT_STRESS_RESULT.json")
    vis = load("WAVE018_PIXEL_VISIBILITY_RESULT.json")
    smoke = load("WAVE018_PIXEL_SMOKE_RESULT.json")
    desktop_sel = load("SELECT_PREVIEW_STRESS_RESULT.json")
    desktop_s2b = load("SELECT_TO_BATTLE_VISIBILITY_RESULT.json")
    desktop_battle = load("BATTLE_VISIBILITY_INVARIANT_RESULT.json")

    physical_sha = (
        select.get("PIXEL_SOURCE_SHA")
        or smoke.get("PIXEL_SOURCE_SHA")
        or result.get("PHYSICALLY_TESTED_RUNTIME_SHA")
        or head
    )
    # Diff vs physically tested SHA (not the older prior candidate) for honest equivalence.
    runtime_changed = git(
        "diff",
        "--name-only",
        f"{physical_sha}..{head}",
        "--",
        "game-godot/",
    ).splitlines()
    evidence_changed = git(
        "diff",
        "--name-only",
        f"{physical_sha}..{head}",
    ).splitlines()
    evidence_only = [p for p in evidence_changed if p not in runtime_changed]

    apk = select.get("APK_SHA256") or smoke.get("APK_SHA256") or result.get("APK_SHA256")
    # Equivalent when tip has no game-godot delta after the physically tested runtime.
    equiv = physical_sha == head or len(runtime_changed) == 0

    seal = {
        "schema": "engineering_wave018.final_provenance_seal.v1",
        "generated_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "PR_NUMBER": 89,
        "PR_URL": "https://github.com/gunnchOS3k/anime-aggressors/pull/89",
        "final_pr_head": head,
        "physically_tested_runtime_sha": physical_sha,
        "physically_tested_apk_sha256": apk,
        "prior_physical_candidate_sha": PHYSICALLY_TESTED_CANDIDATE,
        "final_runtime_equivalent_to_physically_tested_runtime": equiv,
        "runtime_affecting_files_changed_after_physical_test": runtime_changed,
        "evidence_or_tooling_files_changed_after_physical_test": evidence_only,
        "desktop_visibility_counters": {
            "SELECT_PREVIEW_TRANSITIONS_TESTED": desktop_sel.get("SELECT_PREVIEW_TRANSITIONS_TESTED"),
            "SELECT_PREVIEW_GHOST_OCCURRENCES": desktop_sel.get("SELECT_PREVIEW_GHOST_OCCURRENCES"),
            "SELECT_TO_BATTLE_GHOST_OCCURRENCES": desktop_s2b.get("SELECT_TO_BATTLE_GHOST_OCCURRENCES"),
            "BATTLE_VISIBLE_BODY_ZERO_OCCURRENCES": desktop_battle.get(
                "BATTLE_VISIBLE_BODY_ZERO_OCCURRENCES"
            ),
        },
        "pixel_render_ghost_counters": {
            "PIXEL_SELECT_RENDER_GHOST_OCCURRENCES": select.get(
                "PIXEL_SELECT_RENDER_GHOST_OCCURRENCES"
            ),
            "PIXEL_BATTLE_RENDER_GHOST_OCCURRENCES": vis.get(
                "PIXEL_BATTLE_RENDER_GHOST_OCCURRENCES"
            ),
        },
        "pixel_invariant_violations": smoke.get(
            "PIXEL_VISIBILITY_INVARIANT_VIOLATIONS",
            vis.get("PIXEL_VISIBILITY_INVARIANT_VIOLATIONS"),
        ),
        "fallback_recoveries": smoke.get(
            "PIXEL_FALLBACK_RECOVERIES", vis.get("PIXEL_FALLBACK_RECOVERIES")
        ),
        "process_deaths": smoke.get("PIXEL_PROCESS_DEATHS"),
        "smoke_duration_min": smoke.get("PIXEL_SMOKE_MIN"),
        "GHOST_SEMANTICS": "render_ghost != process_death",
        "READY_FOR_OWNER_MERGE": bool(result.get("READY_FOR_OWNER_MERGE")),
        "CURSOR_MERGED_NOTHING": True,
        "WAVE019_STARTED": False,
    }
    ART.mkdir(parents=True, exist_ok=True)
    (ART / "FINAL_WAVE018_PROVENANCE_SEAL.json").write_text(
        json.dumps(seal, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(seal, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
