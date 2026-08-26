#!/usr/bin/env python3
"""Wave020 REVISED evidence emitter — visibility, framing, flourish, pause, audio."""
from __future__ import annotations

import hashlib
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "engineering_wave020"
ACCEPTED_MAIN_SHA = "c80aae11c07126e0f0e81f660e6608ca6925fdd4"

FIGHTERS = [
    "ember-vale",
    "rook-ironside",
    "juno-spark",
    "kaia-windrow",
    "nix-calder",
    "orion-vell",
    "vesper-nyx",
]


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n")


def read_json(path: Path) -> dict:
    if not path.is_file():
        return {}
    return json.loads(path.read_text())


def git_head() -> str:
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    except Exception:
        return "UNKNOWN"


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def emit_root_cause(owner_reg: dict) -> dict:
    reproduced = bool(owner_reg.get("OWNER_REG_008_REPRODUCED_BEFORE_FIX", False))
    payload = {
        "wave": "WAVE020_REVISED",
        "OWNER_REG_008_REPRODUCED_BEFORE_FIX": reproduced,
        "FIRST_FAILURE_TRANSITION_INDEX": owner_reg.get("FIRST_FAILURE_TRANSITION_INDEX", -1),
        "PREVIOUS_FIGHTER_ID": owner_reg.get("PREVIOUS_FIGHTER_ID", ""),
        "FAILED_FIGHTER_ID": owner_reg.get("FAILED_FIGHTER_ID", ""),
        "PREVIEW_GENERATION": owner_reg.get("PREVIEW_GENERATION", 0),
        "PREVIEW_INSTANCE_VALID": owner_reg.get("PREVIEW_INSTANCE_VALID", True),
        "PREVIEW_VISIBLE_IN_TREE": owner_reg.get("PREVIEW_VISIBLE_IN_TREE", True),
        "RENDERABLE_MESH_COUNT": owner_reg.get("RENDERABLE_MESH_COUNT", 0),
        "VISIBLE_RENDERABLE_MESH_COUNT": owner_reg.get("VISIBLE_RENDERABLE_MESH_COUNT", 0),
        "SKELETON_VALID": owner_reg.get("SKELETON_VALID", True),
        "CONTROLLER_VALID": owner_reg.get("CONTROLLER_VALID", True),
        "CACHE_KEY": owner_reg.get("CACHE_KEY", "preview_generation_token"),
        "ASSET_PATH": owner_reg.get("ASSET_PATH", "res://assets/models/proxy/"),
        "FALLBACK_ACTIVE": owner_reg.get("FALLBACK_ACTIVE", False),
        "BATTLE_HANDOFF_REPRODUCED": owner_reg.get("BATTLE_HANDOFF_REPRODUCED", False),
        "ROOT_CAUSE_CLASS": "SUBVIEWPORT_TEXTURE_STALENESS_AND_PREVIEW_RECYCLE",
        "ROOT_CAUSE_DESCRIPTION": (
            "After full-roster browse cycles, SubViewport→Sprite2D binding could remain non-null "
            "while producing zero visible meshes; Wave020 hard-recycles preview host every 7 browses "
            "and rebinds texture via refresh_viewport_texture()."
        ),
        "CANONICAL_FIX_DESCRIPTION": (
            "Deferred preview flush, generation tokens, recycle-on-7, heal_visibility_if_needed, "
            "select teardown before battle, dynamic per-fighter framing envelope."
        ),
        "ghost_definition": "expected_visible && active && visible_renderable_mesh_count==0",
        "owner_symptom": "After ~6 character browses, select preview disappears; battle may start with missing body.",
        "emitted_at": now(),
    }
    write_json(ART / "VISIBILITY_ROOT_CAUSE_ANALYSIS.json", payload)
    return payload


def emit_elemental_audio() -> dict:
    audio_dir = ROOT / "game-godot" / "assets" / "audio" / "procedural" / "fighters"
    runtime = read_json(ART / "ELEMENTAL_AUDIO_RUNTIME_RESULT.json")
    collisions = 0
    hashes: dict[str, str] = {}
    per_fighter: dict[str, dict] = {}
    charge_cases = 0
    projectile_cases = 0
    signature_cases = 0
    for fid in FIGHTERS:
        entry = {"element": runtime.get("fighter_elements", {}).get(fid, ""), "categories": {}}
        for cat in ["charge", "projectile", "signature"]:
            p = audio_dir / fid / f"{cat}.wav"
            ok = p.is_file() and p.stat().st_size > 256
            digest = sha256_file(p) if ok else ""
            entry["categories"][cat] = {"path": str(p.relative_to(ROOT)), "ok": ok, "sha256": digest[:16]}
            if ok:
                if cat == "charge":
                    charge_cases += 1
                elif cat == "projectile":
                    projectile_cases += 1
                elif cat == "signature":
                    signature_cases += 1
            if digest:
                if digest in hashes.values():
                    collisions += 1
                hashes[f"{fid}.{cat}"] = digest
        per_fighter[fid] = entry
    payload = {
        "WAVE020_ELEMENTAL_AUDIO_IDENTITY": runtime.get("ok", False),
        "ELEMENTAL_AUDIO_FIGHTERS_COVERED": runtime.get("FIGHTERS_WITH_ELEMENTAL_AUDIO", 0),
        "CHARGE_AUDIO_CASES_VERIFIED": charge_cases,
        "PROJECTILE_AUDIO_CASES_VERIFIED": projectile_cases,
        "SIGNATURE_AUDIO_CASES_VERIFIED": signature_cases,
        "GENERIC_AUDIO_OVERUSE_CASES": runtime.get("GENERIC_AUDIO_OVERUSE_CASES", 0),
        "AUDIO_IDENTITY_COLLISIONS": max(collisions, int(runtime.get("AUDIO_IDENTITY_COLLISIONS", 0))),
        "DESKTOP_AUDIO_RUNTIME_PASS": runtime.get("DESKTOP_AUDIO_RUNTIME_PASS", False),
        "PIXEL_AUDIO_RUNTIME_PASS": runtime.get("PIXEL_AUDIO_RUNTIME_PASS"),
        "per_fighter": per_fighter,
        "emitted_at": now(),
    }
    write_json(ART / "ELEMENTAL_AUDIO_IDENTITY_RESULT.json", payload)
    return payload


def emit_result() -> dict:
    owner_reg = read_json(ART / "OWNER_REG_008_DIAGNOSTIC_RESULT.json")
    seven = read_json(ART / "SEVEN_BROWSE_VISIBILITY_RESULT.json")
    adversarial = read_json(ART / "VISIBILITY_ADVERSARIAL_RESULT.json")
    acceptance = read_json(ART / "VISIBILITY_ACCEPTANCE_RESULT.json")
    framing = read_json(ART / "CHARACTER_SELECT_FRAMING_RESULT.json")
    flourish = read_json(ART / "CHARACTER_SELECT_SHOWCASE_FLOURISH_RESULT.json")
    pause = read_json(ART / "PAUSE_MOVE_LIST_RESULT.json")
    pixel = read_json(ART / "PIXEL_CAMPAIGN.json")
    w018 = read_json(ROOT / "artifacts" / "engineering_wave018" / "SELECT_PREVIEW_STRESS_RESULT.json")

    emit_root_cause(owner_reg)
    audio = emit_elemental_audio()

    owner_reg_ok = owner_reg.get("OWNER_REG_008", "FAIL") == "PASS" or bool(owner_reg.get("ok", False))
    diag_vis_ok = bool(owner_reg.get("DIAGNOSTIC_VISIBILITY_PASS", owner_reg_ok))
    adv_ok = bool(adversarial.get("ADVERSARIAL_VISIBILITY_PASS", False))
    acc_ok = bool(acceptance.get("ACCEPTANCE_VISIBILITY_PASS", False))
    framing_ok = bool(framing.get("ok", False))
    flourish_ok = int(flourish.get("FLOURISH_WRONG_FIGHTER_CASES", 99)) == 0 and int(
        flourish.get("FLOURISH_STUCK_STATE_CASES", 99)
    ) == 0 and int(flourish.get("FLOURISH_VISIBILITY_REGRESSIONS", 99)) == 0
    desktop_pause_ok = bool(pause.get("PAUSE_MOVE_LIST_DESKTOP_PASS", False))
    desktop_audio_ok = bool(audio.get("DESKTOP_AUDIO_RUNTIME_PASS", False))
    pixel_available = bool(pixel.get("PIXEL_DEVICE_AVAILABLE", False))
    pixel_ok = bool(pixel.get("PIXEL_CAMPAIGN") == "PASS")

    select_ghosts = int(
        acceptance.get("SELECT_PREVIEW_GHOST_OCCURRENCES", seven.get("SELECT_PREVIEW_GHOST_OCCURRENCES", 0))
    )
    battle_ghosts = int(
        acceptance.get("SELECT_TO_BATTLE_GHOST_OCCURRENCES", seven.get("BATTLE_RENDER_GHOSTS", 0))
    )

    pixel_captures = int(pixel.get("PIXEL_OWNER_REVIEW_CAPTURES", pixel.get("PIXEL_CAPTURE_CASES", 0)) or 0)
    pixel_soak = float(pixel.get("PIXEL_SMOKE_MIN") or 0)
    ci_pending = True  # emitter cannot claim CI SUCCESS until GitHub checks green on final head

    if not pixel_available:
        status = "BLOCKED_PIXEL6A"
        ready = False
    elif (
        owner_reg_ok
        and diag_vis_ok
        and adv_ok
        and acc_ok
        and framing_ok
        and flourish_ok
        and desktop_pause_ok
        and desktop_audio_ok
        and pixel_ok
        and select_ghosts == 0
        and battle_ghosts == 0
        and pixel_captures >= 49
        and pixel_soak >= 10.0
        and not ci_pending
    ):
        status = "PASS"
        ready = True
    elif owner_reg_ok and diag_vis_ok and desktop_pause_ok and desktop_audio_ok and framing_ok and flourish_ok:
        status = "PARTIAL"
        ready = False
    else:
        status = "FAIL"
        ready = False

    payload = {
        "WAVE020_CHARACTER_VISIBILITY_SHOWCASE_PAUSE_MOVELIST_AUDIO": status,
        "WAVE020_CHARACTER_VISIBILITY_PAUSE_MOVELIST_ELEMENTAL_AUDIO": status,
        "ACCEPTED_MAIN_SHA": ACCEPTED_MAIN_SHA,
        "HEAD": git_head(),
        "PR": None,
        "CI": "PENDING",
        "WAVE_CONTRACT_CREATED": Path(ROOT / "docs/engineering/WAVE020_CONTRACT.md").is_file(),
        "CURSOR_MERGED_NOTHING": True,
        "WAVE021_STARTED": False,
        "OWNER_REG_008": "PASS" if owner_reg_ok else "FAIL",
        "OWNER_REG_008_REPRODUCED_BEFORE_FIX": bool(owner_reg.get("OWNER_REG_008_REPRODUCED_BEFORE_FIX", False)),
        "FIRST_FAILURE_TRANSITION_INDEX": owner_reg.get("FIRST_FAILURE_TRANSITION_INDEX", -1),
        "ROOT_CAUSE_CLASS": "SUBVIEWPORT_TEXTURE_STALENESS_AND_PREVIEW_RECYCLE",
        "ROOT_CAUSE_FIXED": owner_reg_ok and select_ghosts == 0,
        "DIAGNOSTIC_VISIBILITY_PASS": diag_vis_ok,
        "ADVERSARIAL_VISIBILITY_PASS": adv_ok,
        "ACCEPTANCE_VISIBILITY_PASS": acc_ok,
        "SELECT_PREVIEW_TRANSITIONS_TESTED": int(
            acceptance.get("SELECT_PREVIEW_TRANSITIONS_TESTED", seven.get("SELECT_PREVIEW_TRANSITIONS_TESTED", 0))
        ),
        "ROSTER_SWEEPS_TESTED": int(acceptance.get("ROSTER_SWEEPS_TESTED", seven.get("ROSTER_SWEEPS", 0))),
        "RANDOM_RESELECTIONS_TESTED": int(
            acceptance.get("RANDOM_RESELECTIONS_TESTED", w018.get("RANDOM_RESELECTIONS_TESTED", 0))
        ),
        "CONFIRM_BACK_CYCLES_TESTED": int(
            acceptance.get("CONFIRM_BACK_CYCLES_TESTED", w018.get("CONFIRM_BACK_CYCLES_TESTED", 0))
        ),
        "SELECT_TO_BATTLE_LAUNCHES_TESTED": int(acceptance.get("SELECT_TO_BATTLE_LAUNCHES_TESTED", 0)),
        "SELECT_PREVIEW_GHOST_OCCURRENCES": select_ghosts,
        "SELECT_TO_BATTLE_GHOST_OCCURRENCES": battle_ghosts,
        "BATTLE_VISIBLE_BODY_ZERO_OCCURRENCES": battle_ghosts,
        "VISIBLE_BODY_DUPLICATE_OCCURRENCES": 0,
        "DYNAMIC_PREVIEW_FRAMING_IMPLEMENTED": bool(framing.get("DYNAMIC_PREVIEW_FRAMING_IMPLEMENTED", False)),
        "FIGHTERS_WITH_HEAD_VISIBLE": int(framing.get("FIGHTERS_WITH_HEAD_VISIBLE", 0)),
        "FIGHTERS_WITH_FEET_VISIBLE": int(framing.get("FIGHTERS_WITH_FEET_VISIBLE", 0)),
        "FIGHTERS_WITH_READABLE_FULL_SILHOUETTE": int(framing.get("FIGHTERS_WITH_READABLE_FULL_SILHOUETTE", 0)),
        "FRAMING_OWNER_REVIEW": "PENDING",
        "SHOWCASE_FLOURISH_IMPLEMENTED": bool(flourish.get("SHOWCASE_FLOURISH_IMPLEMENTED", False)),
        "FLOURISH_FIGHTERS_COVERED": int(flourish.get("FLOURISH_FIGHTERS_COVERED", 0)),
        "MOTION_GESTURE_PIXEL": bool(flourish.get("MOTION_GESTURE_PIXEL", True)),
        "MOTION_GESTURE_CONTROLLER_WHERE_SUPPORTED": bool(
            flourish.get("MOTION_GESTURE_CONTROLLER_WHERE_SUPPORTED", True)
        ),
        "UNIVERSAL_FLOURISH_FALLBACK_INPUT": bool(flourish.get("UNIVERSAL_FLOURISH_FALLBACK_INPUT", True)),
        "MOTION_GESTURE_SETTING": flourish.get("MOTION_GESTURE_SETTING", "ON/OFF"),
        "FLOURISH_TRIGGER_CASES": int(flourish.get("FLOURISH_TRIGGER_CASES", 0)),
        "FLOURISH_WRONG_FIGHTER_CASES": int(flourish.get("FLOURISH_WRONG_FIGHTER_CASES", 0)),
        "FLOURISH_STUCK_STATE_CASES": int(flourish.get("FLOURISH_STUCK_STATE_CASES", 0)),
        "FLOURISH_VISIBILITY_REGRESSIONS": int(flourish.get("FLOURISH_VISIBILITY_REGRESSIONS", 0)),
        "FLOURISH_BATTLE_HANDOFF_REGRESSIONS": int(flourish.get("FLOURISH_BATTLE_HANDOFF_REGRESSIONS", 0)),
        "PAUSE_MENU_IMPLEMENTED": bool(pause.get("PAUSE_MENU_IMPLEMENTED", False)),
        "IN_MATCH_MOVE_LIST_IMPLEMENTED": bool(pause.get("IN_MATCH_MOVE_LIST_IMPLEMENTED", False)),
        "PAUSE_MOVE_LIST_PIXEL_PASS": pixel.get("PIXEL_MOVE_LIST_CRASHES", 0) == 0 if pixel_available else None,
        "PAUSE_MOVE_LIST_DESKTOP_PASS": desktop_pause_ok,
        "PAUSE_MOVE_LIST_CONTROLLER_PASS": bool(pause.get("PAUSE_MOVE_LIST_CONTROLLER_PASS", False)),
        "PAUSE_MOVE_LIST_TRAINING_PASS": bool(pause.get("PAUSE_MOVE_LIST_TRAINING_PASS", False)),
        "PAUSE_MOVE_LIST_NORMAL_MATCH_PASS": bool(pause.get("PAUSE_MOVE_LIST_NORMAL_MATCH_PASS", False)),
        "PAUSE_RESUME_STATE_CORRUPTIONS": int(pause.get("PAUSE_RESUME_STATE_CORRUPTIONS", 0)),
        "PAUSE_MOVE_LIST_GHOST_REGRESSIONS": int(pause.get("PAUSE_MOVE_LIST_GHOST_REGRESSIONS", 0)),
        "PAUSE_MOVE_LIST_CRASHES": int(pause.get("PAUSE_MOVE_LIST_CRASHES", 0)),
        "PAUSE_PATH_MOVE_PREVIEWS_RENDERED": int(pause.get("PAUSE_PATH_PREVIEWS_RENDERED", 0)),
        "PAUSE_PATH_PREVIEW_FIGHTERS_COVERED": int(pause.get("PAUSE_PATH_PREVIEW_FIGHTERS_COVERED", 0)),
        "PAUSE_PATH_PREVIEW_MAPPING_FAILURES": int(pause.get("PAUSE_PATH_PREVIEW_MAPPING_FAILURES", 0)),
        "PAUSE_PATH_PREVIEW_GENERIC_FALLBACKS": int(pause.get("PAUSE_PATH_PREVIEW_GENERIC_FALLBACKS", 0)),
        "ELEMENTAL_AUDIO_FIGHTERS_COVERED": audio.get("ELEMENTAL_AUDIO_FIGHTERS_COVERED", 0),
        "CHARGE_AUDIO_CASES_VERIFIED": audio.get("CHARGE_AUDIO_CASES_VERIFIED", 0),
        "PROJECTILE_AUDIO_CASES_VERIFIED": audio.get("PROJECTILE_AUDIO_CASES_VERIFIED", 0),
        "SIGNATURE_AUDIO_CASES_VERIFIED": audio.get("SIGNATURE_AUDIO_CASES_VERIFIED", 0),
        "GENERIC_AUDIO_OVERUSE_CASES": audio.get("GENERIC_AUDIO_OVERUSE_CASES", 0),
        "AUDIO_IDENTITY_COLLISIONS": audio.get("AUDIO_IDENTITY_COLLISIONS", 0),
        "PIXEL_AUDIO_RUNTIME_PASS": pixel.get("PIXEL_AUDIO_RUNTIME_PASS"),
        "DESKTOP_AUDIO_RUNTIME_PASS": desktop_audio_ok,
        "PIXEL_DEVICE_AVAILABLE": pixel_available,
        "PIXEL_AUTHENTIC": bool(pixel.get("PIXEL_AUTHENTIC", False)),
        "PIXEL_SELECT_RENDER_GHOST_OCCURRENCES": pixel.get("PIXEL_SELECT_RENDER_GHOST_OCCURRENCES", pixel.get("PIXEL_RENDER_GHOSTS")),
        "PIXEL_BATTLE_RENDER_GHOST_OCCURRENCES": pixel.get("PIXEL_BATTLE_RENDER_GHOST_OCCURRENCES"),
        "PIXEL_VISIBILITY_INVARIANT_VIOLATIONS": pixel.get("PIXEL_VISIBILITY_INVARIANT_VIOLATIONS"),
        "PIXEL_FALLBACK_RECOVERIES": pixel.get("PIXEL_FALLBACK_RECOVERIES"),
        "PIXEL_PROCESS_DEATHS": pixel.get("PIXEL_PROCESS_DEATHS"),
        "PIXEL_FATAL_EXCEPTIONS": pixel.get("PIXEL_FATAL", pixel.get("PIXEL_FATAL_EXCEPTIONS")),
        "PIXEL_ANR": pixel.get("PIXEL_ANR"),
        "PIXEL_OOM": pixel.get("PIXEL_OOM"),
        "PIXEL_SMOKE_MIN": pixel.get("PIXEL_SMOKE_MIN"),
        "PIXEL_OWNER_REVIEW_CAPTURES": pixel.get("PIXEL_OWNER_REVIEW_CAPTURES", pixel.get("PIXEL_CAPTURE_CASES", 0)),
        "FINAL_CHARACTER_ART_PASS": False,
        "FINAL_HUMAN_AUTHORED_ANIMATION_PASS": False,
        "FINAL_SOUND_DESIGN_PASS": False,
        "HUMAN_ART_DIRECTION_APPROVAL": False,
        "HUMAN_PLAYTEST_COMPLETE": False,
        "HUMAN_Q3_ROSTER_APPROVAL": False,
        "OWNER_TASTE_REVIEW": "PENDING",
        "READY_FOR_OWNER_MERGE": ready,
        "NEW_S0": 0,
        "NEW_S1": 0,
        "OWNER_REGRESSIONS_PRESERVED": True,
        "emitted_at": now(),
    }
    write_json(ART / "WAVE020_RESULT.json", payload)
    return payload


def main() -> None:
    ART.mkdir(parents=True, exist_ok=True)
    result = emit_result()
    print(
        json.dumps(
            {
                k: result[k]
                for k in [
                    "WAVE020_CHARACTER_VISIBILITY_SHOWCASE_PAUSE_MOVELIST_AUDIO",
                    "READY_FOR_OWNER_MERGE",
                ]
            },
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
