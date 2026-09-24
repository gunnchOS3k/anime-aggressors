#!/usr/bin/env python3
"""Author roster-wide Godot pose-to-pose combat clips + owned SFX.

Provenance: in-repo original choreography. Not final art. No third-party packs.
No root-motion translation keys — rotations (and optional presentation scale cheats) only.
Each fighter has a unique motion identity. Do not treat these as recolors.
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
FIGHTERS = (
    "ember-vale",
    "rook-ironside",
    "juno-spark",
    "kaia-windrow",
    "nix-calder",
    "orion-vell",
    "vesper-nyx",
)
BONES = [
    "Spine",
    "Chest",
    "UpperArm_R",
    "LowerArm_R",
    "Hand_R",
    "UpperArm_L",
    "LowerArm_L",
    "Hand_L",
    "UpperLeg_R",
    "LowerLeg_R",
    "UpperLeg_L",
    "LowerLeg_L",
]

# Visible amplitudes. Phase 1 idle_amp 0.018 was owner-invisible.
IDENTITY = {
    "ember-vale": {
        "lane": "flame",
        "element": "flame",
        "lean": 0.32,
        "tempo": 1.38,
        "plant": 0.05,
        "width": 0.16,
        "snap": 1.22,
        "follow": 0.88,
        "stiff": 0.28,
        "idle_amp": 0.24,
        "loco_amp": 0.78,
        "hurt_amp": 1.05,
        "asym": 0.10,
        "phase": 0.15,
        "y_bias": 0.08,
        "color": "rush_flame",
        "socket": "hand_r",
        "reaction": {"light": "flinch", "medium": "stagger", "heavy": "body_snap", "aura": "launch", "super": "launch", "ko": "ko_spin"},
    },
    "rook-ironside": {
        "lane": "impact",
        "element": "impact",
        "lean": -0.06,
        "tempo": 0.72,
        "plant": 0.18,
        "width": 0.34,
        "snap": 1.55,
        "follow": 1.42,
        "stiff": 0.42,
        "idle_amp": 0.20,
        "loco_amp": 0.58,
        "hurt_amp": 1.18,
        "asym": -0.04,
        "phase": 0.40,
        "y_bias": -0.04,
        "color": "planted_armor",
        "socket": "hand_r",
        "reaction": {"light": "flinch", "medium": "stagger", "heavy": "body_snap", "aura": "launch", "super": "launch", "ko": "ko_spin"},
    },
    "juno-spark": {
        "lane": "volt",
        "element": "volt",
        "lean": 0.10,
        "tempo": 1.62,
        "plant": 0.03,
        "width": 0.12,
        "snap": 1.70,
        "follow": 0.42,
        "stiff": 0.18,
        "idle_amp": 0.28,
        "loco_amp": 0.64,
        "hurt_amp": 0.92,
        "asym": 0.22,
        "phase": 1.10,
        "y_bias": 0.14,
        "color": "volt_snap",
        "socket": "hand_l",
        "reaction": {"light": "flinch", "medium": "stagger", "heavy": "stagger", "aura": "launch", "super": "launch", "ko": "ko_spin"},
    },
    "kaia-windrow": {
        "lane": "gale",
        "element": "gale",
        "lean": 0.18,
        "tempo": 1.08,
        "plant": 0.07,
        "width": 0.22,
        "snap": 0.95,
        "follow": 1.18,
        "stiff": 0.22,
        "idle_amp": 0.30,
        "loco_amp": 0.86,
        "hurt_amp": 0.88,
        "asym": 0.16,
        "phase": 0.70,
        "y_bias": 0.22,
        "color": "gale_line",
        "socket": "foot_r",
        "reaction": {"light": "flinch", "medium": "launch", "heavy": "launch", "aura": "tumble", "super": "tumble", "ko": "ko_spin"},
    },
    "nix-calder": {
        "lane": "frost",
        "element": "frost",
        "lean": 0.02,
        "tempo": 0.86,
        "plant": 0.04,
        "width": 0.10,
        "snap": 0.78,
        "follow": 0.40,
        "stiff": 0.88,
        "idle_amp": 0.16,
        "loco_amp": 0.48,
        "hurt_amp": 0.70,
        "asym": -0.12,
        "phase": 0.05,
        "y_bias": 0.02,
        "color": "frost_precision",
        "socket": "hand_l",
        "reaction": {"light": "flinch", "medium": "freeze_stiffness", "heavy": "freeze_stiffness", "aura": "launch", "super": "launch", "ko": "ko_spin"},
    },
    "orion-vell": {
        "lane": "gravity",
        "element": "gravity",
        "lean": -0.10,
        "tempo": 0.68,
        "plant": 0.14,
        "width": 0.26,
        "snap": 0.82,
        "follow": 1.05,
        "stiff": 0.55,
        "idle_amp": 0.18,
        "loco_amp": 0.44,
        "hurt_amp": 1.00,
        "asym": 0.06,
        "phase": 0.95,
        "y_bias": -0.16,
        "color": "orbital_sink",
        "socket": "chest",
        "reaction": {"light": "stagger", "medium": "crumple", "heavy": "crumple", "aura": "launch", "super": "launch", "ko": "ko_spin"},
    },
    "vesper-nyx": {
        "lane": "void",
        "element": "void",
        "lean": 0.14,
        "tempo": 1.20,
        "plant": 0.06,
        "width": 0.20,
        "snap": 1.35,
        "follow": 0.70,
        "stiff": 0.30,
        "idle_amp": 0.26,
        "loco_amp": 0.70,
        "hurt_amp": 1.12,
        "asym": 0.34,
        "phase": 1.55,
        "y_bias": 0.06,
        "color": "void_mix",
        "socket": "hand_r",
        "reaction": {"light": "flinch", "medium": "stagger", "heavy": "body_snap", "aura": "launch", "super": "launch", "ko": "ko_spin"},
    },
}

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
    "back_air": "medium",
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

CLIP_SPECS = {
    "idle": {"frames": 48, "kind": "idle"},
    "idle_personality": {"frames": 56, "kind": "idle_personality"},
    "walk": {"frames": 32, "kind": "walk"},
    "walk_start": {"frames": 10, "kind": "walk_start"},
    "walk_stop": {"frames": 10, "kind": "walk_stop"},
    "run": {"frames": 24, "kind": "run"},
    "run_start": {"frames": 8, "kind": "run_start"},
    "run_stop": {"frames": 10, "kind": "run_stop"},
    "dash": {"frames": 12, "kind": "dash"},
    "dash_stop": {"frames": 10, "kind": "dash_stop"},
    "turn": {"frames": 12, "kind": "turn"},
    "jump_squat": {"frames": 8, "kind": "jump_squat"},
    "jump": {"frames": 16, "kind": "jump"},
    "jump_apex": {"frames": 10, "kind": "jump_apex"},
    "fall": {"frames": 16, "kind": "fall"},
    "landing": {"frames": 12, "kind": "land"},
    "charged_idle": {"frames": 48, "kind": "charged_idle"},
    "charged_walk": {"frames": 32, "kind": "charged_walk"},
    "charged_run": {"frames": 24, "kind": "charged_run"},
    "charged_dash": {"frames": 12, "kind": "charged_dash"},
    "charged_jump": {"frames": 16, "kind": "charged_jump"},
    "charged_fall": {"frames": 16, "kind": "charged_fall"},
    "charged_land": {"frames": 12, "kind": "charged_land"},
    "charge_start": {"frames": 14, "kind": "charge_start"},
    "charge_low": {"frames": 24, "kind": "charge_low"},
    "charge_mid": {"frames": 24, "kind": "charge_mid"},
    "charge_high": {"frames": 24, "kind": "charge_high"},
    "charge_full": {"frames": 28, "kind": "charge_full"},
    "charge_release": {"frames": 16, "kind": "charge_release"},
    "aura_charge": {"frames": 36, "kind": "charge_mid"},
    "aura_release": {"frames": 18, "kind": "charge_release"},
    "charged_hold": {"frames": 24, "kind": "charge_high"},
    "uncharged_release": {"frames": 16, "kind": "charge_release"},
    "jab": {"frames": 14, "kind": "light"},
    "jab_chain_2": {"frames": 14, "kind": "light2"},
    "jab_chain_3": {"frames": 18, "kind": "medium"},
    "tilt_forward": {"frames": 18, "kind": "tilt_f"},
    "tilt_up": {"frames": 18, "kind": "tilt_u"},
    "tilt_down": {"frames": 18, "kind": "tilt_d"},
    "heavy": {"frames": 28, "kind": "heavy"},
    "super": {"frames": 36, "kind": "super"},
    "aerial_neutral": {"frames": 18, "kind": "nair"},
    "aerial_forward": {"frames": 18, "kind": "fair"},
    "aerial_back": {"frames": 18, "kind": "bair"},
    "aerial_up": {"frames": 18, "kind": "uair"},
    "aerial_down": {"frames": 18, "kind": "dair"},
    "air_dodge": {"frames": 16, "kind": "air_dodge"},
    "air_drift": {"frames": 20, "kind": "air_drift"},
    "dodge": {"frames": 16, "kind": "dodge"},
    "shield": {"frames": 20, "kind": "shield"},
    "grab": {"frames": 16, "kind": "grab"},
    "grab_victim": {"frames": 20, "kind": "grab_victim"},
    "throw_forward": {"frames": 20, "kind": "throw_f"},
    "throw_back": {"frames": 20, "kind": "throw_b"},
    "throw_up": {"frames": 20, "kind": "throw_u"},
    "throw_down": {"frames": 20, "kind": "throw_d"},
    "throw_victim_forward": {"frames": 22, "kind": "victim_f"},
    "throw_victim_back": {"frames": 22, "kind": "victim_b"},
    "throw_victim_up": {"frames": 22, "kind": "victim_u"},
    "throw_victim_down": {"frames": 22, "kind": "victim_d"},
    "projectile_tap": {"frames": 16, "kind": "proj_tap"},
    "projectile_medium": {"frames": 20, "kind": "proj_med"},
    "projectile_full": {"frames": 24, "kind": "proj_full"},
    "signature_lane_burst": {"frames": 26, "kind": "aura"},
    "signature_lane_confirm": {"frames": 24, "kind": "sig_confirm"},
    "signature_lane_control": {"frames": 24, "kind": "sig_control"},
    "signature_lane_counter": {"frames": 22, "kind": "sig_counter"},
    "signature_lane_feint": {"frames": 20, "kind": "sig_feint"},
    "signature_lane_finisher": {"frames": 28, "kind": "super"},
    "signature_lane_launch": {"frames": 24, "kind": "sig_launch"},
    "signature_lane_trap": {"frames": 24, "kind": "sig_trap"},
    "smash_forward": {"frames": 26, "kind": "heavy"},
    "smash_up": {"frames": 26, "kind": "tilt_u"},
    "smash_down": {"frames": 26, "kind": "tilt_d"},
    "hurt": {"frames": 18, "kind": "hurt_generic"},
    "hurt_light": {"frames": 14, "kind": "hurt_light"},
    "hurt_medium": {"frames": 18, "kind": "hurt_medium"},
    "hurt_heavy": {"frames": 24, "kind": "hurt_heavy"},
    "hurt_flinch": {"frames": 14, "kind": "hurt_light"},
    "hurt_stagger": {"frames": 20, "kind": "hurt_medium"},
    "hurt_crumple": {"frames": 26, "kind": "hurt_crumple"},
    "hurt_launch": {"frames": 28, "kind": "hurt_launch"},
    "hurt_tumble": {"frames": 32, "kind": "hurt_tumble"},
    "hurt_spike": {"frames": 22, "kind": "hurt_spike"},
    "hurt_freeze_stiffness": {"frames": 24, "kind": "hurt_freeze"},
    "hurt_body_snap": {"frames": 22, "kind": "hurt_snap"},
    "hurt_shield_recoil": {"frames": 14, "kind": "hurt_shield"},
    "hurt_ground_bounce": {"frames": 20, "kind": "hurt_bounce"},
    "hurt_wall_splat": {"frames": 18, "kind": "hurt_splat"},
    "hurt_ko_spin": {"frames": 36, "kind": "hurt_ko"},
    "launch": {"frames": 28, "kind": "hurt_launch"},
    "tumble": {"frames": 32, "kind": "hurt_tumble"},
    "ko": {"frames": 36, "kind": "hurt_ko"},
    "contact_light": {"frames": 10, "kind": "contact_light"},
    "contact_medium": {"frames": 12, "kind": "contact_medium"},
    "contact_heavy": {"frames": 14, "kind": "contact_heavy"},
    "contact_aura": {"frames": 16, "kind": "contact_aura"},
    "contact_super": {"frames": 18, "kind": "contact_super"},
    "contact_ko": {"frames": 20, "kind": "contact_ko"},
    "recovery": {"frames": 22, "kind": "recovery"},
    "recovery_identity": {"frames": 20, "kind": "recovery"},
    "transition_idle_walk": {"frames": 12, "kind": "walk_start"},
    "transition_walk_run": {"frames": 10, "kind": "run_start"},
    "victory": {"frames": 36, "kind": "victory"},
    "defeat": {"frames": 28, "kind": "defeat"},
}


def sha(obj) -> str:
    blob = json.dumps(obj, sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(blob).hexdigest()


def _r(x: float) -> float:
    return round(float(x), 5)


def _v(x: float, y: float, z: float) -> list[float]:
    return [_r(x), _r(y), _r(z)]


def _ident(fid: str) -> dict:
    return IDENTITY[fid]


def _mix(a: dict, b: dict, t: float) -> dict:
    out = {}
    bones = set(a) | set(b)
    for bone in bones:
        av = a.get(bone, [0.0, 0.0, 0.0])
        bv = b.get(bone, [0.0, 0.0, 0.0])
        out[bone] = _v(av[0] + (bv[0] - av[0]) * t, av[1] + (bv[1] - av[1]) * t, av[2] + (bv[2] - av[2]) * t)
    return out


def _base_rest(ident: dict) -> dict:
    lean = ident["lean"]
    width = ident["width"]
    plant = ident["plant"]
    asym = ident["asym"]
    return {
        "Spine": _v(lean * 0.35, asym * 0.15, plant * 0.4),
        "Chest": _v(lean * 0.25, asym * 0.2, 0.04),
        "UpperArm_R": _v(0.18 + lean * 0.1, -0.28 + width * 0.4, 0.12 + asym),
        "LowerArm_R": _v(0.22, -0.16, 0.06),
        "Hand_R": _v(0.08, -0.04, 0.10),
        "UpperArm_L": _v(0.16 + lean * 0.08, 0.26 - width * 0.3, -0.10 - asym * 0.5),
        "LowerArm_L": _v(0.20, 0.14, -0.05),
        "Hand_L": _v(0.06, 0.04, -0.08),
        "UpperLeg_R": _v(0.06 + plant * 0.3, 0.0, 0.10 + width * 0.5),
        "LowerLeg_R": _v(0.08, 0.0, 0.02),
        "UpperLeg_L": _v(0.05 + plant * 0.25, 0.0, -0.10 - width * 0.5),
        "LowerLeg_L": _v(0.07, 0.0, -0.02),
    }


def pose(fid: str, kind: str, t: float, frame: int, frames: int) -> dict:
    ident = _ident(fid)
    rest = _base_rest(ident)
    p = max(0.0, min(1.0, frame / max(1, frames - 1)))
    w = 2.0 * math.pi * (t * ident["tempo"] + ident["phase"])
    idle = ident["idle_amp"]
    loco = ident["loco_amp"]
    hurt = ident["hurt_amp"]
    snap = ident["snap"]
    follow = ident["follow"]
    stiff = ident["stiff"]
    lean = ident["lean"]
    plant = ident["plant"]
    width = ident["width"]
    asym = ident["asym"]
    yb = ident["y_bias"]
    lane = ident["lane"]

    def apply(delta: dict) -> dict:
        out = {b: list(rest[b]) for b in BONES}
        for bone, rot in delta.items():
            if bone not in out:
                continue
            out[bone] = _v(out[bone][0] + rot[0], out[bone][1] + rot[1], out[bone][2] + rot[2])
        return out

    # --- idle / personality ---
    if kind == "idle":
        breath = math.sin(w)
        sway = math.sin(w * 0.5 + ident["phase"])
        return apply(
            {
                "Spine": _v(idle * breath * 0.55 + lean * 0.08, yb * 0.2 * sway, plant * 0.15 * breath),
                "Chest": _v(idle * 0.7 * breath, 0.12 * sway + asym * 0.2, 0.04 * breath),
                "UpperArm_R": _v(idle * 0.35 * breath, -0.18 + 0.10 * sway, 0.08),
                "UpperArm_L": _v(idle * 0.30 * breath, 0.16 - 0.10 * sway, -0.08),
                "UpperLeg_R": _v(0.04 * breath, 0.0, 0.06 + width * 0.2 * abs(sway)),
                "UpperLeg_L": _v(0.05 * -breath, 0.0, -0.06 - width * 0.2 * abs(sway)),
            }
        )
    if kind == "idle_personality":
        # Unique silhouette gag per fighter, still a loop.
        gags = {
            "flame": apply({"Chest": _v(0.22, 0.18 * math.sin(w * 2), 0.1), "UpperArm_R": _v(-0.35, -0.85, 0.25), "Hand_R": _v(0.2, -0.4, 0.45)}),
            "impact": apply({"Spine": _v(0.12, 0.0, 0.22), "UpperArm_R": _v(0.45, -0.55, 0.4), "UpperArm_L": _v(0.45, 0.55, -0.4)}),
            "volt": apply({"Chest": _v(0.08 * math.copysign(1, math.sin(w * 4)), 0.35 * math.sin(w * 4), 0.0), "UpperArm_L": _v(-0.2, 0.9, -0.3)}),
            "gale": apply({"Spine": _v(-0.18, 0.28 * math.sin(w), 0.05), "Chest": _v(-0.12, 0.4 * math.sin(w), 0.1), "UpperArm_L": _v(0.3, 0.7, -0.45)}),
            "frost": apply({"Spine": _v(0.04, 0.0, 0.02), "Chest": _v(0.06, 0.0, 0.0), "UpperArm_L": _v(-0.15, 0.55, -0.2), "Hand_L": _v(0.1, 0.25, 0.35)}),
            "gravity": apply({"Spine": _v(0.28, 0.12 * math.sin(w * 0.5), -0.08), "Chest": _v(0.22, 0.0, 0.0), "UpperArm_R": _v(0.55, -0.2, 0.55)}),
            "void": apply({"Spine": _v(0.1, 0.42 * math.sin(w), 0.16), "Chest": _v(0.08, -0.35 * math.sin(w), 0.2), "UpperArm_R": _v(-0.4, -1.0, 0.5), "UpperArm_L": _v(0.5, 0.2, -0.6)}),
        }
        return gags[lane]

    # --- locomotion ---
    if kind in ("walk", "walk_start", "walk_stop", "charged_walk"):
        amp = max(0.72, loco) * (0.55 if kind == "walk_start" else 0.35 if kind == "walk_stop" else 1.0)
        cycle = 2.0 * math.pi * p
        s = math.sin(cycle)
        c = math.cos(cycle)
        charged = 0.42 if kind == "charged_walk" else 0.0
        return apply(
            {
                "Spine": _v(lean * 0.2 + charged, plant * 0.4 * s, 0.08 * c + charged * 0.15),
                "Chest": _v(0.08 + charged * 0.55, 0.28 * s, 0.06 * c),
                "UpperLeg_R": _v(amp * s, 0.0, 0.12 + width * 0.3 + charged * 0.12),
                "LowerLeg_R": _v(-amp * 0.75 * s + 0.15 * max(0, -s), 0.0, 0.04),
                "UpperLeg_L": _v(-amp * s, 0.0, -0.12 - width * 0.3 - charged * 0.12),
                "LowerLeg_L": _v(amp * 0.75 * s + 0.15 * max(0, s), 0.0, -0.04),
                "UpperArm_R": _v(0.12 + charged, -amp * 0.55 * s - charged * 0.35, 0.16 + charged * 0.2),
                "UpperArm_L": _v(0.12 + charged, amp * 0.55 * s + charged * 0.35, -0.16 - charged * 0.2),
            }
        )
    if kind in ("run", "run_start", "run_stop", "charged_run"):
        amp = max(0.95, loco * 1.45) * (0.6 if "start" in kind else 0.4 if "stop" in kind else 1.0)
        cycle = 2.0 * math.pi * p
        s = math.sin(cycle)
        c = math.cos(cycle)
        charged = 0.38 if kind == "charged_run" else 0.0
        return apply(
            {
                "Spine": _v(lean * 0.55 + 0.18 + charged, 0.10 * s, plant * 0.3),
                "Chest": _v(0.22 + charged, 0.28 * s, 0.08 * c),
                "UpperLeg_R": _v(amp * s, 0.0, 0.16),
                "LowerLeg_R": _v(-amp * 0.9 * s, 0.0, 0.05),
                "UpperLeg_L": _v(-amp * s, 0.0, -0.16),
                "LowerLeg_L": _v(amp * 0.9 * s, 0.0, -0.05),
                "UpperArm_R": _v(0.25, -amp * 0.7 * s, 0.22),
                "UpperArm_L": _v(0.25, amp * 0.7 * s, -0.22),
            }
        )
    if kind in ("dash", "dash_stop", "charged_dash"):
        surge = 0.95 if kind != "dash_stop" else 0.25
        charged = 0.2 if kind == "charged_dash" else 0.0
        return apply(
            {
                "Spine": _v(0.42 * surge + lean + charged, 0.18 * math.sin(w), plant),
                "Chest": _v(0.35 * surge, 0.12, 0.1),
                "UpperArm_R": _v(0.55, -0.85 * surge, 0.35),
                "UpperArm_L": _v(0.55, 0.85 * surge, -0.35),
                "UpperLeg_R": _v(0.55 * surge, 0.0, 0.18),
                "UpperLeg_L": _v(-0.15, 0.0, -0.10),
            }
        )
    if kind == "turn":
        return apply(
            {
                "Spine": _v(0.08, 0.85 * math.sin(p * math.pi), 0.12),
                "Chest": _v(0.06, 1.05 * math.sin(p * math.pi), 0.08),
                "UpperArm_R": _v(0.2, -0.4, 0.3),
                "UpperArm_L": _v(0.2, 0.4, -0.3),
            }
        )

    # --- jump family ---
    if kind == "jump_squat":
        return apply({"Spine": _v(0.45, 0.0, plant), "Chest": _v(0.28, 0.0, 0.0), "UpperLeg_R": _v(0.55, 0.0, 0.12), "UpperLeg_L": _v(0.52, 0.0, -0.12), "UpperArm_R": _v(0.35, 0.25, 0.15), "UpperArm_L": _v(0.35, -0.25, -0.15)})
    if kind in ("jump", "charged_jump"):
        lift = 0.2 if kind == "charged_jump" else 0.0
        return apply({"Spine": _v(-0.22 - lift, 0.0, 0.04), "Chest": _v(-0.18, 0.0, 0.0), "UpperArm_R": _v(-0.55, -0.35, 0.4), "UpperArm_L": _v(-0.55, 0.35, -0.4), "UpperLeg_R": _v(-0.15, 0.0, 0.08), "UpperLeg_L": _v(0.25, 0.0, -0.08)})
    if kind == "jump_apex":
        return apply({"Spine": _v(-0.08, 0.12, 0.0), "Chest": _v(-0.05, 0.18, 0.0), "UpperArm_R": _v(-0.25, -0.55, 0.25), "UpperArm_L": _v(-0.25, 0.55, -0.25)})
    if kind in ("fall", "charged_fall"):
        charged = 0.36 if kind == "charged_fall" else 0.0
        return apply({"Spine": _v(0.18 + charged, 0.0, charged * 0.1), "Chest": _v(0.12 + charged * 0.5, 0.0, 0.0), "UpperArm_R": _v(0.35, -0.45 - charged * 0.4, 0.2 + charged), "UpperArm_L": _v(0.35, 0.45 + charged * 0.4, -0.2 - charged), "UpperLeg_R": _v(0.28, 0.0, 0.1 + charged * 0.15), "UpperLeg_L": _v(0.12, 0.0, -0.08 - charged * 0.15)})
    if kind in ("land", "charged_land"):
        charged = 0.34 if kind == "charged_land" else 0.0
        return apply({"Spine": _v(0.38 + charged, 0.0, plant), "Chest": _v(0.22 + charged * 0.4, 0.0, 0.0), "UpperLeg_R": _v(0.42 + charged * 0.2, 0.0, 0.14 + charged * 0.12), "UpperLeg_L": _v(0.40 + charged * 0.2, 0.0, -0.14 - charged * 0.12), "UpperArm_R": _v(0.28, 0.2 + charged * 0.45, 0.12), "UpperArm_L": _v(0.28, -0.2 - charged * 0.45, -0.12)})

    # --- charge presence (each band changes pose, breath, silhouette) ---
    charge_bands = {
        "charge_start": 0.18,
        "charge_low": 0.32,
        "charge_mid": 0.52,
        "charge_high": 0.78,
        "charge_full": 1.05,
        "charged_idle": 0.62,
        "charge_release": 0.15,
    }
    if kind in charge_bands:
        k = charge_bands[kind]
        bloom = 0.22 if kind == "charge_full" else 0.0
        breath = math.sin(w * (1.2 + k))
        # Unique ready silhouette at 100.
        arms_up = -0.55 * k if lane != "impact" else 0.45 * k
        return apply(
            {
                "Spine": _v(lean * 0.2 + k * 0.18 + bloom * 0.12, asym * k * 0.4, plant + k * 0.12),
                "Chest": _v(k * 0.28 + breath * 0.08, 0.16 * breath, bloom * 0.1),
                "UpperArm_R": _v(arms_up, -0.35 - k * 0.55, 0.2 + k * 0.45),
                "LowerArm_R": _v(-0.15 * k, -0.25 * k, 0.12),
                "UpperArm_L": _v(arms_up, 0.35 + k * 0.55, -0.2 - k * 0.45),
                "LowerArm_L": _v(-0.15 * k, 0.25 * k, -0.12),
                "UpperLeg_R": _v(0.08 + k * 0.18, 0.0, 0.10 + width * k),
                "UpperLeg_L": _v(0.08 + k * 0.16, 0.0, -0.10 - width * k),
            }
        )

    # --- attacks: anticipation / smear / contact / follow / recovery ---
    attack_kinds = {
        "light": (0.55, 0.0, "jab"),
        "light2": (0.62, 0.18, "jab2"),
        "medium": (0.85, 0.12, "med"),
        "heavy": (1.25, 0.0, "heavy"),
        "aura": (1.40, 0.2, "aura"),
        "super": (1.65, 0.35, "super"),
        "tilt_f": (0.78, 0.0, "tf"),
        "tilt_u": (0.80, 0.0, "tu"),
        "tilt_d": (0.76, 0.0, "td"),
        "nair": (0.82, 0.0, "nair"),
        "fair": (0.88, 0.0, "fair"),
        "bair": (0.86, 0.0, "bair"),
        "uair": (0.84, 0.0, "uair"),
        "dair": (0.90, 0.0, "dair"),
        "proj_tap": (0.60, 0.0, "pt"),
        "proj_med": (0.78, 0.0, "pm"),
        "proj_full": (0.95, 0.0, "pf"),
        "sig_confirm": (1.15, 0.1, "sc"),
        "sig_control": (0.92, 0.15, "sctl"),
        "sig_counter": (1.05, 0.05, "scn"),
        "sig_feint": (0.70, 0.45, "sf"),
        "sig_launch": (1.20, 0.1, "sl"),
        "sig_trap": (0.88, 0.2, "st"),
        "contact_light": (0.70, 0.0, "cl"),
        "contact_medium": (0.95, 0.0, "cm"),
        "contact_heavy": (1.25, 0.0, "ch"),
        "contact_aura": (1.45, 0.15, "ca"),
        "contact_super": (1.65, 0.25, "cs"),
        "contact_ko": (1.85, 0.35, "ck"),
    }
    if kind in attack_kinds:
        power, feint, tag = attack_kinds[kind]
        # Four held anime poses.
        if p < 0.22:
            phase = "anticipation"
            q = p / 0.22
        elif p < 0.38:
            phase = "smear"
            q = (p - 0.22) / 0.16
        elif p < 0.55:
            phase = "contact"
            q = (p - 0.38) / 0.17
        elif p < 0.78:
            phase = "follow"
            q = (p - 0.55) / 0.23
        else:
            phase = "recovery"
            q = (p - 0.78) / 0.22
        coil = -0.85 * power * (1.0 if phase == "anticipation" else 0.15)
        smear = 1.15 * power if phase == "smear" else 0.0
        hit = 1.0 * power * snap if phase == "contact" else 0.0
        thru = 0.75 * power * follow if phase == "follow" else 0.0
        rec = 0.12 * power if phase == "recovery" else 0.0
        dir_y = {
            "tu": -0.85,
            "uair": -0.75,
            "td": 0.75,
            "dair": 0.85,
            "bair": 0.15,
            "tf": 0.05,
        }.get(tag, 0.0)
        side = -1.0 if tag == "bair" else 1.0
        if feint and phase == "anticipation":
            side *= -0.55
        arm = coil + smear * side + hit * side + thru * side + rec
        # Unique heavy / aura / super silhouettes per lane.
        extra_spine = 0.0
        extra_chest = 0.0
        if tag in ("heavy", "ch") and lane == "impact":
            extra_spine = 0.35
        if tag in ("aura", "ca") and lane == "frost":
            extra_chest = 0.28
        if tag in ("super", "cs", "ck"):
            extra_spine += 0.22 + ident["phase"] * 0.08
            extra_chest += 0.18
        return apply(
            {
                "Spine": _v(coil * 0.45 + hit * 0.25 + extra_spine + lean * 0.15, arm * 0.18 + dir_y * 0.2, plant + hit * 0.08),
                "Chest": _v(coil * 0.35 + hit * 0.4 + extra_chest, arm * 0.28 + dir_y * 0.35, 0.06 * side),
                "UpperArm_R": _v(-0.15 + coil * 0.3, -0.35 + arm * 0.95, 0.25 + hit * 0.35),
                "LowerArm_R": _v(-0.1, -0.2 + arm * 0.55, 0.12),
                "Hand_R": _v(0.12, -0.15 + arm * 0.35, 0.22 + smear * 0.2),
                "UpperArm_L": _v(0.2 + coil * 0.15, 0.45 - arm * 0.25, -0.18),
                "LowerArm_L": _v(0.12, 0.2, -0.08),
                "UpperLeg_R": _v(0.12 + hit * 0.18 + extra_spine * 0.3, 0.0, 0.14 * side + width * 0.2),
                "UpperLeg_L": _v(0.22 + (0.28 if phase == "anticipation" else 0.08), 0.0, -0.10 * side),
            }
        )

    # --- hurts: arm + torso + hip must all move ---
    if kind in ("hurt_light", "hurt_medium", "hurt_generic", "hurt_heavy", "hurt_crumple", "hurt_snap", "hurt_freeze", "hurt_shield", "hurt_bounce", "hurt_splat", "hurt_launch", "hurt_tumble", "hurt_spike", "hurt_ko"):
        scale = {
            "hurt_light": 0.42,
            "hurt_medium": 0.78,
            "hurt_generic": 0.64,
            "hurt_heavy": 1.15,
            "hurt_crumple": 1.25,
            "hurt_snap": 1.20,
            "hurt_freeze": 0.55,
            "hurt_shield": 0.38,
            "hurt_bounce": 0.95,
            "hurt_splat": 1.05,
            "hurt_launch": 1.35,
            "hurt_tumble": 1.45,
            "hurt_spike": 1.10,
            "hurt_ko": 1.70,
        }[kind]
        hold = 0.85 if kind == "hurt_freeze" and p < 0.35 else (0.0 if kind != "hurt_freeze" else 0.25)
        spin = 0.0
        if kind in ("hurt_tumble", "hurt_ko"):
            spin = p * (2.4 if kind == "hurt_ko" else 1.6)
        if kind == "hurt_launch":
            spin = p * 0.7
        down = 0.85 if kind == "hurt_spike" else (-0.65 if kind in ("hurt_launch", "hurt_ko") else 0.25 if kind == "hurt_bounce" else 0.0)
        if kind == "hurt_crumple":
            down = 0.55 + p * 0.35
        if kind == "hurt_splat":
            down = 0.15
            spin = 0.35
        settle = 1.0 if p < 0.28 else max(0.35, 1.15 - p)
        k = hurt * scale * settle
        # Nix freeze stays stiff; Rook snap yanks torso; Ember whips back; Kaia lofts; Orion sinks; Vesper dissolves-asymmetric.
        freeze = hold * stiff
        sink = 0.35 if lane == "gravity" else 0.0
        loft = -0.28 if lane == "gale" else 0.0
        whip = 0.22 if lane == "flame" else 0.0
        return apply(
            {
                "Spine": _v(-0.22 * k - freeze + down * 0.35 + sink - loft, 0.18 * k + spin * 0.35 + whip, plant + spin * 0.15),
                "Chest": _v(-0.32 * k + loft, 0.28 * k + spin * 0.45 + asym * 0.3, 0.08 + whip),
                "UpperArm_R": _v(0.55 * k + freeze * 0.2, 0.75 * k + spin * 0.5, 0.28 * k),
                "LowerArm_R": _v(0.25 * k, 0.35 * k, 0.12),
                "Hand_R": _v(0.1, 0.2 * k, 0.15),
                "UpperArm_L": _v(0.48 * k, -0.70 * k - spin * 0.4, -0.22 * k),
                "LowerArm_L": _v(0.22 * k, -0.28 * k, -0.10),
                "UpperLeg_R": _v(0.32 * k + down * 0.28 + 0.12 * settle, 0.12 * spin, 0.14 + width * 0.2),
                "UpperLeg_L": _v(0.38 * k + down * 0.30 + 0.10 * settle, -0.10 * spin, -0.12 - width * 0.2),
                "LowerLeg_R": _v(0.12 * k, 0.0, 0.04),
                "LowerLeg_L": _v(0.14 * k, 0.0, -0.04),
            }
        )

    if kind == "shield":
        return apply({"Spine": _v(0.16, 0.0, plant), "Chest": _v(0.22, 0.0, 0.0), "UpperArm_R": _v(-0.65, -0.55, 0.45), "UpperArm_L": _v(-0.65, 0.55, -0.45), "UpperLeg_R": _v(0.18, 0.0, 0.14), "UpperLeg_L": _v(0.18, 0.0, -0.14)})
    if kind in ("dodge", "air_dodge"):
        return apply({"Spine": _v(0.08, 0.55 * math.sin(p * math.pi), 0.1), "Chest": _v(0.05, 0.4, 0.0), "UpperArm_R": _v(0.4, -0.3, 0.2), "UpperArm_L": _v(0.4, 0.3, -0.2)})
    if kind == "air_drift":
        return apply({"Spine": _v(-0.08, 0.2 * math.sin(w), 0.0), "Chest": _v(-0.05, 0.15 * math.sin(w), 0.0), "UpperArm_R": _v(-0.2, -0.35, 0.2)})
    if kind == "grab":
        return apply({"Spine": _v(0.18, 0.0, plant), "Chest": _v(0.22, 0.0, 0.0), "UpperArm_R": _v(-0.15, -0.95, 0.35), "UpperArm_L": _v(-0.15, 0.95, -0.35)})
    if kind == "grab_victim":
        return apply({"Spine": _v(-0.12, 0.0, 0.0), "Chest": _v(-0.08, 0.0, 0.0), "UpperArm_R": _v(0.55, 0.45, 0.2), "UpperArm_L": _v(0.55, -0.45, -0.2)})
    if kind in ("throw_f", "throw_b", "throw_u", "throw_d"):
        dir_map = {"throw_f": (0.15, 0.9), "throw_b": (0.1, -1.0), "throw_u": (-0.7, 0.2), "throw_d": (0.7, 0.15)}
        dx, dy = dir_map[kind]
        return apply({"Spine": _v(dx, dy * 0.35, plant), "Chest": _v(dx * 0.8, dy * 0.5, 0.0), "UpperArm_R": _v(-0.2 + dx, -0.8 + dy, 0.3), "UpperArm_L": _v(0.15, 0.4, -0.2)})
    if kind in ("victim_f", "victim_b", "victim_u", "victim_d"):
        dir_map = {"victim_f": (0.35, 0.8), "victim_b": (0.25, -0.9), "victim_u": (-0.85, 0.2), "victim_d": (0.9, 0.1)}
        dx, dy = dir_map[kind]
        return apply({"Spine": _v(dx, dy * 0.4, 0.1), "Chest": _v(dx * 0.7, dy * 0.55, 0.0), "UpperArm_R": _v(0.6, 0.7, 0.3), "UpperArm_L": _v(0.55, -0.6, -0.25), "UpperLeg_R": _v(0.35, 0.2, 0.1), "UpperLeg_L": _v(0.3, -0.15, -0.08)})
    if kind == "recovery":
        return apply({"Spine": _v(-0.12 + lean * 0.1, 0.08 * math.sin(w), 0.04), "Chest": _v(-0.08, 0.1, 0.0), "UpperArm_R": _v(-0.45, -0.55, 0.35), "UpperArm_L": _v(-0.25, 0.35, -0.2)})
    if kind == "victory":
        return apply({"Spine": _v(-0.12, 0.15 * math.sin(w), 0.08), "Chest": _v(-0.08, 0.2, 0.0), "UpperArm_R": _v(-0.85, -0.35, 0.55), "UpperArm_L": _v(-0.4, 0.55, -0.25)})
    if kind == "defeat":
        return apply({"Spine": _v(0.42, 0.12, plant), "Chest": _v(0.28, 0.08, 0.0), "UpperArm_R": _v(0.35, 0.25, 0.1), "UpperArm_L": _v(0.35, -0.2, -0.1)})
    return pose(fid, "idle", t, frame, frames)


def keys_for(fid: str, kind: str, frames: int) -> dict:
    fps = 60.0
    # Stepped anime holds, not mocap-smooth. Always >= 4 distinct samples.
    if kind in ("walk", "run", "charged_walk", "charged_run"):
        samples = [0, max(1, frames // 4), max(2, frames // 2), max(3, (3 * frames) // 4)]
    elif kind in ("idle", "charged_idle", "idle_personality"):
        samples = [0, max(1, frames // 4), max(2, frames // 2), max(3, (3 * frames) // 4), frames - 1]
    elif kind in ("heavy", "aura", "super", "contact_heavy", "contact_aura", "contact_super", "contact_ko"):
        samples = [0, max(2, frames // 5), max(4, frames // 3), max(6, frames // 2), max(8, (2 * frames) // 3), frames - 1]
    else:
        samples = [0, max(1, frames // 5), max(2, frames // 3), max(3, (2 * frames) // 3), frames - 1]
    tracks = {b: [] for b in BONES}
    for fr in samples:
        t = fr / fps
        p = pose(fid, kind, t, fr, frames)
        for bone in BONES:
            tracks[bone].append({"frame": fr, "time_s": round(fr / fps, 4), "rotation_rad": p.get(bone, [0.0, 0.0, 0.0])})
    return tracks


def write_clip(fid: str, name: str, frames: int, kind: str) -> dict:
    ident = _ident(fid)
    tracks = keys_for(fid, kind, frames)
    events = [
        {"frame": 0, "event_type": "anticipation_start", "payload": {"pose": ident["color"], "fighter": fid, "clip": name}},
        {"frame": max(1, frames // 5), "event_type": "smear", "payload": {"lane": ident["lane"]}},
        {"frame": max(2, frames // 3), "event_type": "active_start", "payload": {"contact": name, "root": "none"}},
        {"frame": max(3, frames // 2), "event_type": "hitbox_on", "payload": {"socket": ident["socket"], "lane": ident["lane"]}},
        {"frame": max(4, (2 * frames) // 3), "event_type": "hitbox_off", "payload": {"vfx": ident["lane"]}},
        {"frame": max(5, frames - 3), "event_type": "recovery_start", "payload": {"follow": ident["color"]}},
    ]
    if kind in ("heavy", "aura", "super"):
        events.append({"frame": max(2, frames // 3), "event_type": "contact_pose", "payload": {"tier": kind}})
        events.append({"frame": max(3, frames // 2), "event_type": "follow_through", "payload": {"tier": kind}})
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
            "ground_coupling": ident["color"],
            "vxp3_identity": ident["color"],
        },
        "events": events,
        "provenance": {
            "author": "vxp3-roster-wide-generator",
            "license": "owned_in_repo",
            "third_party": False,
            "final_art_claim": False,
        },
    }
    data["curve_signature"] = sha(tracks)
    return data


def annotate_moves(fid: str) -> None:
    path = GODOT / "data" / "moves" / f"{fid}.json"
    doc = json.loads(path.read_text())
    ident = _ident(fid)
    reactions = ident["reaction"]
    for move in doc.get("moves", []):
        mid = str(move.get("move_id", ""))
        if mid == "special":
            raise SystemExit(f"refusing generic special on {fid}")
        tier = TIER_BY_MOVE.get(mid, str(move.get("feedback", {}).get("tier", "medium")))
        if tier not in ("light", "medium", "heavy", "aura", "super", "ko"):
            tier = "medium"
        startup = int(move.get("startup_frames", 4))
        active = int(move.get("active_frames", 3))
        contact = startup + max(0, active // 2)
        socket = ident["socket"]
        if "air" in mid or "down" in mid:
            socket = "foot_r" if ident["lane"] in ("impact", "gale") else ident["socket"]
        move["impact_profile"] = tier
        move["choreography"] = {
            "contact_socket": socket,
            "contact_frame": contact,
            "contact_pose_clip": f"contact_{tier if tier != 'super' else 'super'}",
            "victim_reaction_family": reactions.get(tier, "flinch"),
            "charged_layer": "hold" if mid == "aura_charge" else ("release" if mid == "aura_burst" else "none"),
            "cinematic_hook": "warranted_heavy" if tier in ("heavy", "aura", "super", "ko") else "",
            "identity": ident["color"],
        }
        move["anime_timing"] = {
            "anticipation_holds": 3 if ident["stiff"] > 0.6 else 2,
            "impact_accent_frames": 2 if ident["tempo"] > 1.2 else 3,
            "recovery_settle": 4 if ident["follow"] < 0.8 else 5,
            "pose_to_pose": True,
        }
    path.write_text(json.dumps(doc, indent=2) + "\n")


def write_wav(path: Path, freq: float, dur: float, amp: float = 0.22, overtone: float = 0.0) -> None:
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
            wave_s = math.sin(2 * math.pi * freq * t)
            if overtone:
                wave_s += 0.35 * math.sin(2 * math.pi * freq * overtone * t)
            sample = int(max(-1.0, min(1.0, wave_s * env * amp)) * 32767)
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
        + "\n"
    )


def generate_audio() -> list[str]:
    specs = {
        "flame": (220, 0.11, 2.0),
        "impact": (90, 0.14, 0.5),
        "volt": (1480, 0.08, 1.5),
        "gale": (440, 0.10, 1.25),
        "frost": (1760, 0.09, 1.15),
        "gravity": (70, 0.16, 0.5),
        "void": (130, 0.13, 0.75),
    }
    tiers = {"light": 0.7, "medium": 1.0, "heavy": 1.25, "aura": 1.4, "super": 1.55, "ko": 1.7}
    written = []
    out_dir = GODOT / "assets" / "audio" / "procedural" / "impact"
    for element, (freq, dur, over) in specs.items():
        for tier, mul in tiers.items():
            p = out_dir / f"{element}_{tier}.wav"
            write_wav(p, freq * (0.82 if tier in ("heavy", "ko") else 1.0), dur * mul, 0.18 * mul, over)
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
                "signature_clip_count": sum(1 for c in clips if c["clip_name"].startswith("signature_")),
                "clips": clips,
                "status": "PROCEDURAL_RUNTIME_ANIMATION",
                "vxp3_phase": 2,
                "not_final_art": True,
                "production_status": "GODOT_AUTHORED_POSE_TO_POSE_PLACEHOLDER",
            },
            indent=2,
        )
        + "\n"
    )


def write_hurt_library() -> None:
    families = {
        "flinch": {"gameplay_state": "hurt_light", "clip": "hurt_flinch", "legacy_clip": "hurt", "percent_hint": [0, 40], "kb_hint": [0, 8]},
        "stagger": {"gameplay_state": "hurt_heavy", "clip": "hurt_stagger", "legacy_clip": "hurt", "percent_hint": [20, 80], "kb_hint": [6, 14]},
        "crumple": {"gameplay_state": "hurt_heavy", "clip": "hurt_crumple", "legacy_clip": "hurt", "percent_hint": [50, 999], "kb_hint": [4, 12]},
        "launch": {"gameplay_state": "launched", "clip": "hurt_launch", "legacy_clip": "launch", "percent_hint": [0, 999], "kb_hint": [14, 999]},
        "tumble": {"gameplay_state": "tumble", "clip": "hurt_tumble", "legacy_clip": "tumble", "percent_hint": [60, 999], "kb_hint": [12, 999]},
        "spike": {"gameplay_state": "launched", "clip": "hurt_spike", "legacy_clip": "launch", "percent_hint": [0, 999], "angle_hint": "down"},
        "freeze_stiffness": {"gameplay_state": "hurt_heavy", "clip": "hurt_freeze_stiffness", "legacy_clip": "hurt", "identity_owner": "nix-calder"},
        "body_snap": {"gameplay_state": "hurt_heavy", "clip": "hurt_body_snap", "legacy_clip": "hurt", "identity_owner": "rook-ironside"},
        "shield_recoil": {"gameplay_state": "shield_stun", "clip": "hurt_shield_recoil", "legacy_clip": "shield"},
        "ground_bounce": {"gameplay_state": "tumble", "clip": "hurt_ground_bounce", "legacy_clip": "tumble"},
        "wall_splat": {"gameplay_state": "hurt_heavy", "clip": "hurt_wall_splat", "legacy_clip": "hurt"},
        "ko_spin": {"gameplay_state": "ko", "clip": "hurt_ko_spin", "legacy_clip": "ko"},
    }
    overrides = {}
    table = {k: v["clip"] for k, v in families.items()}
    for fid in FIGHTERS:
        overrides[fid] = dict(table)
    doc = {
        "schema_id": "anime_aggressors.hurt_reaction_library.v1",
        "schema_version": 2,
        "phase": 2,
        "slice_fighters": list(FIGHTERS),
        "extensible_roster": list(FIGHTERS),
        "families": families,
        "minimum_families": list(families),
        "fighter_clip_overrides": overrides,
        "architecture_note": "Roster-wide authored reaction clips. Procedural placeholders, not final art.",
    }
    dest = GODOT / "data" / "combat" / "hurt_reaction_library.json"
    dest.write_text(json.dumps(doc, indent=2) + "\n")


def write_sfx_palettes() -> None:
    elements = {}
    mapping = {
        "flame": "ember-vale",
        "impact": "rook-ironside",
        "volt": "juno-spark",
        "gale": "kaia-windrow",
        "frost": "nix-calder",
        "gravity": "orion-vell",
        "void": "vesper-nyx",
    }
    for element, fid in mapping.items():
        elements[element] = {
            "fighter_hint": fid,
            "palette": {tier: f"res://assets/audio/procedural/impact/{element}_{tier}.wav" for tier in ("light", "medium", "heavy", "aura", "super", "ko")},
        }
    doc = {
        "schema_id": "anime_aggressors.element_sfx_palette.v1",
        "schema_version": 2,
        "license": "owned_procedural_placeholders",
        "third_party_packs": [],
        "elements": elements,
        "fallback_owned": "res://assets/audio/procedural/shared/hit.wav",
        "notes": "Placeholders synthesized in-repo. Not third-party packs. Not claimed as final mix.",
    }
    (GODOT / "data" / "combat" / "element_sfx_palettes.json").write_text(json.dumps(doc, indent=2) + "\n")


def write_vfx_palettes() -> None:
    palettes = {
        "ember-vale": {"element": "flame", "color": [1.0, 0.38, 0.08, 1.0], "shape": "slash_arc", "particle_life": 0.12, "max_particles": 6, "orient": "attack"},
        "rook-ironside": {"element": "impact", "color": [0.92, 0.72, 0.18, 1.0], "shape": "ring_shock", "particle_life": 0.16, "max_particles": 5, "orient": "normal"},
        "juno-spark": {"element": "volt", "color": [0.98, 0.95, 0.25, 1.0], "shape": "bolt_jag", "particle_life": 0.08, "max_particles": 7, "orient": "attack"},
        "kaia-windrow": {"element": "gale", "color": [0.35, 0.88, 0.55, 1.0], "shape": "ribbon", "particle_life": 0.14, "max_particles": 6, "orient": "carry"},
        "nix-calder": {"element": "frost", "color": [0.45, 0.75, 1.0, 1.0], "shape": "crystal", "particle_life": 0.11, "max_particles": 5, "orient": "normal"},
        "orion-vell": {"element": "gravity", "color": [0.52, 0.38, 0.85, 1.0], "shape": "orbit_ring", "particle_life": 0.15, "max_particles": 5, "orient": "inward"},
        "vesper-nyx": {"element": "void", "color": [0.55, 0.18, 0.78, 1.0], "shape": "fold_slash", "particle_life": 0.10, "max_particles": 6, "orient": "feint"},
    }
    doc = {
        "schema_id": "anime_aggressors.element_vfx_palette.v1",
        "schema_version": 1,
        "not_final_art": True,
        "a11y_respects_reduce_flash": True,
        "spawn_at": "true_contact_socket",
        "fighters": palettes,
        "tier_scale": {"light": 0.7, "medium": 1.0, "heavy": 1.45, "aura": 1.7, "super": 2.0, "ko": 2.4},
    }
    (GODOT / "data" / "combat" / "element_vfx_palettes.json").write_text(json.dumps(doc, indent=2) + "\n")


def main() -> None:
    created = []
    for fid in FIGHTERS:
        anim_dir = GODOT / "content" / "fighters" / fid / "animations" / "procedural"
        anim_dir.mkdir(parents=True, exist_ok=True)
        for name, spec in CLIP_SPECS.items():
            data = write_clip(fid, name, spec["frames"], spec["kind"])
            dest = anim_dir / f"{name}.anim.json"
            dest.write_text(json.dumps(data, indent=2) + "\n")
            created.append(str(dest.relative_to(ROOT)))
        annotate_moves(fid)
        refresh_manifest(fid, anim_dir)
        mirror = ROOT / "content" / "fighters" / fid / "animations" / "procedural"
        mirror.mkdir(parents=True, exist_ok=True)
        for name in CLIP_SPECS:
            src = anim_dir / f"{name}.anim.json"
            (mirror / src.name).write_text(src.read_text())
        (mirror / "manifest.json").write_text((anim_dir / "manifest.json").read_text())
    write_hurt_library()
    write_sfx_palettes()
    write_vfx_palettes()
    wavs = generate_audio()
    prov = {
        "program": "VXP-3",
        "phase": 2,
        "scope": "roster_wide",
        "not_final_art": True,
        "third_party_packs": [],
        "launcher_icon_used_as_brand": False,
        "fighters": list(FIGHTERS),
        "clips_per_fighter": len(CLIP_SPECS),
        "assets": created + wavs,
        "method": "Godot-authored pose-to-pose JSON + owned sine placeholders",
        "physics": "no root motion; CombatMath / knockback / stock rules unchanged",
    }
    out = ROOT / "artifacts" / "vxp3" / "provenance" / "ASSETS.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(prov, indent=2) + "\n")
    print(json.dumps({"fighters": len(FIGHTERS), "clips_each": len(CLIP_SPECS), "wavs": len(wavs)}, indent=2))


if __name__ == "__main__":
    main()
