#!/usr/bin/env python3
"""Validate all seven fighter manifests and any actual supplied candidate assets."""
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import (  # noqa: E402
    FIGHTER_IDS,
    FIGHTER_META,
    HUMAN_ONLY_LABELS,
    MIN_REVIEW_ACTIONS,
    ROOT,
    STAGING,
    SUPPORTED_CANDIDATE_SUFFIXES,
    candidate_manifest_path,
    empty_candidate_manifest,
    glb_stats,
    load_json,
    load_skeleton,
    path_looks_generated,
    write_json,
)
from validate_human_art import validate_actions, validate_provenance  # noqa: E402
from validate_skeleton import validate_contract, validate_glb  # noqa: E402

MATERIAL_SOFT_MAX = 12


def _row() -> dict:
    return {
        "candidate": "FAIL",
        "contract": "N/A",
        "actions": "N/A",
        "attachments": "N/A",
        "provenance": "FAIL",
        "ready": "NO",
        "failures": [],
        "triangle_count": None,
        "material_count": None,
    }


def validate_fighter(fighter_id: str) -> dict:
    row = _row()
    fails: list[str] = []
    manifest_path = candidate_manifest_path(fighter_id)
    manifest = load_json(manifest_path) if manifest_path.is_file() else empty_candidate_manifest(fighter_id)
    if not manifest_path.is_file():
        fails.append("manifest_missing")
    status = str(manifest.get("candidate_status") or "MISSING")
    if status in HUMAN_ONLY_LABELS or manifest.get("owner_approved") is True:
        fails.append("automation_or_submit_cannot_set_HUMAN_APPROVED")
    if bool(manifest.get("GENERATED_EXPERIMENT")):
        fails.append("manifest_marks_generated_experiment")
    mesh = manifest.get("mesh_path")
    mesh_path = Path(mesh) if mesh else STAGING / fighter_id / f"{fighter_id}.glb"
    if not mesh_path.is_absolute():
        mesh_path = ROOT / mesh_path if mesh else mesh_path
    exists = mesh_path.is_file() and mesh_path.stat().st_size > 0
    if status == "MISSING" and not exists:
        row["candidate"] = "MISSING"
        row["provenance"] = "PASS" if status == "MISSING" and not manifest.get("owner_approved") else "FAIL"
        fails.append("human_candidate_asset_absent")
    elif not exists:
        fails.append("candidate_file_missing")
        row["candidate"] = "FAIL"
    else:
        if mesh_path.suffix.lower() not in SUPPORTED_CANDIDATE_SUFFIXES:
            fails.append(f"unsupported_format:{mesh_path.suffix}")
        if path_looks_generated(str(mesh_path)):
            fails.append("generated_experiment_path_is_not_a_human_candidate")
        row["candidate"] = "PASS" if status == "HUMAN_CANDIDATE" else "FAIL"
        if status != "HUMAN_CANDIDATE":
            fails.append(f"status_not_HUMAN_CANDIDATE:{status}")
        contract = load_skeleton()
        contract_fails = validate_contract(contract)
        try:
            contract_fails.extend(
                validate_glb(mesh_path, contract.get("required_bones", []), contract.get("required_sockets", []))
            )
            stats = glb_stats(mesh_path)
        except Exception as exc:  # noqa: BLE001
            contract_fails.append(f"glb_load_failed:{exc}")
            stats = {}
        row["triangle_count"] = stats.get("triangle_count")
        row["material_count"] = stats.get("material_count")
        row["contract"] = "PASS" if not contract_fails else "FAIL"
        fails.extend(contract_fails)
        action_fails = validate_actions(stats)
        names = {str(n or "") for n in (stats.get("animation_names") or [])}
        missing_min = [a for a in MIN_REVIEW_ACTIONS if a not in names]
        if missing_min:
            action_fails.append(f"missing_min_review_actions:{missing_min}")
        row["actions"] = "PASS" if not action_fails else "FAIL"
        fails.extend(action_fails)
        extras = stats.get("extras") or {}
        attachments = extras.get("attachment_classes") or manifest.get("attachment_classes")
        row["attachments"] = "PASS" if attachments else "REPORT"
        sidecar_fails = validate_provenance(manifest)
        if not manifest.get("SOURCE_KNOWN"):
            sidecar_fails.append("SOURCE_KNOWN=false")
        if not manifest.get("RIGHTS_DECLARATION_PRESENT"):
            sidecar_fails.append("RIGHTS_DECLARATION_PRESENT=false")
        row["provenance"] = "PASS" if not sidecar_fails else "FAIL"
        fails.extend(sidecar_fails)
        if stats.get("material_count", 0) > MATERIAL_SOFT_MAX:
            fails.append(f"material_count_above_soft_max:{stats.get('material_count')}>{MATERIAL_SOFT_MAX}")
    row["failures"] = fails
    structural_ready = (
        row["candidate"] == "PASS"
        and row["contract"] == "PASS"
        and row["actions"] == "PASS"
        and row["provenance"] == "PASS"
        and not path_looks_generated(str(mesh_path))
    )
    row["ready"] = "YES" if structural_ready else "NO"
    row["fighter_id"] = fighter_id
    row["display_name"] = FIGHTER_META[fighter_id]["name"]
    row["candidate_status"] = status
    row["HUMAN_APPROVED"] = False
    return row


def matrix_text(rows: list[dict]) -> str:
    header = "fighter | candidate | contract | actions | attachments | provenance | ready"
    lines = [header, "-" * len(header)]
    for row in rows:
        lines.append(
            f"{row['fighter_id']} | {row['candidate']} | {row['contract']} | {row['actions']} | "
            f"{row['attachments']} | {row['provenance']} | {row['ready']}"
        )
    return "\n".join(lines)


def main() -> int:
    rows = [validate_fighter(fid) for fid in FIGHTER_IDS]
    complete = all(r["ready"] == "YES" for r in rows)
    rights_ready = True
    for fid in FIGHTER_IDS:
        manifest = load_json(candidate_manifest_path(fid))
        ready_row = next(r for r in rows if r["fighter_id"] == fid)
        if ready_row["ready"] == "YES" and not manifest.get("owner_approved"):
            manifest["validated"] = True
            write_json(candidate_manifest_path(fid), manifest)
        rights_ready = rights_ready and bool(manifest.get("SOURCE_KNOWN")) and bool(
            manifest.get("RIGHTS_DECLARATION_PRESENT")
        ) and str(manifest.get("COMMERCIAL_USE_STATUS")) == "commercial_use_allowed" and not bool(
            manifest.get("GENERATED_EXPERIMENT")
        )
    rights_ready = rights_ready and complete
    payload = {
        "ok": True,
        "FULL_ROSTER_VALIDATOR_PASS": True,
        "FULL_ROSTER_HUMAN_CANDIDATE_CONTRACT_PASS": complete,
        "FULL_ROSTER_HUMAN_CANDIDATES_COMPLETE": complete,
        "HUMAN_APPROVED": False,
        "CANDIDATE_RIGHTS_READY": rights_ready,
        "note": "PASS/FAIL is contract hygiene only. Missing candidates are reported, not invented.",
        "matrix": matrix_text(rows),
        "fighters": rows,
        "counts": {
            "candidate": sum(1 for r in rows if r["candidate"] == "PASS"),
            "validated": sum(1 for r in rows if r["ready"] == "YES"),
            "owner_approved": 0,
            "total": 7,
        },
    }
    write_json(ROOT / "artifacts/art_pipeline/FULL_ROSTER_VALIDATOR.json", payload)
    print(json.dumps({
        "ok": payload["ok"],
        "complete": complete,
        "CANDIDATE_RIGHTS_READY": rights_ready,
        "counts": payload["counts"],
        "matrix": payload["matrix"],
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
