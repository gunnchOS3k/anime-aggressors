extends RefCounted
class_name MoveChoreography

const MOVES := {
	"ember_neutral_attack": {
		"move_id": "ember_neutral_attack",
		"animation_name": "neutral_attack",
		"startup_frames": 4,
		"active_frames": 3,
		"recovery_frames": 10,
		"hitbox_socket": "right_hand",
		"vfx_socket": "right_hand",
		"camera_event": "light_impact",
		"audio_event": "ember_jab_hit",
		"hitstop_frames": 4,
		"damage": 7.0,
		"base_knockback": 420.0,
		"knockback_growth": 1.05,
		"launch_angle_degrees": 35.0,
	},
	"neutral_attack": {
		"move_id": "neutral_attack",
		"animation_name": "neutral_attack",
		"startup_frames": 4,
		"active_frames": 3,
		"recovery_frames": 10,
		"hitbox_socket": "right_hand",
		"vfx_socket": "right_hand",
		"camera_event": "light_impact",
		"audio_event": "jab_hit",
		"hitstop_frames": 4,
		"damage": 6.0,
		"base_knockback": 420.0,
		"knockback_growth": 1.05,
		"launch_angle_degrees": 35.0,
	},
	"side_attack": {
		"move_id": "side_attack",
		"animation_name": "side_attack",
		"startup_frames": 5,
		"active_frames": 4,
		"recovery_frames": 12,
		"hitbox_socket": "right_hand",
		"vfx_socket": "weapon_tip",
		"camera_event": "medium_impact",
		"audio_event": "side_hit",
		"hitstop_frames": 5,
		"damage": 9.0,
		"base_knockback": 480.0,
		"knockback_growth": 1.08,
		"launch_angle_degrees": 20.0,
	},
	"up_attack": {
		"move_id": "up_attack",
		"animation_name": "up_attack",
		"startup_frames": 6,
		"active_frames": 3,
		"recovery_frames": 14,
		"hitbox_socket": "right_hand",
		"vfx_socket": "right_hand",
		"camera_event": "launch_impact",
		"audio_event": "upper_hit",
		"hitstop_frames": 6,
		"damage": 10.0,
		"base_knockback": 520.0,
		"knockback_growth": 1.1,
		"launch_angle_degrees": 78.0,
	},
	"down_attack": {
		"move_id": "down_attack",
		"animation_name": "down_attack",
		"startup_frames": 5,
		"active_frames": 4,
		"recovery_frames": 11,
		"hitbox_socket": "right_foot",
		"vfx_socket": "right_foot",
		"camera_event": "sweep_impact",
		"audio_event": "down_hit",
		"hitstop_frames": 5,
		"damage": 8.0,
		"base_knockback": 440.0,
		"knockback_growth": 1.06,
		"launch_angle_degrees": -25.0,
	},
}

static func get_move(move_id: String) -> MoveFrameData:
	if MOVES.has(move_id):
		return MoveFrameData.new(MOVES[move_id])
	return MoveFrameData.new(MOVES["neutral_attack"])

static func get_choreography(move_id: String) -> MoveChoreographyData:
	if MOVES.has(move_id):
		return MoveChoreographyData.new(MOVES[move_id])
	return MoveChoreographyData.new(MOVES["neutral_attack"])
