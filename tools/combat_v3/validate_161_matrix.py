#!/usr/bin/env python3
"""Validate V3 matrix honesty: 161 rows, no HUMAN_*/OWNER_* true, no identical manifests."""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
from v3_constants import FIGHTERS, REQUIRED_MOVES  # noqa: E402

GATES_FALSE = [
    "OWNER_MOVESET_COMPLETENESS_PASS",
    "OWNER_ANIMATION_QUALITY_PASS",
    "OWNER_VFX_QUALITY_PASS",
    "OWNER_AUDIO_QUALITY_PASS",
    "OWNER_COMBAT_FEEL_PASS",
    "HUMAN_ORIGINALITY_REVIEW_PASS",
    "MERGE_AUTHORIZED",
]


def main() -> int:
    matrix = json.loads((ROOT / "artifacts/combat/v3/MOVE_CONTENT_COMPLETION_MATRIX.json").read_text())
    rows = matrix["rows"]
    errors: list[str] = []
    if len(rows) != 161:
        errors.append(f"row_count {len(rows)} != 161")
    seen = {(r["fighter_id"], r["move_id"]) for r in rows}
    if len(seen) != 161:
        errors.append("duplicate fighter/move rows")
    for fid in FIGHTERS:
        for mid in REQUIRED_MOVES:
            if (fid, mid) not in seen:
                errors.append(f"missing {fid}:{mid}")
    hashes = []
    for fid in FIGHTERS:
        raw = (ROOT / "game-godot/data/moves" / f"{fid}.json").read_bytes()
        hashes.append(hashlib.sha256(raw).hexdigest())
    if len(set(hashes)) != 7:
        errors.append("full manifests are identical")
    if matrix.get("complete_true_count", 0) > 0 and not matrix.get("honesty", {}).get(
        "mobile_capture_present", False
    ):
        errors.append("complete=true without mobile capture is dishonest")
    orig = json.loads((ROOT / "artifacts/legal/INSPIRATION_ORIGINALITY_REVIEW_V3.json").read_text())
    if orig.get("HUMAN_ORIGINALITY_REVIEW_PASS") is True:
        errors.append("HUMAN_ORIGINALITY_REVIEW_PASS must stay false")
    gates_path = ROOT / "artifacts/combat/v3/V3_GATES.json"
    if gates_path.is_file():
        gates = json.loads(gates_path.read_text())
        for key in GATES_FALSE:
            if gates.get(key) is True:
                errors.append(f"{key} must stay false")
    if errors:
        print("VALIDATE FAIL")
        for e in errors:
            print(" -", e)
        return 1
    print("VALIDATE OK rows=161 complete_true=%s digital_ready=%s" % (
        matrix.get("complete_true_count"),
        matrix.get("digital_ready_count"),
    ))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
