#!/usr/bin/env python3
"""Honest Mode A resolver matrix. Never invents HUMAN_CANDIDATE assets."""
from __future__ import annotations

import json
from pathlib import Path

from common import ACCEPTED_PROXY, ARTIFACTS, FIGHTER_IDS, FIGHTER_META, STAGING, candidate_manifest_path, load_json, write_json


def resolve_row(fighter_id: str) -> dict:
    manifest = load_json(candidate_manifest_path(fighter_id))
    staged = STAGING / fighter_id / f"{fighter_id}.glb"
    approved = STAGING / fighter_id / "approved" / f"{fighter_id}.glb"
    proxy = ACCEPTED_PROXY / fighter_id / "model" / f"{fighter_id}_procedural_proxy.glb"
    generated = list((ACCEPTED_PROXY / fighter_id).rglob("*generated*")) if (ACCEPTED_PROXY / fighter_id).is_dir() else []
    human_candidate = staged.is_file() and manifest.get("candidate_status") == "HUMAN_CANDIDATE"
    owner_approved = bool(manifest.get("owner_approved")) and approved.is_file()
    if owner_approved:
        source = "HUMAN_APPROVED"
        asset_id = str(approved.relative_to(ACCEPTED_PROXY.parent.parent))
    elif human_candidate:
        source = "HUMAN_CANDIDATE"
        asset_id = str(staged.relative_to(STAGING.parent.parent))
    elif proxy.is_file():
        source = "CURRENT_ACCEPTED_ART"
        asset_id = f"{fighter_id}_procedural_proxy.glb"
    else:
        source = "PROCEDURAL_FALLBACK"
        asset_id = "missing_accepted_proxy"
    return {
        "fighter": FIGHTER_META[fighter_id]["name"],
        "fighter_id": fighter_id,
        "resolved_source": source,
        "asset_id": asset_id,
        "human_candidate": human_candidate,
        "validated": bool(manifest.get("validated")),
        "owner_approved": bool(manifest.get("owner_approved")),
        "generated_experiment_selected": False,
        "generated_experiment_paths_ignored": [str(p.name) for p in generated],
        "candidate_status": manifest.get("candidate_status", "MISSING"),
    }


def main() -> int:
    rows = [resolve_row(fid) for fid in FIGHTER_IDS]
    payload = {
        "ok": all(not r["generated_experiment_selected"] for r in rows)
        and all(r["resolved_source"] in ("CURRENT_ACCEPTED_ART", "PROCEDURAL_FALLBACK") for r in rows)
        and all(not r["human_candidate"] for r in rows)
        and all(not r["owner_approved"] for r in rows),
        "gate": "MODE_A_RESOLVER_TRUTH_PASS",
        "MODE_A_RESOLVER_TRUTH_PASS": True,
        "MODE_B_ELIGIBLE": False,
        "HUMAN_CANDIDATE_COUNT": sum(1 for r in rows if r["human_candidate"]),
        "HUMAN_APPROVED_COUNT": sum(1 for r in rows if r["owner_approved"]),
        "fighters": rows,
        "note": "Mode A uses CURRENT_ACCEPTED_ART / PROCEDURAL_FALLBACK only. Generated V2–V9 are excluded.",
    }
    payload["MODE_A_RESOLVER_TRUTH_PASS"] = payload["ok"]
    out = ARTIFACTS / "pixel_mode_a" / "ART_SOURCE_MATRIX.json"
    write_json(out, payload)
    print(json.dumps(payload, indent=2))
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
