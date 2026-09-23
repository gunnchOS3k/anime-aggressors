"""Complete generated production action catalog. Gameplay IDs stay stable."""
from __future__ import annotations

from .common import WAVE_A

# Existing runtime clips that must have generated production replacements.
GAMEPLAY_CLIPS = (
    "idle",
    "walk",
    "run",
    "dash",
    "jump",
    "fall",
    "landing",
    "dodge",
    "air_dodge",
    "air_drift",
    "jab",
    "jab_chain_2",
    "jab_chain_3",
    "tilt_forward",
    "tilt_up",
    "tilt_down",
    "heavy",
    "smash_forward",
    "smash_up",
    "smash_down",
    "aerial_neutral",
    "aerial_forward",
    "aerial_back",
    "aerial_up",
    "aerial_down",
    "projectile_tap",
    "projectile_medium",
    "projectile_full",
    "signature_lane_burst",
    "signature_lane_confirm",
    "signature_lane_control",
    "signature_lane_counter",
    "signature_lane_feint",
    "signature_lane_finisher",
    "signature_lane_launch",
    "signature_lane_trap",
    "aura_charge",
    "aura_release",
    "grab",
    "throw_forward",
    "throw_back",
    "throw_up",
    "throw_down",
    "shield",
    "recovery",
    "hurt",
    "launch",
    "tumble",
    "ko",
    "victory",
    "defeat",
)

LOCOMOTION_EXTRA = (
    "personality_idle",
    "walk_start",
    "walk_stop",
    "run_start",
    "run_stop",
    "dash_stop",
    "turn",
    "crouch",
    "jump_squat",
    "double_jump",
    "jump_apex",
    "fast_fall",
    "land_soft",
    "land_hard",
)

CHARGE_EXTRA = (
    "charge_start",
    "charge_low",
    "charge_mid",
    "charge_high",
    "charge_full",
    "charge_release",
    "charged_idle",
    "charged_walk",
    "charged_run",
    "charged_dash",
    "charged_jump",
    "charged_fall",
    "charged_land",
)

HURT_EXTRA = (
    "hurt_light",
    "hurt_light_high",
    "hurt_light_mid",
    "hurt_light_low",
    "hurt_medium_front",
    "hurt_medium_back",
    "hurt_heavy",
    "hurt_heavy_front",
    "hurt_heavy_back",
    "hurt_launch_up",
    "hurt_launch_diagonal",
    "hurt_launch_horizontal",
    "hurt_flinch",
    "hurt_stagger",
    "hurt_crumple",
    "ground_bounce",
    "wall_splat",
    "shield_hit_light",
    "shield_hit_heavy",
    "grabbed_hold",
    "throw_victim_forward",
    "throw_victim_back",
    "throw_victim_up",
    "throw_victim_down",
    "ko_launch",
)

CLASH_EXTRA = (
    "clash_start",
    "clash_lock",
    "clash_push",
    "clash_winning",
    "clash_losing",
    "clash_break",
)

SUPER_EXTRA = (
    "aura_signature",
    "aura_burst_super_pose",
    "ko_reaction",
    "launch_tumble",
)


def all_actions() -> tuple[str, ...]:
    seen: list[str] = []
    for group in (
        GAMEPLAY_CLIPS,
        LOCOMOTION_EXTRA,
        CHARGE_EXTRA,
        HURT_EXTRA,
        CLASH_EXTRA,
        SUPER_EXTRA,
        WAVE_A,
    ):
        for name in group:
            if name not in seen:
                seen.append(name)
    return tuple(seen)


LOOPING = {
    "idle",
    "personality_idle",
    "walk",
    "run",
    "charged_idle",
    "charged_walk",
    "charged_run",
    "charge_low",
    "charge_mid",
    "charge_high",
    "charge_full",
    "fall",
    "fast_fall",
    "shield",
    "aura_charge",
    "crouch",
    "grabbed_hold",
}

DURATIONS = {
    "idle": 48,
    "personality_idle": 56,
    "walk": 32,
    "run": 24,
    "dash": 16,
    "jump": 20,
    "fall": 24,
    "landing": 16,
    "heavy": 30,
    "hurt_heavy": 24,
    "hurt": 18,
    "launch": 24,
    "tumble": 28,
    "ko": 36,
    "signature_lane_burst": 40,
    "signature_lane_finisher": 44,
    "aura_charge": 36,
    "charge_full": 32,
    "charged_idle": 48,
    "clash_lock": 28,
}


def duration_for(action: str) -> int:
    if action in DURATIONS:
        return DURATIONS[action]
    if action.startswith("charge"):
        return 28
    if action.startswith("charged_"):
        return 32
    if action.startswith("hurt") or action.startswith("throw_victim"):
        return 22
    if action.startswith("clash"):
        return 24
    if action.startswith("jab") or action.startswith("tilt"):
        return 18
    if action.startswith("aerial"):
        return 20
    if action.startswith("signature"):
        return 36
    if action.startswith("projectile"):
        return 20
    if action.startswith("smash"):
        return 28
    if action.startswith("throw_"):
        return 22
    return 24


def family(action: str) -> str:
    if action in WAVE_A:
        return "wave_a"
    if action in LOCOMOTION_EXTRA or action in {
        "idle",
        "walk",
        "run",
        "dash",
        "jump",
        "fall",
        "landing",
        "dodge",
        "air_dodge",
        "air_drift",
        "crouch",
    }:
        return "locomotion"
    if action.startswith("charge") or action.startswith("charged") or action in {"aura_charge"}:
        return "charge"
    if action.startswith("hurt") or action in {
        "launch",
        "tumble",
        "ko",
        "ground_bounce",
        "wall_splat",
        "grabbed_hold",
        "ko_launch",
        "ko_reaction",
        "launch_tumble",
    } or action.startswith("throw_victim") or action.startswith("shield_hit"):
        return "hurt"
    if action.startswith("clash"):
        return "clash"
    if action.startswith("signature") or action in {
        "aura_signature",
        "aura_burst_super_pose",
        "aura_release",
        "victory",
        "defeat",
    }:
        return "super"
    return "combat"
