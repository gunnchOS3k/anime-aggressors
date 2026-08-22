#!/usr/bin/env python3
"""Consent firewall stages for user motion contributions."""
from __future__ import annotations

import json
from pathlib import Path

STAGES = [
    "upload_received",
    "metadata_stripped",
    "schema_validated",
    "normalize_pass",
    "retarget_pass",
    "qa_pass",
    "preview_available",
    "owner_review_pending",
    "production_use_approved",
]

FORBIDDEN = ["biometric_inference", "identity_linking", "external_upload"]


def evaluate(contribution: dict) -> dict:
    consent = contribution.get("consent", {})
    stages = consent.get("stages", [])
    missing = [s for s in STAGES[:6] if s not in stages]
    approved = "production_use_approved" in stages and consent.get("production_use_after_approval") is True
    return {
        "ok": not missing,
        "missing_stages": missing,
        "production_use_allowed": approved,
        "biometric_inference_forbidden": consent.get("biometric_inference_forbidden", True),
        "forbidden_operations": FORBIDDEN,
    }


def main() -> int:
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--contribution", type=Path, required=True)
    args = parser.parse_args()
    data = json.loads(args.contribution.read_text(encoding="utf-8"))
    result = evaluate(data)
    print(json.dumps(result, indent=2))
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
