extends RefCounted
class_name FighterSocketMap

## Canonical socket names and rig aliases (production GLB + fallback rig).

const SOCKET_ALIASES := {
	"root": ["RigRoot", "hips"],
	"chest": ["chest", "spine"],
	"head": ["head"],
	"left_hand": ["left_hand", "left_hand_socket"],
	"right_hand": ["right_hand", "right_hand_socket"],
	"left_foot": ["left_foot", "left_foot_socket"],
	"right_foot": ["right_foot", "right_foot_socket"],
	"weapon_tip": ["weapon_socket", "weapon_tip"],
	"aura_core": ["aura_socket", "aura_core"],
	"hit_spark_center": ["hit_center_socket", "hit_spark_center"],
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
