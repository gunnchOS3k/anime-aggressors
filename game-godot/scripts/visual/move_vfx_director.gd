extends RefCounted
class_name MoveVfxDirector

## Power-specific VFX. Shape language differs per fighter; not a palette swap.

const _Particles = preload("res://scripts/visual/elemental_particle_library.gd")
const EVENT_PATH := "res://data/combat/v3_vfx_events.json"

const SHAPES := {
	"flame_tongue_cone": "triangle_burst",
	"pressure_ring_fracture": "ring_burst",
	"jagged_fork_arc": "fork_burst",
	"crescent_ribbon": "crescent_burst",
	"crystal_shard_fan": "shard_fan",
	"orbit_node_collapse": "orbit_nodes",
	"phase_seam_echo": "ghost_echo",
}

static var _events: Dictionary = {}
static var _loaded := false


static func _ensure() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(EVENT_PATH):
		return
	var f := FileAccess.open(EVENT_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for row in parsed.get("rows", []):
		_events["%s:%s" % [row.get("fighter_id", ""), row.get("move_id", "")]] = row


static func event_for(fighter_id: String, move_id: String) -> Dictionary:
	_ensure()
	return _events.get("%s:%s" % [fighter_id, move_id], {})


static func play(parent: Node2D, fighter_id: String, move_id: String, pos: Vector2, facing: int = 1) -> Dictionary:
	var ev := event_for(fighter_id, move_id)
	if parent == null:
		return {"ok": false, "reason": "no_parent"}
	var shape := str(ev.get("shape", ""))
	var node := Node2D.new()
	node.name = "V3Vfx_%s" % str(ev.get("event", move_id))
	node.global_position = pos
	node.scale.x = 1.0 if facing >= 0 else -1.0
	parent.add_child(node)
	_draw_shape(node, fighter_id, shape, str(ev.get("tier", "light")))
	_Particles.spawn(parent, fighter_id, move_id, pos)
	var tw := node.create_tween()
	tw.tween_interval(0.2)
	tw.tween_callback(node.queue_free)
	return {
		"ok": true,
		"event": ev.get("event", ""),
		"shape": shape,
		"palette_only": false,
		"family": ev.get("family", ""),
	}


static func _draw_shape(host: Node2D, fighter_id: String, shape: String, tier: String) -> void:
	var col := _color(fighter_id)
	var scale_m := 1.0
	match tier:
		"heavy", "aura":
			scale_m = 1.35
		"super":
			scale_m = 1.7
	var poly := Polygon2D.new()
	poly.color = Color(col.r, col.g, col.b, 0.72)
	match shape:
		"flame_tongue_cone":
			poly.polygon = PackedVector2Array([Vector2(0, -6 * scale_m), Vector2(22 * scale_m, -2), Vector2(22 * scale_m, 6), Vector2(0, 4)])
		"pressure_ring_fracture":
			poly.polygon = _ring(16.0 * scale_m)
		"jagged_fork_arc":
			poly.polygon = PackedVector2Array([Vector2(0, 0), Vector2(18 * scale_m, -10), Vector2(10 * scale_m, 0), Vector2(20 * scale_m, 10)])
		"crescent_ribbon":
			poly.polygon = PackedVector2Array([Vector2(-4, -10 * scale_m), Vector2(16 * scale_m, -6), Vector2(12 * scale_m, 0), Vector2(16 * scale_m, 6), Vector2(-4, 10 * scale_m)])
		"crystal_shard_fan":
			poly.polygon = PackedVector2Array([Vector2(0, 0), Vector2(14 * scale_m, -8), Vector2(8 * scale_m, 0), Vector2(14 * scale_m, 8)])
		"orbit_node_collapse":
			poly.polygon = _ring(10.0 * scale_m)
			var node_a := Polygon2D.new()
			node_a.color = Color(0.95, 0.92, 1.0, 0.9)
			node_a.polygon = _ring(3.0)
			node_a.position = Vector2(12 * scale_m, -6)
			host.add_child(node_a)
		"phase_seam_echo":
			poly.color.a = 0.45
			poly.polygon = PackedVector2Array([Vector2(-8, -8 * scale_m), Vector2(12 * scale_m, -4), Vector2(8 * scale_m, 8 * scale_m), Vector2(-6, 4)])
			var echo := Polygon2D.new()
			echo.color = Color(col.r, col.g, col.b, 0.25)
			echo.polygon = poly.polygon
			echo.position = Vector2(-10, 0)
			host.add_child(echo)
		_:
			poly.polygon = PackedVector2Array([Vector2(-6, -6), Vector2(8, 0), Vector2(-6, 6)])
	host.add_child(poly)


static func _ring(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(8):
		var a := float(i) * TAU / 8.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts


static func _color(fighter_id: String) -> Color:
	match fighter_id:
		"ember-vale":
			return Color(1.0, 0.4, 0.08)
		"rook-ironside":
			return Color(0.86, 0.52, 0.18)
		"juno-spark":
			return Color(1.0, 0.9, 0.2)
		"kaia-windrow":
			return Color(0.2, 0.85, 0.45)
		"nix-calder":
			return Color(0.35, 0.7, 1.0)
		"orion-vell":
			return Color(0.5, 0.38, 0.95)
		"vesper-nyx":
			return Color(0.7, 0.28, 0.82)
		_:
			return Color.WHITE


static func unique_event_count() -> int:
	_ensure()
	return _events.size()
