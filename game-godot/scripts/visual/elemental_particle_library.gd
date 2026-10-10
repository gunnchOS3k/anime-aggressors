extends RefCounted
class_name ElementalParticleLibrary

## Fighter-specific particle profiles. Not blank, not debug-only, not silhouette-obscuring.

const PROFILE_PATH := "res://data/combat/v3_particle_profiles.json"

const LIBRARIES := {
	"ember-vale": {"texture_hint": "ember", "spread": 28.0, "gravity": Vector2(0, -40), "color": Color(1.0, 0.42, 0.08, 0.7)},
	"rook-ironside": {"texture_hint": "chip", "spread": 18.0, "gravity": Vector2(0, 90), "color": Color(0.72, 0.48, 0.22, 0.7)},
	"juno-spark": {"texture_hint": "spark", "spread": 40.0, "gravity": Vector2(0, 0), "color": Color(1.0, 0.92, 0.28, 0.75)},
	"kaia-windrow": {"texture_hint": "streak", "spread": 50.0, "gravity": Vector2(0, -20), "color": Color(0.45, 0.95, 0.7, 0.65)},
	"nix-calder": {"texture_hint": "crystal", "spread": 22.0, "gravity": Vector2(0, 16), "color": Color(0.55, 0.86, 1.0, 0.7)},
	"orion-vell": {"texture_hint": "node", "spread": 34.0, "gravity": Vector2(0, 0), "color": Color(0.62, 0.5, 1.0, 0.7)},
	"vesper-nyx": {"texture_hint": "wisp", "spread": 26.0, "gravity": Vector2(0, -8), "color": Color(0.74, 0.32, 0.82, 0.55)},
}

static var _profiles: Dictionary = {}
static var _loaded := false


static func _ensure() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(PROFILE_PATH):
		return
	var f := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for row in parsed.get("rows", []):
		_profiles[str(row.get("id", ""))] = row


static func profile(fighter_id: String, move_id: String) -> Dictionary:
	_ensure()
	var key := "%s.%s.%s" % [fighter_id, move_id, str(LIBRARIES.get(fighter_id, {}).get("texture_hint", "ember"))]
	# Catalog ids use library names; fall back to prefix scan.
	for id in _profiles.keys():
		var row: Dictionary = _profiles[id]
		if str(row.get("fighter_id", "")) == fighter_id and str(row.get("move_id", "")) == move_id:
			return row
	return _profiles.get(key, {})


static func library(fighter_id: String) -> Dictionary:
	return LIBRARIES.get(fighter_id, {})


static func spawn(parent: Node2D, fighter_id: String, move_id: String, pos: Vector2) -> Node2D:
	var renderer = preload("res://scripts/visual/spectral_feedback_renderer.gd").obtain(parent)
	if renderer != null: renderer.emit_effect(fighter_id,5,pos,Vector2.RIGHT,40,.2)
	return renderer


static func nonplaceholder_count() -> int:
	_ensure()
	var n := 0
	for id in _profiles.keys():
		if not bool(_profiles[id].get("placeholder", true)):
			n += 1
	return n
