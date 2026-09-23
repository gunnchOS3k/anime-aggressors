#!/usr/bin/env python3
"""VXP-3 roster-wide structural + not-static validators.

Honest: no invented Pixel/human PASS. Thresholds are large enough that
imperceptible motion fails.
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GODOT = ROOT / "game-godot"
FIGHTERS = (
    "ember-vale",
    "rook-ironside",
    "juno-spark",
    "kaia-windrow",
    "nix-calder",
    "orion-vell",
    "vesper-nyx",
)
FAMILIES = [
    "flinch",
    "stagger",
    "crumple",
    "launch",
    "tumble",
    "spike",
    "freeze_stiffness",
    "body_snap",
    "shield_recoil",
    "ground_bounce",
    "wall_splat",
    "ko_spin",
]
REQUIRED = [
    "idle",
    "idle_personality",
    "walk",
    "walk_start",
    "walk_stop",
    "run",
    "run_start",
    "run_stop",
    "dash",
    "dash_stop",
    "turn",
    "jump_squat",
    "jump",
    "jump_apex",
    "fall",
    "landing",
    "charged_idle",
    "charged_walk",
    "charged_run",
    "charged_dash",
    "charged_jump",
    "charged_fall",
    "charged_land",
    "charge_start",
    "charge_low",
    "charge_mid",
    "charge_high",
    "charge_full",
    "charge_release",
    "jab",
    "heavy",
    "super",
    "hurt",
    "hurt_light",
    "hurt_medium",
    "hurt_heavy",
    "launch",
    "tumble",
    "ko",
    "shield",
    "grab_victim",
    "throw_victim_forward",
    "throw_victim_back",
    "throw_victim_up",
    "throw_victim_down",
    "aura_charge",
    "contact_light",
    "contact_medium",
    "contact_heavy",
    "contact_aura",
    "contact_super",
    "contact_ko",
]
CONTACT = ["contact_light", "contact_medium", "contact_heavy", "contact_aura", "contact_super", "contact_ko"]
TIERS = ["light", "medium", "heavy", "aura", "super", "ko"]
# Visible-motion floors. Tiny 0.02 rad deltas must fail.
IDLE_VARIATION = 0.16
LOCO_POSE = 0.26
HEAVY_PHASE = 0.32
CHARGED_IDLE = 0.28
CHARGED_LOCO = 0.24
HURT_VS_IDLE = 0.38
AURA_VS_HEAVY = 0.32
KO_VS_HEAVY = 0.38
TRACK_DELTA = 0.18


def load(p: Path):
    return json.loads(p.read_text())


def clip_path(fid: str, name: str) -> Path:
    return GODOT / "content" / "fighters" / fid / "animations" / "procedural" / f"{name}.anim.json"


def clip(fid: str, name: str) -> dict:
    return load(clip_path(fid, name))


def sig(fid: str, name: str) -> str:
    return str(clip(fid, name).get("curve_signature", ""))


def pose_at(data: dict, frame: int) -> dict[str, list[float]]:
    tracks = data.get("bone_tracks", {})
    out = {}
    for bone, keys in tracks.items():
        if not keys:
            continue
        chosen = keys[0]
        for key in keys:
            if int(key.get("frame", 0)) <= frame:
                chosen = key
        out[bone] = list(chosen.get("rotation_rad", [0, 0, 0]))
    return out


def pose_dist(a: dict, b: dict) -> float:
    bones = set(a) | set(b)
    best = 0.0
    for bone in bones:
        av = a.get(bone, [0.0, 0.0, 0.0])
        bv = b.get(bone, [0.0, 0.0, 0.0])
        d = math.sqrt(sum((float(av[i]) - float(bv[i])) ** 2 for i in range(3)))
        best = max(best, d)
    return best


def key_poses(data: dict) -> list[dict]:
    tracks = data.get("bone_tracks", {})
    frames = sorted({int(k.get("frame", 0)) for keys in tracks.values() for k in keys})
    return [pose_at(data, fr) for fr in frames]


def distinct_core_poses(data: dict, min_dist: float) -> int:
    poses = key_poses(data)
    kept: list[dict] = []
    for pose in poses:
        if all(pose_dist(pose, prev) >= min_dist for prev in kept):
            kept.append(pose)
    return len(kept)


def track_changed(data: dict, bones: list[str], min_dist: float) -> bool:
    poses = key_poses(data)
    if len(poses) < 2:
        return False
    best = 0.0
    for i in range(1, len(poses)):
        a = {b: poses[0].get(b, [0, 0, 0]) for b in bones}
        c = {b: poses[i].get(b, [0, 0, 0]) for b in bones}
        best = max(best, pose_dist(a, c))
    return best >= min_dist


def validate() -> dict:
    failures: list[str] = []
    notes: list[str] = []
    uniqueness: dict[str, list[str]] = {}

    profiles = load(GODOT / "data" / "combat" / "impact_profiles.json")
    schema_ok = profiles.get("schema_id") == "anime_aggressors.impact_profile.v1"
    for t in TIERS:
        p = profiles.get("profiles", {}).get(t, {})
        if not p:
            failures.append(f"missing impact profile {t}")
            continue
        if int(p.get("attacker_hitstop_frames", -1)) != int(p.get("defender_hitstop_frames", -2)):
            failures.append(f"hitstop not synced for {t}")
        if not p.get("hitstop_sync"):
            failures.append(f"hitstop_sync false for {t}")
    if not profiles.get("no_silent_special_fallback"):
        failures.append("schema missing no_silent_special_fallback")

    lib = load(GODOT / "data" / "combat" / "hurt_reaction_library.json")
    for fam in FAMILIES:
        if fam not in lib.get("families", {}):
            failures.append(f"missing reaction family {fam}")
    for fid in FIGHTERS:
        table = lib.get("fighter_clip_overrides", {}).get(fid, {})
        for fam in FAMILIES:
            name = table.get(fam)
            if not name or not clip_path(fid, name).exists():
                failures.append(f"{fid} missing family clip {fam}")

    vfx = load(GODOT / "data" / "combat" / "element_vfx_palettes.json")
    sfx = load(GODOT / "data" / "combat" / "element_sfx_palettes.json")
    for fid in FIGHTERS:
        if fid not in vfx.get("fighters", {}):
            failures.append(f"missing VFX palette {fid}")
    for element in ("flame", "impact", "volt", "gale", "frost", "gravity", "void"):
        pal = sfx.get("elements", {}).get(element, {}).get("palette", {})
        for tier in TIERS:
            if tier not in pal:
                failures.append(f"SFX {element} missing {tier}")

    seen_sigs: dict[str, str] = {}
    for fid in FIGHTERS:
        for name in REQUIRED:
            if not clip_path(fid, name).exists():
                failures.append(f"{fid} missing required clip {name}")
                continue
            data = clip(fid, name)
            if data.get("fighter_id") != fid:
                failures.append(f"{fid} {name} fighter_id mismatch")
            if not data.get("not_final_art", False):
                failures.append(f"{fid} {name} missing honest not_final_art")
            curve = str(data.get("curve_signature", ""))
            if not curve:
                failures.append(f"{fid} {name} missing signature")
            if curve in seen_sigs:
                failures.append(f"identical full animation signature {seen_sigs[curve]} == {fid}:{name}")
            else:
                seen_sigs[curve] = f"{fid}:{name}"
        if not clip_path(fid, "idle").exists():
            continue
        idle = clip(fid, "idle")
        if distinct_core_poses(idle, IDLE_VARIATION) < 2:
            failures.append(f"{fid} idle loop has no visible variation")
        for loco in ("walk", "run"):
            if distinct_core_poses(clip(fid, loco), LOCO_POSE) < 3:
                failures.append(f"{fid} {loco} has <3 distinct core poses")
        heavy = clip(fid, "heavy")
        if distinct_core_poses(heavy, HEAVY_PHASE) < 4:
            failures.append(f"{fid} heavy missing anticipation/contact/follow/recovery poses")
        ev = {e.get("event_type") for e in heavy.get("events", [])}
        for token in ("anticipation_start", "contact_pose", "follow_through", "recovery_start"):
            if token not in ev:
                failures.append(f"{fid} heavy missing {token} event")
        charged_idle = clip(fid, "charged_idle")
        if pose_dist(pose_at(idle, 0), pose_at(charged_idle, 0)) < CHARGED_IDLE:
            failures.append(f"{fid} charged idle ≈ base idle")
        if pose_dist(pose_at(clip(fid, "walk"), 0), pose_at(clip(fid, "charged_walk"), 0)) < CHARGED_LOCO:
            failures.append(f"{fid} charged walk ≈ base walk")
        if pose_dist(pose_at(clip(fid, "run"), 0), pose_at(clip(fid, "charged_run"), 0)) < CHARGED_LOCO:
            failures.append(f"{fid} charged run ≈ base run")
        hurt_h = clip(fid, "hurt_heavy")
        if pose_dist(pose_at(idle, 0), pose_at(hurt_h, max(1, hurt_h.get("duration_frames", 8) // 2))) < HURT_VS_IDLE:
            failures.append(f"{fid} heavy hurt ≈ idle")
        if not track_changed(hurt_h, ["UpperArm_R", "UpperArm_L"], TRACK_DELTA):
            failures.append(f"{fid} heavy hurt arms static")
        if not track_changed(hurt_h, ["Spine", "Chest"], TRACK_DELTA):
            failures.append(f"{fid} heavy hurt torso static")
        if not track_changed(hurt_h, ["UpperLeg_R", "UpperLeg_L"], TRACK_DELTA):
            failures.append(f"{fid} heavy hurt hips static")
        if pose_dist(pose_at(clip(fid, "heavy"), clip(fid, "heavy").get("duration_frames", 12) // 2), pose_at(clip(fid, "signature_lane_burst"), 8)) < AURA_VS_HEAVY:
            failures.append(f"{fid} aura ≈ heavy")
        if pose_dist(pose_at(clip(fid, "hurt_heavy"), 8), pose_at(clip(fid, "ko"), 10)) < KO_VS_HEAVY:
            failures.append(f"{fid} KO ≈ heavy reaction")
        moves = load(GODOT / "data" / "moves" / f"{fid}.json").get("moves", [])
        if len(moves) < 20:
            failures.append(f"{fid} move count {len(moves)} < 20")
        for mv in moves:
            mid = mv.get("move_id")
            if mid == "special":
                failures.append(f"{fid} has generic special move_id")
            if mv.get("impact_profile") not in TIERS:
                failures.append(f"{fid} {mid} missing impact_profile")
            ch = mv.get("choreography", {})
            startup = int(mv.get("startup_frames", 0))
            active = int(mv.get("active_frames", 1))
            contact = int(ch.get("contact_frame", -1))
            if contact < startup or contact > startup + active:
                failures.append(f"{fid} {mid} contact_frame {contact} outside hitbox {startup}-{startup+active}")
            if not ch.get("victim_reaction_family"):
                failures.append(f"{fid} {mid} missing victim reaction")
            if "anime_timing" not in mv:
                failures.append(f"{fid} {mid} missing anime_timing")

    for name in ["idle", "walk", "run", "heavy", "hurt_heavy", "charged_idle", "ko", "signature_lane_burst"]:
        sigs = [sig(fid, name) for fid in FIGHTERS if clip_path(fid, name).exists()]
        if len(set(sigs)) != len(sigs):
            failures.append(f"roster identical signature on {name}")
        uniqueness[name] = [s[:12] for s in sigs]
        notes.append(f"{name} unique={len(set(sigs))}/{len(sigs)}")

    resolver = (GODOT / "scripts" / "visual" / "runtime_move_resolver.gd").read_text()
    if 'if requested == "special":' in resolver and "projectile_full" in resolver.split('if requested == "special":')[1][:400]:
        block = resolver.split('if requested == "special":', 1)[1][:350]
        if "for fallback" in block:
            failures.append("silent special fallback still present")
    if 'return "special"' in (GODOT / "scripts" / "fighters" / "fighter_states.gd").read_text():
        failures.append("fighter_states still maps to generic special")

    train = (GODOT / "scripts" / "training" / "training_battle_scene.gd").read_text()
    for token in ["F11 freeze", "F12 step", "KEY_R", "KEY_1", "KEY_H", "training_impact_debug", "TrainingImpactLab"]:
        if token not in train:
            failures.append(f"training missing {token}")
    lab = GODOT / "scripts" / "training" / "training_impact_lab.gd"
    if not lab.exists():
        failures.append("missing Training Impact Lab script")
    else:
        lab_src = lab.read_text()
        for token in ["Hide HUD", "Replay Last Hit", "P1", "P2", "Tier", "Aura", "Freeze", "Step"]:
            if token not in lab_src:
                failures.append(f"impact lab missing {token}")

    a11y = (GODOT / "scripts" / "combat" / "combat_feedback.gd").read_text()
    if "_a11y_allows_camera" not in a11y or "warranted_camera" not in a11y:
        failures.append("a11y/camera warrant missing")
    juice = (GODOT / "scripts" / "juice" / "juice_event_bus.gd").read_text()
    if "EVENT_IMPACT_CLASS" not in juice or "can_reduce_flash" not in juice:
        failures.append("juice impact class / a11y reduce missing")

    return {
        "schema_ok": schema_ok and not any("impact profile" in f or "hitstop" in f for f in failures),
        "unique": not any("identical" in f or "roster identical" in f for f in failures),
        "not_static": not any("static" in f or "≈" in f or "variation" in f or "distinct" in f for f in failures),
        "fighters": list(FIGHTERS),
        "uniqueness": uniqueness,
        "failures": failures,
        "notes": notes,
        "ok": not failures,
    }


def main() -> int:
    result = validate()
    out = ROOT / "artifacts" / "vxp3" / "reports" / "VXP3_VALIDATE.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({k: result[k] for k in ("ok", "schema_ok", "unique", "not_static", "failures")}, indent=2))
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
