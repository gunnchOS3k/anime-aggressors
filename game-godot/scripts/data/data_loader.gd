extends RefCounted
class_name DataLoader

static func load_fighter(id: String) -> Dictionary:
	var path := "res://data/fighters/%s.json" % id
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(f.get_as_text())

static func load_moves(fighter_id: String) -> Dictionary:
	var path := "res://data/moves/%s.json" % fighter_id
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(f.get_as_text())

static func roster_ids() -> Array:
	var path := "res://data/fighters/roster.json"
	if not FileAccess.file_exists(path):
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	return data.get("fighters", [])

static func find_move(manifest: Dictionary, move_id: String) -> Dictionary:
	for m in manifest.get("moves", []):
		if m.get("move_id", "") == move_id:
			return m
	return {}

static func find_move_by_input(manifest: Dictionary, command: String, airborne: bool) -> Dictionary:
	for m in manifest.get("moves", []):
		if m.get("input_command", "") != command:
			continue
		var ga: String = m.get("grounded_air", "both")
		if ga == "both":
			return m
		if ga == "air" and airborne:
			return m
		if ga == "grounded" and not airborne:
			return m
	return {}
