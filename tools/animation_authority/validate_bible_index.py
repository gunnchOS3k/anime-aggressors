#!/usr/bin/env python3
"""Validate fighter bible index and package presence."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def main() -> int:
    index_path = ROOT / "data/bibles/FIGHTER_BIBLE_INDEX.json"
    if not index_path.is_file():
        print("FAIL: missing data/bibles/FIGHTER_BIBLE_INDEX.json", file=sys.stderr)
        return 1
    index = json.loads(index_path.read_text(encoding="utf-8"))
    fighters = index.get("fighters", [])
    if len(fighters) != 9:
        print(f"FAIL: expected 9 fighters, got {len(fighters)}", file=sys.stderr)
        return 1
    missing = []
    for f in fighters:
        path = ROOT / f["path"]
        if not path.is_file():
            missing.append(str(path))
    for auth in index.get("machine_authorities", []):
        path = ROOT / auth
        if not path.is_file():
            missing.append(str(path))
    master = ROOT / index.get("master", "")
    if not master.is_file():
        missing.append(str(master))
    if missing:
        print("FAIL missing paths:\n" + "\n".join(missing), file=sys.stderr)
        return 1
    inv = json.loads((ROOT / "data/bibles/animation_inventory_v1.json").read_text(encoding="utf-8"))
    if inv.get("authority_slot_count") != 111:
        print(f"FAIL: authority_slot_count expected 111 got {inv.get('authority_slot_count')}", file=sys.stderr)
        return 1
    if inv.get("repo_extension_policy", {}).get("back_air") != "RETAIN_CURRENT_REQUIRED_EXTENSION":
        print("FAIL: back_air policy missing/incorrect", file=sys.stderr)
        return 1
    print("PASS validate_bible_index")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
