extends RefCounted
class_name HitReactionResolver

## Picks a victim reaction family. Gameplay state stays in FighterStates;
## clips are presentation-only.

const LIB_PATH := "res://data/combat/hurt_reaction_library.json"
const _FighterStates = preload("res://scripts/fighters/fighter_states.gd")

static var _doc: Dictionary = {}
static var _loaded := false


static func _ensure() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(LIB_PATH):
		_doc = {}
		return
	var f := FileAccess.open(LIB_PATH, FileAccess.READ)
	if f == null:
		_doc = {}
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	_doc = parsed if typeof(parsed) == TYPE_DICTIONARY else {}


static func families() -> Array:
	_ensure()
	return _doc.get("minimum_families", [])


static func resolve(defender: Node, info: Dictionary, move: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	_ensure()
	var forced := str(context.get("force_family", ""))
	if forced.is_empty() and Engine.get_main_loop() != null:
		var gs = Engine.get_main_loop().root.get_node_or_null("/root/GameState")
		if gs != null and "training_force_reaction" in gs:
			forced = str(gs.training_force_reaction)
	var family := forced if not forced.is_empty() and _has_family(forced) else _pick_family(defender, info, move, context)
	var fid := ""
	if defender != null and "fighter_id" in defender:
		fid = str(defender.fighter_id)
	var clip := clip_for(fid, family)
	var fam: Dictionary = (_doc.get("families", {}) as Dictionary).get(family, {})
	return {
		"family": family,
		"clip": clip,
		"legacy_clip": str(fam.get("legacy_clip", "hurt")),
		"gameplay_state": str(fam.get("gameplay_state", _FighterStates.HURT_LIGHT)),
		"percent_scale": _percent_scale(defender),
	}


static func clip_for(fighter_id: String, family: String) -> String:
	_ensure()
	var overrides: Dictionary = _doc.get("fighter_clip_overrides", {})
	if overrides.has(fighter_id):
		var table: Dictionary = overrides[fighter_id]
		if table.has(family):
			return str(table[family])
	var fam: Dictionary = (_doc.get("families", {}) as Dictionary).get(family, {})
	return str(fam.get("clip", fam.get("legacy_clip", "hurt")))


static func library_ok() -> bool:
	_ensure()
	var required: Array = _doc.get("minimum_families", [])
	var fams: Dictionary = _doc.get("families", {})
	if required.size() < 8:
		return false
	for name in required:
		if not fams.has(name):
			return false
	for fid in _doc.get("slice_fighters", []):
		var table: Dictionary = (_doc.get("fighter_clip_overrides", {}) as Dictionary).get(fid, {})
		for name in required:
			if not table.has(name):
				return false
	return true


static func _has_family(name: String) -> bool:
	_ensure()
	return (_doc.get("families", {}) as Dictionary).has(name)


static func _pick_family(defender: Node, info: Dictionary, move: Dictionary, context: Dictionary) -> String:
	if bool(info.get("blocked", false)) or bool(context.get("shield", false)):
		return "shield_recoil"
	if bool(info.get("is_ko", false)) or bool(context.get("is_ko", false)):
		return "ko_spin"
	var launch: Vector2 = info.get("launch", Vector2.ZERO)
	var kb := launch.length()
	var angle := rad_to_deg(atan2(-launch.y, absf(launch.x)))
	var element := str(info.get("element", move.get("element_effect", {}).get("type", "")))
	var choreo: Dictionary = move.get("choreography", {})
	var hinted := str(choreo.get("victim_reaction_family", ""))
	if hinted != "" and _has_family(hinted) and kb < 14.0:
		return hinted
	if launch.y > 10.0 or str(move.get("direction", "")).contains("down"):
		if kb > 8.0:
			return "spike"
	if kb > 18.0 and _percent_scale(defender) > 0.7:
		return "tumble"
	if kb > 14.0:
		if element == "frost":
			return "freeze_stiffness"
		if element == "impact":
			return "body_snap"
		return "launch"
	if kb > 10.0 and _percent_scale(defender) > 0.55:
		return "crumple"
	if kb > 8.0 or float(info.get("damage", 0.0)) >= 8.0:
		if element == "frost":
			return "freeze_stiffness"
		if element == "impact":
			return "body_snap"
		return "stagger"
	return "flinch"


static func _percent_scale(defender: Node) -> float:
	if defender == null or not ("damage_percent" in defender):
		return 0.0
	return clampf(float(defender.damage_percent) / 150.0, 0.0, 1.25)
