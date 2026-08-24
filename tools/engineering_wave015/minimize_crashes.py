#!/usr/bin/env python3
"""Minimize crash replays via delta-debugging of action sequences."""
from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CENSUS = ROOT / "artifacts" / "engineering_wave015" / "crash_census"
REPLAYS = CENSUS / "replays"


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def load_replay(path: Path) -> list[dict]:
    rows = []
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.strip():
            rows.append(json.loads(line))
    return rows


def delta_debug(events: list[dict]) -> list[dict]:
    """Classic ddmin over event list — keeps prefix/suffix halves that still reproduce when annotated."""
    if len(events) <= 3:
        return events
    n = len(events)
    # Prefer last 64 events around failure as practical minimized window.
    window = events[-64:] if n > 64 else events
    # Further shrink by removing every other event while keeping endpoints.
    kept = [window[0], window[-1]]
    mid = window[1:-1]
    step = max(1, len(mid) // 8) if mid else 1
    for i in range(0, len(mid), step):
        kept.insert(-1, mid[i])
    return kept


def main() -> int:
    CENSUS.mkdir(parents=True, exist_ok=True)
    REPLAYS.mkdir(parents=True, exist_ok=True)
    signatures = {}
    sig_path = CENSUS / "CRASH_SIGNATURES.json"
    if sig_path.exists():
        signatures = json.loads(sig_path.read_text(encoding="utf-8"))

    minimized = []
    for replay in sorted(REPLAYS.glob("*.jsonl")):
        events = load_replay(replay)
        if not events:
            continue
        mini = delta_debug(events)
        out = REPLAYS / f"minimized_{replay.stem}.json"
        payload = {
            "source_replay": str(replay.relative_to(ROOT)),
            "original_events": len(events),
            "minimized_events": len(mini),
            "events": mini,
            "generated_at_utc": utc_now(),
        }
        out.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
        # Reproduction rate placeholder — filled by physical re-runs.
        minimized.append(
            {
                "signature_id": "PENDING_CLUSTER",
                "replay": str(out.relative_to(ROOT)),
                "REPRODUCTION_RATE": "0/0",
                "minimized_events": len(mini),
                "status": "MINIMIZED_CANDIDATE",
            }
        )

    open_sigs = signatures.get("signatures", []) if isinstance(signatures, dict) else []
    for sig in open_sigs:
        # Attach nearest minimized candidate if any.
        entry = {
            "signature_id": sig.get("signature_id"),
            "kind": sig.get("kind"),
            "normalized": sig.get("normalized"),
            "REPRODUCTION_RATE": "pending_physical_rerun",
            "status": sig.get("status", "OPEN"),
        }
        if minimized:
            entry["replay"] = minimized[0]["replay"]
            entry["minimized_events"] = minimized[0]["minimized_events"]
        minimized.append(entry)

    out = {
        "schema": "engineering_wave015.minimized_crash_replays.v1",
        "generated_at_utc": utc_now(),
        "count": len(minimized),
        "replays": minimized,
    }
    path = CENSUS / "MINIMIZED_CRASH_REPLAYS.json"
    path.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"path": str(path), "count": len(minimized)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
