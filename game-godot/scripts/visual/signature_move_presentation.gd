extends RefCounted
class_name SignatureMovePresentation

const _DATA_PATH := "res://data/runtime/signature_move_presentation.json"
const LANES := ["special_a", "special_b", "super", "heavy", "charge", "clash"]

static var _cache: Dictionary = {}


static func mapping() -> Dictionary:
	_ensure()
	return _cache


static func fighter_map(fighter_id: String) -> Dictionary:
	_ensure()
	var fighters: Dictionary = _cache.get("fighters", {})
	return fighters.get(fighter_id, {})


static func lane(fighter_id: String, lane_id: String) -> Dictionary:
	return fighter_map(fighter_id).get(lane_id, {})


static func move_id_for_lane(fighter_id: String, lane_id: String) -> String:
	return str(lane(fighter_id, lane_id).get("move_id", ""))


static func label_for_lane(fighter_id: String, lane_id: String) -> String:
	var row := lane(fighter_id, lane_id)
	var label := str(row.get("label", ""))
	if label.is_empty():
		return str(row.get("pose", lane_id))
	return label


static func unique_super_silhouette(fighter_id: String) -> String:
	return str(lane(fighter_id, "super").get("silhouette", ""))


static func mapping_complete() -> bool:
	_ensure()
	var fighters: Dictionary = _cache.get("fighters", {})
	if fighters.size() < 7:
		return false
	for fid in fighters.keys():
		for lane_id in ["special_a", "special_b", "super"]:
			var row: Dictionary = fighters[fid].get(lane_id, {})
			if str(row.get("move_id", "")).is_empty():
				return false
			if str(row.get("pose", "")).is_empty():
				return false
	return true


static func _ensure() -> void:
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
