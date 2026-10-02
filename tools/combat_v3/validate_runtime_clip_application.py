#!/usr/bin/env python3
"""Fail if V3 static clip maps exist while runtime would stay on idle.

Catches the staging-GLB path that ingested only idle clips and skipped
procedural combat JSON, which made Wave016/017 report idle after a real move_id.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GODOT = ROOT / "game-godot"
ALIAS = GODOT / "data/runtime/move_clip_alias_map.json"
CONTROLLER = GODOT / "scripts/visual/fighter_animation_controller.gd"
FIGHTER = GODOT / "scripts/fighters/fighter.gd"
GOLDEN = [
    ("jab_1", "jab"),
    ("forward_tilt", "tilt_forward"),
    ("up_tilt", "tilt_up"),
    ("down_tilt", "tilt_down"),
    ("dash_attack", "dash_attack"),
    ("neutral_air", "aerial_neutral"),
    ("forward_air", "aerial_forward"),
    ("back_air", "aerial_back"),
    ("up_air", "aerial_up"),
    ("down_air", "aerial_down"),
    ("neutral_special_projectile", "projectile_"),  # prefix
    ("side_special", "side_special"),
    ("up_special_recovery", "recovery"),
    ("down_special", "down_special"),
    ("grab", "grab"),
    ("aura_burst", "aura_burst"),
]


def main() -> int:
    errors: list[str] = []
    alias = json.loads(ALIAS.read_text())
    table = alias.get("move_id_to_clip") or {}
    ctrl = CONTROLLER.read_text()
    if ctrl.count("_load_procedural_clips(model_root)") < 2:
        errors.append("embedded staging path must still load procedural combat clips")
    if "procedural_runtime" not in ctrl:
        errors.append("procedural clips must be added as a named AnimationLibrary")
    if "_animation_play_key" not in ctrl or 'for lib_name in ["procedural_runtime"' not in ctrl:
        errors.append("named procedural library clips must be played with library prefix")
    fighter_src = FIGHTER.read_text()
    if "_FighterStates.ATTACK_ACTIVE" not in fighter_src or "_FighterStates.SPECIAL_ACTIVE" not in fighter_src:
        errors.append("airborne motion sync must not interrupt active attack/special into fall/idle")
    fighters = [
        "ember-vale",
        "rook-ironside",
        "juno-spark",
        "kaia-windrow",
        "nix-calder",
        "orion-vell",
        "vesper-nyx",
    ]
    if table.get("aura_burst") != "aura_burst":
        errors.append("aura_burst must route to dedicated aura_burst clip (Wave016 / Animation Authority V1.1)")
    # signature_lane_burst remains separate choreography content, not the aura_burst move binding.
    if table.get("signature_lane_burst") not in (None, "signature_lane_burst") and table.get("signature_lane_burst") == "aura_burst":
        errors.append("signature_lane_burst must remain a distinct choreography identity")
    if "signature_lane_burst" not in table:
        # Accept either explicit identity or absence as long as aura_burst is dedicated.
        pass
    for move_id, expect in GOLDEN:
        mapped = str(table.get(move_id, ""))
        if expect.endswith("_"):
            if not mapped.startswith(expect.rstrip("_")) and mapped not in (
                "projectile_tap",
                "projectile_medium",
                "projectile_full",
            ):
                errors.append(f"{move_id} maps to {mapped!r}, expected projectile_*")
            clip = mapped if mapped else "projectile_tap"
        else:
            if mapped != expect:
                errors.append(f"{move_id} maps to {mapped!r}, expected {expect!r}")
            clip = expect
        for fid in fighters:
            anim = GODOT / "content/fighters" / fid / "animations/procedural" / f"{clip}.anim.json"
            if expect.endswith("_"):
                ok_any = any(
                    (GODOT / "content/fighters" / fid / "animations/procedural" / f"{n}.anim.json").is_file()
                    for n in ("projectile_tap", "projectile_medium", "projectile_full")
                )
                if not ok_any:
                    errors.append(f"missing projectile clips for {fid}")
            elif not anim.is_file():
                errors.append(f"missing {anim.relative_to(ROOT)}")
    if errors:
        print("RUNTIME_CLIP_APPLICATION FAIL")
        for e in errors:
            print(" -", e)
        return 1
    print("RUNTIME_CLIP_APPLICATION OK static maps have procedural files; staging path loads them")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
