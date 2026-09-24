#!/usr/bin/env python3
"""Provenance honesty: automation never writes HUMAN_APPROVED / AUTHORED_APPROVED."""
from __future__ import annotations

import json
from pathlib import Path

from aa_common import ROOT, write_json

MANIFEST = ROOT / "art_source/animation/manifests/WAVE_A_98_ACTIONS.json"
ROSTER = ROOT / "art_source/animation/manifests/provenance_roster.json"


def main() -> int:
    fails = []
    man = json.loads(MANIFEST.read_text(encoding="utf-8")) if MANIFEST.is_file() else {}
    roster = json.loads(ROSTER.read_text(encoding="utf-8")) if ROSTER.is_file() else {}
    actions = man.get("actions", [])
    if len(actions) != 98:
        fails.append(f"expected 98 hero actions, got {len(actions)}")
    approved = [a for a in actions if a.get("status") in ("AUTHORED_APPROVED", "HUMAN_APPROVED")]
    if approved:
        fails.append(f"automation wrote approved label: {approved}")
    if man.get("human_approved") is True:
        fails.append("manifest human_approved must stay false")
    labels = set(roster.get("labels", []))
    for needed in ("CURRENT_ACCEPTED_ART", "HUMAN_CANDIDATE", "HUMAN_APPROVED", "GENERATED_EXPERIMENT", "PROCEDURAL_FALLBACK", "MISSING"):
        if needed not in labels:
            fails.append(f"missing label {needed}")
    if "HUMAN_APPROVED" in roster.get("automation_may_write", []) or "AUTHORED_APPROVED" in roster.get("automation_may_write", []):
        fails.append("automation must never write HUMAN_APPROVED")
    payload = {
        "ok": not fails,
        "failures": fails,
        "hero_actions": len(actions),
        "ART_ACTION_CONTRACT_PASS": not fails,
        "HUMAN_APPROVED": False,
    }
    write_json(ROOT / "artifacts/art_pipeline/ART_ACTION_CONTRACT.json", payload)
    print(json.dumps(payload, indent=2))
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
