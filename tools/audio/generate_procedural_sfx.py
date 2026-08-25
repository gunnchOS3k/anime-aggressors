#!/usr/bin/env python3
"""Generate ORIGINAL procedural WAV banks for Anime Aggressors digital launch.

Wave020: per-element synthesis profiles (fire/electric/wind/frost/gravity/shadow/earth).
Categories: hit, move, charge, projectile, signature, defense, ko, vo_short, ui, stage beds.
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

FIGHTER_ELEMENT = {
    "ember-vale": "fire",
    "rook-ironside": "earth",
    "juno-spark": "electric",
    "kaia-windrow": "wind",
    "nix-calder": "frost",
    "orion-vell": "gravity",
    "vesper-nyx": "shadow",
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


def mix(*tracks: list[float]) -> list[float]:
    n = max(len(t) for t in tracks) if tracks else 0
    out = [0.0] * n
    for t in tracks:
        for i, v in enumerate(t):
            out[i] += v
    peak = max(abs(v) for v in out) if out else 1.0
    if peak > 0.98:
        scale = 0.98 / peak
        out = [v * scale for v in out]
    return out


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


def sweep(start: float, end: float, seconds: float, amp: float = 0.3) -> list[float]:
    rate = 44100
    n = int(seconds * rate)
    out = []
    for i in range(n):
        t = i / rate
        f = start + (end - start) * (i / max(1, n - 1))
        v = math.sin(2 * math.pi * f * t)
        out.append(v * amp * env(i, n, 0.01, 0.25))
    return out


def element_charge(base: float, element: str) -> list[float]:
    if element == "fire":
        return mix(tone(base * 0.6, 0.35, 0.28, "saw"), tone(base * 1.2, 0.55, 0.22, "noise"))
    if element == "electric":
        return mix(fm_burst(base * 1.8, base * 0.4, 0.42, 0.32), tone(base * 3.2, 0.18, 0.18, "square"))
    if element == "wind":
        return mix(sweep(base * 1.4, base * 0.7, 0.48, 0.24), tone(base * 0.9, 0.5, 0.14, "noise"))
    if element == "frost":
        return mix(tone(base * 0.55, 0.52, 0.26, "sine"), sweep(base * 1.1, base * 0.45, 0.4, 0.2))
    if element == "gravity":
        return mix(tone(base * 0.35, 0.58, 0.34, "sine"), fm_burst(base * 0.5, 12, 0.45, 0.28))
    if element == "shadow":
        return mix(tone(base * 0.7, 0.5, 0.2, "saw"), fm_burst(base * 0.9, base * 0.15, 0.55, 0.22))
    # earth
    return mix(tone(base * 0.42, 0.48, 0.32, "square"), fm_burst(base * 0.55, 24, 0.35, 0.3))


def element_projectile(base: float, element: str) -> list[float]:
    if element == "fire":
        return mix(fm_burst(base * 2.4, base / 2, 0.18, 0.38), tone(base * 3.0, 0.12, 0.16, "noise"))
    if element == "electric":
        return fm_burst(base * 3.5, base, 0.16, 0.42)
    if element == "wind":
        return sweep(base * 2.2, base * 0.9, 0.22, 0.3)
    if element == "frost":
        return mix(fm_burst(base * 1.6, base / 4, 0.2, 0.34), tone(base * 2.4, 0.14, 0.12, "sine"))
    if element == "gravity":
        return mix(fm_burst(base * 0.9, 8, 0.24, 0.36), sweep(base * 1.2, base * 0.4, 0.2, 0.22))
    if element == "shadow":
        return mix(fm_burst(base * 1.4, base / 6, 0.22, 0.32), tone(base * 0.6, 0.16, 0.14, "saw"))
    return fm_burst(base * 1.4, base / 3, 0.22, 0.38)


def element_signature(base: float, element: str) -> list[float]:
    if element == "fire":
        return mix(element_charge(base, element), fm_burst(base * 2.8, base / 2, 0.28, 0.45))
    if element == "electric":
        return mix(element_charge(base, element), fm_burst(base * 4.2, base * 1.2, 0.24, 0.48))
    if element == "wind":
        return mix(sweep(base * 0.8, base * 2.6, 0.55, 0.34), tone(base * 1.6, 0.3, 0.18, "noise"))
    if element == "frost":
        return mix(element_charge(base, element), sweep(base * 1.8, base * 0.35, 0.32, 0.32))
    if element == "gravity":
        return mix(tone(base * 0.28, 0.62, 0.38, "sine"), fm_burst(base * 0.45, 6, 0.38, 0.4))
    if element == "shadow":
        return mix(fm_burst(base * 0.75, base / 8, 0.58, 0.34), sweep(base * 1.4, base * 0.25, 0.35, 0.28))
    return mix(element_charge(base, element), fm_burst(base * 0.9, 18, 0.32, 0.42))


def element_hit(base: float, element: str) -> list[float]:
    if element == "electric":
        return fm_burst(base * 1.6, base * 0.8, 0.1, 0.52)
    if element == "earth":
        return mix(tone(base * 0.5, 0.12, 0.42, "square"), fm_burst(base * 0.7, 20, 0.14, 0.38))
    if element == "frost":
        return mix(fm_burst(base, base / 3, 0.12, 0.45), tone(base * 2.2, 0.08, 0.16, "sine"))
    return fm_burst(base, base / 2, 0.14, 0.5)


def fighter_specs(fid: str) -> dict[str, list[float]]:
    base = FIGHTER_TONE[fid]
    element = FIGHTER_ELEMENT[fid]
    return {
        "hit": element_hit(base, element),
        "move": tone(base * 0.8, 0.09, 0.22, "saw"),
        "charge": element_charge(base, element),
        "projectile": element_projectile(base, element),
        "signature": element_signature(base, element),
        "defense": tone(base * 0.4, 0.16, 0.28, "square"),
        "ko": fm_burst(base * 0.35, 18, 0.6, 0.55),
        "vo_short": tone(base * 1.5, 0.12, 0.22, "sine") + tone(base * 1.8, 0.1, 0.18, "sine"),
    }


def make_bank() -> dict:
    files = []
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

    for fid in FIGHTERS:
        fighter_dir = OUT / "fighters" / fid
        element = FIGHTER_ELEMENT[fid]
        for name, samples in fighter_specs(fid).items():
            p = fighter_dir / f"{name}.wav"
            write_wav(p, samples)
            files.append(
                {
                    "id": f"fighter.{fid}.{name}",
                    "path": str(p.relative_to(ROOT)),
                    "fighter": fid,
                    "category": name,
                    "element": element,
                }
            )

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
            x = math.sin(i * 7.123 + base) * 43758.5453
            noise = ((x - math.floor(x)) * 2.0 - 1.0) * 0.03
            bed.append((v + noise) * env(i, n, 0.08, 0.08))
        p = OUT / "stages" / sid / "bed.wav"
        write_wav(p, bed)
        files.append({"id": f"stage.{sid}.bed", "path": str(p.relative_to(ROOT)), "stage": sid, "category": "stage"})

    manifest = {
        "schema_version": 2,
        "status": "PROCEDURAL_FINAL",
        "license": "ORIGINAL_INTERNAL",
        "generator": "tools/audio/generate_procedural_sfx.py",
        "wave": "WAVE020",
        "categories": list(SHARED) + ["signature", "stage", "vo_short"],
        "fighter_elements": FIGHTER_ELEMENT,
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
