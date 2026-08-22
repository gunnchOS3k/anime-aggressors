extends RefCounted
class_name SignatureNameRegistry

const _DATA_PATH := "res://data/runtime/signature_move_names.json"

static var _cache: Dictionary = {}


static func display_name(fighter_id: String, contract_key: String) -> String:
	_ensure_loaded()
	var fighter_map: Dictionary = _cache.get(fighter_id, {})
	if fighter_map.has(contract_key):
		return str(fighter_map[contract_key])
	if contract_key.begins_with("signature_lane_"):
		return contract_key.replace("signature_lane_", "").capitalize()
	return contract_key


static func is_placeholder_visible(contract_key: String, fighter_id: String) -> bool:
	var name := display_name(fighter_id, contract_key)
	return name == contract_key or name.begins_with("signature_lane_")


static func placeholder_count(fighter_id: String) -> int:
	_ensure_loaded()
	var fighter_map: Dictionary = _cache.get(fighter_id, {})
	var count := 0
	for key in fighter_map.keys():
		if is_placeholder_visible(str(key), fighter_id):
			count += 1
	return count


static func _ensure_loaded() -> void:
	if not _cache.is_empty():
		return
	if not FileAccess.file_exists(_DATA_PATH):
		return
	var f := FileAccess.open(_DATA_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_cache = parsed
