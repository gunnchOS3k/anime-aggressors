#!/usr/bin/env python3
"""Rebuild v3 masters, stills, geometry, and gates without rewriting audio/VFX."""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))

from generated_production_art.common import REPORTS, write_json  # noqa: E402
from generated_production_art.emit_gates import main as emit_gates  # noqa: E402
from generated_production_art.generate_animations import generate_all as gen_anims  # noqa: E402
from generated_production_art.make_contact_sheets import main as make_sheets  # noqa: E402
from generated_production_art.make_v3_sheets import main as make_v3_sheets  # noqa: E402
from generated_production_art.run_pipeline import generate_masters  # noqa: E402
from generated_production_art.score_visual_v3 import score as score_v3  # noqa: E402
from generated_production_art.validate_exaggeration import validate  # noqa: E402
from generated_production_art.validate_geometry_v2 import validate as validate_geom  # noqa: E402
from generated_production_art.validate_geometry_v3 import validate as validate_geom_v3  # noqa: E402
from generated_production_art.validate_hero_v3 import validate as validate_hero  # noqa: E402
from generated_production_art.validate_silhouette_v3 import validate as validate_sil  # noqa: E402


def main() -> int:
    anims = gen_anims()
    write_json(REPORTS / "GENERATED_PRODUCTION_ANIMATION.json", anims)
    masters = generate_masters()
    write_json(REPORTS / "GENERATED_PRODUCTION_MASTERS.json", masters)
    exaggeration = validate()
    write_json(REPORTS / "GENERATED_PRODUCTION_EXAGGERATION.json", exaggeration)
    geometry = validate_geom()
    write_json(REPORTS / "GENERATED_PRODUCTION_GEOMETRY_V2.json", geometry)
    geometry_v3 = validate_geom_v3()
    write_json(REPORTS / "GENERATED_PRODUCTION_GEOMETRY_V3.json", geometry_v3)
    make_sheets()
    make_v3_sheets()
    sil = validate_sil()
    hero = validate_hero()
    quality = score_v3()
    write_json(REPORTS / "GENERATED_ART_V3_SILHOUETTE.json", sil)
    write_json(REPORTS / "GENERATED_ART_V3_HERO.json", hero)
    write_json(REPORTS / "GENERATED_ART_V3_QUALITY.json", quality)
    emit_gates()
    print(
        {
            "masters_ok": masters.get("ok"),
            "geometry_ok": geometry.get("ok"),
            "geometry_v3_ok": geometry_v3.get("ok"),
            "silhouette_ok": sil.get("ok"),
            "hero_ok": hero.get("ok"),
            "quality": quality.get("roster"),
        }
    )
    return 0 if masters.get("ok") else 2


if __name__ == "__main__":
    raise SystemExit(main())
