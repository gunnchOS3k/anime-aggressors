"""Runtime GLB export. Same skeleton/sockets/action IDs as v4/v5."""
from __future__ import annotations

from pathlib import Path

from generated_art_v6 import GENERATOR, GENERATOR_REVISION, GENERATOR_VERSION
from generated_art_v5.export_runtime import export_glb, write_glb_import


def report_payload(fid: str, out_blend: Path, out_glb: Path, geom: dict) -> dict:
    return {
        "fighter": fid,
        "status": "GENERATED_PRODUCTION_ART",
        "generator": GENERATOR,
        "generator_version": GENERATOR_VERSION,
        "generator_revision": GENERATOR_REVISION,
        "blend": str(out_blend),
        "glb": str(out_glb),
        "human_authored": False,
        "future_human_replaceable": True,
        "construction": "profile_loft_no_voxel_remesh",
        "visible_style": "graphic_lowpoly_cel_combat",
        "geometry": geom,
    }


__all__ = ["export_glb", "write_glb_import", "report_payload"]
