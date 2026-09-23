#!/usr/bin/env python3
"""Rebuild v2 masters, stills, geometry, and gates without rewriting audio/VFX."""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))

from generated_production_art.common import REPORTS, write_json  # noqa: E402
from generated_production_art.emit_gates import main as emit_gates  # noqa: E402
from generated_production_art.make_contact_sheets import main as make_sheets  # noqa: E402
from generated_production_art.run_pipeline import generate_masters, write_manifest  # noqa: E402
from generated_production_art.validate_exaggeration import validate  # noqa: E402
from generated_production_art.validate_geometry_v2 import validate as validate_geom  # noqa: E402


def main() -> int:
    masters = generate_masters()
    write_json(REPORTS / "GENERATED_PRODUCTION_MASTERS.json", masters)
    exaggeration = validate()
    write_json(REPORTS / "GENERATED_PRODUCTION_EXAGGERATION.json", exaggeration)
    geometry = validate_geom()
    write_json(REPORTS / "GENERATED_PRODUCTION_GEOMETRY_V2.json", geometry)
    make_sheets()
    emit_gates()
    print({"masters_ok": masters.get("ok"), "geometry_ok": geometry.get("ok"), "float": geometry.get("UNINTENTIONAL_FLOATING_ACCESSORIES")})
    return 0 if masters.get("ok") else 2


if __name__ == "__main__":
    raise SystemExit(main())
