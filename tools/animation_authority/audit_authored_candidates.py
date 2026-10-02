#!/usr/bin/env python3
"""Validate automation-authored candidate provenance, uniqueness, key poses, and 777/168 coverage."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SPECTRUM = [
    "ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
    "nix-calder", "orion-vell", "vesper-nyx",
]
INV = json.loads((ROOT / "data/bibles/animation_inventory_v1.json").read_text(encoding="utf-8"))
LIVE_MOVES = [
    "jab_1", "jab_2", "jab_finisher", "forward_tilt", "up_tilt", "down_tilt",
    "dash_attack", "heavy_attack", "neutral_air", "forward_air", "back_air",
    "up_air", "down_air", "neutral_special_projectile", "side_special",
    "up_special_recovery", "down_special", "grab", "throw_forward", "throw_back",
    "throw_up", "throw_down", "aura_charge", "aura_burst",
]


def slots() -> list[str]:
    return [s["id"] for c in INV["categories"] for s in c["slots"]]


def load_clip(fid: str, name: str) -> dict | None:
    p = ROOT / "content/fighters" / fid / "animations/procedural" / f"{name}.anim.json"
    if not p.is_file():
        return None
    return json.loads(p.read_text(encoding="utf-8"))


def main() -> int:
    errors: list[str] = []
    unique_counts: dict[str, int] = {}
    per_slot_sigs: dict[str, set[str]] = {}
    authored_total = 0
    procedural_total = 0

    for fid in SPECTRUM:
        sigs = set()
        for slot in slots():
            clip = load_clip(fid, slot)
            if clip is None:
                errors.append(f"{fid}/{slot}: missing clip")
                continue
            if clip.get("human_approved") is True or clip.get("human_approval") is True:
                errors.append(f"{fid}/{slot}: human_approved must be false")
            authorship = clip.get("authorship") or clip.get("authority_status")
            if authorship != "AUTOMATION_AUTHORED_CANDIDATE":
                procedural_total += 1
                errors.append(f"{fid}/{slot}: expected AUTOMATION_AUTHORED_CANDIDATE got {authorship}")
                continue
            authored_total += 1
            poses = clip.get("key_poses") or []
            if len(poses) < 3:
                errors.append(f"{fid}/{slot}: need >=3 explicit key poses")
            if not clip.get("provenance"):
                errors.append(f"{fid}/{slot}: missing provenance")
            if not clip.get("curve_signature"):
                errors.append(f"{fid}/{slot}: missing curve_signature")
            if clip.get("runtime_clip_id") not in (slot, clip.get("clip_name")):
                errors.append(f"{fid}/{slot}: runtime_clip_id mismatch")
            sig = clip["curve_signature"]
            if sig in sigs:
                errors.append(f"{fid}: duplicate curve_signature across slots ({slot})")
            sigs.add(sig)
            per_slot_sigs.setdefault(slot, set()).add(sig)
        unique_counts[fid] = len(sigs)
        if unique_counts[fid] < 90:
            errors.append(f"{fid}: unique authored clips {unique_counts[fid]} < 90")

    # No identical curves reused across fighters for the same slot.
    for slot, sigs in per_slot_sigs.items():
        if len(sigs) < len(SPECTRUM):
            errors.append(f"cross-fighter curve reuse on slot {slot}: only {len(sigs)} unique signatures")

    # 168 live move authorship
    for fid in SPECTRUM:
        for move in LIVE_MOVES:
            inv = {"aura_charge": "aura_charge_move", "aura_burst": "aura_burst_move"}.get(move, move)
            clip = load_clip(fid, inv) or load_clip(fid, move)
            if clip is None or clip.get("authorship") != "AUTOMATION_AUTHORED_CANDIDATE":
                errors.append(f"{fid}: move {move} not automation-authored candidate")

    # Runtime uses candidate before fallback: alias map targets must exist as authored.
    alias = json.loads((ROOT / "game-godot/data/runtime/move_clip_alias_map.json").read_text(encoding="utf-8"))
    if alias.get("move_id_to_clip", {}).get("aura_burst") != "aura_burst":
        errors.append("move_id_to_clip.aura_burst must be aura_burst (Wave016)")
    if alias.get("clip_aliases", {}).get("aura_burst") != "aura_burst":
        errors.append("clip_aliases.aura_burst must be aura_burst")

    gate = ROOT / "artifacts/animation_authority_v1/GATE_SUMMARY.json"
    if gate.is_file():
        g = json.loads(gate.read_text(encoding="utf-8"))
        for k in ("HUMAN_VISUAL_READABILITY_PASS", "HUMAN_FEEL_PASS", "FINAL_ART_APPROVED", "MERGE_AUTHORIZED"):
            if g.get(k) is True:
                errors.append(f"GATE_SUMMARY illegally flipped {k}=true")

    puppet = ROOT / "artifacts/animation_authority_v1/PUPPET_VARIANT_MATRIX.json"
    if puppet.is_file():
        p = json.loads(puppet.read_text(encoding="utf-8"))
        for key in (
            "PUPPET_VARIANT_7_OF_7",
            "BLACK_PUPPET_MOTION_PROFILE_7_OF_7",
            "WHITE_PUPPET_MOTION_PROFILE_7_OF_7",
            "ESSENCE_PROGRESSION_0_1_2_4_6_PASS",
            "GRAY_TRANSFORMATION_ANIMATION_CANDIDATE_PASS",
        ):
            if p.get(key) is not True:
                errors.append(f"puppet matrix missing/false {key}")

    review = ROOT / "artifacts/animation_authority_v1/DIGITAL_MOTION_REVIEW_INDEX.json"
    if not review.is_file():
        errors.append("DIGITAL_MOTION_REVIEW_INDEX.json missing")

    if errors:
        print("FAIL audit_authored_candidates:\n" + "\n".join(errors[:60]), file=sys.stderr)
        print(f"... total_errors={len(errors)}", file=sys.stderr)
        return 1

    print(
        "PASS audit_authored_candidates "
        f"AUTOMATION_AUTHORED_CANDIDATE_COUNT={authored_total} "
        f"PROCEDURAL_FALLBACK_COUNT={procedural_total} "
        f"unique_per_fighter={unique_counts} "
        "SPECTRUM_MOVE_ANIMATION_AUTHORED_CANDIDATE_168_OF_168=true"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
