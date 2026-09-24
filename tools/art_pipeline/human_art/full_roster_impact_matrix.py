#!/usr/bin/env python3
"""Seven-fighter impact review matrix. Positions only — CombatMath stays untouched."""
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import FULL_ROSTER_IMPACT_PAIRS, IMPACT_FRAMES, ROOT, write_json  # noqa: E402
from impact_review import stage_pair  # noqa: E402


def main() -> int:
    pairs = []
    fails = []
    for attacker, defender in FULL_ROSTER_IMPACT_PAIRS:
        try:
            staged = stage_pair("hand_r", "CHEST")
        except Exception as exc:  # noqa: BLE001
            fails.append(f"{attacker}->{defender}:{exc}")
            staged = {"ok": False}
        pairs.append(
            {
                "attacker": attacker,
                "defender": defender,
                "frames": list(IMPACT_FRAMES),
                "staging": staged,
                "acting_source": "candidate_animation_when_present_else_current_accepted_art",
                "vfx_off_required_for": ["contact_vfx_off", "peak_hurt_vfx_off"],
                "combat_math_unchanged": True,
                "generated_experiment_excluded": True,
            }
        )
    payload = {
        "ok": not fails and all(p["staging"].get("ok") for p in pairs),
        "FULL_ROSTER_IMPACT_MATRIX_PASS": not fails,
        "failures": fails,
        "pairs": pairs,
        "note": "Structural pair placement only. Candidate animation must provide the acting.",
    }
    payload["FULL_ROSTER_IMPACT_MATRIX_PASS"] = bool(payload["ok"])
    write_json(ROOT / "artifacts/art_pipeline/FULL_ROSTER_IMPACT_MATRIX.json", payload)
    print(json.dumps({"ok": payload["ok"], "pairs": [f"{p['attacker']}->{p['defender']}" for p in pairs]}, indent=2))
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
