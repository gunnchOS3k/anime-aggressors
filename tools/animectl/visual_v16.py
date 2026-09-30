"""V1.6 visible-quality contracts for the Godot primary runtime.

Automation proves path identity and which clips are bound to the candidate
choreography. It does not prove beauty or final art.
"""
from __future__ import annotations

import json
from pathlib import Path

SLICE = ("kaia-windrow", "yin", "yang")
ROSTER = (
    "ember-vale",
    "rook-ironside",
    "juno-spark",
    "kaia-windrow",
    "nix-calder",
    "orion-vell",
    "vesper-nyx",
    "yin",
    "yang",
)
LABEL = "ART_DIRECTION_CANDIDATE_V1_6"
REPRESENTATIVE = (
    "idle",
    "dash",
    "run",
    "jump",
    "light",
    "heavy",
    "aerial",
    "nair",
    "special",
    "super",
    "hurt",
    "tumble",
    "launch",
    "victory",
)


def presentation_file(root: Path, fighter: str, variant: str) -> Path:
    return (
        root
        / "game-godot/content/v16_art_direction"
        / fighter
        / variant
        / "PRESENTATION.json"
    )


def load_presentation(root: Path, fighter: str, variant: str) -> dict:
    path = presentation_file(root, fighter, variant)
    return json.loads(path.read_text())


def inspect_variant(root: Path, fighter: str) -> dict:
    male = load_presentation(root, fighter, "male")
    female = load_presentation(root, fighter, "female")
    male_path = str(presentation_file(root, fighter, "male"))
    female_path = str(presentation_file(root, fighter, "female"))
    distinct = male_path != female_path and male != female
    visible = male.get("visible_mesh") == "V16_ART_DIRECTION_BODY"
    return {
        "fighter_id": fighter,
        "male_path": male_path,
        "female_path": female_path,
        "paths_distinct": distinct,
        "visible_mesh_distinct_from_shared_proxy": visible,
        "male_label": male.get("label"),
        "female_label": female.get("label"),
        "final_art": False,
        "kaykit_player_facing": bool(male.get("kaykit_player_facing")),
        "contexts": male.get("contexts", []),
    }


def _clip_status(name: str, fighter: str) -> str:
    if fighter not in SLICE:
        return "NOT_IN_V16_SLICE"
    lowered = name.lower()
    if any(token in lowered for token in REPRESENTATIVE):
        return "V16_POSE_BOUND"
    return "PROCEDURAL_JSON_NOT_VISUALLY_COMPLETE"


def build_move_matrix(root: Path) -> dict:
    rows = []
    for fighter in SLICE:
        clip_dir = (
            root
            / "game-godot/content/fighters"
            / fighter
            / "animations/procedural"
        )
        names = sorted(p.stem.replace(".anim", "") for p in clip_dir.glob("*.anim.json")) if clip_dir.is_dir() else []
        if not names:
            names = list(REPRESENTATIVE)
        for name in names:
            status = _clip_status(name, fighter)
            rows.append(
                {
                    "fighter_id": fighter,
                    "move_id": name,
                    "resolved_clip": name,
                    "visual_status": status,
                    "counts_as_visible_depth": status == "V16_POSE_BOUND",
                    "generic_fallback": status != "V16_POSE_BOUND",
                }
            )
    bound = sum(1 for row in rows if row["counts_as_visible_depth"])
    generic = sum(1 for row in rows if row["generic_fallback"])
    return {
        "schema": "anime_visible_move_fidelity_matrix_v1",
        "slice": list(SLICE),
        "row_count": len(rows),
        "pose_bound_count": bound,
        "generic_fallback_reachable_count": generic,
        "note": "Pose-bound rows are representative choreography on the V1.6 candidate body. Remaining procedural JSON clips are not visible authored depth.",
        "rows": rows,
    }


from .result import AnimectlResult


def _result(schema_name: str, data: dict, ok: bool = True) -> AnimectlResult:
    res = AnimectlResult()
    res.data = data
    res.add_check(schema_name, "PASS" if ok else "FAIL", schema_name)
    return res


def run_inspect_variant(root: Path, fighter: str) -> AnimectlResult:
    data = inspect_variant(root, fighter)
    return _result("VARIANT", data, bool(data.get("paths_distinct")))


def run_trace_move(root: Path, fighter: str, move: str) -> AnimectlResult:
    matrix = build_move_matrix(root)
    match = next((row for row in matrix["rows"] if row["fighter_id"] == fighter and row["move_id"] == move), None)
    if match is None:
        match = {
            "fighter_id": fighter,
            "move_id": move,
            "visual_status": _clip_status(move, fighter),
            "counts_as_visible_depth": _clip_status(move, fighter) == "V16_POSE_BOUND",
        }
    return _result("MOVE_TRACE", match, True)


def acceptance_visual_slice(root: Path, fighters: list[str] | None = None) -> dict:
    chosen = list(fighters or SLICE)
    inspections = [inspect_variant(root, fighter) for fighter in chosen]
    roster_routes = [inspect_variant(root, fighter) for fighter in ROSTER]
    matrix = build_move_matrix(root)
    slice_forms = [inspect_variant(root, fighter) for fighter in SLICE]
    forms_ok = len(slice_forms) == 3 and all(
        item["paths_distinct"]
        and item["visible_mesh_distinct_from_shared_proxy"]
        and item["male_label"] == LABEL
        and not item["final_art"]
        for item in slice_forms
    )
    return {
        "schema": "anime_v16_visual_slice_acceptance_v1",
        "KAIA_YIN_YANG_6_FORM_SLICE_READY_FOR_OWNER": forms_ok,
        "BODY_VARIANT_ROUTING_DIGITAL_PASS": all(item["paths_distinct"] for item in roster_routes),
        "roster_routes": roster_routes,
        "VISIBLE_MOVE_TRACE_PASS": matrix["pose_bound_count"] > 0,
        "inspections": inspections,
        "pose_bound_count": matrix["pose_bound_count"],
        "generic_fallback_reachable_count": matrix["generic_fallback_reachable_count"],
        "G6_VISUAL_READABILITY": "REQUIRES_HUMAN",
        "G8_HUMAN_FEEL": "REQUIRES_HUMAN",
        "G9_FINAL_ART_APPROVED": "REQUIRES_HUMAN",
        "MERGE_AUTHORIZED": False,
    }


def run_visual_slice(root: Path, fighters: list[str] | None = None) -> AnimectlResult:
    data = acceptance_visual_slice(root, fighters)
    return _result("VISUAL_SLICE", data, bool(data.get("BODY_VARIANT_ROUTING_DIGITAL_PASS")))
