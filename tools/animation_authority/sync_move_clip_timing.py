#!/usr/bin/env python3
"""Retarget automation-authored move clip keyframe times to live move frame data.

Does not alter hitboxes/collision — only animation marker/key-pose frame indices.
"""
from __future__ import annotations

import json
from copy import deepcopy
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
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
        return {(m.get("move_id") or m.get("id")): m for m in moves if (m.get("move_id") or m.get("id"))}
    return moves


def extract_timing(mdata: dict) -> tuple[int, int, int, int]:
    startup = mdata.get("startup_frames") or mdata.get("startup") or (mdata.get("frames") or {}).get("startup") or 4
    active = mdata.get("active_frames") or mdata.get("active") or (mdata.get("frames") or {}).get("active") or 3
    recovery = mdata.get("recovery_frames") or mdata.get("recovery") or (mdata.get("frames") or {}).get("recovery") or 8
    if isinstance(active, list):
        if active and isinstance(active[0], (list, tuple)):
            active_len = max(1, int(active[0][1]) - int(active[0][0]) + 1)
            active_start = int(active[0][0])
        elif active and isinstance(active[0], int):
            active_start = int(active[0])
            active_len = max(1, int(active[1]) - int(active[0]) + 1) if len(active) > 1 else int(active[0])
        else:
            active_start = int(startup)
            active_len = 3
    else:
        active_start = int(startup)
        active_len = max(1, int(active))
    startup = int(startup)
    recovery = int(recovery)
    total = max(startup + active_len + recovery, active_start + active_len + recovery)
    contact = active_start
    antic = max(0, min(startup - 1, contact - 1))
    follow = min(total - 1, contact + max(1, active_len))
    return antic, contact, follow, total


def remap_tracks(tracks: dict, old_total: int, mapping: dict[int, int], new_total: int) -> dict:
    out = {}
    for bone, keys in tracks.items():
        new_keys = []
        for key in keys:
            old_f = int(key.get("frame", 0))
            # map nearest old keyframe index proportionally if not exact
            if old_f in mapping:
                nf = mapping[old_f]
            else:
                # proportional
                nf = int(round((old_f / max(old_total, 1)) * new_total))
            nk = deepcopy(key)
            nk["frame"] = int(nf)
            nk["time_s"] = round(nf / 60.0, 4)
            new_keys.append(nk)
        # ensure unique increasing frames
        new_keys.sort(key=lambda k: k["frame"])
        dedup = []
        seen = set()
        for k in new_keys:
            if k["frame"] in seen:
                continue
            seen.add(k["frame"])
            dedup.append(k)
        if dedup and dedup[-1]["frame"] != new_total:
            last = deepcopy(dedup[-1])
            last["frame"] = new_total
            last["time_s"] = round(new_total / 60.0, 4)
            dedup.append(last)
        out[bone] = dedup
    return out


def write_clip(fid: str, name: str, clip: dict) -> None:
    for base in (
        ROOT / "content/fighters" / fid / "animations/procedural",
        ROOT / "game-godot/content/fighters" / fid / "animations/procedural",
    ):
        base.mkdir(parents=True, exist_ok=True)
        (base / f"{name}.anim.json").write_text(json.dumps(clip, indent=2) + "\n")


def sync_clip(clip: dict, antic: int, contact: int, follow: int, total: int) -> dict:
    clip = deepcopy(clip)
    old_total = int(clip.get("duration_frames") or total)
    old_poses = clip.get("key_poses") or []
    # Build old->new frame map from pose names when possible
    mapping = {0: 0, old_total: total}
    name_targets = {
        "intent": 0,
        "anticipation": antic,
        "acceleration": max(antic, (antic + contact) // 2),
        "contact": contact,
        "apex": contact,
        "follow": follow,
        "recovery": total,
        "hold": total,
        "loop_a": 0,
        "loop_b": total // 2,
    }
    for p in old_poses:
        nm = p.get("name")
        if nm in name_targets:
            mapping[int(p.get("frame", 0))] = name_targets[nm]
    clip["bone_tracks"] = remap_tracks(clip.get("bone_tracks") or {}, old_total, mapping, total)
    # Rewrite key poses to exact gameplay-aligned frames
    new_poses = [
        {"name": "intent", "frame": 0, "time_s": 0.0},
        {"name": "anticipation", "frame": antic, "time_s": round(antic / 60.0, 4)},
        {"name": "acceleration", "frame": max(antic, (antic + contact) // 2), "time_s": round(max(antic, (antic + contact) // 2) / 60.0, 4)},
        {"name": "contact", "frame": contact, "time_s": round(contact / 60.0, 4)},
        {"name": "follow", "frame": follow, "time_s": round(follow / 60.0, 4)},
        {"name": "recovery", "frame": total, "time_s": round(total / 60.0, 4)},
    ]
    clip["key_poses"] = new_poses
    clip["duration_frames"] = total
    clip["events"] = [
        {"frame": antic, "type": "vfx", "id": f"{(clip.get('runtime_alignment') or {}).get('motion_law', 'motion')}.anticipation"},
        {"frame": contact, "type": "hit_contact", "id": f"{(clip.get('runtime_alignment') or {}).get('motion_law', 'motion')}.contact"},
        {"frame": contact, "type": "sfx", "id": f"{(clip.get('runtime_alignment') or {}).get('motion_law', 'motion')}.impact"},
        {"frame": follow, "type": "vfx", "id": f"{(clip.get('runtime_alignment') or {}).get('motion_law', 'motion')}.follow_through"},
    ]
    clip["vfx_event_markers"] = [e for e in clip["events"] if e["type"] == "vfx"]
    clip["sfx_event_markers"] = [e for e in clip["events"] if e["type"] == "sfx"]
    clip["hit_contact_markers"] = [e for e in clip["events"] if e["type"] == "hit_contact"]
    clip["runtime_alignment"] = {
        **(clip.get("runtime_alignment") or {}),
        "timing": {"anticipation": antic, "contact": contact, "follow": follow, "total": total},
        "synced_to_live_move_frames": True,
    }
    clip["authorship"] = "AUTOMATION_AUTHORED_CANDIDATE"
    clip["human_approved"] = False
    return clip


def main() -> int:
    synced = 0
    for fid in SPECTRUM:
        moves = load_moves(fid)
        for mid in LIVE_MOVES:
            mdata = moves.get(mid) or {}
            clip_names = {mid, (ALIAS.get("move_id_to_clip") or {}).get(mid, mid)}
            # also authority move slot names
            if mid == "aura_burst":
                clip_names.add("aura_burst_move")
            if mid == "aura_charge":
                clip_names.add("aura_charge_move")
            antic, contact, follow, total = extract_timing(mdata)
            for name in clip_names:
                path = ROOT / "content/fighters" / fid / "animations/procedural" / f"{name}.anim.json"
                if not path.is_file():
                    continue
                clip = json.loads(path.read_text())
                clip = sync_clip(clip, antic, contact, follow, total)
                write_clip(fid, name, clip)
                synced += 1
        print(f"synced {fid}")
    print(f"clips_written={synced}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
