#!/usr/bin/env python3
"""Combat outcome contract tests. No Godot import and no asset download."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
COMBAT = ROOT / "game-godot/scripts/combat/combat_outcome.gd"
GUARD = ROOT / "game-godot/scripts/combat/perfect_guard.gd"
FIGHTER = ROOT / "game-godot/scripts/fighters/fighter.gd"
STATES = ROOT / "game-godot/scripts/fighters/fighter_states.gd"
PROJECT = ROOT / "game-godot/project.godot"

PARRY_WINDOW_FRAMES = 4
PARRY_REARM_FRAMES = 24
PARRY_DEFENDER_STUN_FRAMES = 2
PARRY_ATTACKER_STUN_FRAMES = 6
SHIELD_STUN_FALLBACK_SECONDS = 0.25
SIM_FPS = 60

AURA_BIBLE = {
    "ember-vale": "burn_rushdown",
    "juno-spark": "speed_chain",
    "kaia-windrow": "wind_drift",
    "rook-ironside": "armor_quake",
    "nix-calder": "freeze_control",
    "orion-vell": "gravity_pull",
    "vesper-nyx": "phase_mark",
    "yin": "cosmic_reduction",
    "yang": "cosmic_definition",
}


def const_int(text: str, name: str) -> int:
    match = re.search(rf"const {name} := (\d+)", text)
    if not match:
        raise AssertionError(f"missing {name}")
    return int(match.group(1))


def confirmed_body_damage(meter_before: float, dealt: float, authored: float, ratio: float) -> dict:
    applied = dealt
    if applied <= 0.0 and authored > 0.0 and ratio > 0.0:
        applied = authored * ratio
    if applied < 0.0:
        applied = 0.0
    after = meter_before + applied
    return {
        "event": "hit_damage_applied" if applied > 0.0 else "hit_damage_zero",
        "damage_applied": applied,
        "meter_after": after,
        "meter_changed": applied > 0.0,
        "stocks_delta": 0,
    }


def parry_window_open(age: int, consumed: bool) -> bool:
    return (not consumed) and age >= 0 and age < PARRY_WINDOW_FRAMES


def shield_contact(health: float, shield_damage: float, parry_open: bool, stun_frames: int) -> dict:
    if parry_open:
        return {
            "state": "parry",
            "next_state": "shield_hold",
            "event": "parry",
            "parry_result": "success",
            "damage_applied": 0.0,
            "shield_health": health,
            "defender_stun_frames": PARRY_DEFENDER_STUN_FRAMES,
            "attacker_stun_frames": PARRY_ATTACKER_STUN_FRAMES,
            "stocks_delta": 0,
        }
    next_health = health - max(0.0, shield_damage)
    if next_health <= 0.0:
        return {
            "state": "shield_break",
            "event": "shield_break",
            "parry_result": "fail",
            "damage_applied": 0.0,
            "shield_health": 0.0,
            "stocks_delta": 0,
        }
    frames = stun_frames if stun_frames > 0 else int(round(SHIELD_STUN_FALLBACK_SECONDS * SIM_FPS))
    return {
        "state": "shield_hit",
        "next_state": "shield_stun",
        "event": "shield_hit",
        "parry_result": "fail",
        "damage_applied": 0.0,
        "shield_health": next_health,
        "shield_stun_frames": frames,
        "stocks_delta": 0,
    }


def check(name: str, cond: bool) -> None:
    if not cond:
        raise AssertionError(name)
    print("ok", name)


def main() -> int:
    combat = COMBAT.read_text()
    guard = GUARD.read_text()
    fighter = FIGHTER.read_text()
    states = STATES.read_text()
    project = PROJECT.read_text()

    for name, expected in (
        ("PARRY_WINDOW_FRAMES", PARRY_WINDOW_FRAMES),
        ("PARRY_REARM_FRAMES", PARRY_REARM_FRAMES),
        ("PARRY_DEFENDER_STUN_FRAMES", PARRY_DEFENDER_STUN_FRAMES),
        ("PARRY_ATTACKER_STUN_FRAMES", PARRY_ATTACKER_STUN_FRAMES),
    ):
        check(f"outcome {name}", const_int(combat, name) == expected)
    check("guard window", const_int(guard, "WINDOW_FRAMES") == PARRY_WINDOW_FRAMES)
    check("guard rearm", const_int(guard, "REARM_FRAMES") == PARRY_REARM_FRAMES)
    check("guard defender stun", const_int(guard, "DEFENDER_STUN_FRAMES") == PARRY_DEFENDER_STUN_FRAMES)
    check("guard attacker stun", const_int(guard, "ATTACKER_STUN_FRAMES") == PARRY_ATTACKER_STUN_FRAMES)

    # Public training symptom: HIT jab_1 with shield_dmg 3.0 and a 0% meter.
    # Authored jab damage is 2.5. A dropped dealt value must still move the meter.
    jab = confirmed_body_damage(0.0, 0.0, 2.5, 1.0)
    check("jab meter moves", jab["meter_after"] == 2.5 and jab["meter_changed"] and jab["stocks_delta"] == 0)
    check("jab event", jab["event"] == "hit_damage_applied")
    kept = confirmed_body_damage(10.0, 2.5, 2.5, 1.0)
    check("dealt is not doubled", kept["meter_after"] == 12.5)
    zero_ratio = confirmed_body_damage(0.0, 0.0, 2.5, 0.0)
    check("zero ratio stays", zero_ratio["meter_after"] == 0.0 and zero_ratio["event"] == "hit_damage_zero")

    blocked = shield_contact(100.0, 3.0, False, 6)
    check("shield hit", blocked["state"] == "shield_hit" and blocked["next_state"] == "shield_stun")
    check("shield chip", blocked["shield_health"] == 97.0 and blocked["damage_applied"] == 0.0)
    check("jab stun frames", blocked["shield_stun_frames"] == 6 and blocked["stocks_delta"] == 0)
    broken = shield_contact(2.0, 3.0, False, 6)
    check("shield break", broken["state"] == "shield_break" and broken["shield_health"] == 0.0 and broken["parry_result"] == "fail")
    fallback = shield_contact(100.0, 1.0, False, 0)
    check("fallback stun", fallback["shield_stun_frames"] == 15)

    check("parry frame 0", parry_window_open(0, False))
    check("parry frame 3", parry_window_open(3, False))
    check("parry frame 4 fails", not parry_window_open(4, False))
    check("parry consumed fails", not parry_window_open(1, True))
    success = shield_contact(100.0, 3.0, True, 6)
    check(
        "parry success",
        success["event"] == "parry"
        and success["parry_result"] == "success"
        and success["damage_applied"] == 0.0
        and success["defender_stun_frames"] == 2
        and success["attacker_stun_frames"] == 6
        and success["shield_health"] == 100.0
        and success["stocks_delta"] == 0,
    )

    for fid, tag in AURA_BIBLE.items():
        check(f"bible {fid}", f'"{fid}"' in combat and tag in combat)
    for state in ("shield_start", "shield_hold", "shield_hit", "shield_stun", "shield_break"):
        check(f"state {state}", f'const SHIELD_{state.split("_", 1)[1].upper()}' in states or f':= "{state}"' in states)
    check("shield_hit const", 'const SHIELD_HIT := "shield_hit"' in states)
    check("fighter applies meter", "confirmed_body_damage" in fighter and "damage_percent = float(outcome" in fighter)
    check("fighter shield hit", "SHIELD_HIT" in fighter)
    check("shield action has key and pad", "p1_shield=" in project and "InputEventKey" in project and "InputEventJoypadButton" in project)
    p1_up = project.split("p1_up=", 1)[1].split("p1_down=", 1)[0]
    p1_grab = project.split("p1_grab=", 1)[1].split("p2_left=", 1)[0]
    p1_shield = project.split("p1_shield=", 1)[1].split("p1_dodge=", 1)[0]
    check("p1 up joypad", "InputEventJoypadMotion" in p1_up)
    check("p1 grab joypad", "InputEventJoypadButton" in p1_grab)
    check("p1 shield key and pad", "InputEventKey" in p1_shield and "InputEventJoypadButton" in p1_shield)
    print("combat_outcomes pass")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except AssertionError as exc:
        print("FAIL", exc)
        sys.exit(1)
