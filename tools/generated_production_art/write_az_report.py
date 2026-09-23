#!/usr/bin/env python3
"""Write the v3 A–Z report. Never claims human-authored final art."""
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
    geom3 = read("GENERATED_PRODUCTION_GEOMETRY_V3.json")
    quality = read("GENERATED_ART_V3_QUALITY.json")
    sil = read("GENERATED_ART_V3_SILHOUETTE.json")
    hero = read("GENERATED_ART_V3_HERO.json")
    masters = read("GENERATED_PRODUCTION_MASTERS.json")
    head = gates.get("head_sha") or sh(["git", "rev-parse", "HEAD"])
    lines = [
        "# Generated Art v3 A–Z",
        "",
        "Generated production art only. Not human-authored final art. Do not merge.",
        "",
        f"**A new head:** `{head}`",
        f"**PR:** https://github.com/gunnchOS3k/anime-aggressors/pull/106",
        f"**Base:** `6cd1b3100a7e467c2c991394576891660deb1162`",
        f"**RC1:** `v1.0.0-rc.1` untouched",
        "",
        "## B generator-v3 changes",
        "",
        "- Versioned shape profiles at `game-godot/data/art/generated_v3/fighter_shape_profiles.json`",
        "- Body core remesh stays one island; designed heads/hands/boots/costume attach after remesh",
        "- 2–3 band toon materials with rim + accent emission",
        "- Fighter-specific idle/walk/heavy/hurt/charge/super poses",
        "",
    ]
    order = [
        ("C Ember", "ember-vale"),
        ("D Rook", "rook-ironside"),
        ("E Juno", "juno-spark"),
        ("F Kaia", "kaia-windrow"),
        ("G Nix", "nix-calder"),
        ("H Orion", "orion-vell"),
        ("I Vesper", "vesper-nyx"),
    ]
    fighters = (quality.get("fighters") or {})
    geom_f = (geom3.get("fighters") or {})
    for title, fid in order:
        q = fighters.get(fid) or {}
        g = geom_f.get(fid) or {}
        lines.append(f"## {title} art result")
        lines.append("")
        lines.append(f"- class: {q.get('class', 'unknown')} (digital only)")
        lines.append(f"- head: {g.get('head_style')}")
        lines.append(f"- boots: {g.get('boot_style')}")
        lines.append(f"- hands: {g.get('hand_default')} strength={g.get('hand_strength')}")
        lines.append(f"- tris: {g.get('triangles')} islands={g.get('body_connected_components')} gap={g.get('foot_ground_gap_m')}")
        lines.append(f"- note: {(q.get('note') or 'generated craft, not finished anime')}")
        lines.append("")
    lines.extend(
        [
            "## J hands results",
            "",
            f"- Rook/Ember stronger than Juno/Kaia: {geom3.get('rook_ember_hands_stronger')}",
            f"- hierarchy: {json.dumps(geom3.get('hand_hierarchy') or {})}",
            f"- gate: {yn(gates.get('GEN_ART_V3_HANDS_PASS'))}",
            "",
            "## K feet results",
            "",
            f"- designed boots per fighter, ground gap gate: {yn(gates.get('GEN_ART_V3_FEET_PASS'))}",
            "",
            "## L head-design results",
            "",
            f"- seven unique abstract heads: {yn(gates.get('GEN_ART_V3_HEAD_DESIGN_PASS'))}",
            "",
            "## M costume-craft results",
            "",
            f"- attached designed plates/panels: {yn(gates.get('GEN_ART_V3_COSTUME_CRAFT_PASS'))}",
            "",
            "## N silhouette results",
            "",
            f"- digital uniqueness: {yn(sil.get('GEN_ART_V3_SILHOUETTE_PASS'))} worst={sil.get('worst')}",
            "- human/owner silhouette approval: false",
            "",
            "## O materials results",
            "",
            f"- 2–3 band toon: {yn(gates.get('GEN_ART_V3_MATERIAL_PASS'))}",
            "",
            "## P heavy-contact results",
            "",
            f"- gate: {yn(gates.get('GEN_ART_V3_HEAVY_CONTACT_PASS'))}",
            "",
            "## Q hurt results",
            "",
            f"- gate: {yn(gates.get('GEN_ART_V3_HURT_POSE_PASS'))}",
            "",
            "## R charge-body results",
            "",
            f"- body-read without VFX: {yn(gates.get('GEN_ART_V3_CHARGE_BODY_READ_PASS'))}",
            "",
            "## S super-pose results",
            "",
            f"- unique supers: {yn(gates.get('GEN_ART_V3_SUPER_POSE_PASS'))}",
            "",
            "## T design-sheet paths",
            "",
            "- `artifacts/vxp3/review/generated_art_v3/design_sheets/<fighter>/`",
            "- packet: `artifacts/vxp3/review/generated_art_v3/<fighter>/`",
            f"- sheets gate: {yn(gates.get('GEN_ART_V3_DESIGN_SHEET_PASS'))}",
            "",
            "## U v3 gate matrix",
            "",
        ]
    )
    for key in (
        "GEN_ART_V3_HANDS_PASS",
        "GEN_ART_V3_FEET_PASS",
        "GEN_ART_V3_HEAD_DESIGN_PASS",
        "GEN_ART_V3_COSTUME_CRAFT_PASS",
        "GEN_ART_V3_SILHOUETTE_PASS",
        "GEN_ART_V3_MATERIAL_PASS",
        "GEN_ART_V3_HERO_POSE_PASS",
        "GEN_ART_V3_HEAVY_CONTACT_PASS",
        "GEN_ART_V3_HURT_POSE_PASS",
        "GEN_ART_V3_CHARGE_BODY_READ_PASS",
        "GEN_ART_V3_SUPER_POSE_PASS",
        "GEN_ART_V3_DESIGN_SHEET_PASS",
        "GENERATED_PRODUCTION_ART_PASS",
        "HUMAN_AUTHORED_ART_PASS",
        "HUMAN_AUTHORED_ANIMATION_PASS",
        "HUMAN_ART_DIRECTION_APPROVAL",
        "MERGE_AUTHORIZED",
        "FINAL_AUTHORED_ANIMATION_PASS",
    ):
        lines.append(f"- {key}: {gates.get(key)}")
    lines.extend(
        [
            "",
            "## V quality classification per fighter",
            "",
        ]
    )
    for fid, row in fighters.items():
        lines.append(f"- {fid}: {row.get('class')} mean={row.get('mean')} (digital only)")
    lines.extend(
        [
            "",
            f"- roster: {quality.get('roster')}",
            "- finished_anime: false",
            "",
            "## W exact-head CI",
            "",
            "- reported after push; do not claim green while required workflows are pending",
            "",
            "## X APK path/SHA if eligible",
            "",
            "- APK not built. File forbids owner-review APK until the visual-craft pass and exact-head CI are complete.",
            "",
            "## Y Pixel install result if available",
            "",
            "- skipped; no APK",
            "",
            "## Z remaining defects / owner questions",
            "",
            "1. Do these look like intentional game characters rather than remesh toys?",
            "2. Are the abstract heads designed enough?",
            "3. Do hands/feet look intentional?",
            "4. Are costumes readable and character-specific?",
            "5. Can you distinguish all seven in black silhouette?",
            "6. Does each fighter have a unique body language?",
            "7. Do heavy attacks look painful?",
            "8. Does hurt acting read before knockback?",
            "9. Does charge 100 transform the body, not just VFX?",
            "10. Are supers screenshot-worthy?",
            "11. Does Aura Clash feel dramatic?",
            "12. Is this generated art acceptable to ship for this release before future human-art upgrades?",
            "",
            "Human gates stay false until the owner answers.",
            "",
            f"masters_ok: {(masters or {}).get('ok')}",
            "",
        ]
    )
    dest = REPORTS / "GENERATED_ART_V3_AZ.md"
    dest.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(dest)


if __name__ == "__main__":
    main()
