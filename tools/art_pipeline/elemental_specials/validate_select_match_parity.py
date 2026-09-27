#!/usr/bin/env python3
"""Select / preview / match elemental identity parity. Never promotes owner gates."""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
FIGHTER_IDS = (
    "ember-vale",
    "rook-ironside",
    "juno-spark",
    "kaia-windrow",
    "nix-calder",
    "orion-vell",
    "vesper-nyx",
)
ROYGBIV_ORDER = list(FIGHTER_IDS)
MIN_HUE_GAP = 14.0


def load_json(path: Path) -> dict:
    if not path.is_file():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def text(rel: str) -> str:
    path = ROOT / rel
    return path.read_text(encoding="utf-8") if path.is_file() else ""


def hue_gap(a: float, b: float) -> float:
    d = abs(a - b) % 360.0
    return min(d, 360.0 - d)


def evaluate() -> dict:
    failures: list[str] = []
    data = load_json(ROOT / "game-godot/data/runtime/elemental_material_language.json")
    fighters = data.get("fighters", {})
    contract = text("game-godot/scripts/visual/elemental_material_contract.gd")
    profile = text("game-godot/scripts/fighters/fighter_presentation_profile.gd")
    select = text("game-godot/scripts/menus/fighter_select_scene.gd")
    portrait = text("game-godot/scripts/ui/fighter_card_portrait.gd")
    model = text("game-godot/scripts/fighters/fighter_model_3d.gd")
    review = text("game-godot/scripts/labs/full_roster_art_review_scene.gd")
    shader = text("game-godot/shaders/fighter_toon.gdshader")

    source_ok = (
        data.get("source_of_truth") is True
        and "identity_colors" in contract
        and "apply_to_root" in contract
        and "identity_colors" in profile
        and "identity_colors" in select
        and "identity_colors" in portrait
        and "_presentation_context" in model
        and "set_presentation_context" in review
    )
    if not source_ok:
        failures.append("select_preview_source_of_truth_incomplete")

    parity_ok = (
        "SELECT_PREVIEW" in contract
        and "is_preview_context" in contract
        and "apply_to_root(root, _fighter_id, _charge_level, _vfx_enabled, _presentation_context)" in model
        and "_apply_identity_lighting" in model
        and "_apply_tile_identity_chrome" in select
    )
    if not parity_ok:
        failures.append("select_match_parity_wiring_incomplete")

    hues = []
    families = []
    style = data.get("style", {})
    translucent_ok = (
        style.get("translucent_body") is True
        and float(style.get("body_alpha_min", 0)) >= 0.70
        and float(style.get("body_alpha_max", 1)) <= 0.90
        and "body_alpha" in shader
        and "blend_mix" in shader
    )
    if not translucent_ok:
        failures.append("translucent_body_style_incomplete")

    bible_ok = True
    for fid in FIGHTER_IDS:
        entry = fighters.get(fid, {})
        for key in ("core", "structure", "accent", "emission", "rim", "family_hue_deg", "bible_detail", "tile_primary"):
            if key not in entry:
                failures.append(f"identity_missing:{fid}:{key}")
                bible_ok = False
        hues.append(float(entry.get("family_hue_deg", 0)))
        families.append(str(entry.get("roygbiv_family", "")))
        if len(str(entry.get("bible_detail", ""))) < 24:
            failures.append(f"bible_detail_thin:{fid}")
            bible_ok = False
    if data.get("roygbiv_order") != ROYGBIV_ORDER:
        failures.append("roygbiv_order_mismatch")
    spacing_ok = True
    for i in range(len(hues) - 1):
        if hues[i] >= hues[i + 1]:
            failures.append(f"roygbiv_not_increasing:{FIGHTER_IDS[i]}")
            spacing_ok = False
        if hue_gap(hues[i], hues[i + 1]) < MIN_HUE_GAP:
            failures.append(f"roygbiv_gap_too_small:{FIGHTER_IDS[i]}:{FIGHTER_IDS[i + 1]}")
            spacing_ok = False
    if len(set(families)) != 7:
        failures.append("roygbiv_family_collision")
        spacing_ok = False

    pixel_form = ROOT / "docs/playtest/SELECT_MATCH_COLOR_PARITY.md"
    pixel_ok = pixel_form.is_file() and "OWNER_REVIEW_SELECT_SCREEN_COLOR_PARITY_AND_ELEMENTAL_DETAIL" in pixel_form.read_text(
        encoding="utf-8"
    )
    if not pixel_ok:
        failures.append("pixel_select_review_form_missing")

    owner_false = {
        "OWNER_SELECT_COLOR_APPROVAL": False,
        "OWNER_MATCH_COLOR_APPROVAL": False,
        "OWNER_ROSTER_ROYGBIV_APPROVAL": False,
        "MERGE_AUTHORIZED": False,
        "HUMAN_ART_DIRECTION_APPROVAL": False,
        "HUMAN_PIXEL_REVIEW_PASS": False,
    }
    gates = {
        "SELECT_PREVIEW_SOURCE_OF_TRUTH_PASS": source_ok and not any(f.startswith("select_preview") for f in failures),
        "SELECT_MATCH_PARITY_STRUCTURAL_PASS": parity_ok,
        "ROSTER_ROYGBIV_SPACING_PASS": spacing_ok and "roygbiv_order_mismatch" not in failures,
        "TRANSLUCENT_BODY_STYLE_PASS": translucent_ok,
        "FIGHTER_ART_BIBLE_DETAIL_PASS": bible_ok,
        "PIXEL_SELECT_REVIEW_ROUTE_PASS": pixel_ok,
        **owner_false,
    }
    fighters_out = {}
    for fid in FIGHTER_IDS:
        entry = fighters.get(fid, {})
        fighters_out[fid] = {
            "element": entry.get("element"),
            "roygbiv_family": entry.get("roygbiv_family"),
            "family_hue_deg": entry.get("family_hue_deg"),
            "bible_detail": entry.get("bible_detail"),
            "select_source": "elemental_material_language.json",
            "match_source": "elemental_material_language.json",
        }
    payload = {
        "schema": "select_match_parity/v1",
        "emitted_at": datetime.now(timezone.utc).isoformat(),
        "source_of_truth": "game-godot/data/runtime/elemental_material_language.json",
        "failures": failures,
        "fighters": fighters_out,
        "hues": dict(zip(FIGHTER_IDS, hues, strict=True)),
        "gates": gates,
        "HUMAN_*": "Remain false unless a human signed.",
        "next_action": "OWNER_REVIEW_SELECT_SCREEN_COLOR_PARITY_AND_ELEMENTAL_DETAIL",
    }
    write_json(ROOT / "artifacts/elemental_identity/SELECT_MATCH_PARITY.json", payload)
    return payload


def main() -> int:
    payload = evaluate()
    structural = [
        "SELECT_PREVIEW_SOURCE_OF_TRUTH_PASS",
        "SELECT_MATCH_PARITY_STRUCTURAL_PASS",
        "ROSTER_ROYGBIV_SPACING_PASS",
        "TRANSLUCENT_BODY_STYLE_PASS",
        "FIGHTER_ART_BIBLE_DETAIL_PASS",
        "PIXEL_SELECT_REVIEW_ROUTE_PASS",
    ]
    ok = all(payload["gates"][name] for name in structural) and not payload["failures"]
    print(json.dumps({"ok": ok, "failures": payload["failures"], "gates": payload["gates"]}, indent=2))
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
