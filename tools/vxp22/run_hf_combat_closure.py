#!/usr/bin/env python3
"""Run VXP-2.2 human-feedback combat harnesses and emit ANIME_HUMAN_FEEDBACK_GATES.json."""
from __future__ import annotations

import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "vxp22"
REPORTS = ART / "reports"
PIXEL = ART / "pixel"
GODOT_PROJECT = ROOT / "game-godot"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def sh(cmd: list[str], timeout: int = 300) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, timeout=timeout)


def resolve_godot() -> str | None:
    import os
    if os.environ.get("GODOT_BIN"):
        return os.environ["GODOT_BIN"]
    # Prefer Godot 4.5 (project feature) — homebrew 4.7 can SIGSEGV headless on macOS.
    for p in (
        Path.home() / "Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot",
        Path("/Applications/Godot-4.5.app/Contents/MacOS/Godot"),
        Path("/Applications/Godot-4.3.app/Contents/MacOS/Godot"),
        Path("/Applications/Godot.app/Contents/MacOS/Godot"),
        Path("/opt/homebrew/bin/godot"),
    ):
        if p.exists():
            return str(p)
    for c in ("godot4", "godot", "Godot"):
        r = sh(["bash", "-lc", f"command -v {c}"])
        if r.returncode == 0 and r.stdout.strip():
            return r.stdout.strip()
    return None


def git_sha() -> str:
    r = sh(["git", "rev-parse", "HEAD"])
    return r.stdout.strip() if r.returncode == 0 else ""


def parent_sha() -> str:
    r = sh(["git", "rev-parse", "HEAD^"])
    # stacked branch first commit parent should be PR101 head; use merge-base with brand branch if available
    r2 = sh(["git", "merge-base", "HEAD", "vxp/vxp-2-anime-aggressors-brand-presentation"])
    if r2.returncode == 0 and r2.stdout.strip():
        return r2.stdout.strip()
    return r.stdout.strip() if r.returncode == 0 else ""


def run_harness(godot: str) -> dict:
    REPORTS.mkdir(parents=True, exist_ok=True)
    script = "res://tests/vxp22_hf/HfCombatClosureHarness.gd"
    cmd = [
        godot,
        "--headless",
        "--rendering-driver",
        "opengl3",
        "--path",
        str(GODOT_PROJECT),
        "-s",
        script,
    ]
    proc = sh(cmd, timeout=240)
    out = REPORTS / "HF_COMBAT_HARNESS.json"
    payload = {}
    if out.exists():
        payload = json.loads(out.read_text())
    payload["exit_code"] = proc.returncode
    payload["stdout_tail"] = (proc.stdout or "")[-4000:]
    payload["stderr_tail"] = (proc.stderr or "")[-4000:]
    (REPORTS / "HF_COMBAT_HARNESS_RUN.txt").write_text(
        f"cmd={' '.join(cmd)}\nexit={proc.returncode}\n\nSTDOUT\n{proc.stdout}\n\nSTDERR\n{proc.stderr}\n"
    )
    return payload


def emit_gates(harness: dict, pixel: dict | None = None) -> dict:
    head = git_sha()
    parent = parent_sha() or "af8dbf5941db21ed45e9206f6cd807d80ee3377d"
    harness_ok = bool(harness.get("ok")) and int(harness.get("exit_code", 0 if harness.get("ok") else 1)) == 0
    pixel = pixel or {}
    gates = {
        "program": "VXP-2.2",
        "title": "Post-human-playtest Anime combat space, ledges, CPU and start-flow closure",
        "parent_pr": 101,
        "parent_head_sha": parent,
        "head_sha": head,
        "branch": "vxp/vxp-2-2-anime-human-feedback-combat-closure",
        "emitted_at": now(),
        "ANIME_HF_COMBAT_SPACE_CALIBRATION_PASS": harness_ok and int(harness.get("combat_space", {}).get("out_of_band", 1)) == 0,
        "ANIME_HF_LEDGE_RECOVERY_PASS": harness_ok and "ledge_grab" in harness,
        "ANIME_HF_CPU_EDGE_AWARENESS_PASS": harness_ok and not bool(harness.get("cpu_edge_guard", {}).get("went_past_edge", True)),
        "ANIME_HF_CPU_DIFFICULTY_CURVE_PASS": harness_ok and len(harness.get("cpu_difficulty", [])) == 5,
        "ANIME_HF_COUNTDOWN_CPU_IDLE_PASS": harness_ok,
        "ANIME_HF_FIGHTER_SELECT_START_MATCH_PASS": harness_ok and bool(harness.get("fighter_select_cta", {}).get("PASS", False)),
        "ANIME_HF_MOVE_LIST_SIMPLE_LABELS_PASS": harness_ok and int(harness.get("move_list_raw_core_leaks", 1)) == 0,
        "ANIME_HF_BLAST_ZONE_AUTHORITY_PASS": harness_ok and bool(harness.get("blast_zone", {}).get("past_blast_ko", False)),
        "ANIME_HF_AUTOMATED_HARNESS_PASS": harness_ok,
        "ANIME_HF_PIXEL_PHYSICAL_PASS": bool(pixel.get("PIXEL_PHYSICAL_PASS", False)),
        "ANIME_HF_HUMAN_COMBAT_FEEL_PASS": False,
        "ANIME_HF_HUMAN_FUN_PASS": False,
        "ANIME_HF_MERGE_AUTHORIZED": False,
        "harness_exit_code": harness.get("exit_code"),
        "pixel": pixel,
    }
    REPORTS.mkdir(parents=True, exist_ok=True)
    path = REPORTS / "ANIME_HUMAN_FEEDBACK_GATES.json"
    path.write_text(json.dumps(gates, indent=2) + "\n")
    print("Wrote", path)
    return gates


def main() -> int:
    godot = resolve_godot()
    if not godot:
        print("Godot not found", file=sys.stderr)
        return 2
    print("Using Godot:", godot)
    harness = run_harness(godot)
    pixel_path = PIXEL / "PIXEL_HF_ACCEPTANCE.json"
    pixel = json.loads(pixel_path.read_text()) if pixel_path.exists() else {}
    gates = emit_gates(harness, pixel)
    print(json.dumps({k: gates[k] for k in gates if k.startswith("ANIME_HF")}, indent=2))
    return 0 if gates.get("ANIME_HF_AUTOMATED_HARNESS_PASS") else 1


if __name__ == "__main__":
    raise SystemExit(main())
