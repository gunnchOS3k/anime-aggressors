extends RefCounted
class_name MoveFrameData

var move_id: String
var startup: int
var active: int
var recovery: int
var hit_socket: String
var vfx_socket: String
var trail: String
var hitstop: int
var knockback_angle: float
var knockback_growth: float

func _init(data: Dictionary = {}) -> void:
	move_id = String(data.get("move_id", "neutral_attack"))
	startup = int(data.get("startup", 4))
	active = int(data.get("active", 3))
	recovery = int(data.get("recovery", 10))
	hit_socket = String(data.get("hit_socket", "right_fist"))
	vfx_socket = String(data.get("vfx_socket", "right_fist"))
	trail = String(data.get("trail", "default_arc"))
	hitstop = int(data.get("hitstop", 4))
	knockback_angle = float(data.get("knockback_angle", 35.0))
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
