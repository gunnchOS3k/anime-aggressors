#!/usr/bin/env python3
"""Record Pixel Wave021 validation status."""
from __future__ import annotations

import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "engineering_wave021"
PKG = "com.gunnchos.animeaggressors"


def device_online() -> bool:
    try:
        out = subprocess.check_output(["adb", "devices"], text=True, stderr=subprocess.DEVNULL)
        return any(line.endswith("\tdevice") for line in out.splitlines()[1:])
    except Exception:
        return False


def main() -> int:
    ART.mkdir(parents=True, exist_ok=True)
    online = device_online()
    if not online:
        payload = {
            "PIXEL_DEVICE_AVAILABLE": False,
            "PIXEL_WAVE021_VALIDATION": "BLOCKED",
            "GATE_0_LAUNCH": None,
            "GATE_1_SELECT": None,
            "GATE_2_TRANSFORM": None,
            "GATE_3_BATTLE_ASCENDED": None,
            "GATE_4_OWNER_SOAK": None,
            "reason": "No authorized Pixel 6a attached during Wave021 run",
            "package": PKG,
            "emitted_at": datetime.now(timezone.utc).isoformat(),
        }
        (ART / "PIXEL_WAVE021.json").write_text(json.dumps(payload, indent=2) + "\n")
        print("PIXEL_WAVE021_VALIDATION=BLOCKED")
        return 0
    # Device online — honest stub until full pixel harness wired for Wave021
    payload = {
        "PIXEL_DEVICE_AVAILABLE": True,
        "PIXEL_WAVE021_VALIDATION": "PENDING_HARNESS",
        "GATE_0_LAUNCH": "PENDING",
        "GATE_1_SELECT": "PENDING",
        "GATE_2_TRANSFORM": "PENDING",
        "GATE_3_BATTLE_ASCENDED": "PENDING",
        "GATE_4_OWNER_SOAK": "PENDING",
        "reason": "Pixel attached but Wave021 gate harness not yet executed on this tip",
        "package": PKG,
        "emitted_at": datetime.now(timezone.utc).isoformat(),
    }
    (ART / "PIXEL_WAVE021.json").write_text(json.dumps(payload, indent=2) + "\n")
    print("PIXEL_WAVE021_VALIDATION=PENDING_HARNESS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
