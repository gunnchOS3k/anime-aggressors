#!/usr/bin/env python3
"""Honest full-roster asset audit. Never promotes HUMAN_APPROVED or fakes candidates."""
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import (  # noqa: E402
    FIGHTER_IDS,
    FIGHTER_META,
    MIN_REVIEW_ACTIONS,
    ROOT,
    STAGING,
    candidate_manifest_path,
    candidate_rights_ready,
    empty_candidate_manifest,
    glb_stats,
    load_json,
    path_looks_generated,
    path_looks_staging,
    write_json,
)

MESH_SUFFIXES = {".glb", ".gltf", ".blend", ".fbx", ".obj", ".dae"}
SKIP_DIRS = {".git", "node_modules", ".godot", "__pycache__", "tmp"}


def classify_path(rel: str) -> str:
    lowered = rel.replace("\\", "/").lower()
    if path_looks_generated(rel) or "generated_production" in lowered:
        return "GENERATED_EXPERIMENT"
    if path_looks_staging(rel):
        return "HUMAN_CANDIDATE" if Path(ROOT / rel).is_file() and Path(ROOT / rel).stat().st_size > 0 else "MISSING"
    if "content/fighters/" in lowered and "_procedural_proxy." in lowered:
        return "CURRENT_ACCEPTED_ART"
    if "assets/exports/godot/fighters/" in lowered:
        return "CURRENT_ACCEPTED_ART"
    if "assets/blender/fighters/" in lowered:
        return "CURRENT_ACCEPTED_ART"
    if "art_source/generated/" in lowered:
        return "GENERATED_EXPERIMENT"
    if "assets/characters/proxy/" in lowered:
        return "PROCEDURAL_FALLBACK"
    if "assets/characters/procedural_final/" in lowered:
        return "PROCEDURAL_FALLBACK"
    if "builds/digital-rc/" in lowered:
        return "PROCEDURAL_FALLBACK"
    return "UNKNOWN"


def fighter_from_path(rel: str) -> str | None:
    lowered = rel.replace("\\", "/").lower()
    for fid in FIGHTER_IDS:
        if fid in lowered:
            return fid
    return None


def scan() -> list[dict]:
    rows = []
    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
        if any(part in SKIP_DIRS for part in path.parts):
            continue
        if path.suffix.lower() not in MESH_SUFFIXES:
            continue
        rel = str(path.relative_to(ROOT)).replace("\\", "/")
        fid = fighter_from_path(rel)
        if fid is None:
            continue
        rows.append(
            {
                "path": rel,
                "fighter_id": fid,
                "suffix": path.suffix.lower(),
                "bytes": path.stat().st_size,
                "provenance": classify_path(rel),
                "human_source_evidence": False,
                "owner_approved": False,
                "on_pr106_only": False,
            }
        )
    return sorted(rows, key=lambda r: (r["fighter_id"], r["path"]))


def pr106_generated_note() -> list[dict]:
    # Recorded from live PR #106 worktree inspection. Not present on this branch.
    return [
        {
            "path": f"game-godot/content/fighters/{fid}/model/{fid}_generated_production.glb",
            "fighter_id": fid,
            "suffix": ".glb",
            "bytes": None,
            "provenance": "GENERATED_EXPERIMENT",
            "human_source_evidence": False,
            "owner_approved": False,
            "on_pr106_only": True,
            "branch": "vxp/vxp-3-combat-impact-nix-rook",
            "head": "8cd3e1359f11644787c79de4a6f03e17dbf1ec56",
        }
        for fid in FIGHTER_IDS
    ]


def main() -> int:
    assets = scan()
    by_fighter = {fid: [] for fid in FIGHTER_IDS}
    for row in assets:
        by_fighter[row["fighter_id"]].append(row)
    lanes = {}
    missing = {}
    for fid in FIGHTER_IDS:
        rows = by_fighter[fid]
        provenances = {r["provenance"] for r in rows}
        human = [r for r in rows if r["provenance"] == "HUMAN_CANDIDATE"]
        manifest = load_json(candidate_manifest_path(fid))
        staged = STAGING / fid / f"{fid}.glb"
        stats = glb_stats(staged) if staged.is_file() else {}
        anims = {str(n or "") for n in (stats.get("animation_names") or [])}
        missing_actions = [a for a in MIN_REVIEW_ACTIONS if a not in anims]
        rights_ready = candidate_rights_ready(manifest)
        lanes[fid] = {
            "fighter_id": fid,
            "display_name": FIGHTER_META[fid]["name"],
            "lane": FIGHTER_META[fid]["lane"],
            "candidate_status": manifest.get("candidate_status") or ("HUMAN_CANDIDATE" if human else "MISSING"),
            "owner_approved": False,
            "asset_count": len(rows),
            "provenances_present": sorted(provenances),
            "human_candidate_assets": [r["path"] for r in human],
            "current_accepted_art": [r["path"] for r in rows if r["provenance"] == "CURRENT_ACCEPTED_ART"],
            "generated_experiment_on_this_branch": [
                r["path"] for r in rows if r["provenance"] == "GENERATED_EXPERIMENT"
            ],
            "unknown": [r["path"] for r in rows if r["provenance"] == "UNKNOWN"],
            "animation_names": sorted(anims),
            "CANDIDATE_RIGHTS_READY": rights_ready,
        }
        missing[fid] = {
            "mesh": not staged.is_file(),
            "rig": int(stats.get("skin_count") or 0) < 1,
            "min_review_actions": missing_actions,
            "rights": "documented" if rights_ready else "undocumented",
            "source": manifest.get("source_reference") or "none",
        }
    complete = all(
        lanes[fid]["candidate_status"] == "HUMAN_CANDIDATE"
        and not missing[fid]["mesh"]
        and not missing[fid]["rig"]
        and not missing[fid]["min_review_actions"]
        for fid in FIGHTER_IDS
    )
    payload = {
        "ok": True,
        "FULL_ROSTER_HUMAN_CANDIDATES_COMPLETE": complete,
        "HUMAN_APPROVED": False,
        "generated_experiment_excluded_from_resolver": True,
        "note": (
            "Candidate completeness is computed from staging manifests and GLBs. "
            "Procedural proxies remain CURRENT_ACCEPTED_ART in production. "
            "PR #106 generated V2–V9 production GLBs stay on the frozen R&D branch."
        ),
        "fighters": lanes,
        "assets_on_this_branch": assets,
        "pr106_generated_experiment_not_present_here": pr106_generated_note(),
        "unknown_must_not_be_promoted": True,
        "empty_manifest_template": empty_candidate_manifest("<fighter-id>"),
    }
    write_json(ROOT / "artifacts/art_pipeline/full_roster_asset_audit.json", payload)
    write_json(
        ROOT / "artifacts/art_pipeline/FULL_ROSTER_MISSING_ASSETS.json",
        {
            "FULL_ROSTER_HUMAN_CANDIDATES_COMPLETE": complete,
            "fighters": missing,
            "Mode_B_eligible": complete,
            "Mode_A_purpose": "integration baseline only — not a human-art quality review",
        },
    )
    print(json.dumps({"ok": True, "fighters": {k: v["candidate_status"] for k, v in lanes.items()}}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
