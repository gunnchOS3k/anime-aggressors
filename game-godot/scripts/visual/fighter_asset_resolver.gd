extends RefCounted
class_name FighterAssetResolver

## Canonical fighter presentation authority (Wave020 CP2).
## One resolve API for all player-facing contexts. Legacy paths are classified
## and rejected for normal gameplay (DEV_ONLY / TEST_ONLY / HISTORICAL / DEPRECATED).

const STATUS_PROCEDURAL := "PROCEDURAL_PRODUCTION_PROXY"
const STATUS_PROCEDURAL_ANIM := "PROCEDURAL_RUNTIME_ANIMATION"

const CLASS_CURRENT := "CURRENT_PLAYER_FACING"
const CLASS_DEV := "DEV_ONLY"
const CLASS_TEST := "TEST_ONLY"
const CLASS_HISTORICAL := "HISTORICAL"
const CLASS_DEPRECATED := "DEPRECATED"

const CTX_SELECT_CARD := "select_card"
const CTX_SELECT_PREVIEW := "select_preview"
const CTX_VERSUS := "versus"
const CTX_BATTLE := "battle"
const CTX_MOVE_PREVIEW := "move_preview"
const CTX_VICTORY := "victory"
const CTX_BOOT := "boot"

## Telemetry counters (process-lifetime).
static var PLAYER_VISIBLE_LEGACY_MODEL_OCCURRENCES: int = 0
static var PLAYER_VISIBLE_LEGACY_CARD_OCCURRENCES: int = 0
static var PLAYER_VISIBLE_LEGACY_BATTLE_BODY_OCCURRENCES: int = 0
static var PLAYER_VISIBLE_LEGACY_MOVE_PREVIEW_OCCURRENCES: int = 0
static var PLAYER_VISIBLE_LEGACY_VICTORY_OCCURRENCES: int = 0
static var CANONICAL_MODEL_LOAD_FAILURES: int = 0
static var CANONICAL_MODEL_RECOVERIES: int = 0
static var EMERGENCY_FALLBACK_USES: int = 0
static var LEGACY_FALLBACK_USES: int = 0


static func canonical_glb_path(fighter_id: String) -> String:
	return "res://content/fighters/%s/model/%s_procedural_proxy.glb" % [fighter_id, fighter_id]


static func classify_path(path: String) -> String:
	if path.is_empty():
		return CLASS_DEPRECATED
	if path.contains("/content/fighters/") and path.ends_with("_procedural_proxy.glb"):
		return CLASS_CURRENT
	if path.contains("/approved/") or path.contains("/final/") or path.contains("vroid"):
		return CLASS_CURRENT
	if path.contains("assets/characters/proxy/"):
		return CLASS_HISTORICAL
	if path.contains("assets/characters/procedural_final/"):
		return CLASS_DEPRECATED
	if path.contains("assets/ui/placeholders/"):
		return CLASS_HISTORICAL
	if path.contains("/labs/") or path.contains("RosterArtLab") or path.contains("AnimationLab"):
		return CLASS_DEV
	return CLASS_DEPRECATED


static func is_player_build() -> bool:
	## Treat shipped/debug APK and normal desktop export as player-facing.
	## Lab scenes may opt out via SceneRouter / feature flags later.
	return true


static func resolve_presentation(fighter_id: String, context: String, fighter_data: Dictionary = {}) -> Dictionary:
	## CanonicalFighterPresentationResolver entry point.
	var data: Dictionary = fighter_data
	if data.is_empty() and Engine.get_main_loop() != null:
		var gs = Engine.get_main_loop().root.get_node_or_null("/root/GameState")
		if gs != null and gs.has_method("load_fighter"):
			data = gs.load_fighter(fighter_id)
	var model := resolve_model_path(fighter_id, data)
	var path := str(model.get("path", ""))
	var classification := classify_path(path)
	if classification != CLASS_CURRENT and is_player_build():
		# Reject legacy — force canonical content proxy.
		var forced := canonical_glb_path(fighter_id)
		if ResourceLoader.exists(forced):
			_count_legacy_reject(context)
			path = forced
			classification = CLASS_CURRENT
			model = {
				"path": forced,
				"source": "PROCEDURAL_PRODUCTION_PROXY",
				"tier": STATUS_PROCEDURAL,
				"CURRENT_MODEL_SOURCE": "PROCEDURAL_PRODUCTION_PROXY",
				"legacy_rejected": true,
			}
		else:
			CANONICAL_MODEL_LOAD_FAILURES += 1
			model["legacy_rejected"] = true
			model["canonical_missing"] = true
	var representation_id := "%s::%s" % [fighter_id, str(model.get("source", "UNKNOWN"))]
	return {
		"fighter_id": fighter_id,
		"context": context,
		"path": path,
		"representation_id": representation_id,
		"classification": classification,
		"is_current_canonical": classification == CLASS_CURRENT,
		"is_legacy": classification != CLASS_CURRENT,
		"source": model.get("source", "MISSING"),
		"tier": model.get("tier", "MISSING"),
		"CURRENT_MODEL_SOURCE": model.get("CURRENT_MODEL_SOURCE", model.get("source", "MISSING")),
		"model": model,
	}


static func _count_legacy_reject(context: String) -> void:
	match context:
		CTX_SELECT_CARD:
			PLAYER_VISIBLE_LEGACY_CARD_OCCURRENCES += 1
		CTX_BATTLE:
			PLAYER_VISIBLE_LEGACY_BATTLE_BODY_OCCURRENCES += 1
		CTX_MOVE_PREVIEW:
			PLAYER_VISIBLE_LEGACY_MOVE_PREVIEW_OCCURRENCES += 1
		CTX_VICTORY:
			PLAYER_VISIBLE_LEGACY_VICTORY_OCCURRENCES += 1
		_:
			PLAYER_VISIBLE_LEGACY_MODEL_OCCURRENCES += 1


static func resolve_model_path(fighter_id: String, fighter_data: Dictionary = {}) -> Dictionary:
	var explicit := str(fighter_data.get("modelPath", ""))
	# Approved / final / vroid — only if path itself is not a procedural_final legacy alias.
	if explicit.contains("/approved/") or (explicit.contains("/final/") and not explicit.contains("procedural_final")):
		return {"path": explicit, "source": "FINAL_CUSTOM", "tier": "FINAL_CUSTOM", "CURRENT_MODEL_SOURCE": "FINAL_CUSTOM"}
	if explicit.contains("vroid") or explicit.contains("/approved_vroid/"):
		return {"path": explicit, "source": "APPROVED_VROID", "tier": "APPROVED_VROID", "CURRENT_MODEL_SOURCE": "APPROVED_VROID"}
	var proxy := canonical_glb_path(fighter_id)
	if ResourceLoader.exists(proxy):
		return {
			"path": proxy,
			"source": "PROCEDURAL_PRODUCTION_PROXY",
			"tier": STATUS_PROCEDURAL,
			"CURRENT_MODEL_SOURCE": "PROCEDURAL_PRODUCTION_PROXY",
		}
	# Legacy secondary — still discoverable for labs, but marked DEPRECATED.
	var legacy := "res://assets/characters/procedural_final/%s.glb" % fighter_id
	if ResourceLoader.exists(legacy):
		return {
			"path": legacy,
			"source": "LEGACY_PROCEDURAL_FINAL",
			"tier": STATUS_PROCEDURAL,
			"CURRENT_MODEL_SOURCE": "LEGACY_PROCEDURAL_FINAL",
			"classification": CLASS_DEPRECATED,
		}
	return {"path": explicit, "source": "MISSING", "tier": "MISSING", "CURRENT_MODEL_SOURCE": "MISSING"}


static func resolve_animation_root(fighter_id: String) -> Dictionary:
	var procedural := "res://content/fighters/%s/animations/procedural" % fighter_id
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(procedural)):
		return {
			"root": procedural,
			"source": STATUS_PROCEDURAL_ANIM,
			"CURRENT_ANIMATION_SOURCE": "PROCEDURAL_RUNTIME_ANIMATION",
		}
	return {
		"root": "res://data/fighters/%s_animations.json" % fighter_id,
		"source": "LEGACY_MANIFEST",
		"CURRENT_ANIMATION_SOURCE": "PROCEDURAL_RUNTIME_ANIMATION",
	}


static func note_canonical_failure() -> void:
	CANONICAL_MODEL_LOAD_FAILURES += 1


static func note_canonical_recovery() -> void:
	CANONICAL_MODEL_RECOVERIES += 1


static func note_emergency_fallback() -> void:
	EMERGENCY_FALLBACK_USES += 1


static func note_legacy_fallback() -> void:
	LEGACY_FALLBACK_USES += 1
	PLAYER_VISIBLE_LEGACY_BATTLE_BODY_OCCURRENCES += 1


static func telemetry_snapshot() -> Dictionary:
	return {
		"PLAYER_VISIBLE_LEGACY_MODEL_OCCURRENCES": PLAYER_VISIBLE_LEGACY_MODEL_OCCURRENCES,
		"PLAYER_VISIBLE_LEGACY_CARD_OCCURRENCES": PLAYER_VISIBLE_LEGACY_CARD_OCCURRENCES,
		"PLAYER_VISIBLE_LEGACY_BATTLE_BODY_OCCURRENCES": PLAYER_VISIBLE_LEGACY_BATTLE_BODY_OCCURRENCES,
		"PLAYER_VISIBLE_LEGACY_MOVE_PREVIEW_OCCURRENCES": PLAYER_VISIBLE_LEGACY_MOVE_PREVIEW_OCCURRENCES,
		"PLAYER_VISIBLE_LEGACY_VICTORY_OCCURRENCES": PLAYER_VISIBLE_LEGACY_VICTORY_OCCURRENCES,
		"CANONICAL_MODEL_LOAD_FAILURES": CANONICAL_MODEL_LOAD_FAILURES,
		"CANONICAL_MODEL_RECOVERIES": CANONICAL_MODEL_RECOVERIES,
		"EMERGENCY_FALLBACK_USES": EMERGENCY_FALLBACK_USES,
		"LEGACY_FALLBACK_USES": LEGACY_FALLBACK_USES,
	}


static func truth_flags_from_observation(model: Node = null) -> Dictionary:
	if model != null and model.has_method("truth_flags"):
		return model.truth_flags()
	return {
		"PROCEDURAL_CHARACTER_RUNTIME_PASS": false,
		"PROCEDURAL_RUNTIME_ANIMATION_PASS": false,
		"FINAL_CHARACTER_ART_PASS": false,
		"FINAL_HUMAN_AUTHORED_ANIMATION_PASS": false,
		"HUMAN_ART_DIRECTION_APPROVAL": false,
		"CURRENT_MODEL_SOURCE": "UNOBSERVED",
		"CURRENT_ANIMATION_SOURCE": "UNOBSERVED",
	}


static func truth_flags() -> Dictionary:
	return truth_flags_from_observation()
