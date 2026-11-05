#!/usr/bin/env python3
"""P1 device-0 joypad events must match P2 device-1 events for the same action.

Reads game-godot/project.godot. Does not launch Godot or import assets.
Exit 0 when the maps match. Exit 1 and print the missing P1 events otherwise.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ACTIONS = (
    "left",
    "right",
    "up",
    "down",
    "jump",
    "attack",
    "special",
    "shield",
    "dodge",
    "grab",
)


def _section(text: str) -> str:
    start = text.index("[input]")
    rest = text[start + len("[input]") :]
    end = rest.find("\n[")
    return rest if end < 0 else rest[:end]


def _actions(section: str) -> dict[str, list[tuple[str, dict[str, str]]]]:
    blocks = re.findall(r"^([A-Za-z0-9_]+)=\{(.*?)\n\}", section, re.M | re.S)
    parsed: dict[str, list[tuple[str, dict[str, str]]]] = {}
    for name, body in blocks:
        events = []
        for kind, inner in re.findall(r"Object\((InputEvent\w+),([^\)]*)\)", body):
            fields = dict(re.findall(r'"([A-Za-z0-9_]+)":([^,]+)', inner))
            events.append((kind, fields))
        parsed[name] = events
    return parsed


def _joypad(events: list[tuple[str, dict[str, str]]], device: str) -> list[str]:
    out: list[str] = []
    for kind, fields in events:
        if fields.get("device") != device:
            continue
        if kind == "InputEventJoypadMotion":
            out.append(f"motion axis={fields.get('axis')} value={fields.get('axis_value')}")
        elif kind == "InputEventJoypadButton":
            out.append(f"button index={fields.get('button_index')}")
    return out


def main() -> int:
    root = Path(__file__).resolve().parents[2]
    path = root / "game-godot" / "project.godot"
    actions = _actions(_section(path.read_text()))
    mismatches = []
    for suffix in ACTIONS:
        p1_name = f"p1_{suffix}"
        p2_name = f"p2_{suffix}"
        p1 = _joypad(actions[p1_name], "0")
        p2 = _joypad(actions[p2_name], "1")
        if p1 != p2:
            mismatches.append((p1_name, p1, p2_name, p2))
    if mismatches:
        print("P1 device 0 is missing joypad events that P2 device 1 already has:")
        for p1_name, p1, p2_name, p2 in mismatches:
            print(f"  {p1_name}: {p1 or ['NONE']}")
            print(f"  {p2_name}: {p2 or ['NONE']}")
        print(f"mismatch_count {len(mismatches)}")
        return 1
    print("p1_joypad_matches_p2 mismatch_count 0")
    return 0


if __name__ == "__main__":
    sys.exit(main())
