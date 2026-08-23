#!/usr/bin/env python3
"""Regression: FighterModel3D SubViewport MSAA disabled for Pixel gralloc safety."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
MODEL = ROOT / "game-godot/scripts/fighters/fighter_model_3d.gd"


def main() -> int:
    text = MODEL.read_text(encoding="utf-8")
    ok = "msaa_3d = Viewport.MSAA_DISABLED" in text
    bad = "msaa_3d = Viewport.MSAA_2X" in text
    print({"ok": ok and not bad})
    return 0 if ok and not bad else 1


if __name__ == "__main__":
    raise SystemExit(main())
