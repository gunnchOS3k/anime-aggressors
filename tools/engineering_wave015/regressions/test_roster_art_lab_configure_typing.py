#!/usr/bin/env python3
"""Regression: roster art lab configure typing must use explicit bool cast."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SRC = ROOT / "game-godot/scripts/labs/roster_art_lab.gd"


def main() -> int:
    text = SRC.read_text(encoding="utf-8")
    ok = 'bool(model.call("configure", data))' in text or "bool(model.configure(" in text
    bad = "var configured := model.configure(" in text
    print({"ok": ok and not bad, "path": str(SRC)})
    return 0 if ok and not bad else 1


if __name__ == "__main__":
    raise SystemExit(main())
