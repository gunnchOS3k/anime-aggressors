#!/usr/bin/env python3
"""Validate prototype animatics are fighter-specific."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
REF = ROOT / "tools/motion_pipeline/reference_animation"


def main() -> int:
    timelines = []
    signatures = set()
    collisions = 0
    for path in sorted(REF.rglob("*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        timelines.append(data)
        sig = json.dumps(
            {
                "fighter_id": data.get("fighter_id"),
                "action_id": data.get("action_id"),
                "duration_frames": data.get("duration_frames"),
                "events": data.get("events"),
                "fighter_motion_signature": data.get("fighter_motion_signature"),
            },
            sort_keys=True,
        )
        if sig in signatures:
            collisions += 1
        signatures.add(sig)
        if not data.get("provenance", {}).get("final_animation") is False:
            collisions += 1

    out = {
        "count": len(timelines),
        "PROTOTYPE_ANIMATIC_FIGHTER_SPECIFIC": collisions == 0,
        "GENERIC_PROTOTYPE_TIMELINE_COLLISIONS": collisions,
        "REFERENCE_ANIMATIC": True,
        "final_animation": False,
        "pass": len(timelines) >= 91 and collisions == 0,
    }
    dest = ROOT / "artifacts/engineering_wave013b/PROTOTYPE_ANIMATIC_QA.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    return 0 if out["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
