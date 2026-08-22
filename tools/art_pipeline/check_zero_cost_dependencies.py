#!/usr/bin/env python3
"""Fail if CORE art pipeline depends on paid/unknown-license services."""
from __future__ import annotations
import json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

def main() -> int:
    pins = json.loads((ROOT / "vendor_pins/WAVE012_TOOL_PINS.json").read_text(encoding="utf-8"))
    cost = pins.get("CORE_PIPELINE_MONETARY_COST_USD", 1)
    errors = []
    if cost != 0:
        errors.append(f"CORE_PIPELINE_MONETARY_COST_USD must be 0, got {cost}")
    for name, meta in pins.get("pins", {}).items():
        classification = str(meta.get("classification", "")).upper()
        required = bool(meta.get("required_for_build", False))
        if classification in {"REJECTED", "EXPERIMENTAL_TRANSIENT_TOOL"} and required:
            errors.append(f"Non-core tool marked required: {name}")
        if classification == "OPTIONAL" and required:
            errors.append(f"Optional tool cannot be required_for_build: {name}")
    wf = ROOT / ".github/workflows/engineering-wave012.yml"
    if wf.exists():
        text = wf.read_text(encoding="utf-8")
        if re.search(r"fal\\.ai", text, re.I) and "REJECTED" not in text:
            errors.append("fal.ai referenced in CORE CI without REJECTED marker")
    matrix = ROOT / "docs/art_pipeline/FREE_TOOLCHAIN_AND_LICENSE_MATRIX.md"
    if not matrix.exists():
        errors.append(f"missing {matrix}")
    else:
        mt = matrix.read_text(encoding="utf-8")
        if "fal.ai" not in mt.lower() or "REJECTED" not in mt:
            errors.append("License matrix must document fal.ai sprite-sheet path as REJECTED")
    out = {"pass": not errors, "CORE_PIPELINE_MONETARY_COST_USD": cost, "errors": errors}
    for dest in [
        ROOT / "artifacts/engineering_wave012/ZERO_COST_DEPENDENCY_CHECK.json",
        ROOT / "artifacts/wave012/ZERO_COST_DEPENDENCY_CHECK.json",
    ]:
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    return 0 if out["pass"] else 1

if __name__ == "__main__":
    raise SystemExit(main())
