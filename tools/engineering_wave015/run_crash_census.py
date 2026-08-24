#!/usr/bin/env python3
"""Wave015 Pixel 6a crash census orchestrator (ADB real device only)."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "engineering_wave015"
CENSUS = ART / "crash_census"
LOGCAT_DIR = CENSUS / "logcat"
REPLAYS = CENSUS / "replays"
PACKAGE = "com.gunnchos.animeaggressors"
ACTIVITY = "com.godot.game.GodotApp"
APK_PATH = ROOT / "builds" / "android" / "anime-aggressors-debug.apk"
PR85_HEAD_BEFORE_DEFAULT = "6fe535c81b461176f4bebcff6a22ff7ee11c8d5c"


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


def adb(*args: str, serial: str | None = None, check: bool = False) -> subprocess.CompletedProcess[str]:
    cmd = ["adb"]
    if serial:
        cmd += ["-s", serial]
    cmd += list(args)
    return subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, check=check)


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
        unauth = [ln for ln in lines if ln.split()[1] == "unauthorized"]
        if auth:
            serial = auth[0].split()[0]
            model = adb_out("shell", "getprop", "ro.product.model", serial=serial)
            if "Pixel 6a" not in model:
                return {"ok": False, "reason": "BLOCKED_WRONG_DEVICE", "model": model, "raw": raw}
            return {"ok": True, "serial": serial, "model": model, "raw": raw}
        if unauth and not auth:
            time.sleep(2)
            continue
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
        "stdout_tail": (proc.stdout or "")[-2500:],
        "stderr_tail": (proc.stderr or "")[-2500:],
    }


def install_apk(serial: str) -> dict:
    adb("shell", "pm", "uninstall", PACKAGE, serial=serial)
    proc = adb("install", "-r", "-t", str(APK_PATH), serial=serial)
    ok = proc.returncode == 0 and "Success" in (proc.stdout + proc.stderr)
    return {"INSTALL_PASS": ok, "stdout": proc.stdout.strip(), "stderr": proc.stderr.strip()}


def clear_logcat(serial: str) -> None:
    adb("logcat", "-c", serial=serial)


def dump_logcat(serial: str, label: str) -> Path:
    LOGCAT_DIR.mkdir(parents=True, exist_ok=True)
    text = adb_out("logcat", "-d", serial=serial)
    path = LOGCAT_DIR / f"{label}.txt"
    path.write_text(text, encoding="utf-8")
    # structured extract
    fatal = len(re.findall(r"FATAL EXCEPTION", text))
    anr = len(re.findall(r"ANR in", text))
    native = len(re.findall(r"Fatal signal", text))
    godot_err = len(re.findall(r"SCRIPT ERROR|Godot.*ERROR", text))
    write_json(
        LOGCAT_DIR / f"{label}.summary.json",
        {
            "label": label,
            "generated_at_utc": utc_now(),
            "FATAL_EXCEPTIONS": fatal,
            "ANR_COUNT": anr,
            "NATIVE_FATAL_SIGNAL": native,
            "GODOT_ERROR_LINES": godot_err,
            "bytes": len(text.encode("utf-8")),
            "sha256": hashlib.sha256(text.encode("utf-8")).hexdigest(),
            "path": str(path.relative_to(ROOT)),
        },
    )
    return path


def pidof(serial: str) -> str:
    return adb_out("shell", "pidof", PACKAGE, serial=serial)


def force_stop(serial: str) -> None:
    adb("shell", "am", "force-stop", PACKAGE, serial=serial)


def push_trigger(serial: str, stage: str, seed: int, wipe: bool = True) -> None:
    adb("shell", f"run-as {PACKAGE} mkdir -p files", serial=serial)
    adb(
        "shell",
        f"run-as {PACKAGE} sh -c 'printf wave015-crash-census > files/wave015_crash_census_trigger.txt'",
        serial=serial,
    )
    adb(
        "shell",
        f"run-as {PACKAGE} sh -c 'printf {stage} > files/wave015_crash_census_stage.txt'",
        serial=serial,
    )
    adb(
        "shell",
        f"run-as {PACKAGE} sh -c 'printf {seed} > files/wave015_crash_census_seed.txt'",
        serial=serial,
    )
    if wipe:
        adb("shell", f"run-as {PACKAGE} rm -rf files/wave015_crash_census", serial=serial)
        # Remove prior summary marker so wait_for_census cannot false-complete.
        adb("shell", f"run-as {PACKAGE} rm -f files/wave015_crash_census/CENSUS_SUMMARY.json", serial=serial)


def start_census(serial: str) -> None:
    adb(
        "shell",
        "am",
        "start",
        "-n",
        f"{PACKAGE}/{ACTIVITY}",
        "--es",
        "command_line",
        "--wave015-crash-census",
        serial=serial,
    )


def pull_census_dir(serial: str) -> dict:
    dest = CENSUS / "device_pull"
    dest.mkdir(parents=True, exist_ok=True)
    REPLAYS.mkdir(parents=True, exist_ok=True)
    list_proc = adb("shell", "run-as", PACKAGE, "find", "files/wave015_crash_census", "-type", "f", serial=serial)
    pulled = []
    if list_proc.returncode != 0:
        return {"pulled": [], "error": list_proc.stderr}
    for rel in list_proc.stdout.split():
        rel = rel.strip()
        if not rel:
            continue
        # rel like files/wave015_crash_census/FOO.json
        short = rel.replace("files/wave015_crash_census/", "")
        out = dest / short
        out.parent.mkdir(parents=True, exist_ok=True)
        with out.open("wb") as fh:
            subprocess.run(
                ["adb", "-s", serial, "exec-out", "run-as", PACKAGE, "cat", rel],
                stdout=fh,
                stderr=subprocess.PIPE,
                check=False,
            )
        pulled.append(str(out.relative_to(ROOT)))
        # promote key artifacts + replays
        if short.endswith(".json"):
            (CENSUS / Path(short).name).write_bytes(out.read_bytes())
        if "replays/" in short or short.startswith("replays/"):
            rdest = REPLAYS / Path(short).name
            rdest.write_bytes(out.read_bytes())
    # diagnostics
    for diag in ["files/diagnostics/last_action_trace.jsonl", "files/diagnostics/session_heartbeat.json"]:
        short = diag.replace("files/", "")
        out = dest / short
        out.parent.mkdir(parents=True, exist_ok=True)
        with out.open("wb") as fh:
            subprocess.run(
                ["adb", "-s", serial, "exec-out", "run-as", PACKAGE, "cat", diag],
                stdout=fh,
                stderr=subprocess.PIPE,
                check=False,
            )
        if out.stat().st_size > 0:
            pulled.append(str(out.relative_to(ROOT)))
    return {"pulled": pulled, "count": len(pulled)}


STAGE_DONE_MARKERS = {
    "A": "files/wave015_crash_census/ACTION_ISOLATION_MATRIX.json",
    "B": "files/wave015_crash_census/ACTION_TRANSITION_MATRIX.json",
    "C": "files/wave015_crash_census/FUZZ_CAMPAIGN_RESULT.json",
    "D": "files/wave015_crash_census/MATCHUP_STRESS_RESULT.json",
    "E": "files/wave015_crash_census/SCENE_LIFECYCLE_RESULT.json",
    "F": "files/wave015_crash_census/SOAK_RESULT.json",
    "ABCD": "files/wave015_crash_census/CENSUS_SUMMARY.json",
    "ALL": "files/wave015_crash_census/SOAK_RESULT.json",
}


def wait_for_census(serial: str, timeout_s: int, label: str, stage: str = "ALL") -> dict:
    deadline = time.time() + timeout_s
    last_pid = ""
    saw_pid = False
    marker = STAGE_DONE_MARKERS.get(stage.upper(), "files/wave015_crash_census/CENSUS_SUMMARY.json")
    while time.time() < deadline:
        check = adb("shell", "run-as", PACKAGE, "ls", marker, serial=serial)
        if check.returncode == 0 and Path(marker).name in check.stdout:
            return {
                "completed": True,
                "unexpected_termination": False,
                "marker": marker,
                "last_pid": last_pid or pidof(serial),
                "elapsed_s": timeout_s - (deadline - time.time()),
            }
        pid = pidof(serial)
        if pid:
            saw_pid = True
            last_pid = pid
        elif saw_pid:
            dump_logcat(serial, f"{label}_death")
            return {
                "completed": False,
                "unexpected_termination": True,
                "marker": marker,
                "last_pid": last_pid,
                "elapsed_s": timeout_s - (deadline - time.time()),
            }
        time.sleep(3)
    dump_logcat(serial, f"{label}_timeout")
    return {
        "completed": False,
        "unexpected_termination": False,
        "timeout": True,
        "marker": marker,
        "last_pid": last_pid or pidof(serial),
        "elapsed_s": timeout_s,
    }


def run_stages(serial: str, stages: str, seed: int, timeouts: dict[str, int]) -> dict:
    results = {}
    stage_token = stages.upper()
    timeout = timeouts.get(stage_token, timeouts.get("ALL", 7200))
    clear_logcat(serial)
    force_stop(serial)
    push_trigger(serial, stage_token, seed, wipe=True)
    start_census(serial)
    wait = wait_for_census(serial, timeout, f"stage_{stage_token}", stage=stage_token)
    dump_logcat(serial, f"stage_{stage_token}_final")
    pulled = pull_census_dir(serial)
    # Archive stage-specific snapshot before a later stage wipe.
    stage_dir = CENSUS / "stages" / stage_token
    stage_dir.mkdir(parents=True, exist_ok=True)
    pull_root = CENSUS / "device_pull"
    if pull_root.exists():
        for src in pull_root.rglob("*"):
            if src.is_file():
                dest = stage_dir / src.relative_to(pull_root)
                dest.parent.mkdir(parents=True, exist_ok=True)
                dest.write_bytes(src.read_bytes())
    force_stop(serial)
    results[stage_token] = {"wait": wait, "pulled": pulled}
    return results


def load_json(name: str) -> dict:
    path = CENSUS / name
    if not path.exists():
        alt = CENSUS / "device_pull" / name
        path = alt if alt.exists() else path
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        return {"_error": str(exc)}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--stages", default="ABCD", help="A/B/C/D/E/F/ALL/ABCD")
    parser.add_argument("--seed", type=int, default=152026)
    parser.add_argument("--skip-build", action="store_true")
    parser.add_argument("--baseline-sha", default=PR85_HEAD_BEFORE_DEFAULT)
    parser.add_argument("--phase", default="baseline", choices=["baseline", "post_repair", "final"])
    args = parser.parse_args()

    CENSUS.mkdir(parents=True, exist_ok=True)
    LOGCAT_DIR.mkdir(parents=True, exist_ok=True)
    REPLAYS.mkdir(parents=True, exist_ok=True)

    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    device = discover_pixel6a()
    if not device.get("ok"):
        write_json(
            CENSUS / "BASELINE_CRASH_CENSUS.json",
            {
                "schema": "engineering_wave015.baseline_crash_census.v1",
                "generated_at_utc": utc_now(),
                "BASELINE_CRASH_CENSUS_SHA": args.baseline_sha,
                "HEAD_SHA": head,
                "PHYSICAL_PIXEL6A_OBJECTIVE_VALIDATED": False,
                "PIXEL6A_STABILITY_VALIDATED": False,
                "PRIOR_WAVE015_OBJECTIVE_PASS": "SUPERSEDED_BY_HUMAN_CRASH_REPORT",
                "status": "PARTIAL",
                "blocker": device.get("reason"),
                "device": device,
            },
        )
        print(json.dumps(device, indent=2))
        return 2

    serial = device["serial"]
    build = {"ANDROID_BUILD_PASS": APK_PATH.is_file(), "APK_SHA256": sha256_file(APK_PATH), "skipped": True}
    if not args.skip_build:
        print("=== building Android APK ===", flush=True)
        build = build_apk()
        write_json(ART / "ANDROID_BUILD_PROVENANCE.json", {**build, "generated_at_utc": utc_now()})
        # Gradle may bounce adb auth
        device = discover_pixel6a(wait_s=120)
        if not device.get("ok"):
            write_json(
                CENSUS / "BASELINE_CRASH_CENSUS.json",
                {
                    "schema": "engineering_wave015.baseline_crash_census.v1",
                    "generated_at_utc": utc_now(),
                    "BASELINE_CRASH_CENSUS_SHA": args.baseline_sha,
                    "HEAD_SHA": head,
                    "status": "PARTIAL",
                    "blocker": device.get("reason"),
                    "build": build,
                },
            )
            return 2
        serial = device["serial"]
    if not build.get("ANDROID_BUILD_PASS"):
        print("build failed", file=sys.stderr)
        return 1

    install = install_apk(serial)
    write_json(ART / "PIXEL6A_INSTALL_RESULT.json", {**install, "generated_at_utc": utc_now()})
    if not install["INSTALL_PASS"]:
        return 1

    # Stage mapping: ABCD -> harness ALL but we instruct ABCD via stage file content.
    stage_map = {
        "ABCD": "ABCD",
        "ALL": "ALL",
        "A": "A",
        "B": "B",
        "C": "C",
        "D": "D",
        "E": "E",
        "F": "F",
    }
    stage = stage_map.get(args.stages.upper(), args.stages.upper())
    # Harness understands A/B/C/D/E/F/ALL — for ABCD run as sequential via ALL-like custom:
    # Use ALL but timeouts sized for A-D without long soak: harness ALL includes F.
    # For baseline ABCD we pass stage ABCD and teach harness to accept it.
    timeouts = {
        "A": 1800,
        "B": 1800,
        "C": 5400,
        "D": 3600,
        "E": 1800,
        "F": 2100,
        "ABCD": 9000,
        "ALL": 15000,
    }

    # Patch: if stage ABCD, run harness with stage ALL but skip F by writing ABCD and updating harness —
    # harness already checks _stage in ["A","ALL"] etc. Add ABCD support by running A then B then C then D.
    if stage == "ABCD":
        # Single on-device process for A–D so intermediate artifacts are not wiped.
        print("=== census stage ABCD (single process) ===", flush=True)
        run_info = run_stages(serial, "ABCD", args.seed, timeouts)
    else:
        print(f"=== census stage {stage} ===", flush=True)
        run_info = run_stages(serial, stage, args.seed, timeouts)

    subprocess.run([sys.executable, str(ROOT / "tools/engineering_wave015/cluster_crashes.py")], cwd=ROOT)
    signatures = load_json("CRASH_SIGNATURES.json")
    isolation = load_json("ACTION_ISOLATION_MATRIX.json")
    transitions = load_json("ACTION_TRANSITION_MATRIX.json")
    fuzz = load_json("FUZZ_CAMPAIGN_RESULT.json")
    matchups = load_json("MATCHUP_STRESS_RESULT.json")
    lifecycle = load_json("SCENE_LIFECYCLE_RESULT.json")
    soak = load_json("SOAK_RESULT.json")
    summary = load_json("CENSUS_SUMMARY.json")

    open_sigs = int(signatures.get("UNIQUE_CRASH_SIGNATURES_OPEN", signatures.get("UNIQUE_CRASH_SIGNATURES", 0)))
    baseline = {
        "schema": "engineering_wave015.baseline_crash_census.v1",
        "generated_at_utc": utc_now(),
        "phase": args.phase,
        "BASELINE_CRASH_CENSUS_SHA": args.baseline_sha,
        "HEAD_SHA": head,
        "APK_SHA256": build.get("APK_SHA256"),
        "DEVICE_MODEL": device.get("model"),
        "PRIOR_WAVE015_OBJECTIVE_PASS": "SUPERSEDED_BY_HUMAN_CRASH_REPORT",
        "PHYSICAL_PIXEL6A_OBJECTIVE_VALIDATED": False,
        "PIXEL6A_STABILITY_VALIDATED": False,
        "UNIQUE_CRASH_SIGNATURES": int(signatures.get("UNIQUE_CRASH_SIGNATURES", 0)),
        "UNIQUE_CRASH_SIGNATURES_OPEN": open_sigs,
        "ACTION_ISOLATION_ROWS": int(isolation.get("count", 0)),
        "TRANSITION_CELLS": int(transitions.get("count", 0)),
        "FUZZ_EVENTS": int(fuzz.get("GAMEPLAY_ACTION_EVENTS", 0)),
        "MATCHUPS": int(matchups.get("count", 0)),
        "SCENE_CYCLES": int(lifecycle.get("count", 0)),
        "SOAK_PASS": bool(soak.get("PASS", False)),
        "run_info": run_info,
        "census_summary": summary,
        "status": "BASELINE_CAPTURED" if args.phase == "baseline" else "POST_REPAIR",
    }
    out_name = "BASELINE_CRASH_CENSUS.json" if args.phase == "baseline" else "FINAL_STABILITY_RESULT.json"
    write_json(CENSUS / out_name, baseline)
    if args.phase != "baseline":
        write_json(CENSUS / "FINAL_STABILITY_RESULT.json", baseline)
    print(json.dumps({k: baseline[k] for k in baseline if k not in ("run_info", "census_summary")}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
