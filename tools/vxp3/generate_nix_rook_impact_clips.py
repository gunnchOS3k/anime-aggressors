#!/usr/bin/env python3
"""Author Godot pose-to-pose Nix/Rook impact clips + owned SFX placeholders.

Provenance: in-repo procedural choreography. Not final art. No third-party packs.
No root-motion translation keys — rotations only.
"""
from __future__ import annotations

import hashlib
import json
import math
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GODOT = ROOT / "game-godot"
SLICE = ("nix-calder", "rook-ironside")
BONES = [
    "Spine",
    "Chest",
    "UpperArm_R",
    "LowerArm_R",
    "Hand_R",
    "UpperArm_L",
    "LowerArm_L",
    "UpperLeg_R",
    "LowerLeg_R",
    "UpperLeg_L",
    "LowerLeg_L",
]

IDENTITY = {
    "nix-calder": {
        "lane": "frost",
        "idle_amp": 0.018,
        "foot_amp": 0.04,
        "contact_snap": 0.55,
        "stiffness": 0.82,
        "follow": 0.35,
        "spine_plant": 0.02,
        "color": "crystalline",
    },
    "rook-ironside": {
        "lane": "impact",
        "idle_amp": 0.045,
        "foot_amp": 0.22,
        "contact_snap": 0.95,
        "stiffness": 0.35,
        "follow": 1.35,
        "spine_plant": 0.11,
        "color": "planted",
    },
}

NEW_CLIPS = {
    "hurt_flinch": {"frames": 16, "kind": "flinch"},
    "hurt_stagger": {"frames": 22, "kind": "stagger"},
    "hurt_crumple": {"frames": 28, "kind": "crumple"},
    "hurt_launch": {"frames": 30, "kind": "launch"},
    "hurt_tumble": {"frames": 32, "kind": "tumble"},
    "hurt_spike": {"frames": 24, "kind": "spike"},
    "hurt_freeze_stiffness": {"frames": 26, "kind": "freeze"},
    "hurt_body_snap": {"frames": 22, "kind": "snap"},
    "hurt_shield_recoil": {"frames": 14, "kind": "shield"},
    "hurt_ground_bounce": {"frames": 24, "kind": "bounce"},
    "hurt_wall_splat": {"frames": 20, "kind": "splat"},
    "hurt_ko_spin": {"frames": 36, "kind": "ko"},
    "contact_light": {"frames": 10, "kind": "contact"},
    "contact_medium": {"frames": 12, "kind": "contact"},
    "contact_heavy": {"frames": 14, "kind": "contact"},
    "contact_aura": {"frames": 16, "kind": "contact"},
    "contact_super": {"frames": 18, "kind": "contact"},
    "contact_ko": {"frames": 20, "kind": "contact"},
    "charged_hold": {"frames": 24, "kind": "charged"},
    "uncharged_release": {"frames": 16, "kind": "uncharged"},
    "transition_idle_walk": {"frames": 12, "kind": "transition"},
    "transition_walk_run": {"frames": 10, "kind": "transition"},
    "recovery_identity": {"frames": 18, "kind": "recovery"},
}

DEEPEN = ("idle", "walk", "run", "jab", "heavy", "hurt", "launch", "tumble", "recovery", "aura_charge")

TIER_BY_MOVE = {
    "jab_1": "light",
    "jab_2": "light",
    "jab_finisher": "medium",
    "forward_tilt": "light",
    "up_tilt": "light",
    "down_tilt": "light",
    "dash_attack": "medium",
    "heavy_attack": "heavy",
    "neutral_air": "medium",
    "forward_air": "medium",
    "up_air": "medium",
    "down_air": "medium",
    "neutral_special_projectile": "medium",
    "side_special": "medium",
    "up_special_recovery": "medium",
    "down_special": "heavy",
    "grab": "light",
    "throw_forward": "heavy",
    "throw_back": "heavy",
    "throw_up": "heavy",
    "throw_down": "heavy",
    "aura_charge": "aura",
    "aura_burst": "aura",
}

REACTION_BY_TIER = {
    "light": "flinch",
    "medium": "stagger",
    "heavy": "body_snap",
    "aura": "launch",
    "super": "launch",
    "ko": "ko_spin",
}

NIX_REACTION = {
    "light": "flinch",
    "medium": "freeze_stiffness",
    "heavy": "freeze_stiffness",
    "aura": "launch",
    "super": "launch",
    "ko": "ko_spin",
}


def sha(obj) -> str:
    blob = json.dumps(obj, sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(blob).hexdigest()


def pose(fid: str, kind: str, t: float, frame: int) -> dict[str, list[float]]:
    ident = IDENTITY[fid]
    nix = fid == "nix-calder"
    w = 2.0 * math.pi * t
    idle = ident["idle_amp"]
    foot = ident["foot_amp"]
    snap = ident["contact_snap"]
    stiff = ident["stiffness"]
    follow = ident["follow"]
    plant = ident["spine_plant"]
    hold = 1.0 if (nix and kind in ("freeze", "launch") and frame < 6) else (0.35 if kind == "snap" and frame < 3 else 0.0)

    def v(x, y, z):
        if nix:
            return [round(x * stiff + 0.01, 5), round(y * 0.55, 5), round(z * 0.8, 5)]
        return [round(x * follow, 5), round(y * 1.15, 5), round(z + plant * 0.4, 5)]

    if kind == "idle":
        return {
            "Spine": v(idle * math.sin(w), 0.0, plant * 0.2),
            "Chest": v(idle * 0.6 * math.sin(w + 0.4), 0.0, 0.0),
            "UpperArm_R": v(0.08 + idle, -0.12 if nix else 0.22, 0.05),
            "UpperArm_L": v(0.08 + idle, 0.12 if nix else -0.18, -0.05),
            "UpperLeg_R": v(foot * 0.15, 0.0, 0.02),
            "UpperLeg_L": v(foot * 0.15, 0.0, -0.02),
        }
    if kind in ("walk", "run", "transition"):
        amp = foot * (1.6 if kind == "run" else 1.0)
        return {
            "Spine": v(0.03, plant * math.sin(w), 0.04 if not nix else 0.0),
            "Chest": v(0.02, 0.05 * math.sin(w), 0.0),
            "UpperLeg_R": v(amp * math.sin(w), 0.0, 0.04),
            "LowerLeg_R": v(-amp * 0.6 * math.sin(w), 0.0, 0.0),
            "UpperLeg_L": v(-amp * math.sin(w), 0.0, -0.04),
            "LowerLeg_L": v(amp * 0.6 * math.sin(w), 0.0, 0.0),
            "UpperArm_R": v(0.1, -amp * 0.4 * math.sin(w), 0.1),
            "UpperArm_L": v(0.1, amp * 0.4 * math.sin(w), -0.1),
        }
    if kind in ("contact", "jab", "heavy", "charged", "uncharged"):
        punch = snap * (1.4 if kind in ("heavy", "contact") else 0.8)
        return {
            "Spine": v(0.04 + hold * 0.08, 0.12 * punch, plant),
            "Chest": v(0.08 + hold * 0.1, 0.2 * punch, 0.0),
            "UpperArm_R": v(-0.4 * punch, -0.9 * punch, 0.25),
            "LowerArm_R": v(-0.2, -0.5 * punch, 0.1),
            "Hand_R": v(0.1, -0.3 * punch, 0.35 if nix else 0.05),
            "UpperArm_L": v(0.15, 0.25, -0.1),
            "UpperLeg_R": v(0.08, 0.0, 0.12 if not nix else 0.01),
            "UpperLeg_L": v(0.16 if not nix else 0.02, 0.0, -0.04),
        }
    if kind in ("flinch", "stagger", "crumple", "hurt"):
        k = {"flinch": 0.35, "stagger": 0.7, "crumple": 1.05, "hurt": 0.5}[kind]
        return {
            "Spine": v(-0.12 * k - hold, 0.08 * k, plant),
            "Chest": v(-0.18 * k, 0.16 * k, 0.0),
            "UpperArm_R": v(0.4 * k, 0.5 * k, 0.2),
            "UpperArm_L": v(0.35 * k, -0.4 * k, -0.15),
            "UpperLeg_R": v(0.12 * k, 0.0, 0.06),
            "UpperLeg_L": v(0.18 * k, 0.0, -0.04),
        }
    if kind in ("launch", "tumble", "spike", "freeze", "snap", "bounce", "splat", "ko"):
        spin = 0.0 if hold > 0.5 else (t * (1.8 if kind == "tumble" else 1.1))
        down = 0.8 if kind == "spike" else (-0.55 if kind != "bounce" else 0.4)
        return {
            "Spine": v(down * 0.4 + hold * 0.15, spin * 0.3, plant + spin * 0.2),
            "Chest": v(down * 0.5, spin * 0.5, 0.1),
            "UpperArm_R": v(0.6, 0.8 + spin, 0.3),
            "UpperArm_L": v(0.55, -0.7 - spin, -0.25),
            "UpperLeg_R": v(0.4 + down * 0.2, 0.2, 0.1),
            "UpperLeg_L": v(0.35 + down * 0.2, -0.15, -0.08),
        }
    if kind in ("shield",):
        return {
            "Spine": v(0.05, 0.0, plant),
            "Chest": v(0.12, 0.0, 0.0),
            "UpperArm_R": v(-0.5, -0.4, 0.3),
            "UpperArm_L": v(-0.5, 0.4, -0.3),
        }
    if kind in ("recovery",):
        return {
            "Spine": v(0.03, 0.0, plant * 0.5),
            "Chest": v(0.04, 0.02, 0.0),
            "UpperArm_R": v(0.12, -0.1, 0.05),
            "UpperArm_L": v(0.12, 0.1, -0.05),
        }
    return pose(fid, "idle", t, frame)


def keys_for(fid: str, kind: str, frames: int) -> dict:
    fps = 60.0
    # Pose-to-pose: few held keys, not mocap-smooth.
    samples = [0, max(1, frames // 5), max(2, frames // 3), max(3, (2 * frames) // 3), frames - 1]
    tracks = {b: [] for b in BONES}
    for fr in samples:
        t = fr / fps
        p = pose(fid, kind, t, fr)
        for bone in BONES:
            rot = p.get(bone, [0.0, 0.0, 0.0])
            tracks[bone].append({"frame": fr, "time_s": round(fr / fps, 4), "rotation_rad": rot})
    return tracks


def write_clip(fid: str, name: str, frames: int, kind: str, extra_events: list | None = None) -> dict:
    ident = IDENTITY[fid]
    tracks = keys_for(fid, kind, frames)
    events = [
        {"frame": 0, "event_type": "anticipation_start", "payload": {"pose": ident["color"], "fighter": fid}},
        {"frame": max(1, frames // 4), "event_type": "active_start", "payload": {"contact": name, "root": "none"}},
        {
            "frame": max(2, frames // 3),
            "event_type": "hitbox_on",
            "payload": {"socket": "hand_r" if not name.startswith("hurt") else "chest", "lane": ident["lane"]},
        },
        {"frame": max(3, frames // 2), "event_type": "hitbox_off", "payload": {"vfx": ident["lane"]}},
        {"frame": frames - 2, "event_type": "recovery_start", "payload": {"follow": ident["color"]}},
    ]
    if extra_events:
        events.extend(extra_events)
    data = {
        "schema_version": 1,
        "fighter_id": fid,
        "action_id": f"{fid}.{name}",
        "clip_name": name,
        "kind": "PROCEDURAL_RUNTIME_ANIMATION",
        "production_status": "GODOT_AUTHORED_POSE_TO_POSE_PLACEHOLDER",
        "not_final_art": True,
        "fps": 60.0,
        "duration_frames": frames,
        "bone_tracks": tracks,
        "runtime_alignment": {
            "moves_json_key": name,
            "hitbox_phase_sync": True,
            "root_motion_style": "none",
            "ground_coupling": "nix_precise" if fid == "nix-calder" else "rook_planted",
            "vxp3_identity": ident["color"],
        },
        "events": events,
        "provenance": {
            "author": "vxp3-phase1-generator",
            "license": "owned_in_repo",
            "third_party": False,
            "final_art_claim": False,
        },
    }
    data["curve_signature"] = sha(tracks)
    return data


def deepen_existing(path: Path, fid: str, name: str) -> None:
    raw = json.loads(path.read_text())
    kind = name if name in ("idle", "walk", "run", "jab", "heavy", "hurt", "launch", "tumble", "recovery") else "idle"
    if name == "aura_charge":
        kind = "charged"
    frames = int(raw.get("duration_frames", 24))
    overlay = keys_for(fid, kind, frames)
    tracks = raw.get("bone_tracks", {})
    for bone, keys in overlay.items():
        if bone not in tracks:
            tracks[bone] = keys
            continue
        # Mix identity offsets into existing keys without changing times/count.
        for i, key in enumerate(tracks[bone]):
            src = keys[min(i, len(keys) - 1)]["rotation_rad"]
            dest = list(key.get("rotation_rad", [0, 0, 0]))
            for a in range(3):
                dest[a] = round(float(dest[a]) * 0.55 + float(src[a]) * 0.45, 5)
            key["rotation_rad"] = dest
    raw["bone_tracks"] = tracks
    raw["curve_signature"] = sha(tracks)
    raw["vxp3_deepened"] = True
    raw["not_final_art"] = True
    raw["production_status"] = "GODOT_AUTHORED_POSE_TO_POSE_PLACEHOLDER"
    ev = raw.get("events", [])
    ev.append({"frame": 0, "event_type": "vxp3_identity", "payload": {"fighter": fid, "clip": name}})
    raw["events"] = ev
    path.write_text(json.dumps(raw, indent=2) + "\n")


def annotate_moves(fid: str) -> None:
    path = GODOT / "data" / "moves" / f"{fid}.json"
    doc = json.loads(path.read_text())
    reactions = NIX_REACTION if fid == "nix-calder" else REACTION_BY_TIER
    for move in doc.get("moves", []):
        mid = str(move.get("move_id", ""))
        tier = TIER_BY_MOVE.get(mid, str(move.get("feedback", {}).get("tier", "medium")))
        if mid == "special":
            raise SystemExit(f"refusing generic special on {fid}")
        startup = int(move.get("startup_frames", 4))
        active = int(move.get("active_frames", 3))
        contact = startup + max(0, active // 2)
        socket = "hand_l" if fid == "nix-calder" else "hand_r"
        if "air" in mid or "down" in mid:
            socket = "foot_r" if fid == "rook-ironside" else "hand_l"
        move["impact_profile"] = tier
        move["choreography"] = {
            "contact_socket": socket,
            "contact_frame": contact,
            "contact_pose_clip": f"contact_{tier if tier != 'super' else 'super'}",
            "victim_reaction_family": reactions.get(tier, "flinch"),
            "charged_layer": "hold" if mid == "aura_charge" else ("release" if mid == "aura_burst" else "none"),
            "cinematic_hook": "warranted_heavy" if tier in ("heavy", "aura", "super", "ko") else "",
        }
        move["anime_timing"] = {
            "anticipation_holds": 3 if fid == "nix-calder" else 2,
            "impact_accent_frames": 2 if fid == "nix-calder" else 3,
            "recovery_settle": 4 if fid == "nix-calder" else 5,
            "pose_to_pose": True,
        }
    path.write_text(json.dumps(doc, indent=2) + "\n")


def write_wav(path: Path, freq: float, dur: float, amp: float = 0.22) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    sr = 22050
    n = int(sr * dur)
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        frames = bytearray()
        for i in range(n):
            t = i / sr
            env = min(1.0, i / 80.0) * max(0.0, 1.0 - t / dur)
            sample = int(max(-1.0, min(1.0, math.sin(2 * math.pi * freq * t) * env * amp)) * 32767)
            frames += struct.pack("<h", sample)
        w.writeframes(frames)
    uid = hashlib.md5(str(path).encode()).hexdigest()[:12]
    dest = hashlib.md5(path.name.encode()).hexdigest()
    path.with_suffix(".wav.import").write_text(
        "\n".join(
            [
                "[remap]",
                "",
                'importer="wav"',
                'type="AudioStreamWAV"',
                f'uid="uid://vxp3{uid}"',
                f'path="res://.godot/imported/{path.name}-{dest}.sample"',
                "",
                "[deps]",
                "",
                f'source_file="res://assets/audio/procedural/impact/{path.name}"',
                f'dest_files=["res://.godot/imported/{path.name}-{dest}.sample"]',
                "",
                "[params]",
                "",
                "force/8_bit=false",
                "force/mono=true",
                "force/max_rate=false",
                "force/max_rate_hz=22050",
                "edit/trim=false",
                "edit/normalize=false",
                "edit/loop_mode=0",
                "edit/loop_begin=0",
                "edit/loop_end=-1",
                "compress/mode=2",
                "",
            ]
        )
    )


def generate_audio() -> list[str]:
    specs = {
        "frost": (1760, 0.09),
        "impact": (90, 0.14),
        "flame": (220, 0.11),
        "volt": (1480, 0.08),
        "gale": (440, 0.10),
        "gravity": (70, 0.16),
        "void": (130, 0.13),
    }
    tiers = {"light": 0.7, "medium": 1.0, "heavy": 1.25, "aura": 1.4, "super": 1.55, "ko": 1.7}
    written = []
    out_dir = GODOT / "assets" / "audio" / "procedural" / "impact"
    for element, (freq, dur) in specs.items():
        use_tiers = tiers if element in ("frost", "impact") else {k: tiers[k] for k in ("light", "medium", "heavy")}
        for tier, mul in use_tiers.items():
            p = out_dir / f"{element}_{tier}.wav"
            write_wav(p, freq * (0.85 if tier == "heavy" else 1.0), dur * mul, 0.18 * mul)
            written.append(str(p.relative_to(ROOT)))
    return written


def refresh_manifest(fid: str, anim_dir: Path) -> None:
    clips = []
    for p in sorted(anim_dir.glob("*.anim.json")):
        data = json.loads(p.read_text())
        clips.append(
            {
                "clip_name": p.name.replace(".anim.json", ""),
                "signature": data.get("curve_signature", sha(data.get("bone_tracks", {}))),
                "path": f"content/fighters/{fid}/animations/procedural/{p.name}",
            }
        )
    (anim_dir / "manifest.json").write_text(
        json.dumps(
            {
                "fighter_id": fid,
                "clip_count": len(clips),
                "clips": clips,
                "status": "PROCEDURAL_RUNTIME_ANIMATION",
                "vxp3_phase": 1,
                "not_final_art": True,
            },
            indent=2,
        )
        + "\n"
    )


def main() -> None:
    created = []
    for fid in SLICE:
        anim_dir = GODOT / "content" / "fighters" / fid / "animations" / "procedural"
        for name in DEEPEN:
            p = anim_dir / f"{name}.anim.json"
            if p.exists():
                deepen_existing(p, fid, name)
                created.append(str(p.relative_to(ROOT)))
        extra = []
        if fid == "nix-calder":
            extra = [{"frame": 4, "event_type": "ice_fragments", "payload": {"owned": True}}]
        else:
            extra = [
                {"frame": 3, "event_type": "ground_dust", "payload": {"owned": True}},
                {"frame": 5, "event_type": "ring_shockwave", "payload": {"owned": True}},
            ]
        for name, spec in NEW_CLIPS.items():
            data = write_clip(fid, name, spec["frames"], spec["kind"], extra)
            dest = anim_dir / f"{name}.anim.json"
            dest.write_text(json.dumps(data, indent=2) + "\n")
            created.append(str(dest.relative_to(ROOT)))
        annotate_moves(fid)
        refresh_manifest(fid, anim_dir)
        mirror = ROOT / "content" / "fighters" / fid / "animations" / "procedural"
        if mirror.exists():
            for name in list(NEW_CLIPS) + list(DEEPEN):
                src = anim_dir / f"{name}.anim.json"
                if src.exists():
                    (mirror / src.name).write_text(src.read_text())
    wavs = generate_audio()
    prov = {
        "program": "VXP-3",
        "phase": 1,
        "not_final_art": True,
        "third_party_packs": [],
        "launcher_icon_used_as_brand": False,
        "assets": created + wavs,
        "method": "Godot-authored pose-to-pose JSON + owned sine placeholders",
        "physics": "no root motion; competitive distances unchanged",
    }
    out = ROOT / "artifacts" / "vxp3" / "provenance" / "ASSETS.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(prov, indent=2) + "\n")
    print(json.dumps({"clips": len(created), "wavs": len(wavs)}, indent=2))


if __name__ == "__main__":
    main()
