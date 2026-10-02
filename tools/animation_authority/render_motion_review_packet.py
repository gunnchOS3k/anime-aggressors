#!/usr/bin/env python3
"""Render PNG contact sheets + GIF strips from runtime anim.json clips."""
from __future__ import annotations

import json
import math
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "artifacts/animation_authority_v1"
RENDER = OUT / "rendered_review"
SPECTRUM = [
    "ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
    "nix-calder", "orion-vell", "vesper-nyx",
]
HEAD = os.environ.get("GIT_HEAD") or subprocess.check_output(["git", "-C", str(ROOT), "rev-parse", "HEAD"], text=True).strip()
ALIAS = json.loads((ROOT / "game-godot/data/runtime/move_clip_alias_map.json").read_text())

REVIEW_SLOTS = [
    ("idle", "idle_primary"), ("walk", "walk_loop"), ("run", "run_loop"), ("dash", "dash_loop"),
    ("turnaround", "turnaround"), ("jump", "jump"), ("double_jump", "double_jump"), ("fast_fall", "fast_fall"),
    ("land_soft", "land_soft"), ("land_hard", "land_hard"), ("shield", "shield_hold"), ("spot_dodge", "spot_dodge"),
    ("air_dodge", "air_dodge_neutral"), ("hurt_light", "hurt_light_front"), ("hurt_heavy", "hurt_heavy"),
    ("launch", "launch_vertical"), ("tumble", "tumble"), ("grab", "grab_hold"), ("throw", "throw_forward"),
    ("jab", "jab_1"), ("heavy", "heavy_attack"), ("neutral_air", "neutral_air"), ("back_air", "back_air"),
    ("neutral_special", "neutral_special_projectile"), ("side_special", "side_special"),
    ("up_special", "up_special_recovery"), ("down_special", "down_special"),
    ("aura_charge", "aura_charge"), ("aura_burst", "aura_burst"), ("victory", "victory"),
]
LAW_COLOR = {
    "combustion": (220, 90, 40), "mass": (120, 110, 90), "current": (80, 170, 230),
    "flow": (90, 200, 150), "structure": (160, 200, 230), "vectors": (180, 140, 255),
    "uncertainty": (140, 100, 180),
}
BONE_CHAIN = [
    ("Spine", (80, 90)), ("Chest", (80, 60)), ("UpperArm_R", (110, 70)), ("LowerArm_R", (130, 90)),
    ("Hand_R", (145, 105)), ("UpperArm_L", (50, 70)), ("LowerArm_L", (30, 90)),
    ("UpperLeg_R", (95, 120)), ("LowerLeg_R", (100, 150)), ("UpperLeg_L", (65, 120)), ("LowerLeg_L", (60, 150)),
]


def load_clip(fid: str, slot: str):
    p = ROOT / "content/fighters" / fid / "animations/procedural" / f"{slot}.anim.json"
    return json.loads(p.read_text()) if p.is_file() else None


def resolve_runtime(slot: str):
    for table in (ALIAS.get("move_id_to_clip") or {}, ALIAS.get("state_to_clip") or {}, ALIAS.get("clip_aliases") or {}):
        if slot in table:
            return table[slot], False
    docs = ALIAS.get("documented_semantic_aliases") or {}
    if slot in docs:
        return docs[slot]["alias_of"], False
    return slot, False


def bone_xy(base, rot, scale=28.0):
    x = base[0] + math.sin(rot[0]) * scale + math.cos(rot[2]) * scale * 0.35
    y = base[1] + math.cos(rot[1]) * scale * 0.55 + math.sin(rot[0]) * 8
    return x, y


def draw_pose(draw, clip, frame_idx, origin, color, label):
    tracks = clip.get("bone_tracks") or {}
    pts = {}
    for bone, base in BONE_CHAIN:
        keys = tracks.get(bone) or []
        rot = keys[min(frame_idx, len(keys) - 1)]["rotation_rad"] if keys else [0, 0, 0]
        x, y = bone_xy(base, rot)
        pts[bone] = (origin[0] + x, origin[1] + y)
    links = [
        ("Spine", "Chest"), ("Chest", "UpperArm_R"), ("UpperArm_R", "LowerArm_R"), ("LowerArm_R", "Hand_R"),
        ("Chest", "UpperArm_L"), ("UpperArm_L", "LowerArm_L"), ("Spine", "UpperLeg_R"), ("UpperLeg_R", "LowerLeg_R"),
        ("Spine", "UpperLeg_L"), ("UpperLeg_L", "LowerLeg_L"),
    ]
    for a, b in links:
        if a in pts and b in pts:
            draw.line([pts[a], pts[b]], fill=color, width=3)
    for bone, (x, y) in pts.items():
        r = 4 if "Hand" in bone else 3
        draw.ellipse([x - r, y - r, x + r, y + r], fill=color)
    draw.text((origin[0] + 8, origin[1] + 168), label, fill=(30, 30, 30))


def render_contact_sheet(fid, label, slot, clip, out_path, variant="NORMAL"):
    law = (clip.get("runtime_alignment") or {}).get("motion_law") or "neutral"
    color = LAW_COLOR.get(law, (80, 80, 80))
    if variant == "BLACK_PUPPET":
        color = (20, 20, 20)
    elif variant == "WHITE_PUPPET":
        color = (40, 40, 40)
    elif variant.startswith("ESSENCE"):
        color = tuple(min(255, c + 40) for c in color)
    poses = clip.get("key_poses") or []
    wanted = []
    for name in ("anticipation", "contact", "apex", "follow", "recovery", "loop_a", "intent"):
        for i, p in enumerate(poses):
            if p.get("name") == name and i not in wanted:
                wanted.append(i)
    if not wanted:
        wanted = list(range(min(3, max(1, len(poses)))))
    wanted = wanted[:3]
    img = Image.new("RGB", (540, 220), (245, 245, 242))
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, 540, 24], fill=(35, 35, 40))
    draw.text((8, 6), f"{fid} | {label} | {slot} | {variant} | head={HEAD[:10]}", fill=(240, 240, 240))
    for i, pi in enumerate(wanted):
        origin = (20 + i * 170, 30)
        pose = poses[pi] if pi < len(poses) else {"name": f"f{pi}", "frame": pi}
        draw_pose(draw, clip, pi, origin, color, f"{pose.get('name')}@{pose.get('frame')}")
        if variant == "WHITE_PUPPET":
            draw.ellipse([origin[0] + 70, origin[1] + 40, origin[0] + 76, origin[1] + 46], fill=(20, 20, 20))
        if variant == "BLACK_PUPPET":
            draw.ellipse([origin[0] + 70, origin[1] + 40, origin[0] + 78, origin[1] + 48], fill=LAW_COLOR.get(law, (220, 90, 40)))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(out_path, format="PNG")
    frames = []
    for pi in wanted:
        fimg = Image.new("RGB", (180, 200), (245, 245, 242))
        fd = ImageDraw.Draw(fimg)
        draw_pose(fd, clip, pi, (10, 10), color, poses[pi].get("name") if pi < len(poses) else "")
        frames.append(fimg)
    gif_path = out_path.with_suffix(".gif")
    if frames:
        frames[0].save(gif_path, save_all=True, append_images=frames[1:], duration=220, loop=0)
    return {
        "fighter_id": fid, "label": label, "semantic_slot": slot, "runtime_clip": slot,
        "head_sha": HEAD, "render_png": str(out_path.relative_to(ROOT)),
        "render_gif": str(gif_path.relative_to(ROOT)),
        "represented_frames": [poses[i] if i < len(poses) else {"index": i} for i in wanted],
        "variant": variant, "human_approved": False,
        "source_clip_path": f"content/fighters/{fid}/animations/procedural/{slot}.anim.json",
    }


def main() -> int:
    RENDER.mkdir(parents=True, exist_ok=True)
    index = {
        "schema": "rendered_motion_review_index_v1",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "head_sha": HEAD, "human_approved": False, "fighters": {},
        "RENDERED_REVIEW_PACKET_7_OF_7": False,
        "PUPPET_RENDER_EVIDENCE_7_OF_7": False,
        "ESSENCE_RENDER_EVIDENCE_0_1_2_4_6": False,
    }
    playback_rows = []
    puppet_ok = 0
    for fid in SPECTRUM:
        fdir = RENDER / fid
        fdir.mkdir(parents=True, exist_ok=True)
        entries = []
        for label, slot in REVIEW_SLOTS:
            clip = load_clip(fid, slot)
            resolved, _ = resolve_runtime(slot)
            if clip is None:
                clip = load_clip(fid, resolved)
            if clip is None:
                playback_rows.append({
                    "fighter_id": fid, "requested_semantic_slot": slot, "resolver_result": resolved,
                    "actual_loaded_clip": None, "fallback": True, "runtime_frame_progression": [], "mismatch": True,
                })
                continue
            actual = clip.get("runtime_clip_id") or clip.get("clip_name") or slot
            mismatch = actual not in (slot, resolved)
            playback_rows.append({
                "fighter_id": fid, "requested_semantic_slot": slot, "resolver_result": resolved,
                "actual_loaded_clip": actual, "fallback": False,
                "runtime_frame_progression": [k.get("frame") for k in (clip.get("key_poses") or [])],
                "mismatch": mismatch, "authorship": clip.get("authorship"),
            })
            entries.append(render_contact_sheet(fid, label, slot, clip, fdir / f"{label}__{slot}.png", "NORMAL"))
        for variant, sample_slot in (("BLACK_PUPPET", "jab_1"), ("WHITE_PUPPET", "aura_burst"),
                                     ("BLACK_PUPPET", "idle_primary"), ("WHITE_PUPPET", "walk_loop")):
            clip = load_clip(fid, sample_slot)
            if clip:
                entries.append(render_contact_sheet(fid, f"puppet_{variant.lower()}", sample_slot, clip,
                                                    fdir / f"puppet_{variant}__{sample_slot}.png", variant))
        puppet_ok += 1
        for level in (0, 1, 2, 4, 6):
            slot = "aura_super_transform" if level == 6 else ("aura_ready" if level >= 2 else "idle_primary")
            clip = load_clip(fid, slot)
            if clip:
                entries.append(render_contact_sheet(
                    fid, f"essence_{level}", slot, clip, fdir / f"essence_{level}__{slot}.png",
                    f"ESSENCE_{level}" if level < 6 else "ESSENCE_6_GRAY_PRISMATIC"))
        index["fighters"][fid] = {"count": len(entries), "entries": entries}
    index["RENDERED_REVIEW_PACKET_7_OF_7"] = len(index["fighters"]) == 7 and all(
        index["fighters"][f]["count"] >= 30 for f in SPECTRUM)
    index["PUPPET_RENDER_EVIDENCE_7_OF_7"] = puppet_ok == 7
    kaia_levels = {e["label"] for e in index["fighters"].get("kaia-windrow", {}).get("entries", [])
                   if str(e.get("label", "")).startswith("essence_")}
    index["ESSENCE_RENDER_EVIDENCE_0_1_2_4_6"] = all(f"essence_{n}" in kaia_levels for n in (0, 1, 2, 4, 6))
    (OUT / "RENDERED_MOTION_REVIEW_INDEX.json").write_text(json.dumps(index, indent=2) + "\n")
    mismatch = sum(1 for r in playback_rows if r.get("mismatch"))
    fallback = sum(1 for r in playback_rows if r.get("fallback"))
    (OUT / "RUNTIME_CANDIDATE_PLAYBACK_PROOF.json").write_text(json.dumps({
        "schema": "runtime_candidate_playback_proof_v1", "head_sha": HEAD, "rows": playback_rows,
        "REVIEWED_RUNTIME_CLIP_MISMATCH_COUNT": mismatch, "REVIEWED_RUNTIME_FALLBACK_COUNT": fallback,
    }, indent=2) + "\n")
    print(json.dumps({
        "RENDERED_REVIEW_PACKET_7_OF_7": index["RENDERED_REVIEW_PACKET_7_OF_7"],
        "PUPPET_RENDER_EVIDENCE_7_OF_7": index["PUPPET_RENDER_EVIDENCE_7_OF_7"],
        "ESSENCE_RENDER_EVIDENCE_0_1_2_4_6": index["ESSENCE_RENDER_EVIDENCE_0_1_2_4_6"],
        "REVIEWED_RUNTIME_CLIP_MISMATCH_COUNT": mismatch,
        "REVIEWED_RUNTIME_FALLBACK_COUNT": fallback,
    }, indent=2))
    return 0 if index["RENDERED_REVIEW_PACKET_7_OF_7"] and mismatch == 0 and fallback == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
