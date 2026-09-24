#!/usr/bin/env python3
"""Original procedural combat SFX. No third-party samples."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

from .common import FIGHTER_IDS, GENERATOR, GENERATOR_VERSION, STATUS, generated_audio_dir, shared_audio_dir, write_json
from .profiles import profile

RATE = 44100


def _clamp(sample: float) -> int:
    return max(-32767, min(32767, int(sample * 32767.0)))


def _write_wav(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(RATE)
        handle.writeframes(b"".join(struct.pack("<h", _clamp(s)) for s in samples))


def _env(i: int, n: int, attack: float, release: float) -> float:
    a = max(1, int(n * attack))
    r = max(1, int(n * release))
    if i < a:
        return i / a
    if i > n - r:
        return max(0.0, (n - i) / r)
    return 1.0


def _tone(freq: float, seconds: float, amp: float = 0.22, attack: float = 0.02, release: float = 0.18) -> list[float]:
    n = int(RATE * seconds)
    out = []
    for i in range(n):
        t = i / RATE
        wave_s = math.sin(2 * math.pi * freq * t) + 0.35 * math.sin(4 * math.pi * freq * t)
        out.append(wave_s * amp * _env(i, n, attack, release))
    return out


def _noise(seconds: float, amp: float = 0.18, attack: float = 0.01, release: float = 0.4, seed: int = 1) -> list[float]:
    n = int(RATE * seconds)
    out = []
    state = seed * 1103515245 + 12345
    prev = 0.0
    for i in range(n):
        state = (1103515245 * state + 12345) & 0x7FFFFFFF
        white = (state / 0x7FFFFFFF) * 2.0 - 1.0
        prev = 0.65 * prev + 0.35 * white
        out.append(prev * amp * _env(i, n, attack, release))
    return out


def _mix(*layers: list[float]) -> list[float]:
    n = max(len(layer) for layer in layers)
    out = [0.0] * n
    for layer in layers:
        for i, sample in enumerate(layer):
            out[i] += sample
    peak = max(0.001, max(abs(s) for s in out))
    return [s / peak * 0.88 for s in out]


def _sweep(start: float, end: float, seconds: float, amp: float = 0.2) -> list[float]:
    n = int(RATE * seconds)
    out = []
    for i in range(n):
        t = i / max(1, n - 1)
        freq = start + (end - start) * t
        out.append(math.sin(2 * math.pi * freq * (i / RATE)) * amp * _env(i, n, 0.04, 0.25))
    return out


SHARED = {
    "whoosh": lambda: _mix(_noise(0.18, 0.22, 0.01, 0.5, 3), _sweep(420, 180, 0.16, 0.12)),
    "hit_light": lambda: _mix(_tone(620, 0.08, 0.18, 0.01, 0.5), _noise(0.09, 0.16, 0.01, 0.6, 9)),
    "hit_medium": lambda: _mix(_tone(280, 0.12, 0.22, 0.01, 0.45), _noise(0.12, 0.20, 0.01, 0.55, 11)),
    "hit_heavy": lambda: _mix(_tone(92, 0.22, 0.28, 0.01, 0.4), _tone(210, 0.14, 0.12, 0.01, 0.5), _noise(0.16, 0.22, 0.01, 0.5, 17)),
    "hit_aura": lambda: _mix(_sweep(180, 540, 0.22, 0.18), _tone(360, 0.20, 0.12), _noise(0.20, 0.12, 0.02, 0.5, 21)),
    "super": lambda: _mix(_sweep(90, 720, 0.42, 0.20), _tone(180, 0.40, 0.14), _noise(0.38, 0.10, 0.05, 0.4, 29)),
    "ko": lambda: _mix(_tone(70, 0.55, 0.26, 0.02, 0.35), _noise(0.50, 0.16, 0.02, 0.4, 31)),
    "charge_low": lambda: _mix(_tone(110, 0.28, 0.10), _noise(0.28, 0.06, 0.1, 0.3, 37)),
    "charge_mid": lambda: _mix(_tone(150, 0.32, 0.12), _noise(0.32, 0.07, 0.1, 0.3, 41)),
    "charge_high": lambda: _mix(_tone(200, 0.36, 0.14), _noise(0.36, 0.08, 0.08, 0.3, 43)),
    "charge_full": lambda: _mix(_sweep(140, 420, 0.36, 0.16), _tone(280, 0.30, 0.10), _noise(0.30, 0.08, 0.05, 0.35, 47)),
    "clash_bed": lambda: _mix(_tone(98, 0.80, 0.10, 0.1, 0.2), _tone(147, 0.80, 0.08, 0.1, 0.2), _noise(0.80, 0.05, 0.1, 0.2, 53)),
    "clash_resolution": lambda: _mix(_sweep(160, 40, 0.34, 0.18), _tone(55, 0.36, 0.16), _noise(0.30, 0.10, 0.02, 0.4, 59)),
}


def fighter_layer(fid: str, kind: str) -> list[float]:
    p = profile(fid)
    color = p.audio_color
    if kind == "whoosh":
        return _mix(_sweep(color, color * 0.45, 0.16, 0.14), _noise(0.16, 0.10, 0.01, 0.5, hash(fid) & 255))
    if kind == "element":
        return _mix(_tone(color, 0.22, 0.12), _sweep(color * 0.5, color * 1.4, 0.24, 0.10))
    if kind == "charge":
        return _mix(_sweep(color * 0.4, color, 0.34, 0.12), _noise(0.30, 0.06, 0.08, 0.3, 61))
    return _mix(_tone(color * 0.5, 0.18, 0.12), _noise(0.16, 0.08, 0.02, 0.45, 67))


def generate_all() -> dict:
    shared = shared_audio_dir()
    files = []
    for name, builder in SHARED.items():
        path = shared / f"{name}.wav"
        _write_wav(path, builder())
        files.append(str(path.relative_to(path.parents[6] if False else path.parent.parent.parent.parent.parent.parent)))
        _write_import(path)
    for fid in FIGHTER_IDS:
        out = generated_audio_dir(fid)
        for kind in ("whoosh", "element", "charge", "hit"):
            path = out / f"{kind}.wav"
            _write_wav(path, fighter_layer(fid, kind if kind != "hit" else "element"))
            _write_import(path)
            files.append(str(path))
    report = {
        "status": "GENERATED_PRODUCTION_AUDIO",
        "generator": GENERATOR,
        "generator_version": GENERATOR_VERSION,
        "human_authored": False,
        "third_party": False,
        "file_count": len(list(shared.glob("*.wav"))) + sum(len(list(generated_audio_dir(fid).glob("*.wav"))) for fid in FIGHTER_IDS),
        "categories": list(SHARED),
    }
    write_json(shared / "manifest.json", report)
    return report


def _write_import(path: Path) -> None:
    rel = f"res://assets/audio/generated_production/{'shared' if path.parent.name == 'shared' else 'fighters/' + path.parent.name}/{path.name}"
    path.with_suffix(path.suffix + ".import").write_text(
        "\n".join(
            [
                "[remap]",
                "",
                'importer="wav"',
                'type="AudioStreamWAV"',
                "",
                "[deps]",
                "",
                f'source_file="{rel}"',
                "",
                "[params]",
                "",
                "force/8_bit=false",
                "force/mono=false",
                "force/max_rate=false",
                "force/max_rate_hz=44100",
                "edit/trim=false",
                "edit/normalize=false",
                "edit/loop_mode=0",
                "edit/loop_begin=0",
                "edit/loop_end=-1",
                "compress/mode=2",
                "",
            ]
        ),
        encoding="utf-8",
    )


if __name__ == "__main__":
    print(generate_all())
