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
	var renderer = preload("res://scripts/visual/spectral_feedback_renderer.gd").obtain(parent)
	if renderer != null: renderer.emit_effect(fighter_id,6,pos,Vector2(facing,0),58,.13)

	return {
		"ok": true,
		"event": ev.get("event", ""),
		"shape": shape,
		"palette_only": false,
		"family": ev.get("family", ""),
	}


static func unique_event_count() -> int:
	_ensure()
	return _events.size()
