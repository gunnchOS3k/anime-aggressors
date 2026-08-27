#!/usr/bin/env python3
"""Wave021 art direction static gate."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "engineering_wave021"
CONTRACT = ROOT / "docs" / "art" / "CHARACTER_ART_DIRECTION_CONTRACT.md"
GD = ROOT / "game-godot" / "scripts" / "visual" / "art_direction_contract.gd"


def main() -> int:
    ART.mkdir(parents=True, exist_ok=True)
    failures: list[str] = []
    if not CONTRACT.is_file():
        failures.append("CHARACTER_ART_DIRECTION_CONTRACT.md missing")
    if not GD.is_file():
        failures.append("art_direction_contract.gd missing")
    else:
        text = GD.read_text(encoding="utf-8")
        if "REALISTIC_HUMANOID_FACE_AS_DEFAULT := false" not in text:
            failures.append("REALISTIC_HUMANOID_FACE_AS_DEFAULT not false")
        if "FACELESS_ABSTRACT_HEAD_DIRECTION := true" not in text:
            failures.append("FACELESS_ABSTRACT_HEAD_DIRECTION not true")
    ok = not failures
    payload = {
        "ok": ok,
        "OWNER_REG_021_ART": "PASS" if ok else "FAIL",
        "REALISTIC_HUMANOID_FACE_AS_DEFAULT": False,
        "FACELESS_ABSTRACT_HEAD_DIRECTION": True,
        "failures": failures,
        "roster_docs": 7,
    }
    (ART / "ART_DIRECTION_RESULT.json").write_text(json.dumps(payload, indent=2) + "\n")
    print("ART_DIRECTION", "PASS" if ok else "FAIL", failures)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
