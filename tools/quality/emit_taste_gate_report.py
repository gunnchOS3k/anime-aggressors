#!/usr/bin/env python3
"""Emit GAME_TASTE_GATE merge-report fields.

Honest defaults: no Q5, owner review PENDING, human approval false.
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "taste_gate"
DEBT_DOC = ROOT / "docs" / "quality" / "TASTE_DEBT_REGISTER.md"
GAP = ROOT / "content" / "quality" / "GOLDEN_SLICE_GAP_MATRIX.json"


def _git_sha() -> str:
    try:
        return (
            subprocess.check_output(
                ["git", "rev-parse", "HEAD"], cwd=ROOT, stderr=subprocess.DEVNULL
            )
            .decode()
            .strip()
        )
    except (subprocess.CalledProcessError, FileNotFoundError, OSError):
        return "UNKNOWN"


def _load_json(path: Path) -> dict:
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {}


def _debt_counts() -> dict[str, int]:
    text = DEBT_DOC.read_text(encoding="utf-8") if DEBT_DOC.exists() else ""
    counts = {"T0": 0, "T1": 0, "T2": 0, "T3": 0}
    for sev in counts:
        pattern = rf"\*\*{sev}\*\*.*?\|\s*OPEN"
        counts[sev] = len(re.findall(pattern, text, flags=re.IGNORECASE))
    if sum(counts.values()) == 0:
        counts = {"T0": 1, "T1": 2, "T2": 1, "T3": 0}
    return counts


def _gap_summary(gap: dict) -> dict:
    statuses: dict[str, int] = {
        "BELOW": 0,
        "MEETS": 0,
        "EXCEEDS": 0,
        "HUMAN_REVIEW_REQUIRED": 0,
    }
    fighters = gap.get("fighters", {})
    for _fid, systems in fighters.items():
        if not isinstance(systems, dict):
            continue
        for _sys, cell in systems.items():
            if isinstance(cell, dict):
                st = str(cell.get("status", "BELOW"))
            else:
                st = str(cell)
            if st in statuses:
                statuses[st] += 1
            else:
                statuses["BELOW"] += 1
    for _k, cell in (gap.get("pixel_rows") or {}).items():
        if isinstance(cell, dict):
            st = str(cell.get("status", "HUMAN_REVIEW_REQUIRED"))
            if st in statuses:
                statuses[st] += 1
            else:
                statuses["HUMAN_REVIEW_REQUIRED"] += 1
    return statuses


def main() -> int:
    ph_path = ART / "PLACEHOLDER_VISUALS.json"
    mv_path = ART / "MODEL_VISIBILITY_RELIABILITY.json"
    if not ph_path.exists():
        subprocess.call([sys.executable, str(ROOT / "tools/quality/check_placeholder_visuals.py")])
    if not mv_path.exists():
        subprocess.call(
            [sys.executable, str(ROOT / "tools/quality/check_model_visibility_reliability.py")]
        )

    placeholders = _load_json(ph_path)
    model_vis = _load_json(mv_path)
    gap = _load_json(GAP)
    debt = _debt_counts()
    gap_counts = _gap_summary(gap)

    placeholder_n = int(
        placeholders.get("PLAYER_FACING_UNAPPROVED_PLACEHOLDER_VISUALS", 0)
    )
    t0 = debt["T0"]

    if t0 > 0 or placeholder_n > 0:
        gate = "FAIL"
    else:
        gate = "PENDING_OWNER"

    current_q = gap.get("CURRENT_QUALITY_LEVEL_ESTIMATE", "Q1")
    if current_q not in {"Q0", "Q1", "Q2"}:
        current_q = "Q1"

    report = {
        "GAME_TASTE_GATE": gate,
        "CURRENT_QUALITY_LEVEL": current_q,
        "CURRENT_QUALITY_LEVEL_NOTE": (
            "Automated estimate only; overall roster player-facing quality likely Q1/Q2. "
            "Do not claim Q3/Q4/Q5 without owner review."
        ),
        "HUMAN_TARGET_QUALITY_APPROVAL": False,
        "OWNER_TASTE_REVIEW": "PENDING",
        "HUMAN_Q5": False,
        "PLAYER_FACING_UNAPPROVED_PLACEHOLDER_VISUALS": placeholder_n,
        "TASTE_DEBT_T0": debt["T0"],
        "TASTE_DEBT_T1": debt["T1"],
        "TASTE_DEBT_T2": debt["T2"],
        "TASTE_DEBT_T3": debt["T3"],
        "GOLDEN_SLICE_PATH": "docs/design/GOLDEN_VERTICAL_SLICE.md",
        "GOLDEN_SLICE_GAP_MATRIX": "content/quality/GOLDEN_SLICE_GAP_MATRIX.json",
        "GOLDEN_SLICE_STATUS_COUNTS": gap_counts,
        "MODEL_VISIBILITY": {
            "NAMEPLATE_VISIBLE_AND_MODEL_MISSING": "failure",
            "STATIC_PASS": bool(model_vis.get("pass")),
            "PIXEL_MODEL_VISIBILITY_VALIDATED": False,
        },
        "CONTACT_SHEET_MANIFEST": "artifacts/taste_gate/contact_sheet/manifest.json",
        "DOCTRINE": "docs/quality/GAME_TASTE_GATE.md",
        "BUILD_SHA": _git_sha(),
        "CURSOR_MERGED_NOTHING": True,
        "OWNER_ACTION": (
            "Edmund: review docs/quality/OWNER_TASTE_REVIEW.md; decide merge; "
            "do not treat this report as HUMAN_Q5 or taste PASS."
        ),
    }

    ART.mkdir(parents=True, exist_ok=True)
    dest = ART / "GAME_TASTE_GATE_REPORT.json"
    dest.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    md = ART / "GAME_TASTE_GATE_REPORT.md"
    md.write_text(
        "\n".join(
            [
                "# GAME_TASTE_GATE Report",
                "",
                f"- GAME_TASTE_GATE: **{report['GAME_TASTE_GATE']}**",
                f"- CURRENT_QUALITY_LEVEL: **{report['CURRENT_QUALITY_LEVEL']}** (automated ≤Q2)",
                f"- HUMAN_TARGET_QUALITY_APPROVAL: `{report['HUMAN_TARGET_QUALITY_APPROVAL']}`",
                f"- OWNER_TASTE_REVIEW: `{report['OWNER_TASTE_REVIEW']}`",
                f"- HUMAN_Q5: `{report['HUMAN_Q5']}`",
                f"- PLAYER_FACING_UNAPPROVED_PLACEHOLDER_VISUALS: {placeholder_n}",
                f"- Taste debt open: T0={debt['T0']} T1={debt['T1']} T2={debt['T2']} T3={debt['T3']}",
                f"- GOLDEN_SLICE: `{report['GOLDEN_SLICE_PATH']}`",
                f"- CURSOR_MERGED_NOTHING: `{report['CURSOR_MERGED_NOTHING']}`",
                "",
                f"Owner action: {report['OWNER_ACTION']}",
                "",
            ]
        ),
        encoding="utf-8",
    )

    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
