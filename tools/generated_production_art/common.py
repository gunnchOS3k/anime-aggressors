"""Generated production art constants. Not human-authored art."""
from __future__ import annotations

import hashlib
import json
import os
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GODOT = ROOT / "game-godot"
ANIM_SRC = ROOT / "art_source" / "animation"
ART_GEN = ROOT / "art_source" / "generated" / "production"
ARTIFACTS = ROOT / "artifacts" / "vxp3"
REPORTS = ARTIFACTS / "reports"

GENERATOR = "aa_generated_production_art"
GENERATOR_VERSION = "2.0.0"
GENERATOR_REVISION = "cohesive_body_v2_remesh"
STATUS = "GENERATED_PRODUCTION_ART"
ANIM_STATUS = "GENERATED_PRODUCTION_ANIMATION"
BLENDER_VERSION = "3.3.1"

FIGHTERS = (
    ("ember-vale", "Ember Vale", "flame", "rushdown"),
    ("rook-ironside", "Rook Ironside", "impact", "bruiser"),
    ("juno-spark", "Juno Spark", "volt", "speed"),
    ("kaia-windrow", "Kaia Windrow", "gale", "aerial"),
    ("nix-calder", "Nix Calder", "frost", "precision"),
    ("orion-vell", "Orion Vell", "gravity", "control"),
    ("vesper-nyx", "Vesper Nyx", "void", "trickster"),
)
FIGHTER_IDS = tuple(row[0] for row in FIGHTERS)

CANONICAL_BONES = (
    "Root",
    "Hips",
    "Spine",
    "Chest",
    "Neck",
    "Head",
    "Shoulder_L",
    "UpperArm_L",
    "LowerArm_L",
    "Hand_L",
    "Shoulder_R",
    "UpperArm_R",
    "LowerArm_R",
    "Hand_R",
    "UpperLeg_L",
    "LowerLeg_L",
    "Foot_L",
    "Toes_L",
    "UpperLeg_R",
    "LowerLeg_R",
    "Foot_R",
    "Toes_R",
)

POSE_BONES = tuple(b for b in CANONICAL_BONES if b != "Root")

WAVE_A = (
    "idle",
    "personality_idle",
    "walk",
    "run",
    "dash",
    "charged_idle",
    "charge_start",
    "charge_full",
    "heavy",
    "hurt_heavy",
    "launch_tumble",
    "aura_signature",
    "ko_reaction",
    "aura_burst_super_pose",
)

RUNTIME_ALIASES = {
    "launch_tumble": "launch",
    "aura_signature": "signature_lane_burst",
    "ko_reaction": "ko",
    "aura_burst_super_pose": "signature_lane_finisher",
    "apex": "jump_apex",
}


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 16), b""):
            h.update(chunk)
    return h.hexdigest()


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def write_json(path: Path, payload) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def load_json(path: Path) -> dict:
    if not path.is_file():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def find_blender() -> str | None:
    env = os.environ.get("BLENDER_BIN")
    candidates = (
        env,
        shutil.which("blender"),
        "/Applications/Blender.app/Contents/MacOS/Blender",
        str(Path.home() / "Applications" / "Blender.app" / "Contents" / "MacOS" / "Blender"),
    )
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            return candidate
    return None


def production_master_blend(fid: str) -> Path:
    return ANIM_SRC / "fighters" / fid / "source" / f"{fid}_production_master.blend"


def generated_model_glb(fid: str) -> Path:
    return GODOT / "content" / "fighters" / fid / "model" / f"{fid}_generated_production.glb"


def generated_anim_dir(fid: str) -> Path:
    return GODOT / "content" / "fighters" / fid / "animations" / "generated_production"


def generated_audio_dir(fid: str) -> Path:
    return GODOT / "assets" / "audio" / "generated_production" / "fighters" / fid


def shared_audio_dir() -> Path:
    return GODOT / "assets" / "audio" / "generated_production" / "shared"


def logical_ids(fid: str) -> dict:
    return {
        "fighter_mesh_id": f"{fid}.mesh",
        "fighter_material_id": f"{fid}.material",
        "fighter_skeleton_id": f"{fid}.skeleton",
        "fighter_animation_action_id": f"{fid}.action",
        "fighter_vfx_family_id": f"{fid}.vfx",
        "fighter_audio_family_id": f"{fid}.audio",
    }
