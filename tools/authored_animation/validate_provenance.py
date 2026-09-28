#!/usr/bin/env python3
"""Provenance honesty: no AUTHORED_APPROVED/HUMAN_APPROVED from automation; 98 hero rows defined."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "art_source/animation/manifests/WAVE_A_98_ACTIONS.json"
ROSTER = ROOT / "art_source/animation/manifests/provenance_roster.json"
GODOT_COPY = ROOT / "game-godot/data/animation/provenance_roster.json"

# v1 names + main (#107/#108) v2 names / aliases
REQUIRED_LABEL_GROUPS = (
    ("AUTHORED_APPROVED", "HUMAN_APPROVED"),
    ("AUTHORED_WIP", "HUMAN_CANDIDATE"),
    ("PROCEDURAL_FALLBACK",),
    ("MISSING",),
)


def _labels(roster: dict) -> set[str]:
    labels = set(roster.get("labels", []))
    aliases = roster.get("legacy_aliases", {}) or {}
    # Treat alias keys as present when mapped targets exist (or vice versa)
    for src, dst in aliases.items():
        if dst in labels:
            labels.add(src)
        if src in labels:
            labels.add(dst)
    return labels


def main() -> int:
    fails = []
    man = json.loads(MANIFEST.read_text())
    roster = json.loads(ROSTER.read_text())
    actions = man.get("actions", [])
    if len(actions) != 98:
        fails.append(f"expected 98 hero actions, got {len(actions)}")
    if man.get("authored_complete_count", 1) != 0:
        fails.append("authored_complete_count must stay 0 this pass")
    forbidden_status = {"AUTHORED_APPROVED", "HUMAN_APPROVED"}
    approved = [a for a in actions if a.get("status") in forbidden_status]
    if approved:
        fails.append(f"automation wrote approved status: {approved}")
    complete = [a for a in actions if a.get("authored_complete")]
    if complete:
        fails.append("hero actions marked authored_complete")
    labels = _labels(roster)
    for group in REQUIRED_LABEL_GROUPS:
        if not any(name in labels for name in group):
            fails.append(f"missing label group {group}")
    auto_write = set(roster.get("automation_may_write", []))
    if "AUTHORED_APPROVED" in auto_write or "HUMAN_APPROVED" in auto_write:
        fails.append("automation must never write AUTHORED_APPROVED/HUMAN_APPROVED")
    blocked = set(roster.get("automation_may_not_write", [])) | set(
        roster.get("automation_must_never_write", [])
    )
    if "AUTHORED_APPROVED" not in blocked and "HUMAN_APPROVED" not in blocked:
        fails.append("roster must block automation writing approved labels")
    if not GODOT_COPY.is_file():
        fails.append("missing game-godot provenance copy")
    payload = {
        "ok": not fails,
        "failures": fails,
        "hero_actions": len(actions),
        "authored_approved_count": len(approved),
        "roster_schema": roster.get("schema"),
    }
    out = ROOT / "artifacts/vxp3/reports/AUTHORED_PROVENANCE.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps(payload, indent=2))
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
