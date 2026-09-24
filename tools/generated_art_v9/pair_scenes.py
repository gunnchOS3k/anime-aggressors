"""Contrasting pair staging. Solver places the defender; offsets are only seeds."""
from __future__ import annotations

from generated_art_v9.body_profiles import load_pairs

ATTACKER_X = -0.22
DEFENDER_X = 0.42


def defender_for(fid: str) -> str:
    return (load_pairs().get("heavy") or {})[fid]


def clash_presets() -> list[list[str]]:
    return list(load_pairs().get("clash_presets") or [])


def pair_offsets() -> tuple[float, float]:
    return ATTACKER_X, DEFENDER_X
