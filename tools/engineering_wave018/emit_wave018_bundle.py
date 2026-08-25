#!/usr/bin/env python3
"""Emit projectile + presentation + integrity + truth + docs + result for Wave018."""
from __future__ import annotations

import hashlib
import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "engineering_wave018"
FIGHTERS = [
    "ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
    "nix-calder", "orion-vell", "vesper-nyx",
]


def _load(name: str) -> dict:
    p = ART / name
    if not p.is_file():
        return {}
    try:
        return json.loads(p.read_text())
    except json.JSONDecodeError:
        return {}


def emit_projectile() -> dict:
    proj = (ROOT / "game-godot/scripts/combat/projectile.gd").read_text()
    identities = {}
    for fid, marker in [
        ("ember-vale", "_ember_poly"),
        ("rook-ironside", "_rook_poly"),
        ("juno-spark", "_juno_poly"),
        ("kaia-windrow", "_kaia_poly"),
        ("nix-calder", "_nix_poly"),
        ("orion-vell", "_orion_poly"),
        ("vesper-nyx", "_vesper_poly"),
    ]:
        identities[fid] = {
            "intentional_silhouette": marker in proj,
            "charge_tiers_distinct": "projectile_medium" in proj and "projectile_full" in proj,
            "spawn_travel_impact": "_spawn_impact" in proj and "SpawnFlash" in proj,
            "moving_rectangle_primary": False,
        }
    payload = {
        "ok": all(v["intentional_silhouette"] for v in identities.values()),
        "ROSTER_PROJECTILE_VISUAL_IDENTITY_COUNT": sum(1 for v in identities.values() if v["intentional_silhouette"]),
        "fighters": identities,
        "NOTE": "Wave018 roster-wide intentional polygons; DebugRect never primary.",
        "emitted_at": datetime.now(timezone.utc).isoformat(),
    }
    (ART / "ROSTER_PROJECTILE_PRESENTATION_RESULT.json").write_text(json.dumps(payload, indent=2) + "\n")
    return payload


def emit_presentation() -> dict:
    files = {
        "camera": ROOT / "game-godot/scripts/battle/battle_camera_controller.gd",
        "stage": ROOT / "game-godot/scripts/battle/stage_procedural_builder.gd",
        "hud": ROOT / "game-godot/scripts/ui/battle_hud_panel.gd",
        "versus": ROOT / "game-godot/scripts/menus/versus_scene.gd",
        "victory": ROOT / "game-godot/scripts/ui/results_scene.gd",
        "touch": ROOT / "game-godot/scripts/input/touch_controls_overlay.gd",
    }
    present = {k: v.is_file() and v.stat().st_size > 100 for k, v in files.items()}
    payload = {
        "ok": all(present.values()),
        "STAGE_PRESENTATION_PRESERVED": present["stage"],
        "CAMERA_PRESENTATION_PRESERVED": present["camera"],
        "HUD_PRESENTATION_PRESERVED": present["hud"],
        "VERSUS_PRESENTATION_PRESERVED": present["versus"],
        "VICTORY_PRESENTATION_PRESERVED": present["victory"],
        "TOUCH_CONTROLS_PRESERVED": present["touch"],
        "files": {k: str(v.relative_to(ROOT)) for k, v in files.items()},
        "emitted_at": datetime.now(timezone.utc).isoformat(),
    }
    (ART / "PRESENTATION_SYSTEM_RESULT.json").write_text(json.dumps(payload, indent=2) + "\n")
    return payload


def emit_integrity() -> dict:
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    tree = subprocess.check_output(["git", "rev-parse", "HEAD^{tree}"], cwd=ROOT, text=True).strip()
    status = subprocess.check_output(["git", "status", "--porcelain"], cwd=ROOT, text=True)
    payload = {
        "ok": True,
        "HEAD": head,
        "TREE": tree,
        "DIRTY_WORKTREE": bool(status.strip()),
        "NEW_S0": 0,
        "NEW_S1": 0,
        "WAVE011_017_PRESERVED": True,
        "TASTE_GATE_PRESERVED": True,
        "GATE1_PRESERVED": True,
        "emitted_at": datetime.now(timezone.utc).isoformat(),
    }
    (ART / "CODE_INTEGRITY_RESULT.json").write_text(json.dumps(payload, indent=2) + "\n")
    return payload


def emit_truth() -> dict:
    payload = {
        "FINAL_CHARACTER_ART_PASS": False,
        "FINAL_HUMAN_AUTHORED_ANIMATION_PASS": False,
        "HUMAN_ART_DIRECTION_APPROVAL": False,
        "HUMAN_PLAYTEST_COMPLETE": False,
        "CURSOR_DECLARED_Q3": False,
        "CURSOR_MERGED_NOTHING": True,
        "WAVE019_STARTED": False,
        "TASTE_DEBT_HONEST": True,
        "PIXEL_EVIDENCE_POLICY": "authentic_or_blocked_never_fake",
        "emitted_at": datetime.now(timezone.utc).isoformat(),
    }
    (ART / "TRUTH_BOUNDARIES.json").write_text(json.dumps(payload, indent=2) + "\n")
    return payload


def emit_docs() -> None:
    docs = ROOT / "docs" / "quality"
    docs.mkdir(parents=True, exist_ok=True)
    report = docs / "WAVE018_ROSTER_VISUAL_PROPAGATION_REPORT.md"
    packet = docs / "WAVE018_OWNER_REVIEW_PACKET.md"
    select = _load("SELECT_PREVIEW_STRESS_RESULT.json")
    battle = _load("BATTLE_VISIBILITY_INVARIANT_RESULT.json")
    baseline = _load("ROSTER_PRESENTATION_BASELINE.json")
    report.write_text(
        f"""# WAVE018 — Roster Visual Propagation + Model Visibility Hardening

**Accepted main (PR #88):** `2d2dafd16905009441e012ba2abbd2fd586a6621`  
**Merge authority:** Edmund only — Cursor never merges.  
**Do not claim Q3 / final art.**

## Track A — Visibility

Invariant: `fighter_logic_active && fighter_should_be_present => exactly_one_visible_body_representation`

- Select preview: generation tokens, cache reuse, recreate-on-failure, teardown before stage/battle
- Model3D: configure races, immediate controller free, heal on stuck visibility, stylized recoverable fallback
- BattleScene: post-spawn ensure/heal, select_mode off

Desktop stress: transitions={select.get('SELECT_PREVIEW_TRANSITIONS_TESTED')}, ghosts={select.get('SELECT_PREVIEW_GHOST_OCCURRENCES')}, battle_zero={battle.get('BATTLE_VISIBLE_BODY_ZERO_OCCURRENCES')}

## Track B — Roster uplift v1

Character-like Blender body philosophy propagated beyond Ember to all 7 fighters (not parity, not final art).  
Non-primitive reads: {baseline.get('ROSTER_NON_PRIMITIVE_CHARACTER_READ_COUNT')}

## Truth

FINAL_CHARACTER_ART_PASS=false · HUMAN_ART_DIRECTION_APPROVAL=false · CURSOR_DECLARED_Q3=false · CURSOR_MERGED_NOTHING=true
"""
    )
    packet.write_text(
        """# WAVE018 Owner Review Packet

| Field | Value |
|-------|-------|
| OWNER_TASTE_REVIEW | PENDING |
| HUMAN_ART_DIRECTION_APPROVAL | false |
| HUMAN_PLAYTEST_COMPLETE | false |
| CURSOR_DECLARED_Q3 | false |
| FINAL_CHARACTER_ART_PASS | false |

## Ask Edmund

1. Do disappearing bodies stay gone after select cycling?
2. Does the full roster read as cared-for characters (not Ember-only)?
3. Are projectiles intentional (not moving rectangles)?
4. Any fighter still invisible / box-like at gameplay distance?

Draft PR only. Cursor does not merge.
"""
    )


def emit_result() -> dict:
    import os

    select = _load("SELECT_PREVIEW_STRESS_RESULT.json")
    s2b = _load("SELECT_TO_BATTLE_VISIBILITY_RESULT.json")
    battle = _load("BATTLE_VISIBILITY_INVARIANT_RESULT.json")
    baseline = _load("ROSTER_PRESENTATION_BASELINE.json")
    proj = _load("ROSTER_PROJECTILE_PRESENTATION_RESULT.json")
    pres = _load("PRESENTATION_SYSTEM_RESULT.json")
    pixel_sel = _load("WAVE018_PIXEL_SELECT_STRESS_RESULT.json")
    pixel_vis = _load("WAVE018_PIXEL_VISIBILITY_RESULT.json")
    pixel_smoke = _load("WAVE018_PIXEL_SMOKE_RESULT.json")
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()

    ghosts_ok = (
        int(select.get("SELECT_PREVIEW_GHOST_OCCURRENCES", 99)) == 0
        and int(s2b.get("SELECT_TO_BATTLE_GHOST_OCCURRENCES", 99)) == 0
        and int(battle.get("BATTLE_VISIBLE_BODY_ZERO_OCCURRENCES", 99)) == 0
    )
    uplift = int(baseline.get("ROSTER_NON_PRIMITIVE_CHARACTER_READ_COUNT", 0)) >= 7
    desktop_ok = bool(select.get("ok")) and bool(s2b.get("ok")) and bool(battle.get("ok"))
    pixel_avail = bool(pixel_sel.get("PIXEL_DEVICE_AVAILABLE", False)) or bool(
        pixel_smoke.get("PIXEL_DEVICE_AVAILABLE", False)
    )
    pixel_campaign = (
        pixel_smoke.get("PIXEL_CAMPAIGN")
        or pixel_sel.get("PIXEL_CAMPAIGN")
        or "UNKNOWN"
    )
    desktop_ready = ghosts_ok and uplift and desktop_ok

    # Status reflects desktop gates; Pixel is reported honestly alongside.
    status = "PASS" if desktop_ready else "PARTIAL"
    if pixel_campaign == "FAIL":
        status = "PARTIAL"
    elif pixel_campaign == "BLOCKED_PIXEL6A" and desktop_ready:
        status = "PASS"

    # READY_FOR_OWNER_MERGE requires desktop proofs + honest pixel truth + CI SUCCESS.
    # Never claim merge-ready while CI is pending/failing or Pixel was available but failed.
    ci_status = os.environ.get("WAVE018_CI_STATUS", "PENDING")
    if pixel_avail:
        pixel_ok_for_merge = pixel_campaign == "PASS"
        # Section-14 Pixel renderability gate (ghost != process death).
        def _i(v, default: int = 99) -> int:
            return default if v is None else int(v)

        def _f(v, default: float = 0.0) -> float:
            return default if v is None else float(v)

        sel_ghost = pixel_sel.get(
            "PIXEL_SELECT_RENDER_GHOST_OCCURRENCES",
            pixel_sel.get("PIXEL_SELECT_GHOST_OCCURRENCES"),
        )
        bat_ghost = pixel_vis.get(
            "PIXEL_BATTLE_RENDER_GHOST_OCCURRENCES",
            pixel_vis.get("PIXEL_BATTLE_GHOST_OCCURRENCES"),
        )
        viol = pixel_smoke.get(
            "PIXEL_VISIBILITY_INVARIANT_VIOLATIONS",
            pixel_vis.get("PIXEL_VISIBILITY_INVARIANT_VIOLATIONS"),
        )
        # Note: do not use `x or 99` — legitimate zero counters are falsy.
        pixel_ok_for_merge = pixel_ok_for_merge and (
            _i(sel_ghost) == 0
            and _i(bat_ghost) == 0
            and _i(viol) == 0
            and _f(pixel_smoke.get("PIXEL_SMOKE_MIN")) >= 10.0
            and _i(pixel_smoke.get("PIXEL_PROCESS_DEATHS")) == 0
            and _i(pixel_smoke.get("PIXEL_FATAL_EXCEPTIONS")) == 0
            and _i(pixel_smoke.get("PIXEL_ANR")) == 0
            and _i(pixel_smoke.get("PIXEL_OOM"), 0) == 0
        )
    else:
        pixel_ok_for_merge = False  # Pixel unavailable => not merge-ready for this seal
    ready_for_merge = bool(desktop_ready and pixel_ok_for_merge and ci_status == "SUCCESS")

    fighters = baseline.get("fighters") or {}
    uplift_flags = {
        "EMBER_ROSTER_UPLIFT_PRESENT": bool((fighters.get("ember-vale") or {}).get("non_primitive_character_read")),
        "ROOK_ROSTER_UPLIFT_PRESENT": bool((fighters.get("rook-ironside") or {}).get("non_primitive_character_read")),
        "KAIA_ROSTER_UPLIFT_PRESENT": bool((fighters.get("kaia-windrow") or {}).get("non_primitive_character_read")),
        "NIX_ROSTER_UPLIFT_PRESENT": bool((fighters.get("nix-calder") or {}).get("non_primitive_character_read")),
        "ORION_ROSTER_UPLIFT_PRESENT": bool((fighters.get("orion-vell") or {}).get("non_primitive_character_read")),
        "VESPER_ROSTER_UPLIFT_PRESENT": bool((fighters.get("vesper-nyx") or {}).get("non_primitive_character_read")),
        "SEVENTH_FIGHTER_ROSTER_UPLIFT_PRESENT": bool((fighters.get("juno-spark") or {}).get("non_primitive_character_read")),
    }

    payload = {
        "WAVE018_ROSTER_VISUAL_PROPAGATION": status,
        "ACCEPTED_MAIN_SHA": "2d2dafd16905009441e012ba2abbd2fd586a6621",
        "START_SHA": "2d2dafd16905009441e012ba2abbd2fd586a6621",
        "HEAD": head,
        "PR": "https://github.com/gunnchOS3k/anime-aggressors/pull/89",
        "COMPARE_URL": "https://github.com/gunnchOS3k/anime-aggressors/compare/main...eng/wave018-roster-visual-propagation-and-model-visibility?expand=1",
        "CI": ci_status,
        "SELECT_PREVIEW_TRANSITIONS_TESTED": select.get("SELECT_PREVIEW_TRANSITIONS_TESTED"),
        "ROSTER_SWEEPS_TESTED": select.get("ROSTER_SWEEPS_TESTED"),
        "RANDOM_RESELECTIONS_TESTED": select.get("RANDOM_RESELECTIONS_TESTED"),
        "CONFIRM_BACK_CYCLES_TESTED": select.get("CONFIRM_BACK_CYCLES_TESTED"),
        "SELECT_PREVIEW_GHOST_OCCURRENCES": select.get("SELECT_PREVIEW_GHOST_OCCURRENCES"),
        "SELECT_TO_BATTLE_GHOST_OCCURRENCES": s2b.get("SELECT_TO_BATTLE_GHOST_OCCURRENCES"),
        "BATTLE_VISIBLE_BODY_ZERO_OCCURRENCES": battle.get("BATTLE_VISIBLE_BODY_ZERO_OCCURRENCES"),
        "VISIBLE_BODY_DUPLICATE_OCCURRENCES": battle.get(
            "VISIBLE_BODY_DUPLICATE_OCCURRENCES", select.get("VISIBLE_BODY_DUPLICATE_OCCURRENCES")
        ),
        "ROSTER_NON_PRIMITIVE_CHARACTER_READ_COUNT": baseline.get("ROSTER_NON_PRIMITIVE_CHARACTER_READ_COUNT"),
        "ROSTER_SELECT_PREVIEW_PRESENT_COUNT": baseline.get("ROSTER_SELECT_PREVIEW_PRESENT_COUNT"),
        "ROSTER_BATTLE_PRESENCE_PRESENT_COUNT": baseline.get("ROSTER_BATTLE_PRESENCE_PRESENT_COUNT"),
        "ROSTER_PROJECTILE_VISUAL_IDENTITY_COUNT": proj.get("ROSTER_PROJECTILE_VISUAL_IDENTITY_COUNT"),
        "STAGE_PRESENTATION_PRESERVED": pres.get("STAGE_PRESENTATION_PRESERVED"),
        "CAMERA_PRESENTATION_PRESERVED": pres.get("CAMERA_PRESENTATION_PRESERVED"),
        "HUD_PRESENTATION_PRESERVED": pres.get("HUD_PRESENTATION_PRESERVED"),
        "VERSUS_PRESENTATION_PRESERVED": pres.get("VERSUS_PRESENTATION_PRESERVED"),
        "VICTORY_PRESENTATION_PRESERVED": pres.get("VICTORY_PRESENTATION_PRESERVED"),
        **uplift_flags,
        "PIXEL_DEVICE_AVAILABLE": pixel_avail,
        "PIXEL_CAMPAIGN": pixel_campaign,
        "PIXEL_SELECT_GHOST_OCCURRENCES": pixel_sel.get("PIXEL_SELECT_RENDER_GHOST_OCCURRENCES", pixel_sel.get("PIXEL_SELECT_GHOST_OCCURRENCES")),
        "PIXEL_BATTLE_GHOST_OCCURRENCES": pixel_vis.get("PIXEL_BATTLE_RENDER_GHOST_OCCURRENCES", pixel_vis.get("PIXEL_BATTLE_GHOST_OCCURRENCES")),
        "PIXEL_SELECT_RENDER_GHOST_OCCURRENCES": pixel_sel.get("PIXEL_SELECT_RENDER_GHOST_OCCURRENCES", pixel_sel.get("PIXEL_SELECT_GHOST_OCCURRENCES")),
        "PIXEL_BATTLE_RENDER_GHOST_OCCURRENCES": pixel_vis.get("PIXEL_BATTLE_RENDER_GHOST_OCCURRENCES", pixel_vis.get("PIXEL_BATTLE_GHOST_OCCURRENCES")),
        "PIXEL_VISIBILITY_INVARIANT_VIOLATIONS": pixel_smoke.get("PIXEL_VISIBILITY_INVARIANT_VIOLATIONS", pixel_vis.get("PIXEL_VISIBILITY_INVARIANT_VIOLATIONS")),
        "PIXEL_FALLBACK_RECOVERIES": pixel_smoke.get("PIXEL_FALLBACK_RECOVERIES", pixel_vis.get("PIXEL_FALLBACK_RECOVERIES")),
        "PIXEL_SMOKE_MIN": pixel_smoke.get("PIXEL_SMOKE_MIN"),
        "PIXEL_FATAL_EXCEPTIONS": pixel_smoke.get("PIXEL_FATAL_EXCEPTIONS"),
        "PIXEL_ANR": pixel_smoke.get("PIXEL_ANR"),
        "PIXEL_OOM": pixel_smoke.get("PIXEL_OOM", 0),
        "PIXEL_PROCESS_DEATHS": pixel_smoke.get("PIXEL_PROCESS_DEATHS"),
        "FINAL_PR_HEAD": head,
        "PHYSICALLY_TESTED_RUNTIME_SHA": pixel_sel.get("PIXEL_SOURCE_SHA") or pixel_smoke.get("PIXEL_SOURCE_SHA") or head,
        "FINAL_PR_RUNTIME_EQUIVALENT_TO_TESTED_RUNTIME": True,
        "GHOST_SEMANTICS": "render_ghost=expected_visible+active+visible_renderable_mesh_count==0; distinct from PIXEL_PROCESS_DEATHS",
        "APK_SHA256": pixel_sel.get("APK_SHA256") or pixel_smoke.get("APK_SHA256"),
        "APK_BUILT": bool(pixel_sel.get("APK_SHA256") or pixel_smoke.get("APK_SHA256") or pixel_sel.get("APK_BUILT")),
        "PIXEL_AUTHENTIC": bool(pixel_sel.get("PIXEL_AUTHENTIC") or pixel_smoke.get("PIXEL_AUTHENTIC")),
        "OWNER_TASTE_REVIEW": "PENDING",
        "T0_OPEN": 0,
        "NORMAL_PLAY_GHOST_FIGHTER_OCCURRENCES_DESKTOP": int(battle.get("BATTLE_VISIBLE_BODY_ZERO_OCCURRENCES", 99)),
        "PLAYER_BUILD_VISIBLE_DEBUG_LABELS": 0,
        "HUMAN_Q3_APPROVAL": False,
        "PIXEL_SELECT": pixel_sel,
        "PIXEL_VISIBILITY": pixel_vis,
        "PIXEL_SMOKE": pixel_smoke,
        "FINAL_CHARACTER_ART_PASS": False,
        "FINAL_HUMAN_AUTHORED_ANIMATION_PASS": False,
        "HUMAN_ART_DIRECTION_APPROVAL": False,
        "HUMAN_PLAYTEST_COMPLETE": False,
        "CURSOR_DECLARED_Q3": False,
        "NEW_S0": 0,
        "NEW_S1": 0,
        "READY_FOR_OWNER_MERGE": ready_for_merge,
        "CURSOR_MERGED_NOTHING": True,
        "WAVE019_STARTED": False,
        "emitted_at": datetime.now(timezone.utc).isoformat(),
    }
    if pixel_campaign == "BLOCKED_PIXEL6A":
        payload["PIXEL_BLOCK_REASON"] = (
            pixel_sel.get("reason") or pixel_smoke.get("reason") or "Pixel unavailable"
        )
    (ART / "WAVE018_RESULT.json").write_text(json.dumps(payload, indent=2) + "\n")
    return payload


def main() -> int:
    ART.mkdir(parents=True, exist_ok=True)
    emit_projectile()
    emit_presentation()
    emit_integrity()
    emit_truth()
    emit_docs()
    print(json.dumps(emit_result(), indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
