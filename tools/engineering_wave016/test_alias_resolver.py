#!/usr/bin/env python3
"""Unit checks for Wave016 canonical alias map (no Godot required)."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def main() -> int:
    alias = json.loads((ROOT / "content/runtime/move_clip_alias_map.json").read_text())
    table = alias["move_id_to_clip"]
    required = {
        "forward_tilt": "tilt_forward",
        "up_tilt": "tilt_up",
        "down_tilt": "tilt_down",
        "neutral_air": "aerial_neutral",
        "forward_air": "aerial_forward",
        "back_air": "aerial_back",
        "up_air": "aerial_up",
        "down_air": "aerial_down",
        "jab_1": "jab",
        "jab_2": "jab_chain_2",
        "jab_finisher": "jab_chain_3",
        "heavy_attack": "heavy",
        "aura_burst": "signature_lane_burst",
        "throw_forward": "throw_forward",
        "throw_back": "throw_back",
        "throw_up": "throw_up",
        "throw_down": "throw_down",
        "up_special_recovery": "recovery",
        "dash_attack": "heavy",
    }
    failed = []
    for k, v in required.items():
        if table.get(k) != v:
            failed.append(f"{k}: got {table.get(k)!r} want {v!r}")
    # Clips exist for ember
    for clip in set(required.values()):
        p = ROOT / "game-godot/content/fighters/ember-vale/animations/procedural" / f"{clip}.anim.json"
        if not p.is_file():
            failed.append(f"missing clip file {clip}")
    # Must not claim 357 reachable
    if "force_all_reachable" in alias:
        failed.append("must not force all clips reachable")
    if failed:
        print("FAIL", *failed, sep="\n")
        return 1
    print("PASS alias resolver unit checks", len(required))
    return 0


if __name__ == "__main__":
    sys.exit(main())
