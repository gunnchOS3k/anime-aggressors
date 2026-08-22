#!/usr/bin/env python3
"""Validate choreography distinctness across roster — no generic template collisions."""
from __future__ import annotations

import json
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
CHOREO_DIR = ROOT / "content/choreography"
OUT = ROOT / "artifacts/engineering_wave013b/CHOREOGRAPHY_DISTINCTNESS_RESULT.json"

DIMENSION_KEYS = [
    ("timing", ("anticipation_frames", "active_frames", "recovery_frames", "total_frames")),
    ("root_motion", ("style", "ground_coupling", "dash_commitment")),
    ("contact", ("primary_socket", "impact_style")),
    ("camera", ("framing", "push_in", "shake_tier")),
    ("impact", ("hitstop_tier", "risk_reward")),
    ("motion", ("weight", "tempo", "arc_type")),
]


def load_specs() -> list[dict]:
    specs = []
    for path in sorted(CHOREO_DIR.glob("*/*.json")):
        if path.name in {"index.json", "action_spec.schema.json", "fighter_motion_blueprints.json"}:
            continue
        specs.append(json.loads(path.read_text(encoding="utf-8")))
    return specs


def action_key(spec: dict) -> str:
    return spec["action_id"].split(".", 1)[1]


def extract_profile(spec: dict) -> dict:
    timing = spec.get("timing", {})
    mg = spec.get("motion_grammar", {})
    cam = spec.get("camera", {})
    imp = spec.get("impact", {})
    ra = spec.get("runtime_alignment", {})
    return {
        "timing": tuple(timing.get(k) for k in ("anticipation_frames", "active_frames", "recovery_frames", "total_frames")),
        "root_motion": (ra.get("root_motion_style"), ra.get("ground_coupling")),
        "contact": tuple(mg.get("contact_points", [])),
        "camera": (cam.get("framing"), cam.get("push_in"), cam.get("shake_tier")),
        "impact": (imp.get("hitstop_tier"), imp.get("risk_reward")),
        "motion": (mg.get("weight"), mg.get("tempo"), mg.get("arc_type")),
        "cancel": tuple(timing.get("cancel_windows", [])),
    }


def count_dimension_diffs(a: dict, b: dict) -> int:
    diffs = 0
    for _, keys in DIMENSION_KEYS:
        if a.get("timing") != b.get("timing") and "timing" in str(keys):
            pass
    for dim in ("timing", "root_motion", "contact", "camera", "impact", "motion", "cancel"):
        if a.get(dim) != b.get(dim):
            diffs += 1
    return diffs


def main() -> int:
    specs = load_specs()
    by_action: dict[str, list[dict]] = defaultdict(list)
    for spec in specs:
        by_action[action_key(spec)].append(spec)

    generic_collisions = 0
    identical_timing_profiles = 0
    identical_signature_contracts = 0
    cross_fighter_failures: list[str] = []

    placeholder_pattern = ("Signature Lane", " 43", " 42", " 41")

    for spec in specs:
        name = spec.get("display_name", "") + spec.get("original_move_name", "")
        if any(p in name for p in placeholder_pattern):
            generic_collisions += 1

    timing_by_fighter: dict[str, tuple] = {}
    for spec in specs:
        if spec.get("category") == "movement" and spec.get("action_id", "").endswith(".idle"):
            fid = spec["fighter_id"]
            timing_by_fighter[fid] = extract_profile(spec)["timing"]
    if len(set(timing_by_fighter.values())) < len(timing_by_fighter):
        identical_timing_profiles = len(timing_by_fighter) - len(set(timing_by_fighter.values()))

    sig_contracts: dict[str, list] = defaultdict(list)
    for spec in specs:
        if spec.get("category") == "signature":
            sig_contracts[spec.get("display_name")].append(spec["fighter_id"])
    for name, fighters in sig_contracts.items():
        if len(fighters) > 1:
            identical_signature_contracts += 1

    for act_key, group in by_action.items():
        if len(group) < 2:
            continue
        profiles = [extract_profile(s) for s in group]
        for i in range(len(profiles)):
            for j in range(i + 1, len(profiles)):
                if count_dimension_diffs(profiles[i], profiles[j]) < 3:
                    cross_fighter_failures.append(f"{act_key}:{group[i]['fighter_id']}vs{group[j]['fighter_id']}")

    out = {
        "checked_specs": len(specs),
        "GENERIC_TEMPLATE_COLLISIONS": generic_collisions,
        "IDENTICAL_TIMING_PROFILES_ACROSS_ROSTER": identical_timing_profiles,
        "IDENTICAL_SIGNATURE_MOVE_CONTRACTS": identical_signature_contracts,
        "cross_fighter_dimension_failures": len(cross_fighter_failures),
        "cross_fighter_failures_sample": cross_fighter_failures[:10],
        "pass": (
            generic_collisions == 0
            and identical_timing_profiles == 0
            and identical_signature_contracts == 0
            and len(cross_fighter_failures) == 0
        ),
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    return 0 if out["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
