extends RefCounted
class_name MoveDefinition

enum MoveType { JAB, TILT, SPECIAL, HEAVY }

const JAB := {
	"name": "jab",
	"startup": 0.08,
	"active": 0.06,
	"recovery": 0.18,
	"base_damage": 3.5,
	"base_knockback": 120.0,
	"knockback_growth": 1.10
}

const TILT := {
	"name": "tilt",
	"startup": 0.12,
	"active": 0.09,
	"recovery": 0.23,
	"base_damage": 6.0,
	"base_knockback": 180.0,
	"knockback_growth": 1.25
}

const SPECIAL := {
	"name": "special",
	"startup": 0.20,
	"active": 0.12,
	"recovery": 0.30,
	"base_damage": 9.0,
	"base_knockback": 240.0,
	"knockback_growth": 1.42
}

const HEAVY := {
	"name": "heavy",
	"startup": 0.30,
	"active": 0.10,
	"recovery": 0.38,
	"base_damage": 13.0,
	"base_knockback": 320.0,
	"knockback_growth": 1.60
}

static func get_move(move_type: MoveType) -> Dictionary:
	match move_type:
		MoveType.JAB:
			return JAB.duplicate(true)
		MoveType.TILT:
			return TILT.duplicate(true)
		MoveType.SPECIAL:
			return SPECIAL.duplicate(true)
		MoveType.HEAVY:
			return HEAVY.duplicate(true)
		_:
			return JAB.duplicate(true)
