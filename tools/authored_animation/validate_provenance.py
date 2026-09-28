#!/usr/bin/env python3
"""Provenance honesty: no AUTHORED_APPROVED from automation; 98 hero rows defined."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "art_source/animation/manifests/WAVE_A_98_ACTIONS.json"
ROSTER = ROOT / "art_source/animation/manifests/provenance_roster.json"
GODOT_COPY = ROOT / "game-godot/data/animation/provenance_roster.json"


def main() -> int:
    fails = []
    man = json.loads(MANIFEST.read_text())
    roster = json.loads(ROSTER.read_text())
    actions = man.get("actions", [])
    if len(actions) != 98:
        fails.append(f"expected 98 hero actions, got {len(actions)}")
    if man.get("authored_complete_count", 1) != 0:
        fails.append("authored_complete_count must stay 0 this pass")
    approved = [a for a in actions if a.get("status") == "AUTHORED_APPROVED"]
    if approved:
        fails.append(f"automation wrote AUTHORED_APPROVED: {approved}")
    complete = [a for a in actions if a.get("authored_complete")]
    if complete:
        fails.append("hero actions marked authored_complete")
    labels = set(roster.get("labels", []))
    for needed in ("AUTHORED_APPROVED", "AUTHORED_WIP", "PROCEDURAL_FALLBACK", "MISSING"):
        if needed not in labels:
            fails.append(f"missing label {needed}")
    if "AUTHORED_APPROVED" in roster.get("automation_may_write", []):
        fails.append("automation must never write AUTHORED_APPROVED")
    if not GODOT_COPY.is_file():
        fails.append("missing game-godot provenance copy")
    payload = {
        "ok": not fails,
        "failures": fails,
        "hero_actions": len(actions),
        "authored_approved_count": len(approved),
    }
    out = ROOT / "artifacts/vxp3/reports/AUTHORED_PROVENANCE.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps(payload, indent=2))
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
