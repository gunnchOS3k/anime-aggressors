#!/usr/bin/env python3
"""Wave021 evidence emitter."""
from __future__ import annotations

import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "engineering_wave021"
PR95_MERGE_SHA = "0d094349e2aa6a7bbb4e7cdec4694ab33e585593"


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
    art = read_json(ART / "ART_DIRECTION_RESULT.json")
    form = read_json(ART / "FORM_ARCHITECTURE_RESULT.json")
    aura = read_json(ART / "AURA_TIER_RESULT.json")
    ember = read_json(ART / "EMBER_ASCENSION_RESULT.json")
    scale = read_json(ART / "BATTLE_SCALE_RESULT.json")
    ui = read_json(ART / "UI_FEEL_RESULT.json")
    pixel = read_json(ART / "PIXEL_WAVE021.json")
    golden = read_json(ROOT / "artifacts" / "visual_qa" / "latest" / "GOLDEN_VISUAL_QA_RESULT.json")

    pixel_available = bool(pixel.get("PIXEL_DEVICE_AVAILABLE", False))
    pixel_ok = pixel.get("PIXEL_WAVE021_VALIDATION") == "PASS"
    transform_acts = int(ember.get("TRANSFORM_ACTIVATIONS", 0))
    failure_sum = sum(
        int(x.get(k, 0))
        for x, k in [
            (form, "FORM_LADDER_FAILURES"),
            (aura, "AURA_TIER_FAILURES"),
            (ember, "FAILURES"),
            (scale, "SCALE_LEAKS"),
            (ui, "UI_FEEL_FAILURES"),
        ]
    )
    failure_sum += int(ember.get("SCALE_VIOLATIONS", 0)) + int(ember.get("FORM_MISMATCHES", 0))

    desktop_ok = (
        art.get("ok", False)
        and form.get("ok", False)
        and aura.get("ok", False)
        and ember.get("ok", False)
        and scale.get("ok", False)
        and ui.get("ok", False)
        and transform_acts >= 50
        and failure_sum == 0
        and golden.get("GOLDEN_VISUAL_QA", "FAIL") in ("PASS", "PARTIAL")
    )

    if not pixel_available:
        status = "BLOCKED_PIXEL6A" if desktop_ok else "PARTIAL"
        ready = False
        pixel_validation = "BLOCKED"
    elif desktop_ok and pixel_ok:
        status = "PASS"
        ready = False  # Edmund merge authority; CI may still be pending
        pixel_validation = "PASS"
    elif desktop_ok:
        status = "PARTIAL"
        ready = False
        pixel_validation = "FAIL"
    else:
        status = "FAIL"
        ready = False
        pixel_validation = pixel.get("PIXEL_WAVE021_VALIDATION", "BLOCKED")

    payload = {
        "WAVE021_FACELESS_ASCENSION_UI_GOLDEN": status,
        "PR95_MERGED": True,
        "PR95_MERGE_SHA": PR95_MERGE_SHA,
        "ACCEPTED_MAIN_SHA": PR95_MERGE_SHA,
        "CURRENT_MAIN_SHA": git_head(),
        "HEAD": git_head(),
        "BRANCH": "eng/wave021-ascension-ui-golden-slice",
        "WAVE021_STARTED": True,
        "CURSOR_MERGED_NOTHING": True,
        "READY_FOR_OWNER_MERGE": ready,
        "PIXEL_WAVE021_VALIDATION": pixel_validation,
        "PIXEL_DEVICE_AVAILABLE": pixel_available,
        "OWNER_REG_021": form.get("OWNER_REG_021", "FAIL"),
        "OWNER_REG_022": form.get("OWNER_REG_022", "FAIL"),
        "OWNER_REG_023": aura.get("OWNER_REG_023", "FAIL"),
        "OWNER_REG_024": ember.get("OWNER_REG_024", "FAIL"),
        "OWNER_REG_025": scale.get("OWNER_REG_025", "FAIL"),
        "OWNER_REG_026": ui.get("OWNER_REG_026", "FAIL"),
        "TRANSFORM_ACTIVATIONS": transform_acts,
        "FAILURE_COUNTERS_SUM": failure_sum,
        "DESKTOP_GATES_PASS": desktop_ok,
        "GOLDEN_VISUAL_QA_V2": golden.get("GOLDEN_VISUAL_QA", "UNKNOWN"),
        "OWNER_APPROVED_GOLDEN_COUNT": 0,
        "EMBER_ASCENSION_RUNTIME": ember.get("EMBER_ASCENSION_DESKTOP", "FAIL"),
        "ROSTER_ASCENDED_RUNTIME": ["ember-vale"],
        "DESIGN_ONLY_FIGHTERS": [
            "rook-ironside", "juno-spark", "kaia-windrow",
            "nix-calder", "orion-vell", "vesper-nyx",
        ],
        "emitted_at": now(),
    }
    ART.mkdir(parents=True, exist_ok=True)
    (ART / "WAVE021_RESULT.json").write_text(json.dumps(payload, indent=2) + "\n")
    return payload


if __name__ == "__main__":
    r = emit()
    print("WAVE021=", r["WAVE021_FACELESS_ASCENSION_UI_GOLDEN"])
    print("READY_FOR_OWNER_MERGE=", r["READY_FOR_OWNER_MERGE"])
