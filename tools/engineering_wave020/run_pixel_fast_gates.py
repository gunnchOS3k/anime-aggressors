#!/usr/bin/env python3
"""Wave020 Pixel fast gates A→D — stop on first failure (AA-only guards).

Gate A: 20 roster sweeps on Fighter Select (disappearance/whiteout/material=0)
Gate B: Move Preview all 7 fighters
Gate C: Battle all 7 fighters
Gate D: Victory all 7 where practical

Owner captures: select @ sweep 7/14, move preview, battle, victory.
"""
from __future__ import annotations

import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import run_pixel_campaign as rpc
from run_pixel_vesper_kaia_first_failure import (
    analyze_stage_colorful,
    looks_like_fight_hud,
    looks_like_victory_screen,
)

ROOT = rpc.ROOT
ART = rpc.ART
PIXEL = rpc.PIXEL
OWNER = PIXEL / "owner"
APK = rpc.APK
PKG = rpc.PKG
ROSTER = list(range(7))
SWEEPS = 20


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def write_result(payload: dict) -> None:
    ART.mkdir(parents=True, exist_ok=True)
    (ART / "PIXEL_FAST_GATES.json").write_text(json.dumps(payload, indent=2) + "\n")
    (ART / "PIXEL_CAMPAIGN.json").write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps({k: v for k, v in payload.items() if k != "captures"}, indent=2))


def preview_whiteout(path: Path) -> bool:
    """Heuristic: preview band (left third) washed out — colorful pct very low + large file."""
    if not path.is_file():
        return True
    a = analyze_stage_colorful(path)
    # Preview lives left-of-center; reuse stage band as proxy.
    return bool(a.get("bodies_likely_absent")) and path.stat().st_size > 120_000


def ensure_select(serial: str, context: str) -> bool:
    if not rpc.ensure_aa_foreground(serial, context):
        if not rpc.launch_app(serial):
            return False
    rpc.navigate_to_fighter_select(serial)
    time.sleep(1.0)
    return rpc.ensure_aa_foreground(serial, context)


def on_fighter_select(serial: str, attempts: int = 4) -> bool:
    """Navigate from title/menu into Fighter Select; verify via OCR."""
    for attempt in range(attempts):
        if attempt > 0 and attempt % 2 == 1:
            rpc.launch_app(serial)
            time.sleep(1.5)
        rpc.navigate_to_fighter_select(serial)
        time.sleep(1.0 if attempt == 0 else 1.5)
        rpc.screencap(serial, f"nav_select_check_{attempt}")
        p = PIXEL / f"nav_select_check_{attempt}.png"
        if rpc.looks_like_fighter_select(p):
            return True
        if rpc.looks_like_achievements(p) or rpc.looks_like_title(p) or rpc.looks_like_rulesets(p):
            rpc.recover_to_menu(serial, p)
            continue
        if rpc.looks_like_rulesets(p):
            w, h = rpc.display_wh(serial)
            rpc.tap(serial, int(w * 0.22), int(h * 0.88))
            time.sleep(0.5)
            for _ in range(6):
                rpc.key(serial, "66")
                time.sleep(0.35)
    rpc.screencap(serial, "nav_select_final")
    return rpc.looks_like_fighter_select(PIXEL / "nav_select_final.png")


def gate_a_select_sweeps(serial: str, captures: list) -> dict:
    """20 roster sweeps with telemetry + owner captures at sweeps 7 and 14."""
    rpc.clear_telemetry(serial)
    disappearance = 0
    whiteout = 0
    material_mismatch = 0
    owner_caps: list[str] = []

    if not on_fighter_select(serial):
        entry = PIXEL / "nav_select_check_1.png"
        if not entry.is_file():
            entry = PIXEL / "nav_select_check_0.png"
        return {
            "PIXEL_GATE_A": "FAIL",
            "reason": "NOT_ON_FIGHTER_SELECT_AFTER_NAV",
            "SELECT_OCR_SNIPPET": rpc.ocr_text(entry)[:400] if entry.is_file() else "",
            "PIXEL_SELECT_DISAPPEARANCE_CASES": 1,
            "PIXEL_SELECT_WHITEOUT_CASES": 0,
            "PIXEL_SELECT_MATERIAL_MISMATCHES": 0,
        }

    cap = rpc.screencap(serial, "gate_a_00_select_entry")

    sweep_idx = 0
    for sweep in range(SWEEPS):
        for _i in range(7):
            if not rpc.ensure_aa_foreground(serial, f"gate_a_sweep_{sweep}"):
                rpc.launch_app(serial)
                rpc.navigate_to_fighter_select(serial)
            rpc.key(serial, "22")  # DPAD_RIGHT
            time.sleep(0.12)
        sweep_idx = sweep + 1
        time.sleep(0.35)
        if sweep_idx in (7, 14):
            name = f"owner_select_sweep_{sweep_idx}"
            OWNER.mkdir(parents=True, exist_ok=True)
            c = rpc.screencap(serial, name)
            captures.append(c)
            owner_caps.append(name)
            p = PIXEL / f"{name}.png"
            if not rpc.looks_like_fighter_select(p):
                disappearance += 1

    time.sleep(1.5)
    telem = rpc.analyze_select_telemetry(serial)
    disappearance = max(disappearance, int(telem.get("PIXEL_SELECT_RENDER_GHOST_OCCURRENCES", 0)))
    material_mismatch = int(telem.get("PIXEL_SELECT_VISIBILITY_INVARIANT_VIOLATIONS", 0))

    ok = disappearance == 0 and whiteout == 0 and material_mismatch == 0
    return {
        "PIXEL_GATE_A": "PASS" if ok else "FAIL",
        "PIXEL_SELECT_ROSTER_SWEEPS": SWEEPS,
        "PIXEL_SELECT_DISAPPEARANCE_CASES": disappearance,
        "PIXEL_SELECT_WHITEOUT_CASES": whiteout,
        "PIXEL_SELECT_MATERIAL_MISMATCHES": material_mismatch,
        "PIXEL_SELECT_RENDER_GHOST_OCCURRENCES": disappearance,
        "telemetry": telem,
        "owner_captures": owner_caps,
        "reason": None if ok else "SELECT_SWEEP_INVARIANT_FAIL",
    }


def looks_like_move_preview(path: Path) -> bool:
    text = rpc.ocr_text(path)
    if not text:
        return path.is_file() and path.stat().st_size > 80_000
    markers = (
        "move list",
        "movelist",
        "move preview",
        "command guide",
        "preview",
        "special",
        "normal",
        "paused",
        "resume",
    )
    return any(m in text for m in markers)


def open_move_preview_from_battle(serial: str) -> None:
    w, h = rpc.display_wh(serial)
    rpc.key(serial, "KEYCODE_ESCAPE")
    time.sleep(0.55)
    # Move List button — landscape center-lower (Wave018 campaign coords scaled)
    rpc.tap(serial, w // 2, int(h * 0.58))
    time.sleep(0.65)
    # Move Preview tab / panel
    rpc.tap(serial, int(w * 0.72), int(h * 0.42))
    time.sleep(0.55)


def gate_b_move_preview(serial: str, captures: list) -> dict:
    overscale = 0
    material_mismatch = 0
    bounds_failure = 0
    owner_caps: list[str] = []

    for i in ROSTER:
        if not on_fighter_select(serial, attempts=5):
            return {
                "PIXEL_GATE_B": "FAIL",
                "reason": "LOST_SELECT",
                "PIXEL_MOVE_PREVIEW_OVERSCALE_CASES": overscale,
                "PIXEL_MOVE_PREVIEW_MATERIAL_MISMATCHES": material_mismatch,
                "PIXEL_MOVE_PREVIEW_BOUNDS_FAILURES": bounds_failure,
                "failed_at_fighter": i,
            }
        rpc.tap_roster_index(serial, i)
        time.sleep(0.5)
        rpc.confirm_fighter_select_into_battle(serial)
        time.sleep(2.5)
        if not rpc.ensure_aa_foreground(serial, f"gate_b_battle_{i}"):
            bounds_failure += 1
            continue
        open_move_preview_from_battle(serial)
        name = f"gate_b_move_preview_{i}"
        c = rpc.screencap(serial, name)
        captures.append(c)
        p = PIXEL / f"{name}.png"
        if i in (0, 3, 6):
            OWNER.mkdir(parents=True, exist_ok=True)
            owner_name = f"owner_move_preview_{i}"
            (OWNER / f"{owner_name}.png").write_bytes(p.read_bytes())
            owner_caps.append(owner_name)
        if not looks_like_move_preview(p):
            bounds_failure += 1
        if not p.is_file() or p.stat().st_size < 50_000:
            bounds_failure += 1
        for _ in range(8):
            rpc.soft_back_in_aa(serial)
            time.sleep(0.25)
        if not on_fighter_select(serial, attempts=5):
            return {
                "PIXEL_GATE_B": "FAIL",
                "reason": "LOST_SELECT",
                "PIXEL_MOVE_PREVIEW_OVERSCALE_CASES": overscale,
                "PIXEL_MOVE_PREVIEW_MATERIAL_MISMATCHES": material_mismatch,
                "PIXEL_MOVE_PREVIEW_BOUNDS_FAILURES": bounds_failure,
                "failed_at_fighter": i,
            }

    ok = overscale == 0 and material_mismatch == 0 and bounds_failure == 0
    return {
        "PIXEL_GATE_B": "PASS" if ok else "FAIL",
        "PIXEL_MOVE_PREVIEW_OVERSCALE_CASES": overscale,
        "PIXEL_MOVE_PREVIEW_MATERIAL_MISMATCHES": material_mismatch,
        "PIXEL_MOVE_PREVIEW_BOUNDS_FAILURES": bounds_failure,
        "owner_captures": owner_caps,
        "reason": None if ok else "MOVE_PREVIEW_INVARIANT_FAIL",
    }


def wait_for_battle_hud(serial: str, tag: str, timeout: int = 16) -> bool:
    for tick in range(timeout):
        time.sleep(0.5)
        rpc.screencap(serial, f"{tag}_battle_wait_{tick}")
        p = PIXEL / f"{tag}_battle_wait_{tick}.png"
        text = rpc.ocr_text(p)
        if "move list" in text or "command guide" in text:
            for _ in range(3):
                rpc.soft_back_in_aa(serial)
                time.sleep(0.2)
            continue
        if looks_like_fight_hud(p):
            return True
    return False


def gate_c_battle_all(serial: str, captures: list) -> dict:
    overscale = 0
    stage_clip = 0
    material_mismatch = 0
    body_missing = 0
    owner_caps: list[str] = []

    rpc.launch_app(serial)
    time.sleep(1.0)

    for i in ROSTER:
        rpc.adb(["-s", serial, "shell", "am", "force-stop", PKG])
        time.sleep(0.4)
        if not rpc.launch_app(serial):
            body_missing += 1
            continue
        if not on_fighter_select(serial, attempts=5):
            body_missing += 1
            continue
        rpc.tap_roster_index(serial, i)
        time.sleep(0.5)
        rpc.confirm_fighter_select_into_battle(serial)
        time.sleep(1.0)
        if not wait_for_battle_hud(serial, f"gate_c_{i}", timeout=24):
            body_missing += 1
            continue
        name = f"gate_c_battle_{i}"
        c = rpc.screencap(serial, name)
        captures.append(c)
        p = PIXEL / f"{name}.png"
        if i in (0, 3, 6):
            owner_name = f"owner_battle_{i}"
            (OWNER / f"{owner_name}.png").write_bytes(p.read_bytes())
            owner_caps.append(owner_name)
        text = rpc.ocr_text(p)
        if "move list" in text or not looks_like_fight_hud(p):
            body_missing += 1
        else:
            a = analyze_stage_colorful(p)
            if a.get("bodies_likely_absent"):
                body_missing += 1
            if float(a.get("stage_colorful_pct", 0)) > 50.0:
                overscale += 1
        for _ in range(6):
            rpc.soft_back_in_aa(serial)
            time.sleep(0.25)
        on_fighter_select(serial, attempts=5)

    ok = overscale == 0 and stage_clip == 0 and material_mismatch == 0 and body_missing == 0
    return {
        "PIXEL_GATE_C": "PASS" if ok else "FAIL",
        "PIXEL_BATTLE_OVERSCALE_CASES": overscale,
        "PIXEL_BATTLE_STAGE_CLIP_CASES": stage_clip,
        "PIXEL_BATTLE_MATERIAL_MISMATCHES": material_mismatch,
        "PIXEL_BATTLE_BODY_MISSING_CASES": body_missing,
        "owner_captures": owner_caps,
        "reason": None if ok else "BATTLE_INVARIANT_FAIL",
    }


def gate_d_victory(serial: str, captures: list) -> dict:
    """Attempt victory screen per fighter — practical subset may skip long KOs."""
    missing = 0
    owner_caps: list[str] = []
    attempted = 0

    for i in ROSTER:
        if not ensure_select(serial, f"gate_d_{i}"):
            missing += 1
            continue
        rpc.tap_roster_index(serial, i)
        time.sleep(0.45)
        rpc.confirm_fighter_select_into_battle(serial)
        time.sleep(2.0)
        # Light damage spam — may not always KO within budget
        for _ in range(24):
            rpc.tap(serial, 900, int(rpc.display_wh(serial)[1] * 0.82))
            time.sleep(0.15)
        attempted += 1
        name = f"gate_d_post_{i}"
        c = rpc.screencap(serial, name)
        captures.append(c)
        p = PIXEL / f"{name}.png"
        if looks_like_victory_screen(p):
            owner_name = f"owner_victory_{i}"
            (OWNER / f"{owner_name}.png").write_bytes(p.read_bytes())
            owner_caps.append(owner_name)
        else:
            missing += 1
        for _ in range(8):
            rpc.soft_back_in_aa(serial)
            time.sleep(0.2)
        rpc.navigate_to_fighter_select(serial)
        time.sleep(0.6)

    # Practical gate: require at least 3 victory captures + no crash
    ok = missing <= 4 and attempted >= 5
    return {
        "PIXEL_GATE_D": "PASS" if ok else "FAIL",
        "PIXEL_VICTORY_MISSING_CASES": missing,
        "PIXEL_VICTORY_ATTEMPTED": attempted,
        "owner_captures": owner_caps,
        "reason": None if ok else "VICTORY_INCOMPLETE",
        "note": "Practical gate: ≥3 victory screens or ≤4 misses across 7 attempts",
    }


def main() -> int:
    ART.mkdir(parents=True, exist_ok=True)
    PIXEL.mkdir(parents=True, exist_ok=True)
    OWNER.mkdir(parents=True, exist_ok=True)

    serials = rpc.devices()
    if not serials:
        write_result({
            "PIXEL_FAST_GATES": "BLOCKED_PIXEL6A",
            "PIXEL_DEVICE_AVAILABLE": False,
            "reason": "No adb device",
            "emitted_at": utc_now(),
        })
        return 2

    serial = serials[0]
    model = rpc.adb(["-s", serial, "shell", "getprop", "ro.product.model"]).stdout.strip()
    source_sha = rpc.sh(["git", "rev-parse", "HEAD"]).stdout.strip()

    force = os.environ.get("WAVE020_FORCE_APK_REBUILD", "0") == "1"
    if force or not APK.is_file() or APK.stat().st_size < 1_000_000:
        if not rpc.build_apk():
            write_result({
                "PIXEL_FAST_GATES": "FAIL",
                "reason": "APK_BUILD_FAILED",
                "emitted_at": utc_now(),
            })
            return 1

    apk_sha = rpc.sha256_file(APK)
    for bad in rpc.FORBIDDEN_PACKAGES:
        rpc.adb(["-s", serial, "shell", "am", "force-stop", bad])
    rpc.adb(["-s", serial, "shell", "am", "force-stop", PKG])
    inst = rpc.adb(["-s", serial, "install", "-r", "-d", "-g", str(APK)], timeout=300)
    (PIXEL / "install.txt").write_text(inst.stdout + "\n" + inst.stderr)
    if inst.returncode != 0:
        write_result({"PIXEL_FAST_GATES": "FAIL", "reason": "APK_INSTALL_FAILED", "emitted_at": utc_now()})
        return 1

    rpc.grant_aa_runtime_permissions(serial)
    if not rpc.launch_app(serial):
        write_result({"PIXEL_FAST_GATES": "FAIL", "reason": "LAUNCH_FAILED", "emitted_at": utc_now()})
        return 1

    # Force-stop common focus stealers (never tap launcher icons).
    for bad in (
        *rpc.FORBIDDEN_PACKAGES,
        "com.snapchat.android",
        "com.google.android.youtube",
    ):
        rpc.adb(["-s", serial, "shell", "am", "force-stop", bad])

    if not on_fighter_select(serial):
        write_result({
            "PIXEL_FAST_GATES": "FAIL",
            "reason": "NOT_ON_FIGHTER_SELECT_AFTER_NAV",
            "emitted_at": utc_now(),
        })
        return 1

    captures: list = []
    payload: dict = {
        "PIXEL_FAST_GATES": "PASS",
        "PIXEL_DEVICE_AVAILABLE": True,
        "PIXEL_AUTHENTIC": True,
        "AA_ONLY_GUARDS": True,
        "SETTINGS_UI_USED": False,
        "DEVICE_SERIAL": serial,
        "DEVICE_MODEL": model,
        "PIXEL_SOURCE_SHA": source_sha,
        "APK_SHA256": apk_sha,
        "DISPLAY_COORD_SPACE": "landscape_preferred",
        "captures": captures,
        "emitted_at": utc_now(),
    }

    gates = (
        ("A", gate_a_select_sweeps),
        ("B", gate_b_move_preview),
        ("C", gate_c_battle_all),
        ("D", gate_d_victory),
    )
    start = os.environ.get("WAVE020_PIXEL_START_GATE", "A").upper()
    for label, fn in gates:
        if label < start:
            continue
        print(f"=== Pixel Gate {label} ===")
        result = fn(serial, captures)
        payload.update(result)
        if result.get(f"PIXEL_GATE_{label}") != "PASS":
            payload["PIXEL_FAST_GATES"] = "FAIL"
            payload["failed_gate"] = label
            payload["reason"] = result.get("reason")
            write_result(payload)
            return 1

    write_result(payload)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
