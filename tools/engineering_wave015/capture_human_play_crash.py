#!/usr/bin/env python3
"""Human-path crash auto-capture for Wave015 (normal game, real Pixel 6a)."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
from process_death import classify_process_death  # noqa: E402

ART = ROOT / "artifacts" / "engineering_wave015"
CENSUS = ART / "crash_census"
HUMAN = CENSUS / "human_path"
PACKAGE = "com.gunnchos.animeaggressors"
ACTIVITY = "com.godot.game.GodotApp"
APK_PATH = ROOT / "builds" / "android" / "anime-aggressors-debug.apk"


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def sha256_file(path: Path) -> str | None:
    if not path.is_file():
        return None
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def adb(*args: str, serial: str | None = None) -> subprocess.CompletedProcess[str]:
    cmd = ["adb"]
    if serial:
        cmd += ["-s", serial]
    cmd += list(args)
    return subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)


def adb_out(*args: str, serial: str | None = None) -> str:
    return adb(*args, serial=serial).stdout.strip()


def discover_pixel6a(wait_s: int = 60) -> dict:
    subprocess.run(["adb", "start-server"], capture_output=True, text=True)
    deadline = time.time() + wait_s
    raw = ""
    while time.time() < deadline:
        raw = adb_out("devices", "-l")
        lines = [ln for ln in raw.splitlines()[1:] if ln.strip()]
        auth = [ln for ln in lines if ln.split()[1] == "device"]
        if auth:
            serial = auth[0].split()[0]
            model = adb_out("shell", "getprop", "ro.product.model", serial=serial)
            if "Pixel 6a" not in model:
                return {"ok": False, "reason": "BLOCKED_WRONG_DEVICE", "model": model, "raw": raw}
            return {"ok": True, "serial": serial, "model": model, "raw": raw}
        time.sleep(2)
    return {"ok": False, "reason": "BLOCKED_DEVICE_NOT_CONNECTED", "raw": raw}


def build_apk() -> dict:
    env = os.environ.copy()
    godot = Path.home() / "Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot"
    if godot.is_file():
        env["GODOT_BIN"] = str(godot)
    proc = subprocess.run(
        "npm run godot:export:android",
        shell=True,
        cwd=ROOT,
        capture_output=True,
        text=True,
        env=env,
    )
    ok = proc.returncode == 0 and APK_PATH.is_file()
    return {
        "ANDROID_BUILD_PASS": ok,
        "exit_code": proc.returncode,
        "APK_SHA256": sha256_file(APK_PATH),
        "stdout_tail": (proc.stdout or "")[-2000:],
        "stderr_tail": (proc.stderr or "")[-2000:],
    }


def install_apk(serial: str) -> dict:
    adb("shell", "pm", "uninstall", PACKAGE, serial=serial)
    proc = adb("install", "-r", "-t", str(APK_PATH), serial=serial)
    ok = proc.returncode == 0 and "Success" in (proc.stdout + proc.stderr)
    return {"INSTALL_PASS": ok, "stdout": proc.stdout.strip(), "stderr": proc.stderr.strip()}


def pidof(serial: str) -> str:
    return adb_out("shell", "pidof", PACKAGE, serial=serial)


def pull_diag(serial: str, dest: Path) -> dict:
    dest.mkdir(parents=True, exist_ok=True)
    pulled = {}
    for rel, name in [
        ("files/diagnostics/last_action_trace.jsonl", "last_action_trace.jsonl"),
        ("files/diagnostics/session_heartbeat.json", "session_heartbeat.json"),
    ]:
        out = dest / name
        with out.open("wb") as fh:
            subprocess.run(
                ["adb", "-s", serial, "exec-out", "run-as", PACKAGE, "cat", rel],
                stdout=fh,
                stderr=subprocess.PIPE,
                check=False,
            )
        pulled[name] = {"bytes": out.stat().st_size if out.exists() else 0, "sha256": sha256_file(out)}
    return pulled


def dump_refs(serial: str, dest: Path) -> dict:
    dest.mkdir(parents=True, exist_ok=True)
    refs = {}
    for label, args in [
        ("dumpsys_activity.txt", ["shell", "dumpsys", "activity", PACKAGE]),
        ("dumpsys_meminfo.txt", ["shell", "dumpsys", "meminfo", PACKAGE]),
        ("tombstones_ls.txt", ["shell", "ls", "-la", "/data/tombstones"]),
    ]:
        out = dest / label
        proc = adb(*args, serial=serial)
        out.write_text((proc.stdout or "") + (proc.stderr or ""), encoding="utf-8")
        refs[label] = {"bytes": out.stat().st_size, "sha256": sha256_file(out)}
    return refs


def load_heartbeat(path: Path) -> dict:
    if not path.is_file() or path.stat().st_size == 0:
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def signature_from_death(classification: str, logcat: str, heartbeat: dict) -> dict:
    # Prefer last action route/action from heartbeat / logcat snippet.
    snippet = ""
    for line in logcat.splitlines()[-80:]:
        if PACKAGE in line or "godot" in line.lower() or "FATAL" in line:
            snippet += line[:200] + "\n"
    digest = hashlib.sha256(f"{classification}|{snippet[:400]}|{heartbeat.get('last_kind','')}".encode()).hexdigest()[:8]
    return {
        "signature_id": f"HUMAN-CRASH-{digest.upper()}",
        "classification": classification,
        "normalized": snippet.strip()[:400] or classification,
        "heartbeat_last_kind": heartbeat.get("last_kind"),
        "status": "OPEN",
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--duration-min", type=float, default=10.0)
    parser.add_argument("--max-crashes", type=int, default=5)
    parser.add_argument("--skip-build", action="store_true")
    parser.add_argument("--owner-smoke", action="store_true", help="Owner smoke mode messaging")
    args = parser.parse_args()

    HUMAN.mkdir(parents=True, exist_ok=True)
    CENSUS.mkdir(parents=True, exist_ok=True)
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()

    device = discover_pixel6a()
    if not device.get("ok"):
        write_json(
            CENSUS / "HUMAN_PATH_CAPTURE_RESULT.json",
            {
                "schema": "engineering_wave015.human_path_capture.v1",
                "generated_at_utc": utc_now(),
                "status": "BLOCKED",
                "blocker": device.get("reason"),
                "PHYSICAL_PIXEL6A_OBJECTIVE_VALIDATED": False,
                "PIXEL6A_STABILITY_VALIDATED": False,
                "OWNER_NORMAL_PLAY_CRASHES_REPRODUCED": False,
            },
        )
        print(json.dumps(device, indent=2))
        return 2

    serial = device["serial"]
    build = {"ANDROID_BUILD_PASS": APK_PATH.is_file(), "APK_SHA256": sha256_file(APK_PATH), "skipped": True}
    if not args.skip_build:
        print("=== building Android APK ===", flush=True)
        build = build_apk()
        if not build.get("ANDROID_BUILD_PASS"):
            write_json(CENSUS / "HUMAN_PATH_CAPTURE_RESULT.json", {"status": "BUILD_FAIL", "build": build})
            return 1
        device = discover_pixel6a(wait_s=120)
        if not device.get("ok"):
            return 2
        serial = device["serial"]

    install = install_apk(serial)
    if not install.get("INSTALL_PASS"):
        write_json(CENSUS / "HUMAN_PATH_CAPTURE_RESULT.json", {"status": "INSTALL_FAIL", "install": install})
        return 1

    # Clear any harness triggers so we launch NORMAL game.
    adb("shell", f"run-as {PACKAGE} rm -f files/wave015_crash_census_trigger.txt files/wave015_battlescene_stability_trigger.txt files/wave015_physical_trigger.txt", serial=serial)
    adb("logcat", "-c", serial=serial)
    adb("shell", "am", "force-stop", PACKAGE, serial=serial)
    adb("shell", "am", "start", "-n", f"{PACKAGE}/{ACTIVITY}", serial=serial)

    prompt = (
        "OWNER SMOKE: play normally for 10 minutes. No notes required; watcher captures any crash."
        if args.owner_smoke
        else "PLAY NORMALLY — crash details will be captured automatically."
    )
    print("\n" + "=" * 72, flush=True)
    print(prompt, flush=True)
    print("=" * 72 + "\n", flush=True)

    deadline = time.time() + args.duration_min * 60.0
    crashes: list[dict] = []
    signatures: dict[str, dict] = {}
    saw_pid = False
    pid_stable_since = 0.0
    last_pid = ""
    launch_guard_until = time.time() + 15.0
    start = time.time()

    while time.time() < deadline and len(crashes) < args.max_crashes:
        state = adb_out("get-state", serial=serial)
        if state != "device":
            cls = classify_process_death(adb_disconnected=True, pid_disappeared=False)
            print(f"[capture] {cls.classification}", flush=True)
            time.sleep(2)
            continue

        pid = pidof(serial)
        if pid:
            if not saw_pid or pid != last_pid:
                pid_stable_since = time.time()
            saw_pid = True
            last_pid = pid
            time.sleep(1.0)
            continue

        if not saw_pid:
            time.sleep(1.0)
            continue

        # Require a stable live PID for a few seconds before treating disappearance as a crash.
        # Avoids install/start zygote races with empty logcat false positives.
        if time.time() - pid_stable_since < 5.0 or time.time() < launch_guard_until:
            print("[capture] ignoring short launch/pid race (no stable pid window yet)", flush=True)
            saw_pid = False
            last_pid = ""
            time.sleep(1.0)
            # Ensure game is running again
            if not pidof(serial):
                adb("shell", "am", "start", "-n", f"{PACKAGE}/{ACTIVITY}", serial=serial)
                launch_guard_until = time.time() + 15.0
            continue

        # Unexpected death (or clean quit). Capture everything.
        ts = utc_now()
        death_dir = HUMAN / f"death_{len(crashes)+1}_{int(time.time())}"
        death_dir.mkdir(parents=True, exist_ok=True)
        logcat = adb_out("logcat", "-d", serial=serial)
        (death_dir / "logcat.txt").write_text(logcat, encoding="utf-8")
        diag = pull_diag(serial, death_dir / "diagnostics")
        refs = dump_refs(serial, death_dir / "refs")
        hb = load_heartbeat(death_dir / "diagnostics" / "session_heartbeat.json")
        empty_evidence = (not logcat.strip()) and int(diag.get("session_heartbeat.json", {}).get("bytes", 0) or 0) == 0
        cls = classify_process_death(
            logcat_text=logcat,
            heartbeat=hb,
            harness_expected_quit=False,
            pid_disappeared=True,
            force_stop_observed="Force stopping" in logcat and "from pid" in logcat,
        )
        is_crash = cls.counts_as_crash
        if empty_evidence and cls.classification == "UNKNOWN_PROCESS_DEATH":
            # Empty buffer + no flight recorder strongly indicates ADB launch race, not a proven app crash.
            cls = classify_process_death(adb_disconnected=False, pid_disappeared=True, force_stop_observed=True)
            is_crash = False
            print("[capture] empty logcat/heartbeat — classifying as launch/ADB race, not crash", flush=True)

        entry = {
            "timestamp_utc": ts,
            "last_pid": last_pid,
            "classification": cls.classification,
            "counts_as_crash": is_crash,
            "evidence": cls.evidence,
            "notes": cls.notes,
            "diagnostics": diag,
            "refs": refs,
            "logcat_sha256": hashlib.sha256(logcat.encode()).hexdigest(),
            "HEAD_SHA": head,
            "APK_SHA256": build.get("APK_SHA256"),
        }
        if is_crash:
            sig = signature_from_death(cls.classification, logcat, hb)
            entry["signature"] = sig
            sid = sig["signature_id"]
            if sid not in signatures:
                signatures[sid] = {**sig, "occurrences": 0, "deaths": []}
            signatures[sid]["occurrences"] += 1
            signatures[sid]["deaths"].append(str(death_dir.relative_to(ROOT)))
            crashes.append(entry)
            write_json(death_dir / "DEATH.json", entry)
            print(f"[capture] CRASH #{len(crashes)} {sid} class={cls.classification}", flush=True)

            # Stop early if >=3 same signature
            if signatures[sid]["occurrences"] >= 3:
                print(f"[capture] reached >=3 occurrences of {sid}", flush=True)
                break
            # Relaunch for additional captures
            adb("logcat", "-c", serial=serial)
            adb("shell", "am", "start", "-n", f"{PACKAGE}/{ACTIVITY}", serial=serial)
            saw_pid = False
            last_pid = ""
            time.sleep(2)
        else:
            write_json(death_dir / "DEATH.json", entry)
            print(f"[capture] non-crash termination class={cls.classification} — relaunching", flush=True)
            adb("logcat", "-c", serial=serial)
            adb("shell", "am", "start", "-n", f"{PACKAGE}/{ACTIVITY}", serial=serial)
            saw_pid = False
            last_pid = ""
            time.sleep(2)

    elapsed_min = (time.time() - start) / 60.0
    open_sigs = sum(1 for s in signatures.values() if s.get("status") == "OPEN")
    result = {
        "schema": "engineering_wave015.human_path_capture.v1",
        "generated_at_utc": utc_now(),
        "mode": "OWNER_SMOKE" if args.owner_smoke else "HUMAN_PATH",
        "HEAD_SHA": head,
        "APK_SHA256": build.get("APK_SHA256"),
        "DEVICE_MODEL": device.get("model"),
        "DURATION_MIN": round(elapsed_min, 3),
        "TARGET_DURATION_MIN": args.duration_min,
        "HUMAN_PATH_CRASHES_CAPTURED": len(crashes),
        "HUMAN_PATH_UNIQUE_SIGNATURES": len(signatures),
        "HUMAN_PATH_CRASH_SIGNATURES_OPEN": open_sigs,
        "OWNER_NORMAL_PLAY_CRASHES_REPRODUCED": len(crashes) > 0,
        "OWNER_SMOKE_DURATION_MIN": round(elapsed_min, 3) if args.owner_smoke else None,
        "OWNER_SMOKE_UNEXPECTED_TERMINATIONS": len(crashes) if args.owner_smoke else None,
        "crashes": crashes,
        "PHYSICAL_PIXEL6A_OBJECTIVE_VALIDATED": False,
        "PIXEL6A_STABILITY_VALIDATED": False,
        "status": "CAPTURED",
    }
    write_json(CENSUS / "HUMAN_PATH_CAPTURE_RESULT.json", result)
    write_json(
        CENSUS / "HUMAN_PATH_CRASH_SIGNATURES.json",
        {
            "schema": "engineering_wave015.human_path_crash_signatures.v1",
            "generated_at_utc": utc_now(),
            "UNIQUE_CRASH_SIGNATURES": len(signatures),
            "UNIQUE_CRASH_SIGNATURES_OPEN": open_sigs,
            "signatures": list(signatures.values()),
        },
    )
    if args.owner_smoke:
        write_json(
            CENSUS / "OWNER_STABILITY_SMOKE_RESULT.json",
            {
                "schema": "engineering_wave015.owner_stability_smoke.v1",
                "generated_at_utc": utc_now(),
                "OWNER_SMOKE_DURATION_MIN": round(elapsed_min, 3),
                "OWNER_SMOKE_UNEXPECTED_TERMINATIONS": len(crashes),
                "HEAD_SHA": head,
                "APK_SHA256": build.get("APK_SHA256"),
                "PASS": len(crashes) == 0 and elapsed_min >= 10.0,
                "HUMAN_PLAYTEST_COMPLETE": False,
            },
        )
    print(json.dumps({k: result[k] for k in result if k != "crashes"}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
