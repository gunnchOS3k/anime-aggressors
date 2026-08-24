#!/usr/bin/env python3
"""Emit Wave017 owner taste packet — human approvals stay false / PENDING."""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "artifacts" / "wave017" / "OWNER_TASTE_PACKET.json"


def main() -> int:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    packet = {
        "wave": "WAVE017",
        "slice": "Ember Vale Golden Slice",
        "opponent": "rook-ironside",
        "stage": "ember-courtyard",
        "OWNER_TASTE_REVIEW_BASELINE": "CHANGES_REQUESTED",
        "OWNER_TASTE_REVIEW": "PENDING",
        "HUMAN_VISIBLE_QUALITY_BEFORE": "Q1_FUNCTIONAL_PROTOTYPE",
        "HUMAN_Q2_APPROVAL": False,
        "HUMAN_Q3_APPROVAL": False,
        "HUMAN_ART_DIRECTION_APPROVAL": False,
        "CURRENT_QUALITY_LEVEL_AUTOMATED_CEILING": "Q2",
        "OWNER_RATINGS": "OWNER_PENDING",
        "CURSOR_DECLARED_Q3": False,
        "baseline_doc": "docs/quality/WAVE017_OWNER_SCREENSHOT_BASELINE.md",
        "emitted_at": datetime.now(timezone.utc).isoformat(),
    }
    OUT.write_text(json.dumps(packet, indent=2) + "\n", encoding="utf-8")
    print("Wrote", OUT)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
