"""v7 polish profiles. v6 style lock + v5 loft remain the understructure."""
from __future__ import annotations

import json
from pathlib import Path

from generated_art_v6.body_profiles import (
    FIGHTER_IDS,
    GLOVE_FAMILIES,
    STYLE_LOCK,
    STYLE_PROFILES,
    StyleProfile,
    as_v5_body,
    style_profile,
)

ROOT = Path(__file__).resolve().parents[2]
PALETTE_PATH = ROOT / "game-godot/data/art/generated_v7/palette_blocking.json"
PAIR_PATH = ROOT / "game-godot/data/art/generated_v7/pair_matchups.json"
STYLE_LOCK_V7 = ROOT / "docs/art/GENERATED_ART_V7_GRAPHIC_HERO_POLISH.md"


def _reject_human(payload: dict, label: str) -> None:
    if payload.get("HUMAN_AUTHORED_ART_PASS") or payload.get("HUMAN_AUTHORED_ANIMATION_PASS") or payload.get("human_authored"):
        raise ValueError(f"{label} must remain generated, not human-authored")


def load_palettes(path: Path | None = None) -> dict:
    payload = json.loads((path or PALETTE_PATH).read_text(encoding="utf-8"))
    _reject_human(payload, "v7 palettes")
    return payload.get("fighters") or {}


def load_pairs(path: Path | None = None) -> dict:
    payload = json.loads((path or PAIR_PATH).read_text(encoding="utf-8"))
    _reject_human(payload, "v7 pair matchups")
    return payload


def luma(color) -> float:
    r, g, b = float(color[0]), float(color[1]), float(color[2])
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def palette_value_ok(fid: str) -> bool:
    pal = load_palettes()[fid]
    dark = luma(pal["undersuit"])
    armor = luma(pal["armor"])
    accent = luma(pal["accent"])
    values = sorted((dark, armor, accent))
    gaps = [values[1] - values[0], values[2] - values[1]]
    if fid == "nix-calder":
        return dark < 0.14 and armor > 0.72 and 0.28 < accent < 0.62 and min(gaps) > 0.16
    return dark < 0.16 and min(gaps) > 0.12 and len(pal.get("value_groups") or []) >= 3


__all__ = [
    "FIGHTER_IDS",
    "GLOVE_FAMILIES",
    "PALETTE_PATH",
    "PAIR_PATH",
    "ROOT",
    "STYLE_LOCK",
    "STYLE_LOCK_V7",
    "STYLE_PROFILES",
    "StyleProfile",
    "as_v5_body",
    "load_pairs",
    "load_palettes",
    "luma",
    "palette_value_ok",
    "style_profile",
]
