#!/usr/bin/env python3
"""Semantic motion-distance validation — curve hashes alone are insufficient."""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "artifacts/animation_authority_v1"
SPECTRUM = [
    "ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
    "nix-calder", "orion-vell", "vesper-nyx",
]
INV = json.loads((ROOT / "data/bibles/animation_inventory_v1.json").read_text(encoding="utf-8"))
ALIAS_MAP = json.loads((ROOT / "game-godot/data/runtime/move_clip_alias_map.json").read_text(encoding="utf-8"))
DOC_ALIASES = ALIAS_MAP.get("documented_semantic_aliases") or {}

# Thresholds (radians / frames) — meaningful visual separation, not micro-hash noise.
THRESH = {
    "rms_distinct": 0.08,
    "max_distinct": 0.22,
    "duration_distinct": 2,
    "timing_distinct": 2,
    "identical_rms": 0.012,
    "near_rms": 0.08,
    "near_max": 0.22,
}

BONES = [
    "Spine", "Chest", "UpperArm_R", "LowerArm_R", "Hand_R",
    "UpperArm_L", "LowerArm_L", "UpperLeg_R", "LowerLeg_R", "UpperLeg_L", "LowerLeg_L",
]


def slots() -> list[dict[str, Any]]:
    rows = []
    for cat in INV["categories"]:
        for s in cat["slots"]:
            rows.append({"category": cat["id"], "slot_id": s["id"], "may_alias": bool(s.get("may_alias", False))})
    return rows


def load_clip(fid: str, name: str) -> dict | None:
    p = ROOT / "content/fighters" / fid / "animations/procedural" / f"{name}.anim.json"
    if not p.is_file():
        return None
    return json.loads(p.read_text(encoding="utf-8"))


def pose_frame(clip: dict, names: tuple[str, ...]) -> int | None:
    for pose in clip.get("key_poses") or []:
        if pose.get("name") in names:
            return int(pose.get("frame", 0))
    return None


def angular_stats(a: dict, b: dict) -> tuple[float, float]:
    vals = []
    max_abs = 0.0
    for bone in BONES:
        ka = a.get("bone_tracks", {}).get(bone) or []
        kb = b.get("bone_tracks", {}).get(bone) or []
        n = min(len(ka), len(kb))
        for i in range(n):
            for j in range(3):
                d = float(ka[i]["rotation_rad"][j]) - float(kb[i]["rotation_rad"][j])
                vals.append(d * d)
                max_abs = max(max_abs, abs(d))
    rms = math.sqrt(sum(vals) / len(vals)) if vals else 0.0
    return rms, max_abs


def classify_pair(fid: str, sa: str, sb: str, ca: dict, cb: dict, may_alias_a: bool, may_alias_b: bool) -> dict:
    rms, max_d = angular_stats(ca, cb)
    dur_d = abs(int(ca.get("duration_frames", 0)) - int(cb.get("duration_frames", 0)))
    antic_a = pose_frame(ca, ("anticipation", "loop_a", "intent")) or 0
    antic_b = pose_frame(cb, ("anticipation", "loop_a", "intent")) or 0
    contact_a = pose_frame(ca, ("contact", "apex")) or 0
    contact_b = pose_frame(cb, ("contact", "apex")) or 0
    follow_a = pose_frame(ca, ("follow", "recovery", "hold")) or 0
    follow_b = pose_frame(cb, ("follow", "recovery", "hold")) or 0
    timing_d = max(abs(antic_a - antic_b), abs(contact_a - contact_b), abs(follow_a - follow_b))
    root_a = (ca.get("root_motion_policy") or {}).get("style")
    root_b = (cb.get("root_motion_policy") or {}).get("style")
    def_a = ((ca.get("screen_space_deformation") or {}).get("smear_geometry"))
    def_b = ((cb.get("screen_space_deformation") or {}).get("smear_geometry"))
    ev_a = tuple(sorted((e.get("type"), e.get("id")) for e in (ca.get("events") or [])))
    ev_b = tuple(sorted((e.get("type"), e.get("id")) for e in (cb.get("events") or [])))

    justified = False
    justification = None
    for slot, meta in DOC_ALIASES.items():
        alias_of = meta.get("alias_of")
        if {slot, alias_of} == {sa, sb}:
            justified = True
            justification = meta.get("justification")
            break
    if may_alias_a or may_alias_b:
        # directional pairs sharing family may be justified even without exact DOC entry if one aliases other
        if sa.replace("_forward", "").replace("_back", "").replace("_up", "").replace("_down", "") == \
           sb.replace("_forward", "").replace("_back", "").replace("_up", "").replace("_down", ""):
            if "air_dodge" in sa and "air_dodge" in sb:
                justified = True
                justification = justification or "Directional air-dodge family; inventory may_alias"

    meaningful = (
        rms >= THRESH["rms_distinct"]
        or max_d >= THRESH["max_distinct"]
        or dur_d >= THRESH["duration_distinct"]
        or timing_d >= THRESH["timing_distinct"]
        or root_a != root_b
        or def_a != def_b
        or ev_a != ev_b
    )

    if ca.get("curve_signature") == cb.get("curve_signature") or rms <= THRESH["identical_rms"]:
        status = "JUSTIFIED_ALIAS" if justified else "IDENTICAL_REQUIRES_ALIAS_OR_FIX"
    elif not meaningful and rms < THRESH["near_rms"] and max_d < THRESH["near_max"]:
        status = "JUSTIFIED_ALIAS" if justified else "NEAR_DUPLICATE_REQUIRES_FIX"
    else:
        status = "MEANINGFULLY_DISTINCT"

    return {
        "fighter_id": fid,
        "slot_a": sa,
        "slot_b": sb,
        "status": status,
        "rms": round(rms, 5),
        "max_angular": round(max_d, 5),
        "duration_delta": dur_d,
        "timing_delta": timing_d,
        "anticipation_frames": [antic_a, antic_b],
        "contact_frames": [contact_a, contact_b],
        "follow_frames": [follow_a, follow_b],
        "root_motion": [root_a, root_b],
        "deformation": [def_a, def_b],
        "justification": justification,
    }


def cross_fighter_slot(slot_id: str) -> dict:
    clips = {fid: load_clip(fid, slot_id) for fid in SPECTRUM}
    pairwise = {}
    generic_reuse = 0
    for i, a in enumerate(SPECTRUM):
        for b in SPECTRUM[i + 1 :]:
            ca, cb = clips[a], clips[b]
            if not ca or not cb:
                pairwise[f"{a}__vs__{b}"] = {"status": "MISSING"}
                continue
            rms, max_d = angular_stats(ca, cb)
            # Same law-family template reuse if nearly identical across fighters
            same = rms < THRESH["near_rms"] and max_d < THRESH["near_max"]
            if same and (ca.get("elemental_anatomy") == cb.get("elemental_anatomy") or
                         (ca.get("runtime_alignment") or {}).get("motion_law") == (cb.get("runtime_alignment") or {}).get("motion_law")):
                # Same motion_law string is expected to differ by fighter — if RMS still tiny, it's generic reuse
                pass
            if same:
                generic_reuse += 1
                status = "GENERIC_TEMPLATE_REUSE"
            else:
                status = "DIFFERENTIATED"
            pairwise[f"{a}__vs__{b}"] = {
                "status": status,
                "rms": round(rms, 5),
                "max_angular": round(max_d, 5),
                "laws": [
                    (ca.get("runtime_alignment") or {}).get("motion_law"),
                    (cb.get("runtime_alignment") or {}).get("motion_law"),
                ],
                "anatomy": [ca.get("elemental_anatomy"), cb.get("elemental_anatomy")],
                "root": [
                    (ca.get("root_motion_policy") or {}).get("style"),
                    (cb.get("root_motion_policy") or {}).get("style"),
                ],
            }
    return {"slot_id": slot_id, "pairwise": pairwise, "generic_reuse_pairs": generic_reuse}


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    slot_rows = slots()
    slot_ids = [r["slot_id"] for r in slot_rows]
    may = {r["slot_id"]: r["may_alias"] for r in slot_rows}

    matrix = {
        "schema": "semantic_motion_distance_matrix_v1",
        "thresholds": THRESH,
        "note": "Exact curve_signature uniqueness is not sufficient; angular/timing/policy distance required.",
        "fighters": {},
    }
    near = []
    unjustified = 0

    # Compare within family / category expected-distinct pairs (all pairs would be huge;
    # focus same-category pairs + move set + locomotion set).
    categories: dict[str, list[str]] = {}
    for r in slot_rows:
        categories.setdefault(r["category"], []).append(r["slot_id"])

    for fid in SPECTRUM:
        fighter_pairs = []
        for cat, cat_slots in categories.items():
            for i, sa in enumerate(cat_slots):
                for sb in cat_slots[i + 1 :]:
                    ca, cb = load_clip(fid, sa), load_clip(fid, sb)
                    if not ca or not cb:
                        continue
                    row = classify_pair(fid, sa, sb, ca, cb, may.get(sa, False), may.get(sb, False))
                    fighter_pairs.append(row)
                    if row["status"] in ("NEAR_DUPLICATE_REQUIRES_FIX", "IDENTICAL_REQUIRES_ALIAS_OR_FIX"):
                        near.append(row)
                        unjustified += 1
        matrix["fighters"][fid] = {
            "pair_count": len(fighter_pairs),
            "by_status": {},
        }
        for row in fighter_pairs:
            st = row["status"]
            matrix["fighters"][fid]["by_status"][st] = matrix["fighters"][fid]["by_status"].get(st, 0) + 1

    matrix["UNJUSTIFIED_NEAR_DUPLICATE_COUNT"] = unjustified
    (OUT / "SEMANTIC_MOTION_DISTANCE_MATRIX.json").write_text(json.dumps(matrix, indent=2) + "\n", encoding="utf-8")
    (OUT / "NEAR_DUPLICATE_CANDIDATES.json").write_text(
        json.dumps({"schema": "near_duplicate_candidates_v1", "count": len(near), "rows": near[:500]}, indent=2) + "\n",
        encoding="utf-8",
    )

    # Cross-fighter visual differentiation for representative slots
    probe_slots = [
        "idle_primary", "walk_loop", "run_loop", "dash_loop", "jump", "land_hard",
        "jab_1", "heavy_attack", "neutral_air", "back_air", "aura_burst", "hurt_heavy",
    ]
    cross = {
        "schema": "cross_fighter_visual_differentiation_v1",
        "motion_laws": {
            "ember-vale": "combustion", "rook-ironside": "mass", "juno-spark": "current",
            "kaia-windrow": "flow", "nix-calder": "structure", "orion-vell": "vectors",
            "vesper-nyx": "uncertainty",
        },
        "axes": [
            "center_of_gravity", "stride", "anticipation", "cadence", "torso_posture",
            "arm_path", "air_posture", "landing", "deformation", "event_vfx_family",
        ],
        "slots": {},
    }
    generic_total = 0
    for slot in probe_slots:
        entry = cross_fighter_slot(slot)
        cross["slots"][slot] = entry
        generic_total += entry["generic_reuse_pairs"]
        # Axis evidence from clip metadata
        axis_rows = {}
        for fid in SPECTRUM:
            clip = load_clip(fid, slot)
            if not clip:
                continue
            axis_rows[fid] = {
                "center_of_gravity": (clip.get("root_motion_policy") or {}).get("style"),
                "stride": (clip.get("runtime_alignment") or {}).get("timing"),
                "anticipation": pose_frame(clip, ("anticipation", "loop_a")),
                "cadence": clip.get("duration_frames"),
                "torso_posture": ((clip.get("bone_tracks") or {}).get("Spine") or [{}])[0].get("rotation_rad"),
                "arm_path": ((clip.get("bone_tracks") or {}).get("UpperArm_R") or [{}])[min(2, len((clip.get("bone_tracks") or {}).get("UpperArm_R") or [{}])-1)].get("rotation_rad"),
                "air_posture": (clip.get("root_motion_policy") or {}).get("style"),
                "landing": pose_frame(clip, ("contact", "recovery")),
                "deformation": (clip.get("screen_space_deformation") or {}).get("smear_geometry"),
                "event_vfx_family": [e.get("id") for e in (clip.get("events") or []) if e.get("type") == "vfx"],
                "elemental_anatomy": clip.get("elemental_anatomy"),
                "motion_law": (clip.get("runtime_alignment") or {}).get("motion_law"),
            }
        cross["slots"][slot]["axis_evidence"] = axis_rows
    cross["CROSS_FIGHTER_GENERIC_TEMPLATE_REUSE_COUNT"] = generic_total
    (OUT / "CROSS_FIGHTER_VISUAL_DIFFERENTIATION.json").write_text(json.dumps(cross, indent=2) + "\n", encoding="utf-8")

    print(
        f"UNJUSTIFIED_NEAR_DUPLICATE_COUNT={unjustified} "
        f"CROSS_FIGHTER_GENERIC_TEMPLATE_REUSE_COUNT={generic_total}"
    )
    if unjustified > 0 or generic_total > 0:
        print(f"sample near: {near[:5]}", file=sys.stderr)
        return 1
    print("PASS audit_semantic_motion_distance")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
