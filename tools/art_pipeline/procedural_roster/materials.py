"""Cel/toon material language for procedural roster fighters."""
from __future__ import annotations

from silhouette import SilhouetteContract


def material_slots(style: SilhouetteContract) -> list[dict]:
    return [
        {"name": "skin", "hex": style.primary, "emission": 0.0, "toon_band": 3},
        {"name": "cloth", "hex": style.secondary, "emission": 0.0, "toon_band": 3},
        {"name": "accent", "hex": style.accent, "emission": 0.15, "toon_band": 2},
        {"name": "outline", "hex": style.outline, "emission": 0.0, "toon_band": 1},
        {"name": "accessory", "hex": style.accent, "emission": 0.25, "toon_band": 2},
        {"name": "aura_shell", "hex": style.accent, "emission": 0.45, "toon_band": 2},
    ]


def material_manifest(style: SilhouetteContract) -> dict:
    slots = material_slots(style)
    return {
        "fighter_id": style.fighter_id,
        "shader": "game-godot/shaders/fighter_toon.gdshader",
        "material_count": len(slots),
        "max_texture_resolution": "2048x2048",
        "slots": slots,
        "status": "PROCEDURAL_PRODUCTION_PROXY",
    }
