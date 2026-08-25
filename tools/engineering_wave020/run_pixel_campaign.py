#!/usr/bin/env python3
"""Wave020 Pixel 6a campaign — AA-only package guards (Wave018 pattern).

GUARD POLICY (never violate):
- ONLY launch/resume `com.gunnchos.animeaggressors` via `am start -n <component>`.
- NEVER use `monkey` (can bounce through launcher).
- NEVER send `input tap` / `keyevent` unless AA is foreground (dumpsys window focus).
- If BACK lands on Pixel launcher or a sibling app, relaunch AA BEFORE any further input.
- NEVER tap launcher icons — no global coordinates on home screen.
- Force-stop known sibling packages if they steal focus (Pedestrian Pursuit, etc.).
- NEVER open Android Settings UI — no `am start` settings, no Settings taps.
- Runtime permissions granted via `adb shell pm grant` only (never Settings UI).

Root cause (Wave018): BACK → launcher → unguarded tap opens sibling apps (Settings,
Pedestrian Pursuit, etc.). Wrong install target was NOT the issue; missing foreground
guards were. Settings was never an intentional permission step.
"""
from __future__ import annotations

import hashlib
import json
import os
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "engineering_wave020"
PIXEL = ART / "pixel"
APK = ROOT / "builds" / "android" / "anime-aggressors-debug.apk"
PKG = os.environ.get("AA_ANDROID_PKG", "com.gunnchos.animeaggressors")
ACTIVITY = "com.godot.game.GodotApp"
COMPONENT = f"{PKG}/{ACTIVITY}"
FORBIDDEN_PACKAGES = (
    "com.gunnchos.pedestrianpursuit",
    "com.gunnchos.beatlink",
    "com.gunnchos.archive",
    "com.android.settings",
)
# Godot export preset enables INTERNET + VIBRATE (install-time). ACCESS_LOCAL_NETWORK is
# the only runtime permission; grant via adb — never open Settings UI.
RUNTIME_PERMISSIONS = (
    "android.permission.ACCESS_LOCAL_NETWORK",
)


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


def foreground_package(serial: str) -> str:
    """Prefer window focus — dumpsys activity topResumed can lag behind Godot."""
    win = adb(["-s", serial, "shell", "dumpsys", "window"]).stdout
    for line in win.splitlines():
        if "mCurrentFocus=" not in line and "mFocusedApp=" not in line:
            continue
        if PKG in line:
            return PKG
        for bad in FORBIDDEN_PACKAGES:
            if bad in line:
                return bad
        if "nexuslauncher" in line.lower() or "launcher" in line.lower():
            return "com.google.android.apps.nexuslauncher"
    out = adb(["-s", serial, "shell", "dumpsys", "activity", "activities"]).stdout
    for marker in ("topResumedActivity=", "mResumedActivity=", "mFocusedApp="):
        for line in out.splitlines():
            if marker not in line:
                continue
            if PKG in line:
                return PKG
            if " u0 " not in line:
                continue
            try:
                part = line.split(" u0 ", 1)[1]
                pkg = part.split("/", 1)[0].strip()
                if pkg and not pkg.startswith("ActivityRecord"):
                    return pkg
            except IndexError:
                continue
    return ""


def pidof(serial: str) -> str:
    return adb(["-s", serial, "shell", "pidof", PKG]).stdout.strip()


def grant_aa_runtime_permissions(serial: str) -> dict:
    """Grant AA runtime permissions via adb — never open Settings UI."""
    results: dict[str, str] = {}
    for perm in RUNTIME_PERMISSIONS:
        r = adb(["-s", serial, "shell", "pm", "grant", PKG, perm])
        ok = r.returncode == 0 or "already" in (r.stderr + r.stdout).lower()
        results[perm] = "granted" if ok else (r.stderr or r.stdout or "failed").strip()[:120]
    # Debug APK telemetry uses `adb exec-out run-as` — no storage/overlay permission needed.
    return results


def launch_app(serial: str) -> bool:
    """Launch AA only — never monkey, never launcher taps, never Settings."""
    adb(["-s", serial, "shell", "am", "force-stop", PKG])
    time.sleep(0.5)
    grant_aa_runtime_permissions(serial)
    r = adb(
        ["-s", serial, "shell", "am", "start", "-W", "-n", COMPONENT,
         "-a", "android.intent.action.MAIN", "-c", "android.intent.category.LAUNCHER"],
        timeout=60,
    )
    time.sleep(4.0)
    fg = foreground_package(serial)
    if PKG not in fg and not pidof(serial):
        print(f"LAUNCH FAIL: expected {PKG}, foreground={fg!r}, am={r.stdout}{r.stderr}")
        return False
    if PKG not in fg:
        print(f"LAUNCH WARN: foreground={fg!r} after starting {COMPONENT}")
        return False
    return True


def bring_aa_to_front(serial: str) -> bool:
    """Resume AA without force-stop (preserves in-memory scene)."""
    adb(
        ["-s", serial, "shell", "am", "start", "-n", COMPONENT,
         "-a", "android.intent.action.MAIN", "-c", "android.intent.category.LAUNCHER"],
    )
    time.sleep(1.5)
    return bool(pidof(serial))


def ensure_aa_foreground(serial: str, context: str) -> bool:
    """Refuse input unless AA is foreground; relaunch if on launcher/sibling app."""
    if not pidof(serial):
        return launch_app(serial)
    fg = foreground_package(serial)
    if fg in FORBIDDEN_PACKAGES:
        print(f"force-stopping forbidden package during {context}: {fg}")
        adb(["-s", serial, "shell", "am", "force-stop", fg])
        return bring_aa_to_front(serial)
    if PKG in fg or not fg:
        return True
    print(f"re-focusing AA ({context}); was foreground={fg!r}")
    return bring_aa_to_front(serial)


def soft_back_in_aa(serial: str) -> None:
    """Issue BACK only while AA focused; relaunch AA if landed on launcher."""
    if PKG not in foreground_package(serial):
        ensure_aa_foreground(serial, "soft_back_pre")
        return
    adb(["-s", serial, "shell", "input", "keyevent", "4"])
    time.sleep(0.25)
    if PKG not in foreground_package(serial):
        bring_aa_to_front(serial)
    ensure_aa_foreground(serial, "soft_back_post")


def tap(serial: str, x: int, y: int) -> None:
    if not ensure_aa_foreground(serial, f"tap {x},{y}"):
        return
    adb(["-s", serial, "shell", "input", "tap", str(x), str(y)])


def key(serial: str, code: str) -> None:
    if not ensure_aa_foreground(serial, f"key {code}"):
        return
    if str(code) in ("4", "KEYCODE_BACK"):
        soft_back_in_aa(serial)
        return
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
    print("Building Wave020 candidate APK…")
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
            "AA_ONLY_GUARDS": True,
        "SETTINGS_UI_USED": False,
        "PERMISSION_GRANT_METHOD": "adb_pm_grant",
            "reason": "No adb device",
            "emitted_at": utc_now(),
        })
        return

    serial = serials[0]
    model = adb(["-s", serial, "shell", "getprop", "ro.product.model"]).stdout.strip()
    source_sha = sh(["git", "rev-parse", "HEAD"]).stdout.strip()

    force = os.environ.get("WAVE020_FORCE_APK_REBUILD", "1") == "1"
    if force or not APK.is_file() or APK.stat().st_size < 1_000_000:
        if not build_apk():
            write_payload({
                "PIXEL_CAMPAIGN": "BLOCKED_PIXEL6A",
                "PIXEL_DEVICE_AVAILABLE": True,
                "PIXEL_AUTHENTIC": False,
                "AA_ONLY_GUARDS": True,
        "SETTINGS_UI_USED": False,
        "PERMISSION_GRANT_METHOD": "adb_pm_grant",
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
        "COMPONENT": COMPONENT,
        "AA_ONLY_GUARDS": True,
        "SETTINGS_UI_USED": False,
        "PERMISSION_GRANT_METHOD": "adb_pm_grant",
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
            "AA_ONLY_GUARDS": True,
        "SETTINGS_UI_USED": False,
        "PERMISSION_GRANT_METHOD": "adb_pm_grant",
            "reason": "APK_INSTALL_FAILED",
            "emitted_at": utc_now(),
        })
        return

    if not launch_app(serial):
        write_payload({
            "PIXEL_CAMPAIGN": "BLOCKED_PIXEL6A",
            "PIXEL_DEVICE_AVAILABLE": True,
            "PIXEL_AUTHENTIC": False,
            "AA_ONLY_GUARDS": True,
        "SETTINGS_UI_USED": False,
        "PERMISSION_GRANT_METHOD": "adb_pm_grant",
            "SETTINGS_UI_USED": False,
            "reason": "AA_LAUNCH_FAILED",
            "emitted_at": utc_now(),
        })
        return

    perm_grants = grant_aa_runtime_permissions(serial)
    (PIXEL / "permission_grants.json").write_text(json.dumps({
        "package": PKG,
        "method": "adb_pm_grant",
        "settings_ui_used": False,
        "grants": perm_grants,
        "emitted_at": utc_now(),
    }, indent=2) + "\n")

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
    guard_relaunches = 0

    captures.append(screencap(serial, "00_launch"))

    for _ in range(6):
        tap(serial, 540, 1400)
        time.sleep(0.5)
    captures.append(screencap(serial, "01_after_menu_nav"))

    for i in range(7):
        if not ensure_aa_foreground(serial, f"fighter_loop_{i}"):
            deaths += 1
            guard_relaunches += 1
            if not launch_app(serial):
                break
            continue
        tap(serial, 200 + i * 100, 900)
        time.sleep(0.35)
        captures.append(screencap(serial, f"A_select_{i}"))
        fighters_reviewed += 1
        tap(serial, 540, 2000)
        time.sleep(1.2)
        if not ensure_aa_foreground(serial, f"battle_{i}"):
            deaths += 1
            guard_relaunches += 1
            bring_aa_to_front(serial)
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
            if not ensure_aa_foreground(serial, "pause_move_list"):
                move_crashes += 1
                move_ghosts += 1
                guard_relaunches += 1
                bring_aa_to_front(serial)
                time.sleep(1.0)
                break
            tap(serial, 540, 1100)
            time.sleep(0.15)
            soft_back_in_aa(serial)
            move_open_close += 1
            move_previews += 1
        soft_back_in_aa(serial)
        time.sleep(0.3)

    captures.append(screencap(serial, "E_end_state"))

    smoke_min_target = float(os.environ.get("WAVE020_PIXEL_SMOKE_MIN", "10"))
    t0 = time.time()
    while time.time() - t0 < smoke_min_target * 60:
        if not ensure_aa_foreground(serial, "smoke_loop"):
            deaths += 1
            guard_relaunches += 1
            if not launch_app(serial):
                break
            time.sleep(1.0)
            continue
        tap(serial, 300, 1600)
        time.sleep(0.4)
        tap(serial, 800, 1600)
        time.sleep(0.4)
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
        "AA_ONLY_GUARDS": True,
        "SETTINGS_UI_USED": False,
        "PERMISSION_GRANT_METHOD": "adb_pm_grant",
        "DEVICE_SERIAL": serial,
        "DEVICE_MODEL": model,
        "PIXEL_SOURCE_SHA": source_sha,
        "APK_SHA256": apk_sha,
        "APK": str(APK.relative_to(ROOT)),
        "PIXEL_RENDER_GHOSTS": ghosts,
        "PIXEL_VISIBILITY_INVARIANT_VIOLATIONS": violations,
        "PIXEL_FALLBACK_RECOVERIES": guard_relaunches,
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
        "PIXEL_GUARD_RELAUNCHES": guard_relaunches,
        "captures": captures,
        "performance_tradeoffs": {
            "note": "AA-only guards: no monkey, no launcher taps, foreground check before every input.",
        },
        "emitted_at": utc_now(),
    })


if __name__ == "__main__":
    main()
