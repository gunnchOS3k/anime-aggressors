#!/usr/bin/env python3
"""Validate Anime RTM against vendored GUNNCHOS3K_PVS requirements_to_evidence_matrix schema."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RTM = ROOT / "artifacts/cursor_continuation/rtm/ANIME_REQUIREMENTS_TO_EVIDENCE_MATRIX.json"
SCHEMA = ROOT / "artifacts/cursor_continuation/rtm/requirements_to_evidence_matrix.schema.json"


def main() -> int:
    try:
        import jsonschema
    except ImportError:
        print("jsonschema required: python3 -m venv .venv && .venv/bin/pip install jsonschema", file=sys.stderr)
        return 2
    rtm = json.loads(RTM.read_text())
    schema = json.loads(SCHEMA.read_text())
    validator = jsonschema.Draft202012Validator(schema)
    errors = sorted(validator.iter_errors(rtm), key=lambda e: list(e.path))
    if errors:
        for err in errors:
            print(f"ERR {list(err.path)}: {err.message}", file=sys.stderr)
        return 1
    if rtm.get("contract_id") != "GUNNCHOS3K_PVS" or rtm.get("contract_version") != "1.0.0":
        print("ERR contract pin must be GUNNCHOS3K_PVS@1.0.0", file=sys.stderr)
        return 1
    if rtm.get("honesty_flags") != {"HUMAN": False, "RC2": False, "V1": False}:
        print("ERR honesty_flags must all be false", file=sys.stderr)
        return 1
    for row in rtm.get("rows", []):
        if row.get("independent_review_status") != "not_started":
            print(f"ERR {row.get('req_id')}: independent_review_status must be not_started", file=sys.stderr)
            return 1
    print(
        "ANIME_RTM_VALIDATE PASS",
        rtm["contract_id"],
        rtm["contract_version"],
        "source",
        str(rtm.get("contract_source_sha", ""))[:12],
        "rows",
        len(rtm.get("rows", [])),
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
