extends RefCounted
class_name RuntimeMoveResolver

## Canonical runtime move id -> choreography action id -> procedural clip.
## Single source: res://data/runtime/move_clip_alias_map.json (mirrored in content/runtime/).

const _FighterStates = preload("res://scripts/fighters/fighter_states.gd")
const _SignatureNames = preload("res://scripts/visual/signature_name_registry.gd")
const _ALIAS_PATH := "res://data/runtime/move_clip_alias_map.json"

static var _map: Dictionary = {}
static var _loaded := false


static func _ensure_map() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(_ALIAS_PATH):
		_map = {}
		return
	var f := FileAccess.open(_ALIAS_PATH, FileAccess.READ)
	if f == null:
		_map = {}
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_map = parsed


static func move_id_to_clip_table() -> Dictionary:
	_ensure_map()
	return _map.get("move_id_to_clip", {})


static func design_only_clips() -> Dictionary:
	_ensure_map()
	var out := {}
	for clip in _map.get("design_only_clips", []):
		out[str(clip)] = true
	return out


static func projectile_clip_for_aura(aura_level: int) -> String:
	_ensure_map()
	var table: Dictionary = _map.get("projectile_tier_by_aura_level", {})
	var key := str(clampi(aura_level, 0, 4))
	return str(table.get(key, "projectile_tap"))


static func choreography_action_id(fighter_id: String, move_id: String) -> String:
	var clip := canonical_clip_for_move_id(move_id)
	if clip.is_empty():
		clip = move_id
	if clip.is_empty():
		return ""
	if clip.contains("."):
		return clip
	return "%s.%s" % [fighter_id, clip]


static func canonical_clip_for_move_id(move_id: String) -> String:
	_ensure_map()
	if move_id.is_empty():
		return ""
	var table: Dictionary = _map.get("move_id_to_clip", {})
	if table.has(move_id):
		return str(table[move_id])
	var aliases: Dictionary = _map.get("clip_aliases", {})
	if aliases.has(move_id):
		return str(aliases[move_id])
	if move_id.begins_with("signature_lane_"):
		return move_id
	return move_id


static func resolve_clip(state: String, move_id: String, loaded_clips: Dictionary) -> Dictionary:
	_ensure_map()
	var requested := _requested_clip(state, move_id)
	var clip := _resolve_loaded_name(requested, loaded_clips)
	var design_only := design_only_clips().has(requested) and not _is_gameplay_bound_clip(requested)
	var reachable := loaded_clips.has(clip) and not design_only
	var mapping := "EXACT"
	if clip != requested and loaded_clips.has(clip):
		mapping = "ALIASED"
	elif not loaded_clips.has(clip):
		mapping = "MISSING_CLIP"
	elif design_only:
		mapping = "DESIGN_ONLY"
	return {
		"requested": requested,
		"clip": clip,
		"reachable": reachable,
		"design_only": design_only,
		"mapping_status": mapping,
		"playability": "DESIGN_ONLY_NOT_CURRENTLY_PLAYABLE" if design_only else "RUNTIME_REACHABLE",
	}


static func signature_display_name(fighter_id: String, move_id: String) -> String:
	return _SignatureNames.display_name(fighter_id, move_id)


static func count_generated_clips(fighter_id: String) -> int:
	return _list_clip_names(fighter_id).size()


static func count_runtime_reachable(fighter_id: String) -> int:
	var loaded := _list_clip_names(fighter_id)
	var design := design_only_clips()
	var reachable := 0
	for clip in loaded:
		if not design.has(clip):
			reachable += 1
	return reachable


static func _is_gameplay_bound_clip(clip: String) -> bool:
	_ensure_map()
	var table: Dictionary = _map.get("move_id_to_clip", {})
	for mid in table.keys():
		if str(table[mid]) == clip:
			return true
	return false


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
	_ensure_map()
	if move_id != "":
		var from_move := canonical_clip_for_move_id(move_id)
		if from_move != "":
			return from_move
	return _clip_for_state(state)


static func _clip_for_state(state: String) -> String:
	_ensure_map()
	var table: Dictionary = _map.get("state_to_clip", {})
	if table.has(state):
		return str(table[state])
	# Attack/special/throw states without a move_id must not invent jab_1 as a silent fallback
	# when a current move id should have been supplied by Fighter.play path.
	if state in [_FighterStates.ATTACK_STARTUP, _FighterStates.ATTACK_ACTIVE, _FighterStates.ATTACK_RECOVERY]:
		return "jab"
	if state in [_FighterStates.SPECIAL_STARTUP, _FighterStates.SPECIAL_ACTIVE, _FighterStates.SPECIAL_RECOVERY]:
		return "projectile_full"
	if state in [_FighterStates.THROW_STARTUP, _FighterStates.THROW_RELEASE]:
		return "throw_forward"
	if state in [_FighterStates.AURA_BURST_STARTUP, _FighterStates.AURA_BURST_ACTIVE, _FighterStates.AURA_BURST_RECOVERY]:
		return "signature_lane_burst"
	return "idle"


static func _resolve_loaded_name(requested: String, loaded_clips: Dictionary) -> String:
	_ensure_map()
	if loaded_clips.has(requested):
		return requested
	var aliases: Dictionary = _map.get("clip_aliases", {})
	if aliases.has(requested) and loaded_clips.has(str(aliases[requested])):
		return str(aliases[requested])
	var table: Dictionary = _map.get("move_id_to_clip", {})
	if table.has(requested) and loaded_clips.has(str(table[requested])):
		return str(table[requested])
	if requested == "special":
		for fallback in ["projectile_full", "projectile_medium", "projectile_tap", "heavy"]:
			if loaded_clips.has(fallback):
				return fallback
	if requested == "dodge" and loaded_clips.has("dash"):
		return "dash"
	if requested == "aura_release" and loaded_clips.has("signature_lane_burst"):
		return "signature_lane_burst"
	return requested if loaded_clips.has(requested) else str(aliases.get(requested, requested))
