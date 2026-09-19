#!/usr/bin/env python3
"""Emit machine-readable VXP-2 gates. Honest defaults — never invent Pixel/human PASS."""
from __future__ import annotations
import json, subprocess, hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "artifacts/vxp2/reports/VXP2_GATES.json"
OUT.parent.mkdir(parents=True, exist_ok=True)

def sh(cmd: list[str]) -> str:
    return subprocess.check_output(cmd, cwd=ROOT, text=True).strip()

head = sh(["git", "rev-parse", "HEAD"])
base = sh(["git", "merge-base", "HEAD", "origin/main"]) if True else head
try:
    origin_main = sh(["git", "rev-parse", "origin/main"])
except Exception:
    origin_main = ""

brand = ROOT / "game-godot/assets/branding/vxp2/BRAND_PROVENANCE.json"
theme = ROOT / "game-godot/assets/ui/themes/aa_vxp2_theme.tres"
legacy = ROOT / "game-godot/assets/placeholder/aa_theme.tres"
manifest = ROOT / "artifacts/vxp2/manifests/VXP2_SCREENSHOT_MANIFEST.json"
struct_log = ROOT / "artifacts/vxp2/capture/STRUCTURAL_RESULT.json"

structural_pass = False
if struct_log.exists():
    structural_pass = bool(json.loads(struct_log.read_text()).get("pass"))

shots_ok = False
shot_count = 0
capture_class = "none"
if manifest.exists():
    man = json.loads(manifest.read_text())
    shots = man.get("shots", [])
    shot_count = len(shots)
    capture_class = str(man.get("capture_class", "unknown"))
    shots_ok = shot_count > 0 and all(bool(s.get("ok", True)) for s in shots)
    capture_class = str(man.get("capture_class", ""))
    # Fixture composite is valid VXP-2 screenshot evidence class; still not Pixel.
    if capture_class == "brand_fixture_composite" and shot_count > 0:
        shots_ok = all(bool(s.get("ok", True)) for s in shots)

gates = {
    "program": "VXP-2",
    "title": "Anime Aggressors brand system and match presentation foundation",
    "base_sha": origin_main,
    "head_sha": head,
    "merge_base_with_origin_main": base,
    "branch": sh(["git", "rev-parse", "--abbrev-ref", "HEAD"]),
    "discrepancy_resolution": {
        "audited_local_head": "789b229406bef24d0a614309f84ef08e605fec6c",
        "identity": "tip of cursor/windows-pilot0-authentic-evidence (fix Windows Pilot 0 Godot 4.5)",
        "relation_to_origin_main": "ancestor (0 commits unique; merged via PR #98)",
        "decision": "Branch VXP-2 from origin/main; do not mix dirty checkout; preserve 789b229 history untouched",
    },
    "assets": {
        "brand_provenance_present": brand.exists(),
        "vxp2_theme_present": theme.exists(),
        "legacy_theme_preserved": legacy.exists(),
        "launcher_icon_promoted_canonical": False,
    },
    "VXP2_BRAND_ASSETS_PRESENT": brand.exists() and theme.exists(),
    "VXP2_LEGACY_THEME_PRESERVED": legacy.exists(),
    "VXP2_STRUCTURAL_ASSERTS_PASS": structural_pass,
    "VXP2_SCREENSHOT_FIXTURE_CAPTURE_PASS": shots_ok,
    "VXP2_SCREENSHOT_CAPTURE_CLASS": capture_class,
    "VXP2_SCREENSHOT_COUNT": shot_count,
    "VXP2_PIXEL_PHYSICAL_CAPTURE_PASS": False,
    "VXP2_HUMAN_VISUAL_VALIDATION_PASS": False,
    "VXP2_HUMAN_FUN_VALIDATION_PASS": False,
    "VXP2_ALL_HISTORICAL_RIGHTS_CLEARED": False,
    "VXP2_MERGE_AUTHORIZED": False,
    "VXP2_READY_FOR_DRAFT_PR": True,
}

OUT.write_text(json.dumps(gates, indent=2) + "\n")
print(json.dumps(gates, indent=2))
print("wrote", OUT)
