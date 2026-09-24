"""v9 profiles. Apply fighter-specific heroic exaggeration on the v6 understructure."""
from __future__ import annotations

import json
from dataclasses import replace
from pathlib import Path

from generated_art_v6.body_profiles import (
    FIGHTER_IDS,
    GLOVE_FAMILIES,
    STYLE_LOCK,
    STYLE_PROFILES,
    StyleProfile,
    as_v5_body,
    style_profile as style_profile_v6,
)

ROOT = Path(__file__).resolve().parents[2]
PALETTE_PATH = ROOT / "game-godot/data/art/generated_v9/palette_blocking.json"
PAIR_PATH = ROOT / "game-godot/data/art/generated_v9/pair_matchups.json"
ATTACH_PATH = ROOT / "game-godot/data/art/generated_v9/attachment_classes.json"
HERO_PATH = ROOT / "game-godot/data/art/generated_v9/hero_proportion_profiles.json"
SCREEN_PATH = ROOT / "game-godot/data/art/generated_v9/screen_space_thresholds.json"
STYLE_LOCK_V9 = ROOT / "docs/art/GENERATED_ART_V9_HERO_PROPORTIONS.md"


def _reject_human(payload: dict, label: str) -> None:
    if payload.get("HUMAN_AUTHORED_ART_PASS") or payload.get("HUMAN_AUTHORED_ANIMATION_PASS") or payload.get("human_authored"):
        raise ValueError(f"{label} must remain generated, not human-authored")


def load_palettes(path: Path | None = None) -> dict:
    payload = json.loads((path or PALETTE_PATH).read_text(encoding="utf-8"))
    _reject_human(payload, "v9 palettes")
    return payload.get("fighters") or {}


def load_pairs(path: Path | None = None) -> dict:
    payload = json.loads((path or PAIR_PATH).read_text(encoding="utf-8"))
    _reject_human(payload, "v9 pair matchups")
    return payload


def load_attachment_table(path: Path | None = None) -> dict:
    payload = json.loads((path or ATTACH_PATH).read_text(encoding="utf-8"))
    _reject_human(payload, "v9 attachment classes")
    return payload


def load_hero_profiles(path: Path | None = None) -> dict:
    payload = json.loads((path or HERO_PATH).read_text(encoding="utf-8"))
    _reject_human(payload, "v9 hero proportions")
    fighters = payload.get("fighters") or {}
    missing = set(FIGHTER_IDS) - set(fighters)
    if missing:
        raise ValueError(f"v9 hero roster mismatch missing={sorted(missing)}")
    scales = {fid: float(fighters[fid]["shoulder_scale"]) for fid in FIGHTER_IDS}
    if len(set(round(v, 3) for v in scales.values())) < 5:
        raise ValueError("v9 hero proportions must not be a universal exaggeration")
    return fighters


def load_screen_thresholds(path: Path | None = None) -> dict:
    payload = json.loads((path or SCREEN_PATH).read_text(encoding="utf-8"))
    _reject_human(payload, "v9 screen-space thresholds")
    return payload.get("minimums") or {}


def apply_hero(profile: StyleProfile, hero: dict | None = None) -> StyleProfile:
    hero = hero or load_hero_profiles()[profile.fighter_id]
    chest_bias = float(hero.get("chest_bias") or 1.0)
    return replace(
        profile,
        shoulder_width=profile.shoulder_width * float(hero["shoulder_scale"]),
        forearm_mass=profile.forearm_mass * float(hero["forearm_scale"]),
        upper_arm_mass=profile.upper_arm_mass * (0.55 + 0.45 * float(hero["shoulder_scale"])),
        hand_scale=profile.hand_scale * float(hero["hand_scale"]),
        foot_scale=profile.foot_scale * float(hero["boot_scale"]),
        neck_scale=profile.neck_scale * float(hero["head_scale"]),
        torso_taper=profile.torso_taper * float(hero["torso_taper"]),
        limb_length=profile.limb_length * float(hero["leg_length"]),
        pelvis_width=profile.pelvis_width * float(hero["stance_width"]),
        chest_depth=profile.chest_depth * chest_bias,
        waist_width=profile.waist_width * (2.0 - float(hero["torso_taper"]) * 0.35) if float(hero["torso_taper"]) > 1.05 else profile.waist_width * 0.92,
        height=profile.height * (0.92 + 0.08 * float(hero["leg_length"])),
    )


def style_profile(fid: str) -> StyleProfile:
    return apply_hero(style_profile_v6(fid))


def hero_feature_scale(fid: str) -> float:
    return float(load_hero_profiles()[fid]["hero_feature_scale"])


def action_line(fid: str) -> str:
    return str(load_hero_profiles()[fid].get("action_line") or "horizontal_diagonal_drive")


def luma(color) -> float:
    r, g, b = float(color[0]), float(color[1]), float(color[2])
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def palette_value_ok(fid: str) -> bool:
    pal = load_palettes()[fid]
    dark = luma(pal["undersuit"])
    armor = luma(pal["armor"])
    mid = luma(pal.get("secondary") or pal["glove"])
    accent = luma(pal["accent"])
    values = sorted((dark, armor, accent))
    gaps = [values[1] - values[0], values[2] - values[1]]
    if fid == "nix-calder":
        return dark < 0.14 and armor > 0.72 and 0.28 < accent < 0.62 and min(gaps) > 0.16
    groups = pal.get("value_groups") or []
    return dark < 0.16 and min(gaps) > 0.12 and len(groups) >= 3 and abs(armor - mid) > 0.04


__all__ = [
    "ATTACH_PATH",
    "FIGHTER_IDS",
    "GLOVE_FAMILIES",
    "HERO_PATH",
    "PALETTE_PATH",
    "PAIR_PATH",
    "ROOT",
    "SCREEN_PATH",
    "STYLE_LOCK",
    "STYLE_LOCK_V9",
    "STYLE_PROFILES",
    "StyleProfile",
    "action_line",
    "apply_hero",
    "as_v5_body",
    "hero_feature_scale",
    "load_attachment_table",
    "load_hero_profiles",
    "load_pairs",
    "load_palettes",
    "load_screen_thresholds",
    "luma",
    "palette_value_ok",
    "style_profile",
]
