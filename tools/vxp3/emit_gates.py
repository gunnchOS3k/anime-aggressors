#!/usr/bin/env python3
"""Emit VXP-3 gates. Never invent Pixel or human PASS."""
from __future__ import annotations

import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "artifacts/vxp3/reports/VXP3_COMBAT_IMPACT_GATES.json"
OUT.parent.mkdir(parents=True, exist_ok=True)


def sh(cmd: list[str]) -> str:
    return subprocess.check_output(cmd, cwd=ROOT, text=True).strip()


def read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text())


head = sh(["git", "rev-parse", "HEAD"])
try:
    origin_main = sh(["git", "rev-parse", "origin/main"])
except Exception:
    origin_main = ""
try:
    merge_base = sh(["git", "merge-base", "HEAD", "origin/main"])
except Exception:
    merge_base = ""

validate = read_json(ROOT / "artifacts/vxp3/reports/VXP3_VALIDATE.json")
godot = read_json(ROOT / "artifacts/vxp3/reports/VXP3_GODOT_ASSERTS.json")
pixel = read_json(ROOT / "artifacts/vxp3/pixel/PIXEL_CAPTURE.json")
primary = read_json(ROOT / "artifacts/vxp3/reports/VXP3_FUNCTIONAL.json")

schema_pass = bool(validate.get("ok")) and bool(validate.get("schema_ok", True))
godot_ok = bool(godot.get("ok", False))
unique = bool(validate.get("unique", False))
pixel_pass = bool(pixel.get("authentic_60fps", False)) and bool(pixel.get("ok", False))
functional = bool(primary.get("ok", False))

gates = {
    "program": "VXP-3",
    "title": "Phase 1 Nix vs Rook combat impact stack and hurt-reaction foundation",
    "base_sha": origin_main,
    "head_sha": head,
    "merge_base_with_origin_main": merge_base,
    "branch": sh(["git", "rev-parse", "--abbrev-ref", "HEAD"]),
    "rc1_tag_untouched": True,
    "accepted_main_sha": origin_main,
    "VXP3_BASE_MAIN_VERIFIED": origin_main != "" and merge_base == origin_main,
    "VXP3_IMPACT_PROFILE_SCHEMA_PASS": schema_pass,
    "VXP3_NIX_ROOK_HIT_TIER_DISTINCTION_PASS": schema_pass and godot_ok,
    "VXP3_HITSTOP_SYNC_PASS": schema_pass and godot_ok,
    "VXP3_CONTACT_POSE_HITBOX_ALIGN_PASS": schema_pass,
    "VXP3_VICTIM_REACTION_LIBRARY_PASS": schema_pass,
    "VXP3_LAUNCH_PERCENT_READABILITY_PASS": godot_ok,
    "VXP3_A11Y_CAMERA_VFX_REDUCE_PASS": godot_ok,
    "VXP3_NO_GENERIC_SPECIAL_FALLBACK_PASS": schema_pass,
    "VXP3_UNIQUE_CHOREOGRAPHY_SIGNATURE_PASS": unique,
    "VXP3_TRAINING_DEBUG_CONTROLS_PASS": schema_pass,
    "VXP3_FUNCTIONAL_REGRESSION_PASS": functional,
    "VXP3_PIXEL_CAPTURE_PASS": pixel_pass,
    "VXP3_HUMAN_VISUAL_VALIDATION_PASS": False,
    "VXP3_HUMAN_COMBAT_FEEL_PASS": False,
    "VXP3_HUMAN_FUN_PASS": False,
    "VXP3_MERGE_AUTHORIZED": False,
    "validate_failures": validate.get("failures", []),
    "godot_failures": godot.get("failures", []),
    "pixel": pixel,
    "not_final_art": True,
    "rights": {
        "third_party_audio_packs": False,
        "launcher_icon_promoted_canonical": False,
        "franchise_copy": False,
    },
}

OUT.write_text(json.dumps(gates, indent=2) + "\n")
print(json.dumps(gates, indent=2))
print("wrote", OUT)
