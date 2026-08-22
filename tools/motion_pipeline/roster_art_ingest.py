#!/usr/bin/env python3
"""Roster art ingest contract — VRoid recipes to Godot proxy mapping (no final models)."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIGHTERS = [
    "ember-vale",
    "rook-ironside",
    "juno-spark",
    "kaia-windrow",
    "nix-calder",
    "orion-vell",
    "vesper-nyx",
]


def main() -> int:
    entries = []
    for fid in FIGHTERS:
        recipe = ROOT / f"docs/art_pipeline/VRoid_FIGHTER_AUTHORING_PACKETS/{fid}.md"
        proxy = ROOT / f"game-godot/assets/characters/proxy/{fid}.glb"
        entries.append(
            {
                "fighter_id": fid,
                "vroid_recipe_present": recipe.exists(),
                "vroid_source_model_present": False,
                "proxy_glb_present": proxy.exists(),
                "ingest_status": "RECIPE_READY_PROXY_ONLY",
            }
        )
    out = {
        "schema_version": 1,
        "VROID_SOURCE_MODELS_PRESENT": 0,
        "entries": entries,
        "pass": all(e["vroid_recipe_present"] for e in entries),
    }
    dest = ROOT / "artifacts/wave013b/ROSTER_ART_INGEST.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    return 0 if out["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
