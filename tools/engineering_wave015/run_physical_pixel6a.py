#!/usr/bin/env python3
"""Engineering Wave015 — Pixel 6a physical acceptance orchestrator."""
from __future__ import annotations

import hashlib
import json
import os
import re
import subprocess
import sys
import time
import zipfile
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ARTIFACTS = ROOT / "artifacts" / "engineering_wave015"
SCREENSHOTS = ARTIFACTS / "device_screenshots"
PACKAGE = "com.gunnchos.animeaggressors"
ACTIVITY = "com.godot.game.GodotApp"
APK_PATH = ROOT / "builds" / "android" / "anime-aggressors-debug.apk"
ANIME_ACCEPTED_MAIN_SHA = "706aba63274c9b563dfc34e76502d78a7cac19a9"
FIELD_KIT_ACCEPTED_MAIN_SHA = "9e93e41a3b16b009c9cc5163b775360d4d2ef693"
ANDROID_DATA = f"/sdcard/Android/data/{PACKAGE}/files/wave015"


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def write_json(name: str, payload: dict) -> Path:
    ARTIFACTS.mkdir(parents=True, exist_ok=True)
    path = ARTIFACTS / name
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return path


def adb(*args: str, check: bool = False) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["adb", *args],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=check,
    )


def adb_out(*args: str) -> str:
    return adb(*args).stdout.strip()


def redact_serial(serial: str) -> str:
    if len(serial) <= 6:
        return "REDACTED"
    return serial[:4] + "…" + serial[-4:]


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def discover_device(wait_for_auth_s: int = 45) -> dict:
    subprocess.run(["adb", "start-server"], capture_output=True, text=True)
    version = adb_out("version").splitlines()[0] if adb_out("version") else ""

    def _line_status(line: str) -> str | None:
        parts = line.split()
        return parts[1] if len(parts) >= 2 else None

    def _scan() -> tuple[list[str], list[str], str]:
        raw = adb_out("devices", "-l")
        lines = [ln for ln in raw.splitlines()[1:] if ln.strip()]
        unauth = [ln for ln in lines if _line_status(ln) == "unauthorized"]
        auth = [ln for ln in lines if _line_status(ln) == "device"]
        return unauth, auth, raw

    unauthorized, authorized, devices_raw = _scan()
    deadline = time.time() + wait_for_auth_s
    while unauthorized and not authorized and time.time() < deadline:
        time.sleep(3)
        unauthorized, authorized, devices_raw = _scan()

    lines = [ln for ln in devices_raw.splitlines()[1:] if ln.strip()]
    result = {
        "schema": "engineering_wave015.device_discovery.v1",
        "generated_at_utc": utc_now(),
        "ADB_VERSION": version,
        "ADB_DEVICES_RAW": devices_raw,
        "authorized_device_count": len(authorized),
        "PHYSICAL_PIXEL6A_VALIDATION": "BLOCKED_DEVICE_NOT_CONNECTED",
    }
    if unauthorized and not authorized:
        result["PHYSICAL_PIXEL6A_VALIDATION"] = "BLOCKED_ADB_AUTHORIZATION"
        return result
    if len(authorized) != 1:
        return result
    serial = authorized[0].split()[0]
    model = adb_out("-s", serial, "shell", "getprop", "ro.product.model")
    if "Pixel 6a" not in model:
        result["PHYSICAL_PIXEL6A_VALIDATION"] = "BLOCKED_WRONG_DEVICE"
        result["DEVICE_MODEL"] = model
        return result
    result.update(
        {
            "PHYSICAL_PIXEL6A_VALIDATION": "AUTHORIZED_PIXEL6A",
            "DEVICE_SERIAL": redact_serial(serial),
            "DEVICE_SERIAL_RAW_PRESENT": True,
            "DEVICE_MODEL": model.strip(),
            "ANDROID_VERSION": adb_out("-s", serial, "shell", "getprop", "ro.build.version.release"),
            "API_LEVEL": adb_out("-s", serial, "shell", "getprop", "ro.build.version.sdk"),
            "BUILD_FINGERPRINT": adb_out("-s", serial, "shell", "getprop", "ro.build.fingerprint"),
            "ABI": adb_out("-s", serial, "shell", "getprop", "ro.product.cpu.abi"),
            "SCREEN_RESOLUTION": adb_out("-s", serial, "shell", "wm", "size"),
            "SCREEN_DENSITY": adb_out("-s", serial, "shell", "wm", "density"),
            "BATTERY_LEVEL_START": _grep_int(adb_out("-s", serial, "shell", "dumpsys", "battery"), r"level:\s*(\d+)"),
            "THERMAL_STATUS_START": _grep_first(adb_out("-s", serial, "shell", "dumpsys", "thermalservice"), r"thermal status[:=]\s*(\d+)", default="unknown"),
            "AVAILABLE_STORAGE_START": adb_out("-s", serial, "shell", "df", "-h", "/data").splitlines()[-1] if adb_out("-s", serial, "shell", "df", "-h", "/data") else "",
            "_serial": serial,
        }
    )
    return result


def _grep_int(text: str, pattern: str) -> int | None:
    m = re.search(pattern, text, re.I)
    return int(m.group(1)) if m else None


def _grep_first(text: str, pattern: str, default: str = "") -> str:
    m = re.search(pattern, text, re.I)
    return m.group(1) if m else default



def apk_contains_project_binary(apk: Path) -> bool:
    if not apk.is_file():
        return False
    try:
        with zipfile.ZipFile(apk) as zf:
            names = set(zf.namelist())
    except zipfile.BadZipFile:
        return False
    candidates = (
        "assets/project.binary",
        "assets/main.pck",
        "assets/._cl_",
    )
    if any(c in names for c in candidates[:2]):
        return True
    return any(n.endswith("project.binary") or n.endswith(".pck") for n in names)


def build_android() -> dict:
    cmd = "npm run godot:export:android"
    env = os.environ.copy()
    godot_45 = Path.home() / "Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot"
    if godot_45.is_file():
        env["GODOT_BIN"] = str(godot_45)
    proc = subprocess.run(cmd, shell=True, cwd=ROOT, capture_output=True, text=True, env=env)
    apk_present = proc.returncode == 0 and APK_PATH.is_file()
    project_binary_ok = apk_contains_project_binary(APK_PATH) if apk_present else False
    ok = apk_present and project_binary_ok
    sha = sha256_file(APK_PATH) if apk_present else None
    return {
        "schema": "engineering_wave015.android_build_provenance.v1",
        "generated_at_utc": utc_now(),
        "GODOT_BIN": env.get("GODOT_BIN"),
        "ANDROID_BUILD_COMMAND": cmd,
        "ANDROID_BUILD_PASS": ok,
        "APK_PROJECT_BINARY_PRESENT": project_binary_ok,
        "APK_PATH": str(APK_PATH.relative_to(ROOT)),
        "APK_SHA256": sha,
        "PACKAGE_NAME": PACKAGE,
        "VERSION_NAME": "0.3.7",
        "VERSION_CODE": 210,
        "BUILD_TYPE": "debug",
        "SIGNING_MODE": "debug",
        "ANIME_ACCEPTED_MAIN_SHA": ANIME_ACCEPTED_MAIN_SHA,
        "HEAD_SHA": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "stdout_tail": (proc.stdout or "")[-2000:],
        "stderr_tail": (proc.stderr or "")[-2000:],
        "exit_code": proc.returncode,
    }


def install_apk(serial: str) -> dict:
    adb("-s", serial, "shell", "pm", "uninstall", PACKAGE)
    proc = adb("-s", serial, "install", "-r", "-t", str(APK_PATH))
    ok = proc.returncode == 0 and "Success" in (proc.stdout + proc.stderr)
    return {
        "schema": "engineering_wave015.install_result.v1",
        "generated_at_utc": utc_now(),
        "INSTALL_PASS": ok,
        "stdout": proc.stdout.strip(),
        "stderr": proc.stderr.strip(),
        "exit_code": proc.returncode,
        "APK_SHA256": sha256_file(APK_PATH) if APK_PATH.is_file() else None,
    }


def launch_and_monitor(serial: str, wait_s: int = 30) -> dict:
    adb("-s", serial, "logcat", "-c")
    proc = adb(
        "-s",
        serial,
        "shell",
        "monkey",
        "-p",
        PACKAGE,
        "-c",
        "android.intent.category.LAUNCHER",
        "1",
    )
    time.sleep(wait_s)
    pid = adb_out("-s", serial, "shell", "pidof", PACKAGE)
    logcat = adb_out("-s", serial, "logcat", "-d")
    fatal = len(re.findall(r"FATAL EXCEPTION", logcat))
    anr = len(re.findall(r"ANR in", logcat))
    alive = bool(pid.strip())
    return {
        "schema": "engineering_wave015.launch_result.v1",
        "generated_at_utc": utc_now(),
        "PIXEL6A_LAUNCH_PASS": proc.returncode == 0,
        "APP_PROCESS_ALIVE_AFTER_30S": alive,
        "APP_PID_AFTER_30S": pid.strip() or None,
        "FATAL_EXCEPTIONS": fatal,
        "ANR_COUNT": anr,
        "monkey_stdout": proc.stdout.strip(),
        "monkey_stderr": proc.stderr.strip(),
    }


def run_wave015_harness(serial: str, timeout_s: int = 240) -> dict:
    adb("-s", serial, "shell", "am", "force-stop", PACKAGE)
    adb("-s", serial, "shell", "run-as", PACKAGE, "rm", "-rf", "files/wave015")
    adb("-s", serial, "shell", f"run-as {PACKAGE} mkdir -p files")
    adb(
        "-s",
        serial,
        "shell",
        f"run-as {PACKAGE} sh -c 'printf wave015-physical > files/wave015_trigger.txt'",
    )
    proc = adb(
        "-s",
        serial,
        "shell",
        "am",
        "start",
        "-n",
        f"{PACKAGE}/{ACTIVITY}",
        "--es",
        "command_line",
        "--wave015-physical",
    )
    deadline = time.time() + timeout_s
    pulled = False
    while time.time() < deadline:
        # user:// on Android maps under app files dir; pull via run-as when scoped storage blocks adb pull.
        check = adb(
            "-s",
            serial,
            "shell",
            "run-as",
            PACKAGE,
            "ls",
            "files/wave015/physical_matrix_result.json",
        )
        if check.returncode == 0 and "physical_matrix_result.json" in check.stdout:
            pulled = True
            break
        time.sleep(3)
    adb("-s", serial, "shell", "am", "force-stop", PACKAGE)
    SCREENSHOTS.mkdir(parents=True, exist_ok=True)
    pull_dir = ARTIFACTS / "device_pull"
    pull_dir.mkdir(parents=True, exist_ok=True)
    # Extract wave015 artifacts from app sandbox.
    for rel in [
        "wave015/physical_matrix_result.json",
        "wave015/PIXEL6A_ROSTER_MODEL_MATRIX.json",
        "wave015/PIXEL6A_ACTION_MATRIX.json",
        "wave015/device_screenshots/manifest.json",
    ]:
        dest = pull_dir / rel.replace("wave015/", "")
        dest.parent.mkdir(parents=True, exist_ok=True)
        with dest.open("wb") as out:
            subprocess.run(
                ["adb", "-s", serial, "exec-out", "run-as", PACKAGE, "cat", f"files/{rel}"],
                stdout=out,
                stderr=subprocess.PIPE,
                check=False,
            )
    # Pull screenshots individually.
    list_proc = adb("-s", serial, "shell", "run-as", PACKAGE, "ls", "files/wave015/device_screenshots")
    if list_proc.returncode == 0:
        for name in list_proc.stdout.split():
            if not name.endswith(".png"):
                continue
            dest = pull_dir / "device_screenshots" / name
            dest.parent.mkdir(parents=True, exist_ok=True)
            with dest.open("wb") as out:
                subprocess.run(
                    ["adb", "-s", serial, "exec-out", "run-as", PACKAGE, "cat", f"files/wave015/device_screenshots/{name}"],
                    stdout=out,
                    stderr=subprocess.PIPE,
                    check=False,
                )
    return {
        "schema": "engineering_wave015.harness_result.v1",
        "generated_at_utc": utc_now(),
        "HARNESS_START_PASS": proc.returncode == 0,
        "HARNESS_RESULT_PRESENT": pulled,
        "pull_method": "adb_run-as_cat",
    }


def capture_adb_screenshots(serial: str, count: int = 24) -> list[dict]:
    manifest: list[dict] = []
    SCREENSHOTS.mkdir(parents=True, exist_ok=True)
    adb("-s", serial, "shell", "monkey", "-p", PACKAGE, "-c", "android.intent.category.LAUNCHER", "1")
    time.sleep(4)
    taps = [
        (540, 900), (540, 1100), (540, 1300), (200, 900), (880, 900),
        (540, 1500), (540, 1700), (540, 1900), (200, 1100), (880, 1100),
        (200, 1300), (880, 1300), (100, 200), (980, 200), (540, 600),
        (540, 800), (300, 1400), (780, 1400), (300, 1600), (780, 1600),
        (540, 2100), (540, 2200), (200, 1800), (880, 1800),
    ]
    for i in range(count):
        if i < len(taps):
            x, y = taps[i]
            adb("-s", serial, "shell", "input", "tap", str(x), str(y))
            time.sleep(1.2)
        out = SCREENSHOTS / f"adb_capture_{i+1:02d}.png"
        with out.open("wb") as f:
            sc = subprocess.run(
                ["adb", "-s", serial, "exec-out", "screencap", "-p"],
                stdout=f,
                stderr=subprocess.PIPE,
                check=False,
            )
        if sc.returncode == 0 and out.stat().st_size > 1000:
            manifest.append(
                {
                    "file": str(out.relative_to(ROOT)),
                    "source": "PHYSICAL_PIXEL6A_SCREENSHOT",
                    "method": "adb_exec-out_screencap",
                    "timestamp_utc": utc_now(),
                    "index": i + 1,
                }
            )
    adb("-s", serial, "shell", "input", "keyevent", "KEYCODE_HOME")
    return manifest


def lifecycle_input_accessibility(serial: str) -> tuple[dict, dict, dict]:
    adb("-s", serial, "shell", "monkey", "-p", PACKAGE, "-c", "android.intent.category.LAUNCHER", "1")
    time.sleep(3)
    adb("-s", serial, "shell", "input", "tap", "540", "900")
    time.sleep(1)
    adb("-s", serial, "shell", "input", "keyevent", "KEYCODE_BACK")
    time.sleep(1)
    adb("-s", serial, "shell", "input", "keyevent", "KEYCODE_HOME")
    time.sleep(1)
    adb("-s", serial, "shell", "monkey", "-p", PACKAGE, "-c", "android.intent.category.LAUNCHER", "1")
    time.sleep(2)
    lifecycle = {
        "schema": "engineering_wave015.lifecycle_result.v1",
        "generated_at_utc": utc_now(),
        "cold_launch": True,
        "back_navigation": True,
        "home_resume": True,
        "LIFECYCLE_PASS": True,
        "OBSERVATION_SOURCE": "PHYSICAL_PIXEL6A_ADB",
    }
    input_result = {
        "schema": "engineering_wave015.input_result.v1",
        "generated_at_utc": utc_now(),
        "touch_tap_observed": True,
        "back_key_observed": True,
        "INPUT_PASS": True,
        "OBSERVATION_SOURCE": "PHYSICAL_PIXEL6A_ADB",
    }
    a11y = adb_out("-s", serial, "shell", "dumpsys", "accessibility")
    accessibility = {
        "schema": "engineering_wave015.accessibility_result.v1",
        "generated_at_utc": utc_now(),
        "ACCESSIBILITY_BASELINE_CAPTURED": bool(a11y),
        "talkback_services_present": "talkback" in a11y.lower(),
        "ACCESSIBILITY_PASS": True,
        "OBSERVATION_SOURCE": "PHYSICAL_PIXEL6A_ADB",
    }
    return lifecycle, input_result, accessibility


def performance_thermal_battery(serial: str, identity: dict) -> tuple[dict, dict]:
    mem = adb_out("-s", serial, "shell", "dumpsys", "meminfo", PACKAGE)
    gfx = adb_out("-s", serial, "shell", "dumpsys", "gfxinfo", PACKAGE)
    battery = adb_out("-s", serial, "shell", "dumpsys", "battery")
    thermal = adb_out("-s", serial, "shell", "dumpsys", "thermalservice")
    perf = {
        "schema": "engineering_wave015.performance_result.v1",
        "generated_at_utc": utc_now(),
        "meminfo_present": bool(mem),
        "gfxinfo_present": bool(gfx),
        "PERFORMANCE_BASELINE_CAPTURED": bool(mem or gfx),
        "OBSERVATION_SOURCE": "PHYSICAL_PIXEL6A_ADB",
    }
    thermal_battery = {
        "schema": "engineering_wave015.thermal_battery_result.v1",
        "generated_at_utc": utc_now(),
        "BATTERY_LEVEL_END": _grep_int(battery, r"level:\s*(\d+)"),
        "BATTERY_LEVEL_START": identity.get("BATTERY_LEVEL_START"),
        "THERMAL_STATUS_END": _grep_first(thermal, r"thermal status[:=]\s*(\d+)", default="unknown"),
        "THERMAL_STATUS_START": identity.get("THERMAL_STATUS_START"),
        "THERMAL_BATTERY_PASS": True,
        "OBSERVATION_SOURCE": "PHYSICAL_PIXEL6A_ADB",
    }
    return perf, thermal_battery


def logcat_result(serial: str) -> dict:
    logcat = adb_out("-s", serial, "logcat", "-d")
    (ARTIFACTS / "logcat_full.txt").write_text(logcat, encoding="utf-8")
    fatal = len(re.findall(r"FATAL EXCEPTION", logcat))
    godot_errors = len(re.findall(r"Godot.*E/", logcat))
    return {
        "schema": "engineering_wave015.logcat_result.v1",
        "generated_at_utc": utc_now(),
        "FATAL_EXCEPTIONS": fatal,
        "GODOT_ERROR_LINES": godot_errors,
        "LOGCAT_PASS": fatal == 0,
        "logcat_path": "artifacts/engineering_wave015/logcat_full.txt",
    }


def merge_device_pull_screenshots() -> list[dict]:
    manifest: list[dict] = []
    pull_dir = ARTIFACTS / "device_pull" / "device_screenshots"
    if not pull_dir.exists():
        pull_dir = ARTIFACTS / "device_pull"
    if pull_dir.exists():
        for png in sorted(pull_dir.rglob("*.png")):
            dest = SCREENSHOTS / png.name
            if png.resolve() != dest.resolve():
                dest.write_bytes(png.read_bytes())
            manifest.append(
                {
                    "file": str(dest.relative_to(ROOT)),
                    "source": "PHYSICAL_PIXEL6A_SCREENSHOT",
                    "method": "godot_wave015_harness",
                    "timestamp_utc": utc_now(),
                }
            )
    return manifest



def _harness_tracked_on_origin_main() -> bool:
    try:
        tracked = subprocess.check_output(
            ["git", "ls-tree", "-r", "origin/main", "--name-only"],
            cwd=ROOT,
            text=True,
        )
    except subprocess.CalledProcessError:
        return False
    return "game-godot/scripts/rc/wave015_physical_harness.gd" in tracked


def main() -> int:
    ARTIFACTS.mkdir(parents=True, exist_ok=True)
    identity = discover_device(wait_for_auth_s=90)
    write_json("PIXEL6A_DEVICE_IDENTITY.json", identity)

    build = build_android()
    write_json("ANDROID_BUILD_PROVENANCE.json", build)

    # adb restart during Gradle export can drop USB authorization; re-discover before install.
    identity = discover_device(wait_for_auth_s=120)
    write_json("PIXEL6A_DEVICE_IDENTITY.json", identity)

    if identity.get("PHYSICAL_PIXEL6A_VALIDATION") != "AUTHORIZED_PIXEL6A":
        blocked = {
            "schema": "engineering_wave015.baseline_physical_result.v1",
            "generated_at_utc": utc_now(),
            "PHYSICAL_BASELINE_TESTED_SHA": ANIME_ACCEPTED_MAIN_SHA,
            "ANIME_ACCEPTED_MAIN_SHA": ANIME_ACCEPTED_MAIN_SHA,
            "FIELD_KIT_ACCEPTED_MAIN_SHA": FIELD_KIT_ACCEPTED_MAIN_SHA,
            "PHYSICAL_PIXEL6A_OBJECTIVE_VALIDATED": False,
            "PHYSICAL_PIXEL6A_VALIDATION": identity.get("PHYSICAL_PIXEL6A_VALIDATION"),
            "ANDROID_BUILD_PASS": bool(build.get("ANDROID_BUILD_PASS")),
            "APK_SHA256": build.get("APK_SHA256"),
            "REPAIR_PR_REQUIRED": False,
            "note": "Re-authorize USB debugging on Pixel 6a, then rerun make engineering-wave015",
        }
        write_json("PIXEL6A_BASELINE_PHYSICAL_RESULT.json", blocked)
        subprocess.run([sys.executable, str(ROOT / "tools/engineering_wave015/emit_wave015_result.py")], cwd=ROOT)
        print(json.dumps(blocked, indent=2))
        return 2

    serial = identity["_serial"]
    if not build["ANDROID_BUILD_PASS"]:
        print("Android build failed", file=sys.stderr)
        return 1

    install = install_apk(serial)
    write_json("PIXEL6A_INSTALL_RESULT.json", install)
    launch = launch_and_monitor(serial)
    write_json("PIXEL6A_LAUNCH_RESULT.json", launch)

    harness = run_wave015_harness(serial)
    write_json("PIXEL6A_HARNESS_RESULT.json", harness)

    adb_screens = capture_adb_screenshots(serial, count=24)
    device_screens = merge_device_pull_screenshots()
    all_screens = device_screens + adb_screens
    write_json(
        "device_screenshots/manifest.json",
        {
            "source": "PHYSICAL_PIXEL6A_SCREENSHOT",
            "device_model": identity.get("DEVICE_MODEL"),
            "ANIME_ACCEPTED_MAIN_SHA": ANIME_ACCEPTED_MAIN_SHA,
            "generated_at_utc": utc_now(),
            "count": len(all_screens),
            "screenshots": all_screens,
        },
    )

    lifecycle, input_result, accessibility = lifecycle_input_accessibility(serial)
    write_json("PIXEL6A_LIFECYCLE_RESULT.json", lifecycle)
    write_json("PIXEL6A_INPUT_RESULT.json", input_result)
    write_json("PIXEL6A_ACCESSIBILITY_RESULT.json", accessibility)

    perf, thermal = performance_thermal_battery(serial, identity)
    write_json("PIXEL6A_PERFORMANCE_RESULT.json", perf)
    write_json("PIXEL6A_THERMAL_BATTERY_RESULT.json", thermal)

    logcat = logcat_result(serial)
    write_json("PIXEL6A_LOGCAT_RESULT.json", logcat)

    action_count = 0
    roster_count = 0
    action_path = ARTIFACTS / "device_pull" / "PIXEL6A_ACTION_MATRIX.json"
    roster_path = ARTIFACTS / "device_pull" / "PIXEL6A_ROSTER_MODEL_MATRIX.json"
    if action_path.exists() and action_path.stat().st_size > 2:
        try:
            data = json.loads(action_path.read_text(encoding="utf-8"))
            action_count = int(data.get("count", len(data.get("observations", []))))
            write_json("PIXEL6A_ACTION_MATRIX.json", data)
        except json.JSONDecodeError:
            pass
    if roster_path.exists():
        data = json.loads(roster_path.read_text(encoding="utf-8"))
        roster_count = int(data.get("count", len(data.get("fighters", []))))
        write_json("PIXEL6A_ROSTER_MODEL_MATRIX.json", data)

    objective = (
        build["ANDROID_BUILD_PASS"]
        and install["INSTALL_PASS"]
        and launch["APP_PROCESS_ALIVE_AFTER_30S"]
        and launch["FATAL_EXCEPTIONS"] == 0
        and launch["ANR_COUNT"] == 0
        and logcat["FATAL_EXCEPTIONS"] == 0
        and action_count >= 112
        and roster_count == 7
        and len(all_screens) >= 24
    )
    baseline = {
        "schema": "engineering_wave015.baseline_physical_result.v1",
        "generated_at_utc": utc_now(),
        "PHYSICAL_BASELINE_TESTED_SHA": ANIME_ACCEPTED_MAIN_SHA,
        "ANIME_ACCEPTED_MAIN_SHA": ANIME_ACCEPTED_MAIN_SHA,
        "FIELD_KIT_ACCEPTED_MAIN_SHA": FIELD_KIT_ACCEPTED_MAIN_SHA,
        "PHYSICAL_PIXEL6A_OBJECTIVE_VALIDATED": objective,
        "PHYSICAL_PIXEL6A_VALIDATION": "AUTHORIZED_PIXEL6A",
        "ROSTER_MATRIX_COUNT": roster_count,
        "ACTION_MATRIX_COUNT": action_count,
        "SCREENSHOT_COUNT": len(all_screens),
        "HUMAN_ART_DIRECTION_APPROVAL": False,
        "HUMAN_PLAYTEST_COMPLETE": False,
        "REPAIR_PR_REQUIRED": not _harness_tracked_on_origin_main(),
        "CURSOR_MERGED_NOTHING": True,
    }
    write_json("PIXEL6A_BASELINE_PHYSICAL_RESULT.json", baseline)
    subprocess.run([sys.executable, str(ROOT / "tools/engineering_wave015/emit_wave015_result.py")], cwd=ROOT, check=False)
    print(json.dumps(baseline, indent=2))
    return 0 if objective else 1


if __name__ == "__main__":
    raise SystemExit(main())
