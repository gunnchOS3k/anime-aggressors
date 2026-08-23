#!/usr/bin/env python3
"""Cluster crash signatures from logcat + flight recorder traces (app-scoped)."""
from __future__ import annotations

import hashlib
import json
import re
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CENSUS = ROOT / "artifacts" / "engineering_wave015" / "crash_census"
LOGCAT_DIR = CENSUS / "logcat"
PACKAGE = "com.gunnchos.animeaggressors"

# Only patterns that indicate process-threatening failures for our app.
SIGNATURE_PATTERNS = [
    (rf"FATAL EXCEPTION:.*?(?:\n.*?)*?Process:\s*{re.escape(PACKAGE)}", "FATAL_EXCEPTION"),
    (r"E godot\s+:\s+SCRIPT ERROR:\s*(.+)", "GODOT_SCRIPT_ERROR"),
    (rf"F DEBUG\s+:\s+\*\*\* \*\*\* \*\*\*.*?>>> {re.escape(PACKAGE)} <<<.*?signal (\d+)", "NATIVE_SIGNAL"),
    (rf"Fatal signal (\d+).*?>>> {re.escape(PACKAGE)} <<<", "LIBC_FATAL_SIGNAL"),
    (rf"ANR in\s+{re.escape(PACKAGE)}", "ANR"),
]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def normalize_line(line: str) -> str:
    line = re.sub(r"0x[0-9a-fA-F]+", "0xADDR", line)
    line = re.sub(r"\b\d{5,}\b", "N", line)
    line = re.sub(r"pid:\s*\d+", "pid:N", line)
    line = re.sub(r"tid:\s*\d+", "tid:N", line)
    # Drop Android graphics allocator noise that is not an app crash.
    if "gralloc" in line.lower() or "Format allocation info not found" in line:
        return ""
    return line.strip()[:240]


def signature_id(kind: str, text: str) -> str:
    digest = hashlib.sha256(f"{kind}|{text}".encode()).hexdigest()[:12]
    return f"{kind}:{digest}"


def extract_from_text(text: str, source: str) -> list[dict]:
    found: list[dict] = []
    for pattern, kind in SIGNATURE_PATTERNS:
        for m in re.finditer(pattern, text, re.M | re.S):
            raw = normalize_line(m.group(0) if m.lastindex is None else m.group(1))
            if not raw:
                continue
            found.append(
                {
                    "signature_id": signature_id(kind, raw),
                    "kind": kind,
                    "normalized": raw,
                    "source": source,
                    "match": m.group(0)[:500],
                }
            )
    return found


def load_traces() -> list[dict]:
    rows: list[dict] = []
    for path in sorted(CENSUS.rglob("*.jsonl")):
        try:
            for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
                if not line.strip():
                    continue
                rows.append(json.loads(line))
        except Exception:
            continue
    return rows


def main() -> int:
    CENSUS.mkdir(parents=True, exist_ok=True)
    LOGCAT_DIR.mkdir(parents=True, exist_ok=True)
    events: list[dict] = []
    for log in sorted(LOGCAT_DIR.glob("*.txt")):
        # Ignore legacy/death false-positive dumps when re-clustering after repair unless named final.
        text = log.read_text(encoding="utf-8", errors="replace")
        events.extend(extract_from_text(text, str(log.relative_to(ROOT))))

    by_id: dict[str, dict] = {}
    counts: Counter[str] = Counter()
    for ev in events:
        sid = ev["signature_id"]
        counts[sid] += 1
        if sid not in by_id:
            by_id[sid] = {
                "signature_id": sid,
                "kind": ev["kind"],
                "normalized": ev["normalized"],
                "first_source": ev["source"],
                "examples": [ev["match"]],
                "status": "OPEN",
            }
        elif len(by_id[sid]["examples"]) < 3:
            by_id[sid]["examples"].append(ev["match"])

    for row in load_traces():
        payload = row.get("payload", {}) if isinstance(row, dict) else {}
        if row.get("kind") == "crash_note":
            sid = signature_id("HARNESS_CRASH_NOTE", str(payload.get("signature", "note")))
            counts[sid] += 1
            by_id.setdefault(
                sid,
                {
                    "signature_id": sid,
                    "kind": "HARNESS_CRASH_NOTE",
                    "normalized": str(payload.get("signature", "")),
                    "first_source": "harness",
                    "examples": [payload],
                    "status": "OPEN",
                },
            )

    signatures = []
    for sid, meta in by_id.items():
        meta["count"] = int(counts[sid])
        signatures.append(meta)
    signatures.sort(key=lambda s: (-s["count"], s["signature_id"]))

    open_sigs = [s for s in signatures if s.get("status") == "OPEN"]
    out = {
        "schema": "engineering_wave015.crash_signatures.v1",
        "generated_at_utc": utc_now(),
        "UNIQUE_CRASH_SIGNATURES": len(signatures),
        "UNIQUE_CRASH_SIGNATURES_OPEN": len(open_sigs),
        "signatures": signatures,
        "notes": [
            "gralloc / graphics allocator ERROR lines are excluded (not app process crashes)",
            "only package-scoped FATAL/ANR/native + Godot SCRIPT ERROR are clustered",
        ],
    }
    path = CENSUS / "CRASH_SIGNATURES.json"
    path.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"UNIQUE_CRASH_SIGNATURES": len(signatures), "OPEN": len(open_sigs), "path": str(path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
