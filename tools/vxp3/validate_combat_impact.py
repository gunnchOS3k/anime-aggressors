#!/usr/bin/env python3
"""VXP-3 Phase 1 structural validators. Honest, no invented Pixel/human PASS."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GODOT = ROOT / "game-godot"
SLICE = ("nix-calder", "rook-ironside")
FAMILIES = [
    "flinch",
    "stagger",
    "crumple",
    "launch",
    "tumble",
    "spike",
    "freeze_stiffness",
    "body_snap",
    "shield_recoil",
    "ground_bounce",
    "wall_splat",
    "ko_spin",
]
REQUIRED_STATES = [
    "idle",
    "walk",
    "run",
    "jab",
    "heavy",
    "hurt",
    "launch",
    "tumble",
    "recovery",
    "aura_charge",
]
CONTACT = ["contact_light", "contact_medium", "contact_heavy", "contact_aura", "contact_super", "contact_ko"]
TIERS = ["light", "medium", "heavy", "aura", "super", "ko"]


def load(p: Path):
    return json.loads(p.read_text())


def clip_path(fid: str, name: str) -> Path:
    return GODOT / "content" / "fighters" / fid / "animations" / "procedural" / f"{name}.anim.json"


def sig(fid: str, name: str) -> str:
    return str(load(clip_path(fid, name)).get("curve_signature", ""))


def validate() -> dict:
    failures: list[str] = []
    notes: list[str] = []

    profiles = load(GODOT / "data" / "combat" / "impact_profiles.json")
    schema_ok = profiles.get("schema_id") == "anime_aggressors.impact_profile.v1"
    for t in TIERS:
        p = profiles.get("profiles", {}).get(t, {})
        if not p:
            failures.append(f"missing impact profile {t}")
            continue
        if int(p.get("attacker_hitstop_frames", -1)) != int(p.get("defender_hitstop_frames", -2)):
            failures.append(f"hitstop not synced for {t}")
        if not p.get("hitstop_sync"):
            failures.append(f"hitstop_sync false for {t}")
    if not profiles.get("no_silent_special_fallback"):
        failures.append("schema missing no_silent_special_fallback")

    lib = load(GODOT / "data" / "combat" / "hurt_reaction_library.json")
    for fam in FAMILIES:
        if fam not in lib.get("families", {}):
            failures.append(f"missing reaction family {fam}")
    for fid in SLICE:
        table = lib.get("fighter_clip_overrides", {}).get(fid, {})
        for fam in FAMILIES:
            clip = table.get(fam)
            if not clip or not clip_path(fid, clip).exists():
                failures.append(f"{fid} missing family clip {fam}")

    for fid in SLICE:
        for name in REQUIRED_STATES + CONTACT + [f"hurt_{f}" if f != "launch" else "hurt_launch" for f in FAMILIES]:
            # map family names that already include prefix
            pass
        for name in REQUIRED_STATES + CONTACT:
            if not clip_path(fid, name).exists():
                failures.append(f"{fid} missing required clip {name}")
        moves = load(GODOT / "data" / "moves" / f"{fid}.json").get("moves", [])
        if len(moves) < 23:
            failures.append(f"{fid} move count {len(moves)} < 23")
        for mv in moves:
            mid = mv.get("move_id")
            if mid == "special":
                failures.append(f"{fid} has generic special move_id")
            if mv.get("impact_profile") not in TIERS:
                failures.append(f"{fid} {mid} missing impact_profile")
            ch = mv.get("choreography", {})
            startup = int(mv.get("startup_frames", 0))
            active = int(mv.get("active_frames", 1))
            contact = int(ch.get("contact_frame", -1))
            if contact < startup or contact > startup + active:
                failures.append(f"{fid} {mid} contact_frame {contact} outside hitbox {startup}-{startup+active}")
            if not ch.get("victim_reaction_family"):
                failures.append(f"{fid} {mid} missing victim reaction")
            if "anime_timing" not in mv:
                failures.append(f"{fid} {mid} missing anime_timing")

    unique = True
    compared = 0
    for name in ["idle", "walk", "run", "jab", "hurt_flinch", "hurt_launch", "hurt_body_snap", "hurt_freeze_stiffness", "contact_heavy"]:
        a, b = sig("nix-calder", name), sig("rook-ironside", name)
        compared += 1
        if not a or a == b:
            unique = False
            failures.append(f"identical signature {name}")
        notes.append(f"{name}: nix={a[:10]} rook={b[:10]}")

    resolver = (GODOT / "scripts" / "visual" / "runtime_move_resolver.gd").read_text()
    if 'if requested == "special":' in resolver and "projectile_full" in resolver.split('if requested == "special":')[1][:400]:
        # silent loop must be gone
        block = resolver.split('if requested == "special":', 1)[1][:350]
        if "for fallback" in block:
            failures.append("silent special fallback still present")
    if 'return "special"' in (GODOT / "scripts" / "fighters" / "fighter_states.gd").read_text():
        failures.append("fighter_states still maps to generic special")

    train = (GODOT / "scripts" / "training" / "training_battle_scene.gd").read_text()
    for token in ["F11 freeze", "F12 step", "KEY_R", "KEY_1", "KEY_H", "training_impact_debug"]:
        if token not in train:
            failures.append(f"training missing {token}")

    a11y = (GODOT / "scripts" / "combat" / "combat_feedback.gd").read_text()
    if "_a11y_allows_camera" not in a11y or "warranted_camera" not in a11y:
        failures.append("a11y/camera warrant missing")
    juice = (GODOT / "scripts" / "juice" / "juice_event_bus.gd").read_text()
    if "EVENT_IMPACT_CLASS" not in juice or "can_reduce_flash" not in juice:
        failures.append("juice impact class / a11y reduce missing")

    hooks = [
        GODOT / "scripts" / "visual" / "charged_animation_layer.gd",
        GODOT / "scripts" / "combat" / "combat_cinematic_director.gd",
        GODOT / "data" / "combat" / "choreography_schema.json",
        GODOT / "data" / "combat" / "anime_timing.json",
    ]
    for h in hooks:
        if not h.exists():
            failures.append(f"missing hook {h.name}")

    return {
        "schema_ok": schema_ok and not any("impact profile" in f or "hitstop" in f for f in failures),
        "unique": unique,
        "compared": compared,
        "failures": failures,
        "notes": notes,
        "ok": not failures,
    }


def main() -> int:
    result = validate()
    out = ROOT / "artifacts" / "vxp3" / "reports" / "VXP3_VALIDATE.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
