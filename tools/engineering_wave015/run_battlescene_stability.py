#!/usr/bin/env python3
"""Orchestrate Wave015 full BattleScene stability campaigns on Pixel 6a."""
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
LOGCAT_DIR = CENSUS / "logcat"
PACKAGE = "com.gunnchos.animeaggressors"
ACTIVITY = "com.godot.game.GodotApp"
APK_PATH = ROOT / "builds" / "android" / "anime-aggressors-debug.apk"
OUT_ON_DEVICE = "files/wave015_battlescene_stability"


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
                return {"ok": False, "reason": "BLOCKED_WRONG_DEVICE", "model": model}
            return {"ok": True, "serial": serial, "model": model}
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
    return {
        "ANDROID_BUILD_PASS": proc.returncode == 0 and APK_PATH.is_file(),
        "exit_code": proc.returncode,
        "APK_SHA256": sha256_file(APK_PATH),
        "stdout_tail": (proc.stdout or "")[-2000:],
        "stderr_tail": (proc.stderr or "")[-2000:],
    }


def install_apk(serial: str) -> dict:
    adb("shell", "pm", "uninstall", PACKAGE, serial=serial)
    proc = adb("install", "-r", "-t", str(APK_PATH), serial=serial)
    return {
        "INSTALL_PASS": proc.returncode == 0 and "Success" in (proc.stdout + proc.stderr),
        "stdout": proc.stdout.strip(),
        "stderr": proc.stderr.strip(),
    }


def pidof(serial: str) -> str:
    return adb_out("shell", "pidof", PACKAGE, serial=serial)


STAGE_MARKERS = {
    "FUZZ": f"{OUT_ON_DEVICE}/BATTLESCENE_FUZZ_RESULT.json",
    "TRANSITION": f"{OUT_ON_DEVICE}/BATTLESCENE_TRANSITION_RESULT.json",
    "MATCHUP": f"{OUT_ON_DEVICE}/BATTLESCENE_MATCHUP_DONE.json",
    "LIFECYCLE": f"{OUT_ON_DEVICE}/BATTLESCENE_LIFECYCLE_RESULT.json",
    "SOAK": f"{OUT_ON_DEVICE}/BATTLESCENE_SOAK_RESULT.json",
    "ALL": f"{OUT_ON_DEVICE}/BATTLESCENE_STABILITY_SUMMARY.json",
}


def push_trigger(serial: str, stage: str, seed: int) -> None:
    adb("shell", f"run-as {PACKAGE} mkdir -p files", serial=serial)
    adb("shell", f"run-as {PACKAGE} sh -c 'printf wave015-battlescene-stability > files/wave015_battlescene_stability_trigger.txt'", serial=serial)
    adb("shell", f"run-as {PACKAGE} sh -c 'printf {stage} > files/wave015_battlescene_stability_stage.txt'", serial=serial)
    adb("shell", f"run-as {PACKAGE} sh -c 'printf {seed} > files/wave015_battlescene_stability_seed.txt'", serial=serial)
    adb("shell", f"run-as {PACKAGE} rm -rf files/wave015_battlescene_stability", serial=serial)


def pull_results(serial: str) -> dict:
    dest = CENSUS / "device_pull_battlescene"
    dest.mkdir(parents=True, exist_ok=True)
    listing = adb("shell", "run-as", PACKAGE, "find", OUT_ON_DEVICE, "-type", "f", serial=serial)
    pulled = []
    if listing.returncode != 0:
        return {"pulled": [], "error": listing.stderr}
    for rel in listing.stdout.split():
        rel = rel.strip()
        if not rel:
            continue
        short = rel.replace(f"{OUT_ON_DEVICE}/", "")
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
        if short.endswith(".json"):
            (CENSUS / Path(short).name).write_bytes(out.read_bytes())
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
    return {"pulled": pulled, "count": len(pulled)}


def dump_logcat(serial: str, label: str) -> Path:
    LOGCAT_DIR.mkdir(parents=True, exist_ok=True)
    text = adb_out("logcat", "-d", serial=serial)
    path = LOGCAT_DIR / f"{label}.txt"
    path.write_text(text, encoding="utf-8")
    return path


def wait_stage(serial: str, stage: str, timeout_s: int, label: str) -> dict:
    marker = STAGE_MARKERS.get(stage.upper(), STAGE_MARKERS["ALL"])
    deadline = time.time() + timeout_s
    last_pid = ""
    saw_pid = False
    while time.time() < deadline:
        check = adb("shell", "run-as", PACKAGE, "ls", marker, serial=serial)
        if check.returncode == 0 and Path(marker).name in check.stdout:
            return {
                "completed": True,
                "unexpected_termination": False,
                "classification": "HARNESS_REQUESTED_QUIT",
                "counts_as_crash": False,
                "marker": marker,
                "last_pid": last_pid or pidof(serial),
                "elapsed_s": timeout_s - (deadline - time.time()),
            }
        pid = pidof(serial)
        if pid:
            saw_pid = True
            last_pid = pid
        elif saw_pid:
            log_path = dump_logcat(serial, f"{label}_death")
            logcat = log_path.read_text(encoding="utf-8", errors="replace")
            # Pull heartbeat for classification
            pull_results(serial)
            hb_path = CENSUS / "device_pull_battlescene" / "diagnostics" / "session_heartbeat.json"
            hb = {}
            if hb_path.is_file() and hb_path.stat().st_size > 0:
                try:
                    hb = json.loads(hb_path.read_text(encoding="utf-8"))
                except Exception:
                    hb = {}
            # Marker may exist even if process already quit — recheck
            check2 = adb("shell", "run-as", PACKAGE, "ls", marker, serial=serial)
            harness_done = check2.returncode == 0 and Path(marker).name in check2.stdout
            cls = classify_process_death(
                logcat_text=logcat,
                heartbeat=hb,
                harness_expected_quit=harness_done or (hb.get("clean_shutdown") is True),
                pid_disappeared=True,
            )
            return {
                "completed": harness_done,
                "unexpected_termination": cls.counts_as_crash,
                "classification": cls.classification,
                "counts_as_crash": cls.counts_as_crash,
                "evidence": cls.evidence,
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
        "classification": "UNKNOWN_PROCESS_DEATH",
        "counts_as_crash": False,
        "marker": marker,
        "last_pid": last_pid or pidof(serial),
        "elapsed_s": timeout_s,
    }


def load_json(name: str) -> dict:
    path = CENSUS / name
    if not path.exists():
        alt = CENSUS / "device_pull_battlescene" / name
        path = alt if alt.exists() else path
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        return {"_error": str(exc)}


def run_stage(serial: str, stage: str, seed: int, timeout_s: int) -> dict:
    adb("logcat", "-c", serial=serial)
    adb("shell", "am", "force-stop", PACKAGE, serial=serial)
    push_trigger(serial, stage, seed)
    adb(
        "shell",
        "am",
        "start",
        "-n",
        f"{PACKAGE}/{ACTIVITY}",
        "--es",
        "command_line",
        "--wave015-battlescene-stability",
        serial=serial,
    )
    wait = wait_stage(serial, stage, timeout_s, f"bs_{stage}")
    dump_logcat(serial, f"bs_{stage}_final")
    pulled = pull_results(serial)
    adb("shell", "am", "force-stop", PACKAGE, serial=serial)
    return {"wait": wait, "pulled": pulled}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--stages", default="FUZZ,TRANSITION,MATCHUP,LIFECYCLE,SOAK")
    parser.add_argument("--seed", type=int, default=152026)
    parser.add_argument("--skip-build", action="store_true")
    args = parser.parse_args()

    CENSUS.mkdir(parents=True, exist_ok=True)
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    device = discover_pixel6a()
    if not device.get("ok"):
        print(json.dumps(device, indent=2))
        return 2

    serial = device["serial"]
    build = {"ANDROID_BUILD_PASS": APK_PATH.is_file(), "APK_SHA256": sha256_file(APK_PATH), "skipped": True}
    if not args.skip_build:
        print("=== building Android APK ===", flush=True)
        build = build_apk()
        if not build["ANDROID_BUILD_PASS"]:
            print("build failed", file=sys.stderr)
            return 1
        device = discover_pixel6a(120)
        if not device.get("ok"):
            return 2
        serial = device["serial"]

    install = install_apk(serial)
    write_json(ART / "PIXEL6A_INSTALL_RESULT.json", {**install, "generated_at_utc": utc_now()})
    if not install["INSTALL_PASS"]:
        return 1

    timeouts = {
        "FUZZ": 7200,
        "TRANSITION": 3600,
        "MATCHUP": 7200,
        "LIFECYCLE": 3600,
        "SOAK": 2400,
        "ALL": 18000,
    }
    stages = [s.strip().upper() for s in args.stages.split(",") if s.strip()]
    run_info = {}
    for stage in stages:
        print(f"=== BattleScene stage {stage} ===", flush=True)
        run_info[stage] = run_stage(serial, stage, args.seed, timeouts.get(stage, 7200))
        wait = run_info[stage]["wait"]
        if wait.get("counts_as_crash"):
            print(f"CRASH during {stage}: {wait.get('classification')}", flush=True)
            break

    fuzz = load_json("BATTLESCENE_FUZZ_RESULT.json")
    trans = load_json("BATTLESCENE_TRANSITION_RESULT.json")
    match = load_json("BATTLESCENE_MATCHUP_RESULT.json")
    life = load_json("BATTLESCENE_LIFECYCLE_RESULT.json")
    soak = load_json("BATTLESCENE_SOAK_RESULT.json")

    deaths = sum(1 for s in run_info.values() if s.get("wait", {}).get("counts_as_crash"))
    summary = {
        "schema": "engineering_wave015.battlescene_stability_orchestrator.v1",
        "generated_at_utc": utc_now(),
        "HEAD_SHA": head,
        "APK_SHA256": build.get("APK_SHA256"),
        "DEVICE_MODEL": device.get("model"),
        "BATTLESCENE_FUZZ_EVENTS": int(fuzz.get("BATTLESCENE_FUZZ_EVENTS", 0)),
        "BATTLESCENE_FUZZ_PROCESS_DEATHS": int(fuzz.get("BATTLESCENE_FUZZ_PROCESS_DEATHS", deaths)),
        "BATTLESCENE_TRANSITIONS_TESTED": int(trans.get("BATTLESCENE_TRANSITIONS_TESTED", 0)),
        "BATTLESCENE_TRANSITION_CRASHES": int(trans.get("BATTLESCENE_TRANSITION_CRASHES", 0)),
        "MATCHUPS_ATTEMPTED": int(match.get("MATCHUPS_ATTEMPTED", 0)),
        "MATCHUPS_COMPLETED_WITHOUT_CRASH": int(match.get("MATCHUPS_COMPLETED_WITHOUT_CRASH", 0)),
        "REAL_BATTLESCENE_CYCLES": int(life.get("REAL_BATTLESCENE_CYCLES", 0)),
        "REAL_BATTLESCENE_CYCLE_CRASHES": int(life.get("REAL_BATTLESCENE_CYCLE_CRASHES", 0)),
        "BATTLESCENE_SOAK_MIN": int(soak.get("BATTLESCENE_SOAK_MIN", 0)),
        "UNEXPECTED_PROCESS_DEATHS": deaths,
        "run_info": run_info,
    }
    write_json(CENSUS / "BATTLESCENE_ORCHESTRATOR_SUMMARY.json", summary)
    print(json.dumps({k: summary[k] for k in summary if k != "run_info"}, indent=2))
    return 0 if deaths == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
