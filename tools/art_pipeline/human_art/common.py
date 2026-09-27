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

HUMAN_ROSTER_GATES_FALSE = {
    "HUMAN_ROSTER_ART_DIRECTION_PASS": False,
    "HUMAN_ROSTER_SILHOUETTE_PASS": False,
    "HUMAN_ROSTER_ANIMATION_QUALITY_PASS": False,
    "HUMAN_ROSTER_COMBAT_FEEL_PASS": False,
    "HUMAN_ROSTER_HURT_READ_PASS": False,
    "HUMAN_ROSTER_SUPER_PASS": False,
    "HUMAN_ROSTER_CLASH_PASS": False,
    "HUMAN_ROSTER_MOBILE_READ_PASS": False,
    "HUMAN_ROSTER_CLIP_WORTHY_PASS": False,
}

MIN_REVIEW_ACTIONS = (
    "idle",
    "walk",
    "run",
    "charged_idle",
    "heavy",
    "hurt_heavy",
    "launch",
    "super",
    "clash_lock",
)

FULL_PRODUCTION_ACTIONS = (
    "idle",
    "personality_idle",
    "walk",
    "run",
    "dash",
    "jump",
    "fall",
    "landing",
    "light",
    "heavy_anticipation",
    "heavy",
    "heavy_follow",
    "grab",
    "hurt_light",
    "hurt_heavy",
    "launch",
    "ko",
    "charge",
    "charged_idle",
    "aura",
    "super",
    "clash_start",
    "clash_lock",
    "clash_push",
    "clash_winning",
    "clash_losing",
    "clash_break",
)

FULL_ROSTER_IMPACT_PAIRS = (
    ("ember-vale", "rook-ironside"),
    ("rook-ironside", "nix-calder"),
    ("juno-spark", "orion-vell"),
    ("kaia-windrow", "vesper-nyx"),
    ("nix-calder", "ember-vale"),
    ("orion-vell", "kaia-windrow"),
    ("vesper-nyx", "juno-spark"),
)

IMPACT_FRAMES = (
    "anticipation",
    "pre_contact",
    "contact_vfx_off",
    "peak_hurt_vfx_off",
    "follow_through",
    "launch_start",
    "contact_vfx_on",
)

ROSTER_REVIEW_SHOTS = (
    "front",
    "front_3q",
    "side",
    "back",
    "gameplay_scale",
    "select_preview",
    "silhouette",
    "idle",
    "walk",
    "run",
    "charged_idle",
    "heavy_anticipation",
    "heavy_contact",
    "heavy_follow",
    "hurt_heavy",
    "launch",
    "super",
    "clash_lock",
    "attachment_stress",
)

ROSTER_SHEETS = (
    "full_roster_select.png",
    "full_roster_front_3q.png",
    "full_roster_silhouette.png",
    "full_roster_gameplay_scale.png",
    "full_roster_heavy.png",
    "full_roster_hurt.png",
    "full_roster_super.png",
    "full_roster_clash.png",
)

STAGING_RESOLVER_CHAIN = (
    "HUMAN_APPROVED",
    "HUMAN_CANDIDATE",
    "CURRENT_ACCEPTED_ART",
    "PROCEDURAL_FALLBACK",
)
EXCLUDED_RESOLVER_CHAIN = ("GENERATED_EXPERIMENT",)

SUPPORTED_CANDIDATE_SUFFIXES = (".glb", ".gltf")


def load_json(path: Path) -> dict:
    if not path.is_file():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def load_skeleton() -> dict:
    return load_json(SKELETON)


def env_flag(name: str, default: str = "0") -> bool:
    return os.environ.get(name, default) not in ("", "0", "false", "False")


def human_art_staging_enabled() -> bool:
    return env_flag("HUMAN_ART_STAGING")


def human_art_full_roster_review_enabled() -> bool:
    return env_flag("HUMAN_ART_FULL_ROSTER_REVIEW")


def candidate_manifest_path(fighter_id: str) -> Path:
    return staging_dir(fighter_id) / "candidate_manifest.json"


def empty_candidate_manifest(fighter_id: str) -> dict:
    return {
        "fighter_id": fighter_id,
        "candidate_status": "MISSING",
        "source_type": "unknown",
        "source_reference": None,
        "license_or_rights_status": "pending",
        "mesh_path": None,
        "animation_paths": [],
        "submitted_at": None,
        "validated": False,
        "owner_approved": False,
        "SOURCE_KNOWN": False,
        "RIGHTS_DECLARATION_PRESENT": False,
        "COMMERCIAL_USE_STATUS": "undocumented",
        "GENERATED_EXPERIMENT": False,
        "HUMAN_CANDIDATE_RIGHTS_READY": False,
    }


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
