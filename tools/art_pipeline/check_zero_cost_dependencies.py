#!/usr/bin/env python3
"""Compute CORE pipeline monetary cost from required tools; fail on paid/unknown deps."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

REQUIRED_TOOLS = {
    "Godot",
    "Blender",
    "VRoid Studio",
    "VRM Add-on for Blender",
    "anyCreature",
    "Adobe Mixamo",
    "mixamo-llm-mocap",
    "Twinforge",
    "sprite-sheet-creator-fal-ai",
}

REQUIRED_FIELDS = [
    "name",
    "url",
    "version_or_commit",
    "software_license_or_terms",
    "classification",
    "required_for_repo_build",
    "required_for_pipeline_pass",
    "required_for_final_art_authoring",
    "monetary_cost_usd_required",
    "account_required",
    "human_gui_required",
    "gpu_required",
    "redistribution_notes",
    "output_rights_notes",
    "terms_verification_status",
    "terms_checked_at_utc",
    "provenance_requirement",
    "notes",
]

ALLOWED_CLASS = {
    "CORE_RUNTIME",
    "CORE_AUTHORING",
    "OPTIONAL",
    "EXPERIMENTAL_TRANSIENT_TOOL",
    "REJECTED",
}

NON_CORE_CLASS = {"OPTIONAL", "EXPERIMENTAL_TRANSIENT_TOOL", "REJECTED"}

PAID_ENV_PATTERNS = [
    r"\bFAL_KEY\b",
    r"\bOPENAI_API_KEY\b",
    r"\bANTHROPIC_API_KEY\b",
    r"\bREPLICATE_API_TOKEN\b",
    r"\bOPENAI_",
    r"\bANTHROPIC_",
    r"api\.openai\.com",
    r"api\.anthropic\.com",
    r"replicate\.com",
]

SCAN_GLOBS = [
    ".github/workflows/**/*.yml",
    ".github/workflows/**/*.yaml",
    "Makefile",
    "tools/**/*.py",
    "tools/**/*.sh",
    "tools/**/*.mjs",
    "tools/**/*.js",
    "package.json",
    "package-lock.json",
]

# Docs may mention rejected/optional paid services only when clearly non-required.
DOC_ALLOWLIST = {
    "docs/art_pipeline/FREE_TOOLCHAIN_AND_LICENSE_MATRIX.md",
    "docs/art_pipeline/MIXAMO_USAGE_AND_PROVENANCE.md",
    "docs/art_pipeline/MOCAP_GPU_EXECUTION.md",
    "docs/art_pipeline/EMBER_FREE_ART_PIPELINE_VERTICAL_SLICE.md",
    "vendor_pins/WAVE012_TOOL_PINS.json",
    "content/wave012_provenance_overlay.json",
    "tools/art_pipeline/check_zero_cost_dependencies.py",
    "tools/art_pipeline/validate_toolchain_provenance.py",
    "tools/engineering_wave012/generate_wave012_content.py",
    "tools/engineering_wave012/emit_wave012_result.py",
}


def _is_required(meta: dict) -> bool:
    return bool(meta.get("required_for_repo_build")) or bool(meta.get("required_for_pipeline_pass"))


def _load_pins() -> dict:
    path = ROOT / "vendor_pins/WAVE012_TOOL_PINS.json"
    return json.loads(path.read_text(encoding="utf-8"))


def _scan_paid_refs() -> list[str]:
    errors: list[str] = []
    files: list[Path] = []
    for pattern in SCAN_GLOBS:
        files.extend(ROOT.glob(pattern))
    # Deduplicate
    seen: set[Path] = set()
    for path in files:
        if path in seen or not path.is_file():
            continue
        seen.add(path)
        rel = str(path.relative_to(ROOT)).replace("\\", "/")
        if any(rel.startswith(a.rstrip("*")) or rel == a for a in DOC_ALLOWLIST):
            # Still scan allowlisted code scanners themselves lightly — skip only docs/pins.
            if rel.startswith("docs/") or rel.startswith("vendor_pins/") or rel.startswith("content/"):
                continue
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        for pat in PAID_ENV_PATTERNS:
            if re.search(pat, text):
                # Allow mention only if file is explicitly documenting REJECTED/OPTIONAL exclusion
                if "REJECTED" in text and ("fal" in text.lower() or "FAL_KEY" in text):
                    if _is_code_required_path(rel):
                        errors.append(
                            f"Paid-service token {pat} appears in required path {rel}"
                        )
                    continue
                if _is_code_required_path(rel):
                    errors.append(f"Paid-service pattern {pat} found in {rel}")
    return errors


def _is_code_required_path(rel: str) -> bool:
    if rel.startswith(".github/workflows/"):
        return True
    if rel == "Makefile":
        return True
    if rel.startswith("tools/") and "generate_wave012_content" not in rel:
        # generate script may document rejected tools; checker/validator may mention patterns.
        if "check_zero_cost" in rel or "validate_toolchain" in rel:
            return False
        return True
    if rel in {"package.json", "package-lock.json"}:
        return True
    return False


def _parse_matrix_classifications(md: str) -> dict[str, str]:
    """Extract Tool -> Class from markdown table rows."""
    out: dict[str, str] = {}
    for line in md.splitlines():
        if not line.startswith("|"):
            continue
        parts = [p.strip() for p in line.strip("|").split("|")]
        if len(parts) < 10:
            continue
        tool, classification = parts[0], parts[-1]
        if tool.lower() in {"tool", "----"} or set(tool) <= {"-"}:
            continue
        # Normalize tool keys to pin names
        key = tool
        if tool.startswith("Godot"):
            key = "Godot"
        elif tool.startswith("Blender"):
            key = "Blender"
        elif tool.startswith("VRoid"):
            key = "VRoid Studio"
        elif tool.startswith("VRM"):
            key = "VRM Add-on for Blender"
        elif tool.startswith("anyCreature"):
            key = "anyCreature"
        elif "Mixamo" in tool and "llm" not in tool.lower():
            key = "Adobe Mixamo"
        elif "mixamo-llm" in tool.lower():
            key = "mixamo-llm-mocap"
        elif tool.startswith("Twinforge"):
            key = "Twinforge"
        elif "sprite" in tool.lower() or "fal.ai" in tool.lower():
            key = "sprite-sheet-creator-fal-ai"
        # Take primary class token before slash/paren notes
        cls = classification.split("/")[0].split("(")[0].strip()
        cls = cls.replace(" ", "_")
        if cls == "CORE":
            # legacy — map via tool
            if key == "Godot":
                cls = "CORE_RUNTIME"
            else:
                cls = "CORE_AUTHORING"
        out[key] = cls
    return out


def _anycreature_pin(pins: dict) -> dict:
    declared = str(pins.get("pins", {}).get("anyCreature", {}).get("version_or_commit", ""))
    vendor = ROOT / "third_party/anyCreature"
    actual = None
    source = None
    try:
        import subprocess

        parent = subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True
        ).strip()
        # Authoritative gitlink recorded in the parent tree (works in CI without submodule checkout).
        ls = subprocess.check_output(
            ["git", "ls-tree", "HEAD", "third_party/anyCreature"],
            cwd=ROOT,
            text=True,
        ).strip()
        gitlink = None
        parts = ls.split()
        if len(parts) >= 3 and parts[0] == "160000" and parts[1] == "commit":
            gitlink = parts[2]
            actual = gitlink
            source = "gitlink"

        nested = None
        if vendor.exists() and ((vendor / ".git").exists() or (vendor / "LICENSE").exists()):
            try:
                nested = subprocess.check_output(
                    ["git", "rev-parse", "HEAD"], cwd=vendor, text=True
                ).strip()
            except Exception:
                nested = None
            # Nested rev-parse can walk up to the parent when submodule content is absent.
            if nested and nested != parent:
                actual = nested
                source = "nested_repo"
            elif nested == parent and gitlink:
                actual = gitlink
                source = "gitlink_fallback_nested_was_parent"

        match = bool(declared) and bool(actual) and actual == declared
    except Exception as exc:  # noqa: BLE001
        return {
            "ANYCREATURE_DECLARED_COMMIT": declared,
            "ANYCREATURE_ACTUAL_COMMIT": None,
            "ANYCREATURE_PIN_MATCH": False,
            "ANYCREATURE_PIN_SOURCE": None,
            "error": str(exc),
        }
    return {
        "ANYCREATURE_DECLARED_COMMIT": declared,
        "ANYCREATURE_ACTUAL_COMMIT": actual,
        "ANYCREATURE_PIN_MATCH": match,
        "ANYCREATURE_PIN_SOURCE": source,
    }


def _final_art_guard(pins: dict) -> dict:
    errors: list[str] = []
    result_path = ROOT / "artifacts/engineering_wave012/WAVE012_RESULT.json"
    result = {}
    if result_path.exists():
        try:
            result = json.loads(result_path.read_text(encoding="utf-8"))
        except Exception:
            result = {}

    vroid_export_present = bool(pins.get("VROID_FINAL_EXPORT_PRESENT", False))
    # Evidence: real VRoid export under expected paths
    export_candidates = list((ROOT / "art_source").glob("**/*ember*") if (ROOT / "art_source").exists() else [])
    export_candidates += list((ROOT / "game-godot/assets/characters").glob("**/vroid/**"))
    real_export = any(p.suffix.lower() in {".vrm", ".glb"} and "vroid" in str(p).lower() for p in export_candidates)
    if vroid_export_present and not real_export:
        errors.append("VROID_FINAL_EXPORT_PRESENT=true without real VRoid export evidence")
    if not real_export:
        vroid_export_present = False

    ember_final = bool(result.get("EMBER_FINAL_ART_RUNTIME_PASS", False))
    if ember_final and not real_export:
        errors.append("EMBER_FINAL_ART_RUNTIME_PASS=true without final VRoid/runtime art evidence")

    human_approval = bool(result.get("HUMAN_ART_DIRECTION_APPROVAL", False))
    approval_evidence = ROOT / "artifacts/engineering_wave012/HUMAN_ART_DIRECTION_APPROVAL.json"
    if human_approval and not approval_evidence.exists():
        errors.append("HUMAN_ART_DIRECTION_APPROVAL=true without approval evidence artifact")

    mocap = str(result.get("MOCAP_GPU_EXECUTION", ""))
    mocap_packet = ROOT / "artifacts/wave012/MOCAP_GPU_EXECUTION_PACKET.json"
    packet = {}
    if mocap_packet.exists():
        try:
            packet = json.loads(mocap_packet.read_text(encoding="utf-8"))
        except Exception:
            packet = {}
    if mocap == "PASS":
        if not packet.get("execution_attempted") or packet.get("paid_cloud_gpu"):
            errors.append("MOCAP_GPU_EXECUTION=PASS without successful local GPU execution evidence")
        # Also require explicit success marker
        if packet.get("MIXAMO_LLM_MOCAP_EXECUTION") != "PASS":
            errors.append("MOCAP_GPU_EXECUTION=PASS but packet does not record PASS")

    status = "PASS" if not errors else "FAIL"
    return {
        "FINAL_ART_FALSE_POSITIVE_GUARD": status,
        "VROID_FINAL_EXPORT_PRESENT": vroid_export_present,
        "errors": errors,
    }


def main() -> int:
    errors: list[str] = []
    pins = _load_pins()
    pin_map: dict = pins.get("pins", {})

    if not pins.get("SOFTWARE_LICENSE_NOT_USED_AS_OUTPUT_LICENSE") is True:
        errors.append("SOFTWARE_LICENSE_NOT_USED_AS_OUTPUT_LICENSE must be true")

    missing_tools = REQUIRED_TOOLS - set(pin_map.keys())
    if missing_tools:
        errors.append(f"Missing tools in WAVE012_TOOL_PINS.json: {sorted(missing_tools)}")

    computed_cost = 0.0
    required_names: list[str] = []

    for name, meta in pin_map.items():
        for field in REQUIRED_FIELDS:
            if field not in meta:
                errors.append(f"{name}: missing field {field}")
        classification = str(meta.get("classification", "")).upper()
        if classification not in ALLOWED_CLASS:
            errors.append(f"{name}: invalid classification {classification}")

        required = _is_required(meta)
        if required:
            required_names.append(name)
            if classification in NON_CORE_CLASS:
                errors.append(
                    f"{name}: required tool cannot be classification {classification}"
                )
            cost = meta.get("monetary_cost_usd_required")
            if cost is None:
                errors.append(f"{name}: required tool missing monetary_cost_usd_required")
            else:
                try:
                    cost_f = float(cost)
                except (TypeError, ValueError):
                    errors.append(f"{name}: monetary_cost_usd_required not numeric")
                    cost_f = 1.0
                if cost_f > 0:
                    errors.append(f"{name}: mandatory monetary cost > 0 ({cost_f})")
                computed_cost += max(cost_f, 0.0)
            terms = str(meta.get("terms_verification_status", "")).upper()
            if "UNKNOWN" in terms:
                errors.append(f"{name}: required tool has UNKNOWN terms status")
            if bool(meta.get("account_required")):
                errors.append(
                    f"{name}: account_required=true cannot gate CI/build required tools"
                )
            license_terms = str(meta.get("software_license_or_terms", "")).strip()
            if not license_terms:
                errors.append(f"{name}: missing software_license_or_terms")
            if not str(meta.get("provenance_requirement", "")).strip():
                errors.append(f"{name}: missing provenance_requirement")
            if not str(meta.get("output_rights_notes", "")).strip():
                errors.append(f"{name}: missing output_rights_notes")

        # REJECTED/EXPERIMENTAL must never be required
        if classification in {"REJECTED", "EXPERIMENTAL_TRANSIENT_TOOL"} and (
            bool(meta.get("required_for_repo_build"))
            or bool(meta.get("required_for_pipeline_pass"))
            or bool(meta.get("required_for_final_art_authoring"))
        ):
            errors.append(f"{name}: {classification} marked required")

        if classification == "OPTIONAL" and (
            bool(meta.get("required_for_repo_build"))
            or bool(meta.get("required_for_pipeline_pass"))
        ):
            errors.append(f"{name}: OPTIONAL cannot be required for build/pipeline")

    # Mixamo / VRoid flags
    mixamo = pin_map.get("Adobe Mixamo", {})
    if bool(mixamo.get("required_for_repo_build")) or pins.get("MIXAMO_REQUIRED_FOR_BUILD") is not False:
        if pins.get("MIXAMO_REQUIRED_FOR_BUILD") is not False:
            errors.append("MIXAMO_REQUIRED_FOR_BUILD must be false")
        if bool(mixamo.get("required_for_repo_build")):
            errors.append("Adobe Mixamo required_for_repo_build must be false")
    if pins.get("MIXAMO_REQUIRED_FOR_PIPELINE_PASS") is not False:
        errors.append("MIXAMO_REQUIRED_FOR_PIPELINE_PASS must be false")
    if pins.get("MIXAMO_REQUIRED_FOR_FINAL_ART") is not False:
        errors.append("MIXAMO_REQUIRED_FOR_FINAL_ART must be false")
    if pins.get("VROID_REQUIRED_FOR_BUILD") is not False:
        errors.append("VROID_REQUIRED_FOR_BUILD must be false")
    vroid = pin_map.get("VRoid Studio", {})
    if bool(vroid.get("required_for_repo_build")):
        errors.append("VRoid Studio required_for_repo_build must be false")
    if not bool(vroid.get("human_gui_required")):
        errors.append("VRoid Studio human_gui_required must be true")

    anyc = pin_map.get("anyCreature", {})
    out_notes = str(anyc.get("output_rights_notes", "")).lower()
    if "software_license_not_used_as_output_license" not in out_notes.replace(" ", "").lower() and "not" not in out_notes:
        # Soft check: notes must deny MIT-as-output inference
        if "infer output license" not in out_notes and "not automatically" not in out_notes:
            if "SOFTWARE_LICENSE_NOT_USED_AS_OUTPUT_LICENSE" not in str(anyc.get("output_rights_notes", "")):
                errors.append("anyCreature must state SOFTWARE_LICENSE_NOT_USED_AS_OUTPUT_LICENSE in output_rights_notes")

    # Markdown consistency
    matrix_path = ROOT / "docs/art_pipeline/FREE_TOOLCHAIN_AND_LICENSE_MATRIX.md"
    md_json_consistent = False
    if not matrix_path.exists():
        errors.append(f"missing {matrix_path}")
    else:
        mt = matrix_path.read_text(encoding="utf-8")
        if "fal.ai" not in mt.lower() or "REJECTED" not in mt:
            errors.append("License matrix must document fal.ai sprite-sheet path as REJECTED")
        if "SOFTWARE_LICENSE_NOT_USED_AS_OUTPUT_LICENSE" not in mt:
            errors.append("Matrix must declare SOFTWARE_LICENSE_NOT_USED_AS_OUTPUT_LICENSE")
        # Forbid legacy positive claim that software MIT grants output rights.
        if re.search(r"yes\s*\(\s*MIT outputs\s*\)", mt, re.I):
            errors.append("Matrix must not claim MIT outputs for anyCreature")
        if re.search(r"\byes\b.*\bMIT outputs\b|\bMIT outputs\b.*\ballowed\b", mt, re.I):
            errors.append("Matrix must not claim MIT outputs for anyCreature")
        md_classes = _parse_matrix_classifications(mt)
        mismatches = []
        for name, meta in pin_map.items():
            want = str(meta.get("classification", "")).upper()
            got = str(md_classes.get(name, "")).upper()
            if not got:
                mismatches.append(f"{name}: missing from markdown matrix")
            elif got != want and want not in got and got not in want:
                mismatches.append(f"{name}: md={got} json={want}")
        if mismatches:
            errors.extend(mismatches)
        else:
            md_json_consistent = True
        if "OPTIONAL" not in mt or "Mixamo" not in mt:
            errors.append("Matrix must classify Mixamo as OPTIONAL")

    errors.extend(_scan_paid_refs())

    # Workflow must not require fal without REJECTED docs-only context
    wf = ROOT / ".github/workflows/engineering-wave012.yml"
    if wf.exists():
        text = wf.read_text(encoding="utf-8")
        if re.search(r"fal\.ai|FAL_KEY", text, re.I):
            errors.append("fal.ai / FAL_KEY referenced in Wave012 workflow")

    pin_info = _anycreature_pin(pins)
    if not pin_info.get("ANYCREATURE_PIN_MATCH"):
        errors.append(
            f"anyCreature pin mismatch declared={pin_info.get('ANYCREATURE_DECLARED_COMMIT')} "
            f"actual={pin_info.get('ANYCREATURE_ACTUAL_COMMIT')}"
        )

    guard = _final_art_guard(pins)
    if guard["FINAL_ART_FALSE_POSITIVE_GUARD"] != "PASS":
        errors.extend(guard["errors"])

    if computed_cost != 0:
        errors.append(f"COMPUTED_CORE_PIPELINE_MONETARY_COST_USD must be 0, got {computed_cost}")

    out = {
        "pass": not errors,
        "COMPUTED_CORE_PIPELINE_MONETARY_COST_USD": int(computed_cost)
        if float(computed_cost).is_integer()
        else computed_cost,
        "CORE_PIPELINE_MONETARY_COST_USD": int(computed_cost)
        if float(computed_cost).is_integer()
        else computed_cost,
        "required_tools": required_names,
        "SOFTWARE_LICENSE_NOT_USED_AS_OUTPUT_LICENSE": True,
        "TOOLCHAIN_MD_JSON_CONSISTENT": md_json_consistent and not any(
            "md=" in e or "missing from markdown" in e for e in errors
        ),
        "MIXAMO_REQUIRED_FOR_BUILD": False,
        "MIXAMO_REQUIRED_FOR_PIPELINE_PASS": False,
        "MIXAMO_REQUIRED_FOR_FINAL_ART": False,
        "VROID_REQUIRED_FOR_BUILD": False,
        "VROID_FINAL_EXPORT_PRESENT": guard["VROID_FINAL_EXPORT_PRESENT"],
        "FINAL_ART_FALSE_POSITIVE_GUARD": guard["FINAL_ART_FALSE_POSITIVE_GUARD"],
        **pin_info,
        "errors": errors,
    }
    # Recompute consistency flag strictly
    out["TOOLCHAIN_MD_JSON_CONSISTENT"] = bool(md_json_consistent) and not any(
        ("missing from markdown" in e) or ("md=" in e) for e in errors
    )

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
