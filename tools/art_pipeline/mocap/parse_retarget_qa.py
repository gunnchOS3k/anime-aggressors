#!/usr/bin/env python3
"""Parse retarget QA JSON from mixamo-llm-mocap style reports."""
from __future__ import annotations
import argparse, json, sys
from pathlib import Path

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("qa_json", type=Path)
    args = ap.parse_args()
    qa = json.loads(args.qa_json.read_text())
    explosions = float(qa.get("bone_explosion_score", 1))
    skate = float(qa.get("foot_skate_score", 1))
    ok = explosions < 0.05 and skate < 0.05 and not qa.get("rest_pose_broken", True)
    print(json.dumps({"pass": ok, "explosions": explosions, "foot_skate": skate}, indent=2))
    return 0 if ok else 2

if __name__ == "__main__":
    raise SystemExit(main())
