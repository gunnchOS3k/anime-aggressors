#!/usr/bin/env python3
"""Adapt verified CC0 KayKit characters into human_art_staging candidates."""
from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import FIGHTER_IDS, ROOT, STAGING, glb_stats, write_json  # noqa: E402

MAP_PATH = Path(__file__).resolve().parent / "cc0_roster_map.json"
SOURCE_ROOT = ROOT / "tmp/cc0_sources"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def find_blender() -> str:
    env = os.environ.get("BLENDER_BIN")
    candidates = (
        env,
        shutil.which("blender"),
        "/Applications/Blender.app/Contents/MacOS/Blender",
    )
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            return str(candidate)
    raise FileNotFoundError("Blender not found")


def pack_dir(pack_id: str) -> Path:
    if pack_id == "kaykit_adventurers":
        return SOURCE_ROOT / "KayKit-Character-Pack-Adventures-1.0"
    if pack_id == "kaykit_skeletons":
        return SOURCE_ROOT / "KayKit-Character-Pack-Skeletons-1.0"
    raise KeyError(pack_id)


def adapt_fighter(blender: str, mapping: dict, fighter_id: str) -> dict:
    row = mapping["fighters"][fighter_id]
    pack = mapping["packs"][row["pack"]]
    source = pack_dir(row["pack"]) / row["source_relpath"]
    if not source.is_file():
        raise FileNotFoundError(source)
    dest_dir = STAGING / fighter_id
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest = dest_dir / f"{fighter_id}.glb"
    script = Path(__file__).resolve().parent / "blender/adapt_cc0_kaykit_candidate.py"
    proc = subprocess.run(
        [
            blender,
            "--background",
            "--python",
            str(script),
            "--",
            "--input",
            str(source),
            "--output",
            str(dest),
            "--config",
            str(MAP_PATH),
            "--fighter",
            fighter_id,
        ],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    blender_json = {}
    for line in reversed((proc.stdout or "").splitlines()):
        line = line.strip()
        if line.startswith("{") and line.endswith("}"):
            try:
                blender_json = json.loads(line)
                break
            except json.JSONDecodeError:
                continue
    if proc.returncode != 0 or not dest.is_file():
        raise RuntimeError(
            f"{fighter_id} adapt failed rc={proc.returncode}\n"
            f"stdout={proc.stdout[-1500:]}\nstderr={proc.stderr[-1500:]}"
        )
    stats = glb_stats(dest)
    source_hash = sha256(source)
    dest_hash = sha256(dest)
    clip_map = row["clips"]
    rights_path = dest_dir / "RIGHTS.json"
    source_manifest = dest_dir / "SOURCE_MANIFEST.json"
    provenance = dest_dir / "PROVENANCE.json"
    now = datetime.now(timezone.utc).isoformat()
    rights = {
        "fighter_id": fighter_id,
        "SOURCE_KNOWN": True,
        "RIGHTS_DECLARATION_PRESENT": True,
        "COMMERCIAL_USE_STATUS": "commercial_use_allowed",
        "license": pack["license"],
        "license_url": pack["license_url"],
        "attribution_required": pack["attribution_required"],
        "attribution_appreciated": pack["attribution_appreciated"],
        "redistribution_in_repo_allowed": pack["redistribution_in_repo_allowed"],
        "GENERATED_EXPERIMENT": False,
        "CANDIDATE_RIGHTS_READY": True,
        "ai_generated": False,
    }
    source_payload = {
        "fighter_id": fighter_id,
        "source_type": "cc0_pack",
        "pack_title": pack["title"],
        "author": pack["author"],
        "publisher": pack["publisher"],
        "source_url": pack["source_url"],
        "homepage": pack.get("homepage"),
        "source_character": row["source_character"],
        "source_relpath": row["source_relpath"],
        "source_sha256": source_hash,
        "source_bytes": source.stat().st_size,
        "license": pack["license"],
        "license_url": pack["license_url"],
        "git_commit": pack.get("git_commit"),
        "identity_lane": row["identity_lane"],
        "approximation": row["approximation"],
        "clip_mapping": clip_map,
        "modifications": mapping["modifications"],
        "captured_at": now,
    }
    provenance_payload = {
        "fighter_id": fighter_id,
        "candidate_status": "HUMAN_CANDIDATE",
        "mesh_source": source_payload,
        "animation_source": {
            "same_as_mesh": True,
            "pack_title": pack["title"],
            "clip_mapping": clip_map,
            "note": "Clips were renamed from the source pack. No Mixamo or generated clips were added.",
        },
        "adapted_glb": {
            "path": str(dest.relative_to(ROOT)),
            "sha256": dest_hash,
            "bytes": dest.stat().st_size,
            "stats": stats,
        },
        "blender_adapter": blender_json,
        "HUMAN_APPROVED": False,
        "GENERATED_EXPERIMENT": False,
    }
    write_json(rights_path, rights)
    write_json(source_manifest, source_payload)
    write_json(provenance, provenance_payload)
    candidate = {
        "fighter_id": fighter_id,
        "candidate_status": "HUMAN_CANDIDATE",
        "source_type": "cc0_pack",
        "source_reference": pack["source_url"],
        "source_character": row["source_character"],
        "license_or_rights_status": pack["license"],
        "mesh_path": str(dest.relative_to(ROOT)),
        "animation_paths": [str(dest.relative_to(ROOT))],
        "clip_mapping": clip_map,
        "submitted_at": now,
        "validated": False,
        "owner_approved": False,
        "SOURCE_KNOWN": True,
        "RIGHTS_DECLARATION_PRESENT": True,
        "COMMERCIAL_USE_STATUS": "commercial_use_allowed",
        "GENERATED_EXPERIMENT": False,
        "CANDIDATE_RIGHTS_READY": True,
        "approximation": row["approximation"],
        "identity_lane": row["identity_lane"],
        "source_sha256": source_hash,
        "adapted_sha256": dest_hash,
        "triangle_count": stats.get("triangle_count"),
        "material_count": stats.get("material_count"),
        "animation_names": stats.get("animation_names"),
        "skin_count": stats.get("skin_count"),
    }
    write_json(dest_dir / "candidate_manifest.json", candidate)
    return candidate


def main() -> int:
    mapping = json.loads(MAP_PATH.read_text(encoding="utf-8"))
    blender = find_blender()
    rows = []
    for fighter_id in FIGHTER_IDS:
        print(f"adapting {fighter_id}...", flush=True)
        rows.append(adapt_fighter(blender, mapping, fighter_id))
    write_json(ROOT / "artifacts/art_pipeline/CC0_ADAPT_RESULT.json", {"ok": True, "fighters": rows})
    print(json.dumps({"ok": True, "count": len(rows)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
