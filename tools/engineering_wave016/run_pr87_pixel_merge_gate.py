#!/usr/bin/env python3
"""PR #87 final Pixel merge gate — build, install, authentic capture, smoke."""
from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "wave016"
ENG = ROOT / "artifacts" / "engineering_wave016"
OUT = ART / "golden_slice_contact_sheet"
PKG = "com.gunnchos.animeaggressors"
ACTIVITY = "com.godot.game.GodotApp"
APK = ROOT / "builds" / "android" / "anime-aggressors-debug.apk"


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


def adb(*args: str, serial: str | None = None) -> subprocess.CompletedProcess:
    cmd = ["adb"]
    if serial:
        cmd += ["-s", serial]
    cmd += list(args)
    return subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)


def discover_pixel6a() -> dict:
    if not shutil.which("adb"):
        return {"ok": False, "reason": "BLOCKED_PIXEL6A", "raw": "adb not found"}
    subprocess.run(["adb", "start-server"], capture_output=True, text=True)
    raw = adb("devices", "-l").stdout
    lines = [ln for ln in raw.splitlines()[1:] if ln.strip()]
    auth = [ln for ln in lines if len(ln.split()) >= 2 and ln.split()[1] == "device"]
    if not auth:
        return {"ok": False, "reason": "BLOCKED_PIXEL6A", "raw": raw}
    serial = auth[0].split()[0]
    model = adb("shell", "getprop", "ro.product.model", serial=serial).stdout.strip()
    if "Pixel 6a" not in model:
        return {"ok": False, "reason": "BLOCKED_WRONG_DEVICE", "model": model, "serial": serial}
    return {"ok": True, "serial": serial, "model": model, "raw": raw}


def git_sha() -> str:
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    except Exception:
        return "UNKNOWN"


def godot_version() -> str:
    godot = Path.home() / "Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot"
    candidates = [os.environ.get("GODOT_BIN"), str(godot), shutil.which("godot")]
    for c in candidates:
        if c and Path(c).is_file():
            try:
                return subprocess.check_output([c, "--version"], text=True).strip()
            except Exception:
                pass
    return "UNKNOWN"


def build_apk() -> dict:
    env = os.environ.copy()
    godot = Path.home() / "Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot"
    if godot.is_file():
        env["GODOT_BIN"] = str(godot)
    APK.parent.mkdir(parents=True, exist_ok=True)
    proc = subprocess.run(
        ["npm", "run", "godot:export:android"],
        cwd=ROOT,
        env=env,
        capture_output=True,
        text=True,
    )
    (ART / "android_build_log.txt").write_text(proc.stdout + "\n" + proc.stderr, encoding="utf-8")
    return {
        "ok": proc.returncode == 0 and APK.is_file(),
        "exit_code": proc.returncode,
        "PIXEL_SOURCE_SHA": git_sha(),
        "APK_SHA256": sha256_file(APK),
        "PACKAGE": PKG,
        "GODOT_VERSION": godot_version(),
        "apk_path": str(APK.relative_to(ROOT)) if APK.is_file() else "",
    }


def pull_file(serial: str, rel: str, dest: Path) -> bool:
    dest.parent.mkdir(parents=True, exist_ok=True)
    with dest.open("wb") as out:
        proc = subprocess.run(
            ["adb", "-s", serial, "exec-out", "run-as", PKG, "cat", f"files/{rel}"],
            stdout=out,
            stderr=subprocess.PIPE,
        )
    return dest.is_file() and dest.stat().st_size > 0 and proc.returncode == 0


def run_pixel_capture(serial: str, build: dict, timeout_s: int = 300) -> dict:
    adb("shell", "am", "force-stop", PKG, serial=serial)
    adb("shell", f"run-as {PKG} rm -rf files/wave016", serial=serial)
    adb("shell", f"run-as {PKG} mkdir -p files", serial=serial)
    adb(
        "shell",
        f"run-as {PKG} sh -c 'printf wave016-pixel-capture > files/wave016_pixel_capture_trigger.txt'",
        serial=serial,
    )
    adb(
        "shell",
        "am",
        "start",
        "-n",
        f"{PKG}/{ACTIVITY}",
        "--es",
        "command_line",
        "--wave016-pixel-capture",
        serial=serial,
    )
    deadline = time.time() + timeout_s
    ready = False
    while time.time() < deadline:
        check = adb(
            "shell",
            "run-as",
            PKG,
            "ls",
            "files/wave016/PIXEL_MOVE_CAPTURE_RESULT.json",
            serial=serial,
        )
        if check.returncode == 0 and "PIXEL_MOVE_CAPTURE_RESULT.json" in check.stdout:
            ready = True
            break
        time.sleep(3)
    adb("shell", "am", "force-stop", PKG, serial=serial)

    pull_dir = ART / "device_pull"
    pull_dir.mkdir(parents=True, exist_ok=True)
    result_path = pull_dir / "PIXEL_MOVE_CAPTURE_RESULT.json"
    pull_file(serial, "wave016/PIXEL_MOVE_CAPTURE_RESULT.json", result_path)

    OUT.mkdir(parents=True, exist_ok=True)
    capture = {}
    if result_path.is_file() and result_path.stat().st_size > 2:
        try:
            capture = json.loads(result_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            capture = {}

    # Pull screenshots listed in capture
    shots_out = []
    for shot in capture.get("shots", []):
        rel = str(shot.get("path") or "")
        if not rel.endswith(".png"):
            continue
        name = Path(rel).name
        dest = OUT / name
        ok = pull_file(serial, f"wave016/device_screenshots/{name}", dest)
        row = {
            "label": shot.get("label"),
            "pixel_device": True,
            "device_model": build.get("model") or "Pixel 6a",
            "source_sha": build.get("PIXEL_SOURCE_SHA"),
            "apk_sha256": build.get("APK_SHA256"),
            "fighter_id": shot.get("fighter_id", "ember-vale"),
            "gameplay_move_id": shot.get("gameplay_move_id", ""),
            "active_clip": shot.get("active_clip", ""),
            "input_route": shot.get("input_route", "TouchInputManager|Input -> Fighter._handle_actions"),
            "state_verified": bool(shot.get("state_verified")),
            "model_visible": bool(shot.get("model_visible")),
            "captured_at": shot.get("captured_at") or utc_now(),
            "path": str(dest.relative_to(ROOT)) if ok and dest.is_file() else None,
        }
        shots_out.append(row)

    authentic = bool(capture.get("PIXEL_MOVE_SPECIFIC_CAPTURE_AUTHENTIC")) and all(
        s.get("state_verified") and s.get("path") and s.get("model_visible") for s in shots_out
    ) and len(shots_out) >= 20

    manifest = {
        "schema": "wave016_golden_slice_contact_sheet_v3",
        "status": "CAPTURED_AUTHENTIC" if authentic else ("PARTIAL" if shots_out else "FAIL"),
        "note": "On-device Wave016PixelCaptureHarness via TouchInputManager production path",
        "captured_at": utc_now(),
        "PIXEL_GOLDEN_SLICE_CAPTURE": "CAPTURED_AUTHENTIC" if authentic else "PARTIAL",
        "PIXEL_MOVE_SPECIFIC_CAPTURE_AUTHENTIC": authentic,
        "PIXEL_EMBER_MODEL_VISIBILITY_FAILURES": int(
            capture.get("PIXEL_EMBER_MODEL_VISIBILITY_FAILURES", 0)
        ),
        "PIXEL_SOURCE_SHA": build.get("PIXEL_SOURCE_SHA"),
        "APK_SHA256": build.get("APK_SHA256"),
        "PACKAGE": PKG,
        "GODOT_VERSION": build.get("GODOT_VERSION"),
        "DEVICE_MODEL": "Pixel 6a",
        "state_verified_count": sum(1 for s in shots_out if s.get("state_verified")),
        "required_labels": len(shots_out),
        "PIXEL_REAL_INPUT_CLOSED_CASES": capture.get("PIXEL_REAL_INPUT_CLOSED_CASES", []),
        "shots": shots_out,
        "harness_ready": ready,
        "CURSOR_MERGED_NOTHING": True,
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    (OUT / "README.md").write_text(
        f"# Golden Slice Contact Sheet (PR #87)\n\n"
        f"Status: **{manifest['status']}**\n\n"
        f"PIXEL_MOVE_SPECIFIC_CAPTURE_AUTHENTIC: `{authentic}`\n\n"
        f"Device: Pixel 6a · SHA `{build.get('PIXEL_SOURCE_SHA')}`\n",
        encoding="utf-8",
    )
    # Taste packet for Edmund — no human ratings
    taste = {
        "schema": "wave016_owner_taste_packet_v1",
        "OWNER_TASTE_REVIEW": "PENDING",
        "GOLDEN_SLICE_AUTOMATED_Q3_READINESS": False,
        "CURRENT_QUALITY_LEVEL": "Q2",
        "HUMAN_Q5": False,
        "FINAL_HUMAN_AUTHORED_ANIMATION_PASS": False,
        "HUMAN_ART_DIRECTION_APPROVAL": False,
        "HUMAN_PLAYTEST_COMPLETE": False,
        "contact_sheet": str((OUT / "manifest.json").relative_to(ROOT)),
        "shots": [s.get("label") for s in shots_out],
        "note": "Edmund sole taste authority — ratings intentionally blank",
        "CURSOR_MERGED_NOTHING": True,
    }
    (ART / "OWNER_TASTE_PACKET.json").write_text(json.dumps(taste, indent=2) + "\n", encoding="utf-8")
    return manifest


def run_smoke(serial: str, build: dict, duration_min: float = 10.0) -> dict:
    """10-minute normal-play process smoke (no human ratings)."""
    adb("logcat", "-c", serial=serial)
    adb("shell", "am", "force-stop", PKG, serial=serial)
    # Clear harness triggers so normal boot
    adb("shell", f"run-as {PKG} rm -f files/wave016_pixel_capture_trigger.txt files/wave015_trigger.txt", serial=serial)
    adb(
        "shell",
        "monkey",
        "-p",
        PKG,
        "-c",
        "android.intent.category.LAUNCHER",
        "1",
        serial=serial,
    )
    start = time.time()
    deaths = 0
    last_pid = ""
    saw_pid = False
    while (time.time() - start) < duration_min * 60:
        pid = adb("shell", "pidof", PKG, serial=serial).stdout.strip()
        if pid:
            saw_pid = True
            last_pid = pid
        elif saw_pid and last_pid:
            deaths += 1
            saw_pid = False
            adb(
                "shell",
                "monkey",
                "-p",
                PKG,
                "-c",
                "android.intent.category.LAUNCHER",
                "1",
                serial=serial,
            )
            time.sleep(2)
        time.sleep(5)
    logcat = adb("logcat", "-d", serial=serial).stdout
    fatal = len(re.findall(r"FATAL EXCEPTION", logcat))
    anr = len(re.findall(r"ANR in", logcat))
    oom = len(re.findall(r"OutOfMemoryError|lowmemorykiller|am_crash.*oom", logcat, re.I))
    elapsed = (time.time() - start) / 60.0
    result = {
        "schema": "wave016_pixel_normal_play_smoke_v1",
        "generated_at_utc": utc_now(),
        "PIXEL_NORMAL_PLAY_SMOKE_MIN": round(elapsed, 3),
        "UNEXPECTED_PROCESS_DEATHS": deaths,
        "FATAL_EXCEPTIONS": fatal,
        "ANR_COUNT": anr,
        "OOM_COUNT": oom,
        "PIXEL_SOURCE_SHA": build.get("PIXEL_SOURCE_SHA"),
        "APK_SHA256": build.get("APK_SHA256"),
        "DEVICE_MODEL": "Pixel 6a",
        "PASS": elapsed >= 10.0 and deaths == 0 and fatal == 0 and anr == 0 and oom == 0,
        "CURSOR_MERGED_NOTHING": True,
    }
    (ART / "PIXEL_NORMAL_PLAY_SMOKE.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    ENG.mkdir(parents=True, exist_ok=True)
    (ENG / "PIXEL_NORMAL_PLAY_SMOKE.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    return result


def main() -> int:
    ART.mkdir(parents=True, exist_ok=True)
    ENG.mkdir(parents=True, exist_ok=True)
    device = discover_pixel6a()
    gate = {
        "schema": "pr87_final_merge_gate_device_v1",
        "generated_at_utc": utc_now(),
        "DEVICE": device,
        "CURSOR_MERGED_NOTHING": True,
    }
    if not device.get("ok"):
        gate["PR87_FINAL_MERGE_GATE"] = "BLOCKED_PIXEL6A"
        gate["READY_FOR_OWNER_MERGE"] = False
        (ART / "PR87_FINAL_MERGE_GATE.json").write_text(json.dumps(gate, indent=2) + "\n", encoding="utf-8")
        print(json.dumps(gate, indent=2))
        return 2

    print("=== Building current-head APK ===", flush=True)
    build = build_apk()
    build["model"] = device["model"]
    (ART / "PIXEL_BUILD_PROVENANCE.json").write_text(json.dumps(build, indent=2) + "\n", encoding="utf-8")
    if not build.get("ok"):
        gate["PR87_FINAL_MERGE_GATE"] = "FAIL"
        gate["READY_FOR_OWNER_MERGE"] = False
        gate["build"] = build
        (ART / "PR87_FINAL_MERGE_GATE.json").write_text(json.dumps(gate, indent=2) + "\n", encoding="utf-8")
        print(json.dumps(gate, indent=2))
        return 1

    serial = device["serial"]
    print("=== Installing APK ===", flush=True)
    inst = adb("install", "-r", str(APK), serial=serial)
    print(inst.stdout or inst.stderr, flush=True)

    print("=== Authentic Pixel move capture ===", flush=True)
    manifest = run_pixel_capture(serial, build)
    print("=== 10-minute normal play smoke ===", flush=True)
    smoke = run_smoke(serial, build, duration_min=10.0)

    gate.update(
        {
            "PR87_FINAL_MERGE_GATE": "PASS"
            if manifest.get("PIXEL_MOVE_SPECIFIC_CAPTURE_AUTHENTIC") and smoke.get("PASS")
            else "PARTIAL",
            "build": build,
            "manifest_status": manifest.get("status"),
            "PIXEL_MOVE_SPECIFIC_CAPTURE_AUTHENTIC": manifest.get("PIXEL_MOVE_SPECIFIC_CAPTURE_AUTHENTIC"),
            "PIXEL_EMBER_MODEL_VISIBILITY_FAILURES": manifest.get("PIXEL_EMBER_MODEL_VISIBILITY_FAILURES"),
            "smoke": smoke,
            "DEVICE_MODEL": "Pixel 6a",
            "PIXEL_SOURCE_SHA": build.get("PIXEL_SOURCE_SHA"),
            "APK_SHA256": build.get("APK_SHA256"),
        }
    )
    (ART / "PR87_FINAL_MERGE_GATE.json").write_text(json.dumps(gate, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({k: gate[k] for k in gate if k != "DEVICE"}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
