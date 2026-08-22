#!/usr/bin/env python3
"""Wave011 mutation campaign — disposable dirs only. Never commits mutants.

Kill only if: clean parse+test PASS, mutation applied, mutated parse PASS,
mutated test FAIL with behavioral assertions. Else INVALID_MUTATION.
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GODOT_SRC = ROOT / "game-godot"
OUT = ROOT / "artifacts/engineering_wave011/MUTATION_RESULT.json"

ROSTER_SCRIPT = "res://tests/engineering_wave011/Wave011RosterRuntimeE2E.gd"

MUTATION_ROSTER_HARNESS = {"charge_move_mult_zero"}

MUTATIONS = [
    (
        "charge_disabled",
        "scripts/combat/combat_math.gd",
        "const AURA_CHARGE_PER_SECOND := 35.0",
        "const AURA_CHARGE_PER_SECOND := 0.0",
    ),
    (
        "idle_decay_disabled",
        "scripts/combat/combat_math.gd",
        "const AURA_IDLE_DECAY_PER_SECOND := 4.0",
        "const AURA_IDLE_DECAY_PER_SECOND := 0.0",
    ),
    (
        "stale_floor_neutral",
        "scripts/combat/combat_math.gd",
        "const STALE_FLOOR := 0.55",
        "const STALE_FLOOR := 1.0",
    ),
    (
        "grab_range_collapsed",
        "scripts/combat/combat_math.gd",
        "const GRAB_RANGE_PX := 70.0",
        "const GRAB_RANGE_PX := 1.0",
    ),
    (
        "shield_regen_disabled",
        "scripts/combat/combat_math.gd",
        "const SHIELD_REGEN_PER_SECOND := 14.0",
        "const SHIELD_REGEN_PER_SECOND := 0.0",
    ),
    (
        "mash_disabled",
        "scripts/combat/combat_math.gd",
        "const GRAB_MASH_PER_PRESS := 0.28",
        "const GRAB_MASH_PER_PRESS := 0.0",
    ),
    (
        "interrupt_loss_disabled",
        "scripts/combat/combat_math.gd",
        "const AURA_HIT_INTERRUPT_LOSS := 20.0",
        "const AURA_HIT_INTERRUPT_LOSS := 0.0",
    ),
    (
        "ember_charge_flat",
        "scripts/combat/aura_identity.gd",
        '"charge_rate_mult": 1.12,',
        '"charge_rate_mult": 1.00,',
    ),
    (
        "rook_air_accel_flat",
        "scripts/combat/aura_identity.gd",
        '"air_accel": 900.0,',
        '"air_accel": 1550.0,',
    ),
    (
        "projectile_mask_zero",
        "scripts/combat/projectile.gd",
        "collision_mask = 6",
        "collision_mask = 0",
    ),
    (
        "stocks_not_competitive",
        "scripts/combat/competitive_rules.gd",
        "const STOCKS := 3",
        "const STOCKS := 99",
    ),
    (
        "dodge_invuln_zero",
        "scripts/combat/combat_math.gd",
        "const GROUND_DODGE_INVULN := 0.10",
        "const GROUND_DODGE_INVULN := 0.0",
    ),
    (
        "charge_move_mult_zero",
        "scripts/combat/aura_identity.gd",
        '"charge_move_mult": 0.48,',
        '"charge_move_mult": 0.0,',
    ),
]


def resolve_godot() -> str:
    env = os.environ.get("GODOT_BIN")
    if env and Path(env).exists():
        return env
    for c in (
        "/Applications/Godot.app/Contents/MacOS/Godot",
        "/opt/homebrew/bin/godot",
    ):
        if Path(c).exists():
            return c
    return shutil.which("godot") or ""


def copy_tree(dst: Path) -> None:
    names = (
        "scripts",
        "tests",
        "data",
        "scenes",
        "docs",
        "project.godot",
        "icon.svg",
        "icon.png",
        "export_icon.png",
    )
    for name in names:
        src = GODOT_SRC / name
        if not src.exists():
            continue
        target = dst / name
        if src.is_dir():
            shutil.copytree(src, target, ignore=shutil.ignore_patterns("*.uid", "*.glb"))
        else:
            shutil.copy2(src, target)
    # Minimal assets so scenes resolve (skip heavy glb).
    assets = GODOT_SRC / "assets"
    if assets.exists():
        shutil.copytree(
            assets,
            dst / "assets",
            ignore=shutil.ignore_patterns("*.glb", "*.import", "procedural_final", "characters"),
            dirs_exist_ok=True,
        )
    (dst / "artifacts/engineering_wave011").mkdir(parents=True, exist_ok=True)


def run_component(godot: str, work: Path) -> tuple[int, str]:
    proc = subprocess.run(
        [
            godot,
            "--headless",
            "--path",
            str(work),
            "--script",
            "res://tests/engineering_wave011/Wave011RuntimeTest.gd",
        ],
        cwd=work,
        capture_output=True,
        text=True,
        timeout=240,
    )
    log = (proc.stdout or "") + (proc.stderr or "")
    return proc.returncode, log


def run_roster(godot: str, work: Path) -> tuple[int, str]:
    proc = subprocess.run(
        [
            godot,
            "--headless",
            "--path",
            str(work),
            "--script",
            ROSTER_SCRIPT,
        ],
        cwd=work,
        capture_output=True,
        text=True,
        timeout=600,
    )
    log = (proc.stdout or "") + (proc.stderr or "")
    return proc.returncode, log


def parse_ok(log: str) -> bool:
    bad = ("Parse Error", "Compilation failed", "SCRIPT ERROR: Parse Error")
    return not any(b in log for b in bad)


def behavioral_fail(log: str, code: int) -> bool:
    if not parse_ok(log):
        return False
    if "Wave011RuntimeTest FAIL" in log or "FAIL:" in log:
        return True
    if code != 0 and "Wave011RuntimeTest PASS" not in log and "WAVE011_COMPONENT_RUNTIME_PASS" not in log:
        return "FAIL:" in log
    return False


def roster_behavioral_fail(log: str, code: int) -> bool:
    if not parse_ok(log):
        return False
    if "Wave011RosterRuntimeE2E FAIL" in log or "FAIL:" in log:
        return True
    if code != 0 and "Wave011RosterRuntimeE2E PASS" not in log:
        return "FAIL:" in log
    return False


def run_one(godot: str, work: Path, mid: str, rel: str, old: str, new: str, clean_ok: bool) -> dict:
    if not clean_ok:
        return {
            "id": mid,
            "killed": False,
            "invalid": True,
            "reason": "INVALID_MUTATION:clean_baseline_not_pass",
        }
    target = work / rel
    text = target.read_text()
    if old not in text:
        return {
            "id": mid,
            "killed": False,
            "invalid": True,
            "reason": "INVALID_MUTATION:pattern_not_found",
        }
    target.write_text(text.replace(old, new, 1))
    if old in target.read_text() and new not in target.read_text():
        return {
            "id": mid,
            "killed": False,
            "invalid": True,
            "reason": "INVALID_MUTATION:mutation_not_applied",
        }
    subprocess.run(
        [godot, "--headless", "--path", str(work), "--import"],
        cwd=work,
        capture_output=True,
        text=True,
        timeout=120,
    )
    code, log = run_component(godot, work)
    if not parse_ok(log):
        return {
            "id": mid,
            "killed": False,
            "invalid": True,
            "reason": "INVALID_MUTATION:mutated_parse_failed",
            "exit": code,
            "log_tail": "\n".join(log.splitlines()[-40:]),
        }
    if "Wave011RuntimeTest PASS" in log and "WAVE011_COMPONENT_RUNTIME_PASS" in log and code == 0:
        if mid in MUTATION_ROSTER_HARNESS:
            rcode, rlog = run_roster(godot, work)
            if not parse_ok(rlog):
                return {
                    "id": mid,
                    "killed": False,
                    "invalid": True,
                    "reason": "INVALID_MUTATION:roster_harness_parse_failed",
                    "exit": rcode,
                    "log_tail": "\n".join(rlog.splitlines()[-40:]),
                }
            if roster_behavioral_fail(rlog, rcode):
                return {
                    "id": mid,
                    "killed": True,
                    "invalid": False,
                    "behavioral": True,
                    "reason": "behavioral_kill:roster_harness",
                    "exit": rcode,
                    "log_tail": "\n".join(rlog.splitlines()[-30:]),
                }
        return {
            "id": mid,
            "killed": False,
            "invalid": False,
            "reason": "survived",
            "exit": code,
            "log_tail": "\n".join(log.splitlines()[-30:]),
        }
    if behavioral_fail(log, code):
        return {
            "id": mid,
            "killed": True,
            "invalid": False,
            "behavioral": True,
            "reason": "behavioral_kill",
            "exit": code,
            "log_tail": "\n".join(log.splitlines()[-30:]),
        }
    return {
        "id": mid,
        "killed": False,
        "invalid": True,
        "reason": "INVALID_MUTATION:no_behavioral_assertion_failure",
        "exit": code,
        "log_tail": "\n".join(log.splitlines()[-40:]),
    }


def main() -> int:
    godot = resolve_godot()
    if not godot:
        print("Godot not found", file=sys.stderr)
        return 2

    with tempfile.TemporaryDirectory(prefix="aa-wave011-mut-") as tmp:
        clean = Path(tmp) / "clean"
        clean.mkdir()
        copy_tree(clean)
        subprocess.run(
            [godot, "--headless", "--path", str(clean), "--import"],
            cwd=clean,
            capture_output=True,
            text=True,
            timeout=180,
        )
        clean_code, clean_log = run_component(godot, clean)
        clean_ok = (
            parse_ok(clean_log)
            and clean_code == 0
            and "Wave011RuntimeTest PASS" in clean_log
        )
        results = []
        for mid, rel, old, new in MUTATIONS:
            work = Path(tmp) / mid
            work.mkdir()
            copy_tree(work)
            results.append(run_one(godot, work, mid, rel, old, new, clean_ok))

    attempted = len(results)
    invalid = sum(1 for r in results if r.get("invalid"))
    behavioral_killed = sum(1 for r in results if r.get("killed") and r.get("behavioral"))
    killed = sum(1 for r in results if r.get("killed"))
    payload = {
        "schema": "gunnchos.engineering_wave011.mutation.v1",
        "clean_baseline_pass": clean_ok,
        "WAVE011_MUTATIONS_ATTEMPTED": attempted,
        "WAVE011_MUTATIONS_KILLED": killed,
        "WAVE011_BEHAVIORAL_KILLED": behavioral_killed,
        "WAVE011_INVALID_MUTATIONS": invalid,
        "MUTATED_FILES_COMMITTED": False,
        "results": results,
        "pass": (
            clean_ok
            and invalid == 0
            and behavioral_killed >= 10
            and behavioral_killed == attempted
        ),
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps(payload, indent=2))
    return 0 if payload["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
