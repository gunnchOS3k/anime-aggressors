#!/usr/bin/env python3
"""Write the v9 A–Z report. Never claims human-authored final art."""
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
    return "PASS" if value else "FAIL"


def main() -> None:
    gates = read("VXP3_GENERATED_ART_V9_GATES.json")
    geom = read("GENERATED_ART_V9_GEOMETRY.json")
    quality = read("GENERATED_ART_V9_QUALITY.json")
    attach = read("GENERATED_ART_V9_ATTACHMENT_INTEGRITY.json")
    cam = read("REVIEW_CAMERA_ORIENTATION_V9.json")
    hero = {}
    hero_path = ROOT / "game-godot/data/art/generated_v9/hero_proportion_profiles.json"
    if hero_path.is_file():
        hero = json.loads(hero_path.read_text(encoding="utf-8")).get("fighters") or {}
    head = gates.get("head_sha") or sh(["git", "rev-parse", "HEAD"])
    fighters = geom.get("fighters") or {}
    honest = quality.get("honest_stills") or {}
    qf = quality.get("fighters") or {}
    cycles = quality.get("cycles") or []
    candidate = bool(quality.get("GENERATED_REVIEW_CANDIDATE"))
    ceiling = bool(quality.get("GENERATED_ART_RELEASE_CEILING_REACHED"))
    lines = [
        "# Generated Art v9 A–Z",
        "",
        "Generated production art only. Heroic proportions + contact choreography on the graphic low-poly cel lock. Not human-authored final art. Do not merge. Do not touch RC1.",
        "",
        f"**A new head:** `{head}`",
        "**PR:** https://github.com/gunnchOS3k/anime-aggressors/pull/106",
        "**Base:** `6cd1b3100a7e467c2c991394576891660deb1162`",
        "**RC1:** `v1.0.0-rc.1` untouched",
        "",
        "## B two-cycle iteration evidence",
        "",
    ]
    if cycles:
        for i, cycle in enumerate(cycles, 1):
            lines.append(f"- cycle {i}: {cycle}")
    else:
        lines.append("- pending generate/render/revise cycles")
    lines.extend(["", "## C hero proportion profiles", ""])
    for fid, row in hero.items():
        lines.append(
            f"- {fid}: shoulder={row.get('shoulder_scale')} hand={row.get('hand_scale')} boot={row.get('boot_scale')} head={row.get('head_scale')} feature={row.get('hero_feature_scale')} line={row.get('action_line')}"
        )
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
        qrow = qf.get(fid) or {}
        lines.extend(
            [
                "",
                f"## {title}",
                "",
                f"- construction: {row.get('construction')}",
                f"- triangles: {row.get('triangles')}",
                f"- costume_parts: {row.get('costume_parts')} attachments={row.get('attachment_count')}",
                f"- value_groups: {qrow.get('value_groups')} collapse={qrow.get('value_collapse')}",
                f"- defender: {qrow.get('defender')}",
                f"- contact_distance: {qrow.get('contact_distance')} overlap={qrow.get('body_overlap')} sep={qrow.get('silhouette_separation')} geom={qrow.get('pair_contact_geometry')}",
                f"- pair_two_figures: {qrow.get('pair_two_figures')}",
                f"- honest still: {honest.get(fid) or 'pending visual read'}",
            ]
        )
    lines.extend(
        [
            "",
            f"## K glove silhouettes: digital={yn(geom.get('GEN_ART_V9_GLOVE_READ_DIGITAL'))} visual={yn(gates.get('GEN_ART_V9_GLOVE_SILHOUETTE_PASS'))}",
            f"## L boot silhouettes: digital={yn(geom.get('GEN_ART_V9_BOOT_READ_DIGITAL'))} visual={yn(gates.get('GEN_ART_V9_BOOT_SILHOUETTE_PASS'))}",
            f"## M idle identity: {yn(gates.get('GEN_ART_V9_IDLE_BODY_LANGUAGE_PASS'))}",
            f"## N locomotion identity: {yn(gates.get('GEN_ART_V9_LOCOMOTION_IDENTITY_PASS'))}",
            f"## O impact composition: digital={yn(quality.get('GEN_ART_V9_IMPACT_COMPOSITION_DIGITAL'))} visual={yn(gates.get('GEN_ART_V9_IMPACT_COMPOSITION_PASS'))}",
            "",
            f"## P Ember/Rook heavies: ember_geom={ (qf.get('ember-vale') or {}).get('pair_contact_geometry') } rook_geom={ (qf.get('rook-ironside') or {}).get('pair_contact_geometry') }",
            f"## Q Juno/Kaia heavies: juno_geom={ (qf.get('juno-spark') or {}).get('pair_contact_geometry') } kaia_geom={ (qf.get('kaia-windrow') or {}).get('pair_contact_geometry') }",
            f"## R Nix/Orion/Vesper heavies: nix={ (qf.get('nix-calder') or {}).get('pair_contact_geometry') } orion={ (qf.get('orion-vell') or {}).get('pair_contact_geometry') } vesper={ (qf.get('vesper-nyx') or {}).get('pair_contact_geometry') }",
            f"## S hurt silhouettes: {yn(gates.get('GEN_ART_V9_HURT_SILHOUETTE_PASS'))}",
            f"## T charge silhouettes: {yn(gates.get('GEN_ART_V9_CHARGE_SILHOUETTE_PASS'))}",
            f"## U super silhouettes: {yn(gates.get('GEN_ART_V9_SUPER_FREEZE_FRAME_PASS'))}",
            f"## V clash force read: {yn(gates.get('GEN_ART_V9_CLASH_FORCE_READ_PASS'))}",
            "",
            "## W v9 gate matrix",
            "",
            f"- GEN_ART_V9_ATTACHMENT_INTEGRITY_PASS: {gates.get('GEN_ART_V9_ATTACHMENT_INTEGRITY_PASS')} unintentional_float={gates.get('UNINTENTIONAL_FLOATING_ART_PARTS')}",
            f"- GEN_ART_V9_VALUE_BLOCKING_PASS: {gates.get('GEN_ART_V9_VALUE_BLOCKING_PASS')}",
            f"- GEN_ART_V9_SCREEN_SPACE_READ_PASS: {gates.get('GEN_ART_V9_SCREEN_SPACE_READ_PASS')}",
            f"- GEN_ART_V9_GLOVE_SILHOUETTE_PASS: {gates.get('GEN_ART_V9_GLOVE_SILHOUETTE_PASS')}",
            f"- GEN_ART_V9_BOOT_SILHOUETTE_PASS: {gates.get('GEN_ART_V9_BOOT_SILHOUETTE_PASS')}",
            f"- GEN_ART_V9_IDLE_BODY_LANGUAGE_PASS: {gates.get('GEN_ART_V9_IDLE_BODY_LANGUAGE_PASS')}",
            f"- GEN_ART_V9_LOCOMOTION_IDENTITY_PASS: {gates.get('GEN_ART_V9_LOCOMOTION_IDENTITY_PASS')}",
            f"- GEN_ART_V9_IMPACT_COMPOSITION_PASS: {gates.get('GEN_ART_V9_IMPACT_COMPOSITION_PASS')}",
            f"- GEN_ART_V9_HURT_SILHOUETTE_PASS: {gates.get('GEN_ART_V9_HURT_SILHOUETTE_PASS')}",
            f"- GEN_ART_V9_CONTACT_FREEZE_FRAME_PASS: {gates.get('GEN_ART_V9_CONTACT_FREEZE_FRAME_PASS')}",
            f"- GEN_ART_V9_CHARGE_SILHOUETTE_PASS: {gates.get('GEN_ART_V9_CHARGE_SILHOUETTE_PASS')}",
            f"- GEN_ART_V9_SUPER_FREEZE_FRAME_PASS: {gates.get('GEN_ART_V9_SUPER_FREEZE_FRAME_PASS')}",
            f"- GEN_ART_V9_CLASH_FORCE_READ_PASS: {gates.get('GEN_ART_V9_CLASH_FORCE_READ_PASS')}",
            f"- GEN_ART_V9_MOBILE_READ_PASS: {gates.get('GEN_ART_V9_MOBILE_READ_PASS')}",
            f"- FRONT_CAMERA_CORRECT: {cam.get('FRONT_CAMERA_CORRECT', 'pending')}",
            f"- WAVE014: {yn(gates.get('WAVE014_GENERATED_RUNTIME_DISCOVERY_PASS'))}",
            f"- WAVE020: {yn(gates.get('WAVE020_ROSTER_VISIBILITY_PASS'))}",
            f"- HUMAN_*: all false",
            f"- MERGE_AUTHORIZED: false",
            f"- attach_ok: {attach.get('ok')}",
            "",
            f"## X exact-head CI: {quality.get('ci_note', 'pending after push')}",
            f"## Y APK/Pixel: {quality.get('apk_note', 'not eligible unless GENERATED_REVIEW_CANDIDATE and exact-head CI are green')}",
            "",
            "## Z generated-review-candidate vs release-ceiling",
            "",
            f"GENERATED_REVIEW_CANDIDATE={str(candidate).lower()}",
            f"GENERATED_ART_RELEASE_CEILING_REACHED={str(ceiling).lower()}",
            "",
            quality.get("note") or "Inspect v9 stills. Do not merge.",
            "",
            f"Next human step: {quality.get('next_human') or 'Review artifacts/vxp3/review/generated_art_v9/ stills. Do not set HUMAN_* or MERGE.'}",
            "",
        ]
    )
    text = "\n".join(lines) + "\n"
    (REPORTS / "GENERATED_ART_V9_AZ.md").write_text(text)
    print(text)


if __name__ == "__main__":
    main()
