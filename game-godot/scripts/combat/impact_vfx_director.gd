extends Node
class_name ImpactVfxDirector

## Short-lived, contact-oriented, fighter-owned VFX. Presentation only.

const PALETTE_PATH := "res://data/combat/element_vfx_palettes.json"
const MAX_LIVE := 10

var _palettes: Dictionary = {}
var _live: Array = []


func _ready() -> void:
	_load()
	var bus = get_node_or_null("/root/JuiceEventBus")
	if bus != null and bus.has_signal("juice_event"):
		bus.juice_event.connect(_on_juice)


func _load() -> void:
	if not FileAccess.file_exists(PALETTE_PATH):
		return
	var f := FileAccess.open(PALETTE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_palettes = parsed


func _on_juice(event_name: String, payload: Dictionary) -> void:
	if event_name != "impact_vfx" and event_name != "hit_spark":
		return
	if bool(payload.get("suppressed", false)):
		return
	var parent := get_parent()
	if parent == null:
		return
	spawn(parent, payload)


func spawn(parent: Node, payload: Dictionary) -> void:
	_gc()
	if _live.size() >= MAX_LIVE:
		var old = _live.pop_front()
		if old is Node and is_instance_valid(old):
			old.queue_free()
	var fid := str(payload.get("fighter_id", payload.get("attacker_id", "")))
	var pal: Dictionary = (_palettes.get("fighters", {}) as Dictionary).get(fid, {})
	if pal.is_empty():
		var element := str(payload.get("element", ""))
		for key in (_palettes.get("fighters", {}) as Dictionary).keys():
			var row: Dictionary = _palettes["fighters"][key]
			if str(row.get("element", "")) == element:
				pal = row
				break
	var color_a: Array = pal.get("color", [1, 1, 1, 1])
	var color := Color(float(color_a[0]), float(color_a[1]), float(color_a[2]), float(color_a[3]) if color_a.size() > 3 else 1.0)
	var tier := str(payload.get("tier", "medium"))
	var scale_tbl: Dictionary = _palettes.get("tier_scale", {})
	var scl := float(scale_tbl.get(tier, 1.0))
	var pos: Vector2 = payload.get("pos", Vector2.ZERO)
	var dir: Vector2 = payload.get("dir", Vector2.RIGHT)
	if dir.length() < 0.01:
		dir = Vector2.RIGHT
	var spark := ColorRect.new()
	var base := 14.0 * scl
	spark.size = Vector2(base, base * (1.35 if str(pal.get("shape", "")) == "slash_arc" else 1.0))
	spark.position = pos - spark.size * 0.5
	spark.rotation = dir.angle()
	spark.color = color
	spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(spark)
	_live.append(spark)
	var life := float(pal.get("particle_life", 0.12))
	var tw := spark.create_tween()
	tw.tween_property(spark, "scale", Vector2(1.6, 1.6), life)
	tw.parallel().tween_property(spark, "modulate:a", 0.0, life)
	tw.tween_callback(spark.queue_free)
	if str(pal.get("shape", "")) in ["ring_shock", "orbit_ring", "crystal"]:
		var ring := ColorRect.new()
		ring.size = Vector2(22 * scl, 22 * scl)
		ring.position = pos - ring.size * 0.5
		ring.color = Color(color.r, color.g, color.b, 0.35)
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(ring)
		_live.append(ring)
		var rt := ring.create_tween()
		rt.tween_property(ring, "scale", Vector2(2.1, 2.1), life + 0.04)
		rt.parallel().tween_property(ring, "modulate:a", 0.0, life + 0.04)
		rt.tween_callback(ring.queue_free)


func _gc() -> void:
	var kept: Array = []
	for n in _live:
		if n is Node and is_instance_valid(n):
			kept.append(n)
	_live = kept
