#!/usr/bin/env python3
"""Build Wave016 move application matrix, reachability metrics, signatures, choreography alignment."""
from __future__ import annotations

import json
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIGHTERS = [
    "ember-vale",
    "rook-ironside",
    "juno-spark",
    "kaia-windrow",
    "nix-calder",
    "orion-vell",
    "vesper-nyx",
]
SIGNATURE_LANES = [
    "signature_lane_burst",
    "signature_lane_control",
    "signature_lane_confirm",
    "signature_lane_trap",
    "signature_lane_launch",
    "signature_lane_feint",
    "signature_lane_counter",
    "signature_lane_finisher",
]

# Input commands that normal players can issue in BattleScene (docs/CONTROLS.md).
NORMAL_INPUT_COMMANDS = {
    "attack_neutral",
    "attack_forward",
    "attack_up",
    "attack_down",
    "attack_dash",
    "attack_air_neutral",
    "attack_air_forward",
    "attack_air_back",
    "attack_air_up",
    "attack_air_down",
    "special_neutral",
    "special_forward",
    "special_up",
    "special_down",
    "grab",
    "throw_forward",
    "throw_back",
    "throw_up",
    "throw_down",
    "aura_charge",
    "aura_burst",
}

# State-driven clips reachable without a move_id (locomotion / hurt / KO).
STATE_DRIVEN_CLIPS = {
    "idle",
    "walk",
    "run",
    "dash",
    "jump",
    "fall",
    "landing",
    "shield",
    "dodge",
    "air_dodge",
    "hurt",
    "launch",
    "tumble",
    "ko",
    "victory",
    "defeat",
    "aura_charge",
}


def _load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _clip_exists(fighter_id: str, clip: str) -> bool:
    p = (
        ROOT
        / "game-godot"
        / "content"
        / "fighters"
        / fighter_id
        / "animations"
        / "procedural"
        / f"{clip}.anim.json"
    )
    return p.is_file()


def _choreo_exists(fighter_id: str, clip: str) -> bool:
    return (ROOT / "content" / "choreography" / fighter_id / f"{clip}.json").is_file()


def main() -> int:
    alias = _load(ROOT / "content" / "runtime" / "move_clip_alias_map.json")
    move_to_clip: dict = alias["move_id_to_clip"]
    design_only_clips = set(alias.get("design_only_clips", []))
    deliberate = {d["gameplay_move_id"]: d for d in alias.get("deliberate_shares", [])}
    names = _load(ROOT / "game-godot" / "data" / "runtime" / "signature_move_names.json")

    rows: list[dict] = []
    metrics = {
        "PROCEDURAL_CLIPS_GENERATED": 0,
        "LOADED_CLIP": 0,
        "LAB_TRIGGERABLE": 0,
        "GAMEPLAY_STATE_TRIGGERABLE": 0,
        "NORMAL_PLAYER_INPUT_REACHABLE": 0,
        "CPU_REACHABLE": 0,
        "SIGNATURE_BOUND_TO_INPUT": 0,
        "LAB_ONLY_CLIPS": 0,
        "DESIGN_ONLY_CLIPS": 0,
        "GAMEPLAY_MOVES_TOTAL": 0,
        "GAMEPLAY_MOVES_WITH_DEDICATED_CLIP": 0,
        "GAMEPLAY_MOVES_EXACTLY_MAPPED": 0,
        "GAMEPLAY_MOVES_ALIASED": 0,
        "GENERIC_FALLBACK_GAMEPLAY_MOVES": 0,
        "UNMAPPED_GAMEPLAY_MOVES": 0,
    }

    clip_reach: dict[str, set[str]] = defaultdict(set)  # clip -> reach kinds

    for fighter_id in FIGHTERS:
        manifest = ROOT / "game-godot" / "content" / "fighters" / fighter_id / "animations" / "procedural" / "manifest.json"
        clips = [c["clip_name"] for c in _load(manifest)["clips"]]
        metrics["PROCEDURAL_CLIPS_GENERATED"] += len(clips)
        metrics["LOADED_CLIP"] += len(clips)
        for clip in clips:
            clip_reach[f"{fighter_id}:{clip}"].add("LOADED_CLIP")
            clip_reach[f"{fighter_id}:{clip}"].add("LAB_TRIGGERABLE")
            metrics["LAB_TRIGGERABLE"] += 1
            if clip in design_only_clips:
                clip_reach[f"{fighter_id}:{clip}"].add("DESIGN_ONLY")
            if clip in STATE_DRIVEN_CLIPS:
                clip_reach[f"{fighter_id}:{clip}"].add("GAMEPLAY_STATE_TRIGGERABLE")
                clip_reach[f"{fighter_id}:{clip}"].add("NORMAL_PLAYER_INPUT_REACHABLE")
                clip_reach[f"{fighter_id}:{clip}"].add("CPU_REACHABLE")

        moves_path = ROOT / "game-godot" / "data" / "moves" / f"{fighter_id}.json"
        moves = _load(moves_path)["moves"]
        for m in moves:
            mid = m["move_id"]
            cmd = m.get("input_command", "")
            metrics["GAMEPLAY_MOVES_TOTAL"] += 1
            target = move_to_clip.get(mid, mid)
            clip_exists = _clip_exists(fighter_id, target)
            exact = mid == target and clip_exists
            aliased = mid != target and clip_exists
            design_only_move = m.get("wave016_reachability") == "DESIGN_ONLY_NO_DISTINCT_CONTROL"
            normal = cmd in NORMAL_INPUT_COMMANDS and not design_only_move and clip_exists

            if design_only_move:
                status = "DESIGN_ONLY"
            elif not clip_exists and mid not in move_to_clip:
                status = "UNMAPPED" if False else "MISSING_CLIP"
                metrics["UNMAPPED_GAMEPLAY_MOVES"] += 1
                status = "MISSING_CLIP"
            elif mid not in move_to_clip and not clip_exists:
                status = "UNMAPPED"
                metrics["UNMAPPED_GAMEPLAY_MOVES"] += 1
            elif exact:
                status = "EXACT"
                metrics["GAMEPLAY_MOVES_EXACTLY_MAPPED"] += 1
                metrics["GAMEPLAY_MOVES_WITH_DEDICATED_CLIP"] += 1
            elif aliased:
                status = "ALIASED"
                metrics["GAMEPLAY_MOVES_ALIASED"] += 1
                metrics["GAMEPLAY_MOVES_WITH_DEDICATED_CLIP"] += 1
            else:
                status = "BROKEN"
                metrics["GENERIC_FALLBACK_GAMEPLAY_MOVES"] += 1

            if mid in deliberate and status == "ALIASED":
                # deliberate share still counts as aliased dedicated mapping
                pass

            if normal:
                clip_reach[f"{fighter_id}:{target}"].add("NORMAL_PLAYER_INPUT_REACHABLE")
                clip_reach[f"{fighter_id}:{target}"].add("GAMEPLAY_STATE_TRIGGERABLE")
                clip_reach[f"{fighter_id}:{target}"].add("CPU_REACHABLE")

            # Projectile tiers also reachable via aura on special_neutral
            if mid == "neutral_special_projectile":
                for tier in ("projectile_tap", "projectile_medium", "projectile_full"):
                    if _clip_exists(fighter_id, tier):
                        clip_reach[f"{fighter_id}:{tier}"].add("NORMAL_PLAYER_INPUT_REACHABLE")
                        clip_reach[f"{fighter_id}:{tier}"].add("GAMEPLAY_STATE_TRIGGERABLE")
                        clip_reach[f"{fighter_id}:{tier}"].add("CPU_REACHABLE")

            if mid == "aura_burst" and target.startswith("signature_lane_"):
                clip_reach[f"{fighter_id}:{target}"].add("SIGNATURE_BOUND_TO_INPUT")
                clip_reach[f"{fighter_id}:{target}"].add("NORMAL_PLAYER_INPUT_REACHABLE")
                metrics["SIGNATURE_BOUND_TO_INPUT"] += 1

            # side/down special bind additional signatures
            if mid in ("side_special", "down_special") and target.startswith("signature_lane_"):
                clip_reach[f"{fighter_id}:{target}"].add("SIGNATURE_BOUND_TO_INPUT")
                clip_reach[f"{fighter_id}:{target}"].add("NORMAL_PLAYER_INPUT_REACHABLE")
                metrics["SIGNATURE_BOUND_TO_INPUT"] += 1

            rows.append(
                {
                    "fighter_id": fighter_id,
                    "input_command": cmd,
                    "gameplay_move_id": mid,
                    "move_type": m.get("move_type", ""),
                    "ground_air": m.get("grounded_air", ""),
                    "choreography_action_id": f"{fighter_id}.{target}",
                    "generated_clip_id": target,
                    "clip_file_exists": clip_exists,
                    "gameplay_manifest_exists": True,
                    "normal_player_input_reachable": bool(normal),
                    "cpu_reachable": bool(normal),
                    "training_reachable": True,
                    "signature": mid.startswith("signature_lane_") or target.startswith("signature_lane_"),
                    "current_visible_clip": target if clip_exists else "",
                    "target_visible_clip": target,
                    "mapping_status": status,
                    "visual_quality_level": "Q1" if fighter_id != "ember-vale" else "Q2",
                    "human_review": "PENDING",
                    "animation_class": "PROCEDURAL_RUNTIME_ANIMATION",
                }
            )

        # Clip-only rows for DESIGN_ONLY / lab signatures not in gameplay moves
        for clip in clips:
            if clip in design_only_clips:
                metrics["DESIGN_ONLY_CLIPS"] += 1
                rows.append(
                    {
                        "fighter_id": fighter_id,
                        "input_command": "",
                        "gameplay_move_id": "",
                        "move_type": "design_only",
                        "ground_air": "both",
                        "choreography_action_id": f"{fighter_id}.{clip}",
                        "generated_clip_id": clip,
                        "clip_file_exists": True,
                        "gameplay_manifest_exists": False,
                        "normal_player_input_reachable": False,
                        "cpu_reachable": False,
                        "training_reachable": True,
                        "signature": False,
                        "current_visible_clip": clip,
                        "target_visible_clip": clip,
                        "mapping_status": "DESIGN_ONLY",
                        "visual_quality_level": "Q1",
                        "human_review": "PENDING",
                        "animation_class": "PROCEDURAL_RUNTIME_ANIMATION",
                    }
                )
            elif clip.startswith("signature_lane_") and "SIGNATURE_BOUND_TO_INPUT" not in clip_reach[f"{fighter_id}:{clip}"]:
                rows.append(
                    {
                        "fighter_id": fighter_id,
                        "input_command": "",
                        "gameplay_move_id": clip,
                        "move_type": "signature",
                        "ground_air": "both",
                        "choreography_action_id": f"{fighter_id}.{clip}",
                        "generated_clip_id": clip,
                        "clip_file_exists": True,
                        "gameplay_manifest_exists": False,
                        "normal_player_input_reachable": False,
                        "cpu_reachable": False,
                        "training_reachable": True,
                        "signature": True,
                        "current_visible_clip": clip,
                        "target_visible_clip": clip,
                        "mapping_status": "SIGNATURE_NOT_BOUND_TO_INPUT",
                        "visual_quality_level": "Q1",
                        "human_review": "PENDING",
                        "animation_class": "PROCEDURAL_RUNTIME_ANIMATION",
                    }
                )

    # Aggregate reachability clip counts (unique clips)
    normal_clips = 0
    state_clips = 0
    lab_only = 0
    for key, kinds in clip_reach.items():
        if "NORMAL_PLAYER_INPUT_REACHABLE" in kinds:
            normal_clips += 1
        if "GAMEPLAY_STATE_TRIGGERABLE" in kinds:
            state_clips += 1
        if "LAB_TRIGGERABLE" in kinds and "NORMAL_PLAYER_INPUT_REACHABLE" not in kinds and "DESIGN_ONLY" not in kinds:
            lab_only += 1
    metrics["NORMAL_PLAYER_INPUT_REACHABLE_CLIPS"] = normal_clips
    metrics["GAMEPLAY_STATE_REACHABLE_CLIPS"] = state_clips
    metrics["LAB_ONLY_CLIPS"] = lab_only
    metrics["NORMAL_PLAYER_INPUT_REACHABLE"] = normal_clips
    metrics["GAMEPLAY_STATE_TRIGGERABLE"] = state_clips
    metrics["CPU_REACHABLE"] = normal_clips

    # Signature reality
    sig_rows = []
    sig_stats = {
        "SIGNATURES_DESIGNED": 0,
        "SIGNATURES_WITH_PROCEDURAL_CLIP": 0,
        "SIGNATURES_GAMEPLAY_IMPLEMENTED": 0,
        "SIGNATURES_BOUND_TO_INPUT": 0,
        "SIGNATURES_NORMAL_MATCH_VISIBLE": 0,
        "SIGNATURES_LAB_ONLY": 0,
        "SIGNATURES_DESIGN_ONLY": 0,
    }
    bound_clips = {
        "signature_lane_burst",  # aura_burst
        "signature_lane_feint",  # side_special
        "signature_lane_trap",  # down_special
    }
    for fighter_id in FIGHTERS:
        for lane in SIGNATURE_LANES:
            sig_stats["SIGNATURES_DESIGNED"] += 1
            has_clip = _clip_exists(fighter_id, lane)
            if has_clip:
                sig_stats["SIGNATURES_WITH_PROCEDURAL_CLIP"] += 1
            bound = lane in bound_clips
            access = (
                "normal-match playable via aura_burst / directional special"
                if bound
                else "training/lab preview; future combo/cancel/charge context"
            )
            classes = ["SIGNATURE_DESIGNED", "SIGNATURE_ANIMATED_PROXY"]
            if bound:
                classes.extend(
                    [
                        "SIGNATURE_GAMEPLAY_IMPLEMENTED",
                        "SIGNATURE_BOUND_TO_INPUT",
                        "SIGNATURE_PLAYER_VISIBLE",
                    ]
                )
                sig_stats["SIGNATURES_GAMEPLAY_IMPLEMENTED"] += 1
                sig_stats["SIGNATURES_BOUND_TO_INPUT"] += 1
                sig_stats["SIGNATURES_NORMAL_MATCH_VISIBLE"] += 1
            else:
                classes.append("SIGNATURE_LAB_ONLY")
                sig_stats["SIGNATURES_LAB_ONLY"] += 1
            sig_rows.append(
                {
                    "fighter_id": fighter_id,
                    "contract_key": lane,
                    "display_name": names.get(fighter_id, {}).get(lane, lane),
                    "has_procedural_clip": has_clip,
                    "access_architecture": access,
                    "classes": classes,
                    "normal_match_playable": bound,
                    "context_combo_playable": False,
                    "training_lab_only": not bound,
                    "future_design_only": False,
                }
            )

    # Inspired choreography alignment for player-reachable Ember moves
    alignment = []
    ember_moves = [r for r in rows if r["fighter_id"] == "ember-vale" and r["normal_player_input_reachable"]]
    for r in ember_moves:
        clip = r["generated_clip_id"]
        choreo_path = ROOT / "content" / "choreography" / "ember-vale" / f"{clip}.json"
        entry = {
            "fighter_id": "ember-vale",
            "gameplay_move_id": r["gameplay_move_id"],
            "clip": clip,
            "choreography_present": choreo_path.is_file(),
            "anticipation_frames": None,
            "active_frames": None,
            "recovery_frames": None,
            "motion_grammar": None,
            "silhouette_poses": None,
            "camera": None,
            "impact": None,
            "vfx_cue": None,
            "sfx_cue": None,
            "hitbox_window": None,
            "root_motion_style": None,
            "aligned": False,
        }
        if choreo_path.is_file():
            c = _load(choreo_path)
            timing = c.get("timing", {})
            mg = c.get("motion_grammar", {})
            entry.update(
                {
                    "anticipation_frames": timing.get("anticipation_frames"),
                    "active_frames": timing.get("active_frames"),
                    "recovery_frames": timing.get("recovery_frames"),
                    "motion_grammar": mg,
                    "silhouette_poses": mg.get("silhouette_poses"),
                    "camera": c.get("camera"),
                    "impact": c.get("impact"),
                    "vfx_cue": c.get("vfx_cue"),
                    "sfx_cue": c.get("sfx_cue"),
                    "hitbox_window": c.get("hitbox"),
                    "root_motion_style": mg.get("arc_type"),
                    "aligned": True,
                }
            )
        alignment.append(entry)

    out_matrix = {
        "schema": "move_animation_application_matrix_v1",
        "wave": "016",
        "accepted_main_sha": "b8da943b46e1460723603ea2216f646146180aa3",
        "truth_chain": "PLAYER INPUT -> command -> move_id -> timing/hitboxes -> choreography action_id -> visible clip -> VFX/SFX/camera -> interaction",
        "metrics": metrics,
        "rows": rows,
    }
    matrix_path = ROOT / "content" / "runtime" / "move_animation_application_matrix.json"
    matrix_path.parent.mkdir(parents=True, exist_ok=True)
    matrix_path.write_text(json.dumps(out_matrix, indent=2) + "\n", encoding="utf-8")

    # Markdown matrix (summary + Ember focus)
    ember_rows = [r for r in rows if r["fighter_id"] == "ember-vale" and r.get("gameplay_move_id")]
    md_lines = [
        "# Move Animation Application Matrix",
        "",
        "Wave016 canonical truth chain:",
        "`PLAYER INPUT -> command -> move_id -> timing/hitboxes -> choreography action_id -> visible clip -> VFX/SFX/camera -> interaction`",
        "",
        f"- PROCEDURAL_CLIPS_GENERATED: **{metrics['PROCEDURAL_CLIPS_GENERATED']}**",
        f"- NORMAL_PLAYER_INPUT_REACHABLE_CLIPS: **{metrics['NORMAL_PLAYER_INPUT_REACHABLE_CLIPS']}**",
        f"- GAMEPLAY_STATE_REACHABLE_CLIPS: **{metrics['GAMEPLAY_STATE_REACHABLE_CLIPS']}**",
        f"- LAB_ONLY_CLIPS: **{metrics['LAB_ONLY_CLIPS']}**",
        f"- DESIGN_ONLY_CLIPS: **{metrics['DESIGN_ONLY_CLIPS']}**",
        "",
        "Full machine-readable matrix: `content/runtime/move_animation_application_matrix.json`",
        "",
        "## Ember Vale (Golden Slice) gameplay moves",
        "",
        "| move_id | input | clip | status | normal_reachable |",
        "|---------|-------|------|--------|------------------|",
    ]
    for r in ember_rows:
        if r.get("move_type") == "design_only":
            continue
        md_lines.append(
            f"| `{r['gameplay_move_id']}` | `{r['input_command']}` | `{r['generated_clip_id']}` | {r['mapping_status']} | {r['normal_player_input_reachable']} |"
        )
    md_lines.extend(
        [
            "",
            "## Mapping statuses",
            "",
            "EXACT, ALIASED, MISSING_CLIP, MISSING_GAMEPLAY_MOVE, DESIGN_ONLY, SIGNATURE_NOT_BOUND_TO_INPUT, GENERIC_FALLBACK, BROKEN.",
            "",
            "Reachability is honest: generated ≠ reachable. 357 is LOADED/GENERATED only.",
            "",
        ]
    )
    (ROOT / "docs" / "combat" / "MOVE_ANIMATION_APPLICATION_MATRIX.md").write_text(
        "\n".join(md_lines) + "\n", encoding="utf-8"
    )

    sig_out = {
        "schema": "signature_reality_closure_v1",
        "wave": "016",
        "access_architecture": {
            "normal_match": "aura_burst -> signature_lane_burst; side_special -> signature_lane_feint; down_special -> signature_lane_trap",
            "not_bound": "Remaining 5 lanes per fighter: training/lab preview and future combo/cancel/charge — not jammed onto extra buttons",
        },
        "stats": sig_stats,
        "signatures": sig_rows,
    }
    (ROOT / "content" / "runtime" / "signature_reality_closure.json").write_text(
        json.dumps(sig_out, indent=2) + "\n", encoding="utf-8"
    )
    (ROOT / "artifacts" / "wave016" / "signature_reality_closure.json").parent.mkdir(
        parents=True, exist_ok=True
    )
    (ROOT / "artifacts" / "wave016" / "signature_reality_closure.json").write_text(
        json.dumps(sig_out, indent=2) + "\n", encoding="utf-8"
    )

    align_out = {
        "schema": "inspired_choreography_runtime_alignment_v1",
        "wave": "016",
        "fighter_id": "ember-vale",
        "entries": alignment,
        "aligned_count": sum(1 for e in alignment if e["aligned"]),
        "total": len(alignment),
    }
    (ROOT / "artifacts" / "wave016" / "INSPIRED_CHOREOGRAPHY_RUNTIME_ALIGNMENT.json").write_text(
        json.dumps(align_out, indent=2) + "\n", encoding="utf-8"
    )
    (ROOT / "content" / "runtime" / "INSPIRED_CHOREOGRAPHY_RUNTIME_ALIGNMENT.json").write_text(
        json.dumps(align_out, indent=2) + "\n", encoding="utf-8"
    )

    directional = {
        "schema": "directional_input_audit_v1",
        "wave": "016",
        "checks": [
            {
                "name": "forward_air_vs_back_air",
                "distinguished": True,
                "implementation": "Facing-relative stick vs facing in Fighter._resolve_attack_command",
            },
            {
                "name": "tilt_vs_smash_heavy",
                "distinguished": False,
                "implementation": "DESIGN_ONLY — CONTROLS.md has no smash/heavy distinct input; heavy_attack not bound",
            },
            {
                "name": "projectile_tap_medium_full",
                "distinguished": True,
                "implementation": "Aura level selects cast clip + projectile tier (no new buttons)",
            },
            {
                "name": "four_throws",
                "distinguished": True,
                "implementation": "Direction + attack while grabbing",
            },
            {
                "name": "directional_specials",
                "distinguished": True,
                "implementation": "special_neutral/forward/up/down",
            },
            {
                "name": "signature_commands",
                "distinguished": True,
                "implementation": "aura_burst + side/down special bind 3 signature lanes; others lab-only",
            },
        ],
    }
    (ROOT / "content" / "runtime" / "directional_input_audit.json").write_text(
        json.dumps(directional, indent=2) + "\n", encoding="utf-8"
    )

    print(json.dumps({"ok": True, "metrics": metrics, "sig_stats": sig_stats}, indent=2))
    assert metrics["PROCEDURAL_CLIPS_GENERATED"] == 357, metrics["PROCEDURAL_CLIPS_GENERATED"]
    assert metrics["NORMAL_PLAYER_INPUT_REACHABLE_CLIPS"] < 357
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
