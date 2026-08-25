#!/usr/bin/env python3
"""Wave018 Pixel 6a campaign — select stress, visibility, 10-min smoke (authentic)."""
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
PIXEL = ART / "pixel"
PKG = os.environ.get("AA_ANDROID_PKG", "com.gunnchos.animeaggressors")
ACTIVITY = "com.godot.game.GodotApp"
COMPONENT = f"{PKG}/{ACTIVITY}"
APK = ROOT / "builds" / "android" / "anime-aggressors-debug.apk"
# Hard deny-list: never launch / never send input while these are focused.
FORBIDDEN_PACKAGES = (
    "com.gunnchos.pedestrianpursuit",
    "com.gunnchos.beatlink",
    "com.gunnchos.archive",
)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def sha256_file(path: Path) -> str:
    if not path.is_file():
        return ""
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def git_sha() -> str:
    return subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()


def adb(*args: str, timeout: int = 180) -> subprocess.CompletedProcess:
    return subprocess.run(["adb", *args], cwd=ROOT, capture_output=True, text=True, timeout=timeout)


def adb_authorized() -> bool:
    raw = adb("devices").stdout
    for ln in raw.splitlines()[1:]:
        parts = ln.split()
        if len(parts) >= 2 and parts[1] == "device":
            return True
    return False



def discover_pixel6a() -> dict:
    subprocess.run(["adb", "start-server"], capture_output=True, text=True)
    raw = adb("devices", "-l").stdout
    lines = [ln for ln in raw.splitlines()[1:] if ln.strip()]
    auth = [ln for ln in lines if len(ln.split()) >= 2 and ln.split()[1] == "device"]
    unauth = [ln for ln in lines if "unauthorized" in ln]
    if not auth:
        return {
            "ok": False,
            "reason": "BLOCKED_PIXEL6A",
            "detail": "unauthorized" if unauth else "no adb device",
            "raw": raw,
        }
    serial = auth[0].split()[0]
    model = adb("shell", "getprop", "ro.product.model").stdout.strip()
    if "Pixel 6a" not in model and "Pixel_6a" not in raw:
        # Accept bluejay product as Pixel 6a when model prop is Pixel 6a
        if "bluejay" not in raw and "Pixel 6a" not in model:
            return {"ok": False, "reason": "BLOCKED_WRONG_DEVICE", "model": model, "serial": serial}
    return {"ok": True, "serial": serial, "model": model or "Pixel 6a", "raw": raw}


def write_blocked(reason: str, extra: dict | None = None) -> int:
    payload = {
        "PIXEL_CAMPAIGN": "BLOCKED_PIXEL6A",
        "PIXEL_DEVICE_AVAILABLE": False,
        "PIXEL_AUTHENTIC": False,
        "reason": reason,
        "emitted_at": utc_now(),
    }
    if extra:
        payload.update(extra)
    ART.mkdir(parents=True, exist_ok=True)
    for name in [
        "WAVE018_PIXEL_SELECT_STRESS_RESULT.json",
        "WAVE018_PIXEL_VISIBILITY_RESULT.json",
        "WAVE018_PIXEL_SMOKE_RESULT.json",
    ]:
        (ART / name).write_text(json.dumps({**payload, "artifact": name}, indent=2) + "\n")
    print(json.dumps(payload, indent=2))
    return 2


def screencap(name: str) -> dict:
    PIXEL.mkdir(parents=True, exist_ok=True)
    remote = f"/sdcard/wave018_{name}.png"
    local = PIXEL / f"{name}.png"
    adb("shell", "screencap", "-p", remote)
    r = adb("pull", remote, str(local))
    ok = r.returncode == 0 and local.is_file() and local.stat().st_size > 1000
    return {
        "name": name,
        "path": str(local.relative_to(ROOT)) if ok else None,
        "bytes": local.stat().st_size if ok else 0,
        "ok": ok,
    }


def foreground_package() -> str:
    """Best-effort resumed package; empty if unknown."""
    out = adb(
        "shell",
        "dumpsys",
        "activity",
        "activities",
    ).stdout
    for marker in ("topResumedActivity=", "mResumedActivity=", "mFocusedApp="):
        for line in out.splitlines():
            if marker not in line:
                continue
            # e.g. ... u0 com.gunnchos.animeaggressors/com.godot.game.GodotApp t2}
            if " " not in line:
                continue
            try:
                part = line.split(" u0 ", 1)[1]
                pkg = part.split("/", 1)[0].strip()
                if pkg and not pkg.startswith("ActivityRecord"):
                    return pkg
            except IndexError:
                continue
    return ""


def assert_anime_aggressors_only(*, context: str) -> bool:
    """Refuse to drive the device unless Anime Aggressors owns the foreground."""
    fg = foreground_package()
    if fg in FORBIDDEN_PACKAGES:
        print(f"ABORT input ({context}): forbidden foreground package={fg}")
        adb("shell", "am", "force-stop", fg)
        return False
    if fg and fg != PKG and "nexuslauncher" not in fg and "launcher" not in fg.lower():
        # Unknown non-AA app focused — do not send global input.
        print(f"ABORT input ({context}): unexpected foreground package={fg}")
        return False
    return True


def launch_app() -> bool:
    """Launch ONLY com.gunnchos.animeaggressors. Never monkey. Never other packages."""
    # Stop other known sibling games so they cannot steal focus.
    for bad in FORBIDDEN_PACKAGES:
        adb("shell", "am", "force-stop", bad)
    adb("shell", "am", "force-stop", PKG)
    time.sleep(0.5)
    # Explicit component — never use monkey (monkey can resolve wrong launcher).
    r = adb(
        "shell",
        "am",
        "start",
        "-n",
        COMPONENT,
        "-a",
        "android.intent.action.MAIN",
        "-c",
        "android.intent.category.LAUNCHER",
    )
    time.sleep(4.0)
    fg = foreground_package()
    if PKG not in fg and not pidof():
        print(f"LAUNCH FAIL: expected {PKG}, foreground={fg!r}, am_start={r.stdout}{r.stderr}")
        return False
    if fg and PKG not in fg:
        print(f"LAUNCH WARN: foreground={fg!r} after starting {COMPONENT}")
        return False
    return True


def tap(x: int, y: int) -> None:
    if not ensure_aa_foreground(f"tap {x},{y}"):
        return
    adb("shell", "input", "tap", str(x), str(y))


def key(code: str) -> None:
    if not ensure_aa_foreground(f"key {code}"):
        return
    adb("shell", "input", "keyevent", code)


def ensure_aa_foreground(context: str) -> bool:
    """Bring AA to front if needed; never drive other apps."""
    if not pidof():
        return launch_app()
    fg = foreground_package()
    if fg in FORBIDDEN_PACKAGES:
        print(f"force-stopping forbidden package during {context}: {fg}")
        adb("shell", "am", "force-stop", fg)
        return launch_app()
    if PKG in fg:
        return True
    # Launcher / other — relaunch AA explicitly instead of sending global input.
    print(f"re-launching AA ({context}); was foreground={fg!r}")
    return launch_app()


def pidof() -> str:
    return adb("shell", "pidof", PKG).stdout.strip()


def main() -> int:
    ART.mkdir(parents=True, exist_ok=True)
    PIXEL.mkdir(parents=True, exist_ok=True)
    disc = discover_pixel6a()
    if not disc.get("ok"):
        return write_blocked(str(disc.get("detail") or disc.get("reason")), {"discover": disc})

    serial = disc["serial"]
    model = disc["model"]
    source_sha = git_sha()

    # Ensure APK exists for this head (rebuild if missing)
    if not APK.is_file() or APK.stat().st_size < 1_000_000:
        print("Rebuilding APK…")
        env = os.environ.copy()
        godot = Path.home() / "Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot"
        if godot.is_file():
            env["GODOT_BIN"] = str(godot)
        build = subprocess.run(
            ["node", "scripts/export-godot-android.mjs"],
            cwd=ROOT,
            env=env,
            capture_output=True,
            text=True,
            timeout=600,
        )
        (PIXEL / "apk_build_log.txt").write_text(build.stdout + "\n" + build.stderr)
        if build.returncode != 0 or not APK.is_file():
            return write_blocked("APK_BUILD_FAILED", {"build_exit": build.returncode})

    apk_sha = sha256_file(APK)
    (PIXEL / "PIXEL_BUILD_PROVENANCE.json").write_text(
        json.dumps(
            {
                "PIXEL_SOURCE_SHA": source_sha,
                "APK_SHA256": apk_sha,
                "APK_PATH": str(APK.relative_to(ROOT)),
                "PACKAGE": PKG,
                "DEVICE_SERIAL": serial,
                "DEVICE_MODEL": model,
                "emitted_at": utc_now(),
            },
            indent=2,
        )
        + "\n"
    )

    print("Installing", APK)
    inst = adb("install", "-r", str(APK), timeout=300)
    (PIXEL / "install.txt").write_text(inst.stdout + "\n" + inst.stderr)
    install_ok = inst.returncode == 0
    if not install_ok:
        return write_blocked("APK_INSTALL_FAILED", {"install": inst.stdout[-500:] + inst.stderr[-500:]})

    # ---- Select preview stress ----
    if not launch_app():
        return write_blocked("LAUNCH_FAILED_WRONG_OR_MISSING_PACKAGE")
    captures = []
    captures.append(screencap("00_launch"))
    select_ghosts = 0
    select_actions = 0
    # Navigate toward fighter select with confirms / dpad
    for i in range(12):
        key("66")  # ENTER
        time.sleep(0.35)
        select_actions += 1
    captures.append(screencap("01_after_menu_nav"))

    # Stress cycle: right/left/confirm/back across roster
    # Prefer in-app BACK only while AA focused; never drive launcher/other apps.
    for i in range(80):
        if not ensure_aa_foreground("select_stress"):
            select_ghosts += 1
            break
        key("22")  # DPAD_RIGHT
        time.sleep(0.12)
        select_actions += 1
        if i % 10 == 0:
            key("21")  # DPAD_LEFT
            time.sleep(0.1)
            select_actions += 1
        if i % 8 == 0:
            key("66")  # confirm
            time.sleep(0.25)
            # Soft cancel: only BACK if still in AA
            if PKG in foreground_package():
                key("4")
                time.sleep(0.25)
                select_actions += 2
            # If BACK dropped us to launcher, immediately reclaim AA
            ensure_aa_foreground("select_stress_after_back")
        if not pidof():
            select_ghosts += 1
            if not launch_app():
                break
    captures.append(screencap("02_select_stress_end"))

    select_payload = {
        "PIXEL_CAMPAIGN": "PASS" if select_ghosts == 0 else "FAIL",
        "PIXEL_DEVICE_AVAILABLE": True,
        "PIXEL_AUTHENTIC": True,
        "DEVICE_SERIAL": serial,
        "DEVICE_MODEL": model,
        "PIXEL_SOURCE_SHA": source_sha,
        "APK_SHA256": apk_sha,
        "INSTALL_OK": install_ok,
        "PIXEL_SELECT_GHOST_OCCURRENCES": select_ghosts,
        "SELECT_NAV_ACTIONS": select_actions,
        "captures": [c for c in captures if c.get("ok")],
        "NOTE": "Physical keyevent select cycling on Pixel 6a; ghost counted as unexpected process death during select path.",
        "emitted_at": utc_now(),
    }
    (ART / "WAVE018_PIXEL_SELECT_STRESS_RESULT.json").write_text(json.dumps(select_payload, indent=2) + "\n")

    # ---- Select-to-battle + disappearing-body repro ----
    battle_ghosts = 0
    for bout in range(6):
        # Confirm through select/stage into battle
        for _ in range(10):
            key("66")
            time.sleep(0.4)
        time.sleep(2.0)
        captures.append(screencap(f"03_battle_attempt_{bout}"))
        if not pidof():
            battle_ghosts += 1
            if not launch_app():
                break
        # Back out toward select for next bout (reclaim AA if we hit launcher)
        for _ in range(4):
            if PKG in foreground_package():
                key("4")
                time.sleep(0.35)
            ensure_aa_foreground("battle_bout_back")
        # Re-cycle a few fighters before next launch
        for _ in range(7):
            key("22")
            time.sleep(0.12)
    captures.append(screencap("04_visibility_end"))

    vis_payload = {
        "PIXEL_CAMPAIGN": "PASS" if battle_ghosts == 0 else "FAIL",
        "PIXEL_DEVICE_AVAILABLE": True,
        "PIXEL_AUTHENTIC": True,
        "DEVICE_SERIAL": serial,
        "DEVICE_MODEL": model,
        "PIXEL_SOURCE_SHA": source_sha,
        "APK_SHA256": apk_sha,
        "PIXEL_BATTLE_GHOST_OCCURRENCES": battle_ghosts,
        "SELECT_TO_BATTLE_ATTEMPTS": 6,
        "DISAPPEARING_BODY_REPRO_ATTEMPTED": True,
        "captures": [c for c in captures if c.get("name", "").startswith("03_") or c.get("name") == "04_visibility_end"],
        "NOTE": "Battle entry after select cycling; process death counted as ghost. Owner still confirms visual body presence from captures.",
        "emitted_at": utc_now(),
    }
    (ART / "WAVE018_PIXEL_VISIBILITY_RESULT.json").write_text(json.dumps(vis_payload, indent=2) + "\n")

    # ---- 10-minute normal play smoke ----
    if not launch_app():
        return write_blocked("LAUNCH_FAILED_BEFORE_SMOKE")
    for _ in range(14):
        key("66")
        time.sleep(0.4)
    time.sleep(2.0)
    adb("logcat", "-c")
    smoke_sec = int(os.environ.get("WAVE018_PIXEL_SMOKE_SEC", "600"))
    start = time.time()
    deaths = 0
    unauthorized_interrupt = False
    while time.time() - start < smoke_sec:
        if not adb_authorized():
            print("SMOKE INTERRUPTED: adb unauthorized mid-campaign")
            unauthorized_interrupt = True
            break
        # Keep AA foreground; count unexpected loss as death but continue full duration.
        if not ensure_aa_foreground("smoke"):
            deaths += 1
            # retry once; never drive other packages
            if not launch_app():
                time.sleep(3.0)
                if not launch_app():
                    # still continue timer honestly; do not send input without AA
                    time.sleep(2.0)
                    continue
            time.sleep(2.0)
            continue
        # Light combat-ish input (AA-only via helpers)
        key("22")
        time.sleep(0.2)
        key("21")
        time.sleep(0.2)
        tap(900, 1900)
        time.sleep(0.8)
        tap(750, 1750)
        time.sleep(1.5)
        if not pidof():
            deaths += 1
            if not launch_app():
                time.sleep(3.0)
                launch_app()
            time.sleep(2.0)
        # periodic capture every ~2 min
        elapsed = time.time() - start
        if int(elapsed) % 120 < 3:
            captures.append(screencap(f"05_smoke_{int(elapsed)}s"))

    log = adb("logcat", "-d", "-t", "4000")
    (PIXEL / "pixel_logcat_smoke.txt").write_text(log.stdout)
    fatals = log.stdout.lower().count("fatal exception")
    anrs = log.stdout.lower().count("anr in")
    elapsed = time.time() - start
    captures.append(screencap("06_smoke_end"))

    smoke_payload = {
        "PIXEL_CAMPAIGN": (
            "BLOCKED_PIXEL6A"
            if unauthorized_interrupt
            else ("PASS" if deaths == 0 and fatals == 0 and elapsed >= smoke_sec * 0.95 else "FAIL")
        ),
        "PIXEL_DEVICE_AVAILABLE": True,
        "PIXEL_AUTHENTIC": True,
        "DEVICE_SERIAL": serial,
        "DEVICE_MODEL": model,
        "PIXEL_SOURCE_SHA": source_sha,
        "APK_SHA256": apk_sha,
        "PIXEL_SMOKE_MIN": round(elapsed / 60.0, 3),
        "PIXEL_FATAL_EXCEPTIONS": fatals,
        "PIXEL_ANR": anrs,
        "PIXEL_PROCESS_DEATHS": deaths,
        "UNAUTHORIZED_INTERRUPT": unauthorized_interrupt,
        "PIXEL_SMOKE_TARGET_SEC": smoke_sec,
        "captures": [c for c in captures if str(c.get("name", "")).startswith("05_") or c.get("name") == "06_smoke_end"],
        "emitted_at": utc_now(),
    }
    (ART / "WAVE018_PIXEL_SMOKE_RESULT.json").write_text(json.dumps(smoke_payload, indent=2) + "\n")

    # Manifest of all authentic captures
    (PIXEL / "CAPTURE_MANIFEST.json").write_text(
        json.dumps(
            {
                "PIXEL_AUTHENTIC": True,
                "DEVICE_MODEL": model,
                "DEVICE_SERIAL": serial,
                "PIXEL_SOURCE_SHA": source_sha,
                "APK_SHA256": apk_sha,
                "captures": [c for c in captures if c.get("ok")],
                "emitted_at": utc_now(),
            },
            indent=2,
        )
        + "\n"
    )

    summary = {
        "select": select_payload,
        "visibility": vis_payload,
        "smoke": smoke_payload,
        "PIXEL_CAMPAIGN": (
            "PASS"
            if select_payload["PIXEL_CAMPAIGN"] == "PASS"
            and vis_payload["PIXEL_CAMPAIGN"] == "PASS"
            and smoke_payload["PIXEL_CAMPAIGN"] == "PASS"
            else "FAIL"
        ),
    }
    (ART / "PIXEL_CAMPAIGN.json").write_text(json.dumps(summary, indent=2) + "\n")
    print(json.dumps(summary, indent=2))
    return 0 if summary["PIXEL_CAMPAIGN"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
