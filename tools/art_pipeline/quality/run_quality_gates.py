#!/usr/bin/env python3
"""Measurable Wave012 quality gates — no invented aesthetic scores."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]

REQUIRED = [
    "docs/art_pipeline/FREE_TOOLCHAIN_AND_LICENSE_MATRIX.md",
    "docs/design/CHARACTER_COMBAT_INSPIRATION_BIBLE.md",
    "docs/design/ICONIC_MOMENT_TO_ORIGINAL_MOVE_MATRIX.md",
    "docs/design/CHOREOGRAPHY_LIBRARY.md",
    "docs/art_pipeline/CANONICAL_HUMANOID_RIG.md",
    "docs/art_pipeline/MIXAMO_USAGE_AND_PROVENANCE.md",
    "docs/art_pipeline/MOCAP_GPU_EXECUTION.md",
    "docs/art_pipeline/GAME_JUICE_EVENT_CONTRACT.md",
    "docs/art_pipeline/EMBER_FREE_ART_PIPELINE_VERTICAL_SLICE.md",
    "content/choreography/choreography_manifest.json",
    "artifacts/wave012/MOCAP_GPU_EXECUTION_PACKET.json",
]

FIGHTERS = [
    "ember-vale",
    "rook-ironside",
    "juno-spark",
    "kaia-windrow",
    "nix-calder",
    "orion-vell",
    "vesper-nyx",
]


def main() -> int:
    missing = [p for p in REQUIRED if not (ROOT / p).exists()]
    packets = [
        {
            "id": fid,
            "present": (ROOT / f"docs/art_pipeline/VRoid_FIGHTER_AUTHORING_PACKETS/{fid}.md").exists(),
        }
        for fid in FIGHTERS
    ]
    packets_ok = all(x["present"] for x in packets)
    studies = (ROOT / "docs/design/ICONIC_MOMENT_TO_ORIGINAL_MOVE_MATRIX.md").read_text(
        encoding="utf-8"
    ).count("### Study")
    choreo = json.loads(
        (ROOT / "content/choreography/choreography_manifest.json").read_text(encoding="utf-8")
    )
    clips_ok = all(
        len(choreo.get("fighters", {}).get(f, {}).get("clips", {})) >= 20 for f in FIGHTERS
    )
    juice_ok = (
        (ROOT / "game-godot/scripts/juice/juice_event_bus.gd").exists()
        and "JuiceEventBus" in (ROOT / "game-godot/project.godot").read_text(encoding="utf-8")
        and "_emit_juice" in (ROOT / "game-godot/scripts/combat/combat_feedback.gd").read_text(
            encoding="utf-8"
        )
    )
    smoke = (ROOT / "game-godot/tests/engineering_wave012/Wave012JuiceSmoke.gd").exists()
    out = {
        "docs_missing": missing,
        "docs_pass": not missing,
        "vroid_packets_pass": packets_ok,
        "vroid_packets": packets,
        "iconic_studies_count": studies,
        "iconic_studies_pass": studies >= 35,
        "choreography_clip_coverage_pass": clips_ok,
        "juice_hooks_pass": juice_ok,
        "juice_smoke_script_present": smoke,
        "aesthetic_scores_invented": False,
        "pass": (not missing)
        and packets_ok
        and studies >= 35
        and clips_ok
        and juice_ok
        and smoke,
    }
    for dest in [
        ROOT / "artifacts/wave012/QUALITY_GATES.json",
        ROOT / "artifacts/engineering_wave012/QUALITY_GATES.json",
    ]:
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    return 0 if out["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
