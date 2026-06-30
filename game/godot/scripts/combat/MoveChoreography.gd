extends RefCounted
class_name MoveChoreography

const MOVES := {
	"ember_neutral_attack": {
		"move_id": "ember_neutral_attack",
		"startup": 4,
		"active": 3,
		"recovery": 10,
		"hit_socket": "right_fist",
		"vfx_socket": "right_fist",
		"trail": "flame_arc",
		"hitstop": 4,
		"knockback_angle": 35,
		"knockback_growth": 1.05,
	},
	"neutral_attack": {
		"move_id": "neutral_attack",
		"startup": 4,
		"active": 3,
		"recovery": 10,
		"hit_socket": "right_fist",
		"vfx_socket": "right_fist",
		"trail": "default_arc",
		"hitstop": 4,
		"knockback_angle": 35,
		"knockback_growth": 1.05,
	},
	"side_attack": {
		"move_id": "side_attack",
		"startup": 5,
		"active": 4,
		"recovery": 12,
		"hit_socket": "right_fist",
		"vfx_socket": "weapon_tip",
		"trail": "forward_slash",
		"hitstop": 5,
		"knockback_angle": 20,
		"knockback_growth": 1.08,
	},
	"up_attack": {
		"move_id": "up_attack",
		"startup": 6,
		"active": 3,
		"recovery": 14,
		"hit_socket": "right_fist",
		"vfx_socket": "right_fist",
		"trail": "uppercut_arc",
		"hitstop": 6,
		"knockback_angle": 78,
		"knockback_growth": 1.1,
	},
	"down_attack": {
		"move_id": "down_attack",
		"startup": 5,
		"active": 4,
		"recovery": 11,
		"hit_socket": "right_foot",
		"vfx_socket": "right_foot",
		"trail": "ground_sweep",
		"hitstop": 5,
		"knockback_angle": -25,
		"knockback_growth": 1.06,
	},
}

static func get_move(move_id: String) -> MoveFrameData:
	if MOVES.has(move_id):
		return MoveFrameData.new(MOVES[move_id])
	return MoveFrameData.new(MOVES["neutral_attack"])
