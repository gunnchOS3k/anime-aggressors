extends RefCounted
class_name ComboCatalog

const CATALOG_PATH := "res://data/combos/combo_catalog.json"

static var _cache: Dictionary = {}

static func load_catalog() -> Dictionary:
	if not _cache.is_empty():
		return _cache
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_cache = parsed
	return _cache

static func get_combos(fighter_id: String) -> Array:
	var catalog := load_catalog()
	return catalog.get(fighter_id, [])

static func combos_by_difficulty(fighter_id: String, difficulty: String) -> Array:
	var result: Array = []
	for combo in get_combos(fighter_id):
		if String(combo.get("difficulty", "")) == difficulty:
			result.append(combo)
	return result
