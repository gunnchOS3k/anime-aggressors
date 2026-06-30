extends RefCounted
class_name AttackSocketTimeline

## Maps move frame windows to limb sockets for hitboxes and VFX.

const TIMELINES := {
	"neutral_attack": [
		{"frame": 0, "socket": "right_hand_socket", "phase": "startup"},
		{"frame": 4, "socket": "right_hand_socket", "phase": "active"},
		{"frame": 7, "socket": "right_hand_socket", "phase": "recovery"},
	],
	"side_attack": [
		{"frame": 0, "socket": "right_hand_socket", "phase": "startup"},
		{"frame": 5, "socket": "weapon_socket", "phase": "active"},
	],
	"down_attack": [
		{"frame": 5, "socket": "right_foot_socket", "phase": "active"},
	],
}

static func socket_at(move_id: String, frame: int) -> String:
	var timeline: Array = TIMELINES.get(move_id, TIMELINES["neutral_attack"])
	var chosen := "right_hand_socket"
	for entry in timeline:
		if frame >= int(entry["frame"]):
			chosen = String(entry["socket"])
	return chosen
