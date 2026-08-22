#!/usr/bin/env python3
"""Aggregate choreography depth gate results."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "artifacts/engineering_wave013b/CHOREOGRAPHY_DEPTH_RESULT.json"


def load(rel: str) -> dict:
    p = ROOT / rel
    return json.loads(p.read_text(encoding="utf-8")) if p.exists() else {}


def main() -> int:
    distinct = load("artifacts/engineering_wave013b/CHOREOGRAPHY_DISTINCTNESS_RESULT.json")
    alignment = load("artifacts/engineering_wave013b/RUNTIME_CHOREOGRAPHY_ALIGNMENT.json")
    blueprints = load("content/choreography/fighter_motion_blueprints.json")
    fighter_count = len(blueprints.get("fighters", {}))
    sig_per = 8
    out = {
        "FULL_ROSTER_CHOREOGRAPHY_DEPTH_PASS": (
            distinct.get("pass") and alignment.get("pass") and fighter_count == 7
        ),
        "fighter_blueprints_present": fighter_count == 7,
        "signatures_per_fighter": sig_per,
        "distinctness": distinct,
        "runtime_alignment": alignment,
        "FIGHTER_SIGNATURE_MOVE_BIBLE_present": (
            ROOT / "docs/design/FIGHTER_SIGNATURE_MOVE_BIBLE.md"
        ).exists(),
        "pass": distinct.get("pass") and alignment.get("pass") and fighter_count == 7,
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    return 0 if out["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
