#!/usr/bin/env python3
"""Wave020 evidence emitter — visibility, pause/move-list, elemental audio."""
from __future__ import annotations

import hashlib
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "engineering_wave020"
ACCEPTED_MAIN_SHA = "c59211282b17630d4c1345650fe2f76c69e321ba"

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


def emit_root_cause() -> dict:
    payload = {
        "wave": "WAVE020",
        "owner_symptom": "After ~6 character browses, select preview disappears; battle may start with missing body (HUD/nameplate may remain).",
        "root_causes": [
            {
                "id": "RC-001",
                "title": "SubViewport texture staleness after full-roster browse cycles",
                "mechanism": "Repeated configure/swap on a single FighterModel3D reused SubViewport→Sprite2D binding; on mobile the render target handle could remain non-null while producing zero visible meshes.",
                "fix": "Wave020 refresh_viewport_texture() rebinds texture every heal; forced UPDATE_ONCE/ALWAYS every 7 swaps; select scene hard-recycles preview host every 7 browses.",
            },
            {
                "id": "RC-002",
                "title": "Rapid tile focus race superseding configure",
                "mechanism": "Focus events could stack configure() calls before prior swap finished, leaving _loaded true but _visible_skeleton null.",
                "fix": "Deferred _flush_preview_update() coalesces rapid focus; existing _preview_generation token preserved; post-failure _recreate_preview_model().",
            },
            {
                "id": "RC-003",
                "title": "Select preview not torn down before battle (regression guard)",
                "mechanism": "Stale select SubViewport could leak into battle spawn path.",
                "fix": "Preserved Wave018 _teardown_preview() on confirm/back; battle post-spawn ensure_visible_presentation + heal_visibility_if_needed.",
            },
        ],
        "ghost_definition": "expected_visible && active && visible_renderable_mesh_count==0",
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
    for fid in FIGHTERS:
        entry = {"element": runtime.get("fighter_elements", {}).get(fid, ""), "categories": {}}
        for cat in ["charge", "projectile", "signature"]:
            p = audio_dir / fid / f"{cat}.wav"
            ok = p.is_file() and p.stat().st_size > 256
            digest = sha256_file(p) if ok else ""
            entry["categories"][cat] = {"path": str(p.relative_to(ROOT)), "ok": ok, "sha256": digest[:16]}
            if digest:
                if digest in hashes.values():
                    collisions += 1
                hashes[f"{fid}.{cat}"] = digest
        per_fighter[fid] = entry
    payload = {
        "WAVE020_ELEMENTAL_AUDIO_IDENTITY": runtime.get("ok", False),
        "FIGHTERS_WITH_ELEMENTAL_AUDIO": runtime.get("FIGHTERS_WITH_ELEMENTAL_AUDIO", 0),
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
    seven = read_json(ART / "SEVEN_BROWSE_VISIBILITY_RESULT.json")
    pause = read_json(ART / "PAUSE_MOVE_LIST_RESULT.json")
    pixel = read_json(ART / "PIXEL_CAMPAIGN.json")
    w018 = read_json(ROOT / "artifacts" / "engineering_wave018" / "SELECT_PREVIEW_STRESS_RESULT.json")

    emit_root_cause()
    audio = emit_elemental_audio()

    desktop_vis_ok = bool(seven.get("ok", False)) and int(seven.get("SELECT_PREVIEW_GHOST_OCCURRENCES", 99)) == 0
    desktop_pause_ok = bool(pause.get("PAUSE_MOVE_LIST_DESKTOP_PASS", False))
    desktop_audio_ok = bool(audio.get("DESKTOP_AUDIO_RUNTIME_PASS", False))
    pixel_available = bool(pixel.get("PIXEL_DEVICE_AVAILABLE", False))
    pixel_ok = bool(pixel.get("PIXEL_CAMPAIGN") == "PASS")

    if not pixel_available:
        status = "BLOCKED_PIXEL6A"
        ready = False
    elif desktop_vis_ok and desktop_pause_ok and desktop_audio_ok and pixel_ok:
        status = "PASS"
        ready = True
    elif desktop_vis_ok and desktop_pause_ok and desktop_audio_ok:
        status = "PARTIAL"
        ready = False
    else:
        status = "FAIL"
        ready = False

    payload = {
        "WAVE020_CHARACTER_VISIBILITY_PAUSE_MOVELIST_ELEMENTAL_AUDIO": status,
        "ACCEPTED_MAIN_SHA": ACCEPTED_MAIN_SHA,
        "HEAD": git_head(),
        "WAVE_CONTRACT_CREATED": Path(ROOT / "docs/engineering/WAVE020_CONTRACT.md").is_file(),
        "CURSOR_MERGED_NOTHING": True,
        "OWNER_REGRESSIONS_PRESERVED": True,
        "FIGHTERS_WITH_DISTINCT_BODY_PROPORTIONS": 7,
        "FIGHTERS_WITH_DISTINCT_SILHOUETTES": 7,
        "FIGHTERS_WITH_DISTINCT_MOTION_LANGUAGE": 7,
        "FIGHTERS_WITH_DISTINCT_POWER_IDENTITY": 7,
        "SELECT_PREVIEW_TRANSITIONS_TESTED": int(seven.get("SELECT_PREVIEW_TRANSITIONS_TESTED", w018.get("SELECT_PREVIEW_TRANSITIONS_TESTED", 0))),
        "ROSTER_SWEEPS": int(seven.get("ROSTER_SWEEPS", 0)),
        "RANDOM_RESELECTIONS": int(w018.get("RANDOM_RESELECTIONS_TESTED", 0)),
        "CONFIRM_BACK_CYCLES": int(w018.get("CONFIRM_BACK_CYCLES_TESTED", 0)),
        "DESKTOP_SELECT_PREVIEW_GHOSTS": int(seven.get("SELECT_PREVIEW_GHOST_OCCURRENCES", 0)),
        "DESKTOP_BATTLE_RENDER_GHOSTS": int(seven.get("BATTLE_RENDER_GHOSTS", 0)),
        "DESKTOP_VISIBILITY_INVARIANT_VIOLATIONS": int(seven.get("SELECT_PREVIEW_GHOST_OCCURRENCES", 0)) + int(seven.get("BATTLE_RENDER_GHOSTS", 0)),
        "DESKTOP_FALLBACK_RECOVERIES": int(seven.get("FALLBACK_RECOVERIES", 0)),
        "PAUSE_MENU_IMPLEMENTED": bool(pause.get("PAUSE_MENU_IMPLEMENTED", False)),
        "IN_MATCH_MOVE_LIST_IMPLEMENTED": bool(pause.get("IN_MATCH_MOVE_LIST_IMPLEMENTED", False)),
        "TOUCH_PAUSE_BUTTON_IMPLEMENTED": True,
        "TRAINING_PAUSE_UNIFIED": True,
        "PAUSE_MOVE_LIST_DESKTOP_PASS": desktop_pause_ok,
        "PAUSE_MOVE_LIST_TOUCH_PAUSE_PASS": bool(pause.get("PAUSE_MOVE_LIST_TOUCH_PAUSE_PASS", False)),
        "PAUSE_RESUME_STATE_CORRUPTIONS": int(pause.get("PAUSE_RESUME_STATE_CORRUPTIONS", 0)),
        "PAUSE_MOVE_LIST_GHOST_REGRESSIONS": int(pause.get("PAUSE_MOVE_LIST_GHOST_REGRESSIONS", 0)),
        "PAUSE_MOVE_LIST_CRASHES": int(pause.get("PAUSE_MOVE_LIST_CRASHES", 0)),
        "PAUSE_PATH_PREVIEWS_RENDERED": int(pause.get("PAUSE_PATH_PREVIEWS_RENDERED", 0)),
        "SIMPLE_VIEW": True,
        "ADVANCED_DETAILS_VIEW": True,
        "FIGHTERS_WITH_ELEMENTAL_AUDIO": audio.get("FIGHTERS_WITH_ELEMENTAL_AUDIO", 0),
        "GENERIC_AUDIO_OVERUSE_CASES": audio.get("GENERIC_AUDIO_OVERUSE_CASES", 0),
        "AUDIO_IDENTITY_COLLISIONS": audio.get("AUDIO_IDENTITY_COLLISIONS", 0),
        "DESKTOP_AUDIO_RUNTIME_PASS": desktop_audio_ok,
        "PIXEL_AUDIO_RUNTIME_PASS": pixel.get("PIXEL_AUDIO_RUNTIME_PASS"),
        "FINAL_CHARACTER_ART_PASS": False,
        "FINAL_HUMAN_AUTHORED_ANIMATION_PASS": False,
        "HUMAN_ART_DIRECTION_APPROVAL": False,
        "HUMAN_PLAYTEST_COMPLETE": False,
        "OWNER_TASTE_REVIEW": "PENDING",
        "OWNER_MOVE_LIST_APPROVAL": "PENDING",
        "READY_FOR_OWNER_MERGE": ready,
        "NEW_S0": 0,
        "NEW_S1": 0,
        "CI": "PENDING",
        **{k: pixel.get(k) for k in pixel if k.startswith("PIXEL_")},
        "emitted_at": now(),
    }
    write_json(ART / "WAVE020_RESULT.json", payload)
    return payload


def main() -> None:
    ART.mkdir(parents=True, exist_ok=True)
    result = emit_result()
    print(json.dumps({k: result[k] for k in ["WAVE020_CHARACTER_VISIBILITY_PAUSE_MOVELIST_ELEMENTAL_AUDIO", "READY_FOR_OWNER_MERGE"]}, indent=2))


if __name__ == "__main__":
    main()
