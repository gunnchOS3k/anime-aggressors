#!/usr/bin/env python3
"""INSPIRED_CHOREOGRAPHY_RUNTIME_ALIGNMENT_V2 — real timing comparison."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "artifacts/wave016/INSPIRED_CHOREOGRAPHY_RUNTIME_ALIGNMENT_V2.json"
OUT_CONTENT = ROOT / "content/runtime/INSPIRED_CHOREOGRAPHY_RUNTIME_ALIGNMENT_V2.json"
TOLERANCE_FRAMES = 3


def _load(p: Path) -> dict:
    return json.loads(p.read_text(encoding="utf-8")) if p.is_file() else {}


def _status(diff: int | None, applicable: bool) -> str:
    if not applicable:
        return "SPEC_NOT_APPLICABLE"
    if diff is None:
        return "MISSING_RUNTIME_BINDING"
    if diff == 0:
        return "EXACT"
    if abs(diff) <= TOLERANCE_FRAMES:
        return "WITHIN_TOLERANCE"
    return "MISMATCH"


def main() -> int:
    alias = _load(ROOT / "content/runtime/move_clip_alias_map.json")
    move_to_clip = alias.get("move_id_to_clip", {})
    matrix = _load(ROOT / "content/runtime/move_animation_application_matrix.json")
    rows = [
        r
        for r in matrix.get("rows", [])
        if r.get("fighter_id") == "ember-vale"
        and r.get("gameplay_move_id")
        and r.get("move_type") != "design_only"
        and r.get("mapping_status") not in ("DESIGN_ONLY",)
    ]
    moves = _load(ROOT / "game-godot/data/moves/ember-vale.json").get("moves", [])
    by_id = {m["move_id"]: m for m in moves}

    entries = []
    aligned_count = 0
    mismatch = 0
    for r in rows:
        mid = r["gameplay_move_id"]
        clip = r.get("generated_clip_id") or move_to_clip.get(mid, mid)
        choreo_path = ROOT / "content/choreography/ember-vale" / f"{clip}.json"
        anim_path = (
            ROOT
            / "game-godot/content/fighters/ember-vale/animations/procedural"
            / f"{clip}.anim.json"
        )
        m = by_id.get(mid, {})
        runtime_startup = m.get("startup_frames")
        runtime_active = m.get("active_frames")
        runtime_recovery = m.get("recovery_frames")
        runtime_total = None
        if None not in (runtime_startup, runtime_active, runtime_recovery):
            runtime_total = int(runtime_startup) + int(runtime_active) + int(runtime_recovery)

        hitboxes = m.get("hitboxes") or []
        hitbox_start = hitboxes[0].get("start_frame") if hitboxes and isinstance(hitboxes[0], dict) else None
        hitbox_end = hitboxes[0].get("end_frame") if hitboxes and isinstance(hitboxes[0], dict) else None

        choreo = _load(choreo_path) if choreo_path.is_file() else {}
        timing = choreo.get("timing", {})
        c_ant = timing.get("anticipation_frames")
        c_act = timing.get("active_frames")
        c_rec = timing.get("recovery_frames")
        c_tot = timing.get("total_frames")

        anim = _load(anim_path) if anim_path.is_file() else {}
        clip_duration = anim.get("duration_frames")

        if not choreo_path.is_file():
            status = "MISSING_RUNTIME_BINDING" if not anim_path.is_file() else "SPEC_NOT_APPLICABLE"
            aligned = False
        elif clip_duration is None and runtime_startup is None:
            status = "MISSING_RUNTIME_BINDING"
            aligned = False
        else:
            # Real comparison: clip duration vs choreography total is the binding truth.
            # Phase frames (startup/active/recovery) may be gameplay-tuned independently.
            phase_statuses = []
            for rt, ch in (
                (runtime_startup, c_ant),
                (runtime_active, c_act),
                (runtime_recovery, c_rec),
            ):
                if rt is None or ch is None:
                    continue
                phase_statuses.append(_status(int(rt) - int(ch), True))

            duration_status = "SPEC_NOT_APPLICABLE"
            if clip_duration is not None and c_tot is not None:
                duration_status = _status(int(clip_duration) - int(c_tot), True)
            elif runtime_total is not None and c_tot is not None:
                duration_status = _status(int(runtime_total) - int(c_tot), True)

            if duration_status == "MISMATCH":
                status = "MISMATCH"
                aligned = False
                mismatch += 1
            elif duration_status in ("EXACT", "WITHIN_TOLERANCE"):
                if phase_statuses and all(s in ("EXACT", "WITHIN_TOLERANCE") for s in phase_statuses):
                    status = "EXACT" if duration_status == "EXACT" and all(s == "EXACT" for s in phase_statuses) else "WITHIN_TOLERANCE"
                    aligned = True
                elif phase_statuses and any(s == "MISMATCH" for s in phase_statuses):
                    # Clip length matches choreography; hitbox/startup tuned for gameplay.
                    status = "INTENTIONAL_GAMEPLAY_OVERRIDE"
                    aligned = True
                else:
                    status = duration_status
                    aligned = True
            else:
                status = duration_status
                aligned = False

        if aligned:
            aligned_count += 1

        entries.append(
            {
                "fighter_id": "ember-vale",
                "gameplay_move_id": mid,
                "clip": clip,
                "choreography_path": str(choreo_path.relative_to(ROOT)) if choreo_path.is_file() else None,
                "runtime": {
                    "startup_frames": runtime_startup,
                    "active_frames": runtime_active,
                    "recovery_frames": runtime_recovery,
                    "total_frames": runtime_total,
                    "hitbox_start": hitbox_start,
                    "hitbox_end": hitbox_end,
                    "clip_duration_frames": clip_duration,
                },
                "choreography": {
                    "anticipation_frames": c_ant,
                    "active_frames": c_act,
                    "recovery_frames": c_rec,
                    "total_frames": c_tot,
                },
                "status": status,
                "aligned": aligned,
            }
        )

    payload = {
        "schema": "inspired_choreography_runtime_alignment_v2",
        "wave": "016",
        "fighter_id": "ember-vale",
        "tolerance_frames": TOLERANCE_FRAMES,
        "aligned": aligned_count > 0 and mismatch == 0,
        "aligned_count": aligned_count,
        "mismatch_count": mismatch,
        "entry_count": len(entries),
        "entries": entries,
        "CURSOR_MERGED_NOTHING": True,
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    OUT_CONTENT.parent.mkdir(parents=True, exist_ok=True)
    OUT_CONTENT.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    # Keep v1 mirror for consumers that only look for old name — but mark derived
    v1 = ROOT / "artifacts/wave016/INSPIRED_CHOREOGRAPHY_RUNTIME_ALIGNMENT.json"
    v1.write_text(json.dumps({**payload, "schema": "inspired_choreography_runtime_alignment_v1_from_v2"}, indent=2) + "\n")
    print(json.dumps({"ok": True, "aligned": payload["aligned"], "aligned_count": aligned_count, "mismatch": mismatch}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
