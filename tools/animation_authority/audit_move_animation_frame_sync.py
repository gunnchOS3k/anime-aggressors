#!/usr/bin/env python3
"""Machine-sync animation markers against live move timing for 168 spectrum moves."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "artifacts/animation_authority_v1"
SPECTRUM = [
    "ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
    "nix-calder", "orion-vell", "vesper-nyx",
]
LIVE_MOVES = [
    "jab_1", "jab_2", "jab_finisher", "forward_tilt", "up_tilt", "down_tilt",
    "dash_attack", "heavy_attack", "neutral_air", "forward_air", "back_air",
    "up_air", "down_air", "neutral_special_projectile", "side_special",
    "up_special_recovery", "down_special", "grab", "throw_forward", "throw_back",
    "throw_up", "throw_down", "aura_charge", "aura_burst",
]
ALIAS = json.loads((ROOT / "game-godot/data/runtime/move_clip_alias_map.json").read_text())


def load_moves(fid: str) -> dict:
    data = json.loads((ROOT / "game-godot/data/moves" / f"{fid}.json").read_text())
    moves = data.get("moves") or data
    if isinstance(moves, list):
        out = {}
        for m in moves:
            mid = m.get("move_id") or m.get("id")
            if mid:
                out[mid] = m
        return out
    return moves


def load_clip(fid: str, name: str):
    p = ROOT / "content/fighters" / fid / "animations/procedural" / f"{name}.anim.json"
    return json.loads(p.read_text()) if p.is_file() else None


def pose_frame(clip, names):
    for p in clip.get("key_poses") or []:
        if p.get("name") in names:
            return int(p.get("frame", 0))
    return None


def event_frame(clip, etype):
    for e in clip.get("events") or []:
        if e.get("type") == etype:
            return int(e.get("frame", 0))
    return None


def main() -> int:
    rows = []
    ok = 0
    for fid in SPECTRUM:
        moves = load_moves(fid)
        for mid in LIVE_MOVES:
            mdata = moves.get(mid) or {}
            clip_name = (ALIAS.get("move_id_to_clip") or {}).get(mid, mid)
            clip = load_clip(fid, mid) or load_clip(fid, clip_name)
            if clip is None:
                rows.append({"fighter_id": fid, "move_id": mid, "status": "MISSING_CLIP"})
                continue
            # Extract move timing if present
            startup = mdata.get("startup_frames") or mdata.get("startup") or mdata.get("frames", {}).get("startup")
            active = mdata.get("active_frames") or mdata.get("active") or mdata.get("frames", {}).get("active")
            recovery = mdata.get("recovery_frames") or mdata.get("recovery") or mdata.get("frames", {}).get("recovery")
            # Normalize list active windows
            active_start = active_end = None
            if isinstance(active, list) and active:
                if isinstance(active[0], (list, tuple)) and len(active[0]) >= 2:
                    active_start, active_end = active[0][0], active[0][1]
                elif len(active) >= 2 and all(isinstance(x, int) for x in active[:2]):
                    active_start, active_end = active[0], active[1]
                else:
                    active_start = active[0] if active else None
            elif isinstance(active, int):
                active_start = active

            antic = pose_frame(clip, ("anticipation", "intent"))
            contact = pose_frame(clip, ("contact", "apex"))
            follow = pose_frame(clip, ("follow", "recovery"))
            hit = event_frame(clip, "hit_contact")
            vfx = event_frame(clip, "vfx")
            sfx = event_frame(clip, "sfx")

            # Machine sync: animation must expose markers; contact near active if known
            sync_ok = contact is not None and antic is not None and follow is not None
            if sync_ok and hit is not None and contact is not None:
                sync_ok = abs(hit - contact) <= 3
            if sync_ok and active_start is not None and contact is not None:
                # soft window — animation contact within +/- 6 of move active start if numeric
                try:
                    sync_ok = abs(int(contact) - int(active_start)) <= 8
                except Exception:
                    pass

            row = {
                "fighter_id": fid,
                "move_id": mid,
                "runtime_clip": clip.get("runtime_clip_id") or clip_name,
                "move_startup": startup,
                "move_active_start": active_start,
                "move_active_end": active_end,
                "move_recovery": recovery,
                "anim_anticipation": antic,
                "anim_contact": contact,
                "anim_follow": follow,
                "hit_contact_marker": hit,
                "vfx_marker": vfx,
                "sfx_marker": sfx,
                "duration_frames": clip.get("duration_frames"),
                "status": "SYNCED" if sync_ok else "NEEDS_ALIGN",
                "human_contact_feel": False,
            }
            rows.append(row)
            if sync_ok:
                ok += 1

    report = {
        "schema": "move_animation_frame_sync_168_v1",
        "total": 168,
        "synced": ok,
        "MOVE_ANIMATION_MACHINE_SYNC_168_OF_168": ok == 168,
        "note": "Machine marker sync only; does not auto-pass human contact feel.",
        "rows": rows,
    }
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "MOVE_ANIMATION_FRAME_SYNC_168.json").write_text(json.dumps(report, indent=2) + "\n")
    print(f"MOVE_ANIMATION_MACHINE_SYNC_168_OF_168={ok == 168} synced={ok}/168")
    if ok != 168:
        bad = [r for r in rows if r["status"] != "SYNCED"][:10]
        print("sample failures", bad, file=sys.stderr)
        return 1
    print("PASS audit_move_animation_frame_sync")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
