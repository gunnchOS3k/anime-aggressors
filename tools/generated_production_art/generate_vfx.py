#!/usr/bin/env python3
"""Original generated VFX palettes and clash/super descriptors. Visual only."""
from __future__ import annotations

from .common import FIGHTER_IDS, GENERATOR, GENERATOR_VERSION, GODOT, STATUS, write_json
from .profiles import profile

CLASH_PRESETS = (
    ("rook-ironside", "orion-vell"),
    ("juno-spark", "kaia-windrow"),
    ("ember-vale", "nix-calder"),
    ("vesper-nyx", "ember-vale"),
    ("nix-calder", "rook-ironside"),
)


def _hex(rgb: tuple[float, float, float]) -> str:
    return "#%02X%02X%02X" % tuple(max(0, min(255, int(c * 255))) for c in rgb)


def fighter_vfx(fid: str) -> dict:
    p = profile(fid)
    return {
        "asset_id": f"{fid}.vfx",
        "fighter_id": fid,
        "category": "vfx",
        "generator": GENERATOR,
        "generator_version": GENERATOR_VERSION,
        "status": "GENERATED_PRODUCTION_VFX",
        "future_human_replaceable": True,
        "family_id": f"{fid}.vfx",
        "palettes": {
            "base": _hex(p.primary),
            "accent": _hex(p.accent),
            "charged": _hex(p.charged),
            "vfx": _hex(p.accent),
            "outline": _hex(p.outline),
        },
        "hit_sparks": {"life_s": 0.12, "count": 8, "directional": True, "socket_aligned": True},
        "trails": {"life_s": 0.18, "width": 0.08, "a11y_reducible": True},
        "charge_aura": {"low": 0.25, "mid": 0.5, "high": 0.75, "full": 1.0, "floor_dust": True},
        "launch_trails": {"life_s": 0.22, "count": 6},
        "ko_burst": {"life_s": 0.28, "bloom": 0.35},
        "supers": {"camera_space_accents": True, "unique": True},
        "clash": {"identity": p.clash_vfx, "life_s": 0.40},
        "environment": {"dust": True, "debris": True, "short_lived": True},
        "mobile": {"pixel_readable": True, "lod": True, "no_fullscreen_hold": True},
    }


def clash_mix(a: str, b: str) -> dict:
    pa, pb = profile(a), profile(b)
    return {
        "pair": [a, b],
        "identities": [pa.clash_vfx, pb.clash_vfx],
        "mix": f"{pa.clash_vfx}+{pb.clash_vfx}",
        "palette": [_hex(pa.accent), _hex(pb.accent)],
        "acting": ["clash_start", "clash_lock", "clash_push", "clash_winning", "clash_losing", "clash_break"],
        "status": "GENERATED_PRODUCTION_VFX",
    }


def generate_all() -> dict:
    out = GODOT / "data" / "vfx" / "generated_production"
    out.mkdir(parents=True, exist_ok=True)
    fighters = {}
    for fid in FIGHTER_IDS:
        payload = fighter_vfx(fid)
        write_json(out / f"{fid}.json", payload)
        fighters[fid] = payload
    presets = [clash_mix(a, b) for a, b in CLASH_PRESETS]
    write_json(out / "clash_presets.json", {"presets": presets, "dynamic_mix": True})
    write_json(
        out / "manifest.json",
        {
            "status": "GENERATED_PRODUCTION_VFX",
            "generator": GENERATOR,
            "generator_version": GENERATOR_VERSION,
            "human_authored": False,
            "fighters": FIGHTER_IDS,
            "required_presets": [list(row) for row in CLASH_PRESETS],
        },
    )
    return {"fighters": len(fighters), "presets": len(presets), "status": "GENERATED_PRODUCTION_VFX"}


if __name__ == "__main__":
    print(generate_all())
