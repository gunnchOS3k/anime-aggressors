#!/usr/bin/env python3
"""Generate original / owned procedural review SFX. No licensed announcer packs."""
from __future__ import annotations

import json
import math
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
RATE = 44100

FIGHTERS = {
    "ember-vale": (220.0, 330.0, 0.9),
    "rook-ironside": (110.0, 165.0, 0.7),
    "juno-spark": (392.0, 523.0, 0.55),
    "kaia-windrow": (262.0, 349.0, 0.5),
    "nix-calder": (196.0, 294.0, 0.6),
    "orion-vell": (147.0, 220.0, 0.65),
    "vesper-nyx": (175.0, 247.0, 0.45),
}


def write_wav(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(RATE)
        frames = b"".join(struct.pack("<h", max(-32767, min(32767, int(s * 32767)))) for s in samples)
        wf.writeframes(frames)


def tone(freq: float, seconds: float, amp: float, decay: bool = True) -> list[float]:
    n = int(RATE * seconds)
    out = []
    for i in range(n):
        t = i / RATE
        env = (1.0 - t / seconds) if decay else 1.0
        out.append(math.sin(2 * math.pi * freq * t) * amp * env)
    return out


def mix(*parts: list[float]) -> list[float]:
    length = max(len(p) for p in parts)
    out = [0.0] * length
    for p in parts:
        for i, s in enumerate(p):
            out[i] += s
    peak = max(0.001, max(abs(s) for s in out))
    return [s / peak * 0.85 for s in out]


def generate() -> dict:
    shared = ROOT / "game-godot/assets/audio/procedural/shared"
    announce = ROOT / "game-godot/assets/audio/procedural/announcer"
    combat = ROOT / "game-godot/assets/audio/procedural/combat"
    write_wav(shared / "lockin_stinger.wav", mix(tone(523, 0.12, 0.7), tone(784, 0.18, 0.45)))
    write_wav(shared / "launch_high.wav", mix(tone(180, 0.16, 0.4), tone(90, 0.2, 0.3)))
    write_wav(shared / "launch_critical.wav", mix(tone(140, 0.08, 0.7), tone(420, 0.14, 0.35)))
    files = [
        "game-godot/assets/audio/procedural/shared/lockin_stinger.wav",
        "game-godot/assets/audio/procedural/shared/launch_high.wav",
        "game-godot/assets/audio/procedural/shared/launch_critical.wav",
    ]
    for fid, (a, b, amp) in FIGHTERS.items():
        write_wav(announce / f"name_motif_{fid}.wav", mix(tone(a, 0.16, amp), tone(b, 0.22, amp * 0.6)))
        write_wav(combat / f"launch_critical_{fid}.wav", mix(tone(a * 0.5, 0.1, 0.55), tone(b, 0.16, 0.35)))
        files.append(f"game-godot/assets/audio/procedural/announcer/name_motif_{fid}.wav")
        files.append(f"game-godot/assets/audio/procedural/combat/launch_critical_{fid}.wav")
    provenance = {
        "schema": "audio_provenance/v1",
        "rights": "original_procedural_owned",
        "copyrighted_packs": False,
        "announcer_speech": False,
        "ANNOUNCER_FINAL_VOICE_ASSETS": False,
        "files": files,
        "note": "Review-only motifs and stingers. Not licensed voice acting.",
    }
    out = ROOT / "artifacts/presentation/select_lockin/AUDIO_PROVENANCE.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(provenance, indent=2) + "\n", encoding="utf-8")
    return provenance


if __name__ == "__main__":
    print(json.dumps(generate(), indent=2))
