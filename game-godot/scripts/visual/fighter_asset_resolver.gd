extends RefCounted
class_name FighterAssetResolver

## Canonical fighter presentation authority (Wave020 CP2).
## One resolve API for all player-facing contexts. Legacy paths are classified
## and rejected for normal gameplay (DEV_ONLY / TEST_ONLY / HISTORICAL / DEPRECATED).

const STATUS_PROCEDURAL := "PROCEDURAL_PRODUCTION_PROXY"
const STATUS_PROCEDURAL_ANIM := "PROCEDURAL_RUNTIME_ANIMATION"
const STATUS_STAGING := "HUMAN_CANDIDATE"
const STATUS_APPROVED := "HUMAN_APPROVED"
const STATUS_ACCEPTED := "CURRENT_ACCEPTED_ART"
const STATUS_FALLBACK := "PROCEDURAL_FALLBACK"
## Staging resolver chain: HUMAN_APPROVED → HUMAN_CANDIDATE → CURRENT_ACCEPTED_ART → PROCEDURAL_FALLBACK.
## GENERATED_EXPERIMENT_EXCLUDED — never part of the automatic fallback chain.

const CLASS_CURRENT := "CURRENT_PLAYER_FACING"
const CLASS_DEV := "DEV_ONLY"
const CLASS_TEST := "TEST_ONLY"
const CLASS_HISTORICAL := "HISTORICAL"
const CLASS_DEPRECATED := "DEPRECATED"
const CLASS_RESEARCH := "RESEARCH_ONLY"

## Salvage invariant: PR #106 generated roster never ships from this branch.
const PR106_GENERATED_ROSTER_NOT_SHIPPING := true

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
	if path.contains("human_art_staging"):
		return CLASS_DEV
	if path.contains("generated_production") or path.contains("generated_art") or path.contains("/generated/"):
		return CLASS_RESEARCH
	if path.contains("_generated_production.glb"):
		return CLASS_RESEARCH
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
	if staging_review_enabled() and (classification == CLASS_DEV) and path.contains("human_art_staging"):
		# Staging review may show HUMAN_CANDIDATE / HUMAN_APPROVED. Production default is unchanged.
		pass
	elif classification != CLASS_CURRENT and is_player_build():
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
	var presentation := str(model.get("CURRENT_MODEL_SOURCE", model.get("source", "MISSING")))
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
		"CURRENT_MODEL_SOURCE": presentation,
		"ACTIVE_CHARACTER_PRESENTATION": presentation,
		"ART_SOURCE": art_source_public_label(str(model.get("source", "")), path),
		"PR106_GENERATED_ROSTER_NOT_SHIPPING": PR106_GENERATED_ROSTER_NOT_SHIPPING,
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


const MODE_A_PACKED_PATH := "res://content/review/mode_a_integration_baseline.json"
const MODE_B_PACKED_PATH := "res://content/review/mode_b_human_candidates_review.json"


static func _env_flag(name: String) -> bool:
	var env := str(OS.get_environment(name))
	return env == "1" or env.to_lower() == "true"


static func _read_packed_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


static func _packed_mode_a() -> Dictionary:
	return _read_packed_json(MODE_A_PACKED_PATH)


static func _packed_review() -> Dictionary:
	var mode_b := _read_packed_json(MODE_B_PACKED_PATH)
	if not mode_b.is_empty():
		return mode_b
	return _packed_mode_a()


static func _review_flag(name: String) -> bool:
	## Env defaults remain 0. Packed Mode A marker is review-build only.
	if _env_flag(name):
		return true
	var packed := _packed_review()
	if packed.is_empty():
		return false
	if name == "MODE_B_HUMAN_ART_QUALITY_REVIEW":
		return false
	var value: Variant = packed.get(name, false)
	return value == true or str(value) == "1"


static func human_art_staging_enabled() -> bool:
	return _review_flag("HUMAN_ART_STAGING")


static func full_roster_review_enabled() -> bool:
	## HUMAN_ART_FULL_ROSTER_REVIEW=0 default. Owner-review / Mode A overlay only.
	return _review_flag("HUMAN_ART_FULL_ROSTER_REVIEW") or _review_flag("MODE_A_INTEGRATION_BASELINE")


static func staging_review_enabled() -> bool:
	return human_art_staging_enabled() or full_roster_review_enabled()


static func staging_glb_path(fighter_id: String) -> String:
	return "res://content/human_art_staging/%s/%s.glb" % [fighter_id, fighter_id]


static func approved_glb_path(fighter_id: String) -> String:
	return "res://content/human_art_staging/%s/approved/%s.glb" % [fighter_id, fighter_id]


static func art_source_public_label(source: String, path: String = "") -> String:
	## Never show raw internal paths in review UI.
	if source == STATUS_APPROVED:
		return "HUMAN_APPROVED"
	if source == STATUS_STAGING or path.contains("human_art_staging"):
		return "HUMAN_CANDIDATE"
	if source == STATUS_ACCEPTED or source == "PROCEDURAL_PRODUCTION_PROXY" or path.ends_with("_procedural_proxy.glb"):
		return "CURRENT_ACCEPTED_ART"
	if source == STATUS_FALLBACK or path.contains("procedural_final") or path.contains("/proxy/"):
		return "PROCEDURAL_FALLBACK"
	if path.contains("generated_production") or path.contains("generated_art"):
		return "GENERATED_EXPERIMENT"
	return "CURRENT_ACCEPTED_ART"


static func resolve_model_path(fighter_id: String, fighter_data: Dictionary = {}) -> Dictionary:
	var explicit := str(fighter_data.get("modelPath", ""))
	# Approved / final / vroid — only if path itself is not a procedural_final legacy alias.
	if explicit.contains("/approved/") or (explicit.contains("/final/") and not explicit.contains("procedural_final")):
		return {"path": explicit, "source": "FINAL_CUSTOM", "tier": "FINAL_CUSTOM", "CURRENT_MODEL_SOURCE": "FINAL_CUSTOM", "ACTIVE_CHARACTER_PRESENTATION": "FINAL_CUSTOM"}
	if explicit.contains("vroid") or explicit.contains("/approved_vroid/"):
		return {"path": explicit, "source": "APPROVED_VROID", "tier": "APPROVED_VROID", "CURRENT_MODEL_SOURCE": "APPROVED_VROID", "ACTIVE_CHARACTER_PRESENTATION": "APPROVED_VROID"}
	# Staging is opt-in only. Default HUMAN_ART_STAGING=0 / HUMAN_ART_FULL_ROSTER_REVIEW=0.
	# Priority when enabled: HUMAN_APPROVED → HUMAN_CANDIDATE → CURRENT_ACCEPTED_ART → PROCEDURAL_FALLBACK.
	# GENERATED_EXPERIMENT_EXCLUDED from this chain.
	if staging_review_enabled():
		var approved := approved_glb_path(fighter_id)
		if ResourceLoader.exists(approved) or FileAccess.file_exists(approved):
			return {
				"path": approved,
				"source": STATUS_APPROVED,
				"tier": STATUS_APPROVED,
				"CURRENT_MODEL_SOURCE": STATUS_APPROVED,
				"ACTIVE_CHARACTER_PRESENTATION": "HUMAN_APPROVED",
				"classification": CLASS_DEV,
				"shipping": false,
				"ART_SOURCE": "HUMAN_APPROVED",
			}
		var staged := staging_glb_path(fighter_id)
		if ResourceLoader.exists(staged) or FileAccess.file_exists(staged):
			return {
				"path": staged,
				"source": STATUS_STAGING,
				"tier": STATUS_STAGING,
				"CURRENT_MODEL_SOURCE": STATUS_STAGING,
				"ACTIVE_CHARACTER_PRESENTATION": "HUMAN_CANDIDATE",
				"classification": CLASS_DEV,
				"shipping": false,
				"ART_SOURCE": "HUMAN_CANDIDATE",
			}
	# Generated V2–V9 research assets are never selected here.
	var proxy := canonical_glb_path(fighter_id)
	if ResourceLoader.exists(proxy):
		return {
			"path": proxy,
			"source": "PROCEDURAL_PRODUCTION_PROXY",
			"tier": STATUS_PROCEDURAL,
			"CURRENT_MODEL_SOURCE": "PROCEDURAL_PRODUCTION_PROXY",
			"ACTIVE_CHARACTER_PRESENTATION": "CURRENT_ACCEPTED_ART",
			"ART_SOURCE": "CURRENT_ACCEPTED_ART",
			"PR106_GENERATED_ROSTER_NOT_SHIPPING": PR106_GENERATED_ROSTER_NOT_SHIPPING,
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
			"ART_SOURCE": "PROCEDURAL_FALLBACK",
		}
	return {"path": explicit, "source": "MISSING", "tier": "MISSING", "CURRENT_MODEL_SOURCE": "MISSING", "ART_SOURCE": "PROCEDURAL_FALLBACK"}


static func resolve_animation_root(fighter_id: String) -> Dictionary:
	var procedural := "res://content/fighters/%s/animations/procedural" % fighter_id
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(procedural)):
		return {
			"root": procedural,
			"source": STATUS_PROCEDURAL_ANIM,
			"CURRENT_ANIMATION_SOURCE": "PROCEDURAL_RUNTIME_ANIMATION",
			"ACTIVE_CHARACTER_PRESENTATION": "CURRENT_ACCEPTED_ART",
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


static func roster_review_counts() -> Dictionary:
	var candidate := 0
	var validated := 0
	var approved := 0
	var ids := ["ember-vale", "rook-ironside", "juno-spark", "kaia-windrow", "nix-calder", "orion-vell", "vesper-nyx"]
	for fighter_id in ids:
		var manifest_path := "res://content/human_art_staging/%s/candidate_manifest.json" % fighter_id
		if FileAccess.file_exists(manifest_path):
			var file := FileAccess.open(manifest_path, FileAccess.READ)
			if file:
				var parsed: Variant = JSON.parse_string(file.get_as_text())
				file.close()
				if typeof(parsed) == TYPE_DICTIONARY:
					var status := str(parsed.get("candidate_status", "MISSING"))
					if status == "HUMAN_CANDIDATE":
						candidate += 1
					if bool(parsed.get("validated", false)):
						validated += 1
					# owner_approved is owner-only; automation never increments this.
					if bool(parsed.get("owner_approved", false)):
						approved += 1
		var staged := staging_glb_path(fighter_id)
		if (ResourceLoader.exists(staged) or FileAccess.file_exists(staged)) and not FileAccess.file_exists(manifest_path):
			candidate += 1
	return {
		"candidate": candidate,
		"validated": validated,
		"owner_approved": approved,
		"total": ids.size(),
		"label": "Candidate: %d/7\nValidated: %d/7\nOwner approved: %d/7" % [candidate, validated, approved],
	}
