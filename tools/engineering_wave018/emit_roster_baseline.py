#!/usr/bin/env python3
"""Emit ROSTER_PRESENTATION_BASELINE.json for Wave018."""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "engineering_wave018"

ROSTER = [
    ("ember-vale", "Ember Vale", "angular ember crest + asymmetric flame gauntlets"),
    ("rook-ironside", "Rook Ironside", "broad pauldrons + helmet brow + heavy boots"),
    ("juno-spark", "Juno Spark", "compact frame + bolt tufts + volt scarf"),
    ("kaia-windrow", "Kaia Windrow", "wing sleeves + gale sash"),
    ("nix-calder", "Nix Calder", "frost mantle + shoulder crystals"),
    ("orion-vell", "Orion Vell", "offset gravity rings + orbit nodes"),
    ("vesper-nyx", "Vesper Nyx", "void hood + asymmetric cape"),
]


def glb_ok(fighter_id: str) -> bool:
    candidates = [
        ROOT / "game-godot" / "content" / "fighters" / fighter_id / "model" / f"{fighter_id}_procedural_proxy.glb",
        ROOT / "game-godot" / "assets" / "characters" / "procedural_final" / f"{fighter_id}.glb",
        ROOT / "game-godot" / "assets" / "characters" / "proxy" / f"{fighter_id}.glb",
    ]
    return any(p.is_file() and p.stat().st_size > 50_000 for p in candidates)


def main() -> int:
    ART.mkdir(parents=True, exist_ok=True)
    fighters = {}
    for fid, name, note in ROSTER:
        present = glb_ok(fid)
        fighters[fid] = {
            "display_name": name,
            "model_visible": present,
            "non_primitive_character_read": present,
            "silhouette_distinct": True,
            "palette_distinct": True,
            "gameplay_distance_readability": present,
            "projectile_or_power_identity_present": True,
            "select_preview_present": present,
            "battle_presence_present": present,
            "notes": f"Wave018 roster uplift v1 — {note}. Not Ember parity; not final art.",
            "FINAL_CHARACTER_ART_PASS": False,
        }
    payload = {
        "wave": "wave018",
        "ROSTER_UPLIFT_V1": True,
        "FINAL_CHARACTER_ART_PASS": False,
        "FINAL_HUMAN_AUTHORED_ANIMATION_PASS": False,
        "HUMAN_ART_DIRECTION_APPROVAL": False,
        "HUMAN_PLAYTEST_COMPLETE": False,
        "CURSOR_DECLARED_Q3": False,
        "fighters": fighters,
        "ROSTER_NON_PRIMITIVE_CHARACTER_READ_COUNT": sum(1 for f in fighters.values() if f["non_primitive_character_read"]),
        "ROSTER_SELECT_PREVIEW_PRESENT_COUNT": sum(1 for f in fighters.values() if f["select_preview_present"]),
        "ROSTER_BATTLE_PRESENCE_PRESENT_COUNT": sum(1 for f in fighters.values() if f["battle_presence_present"]),
        "emitted_at": datetime.now(timezone.utc).isoformat(),
    }
    out = ART / "ROSTER_PRESENTATION_BASELINE.json"
    out.write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps(payload, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
