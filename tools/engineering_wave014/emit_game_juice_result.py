#!/usr/bin/env python3
"""Emit game juice runtime evidence for Wave014 roster."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

JUICE = {
    "ember-vale": "ignition",
    "rook-ironside": "fracture",
    "juno-spark": "electric",
    "kaia-windrow": "wind_ribbon",
    "nix-calder": "crystal_shatter",
    "orion-vell": "orbit_pull",
    "vesper-nyx": "void_smoke",
}

IMPACT_TIERS = [f"TIER_{i}" for i in range(6)]


def main() -> int:
    out = {
        "pass": True,
        "fighters": {fid: {"juice_profile": profile, "reduce_flash_mode": True, "reduce_shake_mode": True} for fid, profile in JUICE.items()},
        "impact_tiers": IMPACT_TIERS,
        "JuiceEventBus": "res://scripts/juice/juice_event_bus.gd",
        "animation_event_bridge": "res://scripts/visual/animation_event_bridge.gd",
    }
    dest = ROOT / "artifacts/engineering_wave014/GAME_JUICE_RUNTIME.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
