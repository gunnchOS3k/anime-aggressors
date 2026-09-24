#!/usr/bin/env python3
"""Write the v7 A–Z report. Never claims human-authored final art."""
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
    gates = read("VXP3_GENERATED_ART_V7_GATES.json")
    geom = read("GENERATED_ART_V7_GEOMETRY.json")
    quality = read("GENERATED_ART_V7_QUALITY.json")
    masters = read("GENERATED_ART_V7_MASTERS.json")
    cam = read("REVIEW_CAMERA_ORIENTATION_V7.json")
    head = gates.get("head_sha") or sh(["git", "rev-parse", "HEAD"])
    fighters = geom.get("fighters") or {}
    honest = quality.get("honest_stills") or {}
    qf = quality.get("fighters") or {}
    lines = [
        "# Generated Art v7 A–Z",
        "",
        "Generated production art only. Graphic combat polish on the v6 style lock. Not human-authored final art. Do not merge.",
        "",
        f"**A new head:** `{head}`",
        "**PR:** https://github.com/gunnchOS3k/anime-aggressors/pull/106",
        "**Base:** `6cd1b3100a7e467c2c991394576891660deb1162`",
        "**RC1:** `v1.0.0-rc.1` untouched",
        "",
        f"## B Nix value split: digital={yn(not (qf.get('nix-calder') or {}).get('value_collapse'))} gate={yn(gates.get('GEN_ART_V7_VALUE_BLOCKING_PASS'))}",
        "",
        f"## C roster value blocking: {yn(quality.get('GEN_ART_V7_VALUE_BLOCKING_DIGITAL'))}",
        "",
        f"## D detail-camera fixes: {yn(quality.get('GEN_ART_V7_DETAIL_CAMERA_DIGITAL'))} gate={yn(gates.get('GEN_ART_V7_DETAIL_CAMERA_PASS'))}",
        "",
        f"## E glove polish: digital={yn(geom.get('GEN_ART_V7_GLOVE_READ_DIGITAL'))} gate={yn(gates.get('GEN_ART_V7_GLOVE_READ_PASS'))}",
        "",
        f"## F boot polish: digital={yn(geom.get('GEN_ART_V7_BOOT_READ_DIGITAL'))} gate={yn(gates.get('GEN_ART_V7_BOOT_READ_PASS'))}",
        "",
        f"## G costume hero features: {yn(gates.get('GEN_ART_V7_HERO_FEATURE_READ_PASS'))}",
        "",
    ]
    order = [
        ("H Ember", "ember-vale"),
        ("I Rook", "rook-ironside"),
        ("J Juno", "juno-spark"),
        ("K Kaia", "kaia-windrow"),
        ("L Nix", "nix-calder"),
        ("M Orion", "orion-vell"),
        ("N Vesper", "vesper-nyx"),
    ]
    for title, fid in order:
        row = fighters.get(fid) or {}
        qrow = qf.get(fid) or {}
        lines.append(f"## {title}")
        lines.append("")
        lines.append(f"- construction: {row.get('construction')}")
        lines.append(f"- triangles: {row.get('triangles')}")
        lines.append(f"- glove_family: {row.get('glove_family')}")
        lines.append(f"- hero_feature_parts: {row.get('hero_feature_parts')}")
        lines.append(f"- value_groups: {qrow.get('value_groups')} collapse={qrow.get('value_collapse')}")
        lines.append(f"- defender: {qrow.get('defender')}")
        lines.append(f"- packet_complete: {row.get('packet_complete')} missing={row.get('missing_shots')}")
        if honest.get(fid):
            lines.append(f"- honest still: {honest[fid]}")
        lines.append("")
    lines.extend(
        [
            f"## O idle/locomotion identity: {yn(gates.get('GEN_ART_V7_IDLE_IDENTITY_PASS'))}",
            f"## P heavy-contact pairs: {yn(gates.get('GEN_ART_V7_HEAVY_PAIR_READ_PASS'))}",
            f"## Q hurt acting: {yn(gates.get('GEN_ART_V7_HURT_ACTING_PASS'))}",
            f"## R charge transformation: {yn(gates.get('GEN_ART_V7_CHARGE_TRANSFORM_PASS'))}",
            f"## S super poses: {yn(gates.get('GEN_ART_V7_SUPER_HERO_POSE_PASS'))}",
            f"## T clash acting: {yn(gates.get('GEN_ART_V7_CLASH_ACTING_PASS'))}",
            f"## U select/mobile: select={yn(gates.get('GEN_ART_V7_SELECT_PRESENTATION_PASS'))} mobile={yn(gates.get('GEN_ART_V7_MOBILE_READ_PASS'))}",
            f"## V review packet: artifacts/vxp3/review/generated_art_v7/ FRONT_CAMERA_CORRECT={cam.get('FRONT_CAMERA_CORRECT', 'pending')}",
            "",
            "## W v7 gates",
            "",
            f"- GEN_ART_V7_VALUE_BLOCKING_PASS: {gates.get('GEN_ART_V7_VALUE_BLOCKING_PASS')}",
            f"- GEN_ART_V7_DETAIL_CAMERA_PASS: {gates.get('GEN_ART_V7_DETAIL_CAMERA_PASS')}",
            f"- GEN_ART_V7_HEAVY_PAIR_READ_PASS: {gates.get('GEN_ART_V7_HEAVY_PAIR_READ_PASS')}",
            f"- WAVE014: {yn(gates.get('WAVE014_GENERATED_RUNTIME_DISCOVERY_PASS'))}",
            f"- WAVE020: {yn(gates.get('WAVE020_ROSTER_VISIBILITY_PASS'))}",
            f"- GENERATED_ART_RELEASE_CEILING_REACHED: {gates.get('GENERATED_ART_RELEASE_CEILING_REACHED')}",
            f"- HUMAN_*: all false",
            f"- MERGE_AUTHORIZED: false",
            "",
            f"## X exact-head CI: {quality.get('ci_note', 'pending after push')}",
            f"## Y APK/Pixel: {quality.get('apk_note', 'not eligible unless packet + digital gates + exact-head CI are green and stills are not obvious toys')}",
            "",
            "## Z remaining defects / next action",
            "",
            quality.get("note") or "Inspect v7 stills. Do not merge.",
            "",
            f"Next human step: {quality.get('next_human') or 'Review artifacts/vxp3/review/generated_art_v7/ stills. Do not set HUMAN_* or MERGE. Do not install an APK unless eligibility is earned.'}",
            "",
        ]
    )
    text = "\n".join(lines) + "\n"
    (REPORTS / "GENERATED_ART_V7_AZ.md").write_text(text)
    print(text)


if __name__ == "__main__":
    main()
