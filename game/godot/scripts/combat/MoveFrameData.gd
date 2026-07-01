extends RefCounted
class_name MoveFrameData

var move_id: String
var startup: int
var active: int
var recovery: int
var hit_socket: String
var vfx_socket: String
var hurtbox_profile: String
var trail: String
var hitstop: int
var hitlag: int
var hitstun: int
var knockback_angle: float
var knockback_growth: float

func _init(data: Dictionary = {}) -> void:
	move_id = String(data.get("move_id", "neutral_attack"))
	startup = int(data.get("startup_frames", data.get("startup", 4)))
	active = int(data.get("active_frames", data.get("active", 3)))
	recovery = int(data.get("recovery_frames", data.get("recovery", 10)))
	hit_socket = String(data.get("hit_socket", data.get("hitbox_socket", "right_fist")))
	vfx_socket = String(data.get("vfx_socket", hit_socket))
	hurtbox_profile = String(data.get("hurtbox_profile", "standard"))
	trail = String(data.get("trail", "default_arc"))
	hitstop = int(data.get("hitstop_frames", data.get("hitstop", data.get("hitlag", 4))))
	hitlag = int(data.get("hitlag", hitstop))
	hitstun = int(data.get("hitstun", 10))
	knockback_angle = float(data.get("launch_angle_degrees", data.get("launch_angle", data.get("knockback_angle", 35.0))))
	knockback_growth = float(data.get("knockback_growth", 1.05))

func to_dictionary() -> Dictionary:
	return {
		"move_id": move_id,
		"startup": startup,
		"active": active,
		"recovery": recovery,
		"hit_socket": hit_socket,
		"vfx_socket": vfx_socket,
		"trail": trail,
		"hitstop": hitstop,
		"knockback_angle": knockback_angle,
		"knockback_growth": knockback_growth,
	}
