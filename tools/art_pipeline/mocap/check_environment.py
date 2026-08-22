#!/usr/bin/env python3
"""Honest mocap environment gate — BLOCKED_ENVIRONMENT_GPU on Apple Silicon."""
from __future__ import annotations
import json, platform, shutil, subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "artifacts/wave012/MOCAP_ENVIRONMENT_GATE.json"
PINS = ROOT / "vendor_pins/WAVE012_TOOL_PINS.json"

def main() -> int:
    pins = json.loads(PINS.read_text()) if PINS.exists() else {}
    mocap = pins.get("pins", {}).get("mixamo-llm-mocap", {})
    nvidia = False
    detail = "nvidia-smi unavailable"
    if platform.system() == "Darwin" and platform.machine() in ("arm64", "aarch64"):
        detail = "Apple Silicon — no NVIDIA CUDA GPU"
    elif shutil.which("nvidia-smi"):
        p = subprocess.run(["nvidia-smi", "--query-gpu=name,memory.total", "--format=csv,noheader"], capture_output=True, text=True)
        nvidia = p.returncode == 0 and bool((p.stdout or "").strip())
        detail = (p.stdout or p.stderr or "").strip() or detail
    status = "READY_TO_ATTEMPT" if nvidia else "BLOCKED_ENVIRONMENT_GPU"
    data = {
        "generated_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "pin_url": mocap.get("url"),
        "pin_commit": mocap.get("commit"),
        "nvidia_gpu": nvidia,
        "gpu_detail": detail,
        "MIXAMO_LLM_MOCAP_EXECUTION": status,
        "paid_cloud_gpu": False,
        "execution_attempted": False,
        "integration_packet": "tools/art_pipeline/mocap/",
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(data, indent=2) + "\n")
    pkt = {
        "MIXAMO_LLM_MOCAP_EXECUTION": status,
        "pin_url": mocap.get("url"),
        "pin_commit": mocap.get("commit"),
        "integration_packet": "tools/art_pipeline/mocap/",
        "paid_cloud_gpu": False,
        "execution_attempted": False,
        "reason": detail,
    }
    for dest in [
        ROOT / "artifacts/wave012/MOCAP_GPU_EXECUTION_PACKET.json",
        ROOT / "artifacts/engineering_wave012/MOCAP_GPU_EXECUTION_PACKET.json",
    ]:
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(json.dumps(pkt, indent=2) + "\n")
    print(json.dumps({"MIXAMO_LLM_MOCAP_EXECUTION": status, "gpu_detail": detail}, indent=2))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
