#!/usr/bin/env python3
"""Compose VXP-2 brand fixture evidence boards. NOT physical Pixel."""
from __future__ import annotations
import json, subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
AFTER = ROOT / "artifacts/vxp2/after"
MAN = ROOT / "artifacts/vxp2/manifests"
BRAND = ROOT / "game-godot/assets/branding/vxp2"
AFTER.mkdir(parents=True, exist_ok=True)
MAN.mkdir(parents=True, exist_ok=True)

surfaces = [
    ("main_menu", "Main Menu — FIGHT primary"),
    ("mode_select", "Mode Select — Versus first"),
    ("fighter_select", "Fighter Select — player-first"),
    ("stage_select", "Stage Select — destination"),
    ("versus", "Versus — match intro"),
    ("results", "Results — victory"),
]
viewports = [
    ("desktop-1440x900", 1440, 900),
    ("laptop-1366x768", 1366, 768),
    ("handheld-landscape-960x540", 960, 540),
]

shots = []
for sid, title in surfaces:
    for vid, w, h in viewports:
        svg = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#101B2E"/>
      <stop offset="100%" stop-color="#070B14"/>
    </linearGradient>
  </defs>
  <rect width="{w}" height="{h}" fill="url(#bg)"/>
  <image href="{BRAND / 'aa_hero_backdrop.png'}" x="0" y="0" width="{w}" height="{h}" opacity="0.55" preserveAspectRatio="xMidYMid slice"/>
  <image href="{BRAND / 'aa_seal.png'}" x="{int(w*0.06)}" y="{int(h*0.12)}" width="{int(min(w,h)*0.18)}" height="{int(min(w,h)*0.18)}"/>
  <image href="{BRAND / 'aa_wordmark.png'}" x="{int(w*0.28)}" y="{int(h*0.14)}" width="{int(w*0.55)}" height="{int(h*0.12)}" preserveAspectRatio="xMinYMid meet"/>
  <rect x="{int(w*0.28)}" y="{int(h*0.34)}" width="{int(w*0.28)}" height="{int(h*0.12)}" rx="10" fill="#2E1E0C" stroke="#E8B84A" stroke-width="3"/>
  <text x="{int(w*0.42)}" y="{int(h*0.415)}" text-anchor="middle" font-family="Georgia, serif" font-size="{max(22, int(h*0.045))}" fill="#F5D06A" font-weight="700">FIGHT</text>
  <text x="{int(w*0.06)}" y="{int(h*0.08)}" font-family="Georgia, serif" font-size="{max(16, int(h*0.035))}" fill="#E8B84A">{title}</text>
  <text x="{int(w*0.06)}" y="{int(h*0.92)}" font-family="Georgia, serif" font-size="{max(12, int(h*0.025))}" fill="#8FA3C4">Anime Aggressors · AURA FORGE · fixture composite · {vid}</text>
  <text x="{int(w*0.06)}" y="{int(h*0.96)}" font-family="Georgia, serif" font-size="{max(11, int(h*0.022))}" fill="#6A7A94">NOT physical Pixel · NOT human validation</text>
</svg>'''
        svg_path = AFTER / f"_tmp_{sid}_{vid}.svg"
        out = AFTER / f"after_{sid}_{vid}.png"
        svg_path.write_text(svg)
        subprocess.check_call(["rsvg-convert", "-w", str(w), "-h", str(h), "-o", str(out), str(svg_path)])
        svg_path.unlink(missing_ok=True)
        shots.append({"surface": sid, "viewport": vid, "ok": out.exists(), "file": out.name, "capture_class": "brand_fixture_composite"})

for suffix, label, bg in [("high-contrast", "High Contrast", "#000000"), ("reduce-motion", "Reduce Motion", "#0A1220")]:
    w, h = 1440, 900
    svg = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}">
  <rect width="{w}" height="{h}" fill="{bg}"/>
  <rect x="80" y="120" width="200" height="200" fill="none" stroke="#FFE033" stroke-width="6"/>
  <text x="320" y="220" font-family="Georgia, serif" font-size="48" fill="#FFFFFF">Anime Aggressors</text>
  <rect x="320" y="280" width="360" height="90" fill="#111" stroke="#FFE033" stroke-width="4"/>
  <text x="500" y="340" text-anchor="middle" font-family="Georgia, serif" font-size="36" fill="#FFE033">FIGHT</text>
  <text x="80" y="80" font-family="Georgia, serif" font-size="28" fill="#FFE033">Main Menu · {label}</text>
  <text x="80" y="860" font-family="Georgia, serif" font-size="18" fill="#CCCCCC">fixture composite · NOT physical Pixel</text>
</svg>'''
    svg_path = AFTER / f"_tmp_a11y_{suffix}.svg"
    out = AFTER / f"after_main_menu_desktop-1440x900_{suffix}.png"
    svg_path.write_text(svg)
    subprocess.check_call(["rsvg-convert", "-w", str(w), "-h", str(h), "-o", str(out), str(svg_path)])
    svg_path.unlink(missing_ok=True)
    shots.append({"surface": "main_menu", "viewport": "desktop-1440x900", "ok": True, "file": out.name, "variant": suffix, "capture_class": "brand_fixture_composite"})

manifest = {
    "program": "VXP-2",
    "capture_class": "brand_fixture_composite",
    "note": "Godot headless framebuffer readback unavailable; composites use original VXP-2 brand assets.",
    "physical_pixel": False,
    "human_validation": False,
    "godot_harness_attempted": True,
    "godot_harness_framebuffer_ok": False,
    "shots": shots,
}
(MAN / "VXP2_SCREENSHOT_MANIFEST.json").write_text(json.dumps(manifest, indent=2) + "\n")
print(f"composed {len(shots)} shots")
