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

# Prompt 1 production Wave A — 14 × 7 = 98. Defined, not authored.
PRODUCTION_ACTIONS = (
    ("idle", "idle", "Neutral loop. Identity readable in 8 frames."),
    ("personality_idle", "personality_idle", "Character beat. Not a second generic idle."),
    ("walk", "walk", "Ground locomotion loop. No root translation."),
    ("run", "run", "Run loop. Distinct from walk."),
    ("dash", "dash", "Burst start + travel pose. Gameplay owns displacement."),
    ("charged_idle", "charged_idle", "Charge 100 presence. Not idle + particles."),
    ("charge_start", "charge_start", "Charge begin. Volume change starts here."),
    ("charge_full", "charge_full", "Charge complete hold."),
    ("heavy", "heavy", "Heavy attack. Distinct silhouette vs aura/super."),
    ("hurt_heavy", "hurt_heavy", "Readable victim. Pain before launch."),
    ("launch_tumble", "launch", "Launch / tumble start. Physics owns path."),
    ("aura_signature", "signature_lane_burst", "High-commitment aura. Clash-eligible."),
    ("ko_reaction", "ko", "KO spin / collapse. Cinematic class KO."),
    ("aura_burst_super_pose", "signature_lane_finisher", "Super / finisher. Clash-eligible."),
)

# First-pass runtime aliases (kept so existing ACTION.json folders stay valid).
FIRST_PASS_ACTIONS = (
    ("idle", "idle"),
    ("walk", "walk"),
    ("run", "run"),
    ("dash", "dash"),
    ("jump", "jump"),
    ("light", "jab"),
    ("medium", "tilt_forward"),
    ("heavy", "heavy"),
    ("aura", "signature_lane_burst"),
    ("super", "signature_lane_finisher"),
    ("hurt_heavy", "hurt_heavy"),
    ("launch", "launch"),
    ("charge", "charge_full"),
    ("ko", "ko"),
)

ALLOWED_STATUS = ("AUTHORED_APPROVED", "AUTHORED_WIP", "PROCEDURAL_FALLBACK", "MISSING")
AUTOMATION_MAY_WRITE = ("AUTHORED_WIP", "PROCEDURAL_FALLBACK", "MISSING")
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
        str(Path.home() / "Applications" / "Blender.app" / "Contents" / "MacOS" / "Blender"),
    )
    for c in candidates:
        if c and Path(c).is_file():
            return c
    return None


def load_json(path: Path) -> dict:
    if not path.is_file():
        return {}
    return json.loads(path.read_text())


def write_json(path: Path, payload) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n")


def move_for(fid: str, move_id: str) -> dict:
    data = load_json(MOVES / f"{fid}.json")
    for move in data.get("moves", []):
        if str(move.get("move_id")) == move_id:
            return move
    return {}


def frame_window(fid: str, action: str) -> dict:
    """Gameplay-authored frame ranges. Do not invent missing combat data."""
    mapping = {
        "heavy": "heavy_attack",
        "aura_signature": "aura_burst",
        "aura_burst_super_pose": "aura_burst",
        "charge_start": "aura_charge",
        "charge_full": "aura_charge",
        "charged_idle": "aura_charge",
    }
    move = move_for(fid, mapping.get(action, action))
    startup = int(move.get("startup_frames", 0) or 0)
    active = int(move.get("active_frames", 0) or 0)
    recovery = int(move.get("recovery_frames", 0) or 0)
    choreo = move.get("choreography", {}) if move else {}
    contact = int(choreo.get("contact_frame", 0) or 0)
    if action in ("idle", "personality_idle", "walk", "run", "charged_idle"):
        return {
            "frame_start": 1,
            "frame_end": 48,
            "contact_frame": 0,
            "active_start": 0,
            "active_end": 0,
            "source_move": None,
            "loop": True,
        }
    if action == "hurt_heavy":
        # Reaction presentation only. Knockback stays CombatMath.
        return {
            "frame_start": 1,
            "frame_end": 24,
            "contact_frame": 1,
            "active_start": 1,
            "active_end": 8,
            "source_move": "reaction:hurt_heavy",
            "loop": False,
            "gameplay_authoritative": False,
        }
    if not move:
        return {
            "frame_start": 1,
            "frame_end": 24,
            "contact_frame": 0,
            "active_start": 0,
            "active_end": 0,
            "source_move": None,
            "loop": False,
        }
    start = 1
    active_start = startup + 1
    active_end = startup + active
    end = max(startup + active + recovery, contact, 8)
    return {
        "frame_start": start,
        "frame_end": end,
        "contact_frame": contact or active_start,
        "active_start": active_start,
        "active_end": active_end,
        "source_move": str(move.get("move_id")),
        "startup_frames": startup,
        "active_frames": active,
        "recovery_frames": recovery,
        "hitstop_frames": int((move.get("feedback") or {}).get("hitstop_frames", 0) or 0),
        "contact_socket": str(choreo.get("contact_socket", "")),
        "loop": False,
        "root_motion_authoritative": False,
    }


def empty_provenance(fid: str, action: str, extra: dict | None = None) -> dict:
    win = frame_window(fid, action)
    row = {
        "fighter": fid,
        "action": action,
        "source_blend": str(master_blend(fid).relative_to(ROOT)),
        "source_blend_version": ANIMATION_PRODUCTION_BLENDER_VERSION,
        "exported_glb": "",
        "animator": "",
        "status": "MISSING",
        "pose_bible_approved": False,
        "human_animation_approved": False,
        "contact_frame": win.get("contact_frame", 0),
        "active_start": win.get("active_start", 0),
        "active_end": win.get("active_end", 0),
        "notes": "Empty WIP slot. Not authored animation.",
        "not_final_art": True,
        "automation_may_not_set": ["AUTHORED_APPROVED"],
    }
    if extra:
        row.update(extra)
    return row
