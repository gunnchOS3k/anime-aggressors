#!/usr/bin/env python3
"""Run VXP-2.3 Match Settings harness and emit VXP23_MATCH_SETTINGS_GATES.json."""
from __future__ import annotations

import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "vxp23"
REPORTS = ART / "reports"
PIXEL = ART / "pixel"
GODOT_PROJECT = ROOT / "game-godot"
PARENT_EXPECTED = "d4298aadf35f4c147808037866545686ebd18a62"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def sh(cmd: list[str], timeout: int = 300) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, timeout=timeout)


def resolve_godot() -> str | None:
    import os

    if os.environ.get("GODOT_BIN"):
        return os.environ["GODOT_BIN"]
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
    return r.stdout.strip() if r.returncode == 0 else ""


def run_harness(godot: str) -> dict:
    REPORTS.mkdir(parents=True, exist_ok=True)
    script = "res://tests/vxp23_ms/MatchSettingsHarness.gd"
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
    out = REPORTS / "MATCH_SETTINGS_HARNESS.json"
    payload: dict = {}
    if out.exists():
        payload = json.loads(out.read_text())
    payload["exit_code"] = proc.returncode
    payload["stdout_tail"] = (proc.stdout or "")[-5000:]
    payload["stderr_tail"] = (proc.stderr or "")[-5000:]
    (REPORTS / "MATCH_SETTINGS_HARNESS_RUN.txt").write_text(
        f"cmd={' '.join(cmd)}\nexit={proc.returncode}\n\nSTDOUT\n{proc.stdout}\n\nSTDERR\n{proc.stderr}\n"
    )
    return payload


def load_pixel() -> dict:
    p = PIXEL / "PIXEL_MATCH_SETTINGS_ACCEPTANCE.json"
    if p.exists():
        return json.loads(p.read_text())
    return {}


def parent_verified(head: str, parent: str) -> bool:
    if head == PARENT_EXPECTED or parent == PARENT_EXPECTED:
        return True
    r = sh(["git", "merge-base", "--is-ancestor", PARENT_EXPECTED, "HEAD"])
    return r.returncode == 0


def emit_gates(harness: dict, pixel: dict | None = None) -> dict:
    head = git_sha()
    parent = parent_sha()
    harness_ok = bool(harness.get("ok")) and int(harness.get("exit_code", 1)) == 0
    cta = harness.get("match_settings_cta") or {}
    short = harness.get("match_settings_short_viewport") or {}
    fs = harness.get("fighter_select_cta") or {}
    route = harness.get("continue_route") or {}
    pixel = pixel or {}
    cpu_names = harness.get("cpu_display_names") or []
    cpu_ok = len(cpu_names) == 5 and "Novice" in str(cpu_names[0]) and "Master" in str(cpu_names[-1])

    pixel_cta = bool(pixel.get("PIXEL_MATCH_SETTINGS_CTA_PASS", False))
    pixel_scroll = bool(pixel.get("PIXEL_SCROLL_AND_CTA_PASS", False))
    pixel_continue = bool(pixel.get("PIXEL_CONTINUE_TO_FIGHTERS_PASS", False))

    gates = {
        "program": "VXP-2.3",
        "title": "Post-human-playtest: fix Anime Match Settings progression on Pixel",
        "parent_pr": 102,
        "parent_head_sha": parent if parent != head else PARENT_EXPECTED,
        "parent_expected_sha": PARENT_EXPECTED,
        "head_sha": head,
        "branch": "vxp/vxp-2-3-anime-match-settings-pixel-progression",
        "emitted_at": now(),
        "harness_ok": harness_ok,
        "VXP23_PARENT_PR102_VERIFIED": parent_verified(head, parent),
        "VXP23_MATCH_SETTINGS_SCROLL_BODY_PASS": bool(cta.get("MATCH_SETTINGS_SCROLL_BODY_PRESENT")) and harness_ok,
        "VXP23_MATCH_SETTINGS_PRIMARY_CTA_VISIBLE_PASS": bool(cta.get("MATCH_SETTINGS_CTA_PRESENT")) and harness_ok,
        "VXP23_MATCH_SETTINGS_SAFE_AREA_PASS": bool(cta.get("MATCH_SETTINGS_CTA_SAFE_AREA")) and harness_ok,
        "VXP23_MATCH_SETTINGS_ALL_CONTROLS_REACHABLE_PASS": bool(cta.get("MATCH_SETTINGS_ALL_CONTROLS_REACHABLE"))
        and harness_ok,
        "VXP23_MATCH_SETTINGS_CONTINUE_ROUTE_PASS": bool(route.get("routed")) and harness_ok,
        "VXP23_CPU_DIFFICULTY_LABELS_PASS": cpu_ok and harness_ok,
        "VXP23_PRESET_CONTROLS_REACHABLE_PASS": bool((cta.get("CONTROLS") or {}).get("all_present")) and harness_ok,
        "VXP23_FIGHTER_SELECT_CTA_TRUTHFUL_PASS": bool(fs.get("FIGHTER_SELECT_CTA_TRUTHFUL")) and harness_ok,
        "VXP23_FIGHTER_SELECT_TO_STAGE_ROUTE_PASS": bool(fs.get("FIGHTER_SELECT_CTA_ROUTES_TO_STAGE_SELECT", True))
        and harness_ok,
        "VXP23_PIXEL_MATCH_SETTINGS_CTA_PASS": pixel_cta,
        "VXP23_PIXEL_SCROLL_AND_CTA_PASS": pixel_scroll,
        "VXP23_PIXEL_CONTINUE_TO_FIGHTERS_PASS": pixel_continue,
        "VXP23_HUMAN_VISUAL_VALIDATION_PASS": False,
        "VXP23_HUMAN_FLOW_VALIDATION_PASS": False,
        "VXP23_MERGE_AUTHORIZED": False,
        "MATCH_SETTINGS_PIXEL_SHORT_VIEWPORT_PASS": bool(short.get("MATCH_SETTINGS_PIXEL_SHORT_VIEWPORT_PASS")),
        "pixel": pixel,
        "harness_failures": harness.get("failures", []),
    }
    REPORTS.mkdir(parents=True, exist_ok=True)
    (REPORTS / "VXP23_MATCH_SETTINGS_GATES.json").write_text(json.dumps(gates, indent=2) + "\n")
    return gates


def main() -> int:
    godot = resolve_godot()
    if not godot:
        print("Godot not found", file=sys.stderr)
        return 2
    harness = run_harness(godot)
    pixel = load_pixel()
    gates = emit_gates(harness, pixel)
    print(json.dumps({k: gates[k] for k in gates if k.startswith("VXP23_")}, indent=2))
    return 0 if harness.get("ok") and int(harness.get("exit_code", 1)) == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
