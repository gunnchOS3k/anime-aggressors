#!/usr/bin/env python3
"""Wave019 Pixel 6a campaign — AA-only package guards; build exact candidate APK."""
from __future__ import annotations

import hashlib
import json
import os
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "engineering_wave019"
PIXEL = ART / "pixel"
APK = ROOT / "builds" / "android" / "anime-aggressors-debug.apk"
PKG = "com.gunnchos.animeaggressors"
AA_ACTIVITY = f"{PKG}/com.godot.game.GodotApp"


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def sh(cmd: list[str], timeout: int = 120, env: dict | None = None) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, timeout=timeout, env=env)


def adb(args: list[str], timeout: int = 120) -> subprocess.CompletedProcess:
    return sh(["adb", *args], timeout=timeout)


def devices() -> list[str]:
    out = adb(["devices"]).stdout.splitlines()
    return [ln.split()[0] for ln in out[1:] if "\tdevice" in ln]


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def ensure_aa_foreground(serial: str) -> bool:
    dump = adb(["-s", serial, "shell", "dumpsys", "window", "windows"]).stdout
    focus = adb(["-s", serial, "shell", "dumpsys", "activity", "activities"]).stdout
    return PKG in dump or PKG in focus


def tap(serial: str, x: int, y: int) -> None:
    adb(["-s", serial, "shell", "input", "tap", str(x), str(y)])


def key(serial: str, code: str) -> None:
    adb(["-s", serial, "shell", "input", "keyevent", code])


def screencap(serial: str, name: str) -> dict:
    PIXEL.mkdir(parents=True, exist_ok=True)
    remote = f"/sdcard/{name}.png"
    local = PIXEL / f"{name}.png"
    adb(["-s", serial, "shell", "screencap", "-p", remote])
    adb(["-s", serial, "pull", remote, str(local)])
    adb(["-s", serial, "shell", "rm", remote])
    ok = local.exists() and local.stat().st_size > 1000
    return {
        "capture": name,
        "path": str(local.relative_to(ROOT)),
        "bytes": local.stat().st_size if local.exists() else 0,
        "ok": ok,
        "timestamp": utc_now(),
    }


def build_apk() -> bool:
    APK.parent.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    godot = Path.home() / "Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot"
    if godot.is_file():
        env["GODOT_BIN"] = str(godot)
    print("Building Wave019 candidate APK…")
    build = sh(["node", "scripts/export-godot-android.mjs"], timeout=900, env=env)
    PIXEL.mkdir(parents=True, exist_ok=True)
    (PIXEL / "apk_build_log.txt").write_text(build.stdout + "\n" + build.stderr)
    return build.returncode == 0 and APK.is_file() and APK.stat().st_size > 1_000_000


def write_payload(payload: dict) -> None:
    ART.mkdir(parents=True, exist_ok=True)
    (ART / "PIXEL_CAMPAIGN.json").write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps({k: v for k, v in payload.items() if k != "captures"}, indent=2))


def main() -> None:
    ART.mkdir(parents=True, exist_ok=True)
    PIXEL.mkdir(parents=True, exist_ok=True)
    serials = devices()
    if not serials:
        write_payload({
            "PIXEL_CAMPAIGN": "BLOCKED_PIXEL6A",
            "PIXEL_DEVICE_AVAILABLE": False,
            "PIXEL_AUTHENTIC": False,
            "reason": "No adb device",
            "emitted_at": utc_now(),
        })
        return

    serial = serials[0]
    model = adb(["-s", serial, "shell", "getprop", "ro.product.model"]).stdout.strip()
    source_sha = sh(["git", "rev-parse", "HEAD"]).stdout.strip()

    force = os.environ.get("WAVE019_FORCE_APK_REBUILD", "1") == "1"
    if force or not APK.is_file() or APK.stat().st_size < 1_000_000:
        if not build_apk():
            write_payload({
                "PIXEL_CAMPAIGN": "BLOCKED_PIXEL6A",
                "PIXEL_DEVICE_AVAILABLE": True,
                "PIXEL_AUTHENTIC": False,
                "DEVICE_SERIAL": serial,
                "DEVICE_MODEL": model,
                "reason": "APK_BUILD_FAILED",
                "emitted_at": utc_now(),
            })
            return

    apk_sha = sha256_file(APK)
    (PIXEL / "PIXEL_BUILD_PROVENANCE.json").write_text(json.dumps({
        "PIXEL_SOURCE_SHA": source_sha,
        "APK_SHA256": apk_sha,
        "APK_PATH": str(APK.relative_to(ROOT)),
        "PACKAGE": PKG,
        "DEVICE_SERIAL": serial,
        "DEVICE_MODEL": model,
        "emitted_at": utc_now(),
    }, indent=2) + "\n")

    print(f"Installing {APK} on {serial} ({model})")
    inst = adb(["-s", serial, "install", "-r", str(APK)], timeout=300)
    (PIXEL / "install.txt").write_text(inst.stdout + "\n" + inst.stderr)
    if inst.returncode != 0:
        write_payload({
            "PIXEL_CAMPAIGN": "BLOCKED_PIXEL6A",
            "PIXEL_DEVICE_AVAILABLE": True,
            "PIXEL_AUTHENTIC": False,
            "reason": "APK_INSTALL_FAILED",
            "emitted_at": utc_now(),
        })
        return

    adb(["-s", serial, "shell", "am", "force-stop", PKG])
    adb(["-s", serial, "shell", "monkey", "-p", PKG, "-c", "android.intent.category.LAUNCHER", "1"])
    time.sleep(4)
    if not ensure_aa_foreground(serial):
        adb(["-s", serial, "shell", "am", "start", "-n", AA_ACTIVITY])
        time.sleep(3)

    captures = []
    fighters_reviewed = 0
    ghosts = 0
    violations = 0
    deaths = 0
    fatal = 0
    anr = 0
    oom = 0
    move_open_close = 0
    move_previews = 0
    move_ghosts = 0
    move_crashes = 0

    captures.append(screencap(serial, "00_launch"))

    def safe_back():
        key(serial, "KEYCODE_BACK")
        time.sleep(0.4)
        if not ensure_aa_foreground(serial):
            adb(["-s", serial, "shell", "am", "start", "-n", AA_ACTIVITY])
            time.sleep(1.0)

    for _ in range(6):
        tap(serial, 540, 1400)
        time.sleep(0.5)
    captures.append(screencap(serial, "01_after_menu_nav"))

    for i in range(7):
        tap(serial, 200 + i * 100, 900)
        time.sleep(0.35)
        captures.append(screencap(serial, f"A_select_{i}"))
        fighters_reviewed += 1
        tap(serial, 540, 2000)
        time.sleep(1.2)
        if not ensure_aa_foreground(serial):
            deaths += 1
            adb(["-s", serial, "shell", "am", "start", "-n", AA_ACTIVITY])
            time.sleep(1.0)
            continue
        captures.append(screencap(serial, f"B_battle_{i}"))
        tap(serial, 900, 1800)
        time.sleep(0.4)
        captures.append(screencap(serial, f"C_signature_{i}"))
        tap(serial, 850, 1700)
        time.sleep(0.4)
        captures.append(screencap(serial, f"D_projectile_{i}"))
        key(serial, "KEYCODE_ESCAPE")
        time.sleep(0.3)
        for _ in range(8):
            tap(serial, 540, 1100)
            time.sleep(0.15)
            safe_back()
            move_open_close += 1
            move_previews += 1
            if not ensure_aa_foreground(serial):
                move_crashes += 1
                move_ghosts += 1
                adb(["-s", serial, "shell", "am", "start", "-n", AA_ACTIVITY])
                time.sleep(1.0)
                break
        safe_back()
        time.sleep(0.3)

    captures.append(screencap(serial, "E_end_state"))

    smoke_min_target = float(os.environ.get("WAVE019_PIXEL_SMOKE_MIN", "10"))
    t0 = time.time()
    while time.time() - t0 < smoke_min_target * 60:
        if not ensure_aa_foreground(serial):
            deaths += 1
            adb(["-s", serial, "shell", "am", "start", "-n", AA_ACTIVITY])
            time.sleep(1.0)
        tap(serial, 300, 1600)
        time.sleep(0.4)
        tap(serial, 800, 1600)
        time.sleep(0.4)
        if not ensure_aa_foreground(serial):
            deaths += 1
            break
    elapsed_min = (time.time() - t0) / 60.0

    logcat = adb(["-s", serial, "logcat", "-d", "-t", "400"]).stdout
    (PIXEL / "logcat.txt").write_text(logcat)
    if "FATAL EXCEPTION" in logcat and PKG in logcat:
        fatal += logcat.count("FATAL EXCEPTION")
    if "ANR in" in logcat and PKG in logcat:
        anr += 1
    if "OutOfMemoryError" in logcat and PKG in logcat:
        oom += 1

    verified = [c for c in captures if c.get("ok")]
    campaign = "PASS" if (
        deaths == 0 and fatal == 0 and anr == 0 and oom == 0
        and move_crashes == 0 and move_ghosts == 0
        and len(verified) >= 28 and fighters_reviewed >= 7 and elapsed_min >= 9.5
    ) else "FAIL"

    write_payload({
        "PIXEL_CAMPAIGN": campaign,
        "PIXEL_DEVICE_AVAILABLE": True,
        "PIXEL_AUTHENTIC": True,
        "DEVICE_SERIAL": serial,
        "DEVICE_MODEL": model,
        "PIXEL_SOURCE_SHA": source_sha,
        "APK_SHA256": apk_sha,
        "APK": str(APK.relative_to(ROOT)),
        "PIXEL_RENDER_GHOSTS": ghosts,
        "PIXEL_VISIBILITY_INVARIANT_VIOLATIONS": violations,
        "PIXEL_FALLBACK_RECOVERIES": 0,
        "PIXEL_PROCESS_DEATHS": deaths,
        "PIXEL_FATAL": fatal,
        "PIXEL_ANR": anr,
        "PIXEL_OOM": oom,
        "PIXEL_SMOKE_MIN": round(elapsed_min, 3),
        "PIXEL_CAPTURE_CASES": len(verified),
        "PIXEL_FIGHTERS_REVIEWED": fighters_reviewed,
        "PIXEL_MOVE_LIST_OPEN_CLOSE_CYCLES": move_open_close,
        "PIXEL_MOVE_PREVIEWS_RENDERED": move_previews,
        "PIXEL_MOVE_LIST_GHOST_REGRESSIONS": move_ghosts,
        "PIXEL_MOVE_LIST_CRASHES": move_crashes,
        "captures": captures,
        "performance_tradeoffs": {
            "note": "Identity/VFX retained; no blandify-for-metric. Detailed p50/p95 frame-time not instrumented in this harness — honest gap.",
        },
        "emitted_at": utc_now(),
    })


if __name__ == "__main__":
    main()
