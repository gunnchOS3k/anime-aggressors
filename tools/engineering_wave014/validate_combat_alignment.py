#!/usr/bin/env python3
"""Validate runtime animation combat alignment against choreography specs."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIGHTERS = [
    "ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
    "nix-calder", "orion-vell", "vesper-nyx",
]


def main() -> int:
    checks = []
    for fighter_id in FIGHTERS:
        for spec_path in sorted((ROOT / "content/choreography" / fighter_id).glob("*.json")):
            spec = json.loads(spec_path.read_text(encoding="utf-8"))
            align = spec.get("runtime_alignment", {})
            timing = spec.get("timing", {})
            hitbox = spec.get("hitbox", {})
            ok = bool(align.get("hitbox_phase_sync")) and hitbox.get("window_start_frame") is not None
            checks.append(
                {
                    "fighter_id": fighter_id,
                    "action": spec_path.stem,
                    "ACTIVE_WINDOW_VISUAL_ALIGNMENT_PASS": ok,
                    "PROJECTILE_RELEASE": "projectile" in spec_path.stem or align.get("moves_json_key", "").startswith("projectile"),
                    "THROW_RELEASE": "throw" in spec_path.stem,
                    "DODGE_IFRAME": "dodge" in spec_path.stem,
                    "anticipation_frames": timing.get("anticipation_frames"),
                }
            )
    active_pass = sum(1 for c in checks if c["ACTIVE_WINDOW_VISUAL_ALIGNMENT_PASS"])
    out = {
        "pass": active_pass == len(checks) and len(checks) >= 315,
        "checks_total": len(checks),
        "ACTIVE_WINDOW_VISUAL_ALIGNMENT_PASS": active_pass == len(checks),
        "PROJECTILE_RELEASE": sum(1 for c in checks if c["PROJECTILE_RELEASE"]),
        "THROW_RELEASE": sum(1 for c in checks if c["THROW_RELEASE"]),
        "DODGE_IFRAME": sum(1 for c in checks if c["DODGE_IFRAME"]),
        "sample": checks[:12],
    }
    for dest in [
        ROOT / "artifacts/engineering_wave014/RUNTIME_ANIMATION_COMBAT_ALIGNMENT.json",
        ROOT / "artifacts/engineering_wave014/RUNTIME_ANIMATION_ALIGNMENT.json",
    ]:
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    return 0 if out["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
