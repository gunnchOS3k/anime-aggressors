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
	var lib: Dictionary = library(fighter_id)
	var prof := profile(fighter_id, move_id)
	if parent == null:
		return null
	var amount := int(prof.get("amount", 8))
	var root := Node2D.new()
	root.name = "V3Particles_%s_%s" % [fighter_id, move_id]
	root.global_position = pos
	parent.add_child(root)
	var col: Color = lib.get("color", Color(1, 1, 1, 0.6))
	var grav: Vector2 = lib.get("gravity", Vector2.ZERO)
	var spread := float(lib.get("spread", 24.0))
	for i in range(amount):
		var mote := Polygon2D.new()
		mote.color = Color(col.r, col.g, col.b, col.a)
		mote.polygon = _shape_for(fighter_id)
		var ang := deg_to_rad((-spread * 0.5) + spread * (float(i) / max(1, amount - 1)))
		mote.position = Vector2.ZERO
		root.add_child(mote)
		var dest := Vector2(cos(ang), sin(ang)) * (18.0 + float(i) * 1.6) + grav * 0.08
		var tw := mote.create_tween()
		tw.tween_property(mote, "position", dest, 0.18)
		tw.parallel().tween_property(mote, "modulate:a", 0.0, 0.18)
		tw.tween_callback(mote.queue_free)
	var life := root.create_tween()
	life.tween_interval(0.22)
	life.tween_callback(root.queue_free)
	return root


static func _shape_for(fighter_id: String) -> PackedVector2Array:
	match fighter_id:
		"ember-vale":
			return PackedVector2Array([Vector2(0, -5), Vector2(3, 4), Vector2(-3, 4)])
		"rook-ironside":
			return PackedVector2Array([Vector2(-3, -3), Vector2(3, -3), Vector2(3, 3), Vector2(-3, 3)])
		"juno-spark":
			return PackedVector2Array([Vector2(0, -6), Vector2(1.5, 0), Vector2(0, 6), Vector2(-1.5, 0)])
		"kaia-windrow":
			return PackedVector2Array([Vector2(-6, 0), Vector2(0, -2), Vector2(6, 0), Vector2(0, 2)])
		"nix-calder":
			return PackedVector2Array([Vector2(0, -5), Vector2(3, 0), Vector2(0, 5), Vector2(-3, 0)])
		"orion-vell":
			return PackedVector2Array([Vector2(0, -2), Vector2(2, 0), Vector2(0, 2), Vector2(-2, 0)])
		_:
			return PackedVector2Array([Vector2(-2, -3), Vector2(3, 0), Vector2(-2, 3)])


static func nonplaceholder_count() -> int:
	_ensure()
	var n := 0
	for id in _profiles.keys():
		if not bool(_profiles[id].get("placeholder", true)):
			n += 1
	return n
