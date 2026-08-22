#!/usr/bin/env python3
"""Generate Wave013B notes-driven choreography + user motion upload pipeline content."""
from __future__ import annotations

import hashlib
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
NOW = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

WAVE012_ACCEPTED_MAIN_SHA = "923976103f50d20aad196f49f8cd62cffb9e87e8"
WAVE012_PR82_HEAD_SHA = "5277829032c45281b8e8a567740cd05820eadeda"
ANIME_WAVE013B_START_SHA = subprocess.check_output(
    ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True
).strip()

FIGHTERS = [
    {
        "id": "ember-vale",
        "name": "Ember Vale",
        "lane": "fire/heat/combustion",
        "aura": "overwhelms",
        "palette": ["#E8453C", "#F28C28", "#1A0A08", "#FFD27A"],
        "silhouette": "forward-leaning sprinter, asymmetric ember gauntlets, flame-tail hair volume",
        "motion_grammar": "acceleration bursts, forward lean, heat-trail follow-through",
    },
    {
        "id": "rook-ironside",
        "name": "Rook Ironside",
        "lane": "impact/strength/earth/quake/armor",
        "aura": "armors through",
        "palette": ["#6B5B4B", "#C4A574", "#2B2B2B", "#8A7A6A"],
        "silhouette": "wide basalt stance, riveted pauldrons, low center of gravity",
        "motion_grammar": "ground-coupled weight, planted pivots, delayed follow-through",
    },
    {
        "id": "juno-spark",
        "name": "Juno Spark",
        "lane": "electricity/lightning/speed/magnetism",
        "aura": "confirms",
        "palette": ["#F5D042", "#3D5AFE", "#0D1B2A", "#7EF9FF"],
        "silhouette": "compact core, capacitor spines, trailing volt scarf",
        "motion_grammar": "snap confirms, afterimage trails, tight recovery windows",
    },
    {
        "id": "kaia-windrow",
        "name": "Kaia Windrow",
        "lane": "wind/air/storm/flight/pressure",
        "aura": "controls air",
        "palette": ["#3CB371", "#A8E6CF", "#1B4332", "#E9F5DB"],
        "silhouette": "upward lines, ribbon glider pack, cross-body gale sash",
        "motion_grammar": "floating arcs, ribbon lag, pressure-wave releases",
    },
    {
        "id": "nix-calder",
        "name": "Nix Calder",
        "lane": "ice/frost/snow/freezing/control",
        "aura": "locks space",
        "palette": ["#4A90D9", "#D6EAF8", "#1B263B", "#A0C4FF"],
        "silhouette": "tall narrow profile, frost mantle, paired shoulder crystals",
        "motion_grammar": "held poses, crystalline stops, space-denial extensions",
    },
    {
        "id": "orion-vell",
        "name": "Orion Vell",
        "lane": "gravity/weight/vectors/attraction/repulsion",
        "aura": "manipulates launch",
        "palette": ["#5B4B8A", "#C9B6E4", "#12081F", "#8E7CC3"],
        "silhouette": "offset gravity rings, suspended orbit nodes, weighted boots",
        "motion_grammar": "vector remaps, orbit pivots, launch-vector handoffs",
    },
    {
        "id": "vesper-nyx",
        "name": "Vesper Nyx",
        "lane": "void/darkness/shadow/phase/intangibility",
        "aura": "misdirects",
        "palette": ["#9B59B6", "#2D132C", "#E0AAFF", "#0B090D"],
        "silhouette": "deep hood, segmented void cape, narrow phase outline",
        "motion_grammar": "phase cancels, presence drops, misdirection feints",
    },
]

BASE_ACTIONS = [
    ("idle", "movement", "neutral loop"),
    ("walk", "movement", "slow locomotion"),
    ("run", "movement", "committed dash approach"),
    ("dash", "movement", "burst lateral movement"),
    ("jump", "movement", "ascent launch"),
    ("fall", "movement", "air descent"),
    ("landing", "movement", "ground contact settle"),
    ("air_drift", "movement", "aerial control drift"),
    ("jab", "melee", "fast neutral starter"),
    ("jab_chain_2", "melee", "second chain link"),
    ("jab_chain_3", "melee", "finisher link"),
    ("tilt_forward", "melee", "forward tilt attack"),
    ("tilt_up", "melee", "anti-air tilt"),
    ("tilt_down", "melee", "low sweep tilt"),
    ("smash_forward", "melee", "charged forward smash"),
    ("smash_up", "melee", "charged upward smash"),
    ("smash_down", "melee", "charged downward smash"),
    ("aerial_neutral", "melee", "neutral aerial"),
    ("aerial_forward", "melee", "forward aerial"),
    ("aerial_back", "melee", "back aerial"),
    ("aerial_up", "melee", "up aerial"),
    ("aerial_down", "melee", "down aerial"),
    ("heavy", "melee", "slow power strike"),
    ("projectile_tap", "special", "quick projectile"),
    ("projectile_medium", "special", "medium charge projectile"),
    ("projectile_full", "special", "full charge projectile"),
    ("aura_charge", "special", "aura buildup"),
    ("aura_release", "special", "aura payoff"),
    ("shield", "defense", "shield hold"),
    ("dodge", "defense", "ground dodge"),
    ("air_dodge", "defense", "aerial dodge"),
    ("recovery", "defense", "recovery move"),
    ("grab", "grab", "command grab attempt"),
    ("throw_forward", "grab", "forward throw"),
    ("throw_back", "grab", "back throw"),
    ("throw_up", "grab", "up throw"),
    ("throw_down", "grab", "down throw"),
    ("hurt", "reaction", "hit reaction"),
    ("launch", "reaction", "launch reaction"),
    ("tumble", "reaction", "tumble loop"),
    ("ko", "reaction", "stock KO"),
    ("victory", "presentation", "victory pose"),
    ("defeat", "presentation", "defeat pose"),
]

SIGNATURE_SUFFIXES = [
    "lane_burst",
    "lane_control",
    "lane_confirm",
    "lane_trap",
    "lane_launch",
    "lane_feint",
    "lane_counter",
    "lane_finisher",
]

PROTOTYPE_ACTIONS = [
    "idle",
    "run",
    "jump",
    "jab",
    "tilt_forward",
    "smash_forward",
    "aerial_neutral",
    "projectile_tap",
    "aura_charge",
    "shield",
    "dodge",
    "grab",
    "ko",
]


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def write_json(path: Path, data: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, sort_keys=False) + "\n", encoding="utf-8")


def action_spec_schema() -> dict:
    return {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "$id": "anime-aggressors/action_spec.schema.json",
        "title": "Notes-Driven Action Spec",
        "type": "object",
        "required": [
            "schema_version",
            "action_id",
            "fighter_id",
            "display_name",
            "category",
            "lane",
            "notes_driven",
            "inspiration_notes",
            "original_move_name",
            "originality",
            "timing",
            "motion_grammar",
            "camera",
            "impact",
            "vfx_cue",
            "sfx_cue",
            "hitbox",
            "accessibility",
            "production_status",
            "animation_source_priority",
            "reference_animatic",
            "provenance",
        ],
        "properties": {
            "schema_version": {"type": "integer", "const": 1},
            "action_id": {"type": "string"},
            "fighter_id": {"type": "string"},
            "display_name": {"type": "string"},
            "category": {"type": "string"},
            "lane": {"type": "string"},
            "notes_driven": {"type": "boolean"},
            "inspiration_notes": {
                "type": "object",
                "required": ["research_anchors", "iconic_moment_summary", "do_not_copy"],
                "properties": {
                    "research_anchors": {"type": "array", "items": {"type": "string"}},
                    "iconic_moment_summary": {"type": "string"},
                    "motion_principle": {"type": "string"},
                    "power_principle": {"type": "string"},
                    "do_not_copy": {"type": "array", "items": {"type": "string"}},
                },
            },
            "original_move_name": {"type": "string"},
            "originality": {
                "type": "object",
                "required": ["direct_1_to_1_reference_moves", "franchise_assets_in_production"],
                "properties": {
                    "direct_1_to_1_reference_moves": {"type": "integer", "const": 0},
                    "franchise_assets_in_production": {"type": "integer", "const": 0},
                    "composite_synthesis": {"type": "string"},
                    "originality_review_status": {"type": "string"},
                },
            },
            "timing": {
                "type": "object",
                "required": ["anticipation_frames", "active_frames", "recovery_frames", "total_frames"],
                "properties": {
                    "anticipation_frames": {"type": "integer"},
                    "active_frames": {"type": "integer"},
                    "recovery_frames": {"type": "integer"},
                    "total_frames": {"type": "integer"},
                    "cancel_windows": {"type": "array", "items": {"type": "string"}},
                },
            },
            "motion_grammar": {
                "type": "object",
                "properties": {
                    "weight": {"type": "string"},
                    "tempo": {"type": "string"},
                    "arc_type": {"type": "string"},
                    "contact_points": {"type": "array", "items": {"type": "string"}},
                    "silhouette_poses": {"type": "array", "items": {"type": "string"}},
                    "fighter_motion_grammar": {"type": "string"},
                },
            },
            "camera": {
                "type": "object",
                "properties": {
                    "framing": {"type": "string"},
                    "push_in": {"type": "boolean"},
                    "shake_tier": {"type": "string"},
                },
            },
            "impact": {
                "type": "object",
                "properties": {
                    "hitstop_tier": {"type": "string"},
                    "lane_flash": {"type": "boolean"},
                    "risk_reward": {"type": "string"},
                },
            },
            "vfx_cue": {"type": "string"},
            "sfx_cue": {"type": "string"},
            "hitbox": {
                "type": "object",
                "properties": {
                    "window_start_frame": {"type": "integer"},
                    "window_end_frame": {"type": "integer"},
                    "notes": {"type": "string"},
                },
            },
            "accessibility": {
                "type": "object",
                "properties": {
                    "reduce_flash": {"type": "boolean"},
                    "reduce_shake": {"type": "boolean"},
                },
            },
            "production_status": {"type": "string"},
            "animation_source_priority": {
                "type": "array",
                "items": {"type": "string"},
            },
            "reference_animatic": {
                "type": "object",
                "properties": {
                    "kind": {"type": "string", "enum": ["PROTOTYPE_ANIMATION", "REFERENCE_ANIMATIC", "NONE"]},
                    "path": {"type": ["string", "null"]},
                },
            },
            "provenance": {
                "type": "object",
                "properties": {
                    "source_class": {"type": "string"},
                    "real_user_motion": {"type": "boolean", "const": False},
                    "edmund_personal_motion": {"type": "boolean", "const": False},
                },
            },
        },
        "additionalProperties": False,
    }


def build_action_spec(fighter: dict, action_key: str, category: str, summary: str, idx: int) -> dict:
    fid = fighter["id"]
    lane = fighter["lane"]
    original = f"{fighter['name'].split()[0]} {summary.title()} {idx:02d}"
    proto_kind = "REFERENCE_ANIMATIC" if action_key in PROTOTYPE_ACTIONS else "NONE"
    proto_path = (
        f"tools/motion_pipeline/reference_animation/{fid}/{action_key}.json"
        if proto_kind != "NONE"
        else None
    )
    return {
        "schema_version": 1,
        "action_id": f"{fid}.{action_key}",
        "fighter_id": fid,
        "display_name": original,
        "category": category,
        "lane": lane,
        "notes_driven": True,
        "inspiration_notes": {
            "research_anchors": [
                "genre platform-fighter grammar",
                f"{fighter['lane']} lane studies",
                "ICONIC_MOMENT_TO_ORIGINAL_MOVE_MATRIX",
            ],
            "iconic_moment_summary": f"Notes-driven synthesis for {summary} respecting {fighter['motion_grammar']}.",
            "motion_principle": "anticipation → committed contact → readable follow-through",
            "power_principle": f"aura {fighter['aura']} scaling on payoff frames",
            "do_not_copy": [
                "franchise costumes",
                "named techniques",
                "1:1 choreography",
                "licensed SFX/VFX glyphs",
            ],
        },
        "original_move_name": original,
        "originality": {
            "direct_1_to_1_reference_moves": 0,
            "franchise_assets_in_production": 0,
            "composite_synthesis": f"≥3-anchor composite for {fighter['name']} {action_key}",
            "originality_review_status": "NOTES_DRIVEN_PENDING_HUMAN_REVIEW",
        },
        "timing": {
            "anticipation_frames": 3 + (idx % 4),
            "active_frames": 4 + (idx % 6),
            "recovery_frames": 6 + (idx % 8),
            "total_frames": 16 + (idx % 12),
            "cancel_windows": ["dash", "shield"] if category in ("melee", "special") else [],
        },
        "motion_grammar": {
            "weight": "heavy" if "rook" in fid else "medium",
            "tempo": "fast" if "juno" in fid or action_key == "jab" else "moderate",
            "arc_type": "linear" if category == "movement" else "arc",
            "contact_points": ["hand_r"] if category in ("melee", "grab") else ["root"],
            "silhouette_poses": ["anticipation", "extremum", "recovery"],
            "fighter_motion_grammar": fighter["motion_grammar"],
        },
        "camera": {
            "framing": "medium" if category != "presentation" else "wide",
            "push_in": category in ("melee", "grab", "special"),
            "shake_tier": "heavy" if "smash" in action_key or action_key == "ko" else "light",
        },
        "impact": {
            "hitstop_tier": "aura" if "aura" in action_key else "medium",
            "lane_flash": True,
            "risk_reward": "high commitment on smash/heavy; low on jab/projectile_tap",
        },
        "vfx_cue": f"juice.{fid}.{action_key}.vfx",
        "sfx_cue": f"juice.{fid}.{action_key}.sfx",
        "hitbox": {
            "window_start_frame": 4,
            "window_end_frame": 8,
            "notes": "align to moves json at runtime integration",
        },
        "accessibility": {"reduce_flash": True, "reduce_shake": True},
        "production_status": "NOTES_SPEC_READY",
        "animation_source_priority": [
            "FINAL_ORIGINAL_HUMAN_PRODUCTION",
            "REFERENCE_ANIMATIC",
            "PROTOTYPE_ANIMATION",
            "PROCEDURAL_RUNTIME_PROXY",
        ],
        "reference_animatic": {"kind": proto_kind, "path": proto_path},
        "provenance": {
            "source_class": "NOTES_DRIVEN_SYNTHETIC_SPEC",
            "real_user_motion": False,
            "edmund_personal_motion": False,
        },
    }


def generate_action_specs() -> dict:
    index: dict = {"schema_version": 1, "wave": "wave013b", "fighters": {}, "total_specs": 0}
    for fighter in FIGHTERS:
        fid = fighter["id"]
        specs_dir = ROOT / "content/choreography" / fid
        specs_dir.mkdir(parents=True, exist_ok=True)
        ids: list[str] = []
        idx = 0
        for action_key, category, summary in BASE_ACTIONS:
            spec = build_action_spec(fighter, action_key, category, summary, idx)
            path = specs_dir / f"{action_key}.json"
            write_json(path, spec)
            ids.append(spec["action_id"])
            idx += 1
        for suffix in SIGNATURE_SUFFIXES:
            action_key = f"signature_{suffix}"
            spec = build_action_spec(fighter, action_key, "signature", f"signature {suffix.replace('_', ' ')}", idx)
            write_json(specs_dir / f"{action_key}.json", spec)
            ids.append(spec["action_id"])
            idx += 1
        index["fighters"][fid] = {"count": len(ids), "action_ids": ids}
        index["total_specs"] += len(ids)
    write_json(ROOT / "content/choreography/index.json", index)
    return index


def animation_event_timeline_schema() -> dict:
    return {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "$id": "anime-aggressors/animation_event_timeline.schema.json",
        "title": "Reference Animatic Event Timeline",
        "type": "object",
        "required": ["schema_version", "action_id", "fighter_id", "kind", "fps", "events"],
        "properties": {
            "schema_version": {"type": "integer", "const": 1},
            "action_id": {"type": "string"},
            "fighter_id": {"type": "string"},
            "kind": {"type": "string", "enum": ["PROTOTYPE_ANIMATION", "REFERENCE_ANIMATIC"]},
            "fps": {"type": "number", "const": 60.0},
            "duration_frames": {"type": "integer"},
            "events": {
                "type": "array",
                "items": {
                    "type": "object",
                    "required": ["frame", "event_type"],
                    "properties": {
                        "frame": {"type": "integer"},
                        "event_type": {"type": "string"},
                        "payload": {"type": "object"},
                    },
                },
            },
            "provenance": {
                "type": "object",
                "properties": {
                    "source_class": {"type": "string"},
                    "final_animation": {"type": "boolean", "const": False},
                },
            },
        },
    }


def motion_contribution_schema() -> dict:
    return {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "$id": "anime-aggressors/motion_contribution.schema.json",
        "title": "User Motion Contribution (future-ready)",
        "type": "object",
        "required": [
            "schema_version",
            "contribution_id",
            "contributor_pseudonym",
            "consent",
            "privacy",
            "upload",
            "validation",
            "provenance",
        ],
        "properties": {
            "schema_version": {"type": "integer", "const": 1},
            "contribution_id": {"type": "string"},
            "contributor_pseudonym": {"type": "string"},
            "consent": {
                "type": "object",
                "required": ["stages", "production_use_after_approval"],
                "properties": {
                    "stages": {
                        "type": "array",
                        "items": {"type": "string"},
                    },
                    "production_use_after_approval": {"type": "boolean"},
                    "biometric_inference_forbidden": {"type": "boolean", "const": True},
                },
            },
            "privacy": {
                "type": "object",
                "properties": {
                    "raw_upload_gitignored": {"type": "boolean", "const": True},
                    "metadata_stripped": {"type": "boolean"},
                    "local_only_dirs": {"type": "array", "items": {"type": "string"}},
                },
            },
            "upload": {
                "type": "object",
                "properties": {
                    "original_filename": {"type": "string"},
                    "content_hash_sha256": {"type": "string"},
                    "format": {"type": "string"},
                },
            },
            "validation": {
                "type": "object",
                "properties": {
                    "schema_valid": {"type": "boolean"},
                    "normalize_pass": {"type": "boolean"},
                    "retarget_pass": {"type": "boolean"},
                    "qa_pass": {"type": "boolean"},
                },
            },
            "provenance": {
                "type": "object",
                "properties": {
                    "real_user_motion": {"type": "boolean"},
                    "edmund_personal_motion": {"type": "boolean"},
                    "fixture_class": {"type": "string"},
                },
            },
        },
    }


def prototype_timeline(fighter: dict, action_key: str) -> dict:
    fid = fighter["id"]
    frames = 24 if action_key == "idle" else 32
    events = [
        {"frame": 0, "event_type": "anticipation_start", "payload": {"pose": "neutral"}},
        {"frame": 4, "event_type": "active_start", "payload": {"contact": action_key}},
        {"frame": 8, "event_type": "hitbox_on", "payload": {"socket": "hand_r"}},
        {"frame": 12, "event_type": "hitbox_off", "payload": {}},
        {"frame": frames - 4, "event_type": "recovery_start", "payload": {}},
        {"frame": frames, "event_type": "loop_end", "payload": {}},
    ]
    return {
        "schema_version": 1,
        "action_id": f"{fid}.{action_key}",
        "fighter_id": fid,
        "kind": "REFERENCE_ANIMATIC",
        "fps": 60.0,
        "duration_frames": frames,
        "events": events,
        "provenance": {
            "source_class": "SYNTHETIC_PROTOTYPE",
            "final_animation": False,
        },
    }


def generate_prototypes() -> int:
    count = 0
    for fighter in FIGHTERS:
        out_dir = ROOT / "tools/motion_pipeline/reference_animation" / fighter["id"]
        out_dir.mkdir(parents=True, exist_ok=True)
        for action_key in PROTOTYPE_ACTIONS:
            write_json(out_dir / f"{action_key}.json", prototype_timeline(fighter, action_key))
            count += 1
    return count


def roster_visual_bible() -> str:
    lines = [
        "# Roster Visual Identity Bible",
        "",
        "Wave013B visual identity contracts for all seven fighters.",
        "Production art remains original; franchise assets in production = 0.",
        "",
    ]
    for f in FIGHTERS:
        lines += [
            f"## {f['name']}",
            "",
            f"- **Lane:** {f['lane']}",
            f"- **Aura grammar:** {f['aura']}",
            f"- **Silhouette:** {f['silhouette']}",
            f"- **Palette:** {', '.join(f['palette'])}",
            "- **Black-silhouette gate:** distinct at 64px thumb distance vs roster",
            "- **Costume language:** modular, export-friendly, no franchise logos",
            "- **VFX readability:** lane-colored accents only on sockets",
            "- **VRoid recipe:** see docs/art_pipeline/VRoid_FIGHTER_AUTHORING_PACKETS/",
            "",
        ]
    return "\n".join(lines)


def roster_motion_bible() -> str:
    lines = [
        "# Roster Motion Identity Bible",
        "",
        "Fighter-specific motion grammar for notes-driven choreography factory.",
        "NOTES_DRIVEN_CHOREOGRAPHY_ACTIVE=true",
        "",
    ]
    for f in FIGHTERS:
        lines += [
            f"## {f['name']}",
            "",
            f"- **Motion grammar:** {f['motion_grammar']}",
            f"- **Aura behavior:** {f['aura']}",
            "- **Weight/tempo:** lane-calibrated; see action specs in content/choreography/",
            "- **Anti-copy:** DIRECT_1_TO_1_REFERENCE_MOVES=0",
            "- **Prototype class:** REFERENCE_ANIMATIC / PROTOTYPE_ANIMATION only",
            "",
        ]
    return "\n".join(lines)


def expand_iconic_matrix() -> str:
    base = (ROOT / "docs/design/ICONIC_MOMENT_TO_ORIGINAL_MOVE_MATRIX.md").read_text(encoding="utf-8")
    extra = [
        "",
        "## Wave013B Additional Studies (notes-driven expansion)",
        "",
    ]
    extras = [
        ("ember-vale", "Shōnen dash-in grammar", "closing distance before strike", "Flare Step Rush"),
        ("rook-ironside", "Heavy armor tank walk", "unstoppable advance", "Basalt March"),
        ("juno-spark", "Static charge buildup", "visible confirm window", "Capacitor Prime"),
        ("kaia-windrow", "Updraft recovery", "air control reset", "Ribbon Updraft"),
        ("nix-calder", "Skating stop", "space lock on landing", "Rime Brake"),
        ("orion-vell", "Low-gravity float", "hang-time manipulation", "Orbit Hang"),
        ("vesper-nyx", "Shadow afterimage dodge", "misdirect recovery", "Umbral Echo Dodge"),
    ]
    for fid, ref, moment, original in extras:
        name = next(x["name"] for x in FIGHTERS if x["id"] == fid)
        extra += [
            f"### Study — {original}",
            f"- **Reference character/work (design only):** {ref}",
            f"- **Broad moment description:** {moment}",
            "- **Why memorable:** readable lane identity",
            f"- **Original Anime Aggressors concept:** `{original}` for {name}",
            "",
        ]
    return base + "\n".join(extra)


def motion_library_index(prototype_count: int, spec_index: dict) -> dict:
    entries = []
    for fighter in FIGHTERS:
        fid = fighter["id"]
        for action_key in PROTOTYPE_ACTIONS:
            entries.append(
                {
                    "id": f"{fid}.{action_key}",
                    "fighter_id": fid,
                    "kind": "REFERENCE_ANIMATIC",
                    "path": f"tools/motion_pipeline/reference_animation/{fid}/{action_key}.json",
                    "real_user_motion": False,
                    "final_animation": False,
                }
            )
    return {
        "schema_version": 1,
        "wave": "wave013b",
        "REAL_USER_MOTION_LIBRARY_PRESENT": False,
        "entries": entries,
        "prototype_count": prototype_count,
        "action_spec_count": spec_index["total_specs"],
    }


def motion_provenance() -> dict:
    return {
        "schema_version": 1,
        "wave": "wave013b",
        "REAL_USER_MOTION_LIBRARY_PRESENT": False,
        "EDMUND_PERSONAL_MOTION_REQUIRED": False,
        "DIRECT_1_TO_1_REFERENCE_MOVES": 0,
        "FRANCHISE_ASSETS_IN_PRODUCTION": 0,
        "entries": [
            {
                "id": "choreography.notes_driven_specs",
                "status": "NOTES_SPEC_READY",
                "path": "content/choreography/",
            },
            {
                "id": "reference_animatics.synthetic",
                "status": "PROTOTYPE_ANIMATION",
                "path": "tools/motion_pipeline/reference_animation/",
            },
            {
                "id": "user_upload.pipeline",
                "status": "PIPELINE_READY_NO_REAL_UPLOADS",
                "path": "tools/motion_pipeline/user_upload/",
            },
        ],
    }


def main() -> int:
    write_json(ROOT / "content/choreography/action_spec.schema.json", action_spec_schema())
    write_json(
        ROOT / "tools/motion_pipeline/schemas/animation_event_timeline.schema.json",
        animation_event_timeline_schema(),
    )
    write_json(
        ROOT / "tools/motion_pipeline/schemas/motion_contribution.schema.json",
        motion_contribution_schema(),
    )
    write(ROOT / "docs/design/ROSTER_VISUAL_IDENTITY_BIBLE.md", roster_visual_bible())
    write(ROOT / "docs/design/ROSTER_MOTION_IDENTITY_BIBLE.md", roster_motion_bible())
    write(ROOT / "docs/design/ICONIC_MOMENT_TO_ORIGINAL_MOVE_MATRIX.md", expand_iconic_matrix())

    spec_index = generate_action_specs()
    proto_count = generate_prototypes()
    write_json(ROOT / "content/motion_library/index.json", motion_library_index(proto_count, spec_index))
    write_json(ROOT / "content/motion_provenance.json", motion_provenance())

    write_json(
        ROOT / "vendor_pins/WAVE013B_TOOL_PINS.json",
        {
            "schema_version": 1,
            "generated_for": "engineering_wave013b",
            "CORE_PIPELINE_MONETARY_COST_USD": 0,
            "prerequisites": {
                "ANIME_WAVE013B_START_SHA": ANIME_WAVE013B_START_SHA,
                "WAVE012_ACCEPTED_MAIN_SHA": WAVE012_ACCEPTED_MAIN_SHA,
                "WAVE012_PR82_HEAD_SHA": WAVE012_PR82_HEAD_SHA,
                "ANIME_PR_82": "MERGED",
            },
            "flags": {
                "NOTES_DRIVEN_CHOREOGRAPHY_ACTIVE": True,
                "USER_MOTION_UPLOAD_PIPELINE_READY": True,
                "REAL_USER_MOTION_LIBRARY_PRESENT": False,
                "EDMUND_PERSONAL_MOTION_REQUIRED": False,
                "VROID_SOURCE_MODELS_PRESENT": 0,
            },
        },
    )

    print(f"Wave013B content generated {NOW}")
    print(f"action_specs={spec_index['total_specs']} prototypes={proto_count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
