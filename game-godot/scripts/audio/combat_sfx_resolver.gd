extends RefCounted
class_name CombatSfxResolver

## Per-move procedural SFX. Not a logged string. Falls back to fighter category bank.

const _Bank = preload("res://scripts/audio/procedural_audio_bank.gd")
const PROV_PATH := "res://data/combat/v3_sfx_events.json"

static var _events: Dictionary = {}
static var _loaded := false


static func _ensure() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(PROV_PATH):
		return
	var f := FileAccess.open(PROV_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for row in parsed.get("rows", []):
		_events["%s:%s" % [row.get("fighter_id", ""), row.get("move_id", "")]] = row


static func row_for(fighter_id: String, move_id: String) -> Dictionary:
	_ensure()
	return _events.get("%s:%s" % [fighter_id, move_id], {})


static func play_move(fighter_id: String, move_id: String, host: Node = null) -> Dictionary:
	var row := row_for(fighter_id, move_id)
	var path := str(row.get("asset", ""))
	if path != "":
		var played := _Bank.play(path, host, float(row.get("volume_db", 0.0)))
		if bool(played.get("ok", false)):
			played["event"] = row.get("event", "")
			played["mix_bus"] = row.get("mix_bus", "")
			played["per_move"] = true
			return played
	var cat := _Bank.map_sfx_event_to_category(str(row.get("event", move_id)))
	var fallback := _Bank.play_fighter(fighter_id, cat, host)
	fallback["per_move"] = false
	fallback["event"] = row.get("event", move_id)
	return fallback


static func audible_count() -> int:
	_ensure()
	var n := 0
	for key in _events.keys():
		var row: Dictionary = _events[key]
		if not bool(row.get("silent", true)) and str(row.get("asset", "")) != "":
			n += 1
	return n
