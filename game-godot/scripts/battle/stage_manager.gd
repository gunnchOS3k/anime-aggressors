extends RefCounted
## Single-writer StageManager for Anime Aggressors stage registry integration.
## Owns production_stages.json reconciliation: preserves canonical launch
## stages, exposes expanded-30 registry with honest playable vs pending status.
## Hazards are authoritative snapshot entries — never visual-only / divergent RNG.
## HUMAN_ART / RC2 / V1 gates remain false.

const PROD_PATH := "res://data/stages/production_stages.json"
const RULESET_PATH := "res://data/rulesets/stage_rulesets.json"
const BUILDER := preload("res://scripts/battle/stage_procedural_builder.gd")

var _prod: Dictionary = {}
var _rulesets: Dictionary = {}


func load_registry() -> Dictionary:
	_prod = _read_json(PROD_PATH)
	_rulesets = _read_json(RULESET_PATH)
	return summary()


func summary() -> Dictionary:
	var expanded: Array = _prod.get("expanded_30", [])
	var playable: Array = []
	var pending: Array = []
	for entry in expanded:
		if bool(entry.get("playable", false)):
			playable.append(str(entry.get("id", "")))
		else:
			pending.append(str(entry.get("id", "")))
	return {
		"canonical_launch": _prod.get("stages", []).filter(func(id): return str(id) in [
			"training-grid", "skyline-arena", "neon-rooftops", "cascade-foundry", "void-pier", "ember-courtyard"
		]),
		"production_stage_ids": _prod.get("stages", []),
		"expanded_count": expanded.size(),
		"playable_expanded": playable,
		"registered_pending": pending,
		"canonical_launch_preserved": bool(_prod.get("canonical_launch_preserved", false)),
		"HUMAN_ART_APPROVED": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
	}


func is_playable(stage_id: String) -> bool:
	if stage_id in ["training-grid", "skyline-arena", "neon-rooftops", "cascade-foundry", "void-pier", "ember-courtyard"]:
		return true
	for entry in _prod.get("expanded_30", []):
		if str(entry.get("id", "")) == stage_id:
			return bool(entry.get("playable", false))
	return false


func load_stage_data(stage_id: String) -> Dictionary:
	var path := "res://data/stages/%s.json" % stage_id
	return _read_json(path)


func build_stage(stage_root: Node2D, stage_id: String, reduce_motion: bool = false, ruleset_id: String = "competitive") -> Dictionary:
	if _prod.is_empty():
		load_registry()
	var stage_data := load_stage_data(stage_id)
	if stage_data.is_empty():
		return {"ok": false, "reason": "missing_stage_json", "stage_id": stage_id}
	if not is_playable(stage_id) and str(stage_data.get("productionStatus", "")) == "REGISTERED_PENDING":
		return {
			"ok": false,
			"reason": "registered_pending_not_playable",
			"stage_id": stage_id,
			"honest_status": stage_data.get("productionStatus", ""),
		}
	var built: Dictionary = BUILDER.build(stage_root, stage_data, reduce_motion)
	var ruleset: Dictionary = _rulesets.get("rulesets", {}).get(ruleset_id, {})
	var hazards_enabled := _hazards_enabled(stage_data, ruleset_id, ruleset)
	var hazard_snapshot := _hazard_snapshot(stage_data, hazards_enabled)
	return {
		"ok": true,
		"stage_id": stage_id,
		"ruleset_id": ruleset_id,
		"built": built,
		"spawn_points": stage_data.get("spawnPoints", []),
		"main_platform": stage_data.get("mainPlatform", {}),
		"hazards_enabled": hazards_enabled,
		"hazard_snapshot": hazard_snapshot,
		"yin_yang_presence": stage_data.get("yin_yang_presence", {}),
		"pink_foreshadow": stage_data.get("pink_foreshadow", {}),
		"productionStatus": stage_data.get("productionStatus", ""),
		"geometryStatus": stage_data.get("geometryStatus", ""),
		"artStatus": stage_data.get("artStatus", ""),
		"HUMAN_ART_APPROVED": false,
		"deterministic": true,
	}


func _hazards_enabled(stage_data: Dictionary, ruleset_id: String, ruleset: Dictionary) -> bool:
	if ruleset_id == "competitive":
		var comp: Dictionary = stage_data.get("rulesets", {}).get("competitive", {})
		var flag: Variant = comp.get("hazards", false)
		if typeof(flag) == TYPE_BOOL:
			return flag
		var text := str(flag).strip_edges().to_lower()
		return text != "" and text != "false" and text != "0" and text != "off"
	if ruleset_id == "party_chaos":
		return true
	return bool(ruleset.get("hazards_default", false))


func _hazard_snapshot(stage_data: Dictionary, enabled: bool) -> Array:
	## Authoritative hazard entries for combat-world snapshot / rollback.
	## Visual-only sockets are never counted as gameplay hazards.
	var out: Array = []
	if not enabled:
		return out
	for socket in stage_data.get("hazardSockets", []):
		if not bool(socket.get("authoritative", false)):
			continue
		out.append({
			"id": str(socket.get("id", "")),
			"x": float(socket.get("x", 0)),
			"y": float(socket.get("y", 0)),
			"radius": float(socket.get("radius", 0)),
			"effect": str(socket.get("effect", "")),
			"frames_period": int(socket.get("frames_period", 0)),
			"damage": float(socket.get("damage", 0)),
			"phase": 0,
			"deterministic": true,
		})
	return out


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
