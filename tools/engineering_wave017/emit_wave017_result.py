#!/usr/bin/env python3
"""Emit Wave017 Section-27 style result — never invent Q3 / merge."""
from __future__ import annotations

import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "wave017"
OUT = ART / "WAVE017_RESULT.json"
DEBT = ROOT / "docs" / "quality" / "TASTE_DEBT_REGISTER.md"


def _sha() -> str:
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT).decode().strip()
    except Exception:
        return "UNKNOWN"


def _load(name: str) -> dict:
    p = ART / name
    if not p.exists():
        return {}
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {}


def _t0_open() -> int:
    text = DEBT.read_text(encoding="utf-8") if DEBT.exists() else ""
    # Count T0 rows still marked OPEN (not CLOSED / MITIGATED-only)
    n = 0
    for line in text.splitlines():
        if "T0" in line and "OPEN" in line and "CLOSED" not in line:
            # mitigated lines use MITIGATED without OPEN
            if "**T0**" in line or "TASTE-T0" in line:
                n += 1
    return n


def main() -> int:
    ART.mkdir(parents=True, exist_ok=True)
    ghost = _load("GHOST_LIFECYCLE_HARNESS.json")
    labels = _load("PLAYER_BUILD_DEBUG_LABELS.json")
    visual = _load("GOLDEN_SLICE_VISUAL_SMOKE.json")
    pixel = _load("PIXEL_CAMPAIGN.json")
    packet = _load("OWNER_TASTE_PACKET.json")
    taste = {}
    tg = ROOT / "artifacts" / "taste_gate" / "GAME_TASTE_GATE_REPORT.json"
    if tg.exists():
        try:
            taste = json.loads(tg.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            taste = {}

    desktop_ghosts = int(ghost.get("DESKTOP_GHOST_OCCURRENCES", ghost.get("NORMAL_PLAY_GHOST_FIGHTER_OCCURRENCES_DESKTOP", 99)))
    pixel_ghosts = pixel.get("NORMAL_PLAY_GHOST_FIGHTER_OCCURRENCES")
    pixel_status = str(pixel.get("PIXEL_CAMPAIGN", "UNKNOWN"))
    debug_labels = int(labels.get("PLAYER_BUILD_VISIBLE_DEBUG_LABELS", 99))
    t0 = _t0_open()

    gates_ok = (
        desktop_ghosts == 0
        and debug_labels == 0
        and str(visual.get("GOLDEN_SLICE_VISUAL_SMOKE", "")) == "PASS"
        and t0 == 0
        and pixel_status in ("PASS", "PASS_WITH_DEBT")
        and pixel_ghosts == 0
    )

    if pixel_status == "BLOCKED_PIXEL6A":
        ready = False
        wave_status = "DELIVERED_DRAFT_PR_PIXEL_BLOCKED"
    elif gates_ok:
        ready = True
        wave_status = "ACCEPTED_PENDING_OWNER"
    else:
        ready = False
        wave_status = "DELIVERED_DRAFT_PR_GATES_INCOMPLETE"

    result = {
        "WAVE017_OWNER_TASTE_GOLDEN_SLICE": wave_status,
        "ACCEPTED_MAIN_SHA": "aef8ce845bf01f51703d2dbd584932198a36881c",
        "HEAD": _sha(),
        "OWNER_TASTE_REVIEW_BASELINE": "CHANGES_REQUESTED",
        "OWNER_TASTE_REVIEW": packet.get("OWNER_TASTE_REVIEW", "PENDING"),
        "HUMAN_VISIBLE_QUALITY_BEFORE": "Q1_FUNCTIONAL_PROTOTYPE",
        "HUMAN_Q2_APPROVAL": False,
        "HUMAN_Q3_APPROVAL": False,
        "HUMAN_ART_DIRECTION_APPROVAL": False,
        "T0_OPEN": t0,
        "PLAYER_BUILD_VISIBLE_DEBUG_LABELS": debug_labels,
        "NORMAL_PLAY_GHOST_FIGHTER_OCCURRENCES_DESKTOP": desktop_ghosts,
        "NORMAL_PLAY_GHOST_FIGHTER_OCCURRENCES": pixel_ghosts,
        "PIXEL_CAMPAIGN": pixel_status,
        "GOLDEN_SLICE_VISUAL_SMOKE": visual.get("GOLDEN_SLICE_VISUAL_SMOKE"),
        "GAME_TASTE_GATE": taste.get("GAME_TASTE_GATE"),
        "READY_FOR_OWNER_MERGE": ready,
        "CURSOR_MERGED_NOTHING": True,
        "CURSOR_DECLARED_Q3": False,
        "emitted_at": datetime.now(timezone.utc).isoformat(),
    }
    OUT.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    (ROOT / "artifacts" / "engineering_wave017" / "WAVE017_RESULT.json").parent.mkdir(parents=True, exist_ok=True)
    (ROOT / "artifacts" / "engineering_wave017" / "WAVE017_RESULT.json").write_text(
        json.dumps(result, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
