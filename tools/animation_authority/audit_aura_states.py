#!/usr/bin/env python3
"""Aura state authority: BASE/CHARGED/SURGE/ASCENDANT/SUPER must be represented."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SPECTRUM = [
    "ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
    "nix-calder", "orion-vell", "vesper-nyx",
]
REQUIRED_AURA_SLOTS = [
    "aura_charge", "aura_ready", "aura_burst_startup",
    "aura_burst_active", "aura_burst_recovery", "aura_super_transform",
]


def main() -> int:
    aura = json.loads((ROOT / "data/bibles/aura_profiles_v1.json").read_text(encoding="utf-8"))
    errors = []
    # Accept fighters map or levels list
    text = json.dumps(aura).upper()
    for level in ("BASE", "CHARGED", "SURGE", "ASCENDANT", "SUPER"):
        if level not in text:
            errors.append(f"aura profile missing level token {level}")
    for fid in SPECTRUM:
        root = ROOT / "content/fighters" / fid / "animations/procedural"
        clips = {p.name.replace(".anim.json", "") for p in root.glob("*.anim.json")}
        missing = [s for s in REQUIRED_AURA_SLOTS if s not in clips]
        if missing:
            errors.append(f"{fid} missing aura slots {missing}")
    if errors:
        print("FAIL audit_aura_states:\n" + "\n".join(errors), file=sys.stderr)
        return 1
    print("PASS audit_aura_states")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
