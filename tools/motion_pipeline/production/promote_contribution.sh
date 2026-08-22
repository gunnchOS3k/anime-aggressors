#!/usr/bin/env bash
# Promote reviewed motion contribution to content/approved_motion/ (production firewall).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
CONTRIBUTION="${CONTRIBUTION:-}"
if [[ -z "$CONTRIBUTION" ]]; then
  echo "Usage: make motion-promote CONTRIBUTION=<id>"
  exit 1
fi

QUAR="local/user_motion/quarantine/${CONTRIBUTION}"
REVIEW="local/user_motion/reviews/${CONTRIBUTION}/motion_review_record.json"
PROC="local/user_motion/processed/${CONTRIBUTION}/motion_processing_record.json"
APPROVED="content/approved_motion/${CONTRIBUTION}"

for f in "$REVIEW" "$PROC"; do
  if [[ ! -f "$f" ]]; then
    echo "FAIL missing required record: $f"
    exit 1
  fi
done

python3 - <<PY
import json, sys
from pathlib import Path
review = json.loads(Path("$REVIEW").read_text())
proc = json.loads(Path("$PROC").read_text())
if review.get("decision") != "APPROVED_FOR_PRODUCTION":
    sys.exit("review not approved")
if not review.get("all_checks_passed"):
    sys.exit("all_checks_passed required")
if review.get("reviewer_role") != "trusted_owner_reviewer":
    sys.exit("trusted reviewer required")
if not proc.get("normalize_pass") or not proc.get("schema_valid"):
    sys.exit("processing record incomplete")
print("promote_checks_ok")
PY

mkdir -p "$APPROVED"
if [[ -d "$QUAR" ]]; then
  cp -R "$QUAR/." "$APPROVED/"
fi
cp "$REVIEW" "$APPROVED/motion_review_record.json"
cp "$PROC" "$APPROVED/motion_processing_record.json"
echo "Promoted $CONTRIBUTION -> $APPROVED"
echo "PRODUCTION_CAN_LOAD_QUARANTINED_UPLOAD=false (approved_motion only)"
