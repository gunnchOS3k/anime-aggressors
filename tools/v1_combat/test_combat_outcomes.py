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


def confirmed_body_damage(meter_before: float, resolved: float, gate: str = "hit") -> dict:
    applied = resolved if gate == "hit" and resolved > 0.0 else 0.0
    after = meter_before + applied
    return {
        "event": "hit_damage_applied" if applied > 0.0 else "hit_damage_zero",
        "gate": gate,
        "damage_applied": applied,
        "meter_after": after,
        "meter_changed": applied > 0.0,
        "stocks_delta": 0,
    }


def zero_reason(authored: float, dealt: float, ratio: float, dealt_mult: float) -> str:
    if authored <= 0.0 and dealt <= 0.0:
        return "explicit_zero"
    if ratio <= 0.0:
        return "rules_zero"
    if dealt_mult <= 0.0:
        return "dealt_mult_zero"
    if dealt <= 0.0:
        return "resolved_zero"
    return ""


def resolve_dealt(authored: float, scaled: float, ratio: float, dealt_mult: float, stale: float = 1.0, combo: float = 1.0, armor_chip: float = 1.0) -> float:
    return scaled * dealt_mult * ratio * stale * combo * armor_chip


def apply_contact(meter: float, authored: float, scaled: float, ratio: float, dealt_mult: float, gate: str, stale: float = 1.0, combo: float = 1.0, armor_chip: float = 1.0) -> dict:
    dealt = resolve_dealt(authored, scaled, ratio, dealt_mult, stale, combo, armor_chip)
    reason = gate if gate in {"parry", "shield", "armor", "invulnerable"} else zero_reason(authored, dealt, ratio, dealt_mult)
    contact_gate = reason if reason else "hit"
    # Authored is intentionally unused after resolution. Passing it must not change the meter.
    _ = authored
    return confirmed_body_damage(meter, dealt if contact_gate == "hit" else 0.0, contact_gate)


def parry_window_open(age: int, consumed: bool) -> bool:
    return (not consumed) and age >= 0 and age < PARRY_WINDOW_FRAMES


def guard_transition(current: str, held: bool, just_pressed: bool, grounded: bool, allowed: bool, actions_locked: bool) -> dict:
    guarding = current in {"shield_start", "shield_hold"}
    if guarding and (not held or not grounded):
        return {"state": "idle" if grounded else "fall", "event": "shield_release", "begin_parry": False}
    if current == "shield_start" and held and grounded:
        return {"state": "shield_hold", "event": "shield_hold", "begin_parry": False}
    if current == "shield_hold" and held and grounded:
        return {"state": "shield_hold", "event": "", "begin_parry": False}
    if current in {"shield_hit", "shield_stun", "shield_break"}:
        return {"state": current, "event": "", "begin_parry": False}
    if actions_locked or not held or not grounded or not allowed:
        return {"state": current, "event": "", "begin_parry": False}
    if just_pressed:
        return {"state": "shield_start", "event": "shield_start", "begin_parry": True}
    return {"state": "shield_hold", "event": "shield_hold", "begin_parry": False}


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

    # Ember jab is authored 2.5 and shield_damage 3. The percent meter follows
    # resolved body damage. Shield damage and authored damage do not fill a zero.
    jab = apply_contact(0.0, 2.5, 2.5, 1.0, 1.0, "hit")
    check("jab meter moves", jab["meter_after"] == 2.5 and jab["meter_changed"] and jab["stocks_delta"] == 0)
    check("jab event", jab["event"] == "hit_damage_applied" and jab["gate"] == "hit")
    kept = apply_contact(10.0, 2.5, 2.5, 1.0, 1.0, "hit")
    check("dealt is not doubled", kept["meter_after"] == 12.5 and kept["damage_applied"] == 2.5)
    scaled_hit = apply_contact(0.0, 2.5, 4.0, 1.0, 1.0, "hit")
    check("resolved wins over authored", scaled_hit["damage_applied"] == 4.0 and scaled_hit["meter_after"] == 4.0)
    rules_zero = apply_contact(0.0, 2.5, 2.5, 0.0, 1.0, "hit")
    check("rules zero stays", rules_zero["meter_after"] == 0.0 and rules_zero["gate"] == "rules_zero" and rules_zero["event"] == "hit_damage_zero")
    mult_zero = apply_contact(3.0, 2.5, 2.5, 1.0, 0.0, "hit")
    check("dealt mult zero stays", mult_zero["meter_after"] == 3.0 and mult_zero["gate"] == "dealt_mult_zero")
    explicit_zero = apply_contact(0.0, 0.0, 0.0, 1.0, 1.0, "hit")
    check("explicit zero move stays", explicit_zero["meter_after"] == 0.0 and explicit_zero["gate"] == "explicit_zero")
    for immune in ("parry", "shield", "armor", "invulnerable"):
        blocked_hit = apply_contact(8.0, 2.5, 2.5, 1.0, 1.0, immune)
        check(f"{immune} ignores authored", blocked_hit["meter_after"] == 8.0 and blocked_hit["damage_applied"] == 0.0 and blocked_hit["gate"] == immune)
    chip = apply_contact(0.0, 2.5, 2.5, 1.0, 1.0, "hit", armor_chip=0.55)
    check("armor chip still hits", abs(chip["damage_applied"] - 1.375) < 1e-9 and chip["gate"] == "hit")

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
    pressed = guard_transition("idle", True, True, True, True, False)
    check("press is shield_start", pressed["state"] == "shield_start" and pressed["event"] == "shield_start" and pressed["begin_parry"])
    held_next = guard_transition("shield_start", True, False, True, True, True)
    check("held after press is shield_hold", held_next["state"] == "shield_hold" and held_next["event"] == "shield_hold" and not held_next["begin_parry"])
    stayed = guard_transition("shield_hold", True, False, True, True, True)
    check("hold stays hold", stayed["state"] == "shield_hold" and stayed["event"] == "")
    already = guard_transition("idle", True, False, True, True, False)
    check("already held skips start", already["state"] == "shield_hold" and not already["begin_parry"])
    released = guard_transition("shield_hold", False, False, True, True, True)
    check("release to idle", released["state"] == "idle" and released["event"] == "shield_release")
    airborne = guard_transition("shield_start", True, False, False, True, True)
    check("air guard falls", airborne["state"] == "fall")
    for locked in ("shield_hit", "shield_stun", "shield_break"):
        kept_state = guard_transition(locked, True, True, True, True, True)
        check(f"{locked} not replaced", kept_state["state"] == locked and kept_state["event"] == "")
    blocked_start = guard_transition("idle", True, True, True, False, False)
    check("disallowed press stays idle", blocked_start["state"] == "idle" and not blocked_start["begin_parry"])

    for fid, tag in AURA_BIBLE.items():
        check(f"bible {fid}", f'"{fid}"' in combat and tag in combat)
    for state in ("shield_start", "shield_hold", "shield_hit", "shield_stun", "shield_break"):
        check(f"state {state}", f'const SHIELD_{state.split("_", 1)[1].upper()}' in states or f':= "{state}"' in states)
    check("shield_hit const", 'const SHIELD_HIT := "shield_hit"' in states)
    check("no authored override", "authored_damage * damage_ratio" not in combat and "authored_damage > 0.0" not in combat)
    check("gate keeps zero", 'if gate == "hit" and resolved_damage > 0.0' in combat)
    check("fighter applies resolved meter", "confirmed_body_damage(damage_percent, dmg, gate)" in fighter)
    check("fighter uses guard transition", "guard_transition(" in fighter and "func guard_transition" in combat)
    check("start is not same-frame hold", "enter(_FighterStates.SHIELD_START)\n\t\tstate_machine.enter(_FighterStates.SHIELD_HOLD)" not in fighter)
    check("resolver records zero reason", "damage_zero_reason" in (ROOT / "game-godot/scripts/combat/hit_resolver.gd").read_text())
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
