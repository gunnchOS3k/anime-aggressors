extends RefCounted
class_name MoveCatalog

const CATALOG_PATH := "res://data/moves/move_catalog.json"

static var _cache: Dictionary = {}

static func load_catalog() -> Dictionary:
	if not _cache.is_empty():
		return _cache
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		push_warning("MoveCatalog: missing %s" % CATALOG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_cache = parsed
	return _cache

static func get_move(fighter_id: String, move_id: String) -> Dictionary:
	var catalog := load_catalog()
	var fighter_moves: Dictionary = catalog.get(fighter_id, {})
	if fighter_moves.has(move_id):
		return fighter_moves[move_id]
	var prefixed := "%s_%s" % [fighter_id.split("-")[0], move_id]
	if fighter_moves.has(prefixed):
		return fighter_moves[prefixed]
	for key in fighter_moves.keys():
		var data: Dictionary = fighter_moves[key]
		if data.get("input", "") == move_id or data.get("move_id", "") == move_id:
			return data
	return {}

static func get_move_for_any(move_id: String) -> Dictionary:
	for fighter_id in FighterRoster.get_ids():
		var move := get_move(fighter_id, move_id)
		if not move.is_empty():
			return move
	return {}

static func all_fighter_moves(fighter_id: String) -> Array:
	var catalog := load_catalog()
	var fighter_moves: Dictionary = catalog.get(fighter_id, {})
	var result: Array = []
	var seen := {}
	for key in fighter_moves.keys():
		var data: Dictionary = fighter_moves[key]
		var input := String(data.get("input", key))
		if seen.has(input):
			continue
		seen[input] = true
		result.append(data)
	return result
