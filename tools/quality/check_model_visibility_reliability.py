#!/usr/bin/env python3
"""Static reliability checks for nameplate-vs-model visibility contracts.

NAMEPLATE_VISIBLE_AND_MODEL_MISSING = failure (T0).

Documents Pixel + BattleScene campaign requirements. Does not invent Pixel evidence.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

FIGHTER_GD = ROOT / "game-godot" / "scripts" / "fighters" / "fighter.gd"
MODEL_GD = ROOT / "game-godot" / "scripts" / "fighters" / "fighter_model_3d.gd"
FIGHTER_TSCN = ROOT / "game-godot" / "scenes" / "fighters" / "Fighter.tscn"
HARNESS = ROOT / "game-godot" / "tests" / "quality" / "TasteGateModelVisibility.gd"
WAVE014_E2E = ROOT / "artifacts" / "engineering_wave014" / "BATTLESCENE_VISUAL_E2E.json"


def main() -> int:
    checks: list[dict] = []

    fighter_text = FIGHTER_GD.read_text(encoding="utf-8") if FIGHTER_GD.exists() else ""
    model_text = MODEL_GD.read_text(encoding="utf-8") if MODEL_GD.exists() else ""
    tscn_text = FIGHTER_TSCN.read_text(encoding="utf-8") if FIGHTER_TSCN.exists() else ""

    has_nameplate = "NameLabel" in tscn_text or "NameLabel" in fighter_text
    hides_body_when_model = "body.visible = not model_loaded" in fighter_text
    has_is_model_loaded = (
        "func is_model_loaded()" in fighter_text or "func is_model_loaded()" in model_text
    )
    harness_exists = HARNESS.exists()

    checks.append(
        {
            "id": "nameplate_node_present",
            "pass": has_nameplate,
            "note": "Fighter exposes NameLabel (nameplate)",
        }
    )
    checks.append(
        {
            "id": "body_hidden_when_model_loaded",
            "pass": hides_body_when_model,
            "note": "ColorRect Body hidden when 3D model loads (anti nameplate-only)",
        }
    )
    checks.append(
        {
            "id": "is_model_loaded_api",
            "pass": has_is_model_loaded,
            "note": "Runtime API to detect model load",
        }
    )
    checks.append(
        {
            "id": "godot_harness_present",
            "pass": harness_exists,
            "note": "TasteGateModelVisibility.gd harness available for BattleScene",
        }
    )

    desktop_e2e = None
    if WAVE014_E2E.exists():
        try:
            desktop_e2e = json.loads(WAVE014_E2E.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            desktop_e2e = {"parse_error": True}

    desktop_ok = False
    if isinstance(desktop_e2e, dict):
        desktop_ok = bool(
            desktop_e2e.get("ok")
            or desktop_e2e.get("pass")
            or desktop_e2e.get("BATTLESCENE_VISUAL_E2E") == "PASS"
        )

    pixel_evidence = {
        "PIXEL_MODEL_VISIBILITY_VALIDATED": False,
        "PIXEL_EVIDENCE_INVENTED": False,
        "requirement": (
            "Physical Pixel 6a campaign must capture co-visibility of nameplate + model "
            "in BattleScene; do not mark pass without device screenshots + harness log."
        ),
        "campaign_doc": "docs/design/GOLDEN_VERTICAL_SLICE.md",
        "reliability_doc": "docs/quality/MODEL_VISIBILITY_RELIABILITY.md",
    }

    nameplate_model_contract_defined = (
        has_nameplate and hides_body_when_model and has_is_model_loaded
    )

    out = {
        "NAMEPLATE_VISIBLE_AND_MODEL_MISSING": "failure",
        "STATIC_CONTRACT_DEFINED": nameplate_model_contract_defined,
        "STATIC_CHECKS": checks,
        "DESKTOP_BATTLESCENE_EVIDENCE": {
            "path": str(WAVE014_E2E.relative_to(ROOT)) if WAVE014_E2E.exists() else None,
            "present": WAVE014_E2E.exists(),
            "interpreted_pass": desktop_ok,
            "note": (
                "Wave014 BattleScene visual E2E asserts model loaded for seven fighters. "
                "Re-run harness for fresh SHA; do not treat stale JSON as Pixel proof."
            ),
        },
        "PIXEL_CAMPAIGN": pixel_evidence,
        "HUMAN_Q5": False,
        "pass": nameplate_model_contract_defined and harness_exists,
    }

    dest = ROOT / "artifacts" / "taste_gate" / "MODEL_VISIBILITY_RELIABILITY.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    return 0 if out["pass"] else 1


if __name__ == "__main__":
    sys.exit(main())
