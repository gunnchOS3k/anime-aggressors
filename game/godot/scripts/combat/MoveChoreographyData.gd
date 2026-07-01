extends RefCounted
class_name MoveChoreographyData

var move_id: String
var animation_name: String
var startup_frames: int
var active_frames: int
var recovery_frames: int
var hitbox_socket: String
var vfx_socket: String
var camera_event: String
var audio_event: String
var hitstop_frames: int
var damage: float
var base_knockback: float
var knockback_growth: float
var launch_angle_degrees: float
var cancel_window: int
var on_hit_follow_up: String

func _init(data: Dictionary = {}) -> void:
	move_id = String(data.get("move_id", "neutral_attack"))
	animation_name = String(data.get("animation_name", move_id))
	startup_frames = int(data.get("startup_frames", data.get("startup", 4)))
	active_frames = int(data.get("active_frames", data.get("active", 3)))
	recovery_frames = int(data.get("recovery_frames", data.get("recovery", 10)))
	hitbox_socket = String(data.get("hitbox_socket", data.get("hit_socket", "right_hand")))
	vfx_socket = String(data.get("vfx_socket", hitbox_socket))
	camera_event = String(data.get("camera_event", "light_impact"))
	audio_event = String(data.get("audio_event", ""))
	hitstop_frames = int(data.get("hitstop_frames", data.get("hitstop", 4)))
	damage = float(data.get("damage", 6.0))
	base_knockback = float(data.get("base_knockback", 420.0))
	knockback_growth = float(data.get("knockback_growth", 1.05))
	launch_angle_degrees = float(data.get("launch_angle_degrees", data.get("knockback_angle", 35.0)))
	cancel_window = int(data.get("cancel_window", 0))
	on_hit_follow_up = String(data.get("on_hit_follow_up", ""))

func to_dictionary() -> Dictionary:
	return {
		"move_id": move_id,
		"animation_name": animation_name,
		"startup_frames": startup_frames,
		"active_frames": active_frames,
		"recovery_frames": recovery_frames,
		"hitbox_socket": hitbox_socket,
		"vfx_socket": vfx_socket,
		"camera_event": camera_event,
		"audio_event": audio_event,
		"hitstop_frames": hitstop_frames,
		"damage": damage,
		"base_knockback": base_knockback,
		"knockback_growth": knockback_growth,
		"launch_angle_degrees": launch_angle_degrees,
		"cancel_window": cancel_window,
		"on_hit_follow_up": on_hit_follow_up,
	}
