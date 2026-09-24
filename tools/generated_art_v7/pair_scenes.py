"""Contrasting pair staging. Attackers stay on -X; defenders on +X."""
from __future__ import annotations

from generated_art_v7.body_profiles import load_pairs

ATTACKER_X = -0.68
DEFENDER_X = 0.68


def defender_for(fid: str) -> str:
    return (load_pairs().get("heavy") or {})[fid]


def clash_presets() -> list[list[str]]:
    return list(load_pairs().get("clash_presets") or [])


def pair_offsets() -> tuple[float, float]:
    return ATTACKER_X, DEFENDER_X
