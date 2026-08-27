#!/usr/bin/env python3
"""Wave022 evidence emitter."""
from __future__ import annotations

import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "engineering_wave022"
PR96_MERGE_SHA = "419c5fc3a500445c21b24f730d2162ff6cffbc38"
ROSTER = [
    "ember-vale",
    "rook-ironside",
    "juno-spark",
    "kaia-windrow",
    "nix-calder",
    "orion-vell",
    "vesper-nyx",
]


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def read_json(path: Path) -> dict:
    if not path.is_file():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def git_head() -> str:
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    except Exception:
        return "UNKNOWN"


def emit() -> dict:
    form = read_json(ART / "FORM_ARCHITECTURE_RESULT.json")
    scale = read_json(ART / "BATTLE_SCALE_RESULT.json")
    ui = read_json(ART / "UI_FEEL_RESULT.json")
    ascension = read_json(ART / "FULL_ROSTER_ASCENSION_RESULT.json")
    regression = read_json(ART / "REGRESSION_MATRIX_RESULT.json")
    pixel = read_json(ART / "PIXEL_WAVE022.json")
    golden = read_json(ROOT / "artifacts" / "visual_qa" / "latest" / "GOLDEN_VISUAL_QA_RESULT.json")

    pixel_available = bool(pixel.get("PIXEL_DEVICE_AVAILABLE", False))
    pixel_ok = pixel.get("PIXEL_WAVE022_VALIDATION") == "PASS"
    transform_total = int(ascension.get("TRANSFORM_ACTIVATIONS_TOTAL", 0))
    per_fighter = ascension.get("per_fighter", {})
    failure_sum = sum(
        int(x.get(k, 0))
        for x, k in [
            (form, "FORM_LADDER_FAILURES"),
            (scale, "SCALE_LEAKS"),
            (ui, "UI_FEEL_FAILURES"),
            (ascension, "FAILURES"),
            (regression, "REGRESSION_FAILURES"),
        ]
    )
    failure_sum += int(ascension.get("SCALE_VIOLATIONS", 0)) + int(ascension.get("FORM_MISMATCHES", 0))

    per_fighter_ok = all(
        int(per_fighter.get(fid, {}).get("TRANSFORM_ACTIVATIONS", 0)) >= 30 for fid in ROSTER
    )

    desktop_ok = (
        form.get("ok", False)
        and scale.get("ok", False)
        and ui.get("ok", False)
        and ascension.get("ok", False)
        and transform_total >= 210
        and per_fighter_ok
        and failure_sum == 0
        and regression.get("ok", True)
        and golden.get("GOLDEN_VISUAL_QA", "FAIL") in ("PASS", "PARTIAL")
    )

    if not pixel_available:
        status = "BLOCKED_PIXEL6A" if desktop_ok else "PARTIAL"
        pixel_validation = "BLOCKED"
    elif desktop_ok and pixel_ok:
        status = "PASS"
        pixel_validation = "PASS"
    elif desktop_ok:
        status = "PARTIAL"
        pixel_validation = "FAIL"
    else:
        status = "FAIL"
        pixel_validation = pixel.get("PIXEL_WAVE022_VALIDATION", "BLOCKED")

    payload = {
        "WAVE022_FULL_ROSTER_ASCENSION": status,
        "PR96_MERGED": True,
        "PR96_MERGE_SHA": PR96_MERGE_SHA,
        "ACCEPTED_MAIN_SHA": PR96_MERGE_SHA,
        "CURRENT_MAIN_SHA": git_head(),
        "HEAD": git_head(),
        "BRANCH": "eng/wave022-full-roster-ascension",
        "WAVE022_STARTED": True,
        "WAVE023_STARTED": False,
        "CURSOR_MERGED_NOTHING": True,
        "READY_FOR_OWNER_MERGE": False,
        "PIXEL_WAVE022_VALIDATION": pixel_validation,
        "PIXEL_DEVICE_AVAILABLE": pixel_available,
        "OWNER_REG_027": form.get("OWNER_REG_027", "FAIL"),
        "OWNER_REG_028": form.get("OWNER_REG_028", "FAIL"),
        "OWNER_REG_029": golden.get("GOLDEN_VISUAL_QA", "FAIL"),
        "OWNER_REG_030": regression.get("OWNER_REG_030", "PENDING"),
        "OWNER_REG_031": ascension.get("OWNER_REG_031", "FAIL"),
        "TRANSFORM_ACTIVATIONS_TOTAL": transform_total,
        "TRANSFORM_ACTIVATIONS_TARGET": 210,
        "FAILURE_COUNTERS_SUM": failure_sum,
        "DESKTOP_GATES_PASS": desktop_ok,
        "GOLDEN_VISUAL_QA_FULL_ROSTER": golden.get("GOLDEN_VISUAL_QA", "UNKNOWN"),
        "OWNER_APPROVED_GOLDEN_COUNT": 0,
        "FULL_ROSTER_ASCENSION_RUNTIME": ROSTER,
        "ROSTER_ASCENSION_RUNTIME_COUNT": int(form.get("ROSTER_ASCENSION_RUNTIME_COUNT", 0)),
        "per_fighter_transforms": {
            fid: int(per_fighter.get(fid, {}).get("TRANSFORM_ACTIVATIONS", 0)) for fid in ROSTER
        },
        "emitted_at": now(),
    }
    ART.mkdir(parents=True, exist_ok=True)
    (ART / "WAVE022_RESULT.json").write_text(json.dumps(payload, indent=2) + "\n")
    return payload


if __name__ == "__main__":
    r = emit()
    print("WAVE022=", r["WAVE022_FULL_ROSTER_ASCENSION"])
    print("READY_FOR_OWNER_MERGE=", r["READY_FOR_OWNER_MERGE"])
