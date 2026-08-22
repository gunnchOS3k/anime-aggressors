"""Export helpers for procedural roster GLB production proxies."""
from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def resolve_source_glb(fighter_id: str) -> Path | None:
    for candidate in (
        ROOT / "game-godot/assets/characters/procedural_final" / f"{fighter_id}.glb",
        ROOT / "game-godot/assets/characters/proxy" / f"{fighter_id}.glb",
    ):
        if candidate.is_file() and candidate.stat().st_size > 1024:
            return candidate
    return None


def try_blender_generate(fighter_id: str) -> bool:
    blender_candidates = (
        "/Applications/Blender.app/Contents/MacOS/Blender",
        "blender",
    )
    script = ROOT / "tools/blender/generate_fighter_blockouts.py"
    if not script.is_file():
        return False
    for blender in blender_candidates:
        try:
            proc = subprocess.run(
                [blender, "--background", "--python", str(script)],
                cwd=ROOT,
                capture_output=True,
                text=True,
                timeout=900,
            )
        except (FileNotFoundError, subprocess.TimeoutExpired):
            continue
        if proc.returncode == 0:
            return resolve_source_glb(fighter_id) is not None
    return False


def export_proxy_glb(fighter_id: str, *, force_blender: bool = False) -> dict:
    art_dir = ROOT / "art_source/generated/procedural" / fighter_id
    content_dir = ROOT / "content/fighters" / fighter_id / "model"
    godot_content_dir = ROOT / "game-godot/content/fighters" / fighter_id / "model"
    art_dir.mkdir(parents=True, exist_ok=True)
    content_dir.mkdir(parents=True, exist_ok=True)
    godot_content_dir.mkdir(parents=True, exist_ok=True)
    out_name = f"{fighter_id}_procedural_proxy.glb"
    out_art = art_dir / out_name
    out_content = content_dir / out_name
    out_godot = godot_content_dir / out_name

    if force_blender:
        try_blender_generate(fighter_id)

    source = resolve_source_glb(fighter_id)
    if source is None:
        raise FileNotFoundError(f"No source GLB for {fighter_id}")

    shutil.copy2(source, out_art)
    shutil.copy2(source, out_content)
    shutil.copy2(source, out_godot)
    digest = _sha256(out_content)
    meta = {
        "fighter_id": fighter_id,
        "status": "PROCEDURAL_PRODUCTION_PROXY",
        "source_glb": str(source.relative_to(ROOT)),
        "export_glb": str(out_content.relative_to(ROOT)),
        "sha256": digest,
        "size_bytes": out_content.stat().st_size,
        "triangle_budget_preferred": 35000,
        "material_budget": 6,
    }
    (art_dir / "export_manifest.json").write_text(json.dumps(meta, indent=2) + "\n", encoding="utf-8")
    return meta
