extends Resource
class_name FighterAnimationLibrary

@export var animations: Dictionary = {}

func _init() -> void:
	if animations.is_empty():
		animations = _build_default_animations()

func has_animation(animation_name: StringName) -> bool:
	return animations.has(String(animation_name))

func get_keyframes(animation_name: StringName) -> Array:
	return animations.get(String(animation_name), [])

func sample_pose(animation_name: StringName, time_seconds: float) -> Dictionary:
	var keys: Array = get_keyframes(animation_name)
	if keys.is_empty():
		return {}
	if keys.size() == 1:
		return keys[0]["pose"].duplicate(true)

	var duration := float(keys[keys.size() - 1]["t"])
	var local_time := time_seconds
	if duration > 0.0:
		local_time = fposmod(time_seconds, duration)

	var previous: Dictionary = keys[0]
	var next: Dictionary = keys[keys.size() - 1]
	for i in range(keys.size() - 1):
		var a: Dictionary = keys[i]
		var b: Dictionary = keys[i + 1]
		if local_time >= float(a["t"]) and local_time <= float(b["t"]):
			previous = a
			next = b
			break

	var span := maxf(0.001, float(next["t"]) - float(previous["t"]))
	var blend := clampf((local_time - float(previous["t"])) / span, 0.0, 1.0)
	return _blend_poses(previous["pose"], next["pose"], blend)

func _blend_poses(a: Dictionary, b: Dictionary, blend: float) -> Dictionary:
	var result: Dictionary = {}
	for limb_name in a.keys():
		var va: Dictionary = a[limb_name]
		var vb: Dictionary = b.get(limb_name, va)
		var out := {}
		if va.has("position"):
			out["position"] = va["position"].lerp(vb.get("position", va["position"]), blend)
		if va.has("rotation"):
			out["rotation"] = lerp_angle(float(va["rotation"]), float(vb.get("rotation", va["rotation"])), blend)
		if va.has("scale"):
			out["scale"] = va["scale"].lerp(vb.get("scale", va["scale"]), blend)
		result[limb_name] = out
	return result

func _build_default_animations() -> Dictionary:
	return {
		"idle": [
			{"t": 0.0, "pose": _pose_idle_a()},
			{"t": 0.45, "pose": _pose_idle_b()},
			{"t": 0.90, "pose": _pose_idle_a()}
		],
		"walk": [
			{"t": 0.0, "pose": _pose_walk_a()},
			{"t": 0.20, "pose": _pose_walk_b()},
			{"t": 0.40, "pose": _pose_walk_a()}
		],
		"run": [
			{"t": 0.0, "pose": _pose_run_a()},
			{"t": 0.14, "pose": _pose_run_b()},
			{"t": 0.28, "pose": _pose_run_a()}
		],
		"dash": [{"t": 0.0, "pose": _pose_dash()}],
		"jump": [{"t": 0.0, "pose": _pose_jump()}],
		"double_jump": [{"t": 0.0, "pose": _pose_double_jump()}],
		"fall": [{"t": 0.0, "pose": _pose_fall()}],
		"fast_fall": [{"t": 0.0, "pose": _pose_fast_fall()}],
		"land": [{"t": 0.0, "pose": _pose_land()}],
		"attack_startup": [{"t": 0.0, "pose": _pose_attack_startup()}],
		"attack_active": [{"t": 0.0, "pose": _pose_attack_active()}],
		"attack_recovery": [{"t": 0.0, "pose": _pose_attack_recovery()}],
		"special_startup": [{"t": 0.0, "pose": _pose_special_startup()}],
		"special_active": [{"t": 0.0, "pose": _pose_special_active()}],
		"special_recovery": [{"t": 0.0, "pose": _pose_special_recovery()}],
		"aura_charge": [
			{"t": 0.0, "pose": _pose_aura_charge_a()},
			{"t": 0.20, "pose": _pose_aura_charge_b()},
			{"t": 0.40, "pose": _pose_aura_charge_a()}
		],
		"hitstun": [{"t": 0.0, "pose": _pose_hitstun()}],
		"launched": [{"t": 0.0, "pose": _pose_launched()}],
		"shield": [{"t": 0.0, "pose": _pose_shield()}],
		"dodge": [{"t": 0.0, "pose": _pose_dodge()}],
		"ko": [{"t": 0.0, "pose": _pose_ko()}],
		"victory": [{"t": 0.0, "pose": _pose_victory()}],
		"defeat": [{"t": 0.0, "pose": _pose_defeat()}],
		"hitstop": [{"t": 0.0, "pose": _pose_hitstun()}],
		"tumble": [{"t": 0.0, "pose": _pose_launched()}]
	}

func _pose_idle_a() -> Dictionary:
	return {
		"hips": {"position": Vector2(0, 0), "rotation": 0.0},
		"torso": {"position": Vector2(0, -14), "rotation": -0.02},
		"head": {"position": Vector2(0, -30), "rotation": 0.03},
		"left_arm": {"rotation": -0.18},
		"right_arm": {"rotation": 0.16},
		"left_leg": {"rotation": 0.08},
		"right_leg": {"rotation": -0.06},
		"left_foot": {"rotation": 0.04},
		"right_foot": {"rotation": -0.03},
		"element_aura": {"scale": Vector2(1.0, 1.0)}
	}

func _pose_idle_b() -> Dictionary:
	return {
		"hips": {"position": Vector2(0, 1), "rotation": 0.0},
		"torso": {"position": Vector2(0, -13), "rotation": 0.02},
		"head": {"position": Vector2(0, -29), "rotation": -0.02},
		"left_arm": {"rotation": -0.10},
		"right_arm": {"rotation": 0.10},
		"left_leg": {"rotation": 0.02},
		"right_leg": {"rotation": -0.02},
		"left_foot": {"rotation": 0.02},
		"right_foot": {"rotation": -0.02},
		"element_aura": {"scale": Vector2(1.04, 1.04)}
	}

func _pose_walk_a() -> Dictionary:
	return {
		"hips": {"position": Vector2(0, 1), "rotation": 0.04},
		"torso": {"rotation": -0.05},
		"head": {"rotation": 0.05},
		"left_arm": {"rotation": -0.50},
		"right_arm": {"rotation": 0.42},
		"left_leg": {"rotation": 0.48},
		"right_leg": {"rotation": -0.40},
		"left_foot": {"rotation": 0.22},
		"right_foot": {"rotation": -0.20}
	}

func _pose_walk_b() -> Dictionary:
	return {
		"hips": {"position": Vector2(0, 1), "rotation": -0.04},
		"torso": {"rotation": 0.05},
		"head": {"rotation": -0.05},
		"left_arm": {"rotation": 0.42},
		"right_arm": {"rotation": -0.50},
		"left_leg": {"rotation": -0.40},
		"right_leg": {"rotation": 0.48},
		"left_foot": {"rotation": -0.20},
		"right_foot": {"rotation": 0.22}
	}

func _pose_run_a() -> Dictionary:
	return {
		"hips": {"position": Vector2(0, 2), "rotation": 0.08},
		"torso": {"rotation": -0.10},
		"head": {"rotation": 0.08},
		"left_arm": {"rotation": -0.90},
		"right_arm": {"rotation": 0.72},
		"left_leg": {"rotation": 0.90},
		"right_leg": {"rotation": -0.72},
		"left_foot": {"rotation": 0.30},
		"right_foot": {"rotation": -0.28}
	}

func _pose_run_b() -> Dictionary:
	return {
		"hips": {"position": Vector2(0, 2), "rotation": -0.08},
		"torso": {"rotation": 0.10},
		"head": {"rotation": -0.08},
		"left_arm": {"rotation": 0.72},
		"right_arm": {"rotation": -0.90},
		"left_leg": {"rotation": -0.72},
		"right_leg": {"rotation": 0.90},
		"left_foot": {"rotation": -0.28},
		"right_foot": {"rotation": 0.30}
	}

func _pose_dash() -> Dictionary:
	return {
		"hips": {"rotation": -0.12},
		"torso": {"rotation": -0.18},
		"head": {"rotation": 0.20},
		"left_arm": {"rotation": -0.20},
		"right_arm": {"rotation": 0.25},
		"left_leg": {"rotation": 0.35},
		"right_leg": {"rotation": -0.32}
	}

func _pose_jump() -> Dictionary:
	return {
		"hips": {"position": Vector2(0, -1), "rotation": 0.0},
		"torso": {"rotation": 0.08},
		"head": {"rotation": -0.05},
		"left_arm": {"rotation": -0.50},
		"right_arm": {"rotation": 0.50},
		"left_leg": {"rotation": 0.20},
		"right_leg": {"rotation": -0.20}
	}

func _pose_double_jump() -> Dictionary:
	return {
		"hips": {"position": Vector2(0, -2), "rotation": 0.0},
		"torso": {"rotation": -0.05},
		"head": {"rotation": 0.0},
		"left_arm": {"rotation": -1.05},
		"right_arm": {"rotation": 1.05},
		"left_leg": {"rotation": 0.55},
		"right_leg": {"rotation": -0.55}
	}

func _pose_fall() -> Dictionary:
	return {
		"torso": {"rotation": 0.04},
		"head": {"rotation": -0.03},
		"left_arm": {"rotation": 0.10},
		"right_arm": {"rotation": -0.10},
		"left_leg": {"rotation": -0.10},
		"right_leg": {"rotation": 0.10}
	}

func _pose_fast_fall() -> Dictionary:
	return {
		"torso": {"rotation": -0.14},
		"head": {"rotation": 0.08},
		"left_arm": {"rotation": -0.25},
		"right_arm": {"rotation": 0.25},
		"left_leg": {"rotation": 0.16},
		"right_leg": {"rotation": -0.16}
	}

func _pose_land() -> Dictionary:
	return {
		"hips": {"position": Vector2(0, 3), "rotation": 0.0},
		"torso": {"rotation": 0.12},
		"head": {"rotation": -0.08},
		"left_leg": {"rotation": -0.35},
		"right_leg": {"rotation": 0.35}
	}

func _pose_attack_startup() -> Dictionary:
	return {
		"torso": {"rotation": -0.12},
		"head": {"rotation": 0.08},
		"left_arm": {"rotation": -0.20},
		"right_arm": {"rotation": -0.85},
		"hips": {"rotation": 0.08}
	}

func _pose_attack_active() -> Dictionary:
	return {
		"torso": {"rotation": 0.18},
		"head": {"rotation": -0.12},
		"left_arm": {"rotation": 0.25},
		"right_arm": {"rotation": 1.40},
		"hips": {"rotation": -0.15},
		"left_leg": {"rotation": -0.20},
		"right_leg": {"rotation": 0.20}
	}

func _pose_attack_recovery() -> Dictionary:
	return {
		"torso": {"rotation": 0.06},
		"head": {"rotation": -0.02},
		"left_arm": {"rotation": 0.06},
		"right_arm": {"rotation": 0.35},
		"hips": {"rotation": -0.04}
	}

func _pose_special_startup() -> Dictionary:
	return {
		"torso": {"rotation": -0.10},
		"head": {"rotation": 0.05},
		"left_arm": {"rotation": -1.1},
		"right_arm": {"rotation": 1.1},
		"element_aura": {"scale": Vector2(1.20, 1.20)}
	}

func _pose_special_active() -> Dictionary:
	return {
		"torso": {"rotation": 0.0},
		"head": {"rotation": 0.0},
		"left_arm": {"rotation": -1.5},
		"right_arm": {"rotation": 1.5},
		"element_aura": {"scale": Vector2(1.45, 1.45)}
	}

func _pose_special_recovery() -> Dictionary:
	return {
		"torso": {"rotation": 0.05},
		"head": {"rotation": -0.03},
		"left_arm": {"rotation": -0.45},
		"right_arm": {"rotation": 0.45},
		"element_aura": {"scale": Vector2(1.10, 1.10)}
	}

func _pose_aura_charge_a() -> Dictionary:
	return {
		"torso": {"rotation": 0.03},
		"head": {"rotation": 0.02},
		"left_arm": {"rotation": -0.70},
		"right_arm": {"rotation": 0.70},
		"element_aura": {"scale": Vector2(1.15, 1.15)}
	}

func _pose_aura_charge_b() -> Dictionary:
	return {
		"torso": {"rotation": -0.03},
		"head": {"rotation": -0.02},
		"left_arm": {"rotation": -1.00},
		"right_arm": {"rotation": 1.00},
		"element_aura": {"scale": Vector2(1.30, 1.30)}
	}

func _pose_hitstun() -> Dictionary:
	return {
		"torso": {"rotation": -0.30},
		"head": {"rotation": 0.22},
		"left_arm": {"rotation": -0.90},
		"right_arm": {"rotation": 0.90},
		"left_leg": {"rotation": 0.55},
		"right_leg": {"rotation": -0.55}
	}

func _pose_launched() -> Dictionary:
	return {
		"torso": {"rotation": 0.55},
		"head": {"rotation": -0.38},
		"left_arm": {"rotation": -1.2},
		"right_arm": {"rotation": 1.2},
		"left_leg": {"rotation": -1.0},
		"right_leg": {"rotation": 1.0}
	}

func _pose_shield() -> Dictionary:
	return {
		"torso": {"rotation": 0.02},
		"left_arm": {"rotation": -0.40},
		"right_arm": {"rotation": 0.40},
		"left_leg": {"rotation": 0.10},
		"right_leg": {"rotation": -0.10},
		"element_aura": {"scale": Vector2(1.05, 1.05)}
	}

func _pose_dodge() -> Dictionary:
	return {
		"torso": {"rotation": -0.22},
		"head": {"rotation": 0.12},
		"left_arm": {"rotation": -0.15},
		"right_arm": {"rotation": 0.15},
		"hips": {"position": Vector2(-5, 0)}
	}

func _pose_ko() -> Dictionary:
	return {
		"torso": {"rotation": PI / 2.0},
		"head": {"rotation": -0.30},
		"left_arm": {"rotation": -1.4},
		"right_arm": {"rotation": 1.4},
		"left_leg": {"rotation": -0.8},
		"right_leg": {"rotation": 0.8}
	}

func _pose_victory() -> Dictionary:
	return {
		"torso": {"rotation": -0.05},
		"head": {"rotation": 0.02},
		"left_arm": {"rotation": -1.2},
		"right_arm": {"rotation": 1.2},
		"left_leg": {"rotation": 0.05},
		"right_leg": {"rotation": -0.05}
	}

func _pose_defeat() -> Dictionary:
	return {
		"hips": {"position": Vector2(0, 5)},
		"torso": {"rotation": 0.35},
		"head": {"rotation": -0.25},
		"left_arm": {"rotation": 0.30},
		"right_arm": {"rotation": -0.30},
		"left_leg": {"rotation": -0.05},
		"right_leg": {"rotation": 0.05}
	}
