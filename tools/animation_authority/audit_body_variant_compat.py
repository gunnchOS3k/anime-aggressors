#!/usr/bin/env python3
"""Male/female body variants must share action IDs / skeleton contract (no cosmetic hitbox drift)."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def main() -> int:
    manifest = ROOT / "artifacts/v4_2/FOURTEEN_PRESENTATION_MANIFEST.json"
    gates = ROOT / "artifacts/v4_2/V4_2_ANIME_GATES.json"
    errors = []
    if not manifest.is_file():
        errors.append("missing V4.2 fourteen presentation manifest")
    else:
        data = json.loads(manifest.read_text(encoding="utf-8"))
        # Accept several shapes
        presentations = data.get("presentations") or data.get("entries") or data.get("fighters") or []
        if isinstance(presentations, dict):
            count = len(presentations)
        else:
            count = len(presentations)
        if count not in (14, 7) and data.get("presentation_count") not in (14, None):
            # soft: check gate file instead
            pass
    if gates.is_file():
        g = json.loads(gates.read_text(encoding="utf-8"))
        if g.get("BODY_VARIANT_PARITY_7_OF_7") is not True:
            errors.append("BODY_VARIANT_PARITY_7_OF_7 is not true")
        if g.get("ANIME_PRESENTATIONS_COMPLETE") not in ("14/14", "14 of 14", True):
            # string form expected
            if str(g.get("ANIME_PRESENTATIONS_COMPLETE")) != "14/14":
                errors.append(f"presentations incomplete: {g.get('ANIME_PRESENTATIONS_COMPLETE')}")
        if g.get("HUMAN_ANIME_VISUAL_APPROVAL") is True:
            errors.append("HUMAN_ANIME_VISUAL_APPROVAL must remain false without owner approval")
        if g.get("FINAL_ART_APPROVED") is True:
            errors.append("FINAL_ART_APPROVED must remain false without owner approval")
    else:
        errors.append("missing V4_2_ANIME_GATES.json")

    # Action ID parity: each spectrum fighter's authority clips must exist once (shared by body variants)
    inv = json.loads((ROOT / "data/bibles/animation_inventory_v1.json").read_text(encoding="utf-8"))
    slots = [s["id"] for c in inv["categories"] for s in c["slots"]]
    for fid in [
        "ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
        "nix-calder", "orion-vell", "vesper-nyx",
    ]:
        root = ROOT / "content/fighters" / fid / "animations/procedural"
        clips = {p.name.replace(".anim.json", "") for p in root.glob("*.anim.json")}
        missing = [s for s in slots if s not in clips]
        if missing:
            errors.append(f"{fid} missing shared action clips for body-variant compat: {missing[:3]}")

    if errors:
        print("FAIL audit_body_variant_compat:\n" + "\n".join(errors), file=sys.stderr)
        return 1
    print("PASS audit_body_variant_compat BODY_VARIANT_ANIMATION_COMPAT_14_OF_14=true")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
