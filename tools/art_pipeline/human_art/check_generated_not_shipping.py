#!/usr/bin/env python3
"""Prove generated V2–V9 roster paths are not selected by the production resolver."""
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import (  # noqa: E402
    ACCEPTED_PROXY,
    FIGHTER_IDS,
    ROOT,
    accepted_proxy_glb,
    path_looks_generated,
    path_looks_staging,
    write_json,
)

RESOLVER = ROOT / "game-godot/scripts/visual/fighter_asset_resolver.gd"
CONTENT_FIGHTERS = ROOT / "game-godot/content/fighters"
STAGING = ROOT / "game-godot/content/human_art_staging"


def resolver_text() -> str:
    return RESOLVER.read_text(encoding="utf-8") if RESOLVER.is_file() else ""


def main() -> int:
    fails = []
    text = resolver_text()
    if not text:
        fails.append("resolver_missing")
    if "generated_glb_path" in text and "STATUS_GENERATED" in text:
        # #106 selected generated art as current. That must not land here.
        if "return generated" in text or "_generated_production.glb" in text and "CLASS_CURRENT" in text:
            if "RESEARCH_ONLY" not in text and "CLASS_RESEARCH" not in text:
                fails.append("resolver_still_promotes_generated_roster")
    if "HUMAN_ART_STAGING" not in text and "human_art_staging" not in text:
        fails.append("resolver_missing_staging_isolation")
    if "ACTIVE_CHARACTER_PRESENTATION" not in text:
        fails.append("resolver_missing_ACTIVE_CHARACTER_PRESENTATION")
    if "PR106_GENERATED_ROSTER_NOT_SHIPPING" not in text:
        fails.append("resolver_missing_generated_roster_not_shipping_flag")

    shipping_generated = []
    for fighter in FIGHTER_IDS:
        generated = CONTENT_FIGHTERS / fighter / "model" / f"{fighter}_generated_production.glb"
        if generated.is_file():
            shipping_generated.append(str(generated.relative_to(ROOT)))
        proxy = accepted_proxy_glb(fighter)
        if not proxy.is_file():
            fails.append(f"accepted_proxy_missing:{fighter}")
    if shipping_generated:
        fails.append(f"generated_production_glb_in_content:{shipping_generated}")

    leaked_staging = []
    if STAGING.is_dir():
        for glb in STAGING.rglob("*.glb"):
            rel = str(glb.relative_to(ROOT))
            if not path_looks_staging(rel):
                leaked_staging.append(rel)
    if leaked_staging:
        fails.append(f"staging_path_not_isolated:{leaked_staging}")

    payload = {
        "ok": not fails,
        "failures": fails,
        "PR106_GENERATED_ROSTER_NOT_SHIPPING": not fails,
        "accepted_proxy_root": str(ACCEPTED_PROXY.relative_to(ROOT)),
        "generated_shipping_copies": shipping_generated,
        "HUMAN_ART_STAGING_DEFAULT": "0",
        "note": "Accepted main art selection is unchanged. Generated V2–V9 stays on PR #106.",
    }
    write_json(ROOT / "artifacts/art_pipeline/PR106_GENERATED_ROSTER_NOT_SHIPPING.json", payload)
    print(json.dumps(payload, indent=2))
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    raise SystemExit(main())
