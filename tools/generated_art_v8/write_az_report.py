#!/usr/bin/env python3
"""Write the v8 A–Z report. Never claims human-authored final art."""
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
    gates = read("VXP3_GENERATED_ART_V8_GATES.json")
    geom = read("GENERATED_ART_V8_GEOMETRY.json")
    quality = read("GENERATED_ART_V8_QUALITY.json")
    attach = read("GENERATED_ART_V8_ATTACHMENT_INTEGRITY.json")
    cam = read("REVIEW_CAMERA_ORIENTATION_V8.json")
    head = gates.get("head_sha") or sh(["git", "rev-parse", "HEAD"])
    fighters = geom.get("fighters") or {}
    honest = quality.get("honest_stills") or {}
    qf = quality.get("fighters") or {}
    lines = [
        "# Generated Art v8 A–Z",
        "",
        "Generated production art only. Rigged costume integrity + impact choreography on the v6/v7 graphic style. Not human-authored final art. Do not merge.",
        "",
        f"**A new head:** `{head}`",
        "**PR:** https://github.com/gunnchOS3k/anime-aggressors/pull/106",
        "**Base:** `6cd1b3100a7e467c2c991394576891660deb1162`",
        "**RC1:** `v1.0.0-rc.1` untouched",
        "",
        f"## B attachment architecture: structural={yn(attach.get('ok'))}",
        "",
        f"## C attachment integrity: {yn(gates.get('GEN_ART_V8_ATTACHMENT_INTEGRITY_PASS'))} unintentional_float={gates.get('UNINTENTIONAL_FLOATING_ART_PARTS')}",
        "",
        f"## D Nix regression: digital={yn(not (qf.get('nix-calder') or {}).get('value_collapse'))}",
        "",
        f"## E Juno value split: groups={(qf.get('juno-spark') or {}).get('value_groups')} collapse={(qf.get('juno-spark') or {}).get('value_collapse')}",
        f"## F Kaia value split: groups={(qf.get('kaia-windrow') or {}).get('value_groups')} collapse={(qf.get('kaia-windrow') or {}).get('value_collapse')}",
        f"## G Orion value split: groups={(qf.get('orion-vell') or {}).get('value_groups')} collapse={(qf.get('orion-vell') or {}).get('value_collapse')}",
        f"## H Vesper value split: groups={(qf.get('vesper-nyx') or {}).get('value_groups')} collapse={(qf.get('vesper-nyx') or {}).get('value_collapse')}",
        "",
        f"## I roster value matrix: {yn(quality.get('GEN_ART_V8_VALUE_BLOCKING_DIGITAL'))} gate={yn(gates.get('GEN_ART_V8_VALUE_BLOCKING_PASS'))}",
        f"## J gloves: digital={yn(geom.get('GEN_ART_V8_GLOVE_READ_DIGITAL'))} gate={yn(gates.get('GEN_ART_V8_GLOVE_GAMEPLAY_READ_PASS'))}",
        f"## K boots: digital={yn(geom.get('GEN_ART_V8_BOOT_READ_DIGITAL'))} gate={yn(gates.get('GEN_ART_V8_BOOT_GAMEPLAY_READ_PASS'))}",
        f"## L detail cameras: {yn(quality.get('GEN_ART_V8_DETAIL_CAMERA_DIGITAL'))}",
        f"## M idle/locomotion identity: {yn(gates.get('GEN_ART_V8_IDLE_LOCOMOTION_IDENTITY_PASS'))}",
        f"## N pair-contact solver: {yn(quality.get('GEN_ART_V8_PAIR_CONTACT_GEOMETRY_DIGITAL'))} gate={yn(gates.get('GEN_ART_V8_PAIR_CONTACT_GEOMETRY_PASS'))}",
        "",
    ]
    order = [
        ("O Ember heavy pair", "ember-vale"),
        ("P Rook heavy pair", "rook-ironside"),
        ("Q Juno heavy pair", "juno-spark"),
        ("R Kaia heavy pair", "kaia-windrow"),
        ("S Nix heavy pair", "nix-calder"),
        ("T Orion heavy pair", "orion-vell"),
        ("U Vesper heavy pair", "vesper-nyx"),
    ]
    for title, fid in order:
        row = fighters.get(fid) or {}
        qrow = qf.get(fid) or {}
        lines.append(f"## {title}")
        lines.append("")
        lines.append(f"- construction: {row.get('construction')}")
        lines.append(f"- triangles: {row.get('triangles')}")
        lines.append(f"- costume_parts: {row.get('costume_parts')} attachments={row.get('attachment_count')}")
        lines.append(f"- value_groups: {qrow.get('value_groups')} collapse={qrow.get('value_collapse')}")
        lines.append(f"- defender: {qrow.get('defender')}")
        lines.append(f"- contact_distance: {qrow.get('contact_distance')} overlap={qrow.get('body_overlap')} geom={qrow.get('pair_contact_geometry')}")
        lines.append(f"- pair_two_figures: {qrow.get('pair_two_figures')}")
        if honest.get(fid):
            lines.append(f"- honest still: {honest[fid]}")
        lines.append("")
    lines.extend(
        [
            f"## V hurt / charge / super / clash: hurt={yn(gates.get('GEN_ART_V8_HURT_ACTING_PASS'))} charge={yn(gates.get('GEN_ART_V8_CHARGE_BODY_READ_PASS'))} super={yn(gates.get('GEN_ART_V8_SUPER_HERO_POSE_PASS'))} clash={yn(gates.get('GEN_ART_V8_CLASH_BODY_ACTING_PASS'))}",
            "",
            "## W v8 gates",
            "",
            f"- GEN_ART_V8_ATTACHMENT_INTEGRITY_PASS: {gates.get('GEN_ART_V8_ATTACHMENT_INTEGRITY_PASS')}",
            f"- GEN_ART_V8_VALUE_BLOCKING_PASS: {gates.get('GEN_ART_V8_VALUE_BLOCKING_PASS')}",
            f"- GEN_ART_V8_PAIR_CONTACT_GEOMETRY_PASS: {gates.get('GEN_ART_V8_PAIR_CONTACT_GEOMETRY_PASS')}",
            f"- GEN_ART_V8_HEAVY_CONTACT_VISUAL_READ_PASS: {gates.get('GEN_ART_V8_HEAVY_CONTACT_VISUAL_READ_PASS')} (owner-judged; not auto-passed)",
            f"- FRONT_CAMERA_CORRECT: {cam.get('FRONT_CAMERA_CORRECT', 'pending')}",
            f"- WAVE014: {yn(gates.get('WAVE014_GENERATED_RUNTIME_DISCOVERY_PASS'))}",
            f"- WAVE020: {yn(gates.get('WAVE020_ROSTER_VISIBILITY_PASS'))}",
            f"- GENERATED_ART_RELEASE_CEILING_REACHED: {gates.get('GENERATED_ART_RELEASE_CEILING_REACHED')}",
            f"- HUMAN_*: all false",
            f"- MERGE_AUTHORIZED: false",
            "",
            f"## X exact-head CI: {quality.get('ci_note', 'pending after push')}",
            f"## Y APK/Pixel: {quality.get('apk_note', 'not eligible unless structural gates + contact + no explode + exact-head CI are green and stills are not obvious toys')}",
            "",
            "## Z generated-review-candidate vs release-ceiling",
            "",
            quality.get("note") or "Inspect v8 stills. Do not merge.",
            "",
            f"Next human step: {quality.get('next_human') or 'Review artifacts/vxp3/review/generated_art_v8/ stills. Do not set HUMAN_* or MERGE. Do not install an APK unless eligibility is earned.'}",
            "",
        ]
    )
    text = "\n".join(lines) + "\n"
    (REPORTS / "GENERATED_ART_V8_AZ.md").write_text(text)
    print(text)


if __name__ == "__main__":
    main()
