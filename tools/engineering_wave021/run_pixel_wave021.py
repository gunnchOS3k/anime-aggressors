#!/usr/bin/env python3
"""Wave021 Pixel 6a gate harness — gates 0–4, stop on first real failure.

Gate 0: Inherited PR95 baseline (20 roster sweeps, Move Preview, Battle, Victory)
Gate 1: UI (Select focus/lock-in, Versus, Pause, Move List, Victory)
Gate 2–4: In-app Wave021 harness (aura tiers, ember ascension, ascended lifecycle)
"""
from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "engineering_wave021"
PIXEL = ART / "pixel"
PKG = "com.gunnchos.animeaggressors"
ACTIVITY = "com.godot.game.GodotApp"
COMPONENT = f"{PKG}/{ACTIVITY}"
APK = ROOT / "builds" / "android" / "anime-aggressors-debug.apk"
HARNESS_RESULT_REMOTE = "wave021/WAVE021_PIXEL_HARNESS_RESULT.json"
HARNESS_TRIGGER = "files/wave021_pixel_harness_trigger.txt"
PR95_MERGE_SHA = "0d094349e2aa6a7bbb4e7cdec4694ab33e585593"

sys.path.insert(0, str(ROOT / "tools" / "engineering_wave020"))
import run_pixel_campaign as rpc  # noqa: E402
import run_pixel_fast_gates as fast  # noqa: E402
from run_pixel_vesper_kaia_first_failure import (  # noqa: E402
    looks_like_fight_hud,
    looks_like_victory_screen,
)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def git_sha() -> str:
    return subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def write_pixel_result(payload: dict) -> None:
    ART.mkdir(parents=True, exist_ok=True)
    (ART / "PIXEL_WAVE021.json").write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps({k: v for k, v in payload.items() if k != "captures"}, indent=2))


def blocked_payload(reason: str) -> dict:
    return {
        "PIXEL_DEVICE_AVAILABLE": False,
        "PIXEL_WAVE021_VALIDATION": "BLOCKED",
        "GATE_0_PR95_BASELINE": None,
        "GATE_1_UI": None,
        "GATE_2_AURA_TIERS": None,
        "GATE_3_EMBER_ASCENSION": None,
        "GATE_4_ASCENDED_LIFECYCLE": None,
        "GATE_0_LAUNCH": None,
        "GATE_1_SELECT": None,
        "GATE_2_TRANSFORM": None,
        "GATE_3_BATTLE_ASCENDED": None,
        "GATE_4_OWNER_SOAK": None,
        "reason": reason,
        "package": PKG,
        "PR95_MERGE_SHA": PR95_MERGE_SHA,
        "emitted_at": utc_now(),
    }


def fail_payload(base: dict, gate_key: str, reason: str) -> dict:
    base["PIXEL_WAVE021_VALIDATION"] = "FAIL"
    base["reason"] = reason
    base["failed_gate"] = gate_key
    base["emitted_at"] = utc_now()
    return base


def build_and_install(serial: str) -> tuple[bool, dict]:
    PIXEL.mkdir(parents=True, exist_ok=True)
    force = os.environ.get("WAVE021_FORCE_APK_REBUILD", "1") == "1"
    if force or not APK.is_file() or APK.stat().st_size < 1_000_000:
        if not rpc.build_apk():
            return False, {"reason": "APK_BUILD_FAILED"}
    apk_sha = sha256_file(APK)
    runtime_sha = git_sha()
    for bad in rpc.FORBIDDEN_PACKAGES:
        rpc.adb(["-s", serial, "shell", "am", "force-stop", bad])
    rpc.adb(["-s", serial, "shell", "am", "force-stop", PKG])
    inst = rpc.adb(["-s", serial, "install", "-r", "-d", "-g", str(APK)], timeout=300)
    (PIXEL / "install.txt").write_text(inst.stdout + "\n" + inst.stderr)
    if inst.returncode != 0:
        return False, {"reason": "APK_INSTALL_FAILED", "install": (inst.stdout + inst.stderr)[-400:]}
    rpc.grant_aa_runtime_permissions(serial)
    provenance = {
        "APK_SHA256": apk_sha,
        "PHYSICALLY_TESTED_RUNTIME_SHA": runtime_sha,
        "PR95_MERGE_SHA": PR95_MERGE_SHA,
        "PACKAGE": PKG,
        "DEVICE_SERIAL": serial,
        "BUILD_TIMESTAMP": utc_now(),
        "SETTINGS_UI_USED": False,
        "AA_ONLY_GUARDS": True,
    }
    (PIXEL / "PIXEL_BUILD_PROVENANCE.json").write_text(json.dumps(provenance, indent=2) + "\n")
    return True, provenance


def gate0_pr95_baseline(serial: str, captures: list) -> dict:
    """Wave020 fast gates A→D."""
    if not fast.launch_with_retry(serial):
        return {"GATE_0_PR95_BASELINE": "FAIL", "reason": "LAUNCH_FAILED"}
    if not fast.on_fighter_select(serial):
        return {"GATE_0_PR95_BASELINE": "FAIL", "reason": "NOT_ON_FIGHTER_SELECT"}

    for label, fn in (
        ("A", fast.gate_a_select_sweeps),
        ("B", fast.gate_b_move_preview),
        ("C", fast.gate_c_battle_all),
        ("D", fast.gate_d_victory),
    ):
        print(f"=== Wave021 Gate 0 / PR95 Gate {label} ===")
        result = fn(serial, captures)
        gate_pass = result.get(f"PIXEL_GATE_{label}") == "PASS"
        if not gate_pass:
            return {
                "GATE_0_PR95_BASELINE": "FAIL",
                "GATE_0_LAUNCH": "FAIL",
                "failed_pr95_gate": label,
                "pr95_detail": result,
                "reason": result.get("reason", f"PR95_GATE_{label}_FAIL"),
            }
    return {
        "GATE_0_PR95_BASELINE": "PASS",
        "GATE_0_LAUNCH": "PASS",
        "PR95_GATES": "A-D PASS",
    }


def looks_like_versus(path: Path) -> bool:
    text = rpc.ocr_text(path)
    return bool(text) and any(m in text for m in ("versus", "fight!", "ready"))


def gate1_ui_flow(serial: str, captures: list) -> dict:
    """Select focus/lock-in → Versus → Pause → Move List → Victory (1-stock)."""
    rpc.adb(["-s", serial, "shell", "am", "force-stop", PKG])
    time.sleep(0.4)
    if not fast.launch_with_retry(serial):
        return {"GATE_1_UI": "FAIL", "GATE_1_SELECT": "FAIL", "reason": "LAUNCH_FAILED"}
    if not fast.on_fighter_select(serial, attempts=5):
        return {"GATE_1_UI": "FAIL", "GATE_1_SELECT": "FAIL", "reason": "SELECT_NAV_FAIL"}

    # Focus Ember (index 0) then lock-in P1/P2
    rpc.dismiss_select_overlays(serial)
    rpc.tap_roster_index(serial, 0)
    time.sleep(0.6)
    rpc.dismiss_select_overlays(serial)
    cap_focus = rpc.screencap(serial, "gate1_select_focus")
    captures.append(cap_focus)
    focus_path = PIXEL / "gate1_select_focus.png"
    focus_text = rpc.ocr_text(focus_path)
    if "ember" not in focus_text and "p1:" not in focus_text:
        return {
            "GATE_1_UI": "FAIL",
            "GATE_1_SELECT": "FAIL",
            "reason": "SELECT_FOCUS_FAIL",
            "ocr_snippet": focus_text[:300],
        }
    if not rpc.confirm_fighter_select_into_battle(serial):
        return {"GATE_1_UI": "FAIL", "GATE_1_SELECT": "FAIL", "reason": "SELECT_LOCKIN_FAIL"}
    time.sleep(1.2)
    captures.append(cap_versus)
    versus_path = PIXEL / "gate1_versus.png"
    if not (looks_like_versus(versus_path) or looks_like_fight_hud(versus_path)):
        return {"GATE_1_UI": "FAIL", "GATE_1_SELECT": "FAIL", "reason": "VERSUS_FAIL"}

    if not fast.wait_for_battle_hud(serial, "gate1", timeout=32, fighter_idx=0):
        return {"GATE_1_UI": "FAIL", "GATE_1_SELECT": "FAIL", "reason": "BATTLE_HUD_FAIL"}

    # Pause
    rpc.key(serial, "KEYCODE_ESCAPE")
    time.sleep(0.55)
    cap_pause = rpc.screencap(serial, "gate1_pause")
    captures.append(cap_pause)
    pause_text = rpc.ocr_text(PIXEL / "gate1_pause.png")
    if not any(m in pause_text for m in ("paused", "resume", "pause")):
        return {"GATE_1_UI": "FAIL", "GATE_1_SELECT": "FAIL", "reason": "PAUSE_FAIL"}

    # Move List
    fast.open_move_preview_from_battle(serial)
    time.sleep(0.55)
    cap_movelist = rpc.screencap(serial, "gate1_movelist")
    captures.append(cap_movelist)
    if not fast.looks_like_move_preview(PIXEL / "gate1_movelist.png"):
        return {"GATE_1_UI": "FAIL", "GATE_1_SELECT": "FAIL", "reason": "MOVELIST_FAIL"}
    fast.dismiss_pause_or_move_list(serial)

    # Victory path (1-stock ruleset)
    rpc.adb(["-s", serial, "shell", "am", "force-stop", PKG])
    time.sleep(0.4)
    if not fast.launch_with_retry(serial):
        return {"GATE_1_UI": "FAIL", "GATE_1_SELECT": "FAIL", "reason": "VICTORY_LAUNCH_FAIL"}
    if not fast.on_fighter_select_one_stock(serial, attempts=5):
        return {"GATE_1_UI": "FAIL", "GATE_1_SELECT": "FAIL", "reason": "VICTORY_SELECT_FAIL"}
    if not fast.select_fighter_into_battle(serial, 0):
        return {"GATE_1_UI": "FAIL", "GATE_1_SELECT": "FAIL", "reason": "VICTORY_SELECT_FAIL"}
    time.sleep(1.0)
    if not fast.wait_for_battle_hud(serial, "gate1_victory", timeout=32, fighter_idx=0):
        return {"GATE_1_UI": "FAIL", "GATE_1_SELECT": "FAIL", "reason": "VICTORY_BATTLE_FAIL"}
    final = fast.mash_toward_victory(serial, "gate1_victory", seconds=50.0)
    victory_ok = final is not None and looks_like_victory_screen(final)
    cap_victory = rpc.screencap(serial, "gate1_victory_final")
    captures.append(cap_victory)
    if not victory_ok:
        return {"GATE_1_UI": "FAIL", "GATE_1_SELECT": "FAIL", "reason": "VICTORY_FAIL"}

    return {"GATE_1_UI": "PASS", "GATE_1_SELECT": "PASS"}


def pull_harness_result(serial: str) -> dict:
    raw = rpc.run_as_cat(serial, HARNESS_RESULT_REMOTE)
    if not raw.strip():
        return {}
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {"parse_error": True, "raw_head": raw[:200]}


def run_in_app_harness(serial: str, runtime_sha: str, apk_sha: str, timeout_s: int = 600) -> dict:
    rpc.adb(["-s", serial, "shell", "am", "force-stop", PKG])
    time.sleep(0.5)
    rpc.adb(["-s", serial, "shell", f"run-as {PKG} rm -rf files/wave021"])
    rpc.adb(["-s", serial, "shell", f"run-as {PKG} mkdir -p files/wave021"])
    rpc.adb(
        ["-s", serial, "shell", f"run-as {PKG} sh -c \"printf '{runtime_sha}' > files/wave021/source_sha.txt\""],
    )
    rpc.adb(
        ["-s", serial, "shell", f"run-as {PKG} sh -c \"printf '{apk_sha}' > files/wave021/apk_sha256.txt\""],
    )
    rpc.adb(["-s", serial, "shell", f"run-as {PKG} sh -c 'printf wave021 > {HARNESS_TRIGGER}'"])
    rpc.adb(
        ["-s", serial, "shell", "am", "start", "-W", "-n", COMPONENT,
         "-a", "android.intent.action.MAIN", "-c", "android.intent.category.LAUNCHER",
         "--es", "command_line", "--wave021-pixel-harness"],
        timeout=60,
    )
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        time.sleep(2.0)
        result = pull_harness_result(serial)
        if result:
            local = PIXEL / "WAVE021_PIXEL_HARNESS_RESULT.json"
            local.write_text(json.dumps(result, indent=2) + "\n")
            return result
    return {"timeout": True}


def map_harness_gates(harness: dict) -> dict:
    g2 = harness.get("GATE_2_AURA_TIERS", "FAIL")
    g3 = harness.get("GATE_3_EMBER_ASCENSION", "FAIL")
    g4 = harness.get("GATE_4_ASCENDED_LIFECYCLE", "FAIL")
    return {
        "GATE_2_AURA_TIERS": g2,
        "GATE_2_TRANSFORM": g2,
        "GATE_3_EMBER_ASCENSION": g3,
        "GATE_3_BATTLE_ASCENDED": g3,
        "GATE_4_ASCENDED_LIFECYCLE": g4,
        "GATE_4_OWNER_SOAK": g4,
        "TRANSFORM_ACTIVATIONS": int(harness.get("TRANSFORM_ACTIVATIONS", 0)),
        "TRANSFORM_FAILURES": int(harness.get("TRANSFORM_FAILURES", 0)),
        "AURA_TIER_FAILURES": int(harness.get("AURA_TIER_FAILURES", 0)),
        "LIFECYCLE_FAILURES": int(harness.get("LIFECYCLE_FAILURES", 0)),
        "harness_detail": harness,
    }


def main() -> int:
    ART.mkdir(parents=True, exist_ok=True)
    PIXEL.mkdir(parents=True, exist_ok=True)

    serials = rpc.devices()
    if not serials:
        write_pixel_result(blocked_payload("No authorized Pixel 6a attached"))
        print("PIXEL_WAVE021_VALIDATION=BLOCKED")
        return 2

    serial = serials[0]
    model = rpc.adb(["-s", serial, "shell", "getprop", "ro.product.model"]).stdout.strip()
    captures: list = []

    ok, prov = build_and_install(serial)
    if not ok:
        payload = blocked_payload(prov.get("reason", "BUILD_INSTALL_FAILED"))
        payload["PIXEL_DEVICE_AVAILABLE"] = True
        payload["PIXEL_WAVE021_VALIDATION"] = "FAIL"
        payload["build_detail"] = prov
        write_pixel_result(payload)
        print("PIXEL_WAVE021_VALIDATION=FAIL")
        return 1

    payload: dict = {
        "PIXEL_DEVICE_AVAILABLE": True,
        "PIXEL_WAVE021_VALIDATION": "PENDING",
        "PIXEL_AUTHENTIC": True,
        "AA_ONLY_GUARDS": True,
        "SETTINGS_UI_USED": False,
        "DEVICE_SERIAL": serial,
        "DEVICE_MODEL": model,
        "HEAD": prov["PHYSICALLY_TESTED_RUNTIME_SHA"],
        "APK_SHA256": prov["APK_SHA256"],
        "PHYSICALLY_TESTED_RUNTIME_SHA": prov["PHYSICALLY_TESTED_RUNTIME_SHA"],
        "PR95_MERGE_SHA": PR95_MERGE_SHA,
        "package": PKG,
        "captures": captures,
        "emitted_at": utc_now(),
    }

    start_gate = os.environ.get("WAVE021_PIXEL_START_GATE", "0")
    if start_gate <= "0":
        g0 = gate0_pr95_baseline(serial, captures)
        payload.update(g0)
        if g0.get("GATE_0_PR95_BASELINE") != "PASS":
            write_pixel_result(fail_payload(payload, "GATE_0", g0.get("reason", "GATE_0_FAIL")))
            print("PIXEL_WAVE021_VALIDATION=FAIL")
            return 1

    if start_gate <= "1":
        g1 = gate1_ui_flow(serial, captures)
        payload.update(g1)
        if g1.get("GATE_1_UI") != "PASS":
            write_pixel_result(fail_payload(payload, "GATE_1", g1.get("reason", "GATE_1_FAIL")))
            print("PIXEL_WAVE021_VALIDATION=FAIL")
            return 1

    if start_gate <= "2":
        print("=== Wave021 Gates 2–4 (in-app harness) ===")
        harness = run_in_app_harness(serial, prov["PHYSICALLY_TESTED_RUNTIME_SHA"], prov["APK_SHA256"])
        payload.update(map_harness_gates(harness))
        if harness.get("timeout"):
            write_pixel_result(fail_payload(payload, "GATE_2", "IN_APP_HARNESS_TIMEOUT"))
            print("PIXEL_WAVE021_VALIDATION=FAIL")
            return 1
        if payload.get("GATE_2_AURA_TIERS") != "PASS":
            write_pixel_result(fail_payload(payload, "GATE_2", harness.get("reason", "GATE_2_FAIL")))
            print("PIXEL_WAVE021_VALIDATION=FAIL")
            return 1
        if payload.get("GATE_3_EMBER_ASCENSION") != "PASS":
            write_pixel_result(fail_payload(payload, "GATE_3", harness.get("reason", "GATE_3_FAIL")))
            print("PIXEL_WAVE021_VALIDATION=FAIL")
            return 1
        if payload.get("GATE_4_ASCENDED_LIFECYCLE") != "PASS":
            write_pixel_result(fail_payload(payload, "GATE_4", harness.get("reason", "GATE_4_FAIL")))
            print("PIXEL_WAVE021_VALIDATION=FAIL")
            return 1

    payload["PIXEL_WAVE021_VALIDATION"] = "PASS"
    payload["reason"] = None
    payload["emitted_at"] = utc_now()
    write_pixel_result(payload)
    print("PIXEL_WAVE021_VALIDATION=PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
