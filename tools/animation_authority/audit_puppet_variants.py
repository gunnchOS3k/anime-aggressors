#!/usr/bin/env python3
"""Base roster must not use puppet masks; puppet variants require mask=true contract."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def main() -> int:
    puppet = json.loads((ROOT / "data/bibles/puppet_essence_story_states_v1.json").read_text(encoding="utf-8"))
    errors = []
    if puppet.get("puppet_states", {}).get("NORMAL", {}).get("mask") is not False:
        errors.append("NORMAL base roster mask must be false")
    for key in ("YIN_CONTROLLED_BLACK_PUPPET", "YANG_CONTROLLED_WHITE_PUPPET"):
        if puppet.get("puppet_states", {}).get(key, {}).get("mask") is not True:
            errors.append(f"{key} must set mask=true")
    matrix = ROOT / "artifacts/animation_authority_v1/PUPPET_VARIANT_MATRIX.json"
    if not matrix.is_file():
        errors.append("missing PUPPET_VARIANT_MATRIX.json")
    else:
        data = json.loads(matrix.read_text(encoding="utf-8"))
        if data.get("base_roster_mask") is not False:
            errors.append("matrix base_roster_mask must be false")
        if data.get("PUPPET_VARIANT_7_OF_7") is not True:
            errors.append("PUPPET_VARIANT_7_OF_7 must be true")
        for fid in puppet.get("spectrum_fighters", []):
            if fid not in data.get("fighters", {}):
                errors.append(f"missing puppet matrix fighter {fid}")
            else:
                if data["fighters"][fid]["NORMAL"].get("mask") is not False:
                    errors.append(f"{fid} NORMAL mask must be false")
    if errors:
        print("FAIL audit_puppet_variants:\n" + "\n".join(errors), file=sys.stderr)
        return 1
    print("PASS audit_puppet_variants")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
