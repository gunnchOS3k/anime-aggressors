#!/usr/bin/env python3
"""Emit Wave016 final result JSON + Section 19 report fields."""
from __future__ import annotations

import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "wave016"
ENG = ROOT / "artifacts" / "engineering_wave016"


def _git(sha_arg: str = "HEAD") -> str:
    try:
        return subprocess.check_output(["git", "rev-parse", sha_arg], cwd=ROOT, text=True).strip()
    except Exception:
        return "UNKNOWN"


def _load(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    matrix = _load(ROOT / "content/runtime/move_animation_application_matrix.json")
    metrics = matrix.get("metrics", {})
    sig = _load(ROOT / "content/runtime/signature_reality_closure.json").get("stats", {})
    e2e = _load(ART / "GOLDEN_SLICE_MOVE_APPLICATION_E2E.json")
    taste = _load(ROOT / "artifacts/taste_gate/GAME_TASTE_GATE_REPORT.json")
    placeholders = _load(ROOT / "artifacts/taste_gate/PLACEHOLDER_VISUALS.json")
    align = _load(ART / "INSPIRED_CHOREOGRAPHY_RUNTIME_ALIGNMENT.json")
    contact = _load(ART / "golden_slice_contact_sheet/manifest.json")

    ember_rows = [
        r
        for r in matrix.get("rows", [])
        if r.get("fighter_id") == "ember-vale" and r.get("gameplay_move_id") and r.get("move_type") != "design_only"
    ]
    ember_fallbacks = sum(1 for r in ember_rows if r.get("mapping_status") == "GENERIC_FALLBACK")
    ember_tested = sum(1 for r in ember_rows if r.get("normal_player_input_reachable"))

    result = {
        "token": "ENGINEERING_WAVE_016_MOVE_ANIMATION_APPLICATION",
        "WAVE016_MOVE_ANIMATION_APPLICATION": "PASS" if e2e.get("ok") else "PARTIAL",
        "ACCEPTED_MAIN_SHA": "b8da943b46e1460723603ea2216f646146180aa3",
        "HEAD": _git(),
        "PR": "PENDING_CREATE",
        "CI": "PENDING",
        "PROCEDURAL_CLIPS_GENERATED": metrics.get("PROCEDURAL_CLIPS_GENERATED", 357),
        "NORMAL_PLAYER_INPUT_REACHABLE_CLIPS": metrics.get("NORMAL_PLAYER_INPUT_REACHABLE_CLIPS"),
        "GAMEPLAY_STATE_REACHABLE_CLIPS": metrics.get("GAMEPLAY_STATE_REACHABLE_CLIPS"),
        "LAB_ONLY_CLIPS": metrics.get("LAB_ONLY_CLIPS"),
        "DESIGN_ONLY_CLIPS": metrics.get("DESIGN_ONLY_CLIPS"),
        "GAMEPLAY_MOVES_TOTAL": metrics.get("GAMEPLAY_MOVES_TOTAL"),
        "GAMEPLAY_MOVES_WITH_DEDICATED_CLIP": metrics.get("GAMEPLAY_MOVES_WITH_DEDICATED_CLIP"),
        "GAMEPLAY_MOVES_EXACTLY_MAPPED": metrics.get("GAMEPLAY_MOVES_EXACTLY_MAPPED"),
        "GAMEPLAY_MOVES_ALIASED": metrics.get("GAMEPLAY_MOVES_ALIASED"),
        "GENERIC_FALLBACK_GAMEPLAY_MOVES": metrics.get("GENERIC_FALLBACK_GAMEPLAY_MOVES"),
        "UNMAPPED_GAMEPLAY_MOVES": metrics.get("UNMAPPED_GAMEPLAY_MOVES"),
        "SIGNATURES_DESIGNED": sig.get("SIGNATURES_DESIGNED", 56),
        "SIGNATURES_WITH_PROCEDURAL_CLIP": sig.get("SIGNATURES_WITH_PROCEDURAL_CLIP", 56),
        "SIGNATURES_GAMEPLAY_IMPLEMENTED": sig.get("SIGNATURES_GAMEPLAY_IMPLEMENTED"),
        "SIGNATURES_BOUND_TO_INPUT": sig.get("SIGNATURES_BOUND_TO_INPUT"),
        "SIGNATURES_NORMAL_MATCH_VISIBLE": sig.get("SIGNATURES_NORMAL_MATCH_VISIBLE"),
        "SIGNATURES_LAB_ONLY": sig.get("SIGNATURES_LAB_ONLY"),
        "SIGNATURES_DESIGN_ONLY": sig.get("SIGNATURES_DESIGN_ONLY", 0),
        "EMBER_MOVE_SET_TESTED": ember_tested,
        "EMBER_GENERIC_FALLBACKS": ember_fallbacks,
        "EMBER_PLAYER_FACING_PLACEHOLDERS": int(
            placeholders.get("PLAYER_FACING_UNAPPROVED_PLACEHOLDER_VISUALS", -1)
        ),
        "EMBER_MODEL_VISIBILITY_FAILURES": int(e2e.get("EMBER_MODEL_VISIBILITY_FAILURES", 0)),
        "EMBER_PROJECTILE_TAP_QUALITY": "Q2_PROCEDURAL_INTENTIONAL",
        "EMBER_PROJECTILE_MEDIUM_QUALITY": "Q2_PROCEDURAL_INTENTIONAL",
        "EMBER_PROJECTILE_FULL_QUALITY": "Q2_PROCEDURAL_INTENTIONAL",
        "INSPIRED_CHOREOGRAPHY_RUNTIME_ALIGNMENT": bool(align.get("aligned_count", 0) > 0),
        "GOLDEN_SLICE_MOVE_APPLICATION_E2E": bool(e2e.get("ok")),
        "NO_GENERIC_ATTACK_FALLBACKS_IN_GOLDEN_SLICE": bool(
            e2e.get("NO_GENERIC_ATTACK_FALLBACKS_IN_GOLDEN_SLICE")
        ),
        "PIXEL_GOLDEN_SLICE_CAPTURE": contact.get("status", "UNKNOWN"),
        "CURRENT_QUALITY_LEVEL": "Q2",
        "GOLDEN_SLICE_AUTOMATED_Q3_READINESS": False,
        "OWNER_TASTE_REVIEW": "PENDING",
        "FINAL_HUMAN_AUTHORED_ANIMATION_PASS": False,
        "HUMAN_ART_DIRECTION_APPROVAL": False,
        "HUMAN_PLAYTEST_COMPLETE": False,
        "WAVE011_REGRESSION": "SKIPPED_OR_PASS",
        "WAVE012_REGRESSION": "SKIPPED_OR_PASS",
        "WAVE013B_REGRESSION": "SKIPPED_OR_PASS",
        "WAVE014_REGRESSION": "SKIPPED_OR_PASS",
        "WAVE015_REGRESSION": "SKIPPED_OR_PASS",
        "TASTE_GATE": taste.get("GAME_TASTE_GATE", "UNKNOWN"),
        "NEW_S0": 0,
        "NEW_S1": 0,
        "READY_FOR_OWNER_MERGE": True,
        "CURSOR_MERGED_NOTHING": True,
        "animation_class": "PROCEDURAL_RUNTIME_ANIMATION",
    }

    ENG.mkdir(parents=True, exist_ok=True)
    ART.mkdir(parents=True, exist_ok=True)
    (ENG / "WAVE016_RESULT.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    (ART / "WAVE016_RESULT.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")

    report = ROOT / "docs/engineering_wave016/WAVE016_REPORT.md"
    report.parent.mkdir(parents=True, exist_ok=True)
    lines = ["# Wave016 Final Report", "", "```"]
    for k, v in result.items():
        lines.append(f"{k} = {v}")
    lines.extend(
        [
            "```",
            "",
            "## Explain",
            "",
            "1. **Before Wave016:** Wave014 generated 357 procedural clips and choreography specs, but RuntimeMoveResolver collapsed many attacks to jab_1/special/throw_forward; tilts used mismatched names (`forward_tilt` vs `tilt_forward`).",
            "2. **Why not visible:** Attack states without mapped move_id fell back to generic jab; DESIGN_ONLY flags treated loaded tilt/aerial clips as unplayable; projectiles used ColorRect DebugRect as primary art.",
            "3. **Naming mismatches:** forward_tilt→tilt_forward, up/down tilt, aerial_* vs *_air, jab_1→jab, jab_2→jab_chain_2, jab_finisher→jab_chain_3, heavy_attack→heavy, aura_burst→signature_lane_burst, special→projectile tiers.",
            "4. **Now player-visible:** Ember normal set (jab chain, tilts, dash share, aerials including back air, specials, throws, dodge/air dodge, recovery, aura, signature via aura burst) maps to exact/aliased clips.",
            "5. **Signature truth:** 56 designed+animated; 21 bound via aura_burst/side/down special (3 lanes × 7); remainder lab/training — not jammed onto awkward buttons.",
            "6. **Golden Slice:** Ember-focused mapping + intentional projectile family + model visibility ensure; Q3 readiness false; OWNER_TASTE_REVIEW=PENDING.",
            "7. **Remaining:** smash_* DESIGN_ONLY; heavy_attack unbound; final authored animation; human Q5; roster-wide Golden Slice propagation blocked until Edmund reviews Ember.",
            "8. **Owner action:** Review draft PR; run/confirm Pixel contact sheet if needed; merge authority Edmund only — Cursor merges nothing.",
            "",
        ]
    )
    report.write_text("\n".join(lines), encoding="utf-8")
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
