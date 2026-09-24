#!/usr/bin/env python3
"""Human-candidate asset validator. Contract only — never sets HUMAN_APPROVED."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import (  # noqa: E402
    FIGHTER_IDS,
    HERO_ACTIONS,
    HUMAN_ONLY_LABELS,
    ROOT,
    glb_stats,
    load_json,
    load_skeleton,
    path_looks_generated,
    write_json,
)
from validate_skeleton import validate_contract, validate_glb

MATERIAL_SOFT_MAX = 12
TRIANGLE_REPORT_ONLY = True


def validate_actions(stats: dict) -> list[str]:
    fails = []
    names = [str(n or "") for n in stats.get("animation_names") or []]
    if not names:
        # Mesh-only submissions are allowed; actions may arrive later.
        return fails
    unknown = [n for n in names if n not in HERO_ACTIONS and n not in ("pipeline_proof", "clash_lock", "charged_idle")]
    if unknown:
        fails.append(f"unknown_action_names:{unknown}")
    return fails


def validate_provenance(sidecar: dict) -> list[str]:
    fails = []
    status = str(sidecar.get("status") or sidecar.get("provenance") or "HUMAN_CANDIDATE")
    if status in HUMAN_ONLY_LABELS:
        fails.append("automation_or_submit_cannot_set_HUMAN_APPROVED")
    if bool(sidecar.get("human_animation_approved")) or bool(sidecar.get("HUMAN_APPROVED")):
        fails.append("sidecar_claims_HUMAN_APPROVED")
    if bool(sidecar.get("root_motion_authoritative")):
        fails.append("root_motion_authority_forbidden")
    if bool(sidecar.get("gameplay_root_motion")):
        fails.append("gameplay_root_motion_forbidden")
    return fails


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate a human-authored candidate GLB")
    parser.add_argument("--fighter", required=True)
    parser.add_argument("--asset", required=True)
    parser.add_argument("--sidecar", default="")
    args = parser.parse_args()
    fails: list[str] = []
    if args.fighter not in FIGHTER_IDS:
        fails.append("unknown_fighter")
    asset = Path(args.asset)
    if not asset.is_file():
        fails.append(f"asset_missing:{asset}")
        payload = {"ok": False, "failures": fails, "fighter": args.fighter}
        print(json.dumps(payload, indent=2))
        return 1
    if path_looks_generated(str(asset)):
        fails.append("generated_experiment_path_is_not_a_human_candidate")
    contract = load_skeleton()
    fails.extend(validate_contract(contract))
    try:
        fails.extend(validate_glb(asset, contract.get("required_bones", []), contract.get("required_sockets", [])))
        stats = glb_stats(asset)
    except Exception as exc:  # noqa: BLE001 — report load failures honestly
        fails.append(f"glb_load_failed:{exc}")
        stats = {}
    fails.extend(validate_actions(stats))
    sidecar = load_json(Path(args.sidecar)) if args.sidecar else {}
    fails.extend(validate_provenance(sidecar))
    if stats.get("material_count", 0) > MATERIAL_SOFT_MAX:
        fails.append(f"material_count_above_soft_max:{stats.get('material_count')}>{MATERIAL_SOFT_MAX}")
    payload = {
        "ok": not fails,
        "failures": fails,
        "fighter": args.fighter,
        "asset": str(asset),
        "triangle_count": stats.get("triangle_count", 0),
        "material_count": stats.get("material_count", 0),
        "animation_names": stats.get("animation_names", []),
        "skin_count": stats.get("skin_count", 0),
        "triangle_count_is_report_only": TRIANGLE_REPORT_ONLY,
        "provenance": sidecar.get("status", "HUMAN_CANDIDATE"),
        "HUMAN_APPROVED": False,
        "note": "PASS/FAIL is contract hygiene only. No human-quality judgment.",
    }
    write_json(ROOT / "artifacts/art_pipeline" / f"HUMAN_VALIDATE_{args.fighter}.json", payload)
    print(json.dumps(payload, indent=2))
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    raise SystemExit(main())
