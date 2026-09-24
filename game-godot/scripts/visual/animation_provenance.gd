extends RefCounted
class_name AnimationProvenance

## Honest authored-vs-procedural labels. Automation never writes AUTHORED_APPROVED.

const AUTHORED_APPROVED := "AUTHORED_APPROVED"
const AUTHORED_WIP := "AUTHORED_WIP"
const GENERATED_PRODUCTION := "GENERATED_PRODUCTION_ANIMATION"
const PROCEDURAL_FALLBACK := "PROCEDURAL_FALLBACK"
const MISSING := "MISSING"

const LABELS := [AUTHORED_APPROVED, AUTHORED_WIP, GENERATED_PRODUCTION, PROCEDURAL_FALLBACK, MISSING]

static var _roster: Dictionary = {}
static var _loaded := false


static func load_roster() -> Dictionary:
	if _loaded:
		return _roster
	var path := "res://../art_source/animation/manifests/provenance_roster.json"
	if not FileAccess.file_exists(path):
		path = "res://data/animation/provenance_roster.json"
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		f.close()
		if typeof(parsed) == TYPE_DICTIONARY:
			_roster = parsed
	_loaded = true
	return _roster


static func status_for(fighter_id: String, clip: String) -> String:
	if clip == "pipeline_proof":
		var glb := authored_glb_path(fighter_id, clip)
		if ResourceLoader.exists(glb) or FileAccess.file_exists(glb):
			return AUTHORED_WIP
		return MISSING
	var roster := load_roster()
	var hero: Array = roster.get("wave_a_hero", [])
	for row in hero:
		if str(row.get("fighter_id")) == fighter_id and (
			str(row.get("action_id")) == clip or str(row.get("runtime_clip", "")) == clip
		):
			return str(row.get("status", PROCEDURAL_FALLBACK))
	if clip.is_empty():
		return MISSING
	var generated := "res://content/fighters/%s/animations/generated_production/%s.anim.json" % [fighter_id, clip]
	if FileAccess.file_exists(generated):
		return GENERATED_PRODUCTION
	return PROCEDURAL_FALLBACK


static func authored_glb_path(fighter_id: String, clip: String) -> String:
	return "res://assets/characters/authored/%s/%s.glb" % [fighter_id, clip]


static func label_ok(label: String) -> bool:
	return label in LABELS


static func automation_may_write(label: String) -> bool:
	return label in [AUTHORED_WIP, GENERATED_PRODUCTION, PROCEDURAL_FALLBACK, MISSING]


static func debug_line(fighter_id: String, clip: String) -> String:
	return "%s %s %s" % [fighter_id, clip, status_for(fighter_id, clip)]
