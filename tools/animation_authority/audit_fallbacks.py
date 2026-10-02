#!/usr/bin/env python3
"""Fail if PROCEDURAL_FALLBACK is relabeled as authored completion."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SPECTRUM = [
    "ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
    "nix-calder", "orion-vell", "vesper-nyx",
]
AUTHORED_CLAIMS = {"AUTHORED_COMPLETE", "PASS_WITH_EVIDENCE", "AUTHORED_FINAL"}


def main() -> int:
    errors = []
    wave = ROOT / "art_source/animation/manifests/WAVE_A_PRODUCTION_98.json"
    if wave.is_file():
        data = json.loads(wave.read_text(encoding="utf-8"))
        if int(data.get("authored_complete_count", 0)) > 0 and data.get("human_approved") is True:
            errors.append("WAVE_A claims authored+human_approved without separate evidence")
        for action in data.get("actions", []):
            st = action.get("status")
            if st in AUTHORED_CLAIMS and action.get("kind") == "PROCEDURAL_RUNTIME_ANIMATION":
                errors.append(f"WAVE_A procedural relabeled as {st}: {action.get('id')}")
    for fid in SPECTRUM:
        root = ROOT / "content/fighters" / fid / "animations/procedural"
        for path in root.glob("*.anim.json"):
            clip = json.loads(path.read_text(encoding="utf-8"))
            if clip.get("kind") == "PROCEDURAL_RUNTIME_ANIMATION" and clip.get("human_approval") is True:
                errors.append(f"{path.relative_to(ROOT)} procedural clip claims human_approval=true")
            if clip.get("authority_status") == "PROCEDURAL_FALLBACK" and clip.get("status") in AUTHORED_CLAIMS:
                errors.append(f"{path.relative_to(ROOT)} fallback relabeled authored")
    audit = ROOT / "artifacts/animation_authority_v1/CURRENT_ANIMATION_STATE_AUDIT.json"
    if audit.is_file():
        census = json.loads(audit.read_text(encoding="utf-8"))
        for row in census.get("rows", []):
            if row.get("status") in AUTHORED_CLAIMS:
                # Allow only if evidence explicitly says authored source — currently none expected.
                ev = " ".join(row.get("evidence") or [])
                if "PROCEDURAL" in ev.upper() or "procedural" in (row.get("source_path") or ""):
                    errors.append(f"audit row {row.get('fighter_id')}/{row.get('slot_id')} authored claim over procedural")
    if errors:
        print("FAIL audit_fallbacks:\n" + "\n".join(errors[:40]), file=sys.stderr)
        return 1
    print("PASS audit_fallbacks")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
