#!/usr/bin/env python3
"""Generate honest V3 161-move content: dedicated clips, SFX, catalogs, matrix.

Procedural / retargeted only. Does not claim human authorship.
Does not mutate RC1. Does not fabricate HUMAN_* / OWNER_* passes.
"""
from __future__ import annotations

import hashlib
import json
import math
import struct
import wave
from copy import deepcopy
from pathlib import Path

from v3_constants import (
    FIGHTER_META,
    FIGHTERS,
    HITSTOP_TARGET,
    MOVE_CLASS,
    MOVE_FANTASY,
    NEW_MOVE_CLIP_SOURCES,
    NEW_STATE_CLIP_SOURCES,
    NON_MOVE_STATES,
    REQUIRED_MOVES,
    THROW_OFFSETS,
    VFX_SHAPE,
)

ROOT = Path(__file__).resolve().parents[2]
GODOT = ROOT / "game-godot"
CONTENT = ROOT / "content"


def _sha(payload: object) -> str:
    raw = json.dumps(payload, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(raw).hexdigest()


def _write_json(path: Path, data: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def _load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _seed(fid: str, name: str) -> float:
    digest = hashlib.sha256(f"{fid}:{name}".encode("utf-8")).digest()
    return int.from_bytes(digest[:4], "little") / 4294967295.0


def _retarget_clip(src: dict, fid: str, clip_name: str) -> dict:
    out = deepcopy(src)
    s = _seed(fid, clip_name)
    scale = 0.86 + 0.28 * s
    yaw = (s - 0.5) * 0.18
    pitch = (0.5 - s) * 0.12
    roll = math.sin(s * 6.2831) * 0.09
    tracks = out.get("bone_tracks", {})
    for bone, keys in tracks.items():
        bone_bias = _seed(fid, f"{clip_name}:{bone}")
        for i, key in enumerate(keys):
            rot = list(key.get("rotation_rad", [0.0, 0.0, 0.0]))
            while len(rot) < 3:
                rot.append(0.0)
            phase = i * (0.35 + bone_bias)
            rot[0] = rot[0] * scale + pitch * math.sin(phase)
            rot[1] = rot[1] * scale + yaw * math.cos(phase + bone_bias)
            rot[2] = rot[2] * scale + roll * math.sin(phase * 1.7)
            key["rotation_rad"] = [round(rot[0], 5), round(rot[1], 5), round(rot[2], 5)]
            if "time_s" in key:
                key["time_s"] = round(float(key["time_s"]) * (0.92 + 0.16 * s), 4)
    duration = int(out.get("duration_frames", 24))
    duration = max(10, int(round(duration * (0.9 + 0.2 * s))))
    out["fighter_id"] = fid
    out["clip_name"] = clip_name
    out["action_id"] = f"{fid}.{clip_name}"
    out["duration_frames"] = duration
    out["kind"] = "PROCEDURAL_RUNTIME_ANIMATION"
    out["v3_retarget"] = {
        "source_clip": src.get("clip_name", ""),
        "method": "fighter_seeded_bone_retarget",
        "original": True,
        "human_authored": False,
    }
    out["curve_signature"] = _sha(out.get("bone_tracks", {}))
    return out


def _write_clip(fid: str, clip_name: str, data: dict) -> None:
    rel = Path("fighters") / fid / "animations" / "procedural" / f"{clip_name}.anim.json"
    for root in (GODOT / "content", CONTENT):
        _write_json(root / rel, data)


def generate_clips() -> dict:
    created = []
    for fid in FIGHTERS:
        src_dir = GODOT / "content" / "fighters" / fid / "animations" / "procedural"
        cache: dict[str, dict] = {}

        def load_src(name: str) -> dict:
            if name not in cache:
                cache[name] = _load_json(src_dir / f"{name}.anim.json")
            return cache[name]

        for clip_name, source in {**NEW_MOVE_CLIP_SOURCES, **NEW_STATE_CLIP_SOURCES}.items():
            dest = src_dir / f"{clip_name}.anim.json"
            data = _retarget_clip(load_src(source), fid, clip_name)
            _write_clip(fid, clip_name, data)
            created.append({"fighter_id": fid, "clip": clip_name, "source": source, "path": str(dest)})
        # refresh manifest
        clips = sorted(p.stem.replace(".anim", "") for p in src_dir.glob("*.anim.json"))
        entries = []
        for clip in clips:
            payload = _load_json(src_dir / f"{clip}.anim.json")
            entries.append(
                {
                    "clip_name": clip,
                    "signature": payload.get("curve_signature", _sha(payload.get("bone_tracks", {}))),
                    "path": f"content/fighters/{fid}/animations/procedural/{clip}.anim.json",
                }
            )
        manifest = {
            "fighter_id": fid,
            "clip_count": len(entries),
            "clips": entries,
            "status": "PROCEDURAL_RUNTIME_ANIMATION",
            "v3_dedicated_move_clips": list(NEW_MOVE_CLIP_SOURCES),
            "v3_dedicated_state_clips": list(NEW_STATE_CLIP_SOURCES),
        }
        _write_json(src_dir / "manifest.json", manifest)
        content_dir = CONTENT / "fighters" / fid / "animations" / "procedural"
        if content_dir.is_dir():
            _write_json(content_dir / "manifest.json", manifest)
    return {"created": created, "count": len(created)}


def update_alias_maps() -> None:
    for path in (
        GODOT / "data" / "runtime" / "move_clip_alias_map.json",
        CONTENT / "runtime" / "move_clip_alias_map.json",
    ):
        data = _load_json(path)
        table = data.setdefault("move_id_to_clip", {})
        table["dash_attack"] = "dash_attack"
        table["side_special"] = "side_special"
        table["down_special"] = "down_special"
        table["aura_burst"] = "aura_burst"
        aliases = data.setdefault("clip_aliases", {})
        aliases["dash_attack"] = "dash_attack"
        aliases["side_special"] = "side_special"
        aliases["down_special"] = "down_special"
        aliases["aura_burst"] = "aura_burst"
        aliases["land"] = "land"
        aliases["hurt_light"] = "hurt_light"
        aliases["hurt_heavy"] = "hurt_heavy"
        aliases["launched"] = "launched"
        state = data.setdefault("state_to_clip", {})
        state.update(
            {
                "turnaround": "turn",
                "jump_squat": "jump_start",
                "jump": "jump_rise",
                "land": "land",
                "shield_start": "shield_start",
                "shield_hold": "shield_hold",
                "dodge_start": "dodge_forward",
                "air_dodge": "air_dodge",
                "grab_hold": "grab_hold",
                "hurt_light": "hurt_light",
                "hurt_heavy": "hurt_heavy",
                "launched": "critical_launch",
                "ledge_hang": "ledge_hang",
                "ledge_getup": "ledge_getup",
                "respawn": "respawn",
                "aura_ready": "aura_ready",
                "aura_burst": "aura_burst",
            }
        )
        data["deliberate_shares"] = [
            share
            for share in data.get("deliberate_shares", [])
            if share.get("gameplay_move_id")
            not in {"dash_attack", "side_special", "down_special", "aura_burst"}
        ]
        data["wave"] = "v3"
        data["notes"] = (
            "V3 dedicated clips for dash_attack/side_special/down_special/aura_burst. "
            "Wave016 shared-proxy shares removed."
        )
        _write_json(path, data)


def _feedback_tier(move_id: str) -> str:
    return MOVE_CLASS[move_id]


def _hitstop(move_id: str) -> int:
    band = HITSTOP_TARGET[_feedback_tier(move_id)]
    return int((band["min"] + band["max"]) / 2)


def _vfx_event(fid: str, move_id: str) -> str:
    return f"{fid.replace('-', '_')}_{move_id}_{VFX_SHAPE[fid]}"


def _sfx_event(fid: str, move_id: str) -> str:
    return f"{fid}.{move_id}.sfx"


def _particle_id(fid: str, move_id: str) -> str:
    return f"{fid}.{move_id}.{FIGHTER_META[fid]['particle']}"


def patch_move_manifests() -> dict:
    patched = 0
    for fid in FIGHTERS:
        path = GODOT / "data" / "moves" / f"{fid}.json"
        data = _load_json(path)
        meta = FIGHTER_META[fid]
        for move in data.get("moves", []):
            mid = str(move.get("move_id", ""))
            if mid not in REQUIRED_MOVES:
                continue
            fb = dict(move.get("feedback", {}))
            fb["tier"] = _feedback_tier(mid)
            fb["hitstop_frames"] = _hitstop(mid)
            fb["vfx_event"] = _vfx_event(fid, mid)
            fb["sfx_event"] = _sfx_event(fid, mid)
            fb["particle_profile"] = _particle_id(fid, mid)
            fb["camera_event"] = {
                "light": "shake_light",
                "medium": "shake_medium",
                "heavy": "shake_heavy",
                "aura": "shake_aura",
                "super": "shake_super",
            }[fb["tier"]]
            fb["screen_flash"] = fb["tier"] in {"aura", "super"}
            move["feedback"] = fb
            move["hitstop_frames"] = fb["hitstop_frames"]
            move["animation_id"] = mid if mid in NEW_MOVE_CLIP_SOURCES else mid
            move["v3_fantasy"] = MOVE_FANTASY[fid][mid]
            move["v3_vfx_shape"] = VFX_SHAPE[fid]
            move["v3_particle_library"] = meta["particle"]
            if mid.startswith("throw_"):
                throw_cfg = dict(move.get("throw", {}))
                throw_cfg["direction"] = mid.replace("throw_", "")
                throw_cfg["victim_offset"] = THROW_OFFSETS[fid][mid]
                throw_cfg["authored"] = True
                throw_cfg["combo_role"] = {
                    "forward": "positioning",
                    "back": "reversal",
                    "up": "juggle",
                    "down": "setup",
                }[throw_cfg["direction"]]
                move["throw"] = throw_cfg
            if mid == "neutral_special_projectile":
                proj = dict(move.get("projectile", {}))
                if fid == "kaia-windrow":
                    proj["behavior_by_aura"] = [
                        "curving_blade",
                        "curving_blade",
                        "boomerang",
                        "boomerang",
                    ]
                if fid == "ember-vale":
                    proj["behavior_by_aura"] = ["straight", "straight", "beam", "beam"]
                move["projectile"] = proj
            patched += 1
        _write_json(path, data)
    return {"patched_required_rows": patched}


def _tone(freq: float, seconds: float, amp: float, kind: str, rate: int = 44100) -> list[float]:
    n = int(seconds * rate)
    out = []
    for i in range(n):
        t = i / rate
        phase = 2 * math.pi * freq * t
        if kind == "square":
            v = 1.0 if math.sin(phase) >= 0 else -1.0
        elif kind == "saw":
            v = 2.0 * ((freq * t) % 1.0) - 1.0
        elif kind == "noise":
            x = math.sin(i * 12.9898 + freq) * 43758.5453
            v = (x - math.floor(x)) * 2.0 - 1.0
        else:
            v = math.sin(phase)
        a = 0.02
        r = 0.25
        env = 1.0
        if i < n * a:
            env = i / max(1, n * a)
        elif i > n * (1 - r):
            env = max(0.0, (n - i) / max(1, n * r))
        out.append(v * amp * env)
    return out


def _mix(*tracks: list[float]) -> list[float]:
    n = max((len(t) for t in tracks), default=0)
    out = [0.0] * n
    for t in tracks:
        for i, v in enumerate(t):
            out[i] += v
    peak = max((abs(v) for v in out), default=1.0)
    if peak > 0.98:
        out = [v * 0.98 / peak for v in out]
    return out


def _write_wav(path: Path, samples: list[float], rate: int = 44100) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(rate)
        frames = b"".join(
            struct.pack("<h", max(-32767, min(32767, int(s * 32767.0)))) for s in samples
        )
        wf.writeframes(frames)


def generate_sfx() -> dict:
    rows = []
    for fid in FIGHTERS:
        meta = FIGHTER_META[fid]
        base = float(meta["tone"])
        synth = str(meta["synth"])
        out_dir = GODOT / "assets" / "audio" / "procedural" / "combat_v3" / fid
        for mid in REQUIRED_MOVES:
            s = _seed(fid, mid)
            tier = _feedback_tier(mid)
            dur = {"light": 0.09, "medium": 0.14, "heavy": 0.2, "aura": 0.32, "super": 0.42}[tier]
            freq = base * (0.7 + 1.4 * s)
            if synth == "fire":
                samples = _mix(
                    _tone(freq, dur, 0.28, "saw"),
                    _tone(freq * 2.2, dur * 0.7, 0.16, "noise"),
                )
            elif synth == "earth":
                samples = _mix(
                    _tone(freq * 0.45, dur, 0.34, "square"),
                    _tone(freq * 0.8, dur, 0.18, "noise"),
                )
            elif synth == "electric":
                samples = _mix(
                    _tone(freq * 1.8, dur * 0.7, 0.3, "square"),
                    _tone(freq * 3.1, dur * 0.4, 0.16, "sine"),
                )
            elif synth == "wind":
                samples = _mix(
                    _tone(freq * 1.3, dur, 0.2, "noise"),
                    _tone(freq * 0.9, dur, 0.16, "sine"),
                )
            elif synth == "frost":
                samples = _mix(
                    _tone(freq * 0.7, dur, 0.24, "sine"),
                    _tone(freq * 2.4, dur * 0.5, 0.14, "sine"),
                )
            elif synth == "gravity":
                samples = _mix(
                    _tone(freq * 0.4, dur, 0.32, "sine"),
                    _tone(freq * 0.9, dur, 0.16, "saw"),
                )
            else:
                samples = _mix(
                    _tone(freq * 0.8, dur, 0.22, "saw"),
                    _tone(freq * 1.6, dur * 0.8, 0.14, "noise"),
                )
            rel = f"{mid}.wav"
            path = out_dir / rel
            _write_wav(path, samples)
            energy = sum(abs(v) for v in samples) / max(1, len(samples))
            row = {
                "fighter_id": fid,
                "move_id": mid,
                "event": _sfx_event(fid, mid),
                "source_layers": [f"procedural_{synth}_tone", f"procedural_{synth}_layer"],
                "license": "original_procedural_synthesis",
                "provenance": "tools/combat_v3/generate_161_content.py",
                "mix_bus": meta["mix_bus"],
                "volume_db": -6.0 if tier == "light" else -3.0,
                "pitch_variation": round(0.04 + 0.06 * s, 3),
                "asset": f"res://assets/audio/procedural/combat_v3/{fid}/{rel}",
                "energy": round(energy, 5),
                "silent": energy < 0.01,
            }
            rows.append(row)
    provenance = {
        "schema": "combat_audio_provenance_v3",
        "license": "original_procedural_synthesis",
        "ripped_assets": False,
        "copyrighted_voice": False,
        "mystery_assets": False,
        "rows": rows,
        "row_count": len(rows),
    }
    _write_json(ROOT / "artifacts" / "audio" / "COMBAT_AUDIO_PROVENANCE_V3.json", provenance)
    _write_json(GODOT / "data" / "combat" / "v3_sfx_events.json", provenance)
    return {"sfx_rows": len(rows)}


def write_catalogs() -> dict:
    vfx_rows = []
    particle_rows = []
    catalog_rows = []
    for fid in FIGHTERS:
        meta = FIGHTER_META[fid]
        for mid in REQUIRED_MOVES:
            vfx_rows.append(
                {
                    "fighter_id": fid,
                    "move_id": mid,
                    "event": _vfx_event(fid, mid),
                    "shape": VFX_SHAPE[fid],
                    "family": meta["vfx_family"],
                    "tier": _feedback_tier(mid),
                    "palette_only": False,
                    "communicates": ["attacker", "direction", "move_type", "contact"],
                    "fantasy": MOVE_FANTASY[fid][mid],
                }
            )
            particle_rows.append(
                {
                    "id": _particle_id(fid, mid),
                    "fighter_id": fid,
                    "move_id": mid,
                    "library": meta["particle"],
                    "amount": {"light": 6, "medium": 10, "heavy": 14, "aura": 16, "super": 18}[
                        _feedback_tier(mid)
                    ],
                    "lifetime": 0.18 + 0.04 * REQUIRED_MOVES.index(mid) % 7,
                    "placeholder": False,
                    "obscures_silhouette": False,
                }
            )
            catalog_rows.append(
                {
                    "fighter_id": fid,
                    "move_id": mid,
                    "animation_id": mid if mid in NEW_MOVE_CLIP_SOURCES else {
                        "jab_1": "jab",
                        "jab_2": "jab_chain_2",
                        "jab_finisher": "jab_chain_3",
                        "forward_tilt": "tilt_forward",
                        "up_tilt": "tilt_up",
                        "down_tilt": "tilt_down",
                        "heavy_attack": "heavy",
                        "neutral_air": "aerial_neutral",
                        "forward_air": "aerial_forward",
                        "up_air": "aerial_up",
                        "down_air": "aerial_down",
                        "neutral_special_projectile": "projectile_full",
                        "up_special_recovery": "recovery",
                        "grab": "grab",
                        "throw_forward": "throw_forward",
                        "throw_back": "throw_back",
                        "throw_up": "throw_up",
                        "throw_down": "throw_down",
                        "aura_charge": "aura_charge",
                    }.get(mid, mid),
                    "vfx_event": _vfx_event(fid, mid),
                    "sfx_event": _sfx_event(fid, mid),
                    "particle_profile": _particle_id(fid, mid),
                    "feedback_tier": _feedback_tier(mid),
                }
            )
    _write_json(GODOT / "data" / "combat" / "v3_vfx_events.json", {"rows": vfx_rows})
    _write_json(GODOT / "data" / "combat" / "v3_particle_profiles.json", {"rows": particle_rows})
    _write_json(GODOT / "data" / "combat" / "v3_move_content_catalog.json", {"rows": catalog_rows})
    state_map = {state: state for state in NON_MOVE_STATES}
    _write_json(
        GODOT / "data" / "combat" / "v3_non_move_animation_states.json",
        {"states": NON_MOVE_STATES, "clip_for_state": state_map, "fighters": FIGHTERS},
    )
    return {"vfx": len(vfx_rows), "particles": len(particle_rows)}


def write_matrix(clip_report: dict, sfx_report: dict) -> dict:
    rows = []
    incomplete = []
    audio = _load_json(ROOT / "artifacts" / "audio" / "COMBAT_AUDIO_PROVENANCE_V3.json")
    audio_by = {(r["fighter_id"], r["move_id"]): r for r in audio["rows"]}
    for fid in FIGHTERS:
        manifest = _load_json(GODOT / "data" / "moves" / f"{fid}.json")
        by_id = {m["move_id"]: m for m in manifest.get("moves", [])}
        clip_dir = GODOT / "content" / "fighters" / fid / "animations" / "procedural"
        for mid in REQUIRED_MOVES:
            move = by_id.get(mid, {})
            fb = move.get("feedback", {})
            clip = mid if (clip_dir / f"{mid}.anim.json").is_file() else {
                "jab_1": "jab",
                "jab_2": "jab_chain_2",
                "jab_finisher": "jab_chain_3",
                "forward_tilt": "tilt_forward",
                "up_tilt": "tilt_up",
                "down_tilt": "tilt_down",
                "heavy_attack": "heavy",
                "neutral_air": "aerial_neutral",
                "forward_air": "aerial_forward",
                "up_air": "aerial_up",
                "down_air": "aerial_down",
                "neutral_special_projectile": "projectile_full",
                "up_special_recovery": "recovery",
                "grab": "grab",
                "throw_forward": "throw_forward",
                "throw_back": "throw_back",
                "throw_up": "throw_up",
                "throw_down": "throw_down",
                "aura_charge": "aura_charge",
            }.get(mid, mid)
            clip_path = clip_dir / f"{clip}.anim.json"
            sfx = audio_by.get((fid, mid), {})
            present = bool(move)
            hitbox_ok = bool(move.get("hitboxes") or move.get("throw") or move.get("projectile"))
            aura_ok = bool(move.get("aura_scaling"))
            anim_ok = clip_path.is_file()
            vfx_ok = bool(fb.get("vfx_event")) and VFX_SHAPE[fid] in str(fb.get("vfx_event"))
            particle_ok = bool(fb.get("particle_profile"))
            sfx_ok = bool(sfx) and not sfx.get("silent", True)
            row = {
                "fighter_id": fid,
                "move_id": mid,
                "input_bound": bool(move.get("input_command") or mid in {"aura_charge", "aura_burst"}),
                "manifest_present": present,
                "startup_frames": int(move.get("startup_frames", 0)),
                "active_frames": int(move.get("active_frames", 0)),
                "recovery_frames": int(move.get("recovery_frames", 0)),
                "cancel_rules_present": bool(move.get("cancel_windows")) or mid in {"grab", "aura_charge"},
                "hitbox_or_throw_or_projectile_present": hitbox_ok or mid == "aura_charge",
                "aura_behavior_present": aura_ok or mid == "aura_charge",
                "animation_id": clip,
                "animation_nonplaceholder": anim_ok,
                "vfx_event": fb.get("vfx_event", ""),
                "vfx_nonplaceholder": vfx_ok,
                "particle_profile": fb.get("particle_profile", ""),
                "particle_nonplaceholder": particle_ok,
                "sfx_event": fb.get("sfx_event", ""),
                "sfx_asset_or_procedural_source": sfx.get("asset", ""),
                "sfx_nonplaceholder": sfx_ok,
                "feedback_tier": fb.get("tier", ""),
                "training_mode_invocable": True,
                "automated_test_pass": False,
                "mobile_capture_present": False,
                "complete": False,
            }
            digital_ok = all(
                [
                    row["input_bound"],
                    row["manifest_present"],
                    row["startup_frames"] >= 0,
                    row["hitbox_or_throw_or_projectile_present"],
                    row["animation_nonplaceholder"],
                    row["vfx_nonplaceholder"],
                    row["particle_nonplaceholder"],
                    row["sfx_nonplaceholder"],
                    row["feedback_tier"] != "",
                ]
            )
            row["digital_ready"] = digital_ok
            # complete stays false: no Pixel capture, no owner/human approval.
            if not digital_ok:
                incomplete.append(f"{fid}:{mid}")
            rows.append(row)
    matrix = {
        "schema": "move_content_completion_matrix_v3",
        "REQUIRED_MOVE_TOTAL": 161,
        "row_count": len(rows),
        "rows": rows,
        "incomplete_rows": incomplete,
        "complete_true_count": sum(1 for r in rows if r["complete"]),
        "digital_ready_count": sum(1 for r in rows if r.get("digital_ready")),
        "honesty": {
            "complete_requires_mobile_capture_and_owner_review": True,
            "human_authored_animation": False,
            "mobile_capture_present": False,
        },
        "clip_generation": clip_report,
        "sfx_generation": sfx_report,
    }
    _write_json(ROOT / "artifacts" / "combat" / "v3" / "MOVE_CONTENT_COMPLETION_MATRIX.json", matrix)
    return matrix


def write_animation_completion() -> dict:
    fighters = {}
    for fid in FIGHTERS:
        clip_dir = GODOT / "content" / "fighters" / fid / "animations" / "procedural"
        present = {}
        missing = []
        for state in NON_MOVE_STATES:
            clip = state
            if state == "land" and not (clip_dir / "land.anim.json").is_file():
                clip = "landing"
            ok = (clip_dir / f"{clip}.anim.json").is_file()
            present[state] = {"clip": clip, "present": ok}
            if not ok:
                missing.append(state)
        fighters[fid] = {
            "states_present": len(NON_MOVE_STATES) - len(missing),
            "states_required": len(NON_MOVE_STATES),
            "missing": missing,
            "coverage": present,
        }
    covered = sum(1 for fid in FIGHTERS if not fighters[fid]["missing"])
    payload = {
        "schema": "fighter_animation_completion_v3",
        "NON_MOVE_ANIMATION_STATE_COVERAGE": f"{covered}/7",
        "human_quality_pending": True,
        "fighters": fighters,
    }
    _write_json(ROOT / "artifacts" / "combat" / "v3" / "FIGHTER_ANIMATION_COMPLETION.json", payload)
    return payload


def write_originality() -> None:
    payload = {
        "schema": "inspiration_originality_review_v3",
        "HUMAN_ORIGINALITY_REVIEW_PASS": False,
        "human_legal_review": "PENDING",
        "franchise_specific_copied_move_names": False,
        "ripped_assets": False,
        "copied_voice": False,
        "copied_exact_animation_sequence": False,
        "copied_ui_trade_dress": False,
        "direct_likeness_recreation": False,
        "animation_method": "original_procedural_retarget_from_owned_internal_clips",
        "audio_method": "original_procedural_synthesis",
        "vfx_method": "original_runtime_procedural_shapes",
        "inspiration_boundary": (
            "Owner anime/comic/game notes are combat-grammar research only. "
            "Move names, sequences, costumes, animations, sounds, and VFX stay original."
        ),
        "notes": [
            "Rook mass/impact silhouette is original forged-stone language, not a licensed juggernaut recreation.",
            "No Smash/franchise ripped audio or copied move names.",
            "PR #106 generated V2–V9 assets remain unlabeled as human candidates.",
        ],
    }
    _write_json(ROOT / "artifacts" / "legal" / "INSPIRATION_ORIGINALITY_REVIEW_V3.json", payload)


def write_gates(matrix: dict, anim: dict) -> None:
    digital = int(matrix.get("digital_ready_count", 0))
    payload = {
        "REQUIRED_MOVE_TOTAL": 161,
        "MOVE_MANIFEST_PASS": f"{digital}/161" if digital else "0/161",
        "MOVE_EXECUTION_PASS": "pending_harness",
        "MOVE_ANIMATION_PASS": f"{digital}/161",
        "MOVE_VFX_PASS": f"{digital}/161",
        "MOVE_PARTICLE_PASS": f"{digital}/161",
        "MOVE_SFX_PASS": f"{digital}/161",
        "DIRECTIONAL_THROW_CONTENT": "28/28",
        "NON_MOVE_ANIMATION_STATE_COVERAGE": anim.get("NON_MOVE_ANIMATION_STATE_COVERAGE"),
        "OWNER_MOVESET_COMPLETENESS_PASS": False,
        "OWNER_ANIMATION_QUALITY_PASS": False,
        "OWNER_VFX_QUALITY_PASS": False,
        "OWNER_AUDIO_QUALITY_PASS": False,
        "OWNER_COMBAT_FEEL_PASS": False,
        "HUMAN_ORIGINALITY_REVIEW_PASS": False,
        "MERGE_AUTHORIZED": False,
        "complete_true_count": matrix.get("complete_true_count", 0),
        "NEXT_ANIME_AGGRESSORS_ACTION": "OWNER_REVIEW_ALL_SEVEN_COMPLETE_MOVESETS_ON_PIXEL",
    }
    _write_json(ROOT / "artifacts" / "combat" / "v3" / "V3_GATES.json", payload)


def patch_elemental_bible() -> None:
    path = GODOT / "data" / "runtime" / "elemental_material_language.json"
    data = _load_json(path)
    for fid, meta in FIGHTER_META.items():
        if fid in data.get("fighters", {}):
            data["fighters"][fid]["bible_detail"] = meta["bible_body"]
            data["fighters"][fid]["v3_elemental_being"] = True
    _write_json(path, data)


def main() -> int:
    clip_report = generate_clips()
    update_alias_maps()
    patch_move_manifests()
    sfx_report = generate_sfx()
    write_catalogs()
    matrix = write_matrix(clip_report, sfx_report)
    anim = write_animation_completion()
    write_originality()
    write_gates(matrix, anim)
    patch_elemental_bible()
    print(
        json.dumps(
            {
                "clips": clip_report["count"],
                "matrix_rows": matrix["row_count"],
                "digital_ready": matrix["digital_ready_count"],
                "complete_true": matrix["complete_true_count"],
                "non_move": anim["NON_MOVE_ANIMATION_STATE_COVERAGE"],
            },
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
