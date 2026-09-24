"""Shared constants for human-art infrastructure. No quality judgment."""
from __future__ import annotations

import json
import os
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SKELETON = ROOT / "art_source/animation/shared/deform_skeleton/CANONICAL_DEFORM_SKELETON.json"
STAGING = ROOT / "game-godot/content/human_art_staging"
ACCEPTED_PROXY = ROOT / "game-godot/content/fighters"
ARTIFACTS = ROOT / "artifacts/art_pipeline"

FIGHTER_IDS = (
    "ember-vale",
    "rook-ironside",
    "juno-spark",
    "kaia-windrow",
    "nix-calder",
    "orion-vell",
    "vesper-nyx",
)

FIGHTER_META = {
    "ember-vale": {"name": "Ember Vale", "lane": "flame / rush", "identity": "aggression"},
    "rook-ironside": {"name": "Rook Ironside", "lane": "impact / armor", "identity": "weight"},
    "juno-spark": {"name": "Juno Spark", "lane": "volt / trick", "identity": "snap speed"},
    "kaia-windrow": {"name": "Kaia Windrow", "lane": "gale / carry", "identity": "flow/air"},
    "nix-calder": {"name": "Nix Calder", "lane": "frost / control", "identity": "precision"},
    "orion-vell": {"name": "Orion Vell", "lane": "gravity / trap", "identity": "orbit/control"},
    "vesper-nyx": {"name": "Vesper Nyx", "lane": "void / mix", "identity": "deception/phase"},
}

HERO_ACTIONS = (
    "idle",
    "walk",
    "run",
    "dash",
    "jump",
    "light",
    "medium",
    "heavy",
    "aura",
    "super",
    "hurt_heavy",
    "launch",
    "charge",
    "ko",
)

STRESS_ACTIONS = (
    "idle",
    "walk",
    "run",
    "dash",
    "heavy",
    "hurt",
    "charge",
    "super",
    "clash",
    "KO",
)

ACTION_ALIASES = {
    "hurt": "hurt_heavy",
    "clash": "clash_lock",
    "KO": "ko",
}

PROVENANCE_LABELS = (
    "CURRENT_ACCEPTED_ART",
    "HUMAN_CANDIDATE",
    "HUMAN_APPROVED",
    "GENERATED_EXPERIMENT",
    "PROCEDURAL_FALLBACK",
    "MISSING",
)
AUTOMATION_MAY_WRITE = (
    "CURRENT_ACCEPTED_ART",
    "HUMAN_CANDIDATE",
    "GENERATED_EXPERIMENT",
    "PROCEDURAL_FALLBACK",
    "MISSING",
)
HUMAN_ONLY_LABELS = ("HUMAN_APPROVED",)

ATTACHMENT_CLASSES = (
    "SKINNED_COSTUME",
    "BONE_RIGID",
    "SECONDARY_CHAIN",
    "VFX_ORBIT",
    "WORLD_STATIC",
)

IMPACT_ANCHORS = (
    "HEAD",
    "CHEST",
    "TORSO_LEFT",
    "TORSO_RIGHT",
    "PELVIS",
    "UPPER_GUARD",
    "LOWER_GUARD",
)

GENERATED_PATH_MARKERS = (
    "generated_production",
    "generated_art_v",
    "/generated/",
    "_generated_production",
    "GENERATED_PRODUCTION_ART",
    "art_source/generated",
)

HUMAN_GATES_FALSE = {
    "HUMAN_ART_DIRECTION_APPROVAL": False,
    "HUMAN_ANIMATION_QUALITY_PASS": False,
    "HUMAN_COMBAT_FEEL_PASS": False,
    "HUMAN_AURA_CLASH_PASS": False,
    "HUMAN_CLIP_WORTHY_PASS": False,
    "FINAL_AUTHORED_ANIMATION_PASS": False,
    "MERGE_AUTHORIZED": False,
}


def load_json(path: Path) -> dict:
    if not path.is_file():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def load_skeleton() -> dict:
    return load_json(SKELETON)


def human_art_staging_enabled() -> bool:
    return os.environ.get("HUMAN_ART_STAGING", "0") not in ("", "0", "false", "False")


def path_looks_generated(path: str) -> bool:
    lowered = path.replace("\\", "/").lower()
    return any(marker.lower() in lowered for marker in GENERATED_PATH_MARKERS)


def path_looks_staging(path: str) -> bool:
    return "human_art_staging" in path.replace("\\", "/")


def accepted_proxy_glb(fighter_id: str) -> Path:
    return ACCEPTED_PROXY / fighter_id / "model" / f"{fighter_id}_procedural_proxy.glb"


def staging_dir(fighter_id: str) -> Path:
    return STAGING / fighter_id


def glb_json(path: Path) -> dict:
    raw = path.read_bytes()
    if raw[:4] != b"glTF":
        raise ValueError(f"{path} is not a glTF binary")
    chunk_len = struct.unpack_from("<I", raw, 12)[0]
    chunk_type = raw[16:20]
    if chunk_type != b"JSON":
        raise ValueError(f"{path} first chunk is not JSON")
    return json.loads(raw[20 : 20 + chunk_len])


def glb_node_names(path: Path) -> set[str]:
    data = glb_json(path)
    return {str(n.get("name") or "") for n in data.get("nodes", [])}


def glb_stats(path: Path) -> dict:
    data = glb_json(path)
    meshes = data.get("meshes") or []
    primitives = 0
    extras = data.get("extras") or {}
    for mesh in meshes:
        primitives += len(mesh.get("primitives") or [])
    accessors = {i: a for i, a in enumerate(data.get("accessors") or [])}
    triangle_count = 0
    for mesh in meshes:
        for prim in mesh.get("primitives") or []:
            idx = prim.get("indices")
            if idx is None:
                continue
            acc = accessors.get(idx) or {}
            count = int(acc.get("count") or 0)
            triangle_count += count // 3
    materials = data.get("materials") or []
    animations = data.get("animations") or []
    skins = data.get("skins") or []
    return {
        "nodes": [n.get("name") for n in data.get("nodes", [])],
        "mesh_count": len(meshes),
        "primitive_count": primitives,
        "triangle_count": triangle_count,
        "material_count": len(materials),
        "animation_names": [a.get("name") for a in animations],
        "skin_count": len(skins),
        "extras": extras,
        "has_animations": bool(animations),
        "has_skins": bool(skins),
    }
