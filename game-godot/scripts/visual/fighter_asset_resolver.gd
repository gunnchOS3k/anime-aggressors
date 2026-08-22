extends RefCounted
class_name FighterAssetResolver

## Resolve fighter model/animation sources: final custom > VRoid > procedural proxy.

const STATUS_PROCEDURAL := "PROCEDURAL_PRODUCTION_PROXY"
const STATUS_PROCEDURAL_ANIM := "PROCEDURAL_RUNTIME_ANIMATION"

static func resolve_model_path(fighter_id: String, fighter_data: Dictionary = {}) -> Dictionary:
	var explicit := str(fighter_data.get("modelPath", ""))
	if explicit.contains("/approved/") or explicit.contains("/final/"):
		return {"path": explicit, "source": "FINAL_CUSTOM", "tier": "FINAL_CUSTOM"}
	if explicit.contains("vroid") or explicit.contains("/approved_vroid/"):
		return {"path": explicit, "source": "APPROVED_VROID", "tier": "APPROVED_VROID"}
	var proxy := "res://content/fighters/%s/model/%s_procedural_proxy.glb" % [fighter_id, fighter_id]
	if ResourceLoader.exists(proxy):
		return {
			"path": proxy,
			"source": "PROCEDURAL_PRODUCTION_PROXY",
			"tier": STATUS_PROCEDURAL,
			"CURRENT_MODEL_SOURCE": "PROCEDURAL_PRODUCTION_PROXY",
		}
	var legacy := "res://assets/characters/procedural_final/%s.glb" % fighter_id
	if ResourceLoader.exists(legacy):
		return {
			"path": legacy,
			"source": "PROCEDURAL_PRODUCTION_PROXY",
			"tier": STATUS_PROCEDURAL,
			"CURRENT_MODEL_SOURCE": "PROCEDURAL_PRODUCTION_PROXY",
		}
	return {"path": explicit, "source": "MISSING", "tier": "MISSING"}


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


static func truth_flags() -> Dictionary:
	return {
		"PROCEDURAL_CHARACTER_RUNTIME_PASS": true,
		"PROCEDURAL_RUNTIME_ANIMATION_PASS": true,
		"FINAL_CHARACTER_ART_PASS": false,
		"FINAL_HUMAN_AUTHORED_ANIMATION_PASS": false,
		"HUMAN_ART_DIRECTION_APPROVAL": false,
		"CURRENT_MODEL_SOURCE": "PROCEDURAL_PRODUCTION_PROXY",
		"CURRENT_ANIMATION_SOURCE": "PROCEDURAL_RUNTIME_ANIMATION",
	}
