#!/usr/bin/env python3
"""Write the v5 A–Z report. Never claims human-authored final art."""
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
    gates = read("VXP3_GENERATED_ART_V5_GATES.json")
    geom = read("GENERATED_ART_V5_GEOMETRY.json")
    quality = read("GENERATED_ART_V5_QUALITY.json")
    masters = read("GENERATED_ART_V5_MASTERS.json")
    cam = read("REVIEW_CAMERA_ORIENTATION_V5.json")
    head = gates.get("head_sha") or sh(["git", "rev-parse", "HEAD"])
    fighters = (geom.get("fighters") or {})
    visual = quality.get("visual") or {}
    lines = [
        "# Generated Art v5 A–Z",
        "",
        "Generated production art only. Not human-authored final art. Do not merge.",
        "",
        f"**A new head:** `{head}`",
        f"**PR:** https://github.com/gunnchOS3k/anime-aggressors/pull/106",
        f"**Base:** `6cd1b3100a7e467c2c991394576891660deb1162`",
        f"**RC1:** `v1.0.0-rc.1` untouched",
        "",
        "## B non-remesh generator architecture",
        "",
        "- `tools/generated_art_v5/` loft/profile builders (torso, limbs, joints, hands, boots, heads, costume shells)",
        "- Construction: `profile_loft_no_voxel_remesh`",
        f"- Digital no-remesh: {yn(geom.get('GEN_ART_V5_NO_VOXEL_REMESH'))}",
        f"- Masters ok: {masters.get('ok')}",
        "",
        f"## C body surface: digital={yn(geom.get('GEN_ART_V5_BODY_SURFACE_DIGITAL'))} visual={yn(gates.get('GEN_ART_V5_BODY_SURFACE_PASS'))}",
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
        lines.append(f"- packet_complete: {row.get('packet_complete')} missing={row.get('missing_shots')}")
        lines.append(f"- hand/boot/head/costume parts: {row.get('hand_parts')}/{row.get('boot_parts')}/{row.get('head_parts')}/{row.get('costume_parts')}")
        lines.append("")
    lines.extend(
        [
            f"## K hands: digital={yn(geom.get('GEN_ART_V5_HAND_MODEL_DIGITAL'))} visual={yn(gates.get('GEN_ART_V5_HAND_MODEL_PASS'))}",
            f"## L boots: digital={yn(geom.get('GEN_ART_V5_BOOT_MODEL_DIGITAL'))} visual={yn(gates.get('GEN_ART_V5_BOOT_MODEL_PASS'))}",
            f"## M heads: digital={yn(geom.get('GEN_ART_V5_HEAD_MODEL_DIGITAL'))} visual={yn(gates.get('GEN_ART_V5_HEAD_MODEL_PASS'))}",
            f"## N costume shells/coverage: digital={yn(geom.get('GEN_ART_V5_COSTUME_SHELL_DIGITAL'))} visual={yn(gates.get('GEN_ART_V5_COSTUME_SHELL_PASS'))}/{yn(gates.get('GEN_ART_V5_COSTUME_COVERAGE_PASS'))}",
            f"## O materials: {yn(gates.get('GEN_ART_V5_MATERIAL_READ_PASS'))}",
            f"## P deformation: {yn(gates.get('GEN_ART_V5_DEFORMATION_PASS'))}",
            "## Q animation retarget: same 22-bone rig, sockets, action IDs; v5 hero overlays on idle/charge/hurt/super/clash",
            f"## R heavy/hurt: {yn(gates.get('GEN_ART_V5_HEAVY_CONTACT_READ_PASS'))} / {yn(gates.get('GEN_ART_V5_HURT_READ_PASS'))}",
            f"## S charge: {yn(gates.get('GEN_ART_V5_CHARGE_BODY_READ_PASS'))}",
            f"## T super: {yn(gates.get('GEN_ART_V5_SUPER_READ_PASS'))}",
            f"## U clash acting: {yn(gates.get('GEN_ART_V5_CLASH_ACTING_PASS'))}",
            f"## V review packet: artifacts/vxp3/review/generated_art_v5/ FRONT_CAMERA_CORRECT={cam.get('FRONT_CAMERA_CORRECT', 'pending')}",
            "",
            "## W v5 gates",
            "",
            f"- VISUAL_REMESH_TOY_REMAINING: {gates.get('VISUAL_REMESH_TOY_REMAINING', True)}",
            f"- WAVE014: {yn(gates.get('WAVE014_GENERATED_RUNTIME_DISCOVERY_PASS'))}",
            f"- WAVE020: {yn(gates.get('WAVE020_ROSTER_VISIBILITY_PASS'))}",
            f"- HUMAN_*: all false",
            f"- MERGE_AUTHORIZED: false",
            "",
            f"## X exact-head CI: {quality.get('ci_note', 'not re-run in this packet unless stills stop reading as remesh toys')}",
            f"## Y APK/Pixel: {quality.get('apk_note', 'not eligible — file forbids APK until v5 stills stop reading as remesh toys and exact-head CI is green')}",
            "",
            "## Z remaining defects / next action",
            "",
            quality.get("note") or "Inspect v5 stills. If they still read as toys, iterate the loft/costume parameters. Do not merge.",
            "",
            f"Next human step: {quality.get('next_human') or 'Review artifacts/vxp3/review/generated_art_v5/ stills. Do not set HUMAN_* or MERGE. Do not install an APK until the packet no longer reads as remesh toys.'}",
            "",
        ]
    )
    text = "\n".join(lines) + "\n"
    (REPORTS / "GENERATED_ART_V5_AZ.md").write_text(text)
    print(text)


if __name__ == "__main__":
    main()
