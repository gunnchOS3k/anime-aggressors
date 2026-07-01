extends RefCounted
class_name FighterSocketMap

## Canonical socket names and rig aliases (production GLB + fallback rig).

const SOCKET_ALIASES := {
	"root": ["RigRoot", "hips"],
	"chest": ["chest", "spine", "torso"],
	"head": ["head"],
	"left_hand": ["left_hand", "left_hand_socket"],
	"right_hand": ["right_hand", "right_hand_socket"],
	"left_fist": ["left_hand", "left_hand_socket"],
	"right_fist": ["right_hand", "right_hand_socket"],
	"left_foot": ["left_foot", "left_foot_socket"],
	"right_foot": ["right_foot", "right_foot_socket"],
	"weapon_tip": ["weapon_socket", "weapon_tip"],
	"aura_core": ["aura_socket", "aura_core", "chest_aura"],
	"hit_spark_center": ["hit_center_socket", "hit_spark_center"],
	"center_mass": ["hit_center_socket", "chest", "center_mass"],
	"ground_contact": ["right_foot_socket", "left_foot_socket", "ground_contact"],
}

static func aliases_for(socket_name: String) -> PackedStringArray:
	var list: Array = SOCKET_ALIASES.get(socket_name, [socket_name])
	return PackedStringArray(list)

static func resolve(root: Node, socket_name: String) -> Node3D:
	if root == null:
		return null
	for alias in aliases_for(socket_name):
		var found := root.find_child(String(alias), true, false)
		if found is Node3D:
			return found as Node3D
	return null
