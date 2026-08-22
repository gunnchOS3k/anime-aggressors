#!/usr/bin/env python3
"""Compare action specs to reference animatics."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


def compare(fighter_id: str, action_key: str) -> dict:
    spec_path = ROOT / "content/choreography" / fighter_id / f"{action_key}.json"
    anim_path = ROOT / "tools/motion_pipeline/reference_animation" / fighter_id / f"{action_key}.json"
    if not spec_path.exists():
        return {"ok": False, "error": "spec_missing"}
    spec = json.loads(spec_path.read_text(encoding="utf-8"))
    if not anim_path.exists():
        return {
            "ok": True,
            "mode": "spec_only",
            "action_id": spec["action_id"],
            "reference_animatic": "NONE",
        }
    anim = json.loads(anim_path.read_text(encoding="utf-8"))
    return {
        "ok": spec["action_id"] == anim["action_id"],
        "action_id": spec["action_id"],
        "spec_frames": spec["timing"]["total_frames"],
        "anim_frames": anim.get("duration_frames"),
        "kind": anim.get("kind"),
    }


def main() -> int:
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--fighter", required=True)
    parser.add_argument("--action", required=True)
    args = parser.parse_args()
    result = compare(args.fighter, args.action)
    print(json.dumps(result, indent=2))
    return 0 if result.get("ok") else 1


if __name__ == "__main__":
    raise SystemExit(main())
