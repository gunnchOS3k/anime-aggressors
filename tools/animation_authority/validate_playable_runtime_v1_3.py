#!/usr/bin/env python3
"""Validate PR #118 V1.3 playable runtime contracts (automatable subset)."""
from __future__ import annotations
import json, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SPECTRUM = ["ember-vale","rook-ironside","juno-spark","kaia-windrow","nix-calder","orion-vell","vesper-nyx"]
COSMIC = ["yin","yang"]
ALL = SPECTRUM + COSMIC

def fail(msg: str) -> None:
    print(f"FAIL: {msg}")
    sys.exit(1)

def main() -> int:
    auth = json.loads((ROOT / "data/bibles/roster_runtime_authority_v1_3.json").read_text())
    assert set(auth["full_roster"]) == set(ALL)
    inv = json.loads((ROOT / "data/bibles/animation_inventory_v1.json").read_text())
    slots = [s["id"] for c in inv["categories"] for s in c["slots"]]
    assert len(slots) == 111
    authored = 0
    fallback = 0
    for fid in ALL:
        for slot in slots:
            p = ROOT / "content/fighters" / fid / "animations/procedural" / f"{slot}.anim.json"
            if not p.exists():
                fail(f"missing slot {fid}/{slot}")
            st = json.loads(p.read_text()).get("authority_status")
            if st == "AUTOMATION_AUTHORED_CANDIDATE":
                authored += 1
            elif st == "PROCEDURAL_FALLBACK":
                fallback += 1
            else:
                fail(f"bad status {fid}/{slot}: {st}")
    if authored != 999:
        fail(f"authored={authored} expected 999")
    if fallback != 0:
        fail(f"fallback={fallback} expected 0")
    matrix = json.loads((ROOT / "artifacts/pr118_playable_runtime/matrices/MOVE_ANIMATION_FRAME_SYNC_216.json").read_text())
    if not matrix.get("PASS"):
        fail("216 move matrix not PASS")
    gate = json.loads((ROOT / "artifacts/pr118_playable_runtime/GATE_SUMMARY.json").read_text())
    for k in ("HUMAN_FEEL_APPROVED", "FINAL_ART_APPROVED", "MERGE_AUTHORIZED"):
        if gate.get(k) is True:
            fail(f"human gate flipped true: {k}")
    # body variant battle wiring presence
    fa = (ROOT / "apps/web/src/renderer-three/fighters/FighterAppearance.ts").read_text()
    if "bodyVariant" not in fa or "storyForm" not in fa:
        fail("FighterAppearance missing bodyVariant/storyForm")
    lp = (ROOT / "apps/web/src/renderer-three/fighters/LowPolyHumanoid.ts").read_text()
    if "bodyVariant" not in lp or "story_puppet_mask" not in lp:
        fail("LowPolyHumanoid missing bodyVariant/puppet mask")
    story = ROOT / "packages/game-core/src/story/storyProgression.ts"
    if not story.exists():
        fail("story progression module missing")
    print(json.dumps({
        "ok": True,
        "AUTOMATION_AUTHORED_CANDIDATE_COUNT": authored,
        "PROCEDURAL_FALLBACK_COUNT": fallback,
        "MOVE_MATRIX_216_PASS": True,
        "HUMAN_GATES_FALSE": True,
    }, indent=2))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
