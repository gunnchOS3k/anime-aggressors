"""Shared authored-animation production constants. No final acting."""
from __future__ import annotations

import json
import os
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ANIM = ROOT / "art_source" / "animation"
GODOT_AUTHORED = ROOT / "game-godot" / "assets" / "characters" / "authored"
MOVES = ROOT / "game-godot" / "data" / "moves"

FIGHTERS = (
    ("ember-vale", "Ember Vale", "flame / rush", "aggression"),
    ("rook-ironside", "Rook Ironside", "impact / armor", "weight"),
    ("juno-spark", "Juno Spark", "volt / trick", "snap speed"),
    ("kaia-windrow", "Kaia Windrow", "gale / carry", "flow/air"),
    ("nix-calder", "Nix Calder", "frost / control", "precision"),
    ("orion-vell", "Orion Vell", "gravity / trap", "orbit/control"),
    ("vesper-nyx", "Vesper Nyx", "void / mix", "deception/phase"),
)
FIGHTER_IDS = tuple(f[0] for f in FIGHTERS)

PRODUCTION_ACTIONS = (
    ("idle", "idle", "Neutral loop. Identity readable in 8 frames."),
    ("walk", "walk", "Ground locomotion loop. No root translation."),
    ("run", "run", "Run loop. Distinct from walk."),
    ("dash", "dash", "Burst start + travel pose. Gameplay owns displacement."),
    ("jump", "jump", "Jump rise. Physics owns path."),
    ("light", "light", "Light attack."),
    ("medium", "medium", "Medium attack."),
    ("heavy", "heavy", "Heavy attack. Distinct silhouette vs aura/super."),
    ("aura", "aura", "High-commitment aura."),
    ("super", "super", "Super / finisher."),
    ("hurt_heavy", "hurt_heavy", "Readable victim. Pain before launch."),
    ("launch", "launch", "Launch / tumble start. Physics owns path."),
    ("charge", "charge", "Charge presence. Not idle + particles."),
    ("ko", "ko", "KO spin / collapse."),
)

ALLOWED_STATUS = (
    "CURRENT_ACCEPTED_ART",
    "HUMAN_CANDIDATE",
    "HUMAN_APPROVED",
    "GENERATED_EXPERIMENT",
    "PROCEDURAL_FALLBACK",
    "MISSING",
    "AUTHORED_APPROVED",
    "AUTHORED_WIP",
)
AUTOMATION_MAY_WRITE = (
    "CURRENT_ACCEPTED_ART",
    "HUMAN_CANDIDATE",
    "GENERATED_EXPERIMENT",
    "PROCEDURAL_FALLBACK",
    "MISSING",
    "AUTHORED_WIP",
)
CANONICAL_BONES = (
    "Root", "Hips", "Spine", "Chest", "Neck", "Head",
    "Shoulder_L", "UpperArm_L", "LowerArm_L", "Hand_L",
    "Shoulder_R", "UpperArm_R", "LowerArm_R", "Hand_R",
    "UpperLeg_L", "LowerLeg_L", "Foot_L", "Toes_L",
    "UpperLeg_R", "LowerLeg_R", "Foot_R", "Toes_R",
)
GOLDEN_SLICE = (
    ("rook-ironside", "idle"),
    ("rook-ironside", "walk"),
    ("rook-ironside", "charged_idle"),
    ("rook-ironside", "heavy"),
    ("nix-calder", "hurt_heavy"),
)
ANIMATION_PRODUCTION_BLENDER_VERSION = "3.3.1"


def fighter_dir(fid: str) -> Path:
    return ANIM / "fighters" / fid


def master_blend(fid: str) -> Path:
    return fighter_dir(fid) / "source" / f"{fid}_animation_master.blend"


def find_blender() -> str | None:
    env = os.environ.get("BLENDER_BIN")
    candidates = (
        env,
        shutil.which("blender"),
        "/Applications/Blender.app/Contents/MacOS/Blender",
    )
    for c in candidates:
        if c and Path(c).is_file():
            return c
    return None


def load_json(path: Path) -> dict:
    if not path.is_file():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
