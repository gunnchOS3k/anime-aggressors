#!/usr/bin/env python3
"""Regression: animation play path must guard freed nodes."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
CTRL = ROOT / "game-godot/scripts/visual/fighter_animation_controller.gd"
MODEL = ROOT / "game-godot/scripts/fighters/fighter_model_3d.gd"


def main() -> int:
    c = CTRL.read_text(encoding="utf-8")
    m = MODEL.read_text(encoding="utf-8")
    ok = (
        "is_instance_valid(_player)" in c
        and "is_instance_valid(_skeleton)" in c
        and "is_instance_valid(_animation_controller)" in m
    )
    print({"ok": ok})
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
