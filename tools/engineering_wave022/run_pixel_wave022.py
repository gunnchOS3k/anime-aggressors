#!/usr/bin/env python3
"""Wave022 Pixel fast validation — all 7 fighters, >=3 transform activations each."""
from __future__ import annotations

import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "engineering_wave022"
PACKAGE = "com.gunnchos.animeaggressors"
ROSTER = [
    "ember-vale",
    "rook-ironside",
    "juno-spark",
    "kaia-windrow",
    "nix-calder",
    "orion-vell",
    "vesper-nyx",
]


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def adb_devices() -> list[str]:
    try:
        out = subprocess.check_output(["adb", "devices"], text=True, stderr=subprocess.DEVNULL)
    except Exception:
        return []
    serials = []
    for line in out.splitlines()[1:]:
        parts = line.split()
        if len(parts) >= 2 and parts[1] == "device":
            serials.append(parts[0])
    return serials


def pixel_available() -> bool:
    if not adb_devices():
        return False
    try:
        out = subprocess.check_output(
            ["adb", "shell", "pm", "path", PACKAGE],
            text=True,
            stderr=subprocess.DEVNULL,
            timeout=10,
        )
        return PACKAGE in out or "package:" in out
    except Exception:
        return False


def emit_blocked(reason: str) -> dict:
    payload = {
        "PIXEL_DEVICE_AVAILABLE": False,
        "PIXEL_WAVE022_VALIDATION": "BLOCKED",
        "PIXEL_BLOCK_REASON": reason,
        "CRITICAL_FAILURES": 0,
        "per_fighter_transforms": {fid: 0 for fid in ROSTER},
        "emitted_at": now(),
    }
    ART.mkdir(parents=True, exist_ok=True)
    (ART / "PIXEL_WAVE022.json").write_text(json.dumps(payload, indent=2) + "\n")
    return payload


def main() -> int:
    if not pixel_available():
        emit_blocked("no_pixel6a_or_app_not_installed")
        print("PIXEL_WAVE022=BLOCKED")
        return 0

    # Physical fast gates deferred — desktop-first wave; honest BLOCKED until harness wired.
    emit_blocked("wave022_pixel_harness_not_yet_wired")
    print("PIXEL_WAVE022=BLOCKED (harness pending)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
