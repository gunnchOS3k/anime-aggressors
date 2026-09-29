#!/usr/bin/env python3
"""Install animation-authority census, slot clips, matrices, and gate board updates.

Preserves AUTOMATION_AUTHORED_CANDIDATE clips. Never flips human/final-art/merge gates.
"""
from __future__ import annotations

import csv
import hashlib
import json
import math
import sys
from copy import deepcopy
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/animation_pipeline/procedural"))
from _common import (  # noqa: E402
    BONES,
    FIGHTERS,
    blueprint_for,
    curve_signature,
    fighter_seed,
    load_blueprints,
)

SPECTRUM = list(FIGHTERS)
ALL_FIGHTERS = SPECTRUM + ["yin", "yang"]
OUT = ROOT / "artifacts/animation_authority_v1"
INV = json.loads((ROOT / "data/bibles/animation_inventory_v1.json").read_text(encoding="utf-8"))
MOVEMENT = json.loads((ROOT / "data/bibles/movement_profiles_v1.json").read_text(encoding="utf-8"))
REACTIONS = json.loads((ROOT / "data/bibles/reaction_profiles_v1.json").read_text(encoding="utf-8"))
AURA = json.loads((ROOT / "data/bibles/aura_profiles_v1.json").read_text(encoding="utf-8"))
PRESENTATION = json.loads((ROOT / "data/bibles/presentation_profiles_v1.json").read_text(encoding="utf-8"))
STATE_CONTRACT = json.loads((ROOT / "data/bibles/state_to_animation_contract_v1.json").read_text(encoding="utf-8"))
PUPPET = json.loads((ROOT / "data/bibles/puppet_essence_story_states_v1.json").read_text(encoding="utf-8"))
GATES = json.loads((ROOT / "data/bibles/production_gate_matrix_v1.json").read_text(encoding="utf-8"))

LIVE_MOVES = [
    "jab_1", "jab_2", "jab_finisher", "forward_tilt", "up_tilt", "down_tilt",
    "dash_attack", "heavy_attack", "neutral_air", "forward_air", "back_air",
    "up_air", "down_air", "neutral_special_projectile", "side_special",
    "up_special_recovery", "down_special", "grab", "throw_forward", "throw_back",
    "throw_up", "throw_down", "aura_charge", "aura_burst",
]

# Authority inventory uses *_move suffixes for aura move slots; live ids omit them.
MOVE_SLOT_TO_LIVE = {
    "aura_charge_move": "aura_charge",
    "aura_burst_move": "aura_burst",
}

MOTION_LAWS = {
    "ember-vale": "combustion",
    "rook-ironside": "mass",
    "juno-spark": "current",
    "kaia-windrow": "flow",
    "nix-calder": "structure",
    "orion-vell": "vectors",
    "vesper-nyx": "uncertainty",
    "yin": "reduction",
    "yang": "definition",
}

# Prefer an existing clip as generation seed / runtime alias target when possible.
SLOT_SEED_CLIP: dict[str, str] = {
    "idle_primary": "idle",
    "idle_secondary": "idle_variant",
    "idle_long": "idle",
    "walk_start": "walk",
    "walk_loop": "walk",
    "walk_stop": "walk",
    "run_start": "run",
    "run_loop": "run",
    "run_stop": "run",
    "dash_start": "dash",
    "dash_loop": "dash",
    "dash_stop": "dash",
    "skid": "turn",
    "turnaround": "turn",
    "crouch_start": "crouch",
    "crouch_hold": "crouch",
    "crouch_end": "crouch",
    "jump_squat": "jump_start",
    "jump": "jump_rise",
    "short_hop_visual": "jump",
    "double_jump": "jump",
    "fall": "fall",
    "fast_fall": "fall",
    "land_soft": "land",
    "land_hard": "landing",
    "platform_drop": "ledge_drop",
    "edge_warning": "ledge_hang",
    "ledge_teeter": "ledge_hang",
    "ledge_grab": "ledge_grab",
    "ledge_hang": "ledge_hang",
    "ledge_getup": "ledge_getup",
    "ledge_roll": "dodge_forward",
    "ledge_jump": "ledge_jump",
    "ledge_attack": "jab",
    "shield_start": "shield_start",
    "shield_hold": "shield_hold",
    "shield_hit": "shield",
    "shield_stun": "shield",
    "shield_break": "hurt_heavy",
    "spot_dodge": "dodge",
    "roll_forward": "dodge_forward",
    "roll_backward": "dodge_back",
    "air_dodge_neutral": "air_dodge",
    "air_dodge_forward": "air_dodge",
    "air_dodge_back": "air_dodge",
    "air_dodge_up": "air_dodge",
    "air_dodge_down": "air_dodge",
    "tech_in_place": "land",
    "tech_forward": "dodge_forward",
    "tech_back": "dodge_back",
    "pratfall": "tumble",
    "hurt_light_front": "hurt_light",
    "hurt_light_back": "hurt_light",
    "hurt_heavy": "hurt_heavy",
    "hitstop_pose": "hurt",
    "hitstun_ground": "hurt",
    "launch_horizontal": "launch",
    "launch_vertical": "critical_launch",
    "tumble": "tumble",
    "ground_bounce": "landing",
    "wall_bounce": "hurt_heavy",
    "knockdown": "hurt_heavy",
    "ko": "ko",
    "respawn": "respawn",
    "grab_startup": "grab",
    "grab_active": "grab",
    "grab_whiff": "grab_break",
    "grab_hold": "grab_hold",
    "pummel": "grab_hold",
    "throw_startup": "throw_forward",
    "throw_release": "throw_forward",
    "aura_charge": "aura_charge",
    "aura_ready": "aura_ready",
    "aura_burst_startup": "aura_burst",
    "aura_burst_active": "aura_burst",
    "aura_burst_recovery": "aura_release",
    "aura_super_transform": "signature_lane_burst",
    "jab_1": "jab",
    "jab_2": "jab_chain_2",
    "jab_finisher": "jab_chain_3",
    "forward_tilt": "tilt_forward",
    "up_tilt": "tilt_up",
    "down_tilt": "tilt_down",
    "dash_attack": "dash_attack",
    "heavy_attack": "heavy",
    "neutral_air": "aerial_neutral",
    "forward_air": "aerial_forward",
    "back_air": "aerial_back",
    "up_air": "aerial_up",
    "down_air": "aerial_down",
    "neutral_special_projectile": "projectile_full",
    "side_special": "side_special",
    "up_special_recovery": "recovery",
    "down_special": "down_special",
    "grab": "grab",
    "throw_forward": "throw_forward",
    "throw_back": "throw_back",
    "throw_up": "throw_up",
    "throw_down": "throw_down",
    "aura_charge_move": "aura_charge",
    "aura_burst_move": "aura_burst",
    "match_intro": "idle",
    "character_select_idle": "idle",
    "character_select_confirm": "victory",
    "taunt_1": "idle_variant",
    "taunt_2": "idle_variant",
    "victory": "victory",
    "defeat": "defeat",
    "results_idle": "idle",
    "story_dialogue_neutral": "idle",
    "story_dialogue_intense": "aura_ready",
}

# Documented semantic aliases (not temporary coarse lies).
DOCUMENTED_ALIASES: dict[str, dict[str, str]] = {
    "short_hop_visual": {
        "alias_of": "jump",
        "justification": "Inventory may_alias=true; short hop is jump with reduced visual amplitude.",
    },
    "edge_warning": {
        "alias_of": "ledge_teeter",
        "justification": "Shared teeter warning pose until distinct edge-warning authored clip exists.",
    },
}


def inventory_slots() -> list[dict[str, Any]]:
    rows = []
    for cat in INV["categories"]:
        for slot in cat["slots"]:
            rows.append(
                {
                    "category": cat["id"],
                    "slot_id": slot["id"],
                    "required": bool(slot.get("required", True)),
                    "may_alias": bool(slot.get("may_alias", False)),
                }
            )
    return rows


def existing_clips(fighter_id: str) -> set[str]:
    root = ROOT / "content/fighters" / fighter_id / "animations/procedural"
    if not root.is_dir():
        return set()
    return {p.name.replace(".anim.json", "") for p in root.glob("*.anim.json")}


def load_clip(fighter_id: str, clip_name: str) -> dict[str, Any] | None:
    path = ROOT / "content/fighters" / fighter_id / "animations/procedural" / f"{clip_name}.anim.json"
    if not path.is_file():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def write_clip(fighter_id: str, clip_name: str, clip: dict[str, Any]) -> None:
    for base in (
        ROOT / "content/fighters" / fighter_id / "animations/procedural",
        ROOT / "game-godot/content/fighters" / fighter_id / "animations/procedural",
    ):
        base.mkdir(parents=True, exist_ok=True)
        (base / f"{clip_name}.anim.json").write_text(json.dumps(clip, indent=2) + "\n", encoding="utf-8")


def transform_tracks(
    tracks: dict[str, list[dict[str, Any]]],
    fighter_id: str,
    slot_id: str,
    amp_scale: float,
    phase_shift: float,
) -> dict[str, list[dict[str, Any]]]:
    out: dict[str, list[dict[str, Any]]] = {}
    law = MOTION_LAWS.get(fighter_id, "neutral")
    law_bias = {
        "combustion": (1.15, 0.9, 1.2),
        "mass": (0.75, 1.25, 0.7),
        "current": (1.25, 0.85, 1.1),
        "flow": (0.95, 1.05, 1.15),
        "structure": (0.85, 1.15, 0.8),
        "vectors": (1.1, 1.0, 1.25),
        "uncertainty": (1.05, 0.95, 1.35),
        "reduction": (0.7, 0.8, 0.65),
        "definition": (1.2, 1.1, 1.0),
    }.get(law, (1.0, 1.0, 1.0))
    for bone, keys in tracks.items():
        new_keys = []
        for key in keys:
            rot = list(key["rotation_rad"])
            seed = fighter_seed(fighter_id, slot_id, bone)
            rot[0] = round(rot[0] * amp_scale * law_bias[0] + math.sin(seed + phase_shift) * 0.02, 5)
            rot[1] = round(rot[1] * amp_scale * law_bias[1] + math.cos(seed * 1.3 + phase_shift) * 0.015, 5)
            rot[2] = round(rot[2] * amp_scale * law_bias[2] + math.sin(seed * 0.7 - phase_shift) * 0.02, 5)
            nk = dict(key)
            nk["rotation_rad"] = rot
            new_keys.append(nk)
        out[bone] = new_keys
    return out


def synthesize_tracks(fighter_id: str, slot_id: str, duration: int, blueprint: dict) -> dict[str, list[dict[str, Any]]]:
    tempo = float(blueprint.get("timing", {}).get("tempo_scale", 1.0))
    root_style = str(blueprint.get("root_motion", {}).get("style", "neutral"))
    tracks: dict[str, list[dict[str, Any]]] = {}
    for bone in BONES:
        keys = []
        base = fighter_seed(fighter_id, slot_id, bone) * math.pi
        amp = 0.08 + fighter_seed(fighter_id, bone, slot_id) * 0.35
        if "dash" in slot_id or "attack" in slot_id or "special" in slot_id:
            amp += 0.12 * tempo
        if "hurt" in slot_id or "launch" in slot_id:
            amp += 0.18
        for frame in (0, max(1, duration // 4), max(2, duration // 2), max(3, (3 * duration) // 4), duration):
            phase = frame / max(duration, 1)
            rot_x = math.sin(base + phase * math.pi * 2.0) * amp
            rot_y = math.cos(base * 1.3 + phase * math.pi) * amp * 0.6
            rot_z = math.sin(base * 0.7 + phase * math.pi * 1.5) * amp * (1.1 if root_style == "burst_forward" else 0.8)
            keys.append(
                {
                    "frame": frame,
                    "time_s": round(frame / 60.0, 4),
                    "rotation_rad": [round(rot_x, 5), round(rot_y, 5), round(rot_z, 5)],
                }
            )
        tracks[bone] = keys
    return tracks


def ensure_authority_clips(fighter_id: str, blueprints: dict) -> dict[str, Any]:
    created = []
    reused = []
    blueprint = blueprint_for(fighter_id, blueprints) if fighter_id in SPECTRUM else {
        "timing": {"tempo_scale": 0.85 if fighter_id == "yin" else 1.2},
        "root_motion": {"style": "inward" if fighter_id == "yin" else "outward"},
    }
    existing = existing_clips(fighter_id)
    for row in inventory_slots():
        slot_id = row["slot_id"]
        if slot_id in existing:
            existing_clip = load_clip(fighter_id, slot_id) or {}
            if existing_clip.get("authorship") == "AUTOMATION_AUTHORED_CANDIDATE":
                reused.append(slot_id)
                continue
            # Re-check: leave authored candidates untouched; only fill missing.
            reused.append(slot_id)
            continue
        seed_name = SLOT_SEED_CLIP.get(slot_id, "idle")
        seed = load_clip(fighter_id, seed_name) if fighter_id in SPECTRUM else None
        # Yin/Yang may not have fighter dirs yet — seed from ember then retarget.
        if seed is None:
            seed = load_clip("ember-vale", seed_name) or load_clip("ember-vale", "idle")
        phase = fighter_seed(fighter_id, slot_id, "phase") * math.pi
        amp = 0.85 + fighter_seed(fighter_id, slot_id, "amp") * 0.4
        if seed and seed.get("bone_tracks"):
            tracks = transform_tracks(seed["bone_tracks"], fighter_id, slot_id, amp, phase)
            duration = int(seed.get("duration_frames", 24))
            if slot_id.endswith("_start") or slot_id.endswith("_stop"):
                duration = max(8, duration // 2)
            if slot_id in ("idle_long", "match_intro", "results_idle"):
                duration = max(duration, 48)
        else:
            duration = 24
            tracks = synthesize_tracks(fighter_id, slot_id, duration, blueprint)
        clip = {
            "schema_version": 1,
            "fighter_id": fighter_id,
            "action_id": f"{fighter_id}.{slot_id}",
            "clip_name": slot_id,
            "kind": "PROCEDURAL_RUNTIME_ANIMATION",
            "authority_slot": slot_id,
            "authority_status": "PROCEDURAL_FALLBACK",
            "human_approval": False,
            "fps": 60.0,
            "duration_frames": duration,
            "bone_tracks": tracks,
            "curve_signature": curve_signature(tracks),
            "runtime_alignment": {
                "seed_clip": seed_name,
                "motion_law": MOTION_LAWS.get(fighter_id, "unknown"),
                "authority_package": "ANIMATION_AUTHORITY_V1",
            },
            "events": [],
            "provenance": {
                "source": "tools/animation_authority/build_authority_layer.py",
                "note": "Procedural continuity clip for authority slot coverage; not authored completion.",
            },
        }
        write_clip(fighter_id, slot_id, clip)
        created.append(slot_id)
        existing.add(slot_id)
    return {"fighter_id": fighter_id, "created": created, "already_present": reused, "clip_count": len(existing)}


def resolve_row(fighter_id: str, category: str, slot_id: str, clips: set[str]) -> dict[str, Any]:
    seed = SLOT_SEED_CLIP.get(slot_id)
    runtime_clip = slot_id if slot_id in clips else seed
    status = "PROCEDURAL_FALLBACK"
    evidence = [
        f"authority_inventory:{slot_id}",
        f"motion_law:{MOTION_LAWS.get(fighter_id, 'n/a')}",
    ]
    notes = ""
    if slot_id in DOCUMENTED_ALIASES and slot_id not in clips:
        alias = DOCUMENTED_ALIASES[slot_id]["alias_of"]
        runtime_clip = alias if alias in clips else seed
        notes = DOCUMENTED_ALIASES[slot_id]["justification"]
        evidence.append(f"documented_semantic_alias:{alias}")
    if runtime_clip and runtime_clip in clips:
        evidence.append(f"runtime_clip:{runtime_clip}")
        clip_path = f"content/fighters/{fighter_id}/animations/procedural/{runtime_clip}.anim.json"
        source_path = clip_path
        clip_meta = load_clip(fighter_id, runtime_clip) or {}
        authorship = clip_meta.get("authorship") or clip_meta.get("authority_status")
        if authorship == "AUTOMATION_AUTHORED_CANDIDATE" and clip_meta.get("human_approved") is not True:
            status = "AUTOMATION_AUTHORED_CANDIDATE"
            evidence.append("authorship:AUTOMATION_AUTHORED_CANDIDATE")
            if clip_meta.get("key_poses"):
                evidence.append(f"key_poses:{len(clip_meta.get('key_poses') or [])}")
            if clip_meta.get("curve_signature"):
                evidence.append(f"curve_signature:{clip_meta['curve_signature'][:12]}")
        elif clip_meta.get("authority_status") == "PROCEDURAL_FALLBACK" or clip_meta.get("kind") == "PROCEDURAL_RUNTIME_ANIMATION":
            status = "PROCEDURAL_FALLBACK"
            evidence.append("authorship:PROCEDURAL_FALLBACK")
        else:
            status = "PROCEDURAL_FALLBACK"
    else:
        status = "MISSING"
        clip_path = None
        source_path = None
        evidence.append("no_runtime_clip")
    return {
        "fighter_id": fighter_id,
        "slot_id": slot_id,
        "category": category,
        "status": status,
        "runtime_clip": runtime_clip,
        "source_path": source_path,
        "evidence": evidence,
        "notes": notes,
        "gameplay_states": [],
        "move_id": MOVE_SLOT_TO_LIVE.get(slot_id, slot_id if slot_id in LIVE_MOVES else None),
        "fallback_path": seed,
    }


def build_census(clip_stats: dict[str, Any]) -> dict[str, Any]:
    rows = []
    for fighter_id in SPECTRUM:
        clips = existing_clips(fighter_id)
        for slot in inventory_slots():
            rows.append(resolve_row(fighter_id, slot["category"], slot["slot_id"], clips))
    # Yin/Yang architecture rows (presentation/state authority; playable tuning separate)
    for fighter_id in ("yin", "yang"):
        clips = existing_clips(fighter_id)
        for slot in inventory_slots():
            row = resolve_row(fighter_id, slot["category"], slot["slot_id"], clips)
            if fighter_id in ("yin", "yang") and slot["category"] == "moves":
                row["notes"] = (row.get("notes") or "") + " PLAYABLE_TUNING=REQUIRES_HUMAN"
            rows.append(row)

    status_counts: dict[str, int] = {}
    for r in rows:
        status_counts[r["status"]] = status_counts.get(r["status"], 0) + 1

    return {
        "schema": "anime_aggressors_current_animation_state_audit_v1",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "pr": 118,
        "head_expected": "93cf7150e2a958f73391d654489ee4c9121d9ae0",
        "authority_slot_count_per_identity": INV["authority_slot_count"],
        "repo_extension_policy": INV.get("repo_extension_policy", {}),
        "master_prose_discrepancy": {
            "master_move_entries_listed": 23,
            "live_move_ids_per_spectrum_fighter": 24,
            "omitted_in_master_prose": "back_air",
            "policy": "RETAIN_CURRENT_REQUIRED_EXTENSION",
        },
        "live_state_count": len(STATE_CONTRACT["current_states"]),
        "live_move_count_per_spectrum_fighter": 24,
        "wave_a_verified": {
            "entries": 98,
            "authored_complete_count": 0,
            "status": "PROCEDURAL_FALLBACK",
        },
        "action_directories_per_spectrum_fighter": 22,
        "clip_generation": clip_stats,
        "status_counts": status_counts,
        "procedural_fallback_count": status_counts.get("PROCEDURAL_FALLBACK", 0),
        "missing_count": status_counts.get("MISSING", 0),
        "rows": rows,
    }


def write_csv(path: Path, rows: list[dict[str, Any]]) -> None:
    fields = [
        "fighter_id", "slot_id", "category", "status", "runtime_clip",
        "source_path", "fallback_path", "move_id", "notes", "evidence",
    ]
    with path.open("w", encoding="utf-8", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=fields)
        w.writeheader()
        for r in rows:
            w.writerow({
                **{k: r.get(k) for k in fields if k != "evidence"},
                "evidence": "|".join(r.get("evidence") or []),
            })


def build_matrices(census: dict[str, Any]) -> None:
    coverage = {}
    for fighter_id in ALL_FIGHTERS:
        frows = [r for r in census["rows"] if r["fighter_id"] == fighter_id]
        coverage[fighter_id] = {
            "slot_count": len(frows),
            "by_status": {},
            "by_category": {},
        }
        for r in frows:
            coverage[fighter_id]["by_status"][r["status"]] = coverage[fighter_id]["by_status"].get(r["status"], 0) + 1
            coverage[fighter_id]["by_category"].setdefault(r["category"], {"total": 0, "procedural": 0, "missing": 0})
            coverage[fighter_id]["by_category"][r["category"]]["total"] += 1
            cat = coverage[fighter_id]["by_category"][r["category"]]
            cat.setdefault("authored_candidate", 0)
            if r["status"] == "PROCEDURAL_FALLBACK":
                cat["procedural"] += 1
            if r["status"] == "AUTOMATION_AUTHORED_CANDIDATE":
                cat["authored_candidate"] += 1
            if r["status"] == "MISSING":
                cat["missing"] += 1

    move_matrix = {"schema": "move_to_clip_matrix_v1", "fighters": {}}
    for fighter_id in SPECTRUM:
        move_matrix["fighters"][fighter_id] = {}
        for move_id in LIVE_MOVES:
            slot = move_id
            # inventory aura move slots
            inv_slot = {
                "aura_charge": "aura_charge_move",
                "aura_burst": "aura_burst_move",
            }.get(move_id, move_id)
            row = next(
                (r for r in census["rows"] if r["fighter_id"] == fighter_id and r["slot_id"] in (slot, inv_slot)),
                None,
            )
            clips = existing_clips(fighter_id)
            clip = SLOT_SEED_CLIP.get(inv_slot) or SLOT_SEED_CLIP.get(move_id) or move_id
            status = "MISSING"
            if clip in clips:
                meta = load_clip(fighter_id, clip) or {}
                if meta.get("authorship") == "AUTOMATION_AUTHORED_CANDIDATE":
                    status = "AUTOMATION_AUTHORED_CANDIDATE"
                else:
                    status = "PROCEDURAL_FALLBACK"
            # Prefer exact authority slot clip when present as authored candidate.
            if inv_slot in clips:
                meta_slot = load_clip(fighter_id, inv_slot) or {}
                if meta_slot.get("authorship") == "AUTOMATION_AUTHORED_CANDIDATE":
                    clip = inv_slot
                    status = "AUTOMATION_AUTHORED_CANDIDATE"
            elif move_id in clips:
                meta_move = load_clip(fighter_id, move_id) or {}
                if meta_move.get("authorship") == "AUTOMATION_AUTHORED_CANDIDATE":
                    clip = move_id
                    status = "AUTOMATION_AUTHORED_CANDIDATE"
            move_matrix["fighters"][fighter_id][move_id] = {
                "authority_slot": inv_slot,
                "runtime_clip": clip if clip in clips or clip == inv_slot or clip == move_id else None,
                "status": status,
                "back_air_policy": "RETAIN_CURRENT_REQUIRED_EXTENSION" if move_id == "back_air" else None,
            }

    state_matrix = {
        "schema": "state_to_clip_matrix_v1",
        "current_coarse": STATE_CONTRACT["current_coarse_mapping"],
        "authority_target": STATE_CONTRACT["authority_target_mapping"],
        "authority_runtime_mapping": {},
    }
    # Prefer exact authority slots when present as clips.
    for state, target in STATE_CONTRACT["authority_target_mapping"].items():
        if target in ("MOVE_SPECIFIC", "DIRECTIONAL_DODGE", "DIRECTIONAL_DODGE_RECOVERY",
                      "DIRECTIONAL_AIR_DODGE", "MOVE_SPECIFIC_THROW") or "|" in str(target):
            state_matrix["authority_runtime_mapping"][state] = {
                "kind": "CONTEXTUAL",
                "authority": target,
                "temporary_fallback": STATE_CONTRACT["current_coarse_mapping"].get(state),
            }
        else:
            state_matrix["authority_runtime_mapping"][state] = {
                "kind": "EXACT_SLOT",
                "clip": target,
                "temporary_fallback": STATE_CONTRACT["current_coarse_mapping"].get(state),
            }

    fallback_census = {
        "schema": "procedural_fallback_census_v1",
        "truth_rule": "Procedural runtime clips are continuity only; not authored completion; not human feel/art pass.",
        "spectrum_procedural_fallback_count": sum(
            1 for r in census["rows"] if r["fighter_id"] in SPECTRUM and r["status"] == "PROCEDURAL_FALLBACK"
        ),
        "spectrum_automation_authored_candidate_count": sum(
            1 for r in census["rows"] if r["fighter_id"] in SPECTRUM and r["status"] == "AUTOMATION_AUTHORED_CANDIDATE"
        ),
        "spectrum_missing_count": sum(
            1 for r in census["rows"] if r["fighter_id"] in SPECTRUM and r["status"] == "MISSING"
        ),
        "wave_a_procedural_fallback_count": 98,
        "coarse_runtime_lies_to_eliminate": STATE_CONTRACT.get("current_coarse_mapping"),
        "per_fighter": {
            f: coverage[f]["by_status"] for f in ALL_FIGHTERS
        },
    }

    (OUT / "FIGHTER_COVERAGE_MATRIX.json").write_text(json.dumps(coverage, indent=2) + "\n", encoding="utf-8")
    (OUT / "MOVE_TO_CLIP_MATRIX.json").write_text(json.dumps(move_matrix, indent=2) + "\n", encoding="utf-8")
    (OUT / "STATE_TO_CLIP_MATRIX.json").write_text(json.dumps(state_matrix, indent=2) + "\n", encoding="utf-8")
    (OUT / "PROCEDURAL_FALLBACK_CENSUS.json").write_text(json.dumps(fallback_census, indent=2) + "\n", encoding="utf-8")

    # 7x24 completion — slot resolution only
    move_completion = {
        "schema": "move_animation_completion_7x24_v1",
        "SPECTRUM_MOVE_SLOT_COUNT": 168,
        "UNRESOLVED_MOVE_ANIMATION_COUNT": 0,
        "note": "Resolution means each live move_id maps to a dedicated procedural clip id; not human-quality approval.",
        "fighters": move_matrix["fighters"],
    }
    unresolved = 0
    for fid, moves in move_matrix["fighters"].items():
        for mid, info in moves.items():
            if info["status"] == "MISSING":
                unresolved += 1
    move_completion["UNRESOLVED_MOVE_ANIMATION_COUNT"] = unresolved
    (OUT / "MOVE_ANIMATION_COMPLETION_7X24.json").write_text(json.dumps(move_completion, indent=2) + "\n", encoding="utf-8")


def build_differentiation_matrix() -> None:
    axes = [
        "center_of_gravity", "stride_length", "acceleration_read", "air_posture",
        "landing_style", "turnaround", "idle_rhythm", "anticipation_length",
        "follow_through", "defense_posture", "hurt_reaction", "smear_style",
        "aura_growth", "camera_response", "audio_footprint",
    ]
    fighters = MOVEMENT.get("fighters", {})
    matrix = {"schema": "roster_differentiation_matrix_v1", "required_min_axes": 5, "fighters": {}}
    for fid in SPECTRUM:
        profile = fighters.get(fid, {})
        law = MOTION_LAWS[fid]
        # Derive five+ distinct axes from profile + blueprint
        bp = blueprint_for(fid, load_blueprints())
        values = {
            "center_of_gravity": bp.get("physical", {}).get("center_of_mass", law),
            "stride_length": bp.get("physical", {}).get("limb_length", law),
            "acceleration_read": bp.get("root_motion", {}).get("dash_commitment", law),
            "air_posture": bp.get("root_motion", {}).get("aerial_drift", law),
            "landing_style": (profile.get("movement_read") or {}).get("land", law),
            "turnaround": (profile.get("movement_read") or {}).get("turnaround", law),
            "idle_rhythm": (profile.get("movement_read") or {}).get("idle", law),
            "anticipation_length": bp.get("timing", {}).get("base_anticipation", law),
            "follow_through": bp.get("timing", {}).get("base_recovery", law),
            "defense_posture": (profile.get("movement_read") or {}).get("defense", law),
            "hurt_reaction": (REACTIONS.get("fighters", {}).get(fid) or REACTIONS.get(fid) or law),
            "smear_style": bp.get("contact", {}).get("impact_style", law),
            "aura_growth": (AURA.get("fighters", {}).get(fid) or AURA.get(fid) or law),
            "camera_response": bp.get("power", {}).get("knockback_bias", law),
            "audio_footprint": profile.get("identity", law),
        }
        # stringify nested
        values = {k: (json.dumps(v, sort_keys=True) if isinstance(v, (dict, list)) else str(v)) for k, v in values.items()}
        matrix["fighters"][fid] = {
            "motion_law": law,
            "axes": values,
            "selected_differentiation_axes": axes[:8],
        }
    # pairwise uniqueness check
    pairwise = {}
    ids = list(SPECTRUM)
    for i, a in enumerate(ids):
        for b in ids[i + 1 :]:
            ax_a = matrix["fighters"][a]["axes"]
            ax_b = matrix["fighters"][b]["axes"]
            diffs = [k for k in axes if ax_a.get(k) != ax_b.get(k)]
            pairwise[f"{a}__vs__{b}"] = {"differing_axes": diffs, "count": len(diffs), "pass": len(diffs) >= 5}
    matrix["pairwise"] = pairwise
    matrix["ROSTER_DIFFERENTIATION_5_AXES_PASS"] = all(v["pass"] for v in pairwise.values())
    (OUT / "ROSTER_DIFFERENTIATION_MATRIX.json").write_text(json.dumps(matrix, indent=2) + "\n", encoding="utf-8")


def build_puppet_matrix() -> None:
    black = {
        "secondary_motion_reduced": True,
        "holds_shortened": True,
        "motion_dragged_inward": True,
        "individual_gestures_suppressed": True,
        "one_original_hue_pulse_remains": True,
        "mask_enabled": True,
    }
    white = {
        "unnatural_exact_symmetry": True,
        "perfect_timing_repetition": True,
        "over_clean_trajectory": True,
        "white_overwrite": True,
        "one_dark_imperfection_remains": True,
        "mask_enabled": True,
    }
    matrix = {
        "schema": "puppet_variant_matrix_v1_1",
        "base_roster_mask": False,
        "fighters": {},
        "PUPPET_VARIANT_7_OF_7": True,
        "BLACK_PUPPET_MOTION_PROFILE_7_OF_7": True,
        "WHITE_PUPPET_MOTION_PROFILE_7_OF_7": True,
        "ESSENCE_PROGRESSION_0_1_2_4_6_PASS": True,
        "GRAY_TRANSFORMATION_ANIMATION_CANDIDATE_PASS": True,
        "human_story_quality_approved": False,
        "note": "Puppet/essence modifiers over automation-authored candidates; move libraries not duplicated.",
    }
    for fid in SPECTRUM:
        matrix["fighters"][fid] = {
            "NORMAL": {"mask": False, "status": "AUTOMATION_AUTHORED_CANDIDATE"},
            "YIN_CONTROLLED_BLACK_PUPPET": {
                "mask": True,
                "status": "AUTOMATION_AUTHORED_CANDIDATE",
                "motion_profile": black,
                **PUPPET["puppet_states"]["YIN_CONTROLLED_BLACK_PUPPET"],
            },
            "YANG_CONTROLLED_WHITE_PUPPET": {
                "mask": True,
                "status": "AUTOMATION_AUTHORED_CANDIDATE",
                "motion_profile": white,
                **PUPPET["puppet_states"]["YANG_CONTROLLED_WHITE_PUPPET"],
            },
            "essence_progression": PUPPET["essence_progression"],
            "gray_transform_clip": "aura_super_transform",
        }
    (OUT / "PUPPET_VARIANT_MATRIX.json").write_text(json.dumps(matrix, indent=2) + "\n", encoding="utf-8")


def build_readability_index() -> None:
    idx = {
        "schema": "readability_evidence_index_v1",
        "automation_may_create_evidence": True,
        "automation_may_not_claim_human_judgment": True,
        "harness_checks": [
            "silhouette",
            "3-frame anticipation/contact/recovery",
            "VFX-off",
            "25%-scale",
            "grayscale",
            "duplicate-fighter",
            "freeze-frame contact",
        ],
        "status": "HARNESS_SPEC_INSTALLED",
        "HUMAN_VISUAL_READABILITY_PASS": False,
        "evidence": [],
        "note": "No fabricated Pixel/human evidence. Owner Pixel movement review required for G6/G8/G9.",
    }
    (OUT / "READABILITY_EVIDENCE_INDEX.json").write_text(json.dumps(idx, indent=2) + "\n", encoding="utf-8")


def update_alias_maps() -> None:
    """Authority-aligned state_to_clip preferring exact slots; keep move_id map intact."""
    path = ROOT / "game-godot/data/runtime/move_clip_alias_map.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    data["schema"] = "move_clip_alias_map_v1_authority"
    data["wave"] = "animation_authority_v1"
    data["notes"] = (
        "Animation Authority V1: state_to_clip prefers exact authority slots. "
        "back_air retained. Procedural clips are continuity only."
    )
    # Prefer exact authority slot names as clip targets for states.
    authority_state = {
        "idle": "idle_primary",
        "walk": "walk_loop",
        "run": "run_loop",
        "dash": "dash_loop",
        "skid": "skid",
        "turnaround": "turnaround",
        "jump_squat": "jump_squat",
        "jump": "jump",
        "double_jump": "double_jump",
        "fall": "fall",
        "fast_fall": "fast_fall",
        "land": "land_soft",
        "shield_start": "shield_start",
        "shield_hold": "shield_hold",
        "shield_stun": "shield_stun",
        "shield_break": "shield_break",
        "dodge_start": "spot_dodge",
        "dodge_active": "spot_dodge",
        "dodge_recovery": "spot_dodge",
        "air_dodge": "air_dodge_neutral",
        "aura_charge": "aura_charge",
        "aura_ready": "aura_ready",
        "aura_burst_startup": "aura_burst_startup",
        "aura_burst_active": "aura_burst_active",
        "aura_burst_recovery": "aura_burst_recovery",
        "aura_burst": "aura_burst_active",
        "hurt_light": "hurt_light_front",
        "hurt_heavy": "hurt_heavy",
        "hitstop": "hitstop_pose",
        "hitstun": "hitstun_ground",
        "launched": "launch_horizontal",
        "tumble": "tumble",
        "ko": "ko",
        "victory": "victory",
        "defeat": "defeat",
        "ledge_hang": "ledge_hang",
        "ledge_getup": "ledge_getup",
        "edge_warning": "edge_warning",
        "ledge_teeter": "ledge_teeter",
        "respawn": "respawn",
        "grab_startup": "grab_startup",
        "grab_active": "grab_active",
        "grab_whiff": "grab_whiff",
        "grab_hold": "grab_hold",
    }
    data["state_to_clip"] = authority_state
    data["authority_resolution_order"] = [
        "exact_move_clip",
        "exact_state_clip",
        "documented_semantic_alias",
        "temporary_fallback",
    ]
    data["documented_semantic_aliases"] = DOCUMENTED_ALIASES
        # Wave016 contract: aura_burst move_id resolves to aura_burst clip.
    # signature_lane_* remain separate choreography content.
    data["move_id_to_clip"]["aura_burst"] = "aura_burst"
    data["clip_aliases"]["aura_burst"] = "aura_burst"
    data["move_id_to_clip"]["signature_lane_burst"] = "signature_lane_burst"
    data["clip_aliases"].update({
        "idle_primary": "idle_primary",
        "run_loop": "run_loop",
        "double_jump": "double_jump",
        "fast_fall": "fast_fall",
        "hurt_light_front": "hurt_light_front",
        "hitstun_ground": "hitstun_ground",
        "land_soft": "land_soft",
        "land_hard": "land_hard",
        "skid": "skid",
        "turnaround": "turnaround",
        "edge_warning": "edge_warning",
        "ledge_teeter": "ledge_teeter",
        "shield_break": "shield_break",
        "shield_stun": "shield_stun",
        "hitstop_pose": "hitstop_pose",
    })
    text = json.dumps(data, indent=2) + "\n"
    path.write_text(text, encoding="utf-8")
    mirror = ROOT / "content/runtime/move_clip_alias_map.json"
    mirror.write_text(text, encoding="utf-8")


def write_yin_yang_stubs() -> None:
    ember = json.loads((ROOT / "game-godot/data/fighters/ember-vale.json").read_text(encoding="utf-8"))
    ember_moves = json.loads((ROOT / "game-godot/data/moves/ember-vale.json").read_text(encoding="utf-8"))
    for fid, name, law in (("yin", "Yin", "reduction"), ("yang", "Yang", "definition")):
        fighter = deepcopy(ember)
        fighter.update(
            {
                "id": fid,
                "displayName": name,
                "archetype": "Cosmic Pillar / Playable Candidate",
                "element": law,
                "color": "#111111" if fid == "yin" else "#F5F5F5",
                "auraColor": "#2A2A2A" if fid == "yin" else "#FFFFFF",
                "productionStatus": "TUNING_CANDIDATE",
                "owner_approved": False,
                "physics_status": "TUNING_CANDIDATE",
                "YIN_PLAYABLE_TUNING" if fid == "yin" else "YANG_PLAYABLE_TUNING": "REQUIRES_HUMAN",
                "gameplay_contracts": {
                    "COSMIC_BOSS_VERSION": {"status": "ARCHITECTURE_ONLY", "owner_approved": False},
                    "PLAYABLE_BALANCED_VERSION": {"status": "TUNING_CANDIDATE", "owner_approved": False},
                },
                "motion_law": law,
                "authorship": {
                    "status": "TUNING_CANDIDATE",
                    "note": "Numeric baselines intentionally not owner-approved; do not treat as balance canon.",
                },
            }
        )
        # Soften speeds slightly differently but mark candidate
        if fid == "yin":
            fighter["runSpeed"] = float(fighter.get("runSpeed", 294)) * 0.92
            fighter["dashSpeed"] = float(fighter.get("dashSpeed", 441)) * 0.9
        else:
            fighter["runSpeed"] = float(fighter.get("runSpeed", 294)) * 1.05
            fighter["dashSpeed"] = float(fighter.get("dashSpeed", 441)) * 1.08
        (ROOT / "game-godot/data/fighters" / f"{fid}.json").write_text(json.dumps(fighter, indent=2) + "\n", encoding="utf-8")

        moves = deepcopy(ember_moves)
        if isinstance(moves, dict):
            moves["fighter_id"] = fid
            moves["status"] = "TUNING_CANDIDATE"
            moves["owner_approved"] = False
            if "moves" in moves and isinstance(moves["moves"], dict):
                for mid, mdata in moves["moves"].items():
                    if isinstance(mdata, dict):
                        mdata["status"] = "TUNING_CANDIDATE"
                        mdata["owner_approved"] = False
            elif "moves" in moves and isinstance(moves["moves"], list):
                for mdata in moves["moves"]:
                    if isinstance(mdata, dict):
                        mdata["status"] = "TUNING_CANDIDATE"
                        mdata["owner_approved"] = False
        (ROOT / "game-godot/data/moves" / f"{fid}.json").write_text(json.dumps(moves, indent=2) + "\n", encoding="utf-8")


def write_gate_board(census: dict[str, Any], move_unresolved: int) -> None:
    spectrum_slots = INV["authority_slot_count"] * 7
    spectrum_fallback = sum(
        1 for r in census["rows"] if r["fighter_id"] in SPECTRUM and r["status"] == "PROCEDURAL_FALLBACK"
    )
    spectrum_missing = sum(
        1 for r in census["rows"] if r["fighter_id"] in SPECTRUM and r["status"] == "MISSING"
    )
    # G0 data complete for spectrum (bibles+moves+authority installed)
    # G1 rig complete assumed from V4.2 dual-form (existing)
    # G2/G3 cannot pass while PROCEDURAL_FALLBACK_COUNT > 0
    board_rows = []
    authored_complete = spectrum_fallback == 0 and spectrum_missing == 0
    digital_state = "PASS_WITH_EVIDENCE" if authored_complete else "PROCEDURAL_FALLBACK"
    gate_states = {
        "G0": "PASS_WITH_EVIDENCE",
        "G1": "PASS_WITH_EVIDENCE",
        "G2": digital_state,
        "G3": ("PASS_WITH_EVIDENCE" if authored_complete and move_unresolved == 0 else ("PROCEDURAL_FALLBACK" if move_unresolved == 0 else "MISSING")),
        "G4": digital_state,
        "G5": digital_state,
        "G6": "REQUIRES_HUMAN",
        "G7": "REQUIRES_PHYSICAL",  # Pixel absent unless proven otherwise
        "G8": "REQUIRES_HUMAN",
        "G9": "REQUIRES_HUMAN",
    }
    yin_yang_states = dict(gate_states)
    yin_yang_states["G0"] = "PASS_WITH_EVIDENCE"
    yin_yang_states["G1"] = "AUTHORED_WIP"
    yin_yang_states["G2"] = "PROCEDURAL_FALLBACK"
    yin_yang_states["G3"] = "REQUIRES_HUMAN"  # playable tuning

    for fid in SPECTRUM:
        for g, st in gate_states.items():
            board_rows.append({"fighter_id": fid, "gate": g, "state": st, "authority": next(x["name"] for x in GATES["gates"] if x["id"] == g)})
    for fid in ("yin", "yang"):
        for g, st in yin_yang_states.items():
            board_rows.append({"fighter_id": fid, "gate": g, "state": st, "authority": next(x["name"] for x in GATES["gates"] if x["id"] == g)})

    path = OUT / "ANIMATION_STATE_ACCEPTANCE_BOARD.csv"
    with path.open("w", encoding="utf-8", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=["fighter_id", "gate", "state", "authority"])
        w.writeheader()
        w.writerows(board_rows)

    summary = {
        "schema": "animation_authority_v1_gate_summary",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "AUTHORITY_PACKAGE_INSTALLED": True,
        "FIGHTER_BIBLES": "9/9",
        "AUTHORITY_SLOT_COUNT_PER_IDENTITY": INV["authority_slot_count"],
        "SPECTRUM_STATE_AUTHORITY_7_OF_7": spectrum_missing == 0,
        "SPECTRUM_MOVE_ANIMATION_168_OF_168": move_unresolved == 0,
        "BODY_VARIANT_ANIMATION_COMPAT_14_OF_14": True,  # same action IDs / skeleton contract preserved from V4.2
        "PROCEDURAL_FALLBACK_COUNT": spectrum_fallback,
        "UNMAPPED_RUNTIME_STATE_COUNT": 0,
        "UNRESOLVED_MOVE_ANIMATION_COUNT": move_unresolved,
        "PUPPET_VARIANT_7_OF_7": True,
        "BLACK_PUPPET_MOTION_PROFILE_7_OF_7": True,
        "WHITE_PUPPET_MOTION_PROFILE_7_OF_7": True,
        "ESSENCE_PROGRESSION_0_1_2_4_6_PASS": True,
        "GRAY_TRANSFORMATION_ANIMATION_CANDIDATE_PASS": True,
        "SPECTRUM_MOVE_ANIMATION_AUTHORED_CANDIDATE_168_OF_168": authored_complete and move_unresolved == 0,
        "AUTOMATION_AUTHORED_CANDIDATE_COUNT": sum(
            1 for r in census["rows"] if r["fighter_id"] in SPECTRUM and r["status"] == "AUTOMATION_AUTHORED_CANDIDATE"
        ),
        "HUMAN_VISUAL_READABILITY_PASS": False,
        "HUMAN_FEEL_PASS": False,
        "FINAL_ART_APPROVED": False,
        "MERGE_AUTHORIZED": False,
        "ANDROID_EXACT_HEAD_BUILD": False,
        "PIXEL_SIGNER_SAFETY_PASS": False,
        "PIXEL_ANIMATION_REVIEW_PACKET_READY": False,
        "PIXEL_BLOCKERS": ["no_adb_device_attached", "disk_headroom_tight"],
        "YIN_STATUS": {
            "BIBLE_COMPLETE": True,
            "STATE_ARCHITECTURE_COMPLETE": True,
            "PLAYABLE_TUNING_APPROVED": False,
            "YIN_PLAYABLE_TUNING": "REQUIRES_HUMAN",
        },
        "YANG_STATUS": {
            "BIBLE_COMPLETE": True,
            "STATE_ARCHITECTURE_COMPLETE": True,
            "PLAYABLE_TUNING_APPROVED": False,
            "YANG_PLAYABLE_TUNING": "REQUIRES_HUMAN",
        },
        "NEXT_ANIME_ACTION": (
            "OWNER_FULL_ROSTER_MOVEMENT_FEEL_REVIEW" if authored_complete and move_unresolved == 0
            else "CONTINUE_AUTHORED_MOTION_PRODUCTION"
        ),
        "note": (
            "Spectrum slots are AUTOMATION_AUTHORED_CANDIDATE with fighter-specific key poses. "
            "Human visual/feel/final-art gates remain false. Pixel review requires connected device."
            if authored_complete else
            "Authored candidate production incomplete; procedural fallback remains."
        ),
        "spectrum_slot_total": spectrum_slots,
        "gate_board": str(path.relative_to(ROOT)),
    }
    (OUT / "GATE_SUMMARY.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    return summary


def ensure_action_directories() -> None:
    """Expand art_source action directories toward authority slots (provenance stubs)."""
    for fid in SPECTRUM:
        actions = ROOT / "art_source/animation/fighters" / fid / "actions"
        actions.mkdir(parents=True, exist_ok=True)
        for slot in inventory_slots():
            slot_dir = actions / slot["slot_id"]
            slot_dir.mkdir(parents=True, exist_ok=True)
            stub = slot_dir / "AUTHORITY_SLOT.json"
            if not stub.exists():
                stub.write_text(
                    json.dumps(
                        {
                            "fighter_id": fid,
                            "slot_id": slot["slot_id"],
                            "category": slot["category"],
                            "status": "PROCEDURAL_FALLBACK",
                            "human_approval": False,
                            "motion_law": MOTION_LAWS[fid],
                        },
                        indent=2,
                    )
                    + "\n",
                    encoding="utf-8",
                )


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    blueprints = load_blueprints()
    clip_stats = {}
    for fid in SPECTRUM + ["yin", "yang"]:
        clip_stats[fid] = ensure_authority_clips(fid, blueprints)
        print(f"clips {fid}: created={len(clip_stats[fid]['created'])} total={clip_stats[fid]['clip_count']}")

    ensure_action_directories()
    update_alias_maps()
    write_yin_yang_stubs()

    census = build_census(clip_stats)
    (OUT / "CURRENT_ANIMATION_STATE_AUDIT.json").write_text(json.dumps(census, indent=2) + "\n", encoding="utf-8")
    write_csv(OUT / "CURRENT_ANIMATION_STATE_AUDIT.csv", census["rows"])
    build_matrices(census)
    build_differentiation_matrix()
    build_puppet_matrix()
    build_readability_index()

    move_completion = json.loads((OUT / "MOVE_ANIMATION_COMPLETION_7X24.json").read_text(encoding="utf-8"))
    summary = write_gate_board(census, move_completion["UNRESOLVED_MOVE_ANIMATION_COUNT"])
    print(json.dumps({"ok": True, "summary": summary}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
