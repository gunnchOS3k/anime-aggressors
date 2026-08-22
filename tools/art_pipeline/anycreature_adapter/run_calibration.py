#!/usr/bin/env python3
"""anyCreature adapter: silhouette / creature / prop path; humanoid pilot classified honestly."""
from __future__ import annotations

import json
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PIN = "ab5b1ce5c13e632f00f7f7cbfdb7a746e315000d"
URL = "https://github.com/Ariescar/anyCreature"
VENDOR = ROOT / "third_party/anyCreature"
OUT = ROOT / "artifacts/wave012/ANYCREATURE_CALIBRATION.json"


def run(cmd: list[str], cwd: Path | None = None) -> tuple[int, str]:
    try:
        p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=120)
        return p.returncode, (p.stdout or "") + (p.stderr or "")
    except Exception as e:  # noqa: BLE001
        return 1, str(e)


def ensure_pin() -> dict:
    if not VENDOR.exists():
        code, out = run(["git", "clone", "--depth", "1", URL, str(VENDOR)])
        if code != 0:
            return {"cloned": False, "error": out[-2000:]}
    # best-effort checkout pin
    run(["git", "fetch", "--depth", "1", "origin", PIN], cwd=VENDOR)
    run(["git", "checkout", PIN], cwd=VENDOR)
    head_code, head = run(["git", "rev-parse", "HEAD"], cwd=VENDOR)
    return {"cloned": True, "head": head.strip() if head_code == 0 else None, "wanted": PIN}


def calibrate() -> dict:
    pin = ensure_pin()
    node = shutil.which("node")
    setup = VENDOR / "setup.sh"
    example = VENDOR / "example/wolf.json"
    result = {
        "tool": "anyCreature",
        "url": URL,
        "pin": PIN,
        "pin_state": pin,
        "node_present": bool(node),
        "setup_attempted": False,
        "setup_ok": False,
        "example_attempted": False,
        "example_ok": False,
        "ANYCREATURE_HUMANOID_FIGHTER_FIT": "LIMITED",
        "recommended_use": ["creatures", "props", "silhouette_studies"],
        "hero_fighter_path": False,
        "generated_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }
    if not pin.get("cloned"):
        result["ANYCREATURE_HUMANOID_FIGHTER_FIT"] = "FAIL"
        result["error"] = pin.get("error")
        return result

    if setup.exists() and node:
        result["setup_attempted"] = True
        code, out = run(["bash", str(setup)], cwd=VENDOR)
        result["setup_ok"] = code == 0 and "calibrate OK" in out
        result["setup_log_tail"] = out[-1500:]
    # Worked example if engine present
    cli = VENDOR / "engine/cli.js"
    if cli.exists() and example.exists() and node:
        result["example_attempted"] = True
        out_glb = ROOT / "art_source/anycreature_pilots/wolf_example.glb"
        out_glb.parent.mkdir(parents=True, exist_ok=True)
        code, out = run(["node", str(cli), str(example), str(out_glb)], cwd=VENDOR)
        result["example_ok"] = code == 0 and out_glb.exists()
        result["example_log_tail"] = out[-1000:]

    # Humanoid fighter fit: keep LIMITED unless a dedicated humanoid pilot clearly passes
    # anatomy/silhouette/deform/joints/face-hands-feet/Godot import + animation compatibility.
    pilot_spec = ROOT / "tools/art_pipeline/anycreature_adapter/ember_humanoid_pilot.json"
    result["humanoid_pilot_spec"] = str(pilot_spec.relative_to(ROOT)) if pilot_spec.exists() else None
    result["ANYCREATURE_HUMANOID_FIGHTER_FIT"] = "LIMITED"
    result["rationale"] = (
        "anyCreature is strong for creatures/props/silhouette ideation; "
        "humanoid fighter anatomy, face/hand/foot readability, and competitive animation "
        "compatibility are not proven to hero quality. Keep off hero path."
    )
    return result


def main() -> int:
    data = calibrate()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    alt = ROOT / "artifacts/engineering_wave012/ANYCREATURE_CALIBRATION.json"
    alt.parent.mkdir(parents=True, exist_ok=True)
    alt.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({
        "ANYCREATURE_HUMANOID_FIGHTER_FIT": data["ANYCREATURE_HUMANOID_FIGHTER_FIT"],
        "setup_ok": data["setup_ok"],
        "example_ok": data["example_ok"],
        "hero_fighter_path": data["hero_fighter_path"],
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
