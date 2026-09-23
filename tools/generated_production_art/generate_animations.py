#!/usr/bin/env python3
"""Write generated production .anim.json clips for the full roster."""
from __future__ import annotations

import hashlib
from pathlib import Path

from .action_catalog import LOOPING, all_actions, duration_for, family
from .common import (
    ANIM_STATUS,
    FIGHTER_IDS,
    GENERATOR,
    GENERATOR_VERSION,
    RUNTIME_ALIASES,
    generated_anim_dir,
    write_json,
)
from .pose_library import locations_for, phase_times, pose_delta_metrics, poses_for_action
from .profiles import profile


def _keys(pose_map: dict, times: dict, fid: str, action: str) -> tuple[dict, dict]:
    bone_tracks: dict[str, list] = {}
    loc_tracks: dict[str, list] = {}
    ordered = sorted(((frame, name) for name, frame in times.items()), key=lambda row: (row[0], row[1]))
    seen_frames: set[int] = set()
    for frame, name in ordered:
        if name not in pose_map:
            continue
        if frame in seen_frames:
            continue
        seen_frames.add(frame)
        pose = pose_map[name]
        locs = locations_for(fid, action, name)
        time_s = round(frame / 60.0, 4)
        for bone, rot in pose.items():
            bone_tracks.setdefault(bone, []).append(
                {"frame": frame, "time_s": time_s, "rotation_rad": [round(rot[0], 5), round(rot[1], 5), round(rot[2], 5)]}
            )
        for bone, loc in locs.items():
            loc_tracks.setdefault(bone, []).append(
                {"frame": frame, "time_s": time_s, "location_m": [round(loc[0], 5), round(loc[1], 5), round(loc[2], 5)]}
            )
    return bone_tracks, loc_tracks


def build_clip(fid: str, action: str) -> dict:
    p = profile(fid)
    frames = duration_for(action)
    pose_map = poses_for_action(fid, action)
    times = phase_times(action, frames, p)
    times = {name: frame for name, frame in times.items() if name in pose_map}
    if "SETTLE" not in times:
        times["SETTLE"] = 0
        pose_map.setdefault("SETTLE", next(iter(pose_map.values())))
    if "RETURN" not in times:
        times["RETURN"] = frames - 1
        pose_map.setdefault("RETURN", pose_map.get("SETTLE"))
    bone_tracks, loc_tracks = _keys(pose_map, times, fid, action)
    settle = pose_map.get("SETTLE") or pose_map.get("ANTICIPATION")
    peak = pose_map.get("CONTACT") or pose_map.get("HITSTOP_HOLD") or pose_map.get("OVERSHOOT") or settle
    metrics = pose_delta_metrics(settle, peak) if settle and peak else {}
    clip_name = RUNTIME_ALIASES.get(action, action)
    raw = f"{fid}:{action}:{GENERATOR_VERSION}:{frames}"
    payload = {
        "schema_version": 2,
        "fighter_id": fid,
        "action_id": f"{fid}.{action}",
        "clip_name": clip_name,
        "kind": ANIM_STATUS,
        "production_status": ANIM_STATUS,
        "human_authored": False,
        "future_human_replaceable": True,
        "fps": 60.0,
        "duration_frames": frames,
        "loop": action in LOOPING,
        "family": family(action),
        "phases": times,
        "bone_tracks": bone_tracks,
        "location_tracks": loc_tracks,
        "exaggeration": metrics,
        "identity": {
            "element": p.element,
            "role": p.role,
            "timing": p.timing,
            "notes": p.motion_notes,
        },
        "runtime_alignment": {
            "root_motion_style": "none",
            "gameplay_authoritative": True,
            "visual_com_only": True,
        },
        "events": _events(action, times, p),
        "provenance": {
            "asset_id": f"{fid}.{clip_name}",
            "fighter_id": fid,
            "category": "animation",
            "generator": GENERATOR,
            "generator_version": GENERATOR_VERSION,
            "source_master": f"art_source/animation/fighters/{fid}/source/{fid}_production_master.blend",
            "input_profile": fid,
            "status": ANIM_STATUS,
            "future_human_replaceable": True,
        },
        "curve_signature": hashlib.sha256(raw.encode("utf-8")).hexdigest(),
    }
    return payload


def _events(action: str, times: dict, p) -> list[dict]:
    events = []
    if "ANTICIPATION" in times:
        events.append({"frame": times["ANTICIPATION"], "event_type": "anticipation_start", "payload": {"fighter": p.fighter_id, "clip": action}})
    if "CONTACT" in times:
        events.append({"frame": times["CONTACT"], "event_type": "contact_pose", "payload": {"tier": family(action), "socket": "hand_r"}})
    if "HITSTOP_HOLD" in times:
        events.append({"frame": times["HITSTOP_HOLD"], "event_type": "hitstop_hold", "payload": {"visual_only": True}})
    if "FOLLOW_THROUGH" in times:
        events.append({"frame": times["FOLLOW_THROUGH"], "event_type": "follow_through", "payload": {"element": p.element}})
    if "RECOVERY" in times:
        events.append({"frame": times["RECOVERY"], "event_type": "recovery_start", "payload": {}})
    return events


def generate_fighter(fid: str) -> dict:
    out_dir = generated_anim_dir(fid)
    out_dir.mkdir(parents=True, exist_ok=True)
    clips = []
    for action in all_actions():
        clip = build_clip(fid, action)
        name = clip["clip_name"]
        path = out_dir / f"{name}.anim.json"
        write_json(path, clip)
        clips.append({"action": action, "clip": name, "path": str(path.relative_to(path.parents[5] if False else path)), "frames": clip["duration_frames"]})
        # Write under both action and runtime alias when they differ.
        if action != name:
            write_json(out_dir / f"{action}.anim.json", clip)
    manifest = {
        "fighter_id": fid,
        "count": len(list(out_dir.glob("*.anim.json"))),
        "status": ANIM_STATUS,
        "human_authored": False,
        "clips": sorted({c["clip"] for c in clips}),
    }
    write_json(out_dir / "manifest.json", manifest)
    return manifest


def generate_all() -> dict:
    reports = {fid: generate_fighter(fid) for fid in FIGHTER_IDS}
    return {
        "status": ANIM_STATUS,
        "fighters": reports,
        "actions_per_fighter": len(all_actions()),
    }


if __name__ == "__main__":
    from .common import REPORTS

    report = generate_all()
    write_json(REPORTS / "GENERATED_PRODUCTION_ANIMATION.json", report)
    print(f"generated animation clips for {len(report['fighters'])} fighters")
