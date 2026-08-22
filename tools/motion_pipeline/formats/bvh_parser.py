#!/usr/bin/env python3
"""Parse BVH hierarchy and motion channels into structured data."""
from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


@dataclass
class BvhJoint:
    name: str
    offset: tuple[float, float, float]
    channels: list[str] = field(default_factory=list)
    children: list[BvhJoint] = field(default_factory=list)


@dataclass
class BvhMotion:
    frame_time: float
    frames: list[list[float]]


@dataclass
class BvhDocument:
    root: BvhJoint
    motion: BvhMotion
    channel_order: list[str] = field(default_factory=list)

    @property
    def frame_count(self) -> int:
        return len(self.motion.frames)

    @property
    def fps(self) -> float:
        return 1.0 / self.motion.frame_time if self.motion.frame_time else 0.0


def _tokenize(text: str) -> list[str]:
    tokens: list[str] = []
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue
        line = line.replace("{", " { ").replace("}", " } ")
        tokens.extend(line.split())
    return tokens


def _collect_channels(joint: BvhJoint, out: list[str]) -> None:
    for ch in joint.channels:
        out.append(f"{joint.name}.{ch}")
    for child in joint.children:
        _collect_channels(child, out)


def parse_bvh(text: str) -> BvhDocument:
    tokens = _tokenize(text)
    if not tokens or tokens[0] != "HIERARCHY":
        raise ValueError("missing HIERARCHY")
    idx = 1

    def parse_joint() -> BvhJoint:
        nonlocal idx
        if tokens[idx] not in ("ROOT", "JOINT"):
            raise ValueError(f"expected ROOT/JOINT, got {tokens[idx]}")
        name = tokens[idx + 1]
        idx += 2
        if tokens[idx] != "{":
            raise ValueError("expected {")
        idx += 1
        offset = (0.0, 0.0, 0.0)
        channels: list[str] = []
        children: list[BvhJoint] = []
        while idx < len(tokens) and tokens[idx] != "}":
            tok = tokens[idx]
            if tok == "OFFSET":
                offset = (float(tokens[idx + 1]), float(tokens[idx + 2]), float(tokens[idx + 3]))
                idx += 4
            elif tok == "CHANNELS":
                count = int(tokens[idx + 1])
                channels = tokens[idx + 2 : idx + 2 + count]
                idx += 2 + count
            elif tok in ("ROOT", "JOINT"):
                children.append(parse_joint())
            elif tok == "End":
                idx += 1
                while idx < len(tokens) and tokens[idx] != "}":
                    idx += 1
                if idx < len(tokens) and tokens[idx] == "}":
                    idx += 1
            else:
                idx += 1
        if idx < len(tokens) and tokens[idx] == "}":
            idx += 1
        return BvhJoint(name=name, offset=offset, channels=channels, children=children)

    root = parse_joint()
    if idx >= len(tokens) or tokens[idx] != "MOTION":
        raise ValueError("missing MOTION")
    idx += 1
    if tokens[idx] != "Frames:":
        raise ValueError("missing Frames:")
    frame_count = int(tokens[idx + 1])
    idx += 2
    if tokens[idx] != "Frame":
        raise ValueError("missing Frame Time:")
    frame_time = float(tokens[idx + 2])
    idx += 3

    channel_order: list[str] = []
    _collect_channels(root, channel_order)
    frames: list[list[float]] = []
    while idx < len(tokens) and len(frames) < frame_count:
        values = [float(v) for v in tokens[idx : idx + len(channel_order)]]
        if len(values) != len(channel_order):
            raise ValueError(f"frame channel count mismatch: got {len(values)} expected {len(channel_order)}")
        frames.append(values)
        idx += len(channel_order)

    return BvhDocument(root=root, motion=BvhMotion(frame_time=frame_time, frames=frames), channel_order=channel_order)


def parse_bvh_file(path: Path) -> BvhDocument:
    return parse_bvh(path.read_text(encoding="utf-8", errors="replace"))


def validate_bvh_structure(path: Path) -> dict[str, Any]:
    try:
        doc = parse_bvh_file(path)
        return {
            "ok": True,
            "frame_count": doc.frame_count,
            "fps": round(doc.fps, 4),
            "channel_count": len(doc.channel_order),
            "root_joint": doc.root.name,
        }
    except Exception as exc:  # noqa: BLE001
        return {"ok": False, "error": str(exc)}


if __name__ == "__main__":
    import argparse
    import json

    parser = argparse.ArgumentParser()
    parser.add_argument("bvh", type=Path)
    args = parser.parse_args()
    print(json.dumps(validate_bvh_structure(args.bvh), indent=2))
