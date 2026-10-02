#!/usr/bin/env python3
"""Fail if required authority slots disappear from inventory or spectrum clip coverage."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SPECTRUM = [
    "ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
    "nix-calder", "orion-vell", "vesper-nyx",
]


def main() -> int:
    inv = json.loads((ROOT / "data/bibles/animation_inventory_v1.json").read_text(encoding="utf-8"))
    slots = [s["id"] for c in inv["categories"] for s in c["slots"]]
    if len(slots) != 111:
        print(f"FAIL: required authority slot count 111, got {len(slots)}", file=sys.stderr)
        return 1
    if "back_air" not in slots:
        print("FAIL: back_air authority slot missing", file=sys.stderr)
        return 1
    errors = []
    for fid in SPECTRUM:
        root = ROOT / "content/fighters" / fid / "animations/procedural"
        clips = {p.name.replace(".anim.json", "") for p in root.glob("*.anim.json")} if root.is_dir() else set()
        missing = [s for s in slots if s not in clips]
        if missing:
            errors.append(f"{fid}: missing {len(missing)} authority clips e.g. {missing[:5]}")
    if errors:
        print("FAIL audit_state_coverage:\n" + "\n".join(errors), file=sys.stderr)
        return 1
    print("PASS audit_state_coverage")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
