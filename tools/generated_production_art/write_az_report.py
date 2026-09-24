#!/usr/bin/env python3
"""Write the v4 A–Z report. Never claims human-authored final art."""
from __future__ import annotations

import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REPORTS = ROOT / "artifacts/vxp3/reports"


def sh(cmd: list[str]) -> str:
    return subprocess.check_output(cmd, cwd=ROOT, text=True).strip()


def read(name: str) -> dict:
    path = REPORTS / name
    if not path.is_file():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def yn(value) -> str:
    return "PASS" if value else "FAIL / pending"


def main() -> None:
    gates = read("VXP3_GENERATED_PRODUCTION_ART_GATES.json")
    quality4 = read("GENERATED_ART_V4_QUALITY.json")
    cam4 = read("REVIEW_CAMERA_ORIENTATION_V4.json")
    head = gates.get("head_sha") or sh(["git", "rev-parse", "HEAD"])
    fighters = (quality4.get("fighters") or {})
    lines = [
        "# Generated Art v4 A–Z",
        "",
        "Generated production art only. Not human-authored final art. Do not merge.",
        "",
        f"**A new head:** `{head}`",
        f"**PR:** https://github.com/gunnchOS3k/anime-aggressors/pull/106",
        f"**Base:** `6cd1b3100a7e467c2c991394576891660deb1162`",
        f"**RC1:** `v1.0.0-rc.1` untouched",
        "",
        "## B exact start CI failures",
        "",
        "- Wave014 procedural_smoke: models_loaded=0 / anim_roots=0 because discovery still required PROCEDURAL_PRODUCTION_PROXY",
        "- Wave020: Kaia silhouette_readable=false (coverage 0.482); headless texture_2d_get null spam",
        "",
        f"## C review-camera: FRONT_CAMERA_CORRECT={cam4.get('FRONT_CAMERA_CORRECT', '0/7')} source={cam4.get('source', 'pending')}",
        "",
        f"## D headless visibility: HEADLESS_VISIBILITY_NO_NULL_PASS={yn(gates.get('HEADLESS_VISIBILITY_NO_NULL_PASS'))}",
        "",
        f"## E Wave014 discovery: WAVE014_GENERATED_RUNTIME_DISCOVERY_PASS={yn(gates.get('WAVE014_GENERATED_RUNTIME_DISCOVERY_PASS'))}",
        "",
        f"## F Wave020 Kaia: WAVE020_ROSTER_VISIBILITY_PASS={yn(gates.get('WAVE020_ROSTER_VISIBILITY_PASS'))}",
        "",
    ]
    order = [
        ("G Ember", "ember-vale"),
        ("H Rook", "rook-ironside"),
        ("I Juno", "juno-spark"),
        ("J Kaia", "kaia-windrow"),
        ("K Nix", "nix-calder"),
        ("L Orion", "orion-vell"),
        ("M Vesper", "vesper-nyx"),
    ]
    for title, fid in order:
        row = fighters.get(fid) or {}
        cov = row.get("coverage") or {}
        lines.append(f"## {title}")
        lines.append("")
        lines.append(f"- front_camera_correct: {row.get('front_camera_correct')}")
        lines.append(f"- packet_complete: {row.get('packet_complete')} missing={row.get('missing_shots')}")
        lines.append(f"- costume front forms: {cov.get('front_named_parts')} verts={cov.get('costume_vertices')}")
        lines.append(f"- pose deltas heavy/hurt/charge/super: {row.get('heavy_delta')}/{row.get('hurt_delta')}/{row.get('charge_delta')}/{row.get('super_delta')}")
        lines.append("")
    lines.extend(
        [
            f"## N hands: {yn(gates.get('GEN_ART_V4_HAND_CRAFT_PASS'))}",
            f"## O boots: {yn(gates.get('GEN_ART_V4_BOOT_CRAFT_PASS'))}",
            f"## P heads: {yn(gates.get('GEN_ART_V4_HEAD_CRAFT_PASS'))}",
            f"## Q costume: {yn(gates.get('GEN_ART_V4_COSTUME_COVERAGE_PASS'))}",
            f"## R materials: {yn(gates.get('GEN_ART_V4_MATERIAL_READ_PASS'))}",
            f"## S heavy/hurt/charge/super: {yn(gates.get('GEN_ART_V4_HEAVY_CONTACT_READ_PASS'))} / {yn(gates.get('GEN_ART_V4_HURT_READ_PASS'))} / {yn(gates.get('GEN_ART_V4_CHARGE_BODY_READ_PASS'))} / {yn(gates.get('GEN_ART_V4_SUPER_READ_PASS'))}",
            f"## T silhouette: {yn(gates.get('GEN_ART_V4_SILHOUETTE_ROSTER_PASS'))}",
            "",
            "## U review packet",
            "",
            "`artifacts/vxp3/review/generated_art_v4/`",
            "",
            "## V v4 gate matrix",
            "",
        ]
    )
    for key in (
        "GEN_ART_V4_FRONT_CAMERA_PASS",
        "GEN_ART_V4_MOBILE_READ_PASS",
        "GEN_ART_V4_HAND_CRAFT_PASS",
        "GEN_ART_V4_BOOT_CRAFT_PASS",
        "GEN_ART_V4_HEAD_CRAFT_PASS",
        "GEN_ART_V4_COSTUME_COVERAGE_PASS",
        "GEN_ART_V4_MATERIAL_READ_PASS",
        "GEN_ART_V4_HERO_POSE_PASS",
        "GEN_ART_V4_HEAVY_CONTACT_READ_PASS",
        "GEN_ART_V4_HURT_READ_PASS",
        "GEN_ART_V4_CHARGE_BODY_READ_PASS",
        "GEN_ART_V4_SUPER_READ_PASS",
        "GEN_ART_V4_SILHOUETTE_ROSTER_PASS",
        "WAVE014_GENERATED_RUNTIME_DISCOVERY_PASS",
        "WAVE020_ROSTER_VISIBILITY_PASS",
        "HEADLESS_VISIBILITY_NO_NULL_PASS",
        "HUMAN_ART_DIRECTION_APPROVAL",
        "MERGE_AUTHORIZED",
    ):
        lines.append(f"- {key}={gates.get(key)}")
    lines.extend(
        [
            "",
            "## W exact-head CI: pending after this push; local Wave014 smoke and Wave020 framing passed on generated GLBs",
            "## X APK: not eligible — stills still read as remesh toys; do not build",
            "## Y Pixel / HUMAN_*: false / not started",
            "## Z remaining defects + next human step: FRONT cameras are contract-correct and Wave014/Wave020 pass locally, but stills still read as remesh toys (block hands, primitive heads, peach remesh around plates). Do not Pixel-review questions 1–12. Do not merge. Owner should inspect `artifacts/vxp3/review/generated_art_v4/` and exact-head CI; a later human/internal art pass is required for Q3-like craft.",
            "",
        ]
    )
    dest = REPORTS / "GENERATED_ART_V4_AZ.md"
    dest.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(dest)


if __name__ == "__main__":
    main()
