extends RefCounted
class_name RuntimeMoveResolver

## Canonical runtime move id -> choreography action id -> procedural clip.

const _FighterStates = preload("res://scripts/fighters/fighter_states.gd")
const _SignatureNames = preload("res://scripts/visual/signature_name_registry.gd")

const DESIGN_ONLY_ACTIONS := {
	"air_drift": true,
	"tilt_forward": true,
	"tilt_up": true,
	"tilt_down": true,
	"smash_forward": true,
	"smash_up": true,
	"smash_down": true,
	"aerial_neutral": true,
	"aerial_forward": true,
	"aerial_back": true,
	"aerial_up": true,
	"aerial_down": true,
	"projectile_tap": true,
	"projectile_medium": true,
	"projectile_full": true,
	"air_dodge": true,
	"tumble": true,
	"launch": true,
}

const CLIP_ALIASES := {
	"jab_1": "jab",
	"jab_2": "jab_chain_2",
	"heavy_attack": "heavy",
	"special": "projectile_full",
	"land": "landing",
	"hurt_light": "hurt",
	"hurt_heavy": "hurt",
	"launched": "launch",
	"aura_burst": "aura_release",
	"throw": "throw_forward",
}


static func choreography_action_id(fighter_id: String, move_id: String) -> String:
	if move_id.is_empty():
		return ""
	if move_id.contains("."):
		return move_id
	return "%s.%s" % [fighter_id, move_id]


static func resolve_clip(state: String, move_id: String, loaded_clips: Dictionary) -> Dictionary:
	var requested := _requested_clip(state, move_id)
	var clip := _resolve_loaded_name(requested, loaded_clips)
	var design_only := DESIGN_ONLY_ACTIONS.has(requested) and not loaded_clips.has(requested)
	return {
		"requested": requested,
		"clip": clip,
		"reachable": loaded_clips.has(clip),
		"design_only": design_only,
		"playability": "DESIGN_ONLY_NOT_CURRENTLY_PLAYABLE" if design_only else "RUNTIME_REACHABLE",
	}


static func signature_display_name(fighter_id: String, move_id: String) -> String:
	return _SignatureNames.display_name(fighter_id, move_id)


static func count_generated_clips(fighter_id: String) -> int:
	var root := "res://content/fighters/%s/animations/procedural" % fighter_id
	var abs_root := ProjectSettings.globalize_path(root)
	if not DirAccess.dir_exists_absolute(abs_root):
		return 0
	var dir := DirAccess.open(abs_root)
	if dir == null:
		return 0
	var count := 0
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".anim.json") and not dir.current_is_dir():
			count += 1
		file_name = dir.get_next()
	dir.list_dir_end()
	return count


static func count_runtime_reachable(fighter_id: String) -> int:
	var loaded := _list_clip_names(fighter_id)
	var reachable := 0
	for clip in loaded:
		if not DESIGN_ONLY_ACTIONS.has(clip):
			reachable += 1
	return reachable


static func _list_clip_names(fighter_id: String) -> Array[String]:
	var names: Array[String] = []
	var root := "res://content/fighters/%s/animations/procedural" % fighter_id
	var abs_root := ProjectSettings.globalize_path(root)
	if not DirAccess.dir_exists_absolute(abs_root):
		return names
	var dir := DirAccess.open(abs_root)
	if dir == null:
		return names
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".anim.json") and not dir.current_is_dir():
			names.append(file_name.replace(".anim.json", ""))
		file_name = dir.get_next()
	dir.list_dir_end()
	return names


static func _requested_clip(state: String, move_id: String) -> String:
	if move_id != "":
		if move_id.begins_with("signature_lane_"):
			return move_id
		if move_id in ["jab_1", "jab_2", "heavy_attack"]:
			return move_id
		if move_id in ["throw_forward", "throw_back", "throw_up", "throw_down"]:
			return move_id
		if move_id in ["projectile_tap", "projectile_medium", "projectile_full", "grab", "recovery", "dodge"]:
			return move_id
	return _clip_for_state(state)


static func _clip_for_state(state: String) -> String:
	if state in [_FighterStates.ATTACK_STARTUP, _FighterStates.ATTACK_ACTIVE, _FighterStates.ATTACK_RECOVERY]:
		return "jab_1"
	if state in [_FighterStates.SPECIAL_STARTUP, _FighterStates.SPECIAL_ACTIVE, _FighterStates.SPECIAL_RECOVERY]:
		return "special"
	if state in [_FighterStates.THROW_STARTUP, _FighterStates.THROW_RELEASE]:
		return "throw_forward"
	match state:
		_FighterStates.WALK:
			return "walk"
		_FighterStates.RUN:
			return "run"
		_FighterStates.DASH, _FighterStates.DODGE_START, _FighterStates.DODGE_ACTIVE:
			return "dodge"
		_FighterStates.JUMP, _FighterStates.JUMP_SQUAT, _FighterStates.DOUBLE_JUMP:
			return "jump"
		_FighterStates.FALL, _FighterStates.FAST_FALL, _FighterStates.TUMBLE:
			return "fall"
		_FighterStates.LAND:
			return "land"
		_FighterStates.SHIELD_START, _FighterStates.SHIELD_HOLD, _FighterStates.SHIELD_STUN:
			return "shield"
		_FighterStates.GRAB_STARTUP, _FighterStates.GRAB_ACTIVE, _FighterStates.GRAB_HOLD:
			return "grab"
		_FighterStates.AURA_CHARGE, _FighterStates.AURA_READY:
			return "aura_charge"
		_FighterStates.AURA_BURST_STARTUP, _FighterStates.AURA_BURST_ACTIVE, _FighterStates.AURA_BURST_RECOVERY:
			return "aura_burst"
		_FighterStates.HURT_LIGHT:
			return "hurt_light"
		_FighterStates.HURT_HEAVY, _FighterStates.HITSTUN:
			return "hurt_heavy"
		_FighterStates.LAUNCHED:
			return "launched"
		_FighterStates.KO:
			return "ko"
		_FighterStates.VICTORY:
			return "victory"
		_FighterStates.DEFEAT:
			return "defeat"
		_:
			return "idle"


static func _resolve_loaded_name(requested: String, loaded_clips: Dictionary) -> String:
	if loaded_clips.has(requested):
		return requested
	if CLIP_ALIASES.has(requested) and loaded_clips.has(CLIP_ALIASES[requested]):
		return str(CLIP_ALIASES[requested])
	if requested == "special":
		for fallback in ["projectile_full", "projectile_medium", "heavy"]:
			if loaded_clips.has(fallback):
				return fallback
	if requested.begins_with("throw_") and loaded_clips.has(requested):
		return requested
	if requested == "dodge" and loaded_clips.has("dash"):
		return "dash"
	return requested if loaded_clips.has(requested) else str(CLIP_ALIASES.get(requested, requested))
