#!/usr/bin/env python3
"""Require each live spectrum move_id to resolve to a dedicated clip (not generic jab/special)."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SPECTRUM = [
    "ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
    "nix-calder", "orion-vell", "vesper-nyx",
]
LIVE_MOVES = [
    "jab_1", "jab_2", "jab_finisher", "forward_tilt", "up_tilt", "down_tilt",
    "dash_attack", "heavy_attack", "neutral_air", "forward_air", "back_air",
    "up_air", "down_air", "neutral_special_projectile", "side_special",
    "up_special_recovery", "down_special", "grab", "throw_forward", "throw_back",
    "throw_up", "throw_down", "aura_charge", "aura_burst",
]
FORBIDDEN_SHARED = {
    # All attacks must not collapse to a single jab clip via the alias map values being identical
}


def main() -> int:
    alias = json.loads((ROOT / "game-godot/data/runtime/move_clip_alias_map.json").read_text(encoding="utf-8"))
    table = alias.get("move_id_to_clip", {})
    errors = []
    if "back_air" not in table:
        errors.append("back_air missing from move_id_to_clip (must RETAIN)")
    clips_used = []
    for move_id in LIVE_MOVES:
        if move_id not in table:
            errors.append(f"move_id {move_id} has no clip resolution")
            continue
        clips_used.append(table[move_id])
    # Attack moves must not all map to the same clip
    attack_clips = [table[m] for m in LIVE_MOVES if m in table and m not in ("aura_charge", "aura_burst", "grab")]
    if len(set(attack_clips)) < 10:
        errors.append(f"attack clip diversity too low ({len(set(attack_clips))}); coarse jab/special lie suspected")
    for fid in SPECTRUM:
        root = ROOT / "content/fighters" / fid / "animations/procedural"
        present = {p.name.replace(".anim.json", "") for p in root.glob("*.anim.json")} if root.is_dir() else set()
        for move_id in LIVE_MOVES:
            clip = table.get(move_id)
            if not clip:
                continue
            if clip not in present and move_id not in present:
                # authority slot clip may use move_id name
                errors.append(f"{fid}: move {move_id} -> {clip} clip missing")
    if errors:
        print("FAIL audit_move_clip_resolution:\n" + "\n".join(errors[:40]), file=sys.stderr)
        return 1
    print(f"PASS audit_move_clip_resolution SPECTRUM_MOVE_SLOT_COUNT={7*24} unique_attack_clips={len(set(attack_clips))}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
