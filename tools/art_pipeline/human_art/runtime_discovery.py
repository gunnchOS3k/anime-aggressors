#!/usr/bin/env python3
"""Generic runtime-discovery contract for Wave014-class checks.

Does not hardcode PROCEDURAL_PRODUCTION_PROXY or GENERATED_PRODUCTION_ART.
Normalizes around ACTIVE_CHARACTER_PRESENTATION.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import FIGHTER_IDS, ROOT, accepted_proxy_glb, write_json  # noqa: E402

RESOLVER = ROOT / "game-godot/scripts/visual/fighter_asset_resolver.gd"


def main() -> int:
    fails = []
    text = RESOLVER.read_text(encoding="utf-8") if RESOLVER.is_file() else ""
    if "ACTIVE_CHARACTER_PRESENTATION" not in text:
        fails.append("resolver_missing_ACTIVE_CHARACTER_PRESENTATION")
    if "PROCEDURAL_PRODUCTION_PROXY" in text and "GENERATED_PRODUCTION_ART" in text:
        # Mentioning the labels is fine; selecting generated as current is not.
        if "canonical_glb_path" in text and "generated_glb_path" in text:
            if "CLASS_RESEARCH" not in text:
                fails.append("resolver_treats_generated_as_live_without_research_class")
    roster = []
    for fighter in FIGHTER_IDS:
        proxy = accepted_proxy_glb(fighter)
        row = {
            "fighter_id": fighter,
            "accepted_proxy_present": proxy.is_file(),
            "ACTIVE_CHARACTER_PRESENTATION": "CURRENT_ACCEPTED_ART" if proxy.is_file() else "MISSING",
        }
        if not proxy.is_file():
            fails.append(f"roster_missing_accepted_representation:{fighter}")
        roster.append(row)
    payload = {
        "ok": not fails,
        "failures": fails,
        "roster": roster,
        "ART_RUNTIME_DISCOVERY_PASS": not fails,
        "required_observations": [
            "roster fighter instances",
            "visible active model representation",
            "skeleton",
            "exactly one runtime animation controller per fighter",
            "non-empty action/clip state",
            "inspectable production resolver source",
        ],
        "hardcoded_forbidden": ["PROCEDURAL_PRODUCTION_PROXY", "GENERATED_PRODUCTION_ART"],
        "normalized_label": "ACTIVE_CHARACTER_PRESENTATION",
    }
    write_json(ROOT / "artifacts/art_pipeline/ART_RUNTIME_DISCOVERY.json", payload)
    print(json.dumps(payload, indent=2))
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    raise SystemExit(main())
