extends RefCounted
class_name FighterAssetContract

const DEBUG_FALLBACK_LABEL := "DEBUG FALLBACK — NOT PRODUCTION MODEL"

const REQUIRED_ANIMATIONS := [
	"idle", "walk", "run", "dash", "jump", "double_jump", "fall", "land",
	"neutral_attack", "side_attack", "up_attack", "down_attack",
	"neutral_special", "side_special", "up_special", "down_special",
	"aura_charge", "hitstun_light", "hitstun_heavy", "launch", "victory", "defeat",
]

const REQUIRED_SOCKETS := [
	"root", "chest", "head",
	"left_hand", "right_hand", "left_foot", "right_foot",
	"weapon_tip", "aura_core", "hit_spark_center",
]

static func glb_path(fighter_id: String) -> String:
	return "res://assets/fighters/glb/%s.glb" % fighter_id

static func has_production_glb(fighter_id: String) -> bool:
	return ResourceLoader.exists(glb_path(fighter_id))

static func validate(fighter_id: String, root: Node) -> Dictionary:
	var errors: Array[String] = []
	if not has_production_glb(fighter_id):
		errors.append("missing production GLB for %s" % fighter_id)
	for socket_name in REQUIRED_SOCKETS:
		if root != null and not _has_socket(root, socket_name):
			errors.append("missing socket %s" % socket_name)
	return {
		"fighter_id": fighter_id,
		"is_production": errors.is_empty(),
		"errors": errors,
		"fallback_label": DEBUG_FALLBACK_LABEL,
	}

static func _has_socket(root: Node, socket_name: String) -> bool:
	if root == null:
		return false
	if root.has_node(socket_name):
		return true
	if root.find_child(socket_name, true, false) != null:
		return true
	return FighterSocketMap.aliases_for(socket_name).any(
		func(alias: String) -> bool: return root.find_child(alias, true, false) != null
	)
