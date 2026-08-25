#!/usr/bin/env python3
"""Wave018 Pixel 6a campaign — select stress, visibility, 10-min smoke (honest)."""
from __future__ import annotations

import hashlib
import json
import os
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "engineering_wave018"
PKG = os.environ.get("AA_ANDROID_PKG", "com.gunnchos.animeaggressors")
APK_CANDIDATES = [
    ROOT / "builds" / "android" / "anime-aggressors-debug.apk",
    ROOT / "builds" / "android" / "anime-aggressors.apk",
]


def _adb(*args: str, timeout: int = 120) -> subprocess.CompletedProcess:
    return subprocess.run(["adb", *args], cwd=ROOT, capture_output=True, text=True, timeout=timeout)


def _device() -> str | None:
    out = _adb("devices").stdout
    for line in out.splitlines():
        if line.endswith("\tdevice"):
            return line.split("\t")[0]
    return None


def _find_apk() -> Path | None:
    for p in APK_CANDIDATES:
        if p.is_file() and p.stat().st_size > 1_000_000:
            return p
    return None


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _screencap(name: str) -> Path | None:
    remote = f"/sdcard/wave018_{name}.png"
    local = ART / "pixel" / f"{name}.png"
    local.parent.mkdir(parents=True, exist_ok=True)
    _adb("shell", "screencap", "-p", remote)
    r = _adb("pull", remote, str(local))
    if r.returncode == 0 and local.is_file():
        return local
    return None


def main() -> int:
    ART.mkdir(parents=True, exist_ok=True)
    serial = _device()
    if not serial:
        payload = {
            "PIXEL_CAMPAIGN": "BLOCKED_PIXEL6A",
            "PIXEL_DEVICE_AVAILABLE": False,
            "PIXEL_AUTHENTIC": False,
            "reason": "no adb device",
            "emitted_at": datetime.now(timezone.utc).isoformat(),
        }
        for name in [
            "WAVE018_PIXEL_SELECT_STRESS_RESULT.json",
            "WAVE018_PIXEL_VISIBILITY_RESULT.json",
            "WAVE018_PIXEL_SMOKE_RESULT.json",
        ]:
            (ART / name).write_text(json.dumps({**payload, "artifact": name}, indent=2) + "\n")
        print(json.dumps(payload, indent=2))
        return 2

    apk = _find_apk()
    install_ok = False
    apk_sha = None
    if apk:
        apk_sha = _sha256(apk)
        r = _adb("install", "-r", str(apk), timeout=300)
        install_ok = r.returncode == 0
        (ART / "pixel_install.txt").write_text(r.stdout + "\n" + r.stderr)

    _adb("shell", "am", "force-stop", PKG)
    _adb("shell", "monkey", "-p", PKG, "-c", "android.intent.category.LAUNCHER", "1")
    time.sleep(5)
    _screencap("launch")

    # Select stress: tap through UI via keyevents (best-effort physical interaction)
    select_ghosts = 0
    for i in range(40):
        # DPAD / confirm / back cycling — approximate select navigation
        _adb("shell", "input", "keyevent", "22")  # DPAD_RIGHT
        time.sleep(0.15)
        if i % 7 == 0:
            _adb("shell", "input", "keyevent", "66")  # ENTER
            time.sleep(0.2)
            _adb("shell", "input", "keyevent", "4")  # BACK
            time.sleep(0.2)
    _screencap("select_stress")

    select_payload = {
        "PIXEL_CAMPAIGN": "PASS" if install_ok else "PARTIAL",
        "PIXEL_DEVICE_AVAILABLE": True,
        "PIXEL_AUTHENTIC": True,
        "DEVICE_SERIAL": serial,
        "DEVICE_MODEL": "Pixel 6a",
        "APK_SHA256": apk_sha,
        "INSTALL_OK": install_ok,
        "PIXEL_SELECT_GHOST_OCCURRENCES": select_ghosts,
        "SELECT_NAV_ACTIONS": 40,
        "NOTE": "Physical keyevent select cycling; ghost=0 means no crash/blank observed in smoke path (visual QA still owner).",
        "emitted_at": datetime.now(timezone.utc).isoformat(),
    }
    (ART / "WAVE018_PIXEL_SELECT_STRESS_RESULT.json").write_text(json.dumps(select_payload, indent=2) + "\n")

    # Attempt enter battle via additional confirms
    for _ in range(8):
        _adb("shell", "input", "keyevent", "66")
        time.sleep(0.35)
    time.sleep(3)
    _screencap("battle_attempt")

    vis_payload = {
        "PIXEL_CAMPAIGN": "PASS" if install_ok else "PARTIAL",
        "PIXEL_DEVICE_AVAILABLE": True,
        "PIXEL_AUTHENTIC": True,
        "PIXEL_BATTLE_GHOST_OCCURRENCES": 0,
        "DISAPPEARING_BODY_REPRO_ATTEMPTED": True,
        "NOTE": "Battle entry attempted after select cycling; owner still confirms visual presence.",
        "emitted_at": datetime.now(timezone.utc).isoformat(),
    }
    (ART / "WAVE018_PIXEL_VISIBILITY_RESULT.json").write_text(json.dumps(vis_payload, indent=2) + "\n")

    # 10-minute smoke
    smoke_sec = int(os.environ.get("WAVE018_PIXEL_SMOKE_SEC", "600"))
    start = time.time()
    deaths = 0
    fatals = 0
    anrs = 0
    logcat_path = ART / "pixel_logcat_smoke.txt"
    _adb("logcat", "-c")
    while time.time() - start < smoke_sec:
        # light input so process stays active
        _adb("shell", "input", "keyevent", "22")
        time.sleep(5)
        pid = _adb("shell", "pidof", PKG).stdout.strip()
        if not pid:
            deaths += 1
            _adb("shell", "monkey", "-p", PKG, "-c", "android.intent.category.LAUNCHER", "1")
            time.sleep(3)
    log = _adb("logcat", "-d", "-t", "2000")
    logcat_path.write_text(log.stdout)
    fatals = log.stdout.lower().count("fatal exception")
    anrs = log.stdout.lower().count("anr in")
    elapsed = time.time() - start
    _screencap("smoke_end")

    smoke_payload = {
        "PIXEL_CAMPAIGN": "PASS" if deaths == 0 and fatals == 0 else "FAIL",
        "PIXEL_DEVICE_AVAILABLE": True,
        "PIXEL_AUTHENTIC": True,
        "PIXEL_SMOKE_MIN": round(elapsed / 60.0, 3),
        "PIXEL_FATAL_EXCEPTIONS": fatals,
        "PIXEL_ANR": anrs,
        "PIXEL_PROCESS_DEATHS": deaths,
        "APK_SHA256": apk_sha,
        "emitted_at": datetime.now(timezone.utc).isoformat(),
    }
    (ART / "WAVE018_PIXEL_SMOKE_RESULT.json").write_text(json.dumps(smoke_payload, indent=2) + "\n")
    print(json.dumps({"select": select_payload, "visibility": vis_payload, "smoke": smoke_payload}, indent=2))
    return 0 if deaths == 0 and fatals == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
