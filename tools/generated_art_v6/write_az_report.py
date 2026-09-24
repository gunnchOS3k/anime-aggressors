#!/usr/bin/env python3
"""Write the v6 A–Z report. Never claims human-authored final art."""
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
    gates = read("VXP3_GENERATED_ART_V6_GATES.json")
    geom = read("GENERATED_ART_V6_GEOMETRY.json")
    quality = read("GENERATED_ART_V6_QUALITY.json")
    masters = read("GENERATED_ART_V6_MASTERS.json")
    cam = read("REVIEW_CAMERA_ORIENTATION_V6.json")
    head = gates.get("head_sha") or sh(["git", "rev-parse", "HEAD"])
    fighters = geom.get("fighters") or {}
    honest = quality.get("honest_stills") or {}
    lines = [
        "# Generated Art v6 A–Z",
        "",
        "Generated production art only. Graphic combat style lock. Not human-authored final art. Do not merge.",
        "",
        f"**A new head:** `{head}`",
        f"**PR:** https://github.com/gunnchOS3k/anime-aggressors/pull/106",
        f"**Base:** `6cd1b3100a7e467c2c991394576891660deb1162`",
        f"**RC1:** `v1.0.0-rc.1` untouched",
        "",
        "## B v6 style-lock architecture",
        "",
        "- `docs/art/GENERATED_ART_V6_STYLE_LOCK.md`",
        "- `tools/generated_art_v6/` undersuit + gloves + boots + masks + costume masses + cel materials",
        "- Construction: `profile_loft_no_voxel_remesh` (v5 loft kept as understructure)",
        "- Visible style: `graphic_lowpoly_cel_combat`",
        f"- Digital style lock: {yn(geom.get('GEN_ART_V6_STYLE_LOCK_DIGITAL'))}",
        f"- Masters ok: {masters.get('ok')}",
        "",
        f"## C full-suit coverage: digital={yn(geom.get('GEN_ART_V6_FULL_SUIT_COVERAGE_DIGITAL'))} peach_forbidden={yn(quality.get('GEN_ART_V6_NO_PEACH_BODY_DIGITAL'))} gate={yn(gates.get('GEN_ART_V6_FULL_SUIT_COVERAGE_PASS'))}",
        "",
    ]
    order = [
        ("D Ember", "ember-vale"),
        ("E Rook", "rook-ironside"),
        ("F Juno", "juno-spark"),
        ("G Kaia", "kaia-windrow"),
        ("H Nix", "nix-calder"),
        ("I Orion", "orion-vell"),
        ("J Vesper", "vesper-nyx"),
    ]
    for title, fid in order:
        row = fighters.get(fid) or {}
        lines.append(f"## {title}")
        lines.append("")
        lines.append(f"- construction: {row.get('construction')}")
        lines.append(f"- used_voxel_remesh: {row.get('used_voxel_remesh')}")
        lines.append(f"- triangles: {row.get('triangles')}")
        lines.append(f"- glove_family: {row.get('glove_family')}")
        lines.append(f"- undersuit: {row.get('undersuit')}")
        lines.append(f"- packet_complete: {row.get('packet_complete')} missing={row.get('missing_shots')}")
        lines.append(f"- hand/boot/head/costume parts: {row.get('hand_parts')}/{row.get('boot_parts')}/{row.get('head_parts')}/{row.get('costume_parts')}")
        if honest.get(fid):
            lines.append(f"- honest still: {honest[fid]}")
        lines.append("")
    lines.extend(
        [
            f"## K gloves: digital={yn(geom.get('GEN_ART_V6_GLOVE_READ_DIGITAL'))} gate={yn(gates.get('GEN_ART_V6_GLOVE_READ_PASS'))}",
            f"## L boots: digital={yn(geom.get('GEN_ART_V6_BOOT_READ_DIGITAL'))} gate={yn(gates.get('GEN_ART_V6_BOOT_READ_PASS'))}",
            f"## M masks/heads: digital={yn(geom.get('GEN_ART_V6_MASK_HEAD_READ_DIGITAL'))} gate={yn(gates.get('GEN_ART_V6_MASK_HEAD_READ_PASS'))}",
            f"## N costume masses: digital={yn(geom.get('GEN_ART_V6_COSTUME_MASS_DIGITAL'))} gate={yn(gates.get('GEN_ART_V6_COSTUME_MASS_PASS'))}",
            f"## O value blocking: digital={yn(quality.get('GEN_ART_V6_VALUE_BLOCKING_DIGITAL'))} gate={yn(gates.get('GEN_ART_V6_VALUE_BLOCKING_PASS'))}",
            f"## P cel materials: {yn(gates.get('GEN_ART_V6_CEL_MATERIAL_PASS'))}",
            f"## Q silhouette results: {yn(gates.get('GEN_ART_V6_SILHOUETTE_PASS'))}",
            f"## R idle/locomotion identity: {yn(gates.get('GEN_ART_V6_IDLE_IDENTITY_PASS'))}",
            f"## S heavy/hurt: {yn(gates.get('GEN_ART_V6_HEAVY_CONTACT_READ_PASS'))} / {yn(gates.get('GEN_ART_V6_HURT_READ_PASS'))}",
            f"## T charge: {yn(gates.get('GEN_ART_V6_CHARGE_BODY_READ_PASS'))}",
            f"## U super/clash: {yn(gates.get('GEN_ART_V6_SUPER_SILHOUETTE_PASS'))} / {yn(gates.get('GEN_ART_V6_CLASH_ACTING_PASS'))}",
            f"## V review packet: artifacts/vxp3/review/generated_art_v6/ FRONT_CAMERA_CORRECT={cam.get('FRONT_CAMERA_CORRECT', 'pending')}",
            "",
            "## W v6 gates",
            "",
            f"- GEN_ART_V6_STYLE_LOCK_PASS: {gates.get('GEN_ART_V6_STYLE_LOCK_PASS')}",
            f"- WAVE014: {yn(gates.get('WAVE014_GENERATED_RUNTIME_DISCOVERY_PASS'))}",
            f"- WAVE020: {yn(gates.get('WAVE020_ROSTER_VISIBILITY_PASS'))}",
            f"- GENERATED_ART_RELEASE_CEILING_REACHED: {gates.get('GENERATED_ART_RELEASE_CEILING_REACHED')}",
            f"- HUMAN_*: all false",
            f"- MERGE_AUTHORIZED: false",
            "",
            f"## X exact-head CI: {quality.get('ci_note', 'pending after push')}",
            f"## Y APK/Pixel: {quality.get('apk_note', 'not eligible unless packet + digital gates + exact-head CI are green')}",
            "",
            "## Z remaining defects / next action",
            "",
            quality.get("note") or "Inspect v6 stills. Do not merge.",
            "",
            f"Next human step: {quality.get('next_human') or 'Review artifacts/vxp3/review/generated_art_v6/ stills. Do not set HUMAN_* or MERGE. Do not install an APK unless the file eligibility list is met.'}",
            "",
        ]
    )
    text = "\n".join(lines) + "\n"
    (REPORTS / "GENERATED_ART_V6_AZ.md").write_text(text)
    print(text)


if __name__ == "__main__":
    main()
