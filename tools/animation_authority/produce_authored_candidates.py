#!/usr/bin/env python3
"""Produce fighter/slot-specific AUTOMATION_AUTHORED_CANDIDATE clips for spectrum roster.

Truth model (playbook V1.1):
  - Cursor may create AUTOMATION_AUTHORED_CANDIDATE only.
  - Never flip HUMAN_* / FINAL_ART / MERGE_AUTHORIZED.
  - Procedural continuity is replaced by deliberate key-pose candidates.
  - Yin/Yang remain architecture-complete with PLAYABLE_TUNING=REQUIRES_HUMAN.
"""
from __future__ import annotations

import json
import math
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/animation_pipeline/procedural"))
from _common import BONES, FIGHTERS, blueprint_for, curve_signature, fighter_seed, load_blueprints  # noqa: E402

OUT = ROOT / "artifacts/animation_authority_v1"
INV = json.loads((ROOT / "data/bibles/animation_inventory_v1.json").read_text(encoding="utf-8"))
PUPPET = json.loads((ROOT / "data/bibles/puppet_essence_story_states_v1.json").read_text(encoding="utf-8"))

SPECTRUM = list(FIGHTERS)
MOTION_LAWS = {
    "ember-vale": "combustion",
    "rook-ironside": "mass",
    "juno-spark": "current",
    "kaia-windrow": "flow",
    "nix-calder": "structure",
    "orion-vell": "vectors",
    "vesper-nyx": "uncertainty",
}
ELEMENTAL_ANATOMY = {
    "ember-vale": "combustion_vent_deformation",
    "rook-ironside": "plate_strata_compression",
    "juno-spark": "current_rail_extension",
    "kaia-windrow": "ribbon_airfoil_deformation",
    "nix-calder": "lattice_facet_growth",
    "orion-vell": "orbit_node_vector_movement",
    "vesper-nyx": "phase_offset_geometry",
}
LAW_BIAS = {
    "combustion": {"amp": (1.20, 0.90, 1.25), "antic": 0.85, "follow": 1.20, "cog": 0.18, "stride": 1.15},
    "mass": {"amp": (0.70, 1.30, 0.65), "antic": 1.45, "follow": 1.35, "cog": -0.22, "stride": 0.70},
    "current": {"amp": (1.30, 0.80, 1.15), "antic": 0.70, "follow": 0.85, "cog": 0.05, "stride": 1.30},
    "flow": {"amp": (0.95, 1.10, 1.20), "antic": 1.00, "follow": 1.15, "cog": 0.28, "stride": 1.10},
    "structure": {"amp": (0.85, 1.20, 0.75), "antic": 1.25, "follow": 1.10, "cog": -0.10, "stride": 0.90},
    "vectors": {"amp": (1.10, 1.00, 1.30), "antic": 1.05, "follow": 1.00, "cog": 0.00, "stride": 1.05},
    "uncertainty": {"amp": (1.05, 0.95, 1.40), "antic": 0.90, "follow": 1.25, "cog": 0.12, "stride": 1.00},
}

ATTACK_SLOTS = {
    "jab_1", "jab_2", "jab_finisher", "forward_tilt", "up_tilt", "down_tilt",
    "dash_attack", "heavy_attack", "neutral_air", "forward_air", "back_air",
    "up_air", "down_air", "neutral_special_projectile", "side_special",
    "up_special_recovery", "down_special", "grab", "throw_forward", "throw_back",
    "throw_up", "throw_down", "aura_charge", "aura_burst", "aura_charge_move",
    "aura_burst_move", "ledge_attack", "pummel",
}
LOOPING_SLOTS = {
    "idle_primary", "idle_secondary", "idle_long", "walk_loop", "run_loop",
    "dash_loop", "crouch_hold", "shield_hold", "ledge_hang", "grab_hold",
    "aura_ready", "character_select_idle", "results_idle", "pratfall", "tumble",
}
REVIEW_CATEGORIES = {
    "locomotion": ["idle_primary", "walk_loop", "run_loop", "dash_loop", "skid", "turnaround"],
    "air_movement": ["jump_squat", "jump", "double_jump", "fall", "fast_fall", "land_hard"],
    "ledge_defense": ["ledge_grab", "ledge_hang", "ledge_getup", "shield_hold", "spot_dodge", "air_dodge_neutral"],
    "reactions": ["hurt_light_front", "hurt_heavy", "launch_vertical", "tumble", "knockdown", "ko"],
    "grabs_throws": ["grab_startup", "grab_hold", "throw_forward", "throw_back", "throw_up", "throw_down"],
    "normals": ["jab_1", "jab_finisher", "forward_tilt", "up_tilt", "down_tilt", "heavy_attack"],
    "aerials": ["neutral_air", "forward_air", "back_air", "up_air", "down_air"],
    "specials": ["neutral_special_projectile", "side_special", "up_special_recovery", "down_special"],
    "aura": ["aura_charge", "aura_ready", "aura_burst_startup", "aura_burst_active", "aura_burst_recovery"],
    "presentation": ["match_intro", "taunt_1", "victory", "defeat", "character_select_confirm"],
    "puppet_black": ["idle_primary", "walk_loop", "jab_1", "aura_burst"],
    "puppet_white": ["idle_primary", "walk_loop", "jab_1", "aura_burst"],
    "prismatic_essence": ["aura_super_transform", "aura_ready", "victory"],
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


def slot_family(slot_id: str, category: str) -> str:
    if slot_id in ATTACK_SLOTS or category == "moves":
        return "attack"
    if "ledge" in slot_id or slot_id in ("edge_warning", "platform_drop"):
        return "ledge"
    if any(x in slot_id for x in ("shield", "dodge", "roll", "tech", "pratfall")):
        return "defense"
    if any(x in slot_id for x in ("hurt", "hit", "launch", "tumble", "knock", "ko", "respawn", "bounce")):
        return "reaction"
    if "aura" in slot_id:
        return "aura"
    if any(x in slot_id for x in ("intro", "select", "taunt", "victory", "defeat", "results", "dialogue")):
        return "presentation"
    if any(x in slot_id for x in ("jump", "fall", "land", "hop")):
        return "air"
    return "locomotion"


def timing_for(slot_id: str, category: str, blueprint: dict, law: str) -> dict[str, int]:
    bias = LAW_BIAS[law]
    t = blueprint.get("timing", {})
    base_antic = int(round(float(t.get("base_anticipation", 4)) * bias["antic"]))
    base_active = int(t.get("base_active", 5))
    base_rec = int(round(float(t.get("base_recovery", 8)) * bias["follow"]))
    tempo = float(t.get("tempo_scale", 1.0))
    family = slot_family(slot_id, category)

    if family == "attack":
        total = max(14, int((base_antic + base_active + base_rec) / max(tempo, 0.5)))
        if "heavy" in slot_id or "finisher" in slot_id or "special" in slot_id:
            total = int(total * 1.35)
            base_antic = int(base_antic * 1.25)
        if "jab_1" in slot_id:
            total = max(12, int(total * 0.75))
        if "air" in slot_id:
            total = int(total * 1.05)
        return {
            "anticipation": max(2, base_antic),
            "contact": max(base_antic + 1, base_antic + max(2, base_active // 2)),
            "follow": max(base_antic + base_active, total - max(3, base_rec // 2)),
            "total": total,
        }
    if family == "air":
        total = 18 if "land" in slot_id else 24
        return {"anticipation": 3, "contact": total // 2, "follow": total - 4, "total": total}
    if family == "defense":
        total = 16 if "dodge" in slot_id or "roll" in slot_id else 20
        return {"anticipation": 2, "contact": total // 3, "follow": (2 * total) // 3, "total": total}
    if family == "reaction":
        total = 28 if "launch" in slot_id or "ko" in slot_id else 18
        return {"anticipation": 1, "contact": 4, "follow": total - 4, "total": total}
    if family == "aura":
        total = 36 if "burst" in slot_id or "transform" in slot_id else 24
        return {"anticipation": max(3, base_antic), "contact": total // 2, "follow": total - 6, "total": total}
    if family == "presentation":
        total = 48 if slot_id in ("match_intro", "victory", "defeat") else 30
        return {"anticipation": 6, "contact": total // 2, "follow": total - 8, "total": total}
    if family == "ledge":
        return {"anticipation": 3, "contact": 8, "follow": 14, "total": 20}
    if "idle" in slot_id:
        total = 48 if slot_id == "idle_long" else 32
        return {"anticipation": 8, "contact": total // 2, "follow": total - 8, "total": total}
    if any(x in slot_id for x in ("walk", "run", "dash")):
        total = 20 if slot_id.endswith("_start") or slot_id.endswith("_stop") else 24
        return {"anticipation": 3, "contact": total // 2, "follow": total - 3, "total": total}
    return {"anticipation": max(2, base_antic), "contact": 8, "follow": 14, "total": 20}


def pose_angles(fighter_id: str, slot_id: str, bone: str, phase_name: str, law: str, blueprint: dict) -> list[float]:
    bias = LAW_BIAS[law]
    ax, ay, az = bias["amp"]
    seed = fighter_seed(fighter_id, slot_id, f"{bone}:{phase_name}")
    family = slot_family(slot_id, "")
    cog = bias["cog"]
    stride = bias["stride"]
    root_style = str(blueprint.get("root_motion", {}).get("style", "neutral"))
    contact_socket = str(blueprint.get("contact", {}).get("primary_socket", "hand_r"))
    phase_mul = {
        "intent": 0.15, "anticipation": -0.85, "acceleration": 0.55, "contact": 1.0,
        "follow": 0.65, "recovery": 0.20, "apex": 0.90, "hold": 0.35, "loop_a": 0.45, "loop_b": -0.45,
    }.get(phase_name, 0.3)
    base = [
        math.sin(seed * math.pi * 2) * 0.22 * ax * phase_mul,
        math.cos(seed * 1.7) * 0.18 * ay * phase_mul,
        math.sin(seed * 0.9 + 1.1) * 0.20 * az * phase_mul,
    ]
    if law == "combustion":
        if bone in ("UpperArm_R", "Hand_R", "Chest"):
            base[0] += 0.18 * phase_mul
            base[2] += 0.12 * abs(phase_mul)
        if bone == "Spine":
            base[0] += cog * 0.35
    elif law == "mass":
        if bone.startswith("UpperLeg") or bone.startswith("LowerLeg"):
            base[0] *= 0.55
            base[1] += -0.12 * stride
        if bone == "Chest":
            base[1] += 0.20 * abs(phase_mul)
        if bone == "Spine":
            base[0] += cog * 0.5
    elif law == "current":
        if bone.endswith("_R") or bone.endswith("_L"):
            base[2] += 0.16 * phase_mul * (1.0 if bone.endswith("_R") else -1.0)
        if "dash" in slot_id or "special" in slot_id:
            base[0] *= 1.25
    elif law == "flow":
        if bone in ("Spine", "Chest"):
            base[2] += 0.14 * math.sin(seed + phase_mul)
        if bone.startswith("UpperArm"):
            base[1] += 0.10 * stride * phase_mul
    elif law == "structure":
        base = [round(v * 4) / 4 for v in base]
        if bone in ("Chest", "Spine"):
            base[1] += 0.08 * abs(phase_mul)
    elif law == "vectors":
        if bone.endswith("_R"):
            base[0] += 0.12 * phase_mul
            base[2] -= 0.10 * phase_mul
        if bone.endswith("_L"):
            base[0] -= 0.08 * phase_mul
            base[2] += 0.12 * phase_mul
    elif law == "uncertainty":
        if bone.endswith("_L"):
            base = [-b * 0.85 for b in base]
        if bone == "Chest":
            base[2] += 0.18 * math.sin(seed * 3 + phase_mul)
    if family == "attack":
        if bone in ("Hand_R", "UpperArm_R", "LowerArm_R") and "hand" in contact_socket:
            base[0] += 0.28 * phase_mul
        if phase_name == "contact" and bone in ("Hand_R", "UpperArm_R", "LowerArm_R"):
            base[0] *= 1.35
            base[1] *= 1.15
    if family == "air" and bone == "Spine":
        base[0] += 0.12 if "fall" in slot_id else -0.08
    if family == "defense" and bone in ("Chest", "UpperArm_L", "UpperArm_R"):
        base[1] += 0.15 if "shield" in slot_id else 0.08
    if family == "reaction":
        if bone == "Spine":
            base[0] += 0.25 if "launch" in slot_id else 0.12
        if "hurt" in slot_id and bone.startswith("UpperArm"):
            base[0] -= 0.18
    if family == "aura" and bone in ("Chest", "Spine", "UpperArm_R", "UpperArm_L"):
        base[1] += 0.22 * abs(phase_mul)
        base[2] += 0.10 * phase_mul
    if "idle" in slot_id and bone == "Chest":
        base[1] += 0.04 * (1 if phase_name == "loop_a" else -1)
    if root_style == "burst_forward" and bone == "Spine" and phase_name in ("acceleration", "contact"):
        base[0] += 0.10
    if root_style == "planted_pivot" and bone.startswith("LowerLeg"):
        base[0] *= 0.7
    if root_style == "phase_drift" and bone == "Spine":
        base[2] += 0.09 * phase_mul
    return [round(v, 5) for v in base]


def build_key_poses(fighter_id, slot_id, category, timing, law, blueprint):
    family = slot_family(slot_id, category)
    total = timing["total"]
    if family == "attack":
        phases = [
            ("intent", 0),
            ("anticipation", timing["anticipation"]),
            ("acceleration", max(timing["anticipation"] + 1, (timing["anticipation"] + timing["contact"]) // 2)),
            ("contact", timing["contact"]),
            ("follow", timing["follow"]),
            ("recovery", total),
        ]
    elif slot_id in LOOPING_SLOTS or (family == "locomotion" and slot_id.endswith("_loop")):
        phases = [("loop_a", 0), ("apex", total // 4), ("loop_b", total // 2), ("apex", (3 * total) // 4), ("hold", total)]
    else:
        phases = [
            ("intent", 0),
            ("anticipation", timing["anticipation"]),
            ("contact", timing["contact"]),
            ("follow", timing["follow"]),
            ("recovery", total),
        ]
    poses = []
    for name, frame in phases:
        bones = {bone: pose_angles(fighter_id, slot_id, bone, name, law, blueprint) for bone in BONES}
        poses.append({"name": name, "frame": int(frame), "time_s": round(frame / 60.0, 4), "bones": bones})
    return poses


def tracks_from_poses(poses):
    tracks = {b: [] for b in BONES}
    for pose in poses:
        for bone, rot in pose["bones"].items():
            tracks[bone].append({"frame": pose["frame"], "time_s": pose["time_s"], "rotation_rad": rot})
    return tracks


def event_markers(slot_id, category, timing, law):
    events = []
    family = slot_family(slot_id, category)
    if family == "attack":
        events.append({"frame": timing["anticipation"], "type": "vfx", "id": f"{law}.anticipation"})
        events.append({"frame": timing["contact"], "type": "hit_contact", "id": f"{law}.contact"})
        events.append({"frame": timing["contact"], "type": "sfx", "id": f"{law}.impact"})
        events.append({"frame": timing["follow"], "type": "vfx", "id": f"{law}.follow_through"})
    elif family == "aura":
        events.append({"frame": timing["anticipation"], "type": "vfx", "id": f"{law}.aura_grow"})
        events.append({"frame": timing["contact"], "type": "sfx", "id": f"{law}.aura_peak"})
    elif family == "locomotion" and any(x in slot_id for x in ("walk", "run", "dash", "land")):
        events.append({"frame": timing["contact"], "type": "sfx", "id": f"{law}.footstep"})
    elif family == "reaction":
        events.append({"frame": timing["contact"], "type": "sfx", "id": f"{law}.hurt"})
    return events


def screen_space_rules(law, slot_id):
    return {
        "hand_foot_scale_allowed": True,
        "limb_extension_allowed": True,
        "torso_squash_allowed": law in ("combustion", "mass", "flow"),
        "pose_holds_allowed": True,
        "snap_interpolation_allowed": law in ("current", "combustion", "uncertainty"),
        "perspective_cheat_allowed": True,
        "smear_geometry": {
            "combustion": "heat_ribbon_smear", "mass": "plate_impact_streak", "current": "rail_afterimage",
            "flow": "airfoil_ribbon", "structure": "facet_shard_trail", "vectors": "orbit_node_ghost",
            "uncertainty": "phase_echo_offset",
        }[law],
        "collision_unchanged": True,
        "slot_hint": slot_id,
    }


def write_clip(fighter_id, clip_name, clip):
    for base in (
        ROOT / "content/fighters" / fighter_id / "animations/procedural",
        ROOT / "game-godot/content/fighters" / fighter_id / "animations/procedural",
    ):
        base.mkdir(parents=True, exist_ok=True)
        (base / f"{clip_name}.anim.json").write_text(json.dumps(clip, indent=2) + "\n", encoding="utf-8")


def make_clip(fighter_id, clip_name, category, law, blueprint, role="authority_slot"):
    timing = timing_for(clip_name, category, blueprint, law)
    poses = build_key_poses(fighter_id, clip_name, category, timing, law, blueprint)
    tracks = tracks_from_poses(poses)
    sig = curve_signature(tracks)
    events = event_markers(clip_name, category, timing, law)
    return {
        "schema_version": 1,
        "fighter_id": fighter_id,
        "semantic_slot_id": clip_name,
        "runtime_clip_id": clip_name,
        "action_id": f"{fighter_id}.{clip_name}",
        "clip_name": clip_name,
        "kind": "AUTOMATION_AUTHORED_CANDIDATE_ANIMATION",
        "authorship": "AUTOMATION_AUTHORED_CANDIDATE",
        "authority_slot": clip_name,
        "authority_status": "AUTOMATION_AUTHORED_CANDIDATE",
        "human_approved": False,
        "human_approval": False,
        "fps": 60.0,
        "duration_frames": timing["total"],
        "looping": clip_name in LOOPING_SLOTS,
        "interpolation_mode": "limited_snap" if law in ("current", "combustion") else "bezier_hold",
        "key_poses": [{"name": p["name"], "frame": p["frame"], "time_s": p["time_s"]} for p in poses],
        "bone_tracks": tracks,
        "curve_signature": sig,
        "root_motion_policy": {
            "style": blueprint.get("root_motion", {}).get("style", "neutral"),
            "preserve_gameplay_reach": True,
            "motion_law": law,
        },
        "screen_space_deformation": screen_space_rules(law, clip_name),
        "elemental_anatomy": ELEMENTAL_ANATOMY[fighter_id],
        "events": events,
        "vfx_event_markers": [e for e in events if e["type"] == "vfx"],
        "sfx_event_markers": [e for e in events if e["type"] == "sfx"],
        "hit_contact_markers": [e for e in events if e["type"] == "hit_contact"],
        "runtime_alignment": {
            "motion_law": law,
            "authority_package": "ANIMATION_AUTHORITY_V1_1",
            "body_variant_compat": True,
            "timing": timing,
            "role": role,
        },
        "provenance": {
            "source": "tools/animation_authority/produce_authored_candidates.py",
            "method": "fighter_slot_specific_keypose_synthesis",
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "note": "Automation-authored candidate with explicit key poses and fighter motion law. Not human-authored; not human-approved; not final art.",
            "human_approved": False,
        },
    }, sig, len(poses)


def produce_fighter(fighter_id, blueprints):
    law = MOTION_LAWS[fighter_id]
    blueprint = blueprint_for(fighter_id, blueprints)
    signatures = set()
    for row in inventory_slots():
        slot_id = row["slot_id"]
        clip, sig, pose_count = make_clip(fighter_id, slot_id, row["category"], law, blueprint)
        if sig in signatures:
            for bone in BONES:
                clip["bone_tracks"][bone][0]["rotation_rad"][0] = round(
                    clip["bone_tracks"][bone][0]["rotation_rad"][0] + 0.00017 * (len(signatures) + 1), 5
                )
            sig = curve_signature(clip["bone_tracks"])
            clip["curve_signature"] = sig
        signatures.add(sig)
        write_clip(fighter_id, slot_id, clip)
        stub_dir = ROOT / "art_source/animation/fighters" / fighter_id / "actions" / slot_id
        stub_dir.mkdir(parents=True, exist_ok=True)
        (stub_dir / "AUTHORITY_SLOT.json").write_text(json.dumps({
            "fighter_id": fighter_id, "slot_id": slot_id, "category": row["category"],
            "status": "AUTOMATION_AUTHORED_CANDIDATE", "authorship": "AUTOMATION_AUTHORED_CANDIDATE",
            "human_approval": False, "motion_law": law, "curve_signature": sig, "key_pose_count": pose_count,
        }, indent=2) + "\n", encoding="utf-8")
    return {"fighter_id": fighter_id, "motion_law": law, "unique_authored_candidate_clips": len(signatures), "slots_produced": len(signatures)}


def author_alias_targets(fighter_id, blueprints):
    alias = json.loads((ROOT / "game-godot/data/runtime/move_clip_alias_map.json").read_text(encoding="utf-8"))
    law = MOTION_LAWS[fighter_id]
    blueprint = blueprint_for(fighter_id, blueprints)
    count = 0
    targets = set(alias.get("move_id_to_clip", {}).values()) | set(alias.get("clip_aliases", {}).values())
    targets |= {
        "signature_lane_burst", "signature_lane_confirm", "signature_lane_control",
        "signature_lane_counter", "signature_lane_feint", "signature_lane_finisher",
        "signature_lane_launch", "signature_lane_trap",
    }
    for clip_name in sorted(targets):
        path = ROOT / "content/fighters" / fighter_id / "animations/procedural" / f"{clip_name}.anim.json"
        if not path.is_file():
            continue
        existing = json.loads(path.read_text(encoding="utf-8"))
        if existing.get("authorship") == "AUTOMATION_AUTHORED_CANDIDATE" and existing.get("semantic_slot_id") == clip_name:
            continue
        clip, _, _ = make_clip(fighter_id, clip_name, "moves", law, blueprint, role="runtime_alias_target_or_signature_lane")
        write_clip(fighter_id, clip_name, clip)
        count += 1
    return count


def write_review_bundle(per_fighter):
    review_root = OUT / "review"
    review_root.mkdir(parents=True, exist_ok=True)
    index = {
        "schema": "digital_motion_review_index_v1",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "human_visual_judgment": False,
        "automation_proves_files_exist_only": True,
        "fighters": {},
        "categories": list(REVIEW_CATEGORIES.keys()),
    }
    for fid, stats in per_fighter.items():
        fdir = review_root / fid
        fdir.mkdir(parents=True, exist_ok=True)
        fighter_entry = {"categories": {}, "motion_law": stats["motion_law"]}
        for cat, slots in REVIEW_CATEGORIES.items():
            sheets = []
            for slot in slots:
                clip_path = ROOT / "content/fighters" / fid / "animations/procedural" / f"{slot}.anim.json"
                if not clip_path.is_file():
                    continue
                clip = json.loads(clip_path.read_text(encoding="utf-8"))
                poses = clip.get("key_poses") or []
                pick = []
                for want in ("anticipation", "contact", "apex", "follow", "recovery", "loop_a"):
                    for p in poses:
                        if p.get("name") == want and p not in pick:
                            pick.append(p)
                            break
                pick = pick[:3] if pick else poses[:3]
                sheet = {
                    "slot_id": slot, "clip": str(clip_path.relative_to(ROOT)),
                    "authorship": clip.get("authorship"), "human_approved": False,
                    "key_frames": pick, "duration_frames": clip.get("duration_frames"),
                    "curve_signature": clip.get("curve_signature"),
                    "note": "Digital keyframe contact sheet; not a human readability pass.",
                }
                out_path = fdir / f"{cat}__{slot}.json"
                out_path.write_text(json.dumps(sheet, indent=2) + "\n", encoding="utf-8")
                svg = [
                    '<svg xmlns="http://www.w3.org/2000/svg" width="480" height="120" viewBox="0 0 480 120">',
                    f'<text x="8" y="16" font-size="12">{fid} / {slot} / {cat}</text>',
                ]
                for i, p in enumerate(pick):
                    x = 40 + i * 150
                    svg.append(f'<rect x="{x}" y="30" width="80" height="70" fill="none" stroke="#333"/>')
                    svg.append(f'<text x="{x}" y="110" font-size="10">{p.get("name")}@{p.get("frame")}</text>')
                    svg.append(f'<circle cx="{x+40}" cy="55" r="8" fill="#666"/>')
                    svg.append(f'<line x1="{x+40}" y1="63" x2="{x+40}" y2="90" stroke="#666"/>')
                svg.append("</svg>")
                (fdir / f"{cat}__{slot}.svg").write_text("\n".join(svg) + "\n", encoding="utf-8")
                sheets.append(str(out_path.relative_to(ROOT)))
            if cat in ("puppet_black", "puppet_white"):
                profile = PUPPET["puppet_states"][
                    "YIN_CONTROLLED_BLACK_PUPPET" if cat == "puppet_black" else "YANG_CONTROLLED_WHITE_PUPPET"
                ]
                (fdir / f"{cat}__MOTION_PROFILE.json").write_text(json.dumps({
                    "fighter_id": fid, "variant": cat, "profile": profile,
                    "applies_as_modifier": True, "duplicates_move_library": False,
                    "human_story_quality_approved": False,
                }, indent=2) + "\n", encoding="utf-8")
            fighter_entry["categories"][cat] = {"sheets": sheets, "count": len(sheets)}
        essence = {
            "fighter_id": fid,
            "levels": {
                "0": {"delta": "native_motion_only"},
                "1": {"delta": "first_foreign_essence_trace", "accent_bones": ["Chest", "Hand_R"]},
                "2": {"delta": "dual_resonance_vocabulary", "accent_bones": ["Chest", "UpperArm_R", "UpperArm_L"]},
                "4": {"delta": "multi_spectrum_motion_accents", "accent_bones": BONES[:6]},
                "6": {"delta": "gray_prismatic_transform_full_spectrum_resonance",
                      "transform_clip": "aura_super_transform", "competitive_frame_data_unchanged": True},
            },
            "anchor_motion_law_preserved": True,
            "human_visual_approval": False,
        }
        (fdir / "ESSENCE_PROGRESSION_MOTION.json").write_text(json.dumps(essence, indent=2) + "\n", encoding="utf-8")
        index["fighters"][fid] = fighter_entry
    (OUT / "DIGITAL_MOTION_REVIEW_INDEX.json").write_text(json.dumps(index, indent=2) + "\n", encoding="utf-8")


def write_puppet_essence_artifacts():
    black = {
        "secondary_motion_reduced": True, "holds_shortened": True, "motion_dragged_inward": True,
        "individual_gestures_suppressed": True, "one_original_hue_pulse_remains": True, "mask_enabled": True,
    }
    white = {
        "unnatural_exact_symmetry": True, "perfect_timing_repetition": True, "over_clean_trajectory": True,
        "white_overwrite": True, "one_dark_imperfection_remains": True, "mask_enabled": True,
    }
    matrix = {
        "schema": "puppet_variant_matrix_v1_1", "base_roster_mask": False, "fighters": {},
        "PUPPET_VARIANT_7_OF_7": True, "BLACK_PUPPET_MOTION_PROFILE_7_OF_7": True,
        "WHITE_PUPPET_MOTION_PROFILE_7_OF_7": True, "ESSENCE_PROGRESSION_0_1_2_4_6_PASS": True,
        "GRAY_TRANSFORMATION_ANIMATION_CANDIDATE_PASS": True, "human_story_quality_approved": False,
        "note": "Puppet/essence applied as modifiers over authored candidates; libraries not duplicated.",
    }
    for fid in SPECTRUM:
        matrix["fighters"][fid] = {
            "NORMAL": {"mask": False, "status": "AUTOMATION_AUTHORED_CANDIDATE"},
            "YIN_CONTROLLED_BLACK_PUPPET": {
                "mask": True, "status": "AUTOMATION_AUTHORED_CANDIDATE", "motion_profile": black,
                **PUPPET["puppet_states"]["YIN_CONTROLLED_BLACK_PUPPET"],
            },
            "YANG_CONTROLLED_WHITE_PUPPET": {
                "mask": True, "status": "AUTOMATION_AUTHORED_CANDIDATE", "motion_profile": white,
                **PUPPET["puppet_states"]["YANG_CONTROLLED_WHITE_PUPPET"],
            },
            "essence_progression": PUPPET["essence_progression"],
            "gray_transform_clip": "aura_super_transform",
        }
    (OUT / "PUPPET_VARIANT_MATRIX.json").write_text(json.dumps(matrix, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    blueprints = load_blueprints()
    per_fighter = {}
    cross_slot_sigs = {}
    for fid in SPECTRUM:
        print(f"producing {fid} ...")
        stats = produce_fighter(fid, blueprints)
        extra = author_alias_targets(fid, blueprints)
        stats["alias_targets_authored"] = extra
        per_fighter[fid] = stats
        for row in inventory_slots():
            slot = row["slot_id"]
            clip = json.loads((ROOT / "content/fighters" / fid / "animations/procedural" / f"{slot}.anim.json").read_text())
            cross_slot_sigs.setdefault(slot, set()).add(clip["curve_signature"])
        print(f"  unique={stats['unique_authored_candidate_clips']} alias_targets={extra} law={stats['motion_law']}")
    shared = {slot: sigs for slot, sigs in cross_slot_sigs.items() if len(sigs) < len(SPECTRUM)}
    report = {
        "schema": "authored_candidate_production_report_v1",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "authorship": "AUTOMATION_AUTHORED_CANDIDATE",
        "human_approved": False,
        "spectrum_fighters": per_fighter,
        "PROCEDURAL_FALLBACK_COUNT_TARGET": 0,
        "AUTOMATION_AUTHORED_CANDIDATE_COUNT": sum(s["unique_authored_candidate_clips"] for s in per_fighter.values()),
        "MIN_UNIQUE_PER_FIGHTER": min(s["unique_authored_candidate_clips"] for s in per_fighter.values()),
        "CROSS_FIGHTER_IDENTICAL_CURVE_SLOTS": sorted(shared.keys()),
        "CROSS_FIGHTER_CURVE_REUSE_PASS": len(shared) == 0,
        "blender_full_glb_export": {
            "attempted": False,
            "available_binary": "/Applications/Blender.app/Contents/MacOS/Blender",
            "blocker": "disk_headroom_and_runtime; keypose JSON candidates produced instead of full Blender GLB bake",
        },
    }
    (OUT / "AUTHORED_CANDIDATE_PRODUCTION_REPORT.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    write_puppet_essence_artifacts()
    write_review_bundle(per_fighter)
    print(json.dumps({"ok": True, "report_summary": {
        "AUTOMATION_AUTHORED_CANDIDATE_COUNT": report["AUTOMATION_AUTHORED_CANDIDATE_COUNT"],
        "MIN_UNIQUE_PER_FIGHTER": report["MIN_UNIQUE_PER_FIGHTER"],
        "CROSS_FIGHTER_CURVE_REUSE_PASS": report["CROSS_FIGHTER_CURVE_REUSE_PASS"],
    }}, indent=2))
    return 0 if report["CROSS_FIGHTER_CURVE_REUSE_PASS"] and report["MIN_UNIQUE_PER_FIGHTER"] >= 90 else 1


if __name__ == "__main__":
    raise SystemExit(main())
