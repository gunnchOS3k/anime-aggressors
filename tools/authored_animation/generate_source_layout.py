#!/usr/bin/env python3
"""Create fighter folders, pose-bible templates, Wave A manifest, provenance.

Does not manufacture final acting. Hero actions stay MISSING or PROCEDURAL_FALLBACK
except pipeline_proof rows marked AUTHORED_WIP after a real GLB export exists.
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ANIM = ROOT / "art_source" / "animation"

FIGHTERS = (
    ("ember-vale", "Ember Vale", "flame / rush", "Tempo-first. Restless weight. Rush-through attacks."),
    ("rook-ironside", "Rook Ironside", "impact / armor", "Planted. Enormous follow-through. Armor swell."),
    ("juno-spark", "Juno Spark", "volt / trick", "Staccato resets. Light broken-rhythm walk. Fast recover."),
    ("kaia-windrow", "Kaia Windrow", "gale / carry", "Long lines. Float walk, plant on run. Carry-arcs."),
    ("nix-calder", "Nix Calder", "frost / control", "Still idle. Precise feet. Stiffness before launch."),
    ("orion-vell", "Orion Vell", "gravity / trap", "Delayed breath. Measured walk. Sink before launch."),
    ("vesper-nyx", "Vesper Nyx", "void / mix", "Asymmetric idle. Feint then confirm. Dissolve-snap hurt."),
)

# 14 hero actions × 7 fighters = 98. Define only. Do not fake-complete.
WAVE_A_ACTIONS = (
    ("idle", "idle", "Neutral loop. Identity readable in 8 frames."),
    ("walk", "walk", "Ground locomotion loop. No root translation."),
    ("run", "run", "Run loop. Distinct from walk."),
    ("dash", "dash", "Burst start + travel pose. Gameplay owns displacement."),
    ("jump", "jump", "Squat / leave / apex family starts here."),
    ("light", "jab", "Jab / light. Contact inside hitbox window."),
    ("medium", "tilt_forward", "Medium / tilt. Must not share light posing."),
    ("heavy", "heavy", "Heavy. Distinct silhouette vs aura/super."),
    ("aura", "signature_lane_burst", "High-commitment aura. Clash-eligible."),
    ("super", "signature_lane_finisher", "Super / finisher. Clash-eligible."),
    ("hurt_heavy", "hurt_heavy", "Readable victim. Not a freeze-frame."),
    ("launch", "launch", "Launch / tumble start. Physics owns path."),
    ("charge", "charge_full", "Charge 100 presence. Not a recolor of idle."),
    ("ko", "ko", "KO spin / collapse. Cinematic class KO."),
)

POSE_SLOTS = (
    "neutral_idle",
    "combat_ready",
    "walk_contact_l",
    "walk_contact_r",
    "run_extreme",
    "dash_commit",
    "jump_squat",
    "jump_apex",
    "light_anticipation",
    "light_contact",
    "medium_contact",
    "heavy_anticipation",
    "heavy_contact",
    "heavy_follow",
    "aura_commit",
    "super_release",
    "charge_0",
    "charge_50",
    "charge_100",
    "hurt_heavy",
    "launch",
    "ko",
    "shield",
    "signature_silhouette",
)


def pose_bible(fid: str, name: str, lane: str, notes: str) -> str:
    rows = "\n".join(
        f"| `{slot}` | WIP template | — | Human animator must block this pose |"
        for slot in POSE_SLOTS
    )
    return f"""# Pose Bible — {name}

**Status:** TEMPLATE ONLY. Not human-authored. `AUTHORED_POSE_BIBLE_PASS=false`.

- Fighter: `{fid}`
- Lane: {lane}
- Identity: {notes}
- Rest: A-pose on canonical deform skeleton
- No franchise reproduction

## Slots

| Slot | Status | Frame / still | Notes |
|------|--------|---------------|-------|
{rows}

## Silhouette rules

- Readable at 128px on Pixel 6a.
- Charge 0 / 50 / 100 must change volume, not just VFX.
- Hurt must read without HUD.
- Heavy / aura / super must not share the same contact silhouette.

## How to fill

1. Open `source/{fid}_control_rig.blend` (when LFS source is present).
2. Pose deform or FK controls. Screenshot orthographic front + side.
3. Drop stills in this folder as `{fid}_<slot>_front.png`.
4. Keep provenance `AUTHORED_WIP` until a human director signs the sheet.
"""


def fighter_readme(fid: str, name: str, lane: str, notes: str) -> str:
    return f"""# {name} — authored animation

Lane: {lane}

{notes}

Source `.blend` lives in `source/` (Git LFS when remote auth is configured).
Exports live in `export/`. Runtime copy: `game-godot/assets/characters/authored/{fid}/`.

Wave A 14 hero actions are **defined** in the roster manifest. They are not complete.
This pass includes one `pipeline_proof` GLB import test only.
"""


def write_tree() -> dict:
    actions = []
    provenance_entries = []
    for fid, name, lane, notes in FIGHTERS:
        base = ANIM / "fighters" / fid
        for sub in ("source", "pose_bible", "actions", "export"):
            (base / sub).mkdir(parents=True, exist_ok=True)
            (base / sub / ".gitkeep").write_text("")
        (base / "README.md").write_text(fighter_readme(fid, name, lane, notes))
        (base / "pose_bible" / f"{fid}_POSE_BIBLE.md").write_text(pose_bible(fid, name, lane, notes))
        (base / "provenance.json").write_text(
            json.dumps(
                {
                    "fighter_id": fid,
                    "display_name": name,
                    "lane": lane,
                    "default_status": "PROCEDURAL_FALLBACK",
                    "pipeline_proof": "AUTHORED_WIP",
                    "human_approved": False,
                    "not_final_art": True,
                },
                indent=2,
            )
            + "\n"
        )
        for action_id, runtime_clip, brief in WAVE_A_ACTIONS:
            act_dir = base / "actions" / action_id
            act_dir.mkdir(parents=True, exist_ok=True)
            sidecar = {
                "fighter_id": fid,
                "action_id": action_id,
                "runtime_clip": runtime_clip,
                "status": "PROCEDURAL_FALLBACK",
                "authored_source": None,
                "export_glb": None,
                "not_final_art": True,
                "human_approved": False,
                "brief": brief,
            }
            (act_dir / "ACTION.json").write_text(json.dumps(sidecar, indent=2) + "\n")
            actions.append(
                {
                    "id": f"{fid}.{action_id}",
                    "fighter_id": fid,
                    "action_id": action_id,
                    "runtime_clip": runtime_clip,
                    "status": "PROCEDURAL_FALLBACK",
                    "wave": "A",
                    "hero": True,
                    "authored_complete": False,
                    "brief": brief,
                }
            )
        # Pipeline proof is the only AUTHORED_WIP row this pass (filled after export).
        provenance_entries.append(
            {
                "id": f"{fid}.pipeline_proof",
                "fighter_id": fid,
                "action_id": "pipeline_proof",
                "runtime_clip": "pipeline_proof",
                "status": "MISSING",
                "kind": "import_proof",
                "not_final_art": True,
                "human_approved": False,
            }
        )

    manifest = {
        "schema": "aa_wave_a_98_v1",
        "wave": "A",
        "title": "Authored Wave A hero set — defined, not complete",
        "fighter_count": 7,
        "actions_per_fighter": 14,
        "hero_action_count": 98,
        "authored_complete_count": 0,
        "not_final_art": True,
        "human_approved": False,
        "note": "Do not treat PROCEDURAL_FALLBACK rows as authored animation.",
        "hero_action_ids": [a[0] for a in WAVE_A_ACTIONS],
        "actions": actions,
    }
    man_dir = ANIM / "manifests"
    man_dir.mkdir(parents=True, exist_ok=True)
    (man_dir / "WAVE_A_98_ACTIONS.json").write_text(json.dumps(manifest, indent=2) + "\n")

    roster = {
        "schema": "aa_provenance_v1",
        "labels": [
            "AUTHORED_APPROVED",
            "AUTHORED_WIP",
            "PROCEDURAL_FALLBACK",
            "MISSING",
        ],
        "automation_may_write": ["AUTHORED_WIP", "PROCEDURAL_FALLBACK", "MISSING"],
        "automation_must_never_write": ["AUTHORED_APPROVED"],
        "wave_a_hero": [
            {
                "id": a["id"],
                "status": a["status"],
                "fighter_id": a["fighter_id"],
                "action_id": a["action_id"],
            }
            for a in actions
        ],
        "pipeline_proof": provenance_entries,
        "procedural_library_note": (
            "game-godot/content/fighters/*/animations/procedural/*.anim.json "
            "are PROCEDURAL_FALLBACK placeholders, not authored animation."
        ),
    }
    (man_dir / "provenance_roster.json").write_text(json.dumps(roster, indent=2) + "\n")
    return {
        "fighters": len(FIGHTERS),
        "hero_actions": len(actions),
        "pipeline_proof_rows": len(provenance_entries),
    }


if __name__ == "__main__":
    print(json.dumps(write_tree(), indent=2))
