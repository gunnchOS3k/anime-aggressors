#!/usr/bin/env python3
"""Generate ORIGINAL procedural WAV banks for Anime Aggressors digital launch.

Categories: hit, move, charge, projectile, defense, ko, ui, stage beds.
No licensed samples — pure synthesis.
"""
from __future__ import annotations

import json
import math
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "game-godot" / "assets" / "audio" / "procedural"
EVIDENCE = ROOT / "playtest-evidence" / "visual_qa" / "audio_bank_manifest.json"

FIGHTERS = (
    "ember-vale",
    "rook-ironside",
    "juno-spark",
    "kaia-windrow",
    "nix-calder",
    "orion-vell",
    "vesper-nyx",
)
STAGES = (
    "skyline-arena",
    "neon-rooftops",
    "cascade-foundry",
    "void-pier",
    "ember-courtyard",
    "training-grid",
)
SHARED = ("hit", "move", "charge", "projectile", "defense", "ko", "ui_confirm", "ui_back", "ui_select")

FIGHTER_TONE = {
    "ember-vale": 220.0,
    "rook-ironside": 110.0,
    "juno-spark": 330.0,
    "kaia-windrow": 262.0,
    "nix-calder": 196.0,
    "orion-vell": 147.0,
    "vesper-nyx": 185.0,
}
STAGE_TONE = {
    "skyline-arena": 98.0,
    "neon-rooftops": 130.8,
    "cascade-foundry": 87.3,
    "void-pier": 73.4,
    "ember-courtyard": 110.0,
    "training-grid": 164.8,
}


def clamp(v: float) -> int:
    return max(-32767, min(32767, int(v)))


def write_wav(path: Path, samples: list[float], rate: int = 44100) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(rate)
        frames = b"".join(struct.pack("<h", clamp(s * 32767.0)) for s in samples)
        wf.writeframes(frames)


def env(i: int, n: int, attack: float = 0.02, release: float = 0.2) -> float:
    a = max(1, int(n * attack))
    r = max(1, int(n * release))
    if i < a:
        return i / a
    if i > n - r:
        return max(0.0, (n - i) / r)
    return 1.0


def tone(freq: float, seconds: float, amp: float = 0.35, wave_kind: str = "sine", rate: int = 44100) -> list[float]:
    n = int(seconds * rate)
    out = []
    for i in range(n):
        t = i / rate
        phase = 2 * math.pi * freq * t
        if wave_kind == "square":
            v = 1.0 if math.sin(phase) >= 0 else -1.0
        elif wave_kind == "saw":
            v = 2.0 * ((freq * t) % 1.0) - 1.0
        elif wave_kind == "noise":
            # deterministic hash noise
            x = math.sin(i * 12.9898 + freq) * 43758.5453
            v = (x - math.floor(x)) * 2.0 - 1.0
        else:
            v = math.sin(phase)
        out.append(v * amp * env(i, n))
    return out


def fm_burst(carrier: float, mod: float, seconds: float, amp: float = 0.4) -> list[float]:
    rate = 44100
    n = int(seconds * rate)
    out = []
    for i in range(n):
        t = i / rate
        m = math.sin(2 * math.pi * mod * t) * (8.0 * (1.0 - i / n))
        v = math.sin(2 * math.pi * carrier * t + m)
        out.append(v * amp * env(i, n, 0.005, 0.35))
    return out


def make_bank() -> dict:
    files = []
    # Shared combat / UI
    mapping = {
        "hit": fm_burst(180, 90, 0.12, 0.55),
        "move": tone(140, 0.08, 0.2, "saw"),
        "charge": tone(90, 0.45, 0.28, "sine") + tone(180, 0.25, 0.22, "sine"),
        "projectile": fm_burst(420, 60, 0.22, 0.35),
        "defense": tone(70, 0.18, 0.3, "square"),
        "ko": fm_burst(60, 30, 0.55, 0.6),
        "ui_confirm": tone(520, 0.08, 0.25, "sine") + tone(780, 0.08, 0.2, "sine"),
        "ui_back": tone(320, 0.07, 0.2, "sine"),
        "ui_select": tone(640, 0.05, 0.18, "square"),
    }
    shared_dir = OUT / "shared"
    for name, samples in mapping.items():
        p = shared_dir / f"{name}.wav"
        write_wav(p, samples)
        files.append({"id": f"shared.{name}", "path": str(p.relative_to(ROOT)), "category": name})

    # Per-fighter accent hits / voice-ish chirps
    for fid in FIGHTERS:
        base = FIGHTER_TONE[fid]
        fighter_dir = OUT / "fighters" / fid
        specs = {
            "hit": fm_burst(base, base / 2, 0.14, 0.5),
            "move": tone(base * 0.8, 0.09, 0.22, "saw"),
            "charge": tone(base * 0.5, 0.5, 0.3, "sine"),
            "projectile": fm_burst(base * 2.1, base / 3, 0.2, 0.35),
            "defense": tone(base * 0.4, 0.16, 0.28, "square"),
            "ko": fm_burst(base * 0.35, 18, 0.6, 0.55),
            "vo_short": tone(base * 1.5, 0.12, 0.22, "sine") + tone(base * 1.8, 0.1, 0.18, "sine"),
        }
        for name, samples in specs.items():
            p = fighter_dir / f"{name}.wav"
            write_wav(p, samples)
            files.append({"id": f"fighter.{fid}.{name}", "path": str(p.relative_to(ROOT)), "fighter": fid, "category": name})

    # Stage beds (loopable short beds)
    for sid in STAGES:
        base = STAGE_TONE[sid]
        bed = []
        rate = 44100
        seconds = 2.5
        n = int(seconds * rate)
        for i in range(n):
            t = i / rate
            v = (
                0.18 * math.sin(2 * math.pi * base * t)
                + 0.10 * math.sin(2 * math.pi * base * 1.5 * t)
                + 0.06 * math.sin(2 * math.pi * (base * 0.5) * t + 0.3)
            )
            # soft noise bed
            x = math.sin(i * 7.123 + base) * 43758.5453
            noise = ((x - math.floor(x)) * 2.0 - 1.0) * 0.03
            bed.append((v + noise) * env(i, n, 0.08, 0.08))
        p = OUT / "stages" / sid / "bed.wav"
        write_wav(p, bed)
        files.append({"id": f"stage.{sid}.bed", "path": str(p.relative_to(ROOT)), "stage": sid, "category": "stage"})

    manifest = {
        "schema_version": 1,
        "status": "PROCEDURAL_FINAL",
        "license": "ORIGINAL_INTERNAL",
        "generator": "tools/audio/generate_procedural_sfx.py",
        "categories": list(SHARED) + ["stage", "vo_short"],
        "files": files,
        "counts": {
            "total": len(files),
            "fighters": len(FIGHTERS),
            "stages": len(STAGES),
            "shared": len(SHARED),
        },
    }
    EVIDENCE.parent.mkdir(parents=True, exist_ok=True)
    EVIDENCE.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(files)} procedural WAVs under {OUT}")
    return manifest


if __name__ == "__main__":
    make_bank()
