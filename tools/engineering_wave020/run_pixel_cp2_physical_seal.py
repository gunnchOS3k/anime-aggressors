#!/usr/bin/env python3
"""Wave020 CP2 Pixel physical seal — build/install APK, run in-app harness, pull evidence.

AA-only guards: no Settings UI, no launcher taps, pm grant only, foreground checks via am start.
"""
from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "engineering_wave020"
PIXEL = ART / "pixel"
PKG = "com.gunnchos.animeaggressors"
ACTIVITY = "com.godot.game.GodotApp"
APK = ROOT / "builds" / "android" / "anime-aggressors-debug.apk"
RESULT_REMOTE = "files/wave020/CP2_PIXEL_PHYSICAL_SEAL_RESULT.json"
TRIGGER = "files/wave020_cp2_pixel_seal_trigger.txt"


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def adb(*args: str, serial: str | None = None, timeout: int = 180) -> subprocess.CompletedProcess:
    cmd = ["adb"]
    if serial:
        cmd += ["-s", serial]
    cmd += list(args)
    return subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, timeout=timeout)


def git_sha() -> str:
    return subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()


def godot_version() -> str:
    godot = Path.home() / "Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot"
    for c in [os.environ.get("GODOT_BIN"), str(godot), shutil.which("godot")]:
        if c and Path(c).is_file():
            try:
                return subprocess.check_output([c, "--version"], text=True).strip()
            except Exception:
                pass
    return "UNKNOWN"


def version_code_from_apk() -> str:
    sdk = Path(os.path.expanduser("~/Library/Android/sdk/build-tools"))
    candidates = [shutil.which("aapt"), *([str(p) for p in sdk.glob("*/aapt")] if sdk.is_dir() else [])]
    for aapt in candidates:
        if not aapt or not Path(aapt).is_file():
            continue
        try:
            out = subprocess.check_output([aapt, "dump", "badging", str(APK)], text=True, stderr=subprocess.DEVNULL)
            m = re.search(r"versionCode='(\d+)'", out)
            if m:
                return m.group(1)
        except Exception:
            pass
    return ""


def discover_device() -> dict:
    if not shutil.which("adb"):
        return {"ok": False, "reason": "BLOCKED_PIXEL6A", "detail": "adb not found"}
    raw = adb("devices", "-l").stdout
    lines = [ln for ln in raw.splitlines()[1:] if ln.strip()]
    auth = [ln for ln in lines if len(ln.split()) >= 2 and ln.split()[1] == "device"]
    if not auth:
        unauth = any("unauthorized" in ln for ln in lines)
        return {"ok": False, "reason": "BLOCKED_PIXEL6A", "detail": "unauthorized" if unauth else "no device", "raw": raw}
    serial = auth[0].split()[0]
    model = adb("shell", "getprop", "ro.product.model", serial=serial).stdout.strip()
    return {"ok": True, "serial": serial, "model": model}


def build_apk() -> dict:
    env = os.environ.copy()
    godot = Path.home() / "Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot"
    if godot.is_file():
        env["GODOT_BIN"] = str(godot)
    APK.parent.mkdir(parents=True, exist_ok=True)
    PIXEL.mkdir(parents=True, exist_ok=True)
    proc = subprocess.run(
        ["node", "scripts/export-godot-android.mjs"],
        cwd=ROOT,
        env=env,
        capture_output=True,
        text=True,
        timeout=900,
    )
    (PIXEL / "apk_build_log.txt").write_text(proc.stdout + "\n" + proc.stderr, encoding="utf-8")
    ok = proc.returncode == 0 and APK.is_file() and APK.stat().st_size > 1_000_000
    return {
        "ok": ok,
        "exit_code": proc.returncode,
        "PHYSICALLY_TESTED_RUNTIME_SHA": git_sha(),
        "APK_SHA256": sha256_file(APK) if APK.is_file() else "",
        "PACKAGE": PKG,
        "VERSION_CODE": version_code_from_apk() if ok else "",
        "GODOT_VERSION": godot_version(),
        "BUILD_TIMESTAMP": utc_now(),
    }


def pull_file(serial: str, rel: str, dest: Path) -> bool:
    dest.parent.mkdir(parents=True, exist_ok=True)
    proc = subprocess.run(
        ["adb", "-s", serial, "exec-out", "run-as", PKG, "cat", f"files/{rel}"],
        capture_output=True,
    )
    if proc.returncode != 0 or not proc.stdout:
        return False
    head = proc.stdout[:80]
    if head.startswith(b"cat:") or b"No such file" in head:
        return False
    dest.write_bytes(proc.stdout)
    return dest.is_file() and dest.stat().st_size > 0


def grant_perms(serial: str) -> dict:
    results = {}
    for perm in ("android.permission.ACCESS_LOCAL_NETWORK",):
        r = adb("shell", "pm", "grant", PKG, perm, serial=serial)
        ok = r.returncode == 0 or "already" in (r.stderr + r.stdout).lower()
        results[perm] = "granted" if ok else (r.stderr or r.stdout or "failed")[:120]
    return results


def write_summary(payload: dict) -> None:
    ART.mkdir(parents=True, exist_ok=True)
    (ART / "CP2_PIXEL_PHYSICAL_SEAL_RESULT.json").write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps({k: v for k, v in payload.items() if k not in ("gate2", "samples_head")}, indent=2)[:8000])


def main() -> int:
    ART.mkdir(parents=True, exist_ok=True)
    PIXEL.mkdir(parents=True, exist_ok=True)
    device = discover_device()
    if not device.get("ok"):
        write_summary({
            "WAVE020_CP2_PIXEL_PHYSICAL_SEAL": "BLOCKED_PIXEL6A",
            "CP2_SEALED": False,
            "reason": device.get("reason"),
            "detail": device.get("detail"),
            "emitted_at": utc_now(),
        })
        return 2

    serial = device["serial"]
    force = os.environ.get("WAVE020_FORCE_APK_REBUILD", "1") == "1"
    if force or not APK.is_file():
        build = build_apk()
    else:
        build = {
            "ok": True,
            "PHYSICALLY_TESTED_RUNTIME_SHA": git_sha(),
            "APK_SHA256": sha256_file(APK),
            "PACKAGE": PKG,
            "VERSION_CODE": version_code_from_apk(),
            "GODOT_VERSION": godot_version(),
            "BUILD_TIMESTAMP": utc_now(),
            "reused_existing_apk": True,
        }
    if not build.get("ok"):
        write_summary({
            "WAVE020_CP2_PIXEL_PHYSICAL_SEAL": "FAIL",
            "CP2_SEALED": False,
            "reason": "APK_BUILD_FAILED",
            "build": build,
            "emitted_at": utc_now(),
        })
        return 1

    (PIXEL / "PIXEL_BUILD_PROVENANCE.json").write_text(json.dumps({
        **build,
        "DEVICE_SERIAL": serial,
        "DEVICE_MODEL": device.get("model"),
        "SETTINGS_UI_USED": False,
        "PERMISSION_GRANT_METHOD": "adb_pm_grant",
        "AA_ONLY_GUARDS": True,
        "emitted_at": utc_now(),
    }, indent=2) + "\n")

    inst = adb("install", "-r", "-d", "-g", str(APK), serial=serial, timeout=300)
    (PIXEL / "install.txt").write_text(inst.stdout + "\n" + inst.stderr)
    if inst.returncode != 0:
        write_summary({
            "WAVE020_CP2_PIXEL_PHYSICAL_SEAL": "FAIL",
            "CP2_SEALED": False,
            "reason": "APK_INSTALL_FAILED",
            "install": (inst.stdout + inst.stderr)[-500:],
            "emitted_at": utc_now(),
        })
        return 1

    grants = grant_perms(serial)
    (PIXEL / "permission_grants.json").write_text(json.dumps({
        "method": "adb_pm_grant",
        "settings_ui_used": False,
        "grants": grants,
        "emitted_at": utc_now(),
    }, indent=2) + "\n")

    adb("shell", "am", "force-stop", PKG, serial=serial)
    adb("shell", f"run-as {PKG} rm -rf files/wave020", serial=serial)
    adb("shell", f"run-as {PKG} mkdir -p files/wave020/captures", serial=serial)
    sha = build["PHYSICALLY_TESTED_RUNTIME_SHA"]
    apk_sha = build["APK_SHA256"]
    adb("shell", f"run-as {PKG} sh -c \"printf '{sha}' > files/wave020/source_sha.txt\"", serial=serial)
    adb("shell", f"run-as {PKG} sh -c \"printf '{apk_sha}' > files/wave020/apk_sha256.txt\"", serial=serial)
    adb(
        "shell",
        f"run-as {PKG} sh -c 'printf wave020-cp2-pixel-seal > {TRIGGER}'",
        serial=serial,
    )
    adb(
        "shell",
        "am",
        "start",
        "-W",
        "-n",
        f"{PKG}/{ACTIVITY}",
        "--es",
        "command_line",
        "--wave020-cp2-pixel-seal",
        serial=serial,
        timeout=60,
    )

    timeout_s = int(os.environ.get("WAVE020_CP2_HARNESS_TIMEOUT", "1200"))
    deadline = time.time() + timeout_s
    ready = False
    while time.time() < deadline:
        check = adb("shell", "run-as", PKG, "ls", RESULT_REMOTE.replace("files/", "files/"), serial=serial)
        # ls path relative to app files
        check = adb("shell", "run-as", PKG, "ls", "files/wave020/CP2_PIXEL_PHYSICAL_SEAL_RESULT.json", serial=serial)
        if check.returncode == 0 and "CP2_PIXEL_PHYSICAL_SEAL_RESULT.json" in check.stdout:
            ready = True
            break
        # Also watch for first failure early stop
        fail_check = adb("shell", "run-as", PKG, "ls", "files/wave020/FIRST_FAILURE.json", serial=serial)
        if fail_check.returncode == 0 and "FIRST_FAILURE.json" in fail_check.stdout:
            # wait a bit for final result write
            time.sleep(2.0)
            check2 = adb("shell", "run-as", PKG, "ls", "files/wave020/CP2_PIXEL_PHYSICAL_SEAL_RESULT.json", serial=serial)
            if check2.returncode == 0:
                ready = True
                break
        time.sleep(3.0)

    local_result = ART / "CP2_PIXEL_PHYSICAL_SEAL_RESULT.json"
    if not ready or not pull_file(serial, "wave020/CP2_PIXEL_PHYSICAL_SEAL_RESULT.json", local_result):
        logcat = adb("logcat", "-d", "-t", "300", serial=serial).stdout
        (PIXEL / "cp2_harness_logcat.txt").write_text(logcat)
        pull_file(serial, "wave020/FIRST_FAILURE.json", ART / "CP2_FIRST_FAILURE.json")
        write_summary({
            "WAVE020_CP2_PIXEL_PHYSICAL_SEAL": "FAIL",
            "CP2_SEALED": False,
            "reason": "HARNESS_TIMEOUT_OR_MISSING_RESULT",
            "timeout_s": timeout_s,
            **build,
            "DEVICE_SERIAL": serial,
            "DEVICE_MODEL": device.get("model"),
            "emitted_at": utc_now(),
        })
        return 1

    pull_file(serial, "wave020/FIRST_FAILURE.json", ART / "CP2_FIRST_FAILURE.json")
    # Pull a few victory captures if present
    listing = adb("shell", "run-as", PKG, "ls", "files/wave020/captures", serial=serial)
    if listing.returncode == 0:
        for name in listing.stdout.split():
            name = name.strip()
            if name.endswith(".png"):
                pull_file(serial, f"wave020/captures/{name}", PIXEL / f"cp2_{name}")

    try:
        result = json.loads(local_result.read_text())
    except Exception as exc:
        write_summary({
            "WAVE020_CP2_PIXEL_PHYSICAL_SEAL": "FAIL",
            "CP2_SEALED": False,
            "reason": f"RESULT_PARSE_ERROR:{exc}",
            "emitted_at": utc_now(),
        })
        return 1

    sealed = bool(result.get("CP2_SEALED", False))
    summary = {
        "WAVE020_CP2_PIXEL_PHYSICAL_SEAL": "PASS" if sealed else "FAIL",
        "CP2_SEALED": sealed,
        **build,
        "DEVICE_SERIAL": serial,
        "DEVICE_MODEL": device.get("model"),
        "AA_ONLY_GUARDS": True,
        "SETTINGS_UI_USED": False,
        "PERMISSION_GRANT_METHOD": "adb_pm_grant",
        "harness": result,
        "emitted_at": utc_now(),
    }
    # Flatten key counters for report convenience
    for k in (
        "PIXEL_SELECT_CARDS_CANONICAL_CURRENT_COUNT",
        "PIXEL_SELECT_PREVIEWS_CANONICAL_CURRENT_COUNT",
        "PIXEL_SELECT_LEGACY_CARD_OCCURRENCES",
        "PIXEL_SELECT_LEGACY_PREVIEW_OCCURRENCES",
        "PIXEL_SELECT_WRONG_FIGHTER_OCCURRENCES",
        "PIXEL_BATTLE_BODY_EXPECTED_SAMPLES",
        "PIXEL_BATTLE_BODY_ZERO_SAMPLES",
        "PIXEL_BATTLE_BODY_WRONG_MODEL_SAMPLES",
        "PIXEL_BATTLE_BODY_LEGACY_MODEL_SAMPLES",
        "PIXEL_BATTLE_BODY_DUPLICATE_SAMPLES",
        "PIXEL_BATTLE_VISIBILITY_INVARIANT_VIOLATIONS",
        "PIXEL_BATTLE_FALLBACK_RECOVERIES",
        "PIXEL_SELECT_TO_BATTLE_IDENTITY_MISMATCHES",
        "PAUSE_MENU_CENTERED",
        "PAUSE_MENU_WITHIN_SAFE_AREA",
        "PAUSE_MENU_CONTROLS_REACHABLE",
        "PIXEL_MOVELIST_CLIPPED_CASES",
        "PIXEL_MOVELIST_OFFSCREEN_CASES",
        "PIXEL_MOVELIST_UNREACHABLE_CONTROL_CASES",
        "PIXEL_MOVELIST_SCROLL_FAILURES",
        "PIXEL_PAUSE_MOVELIST_CRASHES",
        "PIXEL_PAUSE_MOVELIST_GHOST_REGRESSIONS",
        "PIXEL_PAUSE_RESUME_STATE_CORRUPTIONS",
        "PIXEL_PAUSE_MOVELIST_STUCK_STATES",
        "PIXEL_MOVE_PREVIEW_CASES",
        "PIXEL_MOVE_PREVIEW_WRONG_MODEL_CASES",
        "PIXEL_MOVE_PREVIEW_LEGACY_MODEL_CASES",
        "PIXEL_MOVE_PREVIEW_MISSING_MODEL_CASES",
        "PIXEL_MOVE_PREVIEW_MAPPING_FAILURES",
        "VICTORY_CANONICAL_CURRENT_COUNT",
        "VICTORY_LEGACY_REPRESENTATION_OCCURRENCES",
        "VICTORY_WRONG_FIGHTER_OCCURRENCES",
        "CONTROLLER_PAUSE_IMPLEMENTED",
        "CONTROLLER_PAUSE_RUNTIME_TESTED",
        "CONTROLLER_PAUSE_RUNTIME_PASS",
    ):
        if k in result:
            summary[k] = result[k]
    if "victory" in result:
        for k, v in result["victory"].items():
            if k.startswith("VICTORY_"):
                summary[k] = v
    if "telemetry" in result:
        summary["telemetry"] = result["telemetry"]
    write_summary(summary)

    # Cleanup trigger so normal launches don't re-run
    adb("shell", f"run-as {PKG} rm -f {TRIGGER}", serial=serial)
    return 0 if sealed else 1


if __name__ == "__main__":
    raise SystemExit(main())
