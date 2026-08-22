#!/usr/bin/env python3
"""Validate Wave012 toolchain provenance: software ≠ output license."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

PROVENANCE_FIELDS = [
    "source_tool",
    "source_tool_version",
    "source_tool_terms",
    "input_asset_rights",
    "output_rights_basis",
    "redistribution_status",
    "human_operator_required",
]

GENERATED_FLAGS = [
    "GENERATOR_LICENSE_KNOWN",
    "INPUT_RIGHTS_KNOWN",
    "OUTPUT_PROVENANCE_KNOWN",
]


def load_json(path: Path) -> dict | list:
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    errors: list[str] = []
    pins = load_json(ROOT / "vendor_pins/WAVE012_TOOL_PINS.json")
    if pins.get("SOFTWARE_LICENSE_NOT_USED_AS_OUTPUT_LICENSE") is not True:
        errors.append("SOFTWARE_LICENSE_NOT_USED_AS_OUTPUT_LICENSE must be true in pins")

    overlay_path = ROOT / "content/wave012_provenance_overlay.json"
    if not overlay_path.exists():
        errors.append("missing content/wave012_provenance_overlay.json")
        overlay = {}
    else:
        overlay = load_json(overlay_path)

    entries = overlay.get("entries", [])
    if not entries:
        errors.append("wave012 provenance overlay has no entries")

    for entry in entries:
        eid = entry.get("id", "<unknown>")
        status = str(entry.get("status", ""))
        # Required provenance schema fields on Wave012 records
        for field in PROVENANCE_FIELDS:
            if field not in entry:
                errors.append(f"{eid}: missing provenance field {field}")
            elif entry.get(field) in (None, ""):
                errors.append(f"{eid}: empty provenance field {field}")

        for flag in GENERATED_FLAGS:
            if flag not in entry:
                errors.append(f"{eid}: missing {flag}")

        # Unknown rights cannot become FINAL_LICENSED
        if status == "FINAL_LICENSED":
            if entry.get("output_rights_basis") == "UNKNOWN_REVIEW_REQUIRED":
                errors.append(f"{eid}: FINAL_LICENSED with UNKNOWN output_rights_basis")
            if entry.get("INPUT_RIGHTS_KNOWN") is not True:
                errors.append(f"{eid}: FINAL_LICENSED requires INPUT_RIGHTS_KNOWN=true")
            if entry.get("OUTPUT_PROVENANCE_KNOWN") is not True:
                errors.append(f"{eid}: FINAL_LICENSED requires OUTPUT_PROVENANCE_KNOWN=true")

        # anyCreature-specific: never treat software MIT as output license
        src = str(entry.get("source_tool", ""))
        if "anyCreature" in src or "anycreature" in eid.lower():
            basis = str(entry.get("output_rights_basis", ""))
            if basis.upper() in {"MIT", "SOFTWARE_MIT", "INFERRED_FROM_SOFTWARE_LICENSE"}:
                errors.append(
                    f"{eid}: anyCreature output_rights_basis must not be inferred from software MIT"
                )
            if entry.get("GENERATOR_LICENSE_KNOWN") is True and entry.get("OUTPUT_PROVENANCE_KNOWN") is True:
                # OK only if output basis is explicit and not software license
                if "SOFTWARE" in basis.upper() and "NOT" not in basis.upper():
                    errors.append(f"{eid}: output rights incorrectly tied to software license")

    # Cross-check pin output_rights_notes for anyCreature
    anyc = pins.get("pins", {}).get("anyCreature", {})
    notes = str(anyc.get("output_rights_notes", ""))
    if "SOFTWARE_LICENSE_NOT_USED_AS_OUTPUT_LICENSE" not in notes:
        errors.append("anyCreature pin output_rights_notes must include SOFTWARE_LICENSE_NOT_USED_AS_OUTPUT_LICENSE")

    # Historical content/provenance.json: do not invent; only ensure Wave012 overlay is authoritative for new fields
    legacy = ROOT / "content/provenance.json"
    legacy_ok = legacy.exists()

    out = {
        "pass": not errors,
        "SOFTWARE_LICENSE_NOT_USED_AS_OUTPUT_LICENSE": True,
        "PROVENANCE_SCHEMA_FIELDS": PROVENANCE_FIELDS,
        "GENERATED_ASSET_FLAGS": GENERATED_FLAGS,
        "overlay_entries": len(entries),
        "legacy_provenance_present": legacy_ok,
        "errors": errors,
    }
    for dest in [
        ROOT / "artifacts/engineering_wave012/TOOLCHAIN_PROVENANCE_VALIDATION.json",
        ROOT / "artifacts/wave012/TOOLCHAIN_PROVENANCE_VALIDATION.json",
    ]:
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    return 0 if out["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
