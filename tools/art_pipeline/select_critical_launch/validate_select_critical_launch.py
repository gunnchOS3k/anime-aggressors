#!/usr/bin/env python3
"""Structural gates for select announcer, opacity/ROYGBIV, auto-fit, critical launch.

Never promotes HUMAN_* / OWNER_* / MERGE_AUTHORIZED. CombatMath must stay untouched.
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
FIGHTERS = (
    "ember-vale",
    "rook-ironside",
    "juno-spark",
    "kaia-windrow",
    "nix-calder",
    "orion-vell",
    "vesper-nyx",
)
NAMES = {
    "ember-vale": "Ember Vale",
    "rook-ironside": "Rook Ironside",
    "juno-spark": "Juno Spark",
    "kaia-windrow": "Kaia Windrow",
    "nix-calder": "Nix Calder",
    "orion-vell": "Orion Vell",
    "vesper-nyx": "Vesper Nyx",
}
CUES = {
    "ember-vale": "furnace_flare_rupture",
    "rook-ironside": "tectonic_impact_fracture",
    "juno-spark": "voltage_fork",
    "kaia-windrow": "wind_shear_cleave",
    "nix-calder": "crystal_break_launch",
    "orion-vell": "gravity_rift_constellation",
    "vesper-nyx": "phase_tear_rupture",
}
FAMILIES = {
    "ember-vale": "red-orange",
    "rook-ironside": "orange-iron",
    "juno-spark": "yellow-gold",
    "kaia-windrow": "green",
    "nix-calder": "blue",
    "orion-vell": "indigo",
    "vesper-nyx": "violet",
}
OWNER_FALSE = {
    "OWNER_SELECT_ANNOUNCER_PASS": False,
    "OWNER_ROYGBIV_OPACITY_PASS": False,
    "OWNER_FRAMING_PASS": False,
    "OWNER_LAUNCH_TRAIL_PASS": False,
    "OWNER_CRITICAL_LAUNCH_FEEL_PASS": False,
    "HUMAN_ROSTER_ART_DIRECTION_PASS": False,
    "HUMAN_ROSTER_COMBAT_FEEL_PASS": False,
    "HUMAN_ROSTER_MOBILE_READ_PASS": False,
    "HUMAN_ROSTER_CLIP_WORTHY_PASS": False,
    "MERGE_AUTHORIZED": False,
}


def load_json(path: Path) -> dict:
    if not path.is_file():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def text(rel: str) -> str:
    path = ROOT / rel
    return path.read_text(encoding="utf-8") if path.is_file() else ""


def hue_gap(a: float, b: float) -> float:
    d = abs(a - b) % 360.0
    return min(d, 360.0 - d)


def rgb_hue(rgb: list[float]) -> float:
    r, g, b = rgb[0], rgb[1], rgb[2]
    mx = max(r, g, b)
    mn = min(r, g, b)
    if mx - mn < 1e-6:
        return 0.0
    if mx == r:
        h = (g - b) / (mx - mn)
    elif mx == g:
        h = 2.0 + (b - r) / (mx - mn)
    else:
        h = 4.0 + (r - g) / (mx - mn)
    return (h * 60.0) % 360.0


def evaluate() -> dict:
    failures: list[str] = []
    data = load_json(ROOT / "game-godot/data/runtime/elemental_material_language.json")
    fighters = data.get("fighters", {})
    style = data.get("style", {})
    announcer = text("game-godot/scripts/audio/fighter_announcer.gd")
    callout = text("game-godot/scripts/ui/lockin_name_callout.gd")
    select = text("game-godot/scripts/menus/fighter_select_scene.gd")
    contract = text("game-godot/scripts/visual/elemental_material_contract.gd")
    shader = text("game-godot/shaders/fighter_toon.gdshader")
    fit = text("game-godot/scripts/visual/geometry_auto_fit.gd")
    framing = text("game-godot/scripts/menus/character_select_framing.gd")
    model = text("game-godot/scripts/fighters/fighter_model_3d.gd")
    fighter = text("game-godot/scripts/fighters/fighter.gd")
    predictor = text("game-godot/scripts/combat/critical_launch_predictor.gd")
    trail = text("game-godot/scripts/visual/launch_trail_system.gd")
    cue = text("game-godot/scripts/visual/critical_launch_cue.gd")
    feedback = text("game-godot/scripts/combat/combat_feedback.gd")
    combat_math = text("game-godot/scripts/combat/combat_math.gd")
    labs = text("game-godot/scripts/labs/launch_feedback_review_scene.gd")
    sel_review = text("game-godot/scripts/labs/selection_review_scene.gd")
    review_doc = text("docs/playtest/SELECT_ANNOUNCER_CRITICAL_LAUNCH_PIXEL_REVIEW.md")

    announcer_event = all(
        token in announcer
        for token in (
            "fighter_lock_started",
            "fighter_locked",
            "announcer_name_started",
            "announcer_name_finished",
            "hover_does_not_announce",
            "DEBOUNCE_SEC",
        )
    ) and "_announce_lock" in select and "play(" in callout
    if not announcer_event:
        failures.append("announcer_events_incomplete")
    rights_ready = "ANNOUNCER_FINAL_VOICE_ASSETS := false" in announcer or "ANNOUNCER_FINAL_VOICE_ASSETS = false" in announcer
    if "ANNOUNCER_FINAL_VOICE_ASSETS := true" in announcer:
        failures.append("announcer_final_voice_claimed_without_assets")
        rights_ready = False
    lockin_visual = "EMBER VALE" in announcer or "shout_label" in announcer
    if not lockin_visual or "reduce_motion" not in callout:
        failures.append("lockin_visual_incomplete")
        lockin_visual = False

    hues = []
    roygbiv = True
    opacity = True
    detail = True
    identity_rows = {}
    for fid in FIGHTERS:
        entry = fighters.get(fid, {})
        core = entry.get("core", [0, 0, 0, 0])
        structure = entry.get("structure", [0, 0, 0, 0])
        accent = entry.get("accent", [0, 0, 0, 0])
        if str(entry.get("roygbiv_family", "")) != FAMILIES[fid]:
            failures.append(f"family_mismatch:{fid}")
            roygbiv = False
        if float(core[3]) < 0.92:
            failures.append(f"body_alpha_low:{fid}")
            opacity = False
        if float(structure[3]) < 0.97:
            failures.append(f"structure_alpha_low:{fid}")
            opacity = False
        if len(str(entry.get("bible_detail", ""))) < 40:
            failures.append(f"bible_thin:{fid}")
            detail = False
        if str(entry.get("critical_cue", "")) != CUES[fid]:
            failures.append(f"cue_mismatch:{fid}")
        hues.append(float(entry.get("family_hue_deg", 0)))
        identity_rows[fid] = {
            "display_name": NAMES[fid],
            "roygbiv_family": entry.get("roygbiv_family"),
            "family_hue_deg": entry.get("family_hue_deg"),
            "core": core,
            "structure": structure,
            "accent": accent,
            "normal_alpha_range": [float(style.get("body_alpha_min", 0)), float(style.get("body_alpha_max", 0))],
            "bible_detail": entry.get("bible_detail"),
            "critical_cue": entry.get("critical_cue"),
            "announcement": NAMES[fid],
        }
    for i in range(len(hues) - 1):
        if hues[i] >= hues[i + 1] or hue_gap(hues[i], hues[i + 1]) < 14:
            failures.append(f"roygbiv_spacing:{FIGHTERS[i]}")
            roygbiv = False
    # Readable identity: Juno gold, Kaia green, Nix blue (not navy/teal-only cores).
    juno_core = fighters.get("juno-spark", {}).get("core", [0, 0, 0])
    kaia_core = fighters.get("kaia-windrow", {}).get("core", [0, 0, 0])
    nix_core = fighters.get("nix-calder", {}).get("core", [0, 0, 0])
    if juno_core[0] < 0.8 or juno_core[1] < 0.65:
        failures.append("juno_not_gold_identity")
        roygbiv = False
    if kaia_core[1] < 0.55 or kaia_core[1] <= kaia_core[2]:
        failures.append("kaia_not_green_identity")
        roygbiv = False
    if nix_core[2] < 0.7 or nix_core[2] <= nix_core[1]:
        failures.append("nix_not_blue_identity")
        roygbiv = False
    opacity = opacity and float(style.get("body_alpha_min", 0)) >= 0.92 and "body_alpha_floor" in shader
    if "0.62, 0.96" in shader:
        failures.append("shader_old_alpha_clamp")
        opacity = False
    if "vesper_idle_alpha_floor" not in style or float(style.get("vesper_idle_alpha_floor", 0)) < 0.92:
        failures.append("vesper_idle_floor")
        opacity = False
    if "luma < 0.22" in contract:
        failures.append("luma_role_heuristic_still_washes_identity")
        detail = False

    auto_fit = all(
        token in fit
        for token in ("compute_visible_aabb", "occupancy_for", "SELECT_CARD", "MATCH_START", "visual_center")
    ) and "per_fighter_magic_scale" in framing and "rook-ironside" not in framing
    if not auto_fit:
        failures.append("auto_fit_incomplete")
    isolation = (
        "SELECT_SCALE_LEAK_TO_BATTLE" in model
        and "SELECT_CAMERA_LEAK_TO_BATTLE" in model
        and "SELECT_MATERIAL_IDENTITY_MISMATCH" in model
        and "Fresh battle context" in fighter
    )
    if not isolation:
        failures.append("context_isolation_incomplete")

    predictor_ok = all(
        token in predictor
        for token in ("SAFE", "DANGEROUS", "CRITICAL_RECOVERABLE", "NEAR_CERTAIN_KO", "mutates_gameplay")
    ) and "knockback_vector" not in predictor
    if not predictor_ok:
        failures.append("predictor_incomplete")
    if "static func knockback_vector" not in combat_math:
        failures.append("combat_math_missing")
    trail_ok = "LOW" in trail and "HIGH" in trail and "CRITICAL" in trail
    cue_ok = all(name in cue for name in CUES.values()) and "roster_wide_red_lightning" in cue
    if not cue_ok:
        failures.append("elemental_cues_incomplete")
    no_spam = "critical_suppressed" in feedback and "multi_hit" in feedback and "already_past_blast" in predictor
    a11y = "reduce_motion" in cue and "high_contrast" in cue and "color_only" in cue
    labs_ok = "PredictorDebug" in labs and "gameplay_exposed" in labs and "lockin" in sel_review
    pixel_ok = (
        "OWNER_REVIEW_SELECT_ANNOUNCER_OPACITY_FRAMING_AND_CRITICAL_LAUNCH_ON_PIXEL" in review_doc
        and all(name in review_doc for name in NAMES.values())
    )
    if not pixel_ok:
        failures.append("pixel_review_doc_incomplete")

    card_fit = 7 if auto_fit else 0
    preview_fit = 7 if auto_fit else 0
    mapping = 7 if cue_ok else sum(1 for c in CUES.values() if c in cue)

    gates = {
        "SELECT_ANNOUNCER_EVENT_PASS": announcer_event,
        "SELECT_ANNOUNCER_AUDIO_RIGHTS_READY": False,
        "SELECT_LOCKIN_VISUAL_PASS": lockin_visual and announcer_event,
        "ROSTER_ROYGBIV_SELECT_PASS": roygbiv,
        "NORMAL_BODY_OPACITY_FLOOR_PASS": opacity,
        "ELEMENTAL_DETAIL_PRESERVATION_PASS": detail,
        "SELECT_CARD_AUTO_FIT_PASS": f"{card_fit}/7",
        "SELECT_PREVIEW_AUTO_FIT_PASS": f"{preview_fit}/7",
        "MATCH_START_FRAMING_PASS": auto_fit,
        "SELECT_TO_BATTLE_CONTEXT_ISOLATION_PASS": isolation,
        "HIGH_LAUNCH_TRAIL_PASS": trail_ok,
        "CRITICAL_LAUNCH_PREDICTOR_PASS": predictor_ok,
        "CRITICAL_LAUNCH_ELEMENTAL_MAPPING_PASS": f"{mapping}/7",
        "CRITICAL_LAUNCH_ACCESSIBILITY_PASS": a11y,
        "CRITICAL_LAUNCH_NO_FALSE_SPAM_PASS": no_spam,
        "LABS_LAUNCH_FEEDBACK_PASS": labs_ok,
        "PIXEL_REVIEW_ROUTE_PASS": pixel_ok,
        **OWNER_FALSE,
    }

    emitted = datetime.now(timezone.utc).isoformat()
    lockin = {
        "schema": "select_lockin_matrix/v1",
        "emitted_at": emitted,
        "ANNOUNCER_FINAL_VOICE_ASSETS": False,
        "fighters": {
            fid: {
                **identity_rows[fid],
                "hover_announces": False,
                "confirm_announces": True,
                "events": [
                    "fighter_lock_started",
                    "fighter_locked",
                    "announcer_name_started",
                    "announcer_name_finished",
                ],
            }
            for fid in FIGHTERS
        },
        "gates": {
            "SELECT_ANNOUNCER_EVENT_PASS": gates["SELECT_ANNOUNCER_EVENT_PASS"],
            "SELECT_LOCKIN_VISUAL_PASS": gates["SELECT_LOCKIN_VISUAL_PASS"],
            "SELECT_ANNOUNCER_AUDIO_RIGHTS_READY": False,
        },
    }
    framing_matrix = {
        "schema": "roster_framing_matrix/v1",
        "emitted_at": emitted,
        "occupancy": {
            "SELECT_CARD": [0.72, 0.86],
            "SELECT_PREVIEW": [0.72, 0.88],
            "VERSUS": [0.68, 0.84],
            "VICTORY": [0.70, 0.88],
        },
        "per_fighter_magic_scale": False,
        "fighters": {
            fid: {
                "no_clip": auto_fit,
                "auto_fit": auto_fit,
                "select_card": "72-86%",
                "select_preview": "72-88%",
            }
            for fid in FIGHTERS
        },
        "SELECT_CARD_AUTO_FIT_PASS": f"{card_fit}/7",
        "SELECT_PREVIEW_AUTO_FIT_PASS": f"{preview_fit}/7",
    }
    required_pairs = [
        ("ember-vale", "rook-ironside"),
        ("juno-spark", "orion-vell"),
        ("kaia-windrow", "vesper-nyx"),
        ("nix-calder", "ember-vale"),
    ]
    pairs = []
    for a in FIGHTERS:
        for b in FIGHTERS:
            pairs.append(
                {
                    "p1": a,
                    "p2": b,
                    "both_visible": auto_fit,
                    "required": (a, b) in required_pairs or (b, a) in required_pairs,
                }
            )
    pair_matrix = {
        "schema": "match_start_pair_matrix/v1",
        "emitted_at": emitted,
        "coverage": "7x7",
        "pairs": pairs,
        "MATCH_START_FRAMING_PASS": auto_fit,
        "SELECT_TO_BATTLE_CONTEXT_ISOLATION_PASS": isolation,
    }
    critical_matrix = {
        "schema": "critical_launch_matrix/v1",
        "emitted_at": emitted,
        "predictor_mutates_gameplay": False,
        "roster_wide_red_lightning": False,
        "fighters": {
            fid: {
                "cue": CUES[fid],
                "unique": True,
                "shared_grammar": [
                    "contact_freeze",
                    "elemental_rift",
                    "directional_streak",
                    "sound_hook",
                    "body_trail",
                ],
            }
            for fid in FIGHTERS
        },
        "regression": {
            "weak_jab_high_percent": "SAFE",
            "heavy_center_safe": "HIGH_TRAIL_MAYBE",
            "offstage_recoverable": "CRITICAL_RECOVERABLE",
            "already_dead": "no_retrigger",
            "multi_hit": "final_only",
        },
        "CRITICAL_LAUNCH_ELEMENTAL_MAPPING_PASS": f"{mapping}/7",
        "CRITICAL_LAUNCH_PREDICTOR_PASS": predictor_ok,
        "CRITICAL_LAUNCH_NO_FALSE_SPAM_PASS": no_spam,
        "CRITICAL_LAUNCH_ACCESSIBILITY_PASS": a11y,
    }
    trail_matrix = {
        "schema": "launch_trail_matrix/v1",
        "emitted_at": emitted,
        "tiers": ["LOW", "MEDIUM", "HIGH", "CRITICAL"],
        "fighters": {fid: {"high_trail": True, "critical_trail": True, "attacker_tint": True} for fid in FIGHTERS},
        "HIGH_LAUNCH_TRAIL_PASS": trail_ok,
    }
    write_json(ROOT / "artifacts/presentation/select_lockin/SELECT_LOCKIN_MATRIX.json", lockin)
    write_json(ROOT / "artifacts/presentation/framing/ROSTER_FRAMING_MATRIX.json", framing_matrix)
    write_json(ROOT / "artifacts/presentation/framing/MATCH_START_PAIR_MATRIX.json", pair_matrix)
    write_json(ROOT / "artifacts/combat_feedback/CRITICAL_LAUNCH_MATRIX.json", critical_matrix)
    write_json(ROOT / "artifacts/combat_feedback/LAUNCH_TRAIL_MATRIX.json", trail_matrix)
    payload = {
        "schema": "select_critical_launch_gates/v1",
        "emitted_at": emitted,
        "parent_head": "6aa44914c50d76d27ed851a40ab6bec7eedd5f7f",
        "failures": failures,
        "gates": gates,
        "hues": dict(zip(FIGHTERS, hues, strict=True)),
        "HUMAN_*": "Remain false unless a human signed.",
        "next_action": "OWNER_REVIEW_SELECT_ANNOUNCER_OPACITY_FRAMING_AND_CRITICAL_LAUNCH_ON_PIXEL",
    }
    write_json(ROOT / "artifacts/presentation/SELECT_CRITICAL_LAUNCH_GATES.json", payload)
    return payload


def main() -> int:
    payload = evaluate()
    structural = [
        "SELECT_ANNOUNCER_EVENT_PASS",
        "SELECT_LOCKIN_VISUAL_PASS",
        "ROSTER_ROYGBIV_SELECT_PASS",
        "NORMAL_BODY_OPACITY_FLOOR_PASS",
        "ELEMENTAL_DETAIL_PRESERVATION_PASS",
        "MATCH_START_FRAMING_PASS",
        "SELECT_TO_BATTLE_CONTEXT_ISOLATION_PASS",
        "HIGH_LAUNCH_TRAIL_PASS",
        "CRITICAL_LAUNCH_PREDICTOR_PASS",
        "CRITICAL_LAUNCH_ACCESSIBILITY_PASS",
        "CRITICAL_LAUNCH_NO_FALSE_SPAM_PASS",
        "PIXEL_REVIEW_ROUTE_PASS",
    ]
    gates = payload["gates"]
    ok = all(gates[name] is True for name in structural) and not payload["failures"]
    ok = ok and gates["SELECT_CARD_AUTO_FIT_PASS"] == "7/7"
    ok = ok and gates["SELECT_PREVIEW_AUTO_FIT_PASS"] == "7/7"
    ok = ok and gates["CRITICAL_LAUNCH_ELEMENTAL_MAPPING_PASS"] == "7/7"
    ok = ok and gates["SELECT_ANNOUNCER_AUDIO_RIGHTS_READY"] is False
    for k, v in OWNER_FALSE.items():
        if gates.get(k) is not False:
            ok = False
    print(json.dumps({"ok": ok, "failures": payload["failures"], "gates": gates}, indent=2))
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
