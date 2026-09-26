extends RefCounted
class_name MoveContentCatalog

## V3 161-move catalog. Digital completeness only; never claims HUMAN_*/OWNER_* passes.

const CATALOG_PATH := "res://data/combat/v3_move_content_catalog.json"
const MATRIX_PATH := "res://../artifacts/combat/v3/MOVE_CONTENT_COMPLETION_MATRIX.json"
const REQUIRED_MOVES := [
	"jab_1", "jab_2", "jab_finisher", "forward_tilt", "up_tilt", "down_tilt",
	"dash_attack", "heavy_attack", "neutral_air", "forward_air", "up_air", "down_air",
	"neutral_special_projectile", "side_special", "up_special_recovery", "down_special",
	"grab", "throw_forward", "throw_back", "throw_up", "throw_down", "aura_charge", "aura_burst",
]
const FIGHTERS := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]

static var _rows: Array = []
static var _loaded := false


static func _ensure() -> void:
	if _loaded:
		return
	_loaded = true
	if FileAccess.file_exists(CATALOG_PATH):
		var f := FileAccess.open(CATALOG_PATH, FileAccess.READ)
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		f.close()
		if typeof(parsed) == TYPE_DICTIONARY:
			_rows = parsed.get("rows", [])


static func all_rows() -> Array:
	_ensure()
	return _rows


static func row_for(fighter_id: String, move_id: String) -> Dictionary:
	_ensure()
	for row in _rows:
		if str(row.get("fighter_id", "")) == fighter_id and str(row.get("move_id", "")) == move_id:
			return row
	return {}


static func required_total() -> int:
	return FIGHTERS.size() * REQUIRED_MOVES.size()


static func audit_manifests() -> Dictionary:
	var missing: Array = []
	var present := 0
	for fid in FIGHTERS:
		var path := "res://data/moves/%s.json" % fid
		if not FileAccess.file_exists(path):
			missing.append("%s:manifest" % fid)
			continue
		var f := FileAccess.open(path, FileAccess.READ)
		var data: Dictionary = JSON.parse_string(f.get_as_text())
		f.close()
		var have := {}
		for move in data.get("moves", []):
			have[str(move.get("move_id", ""))] = move
		for mid in REQUIRED_MOVES:
			if not have.has(mid):
				missing.append("%s:%s" % [fid, mid])
			else:
				present += 1
	return {
		"present": present,
		"required": required_total(),
		"missing": missing,
		"pass": missing.is_empty() and present == required_total(),
	}
