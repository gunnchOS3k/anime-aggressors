extends RefCounted

## Headless unit-ish checks for combat depth + device role contracts.
## Preload class scripts: Godot `--script` / `-s` runs before global class_name registration.

const _CombatMath = preload("res://scripts/combat/combat_math.gd")
const _FighterStates = preload("res://scripts/fighters/fighter_states.gd")
const _SmokeAssert = preload("res://tests/smoke_assert.gd")


static func run() -> bool:
	_SmokeAssert.reset()

	# CombatMath DI shifts launch sideways.
	var base := Vector2(10.0, -8.0)
	var di_right: Vector2 = _CombatMath.apply_di(base, 1.0, 0.0, "heavy")
	_SmokeAssert.ok(di_right.x > base.x, "DI right should increase vx")
	var di_left: Vector2 = _CombatMath.apply_di(base, -1.0, 0.0, "heavy")
	_SmokeAssert.ok(di_left.x < base.x, "DI left should decrease vx")
	var light: Vector2 = _CombatMath.apply_di(base, 1.0, 0.0, "light")
	_SmokeAssert.ok(is_equal_approx(light.x, base.x), "light DI should be no-op")

	# Short hop is lower impulse magnitude.
	var full := 620.0
	var shortv: float = _CombatMath.short_hop_velocity(full)
	_SmokeAssert.ok(absf(shortv) < absf(full), "short hop weaker than full hop")
	_SmokeAssert.ok(_CombatMath.JUMP_SQUAT_FRAMES >= 2, "jump squat frames present")

	# Landing lag ordering.
	_SmokeAssert.ok(
		_CombatMath.landing_lag_seconds(true, true) > _CombatMath.landing_lag_seconds(false, false),
		"fast-fall aerial lag > normal"
	)

	# Device role matrix on disk.
	var path := "res://data/device/device_role_matrix.json"
	_SmokeAssert.ok(FileAccess.file_exists(path), "device role matrix exists")
	var f := FileAccess.open(path, FileAccess.READ)
	var matrix: Dictionary = JSON.parse_string(f.get_as_text())
	var roles: Dictionary = matrix.get("device_roles", {})
	for role_id in ["student_14_5", "handheld_hybrid", "ds_xl_coder", "edge_io_rings"]:
		_SmokeAssert.ok(roles.has(role_id), "matrix has %s" % role_id)
		var p: Dictionary = roles[role_id]
		_SmokeAssert.ok(str(p.get("fx", "")) != "", "%s fx set" % role_id)

	# Fighter states include air dodge + ledge hang.
	var all_states: Array = _FighterStates.all_states()
	_SmokeAssert.ok(_FighterStates.AIR_DODGE in all_states, "AIR_DODGE registered")
	_SmokeAssert.ok(_FighterStates.LEDGE_HANG in all_states, "LEDGE_HANG registered")
	_SmokeAssert.ok(_FighterStates.JUMP_SQUAT in all_states, "JUMP_SQUAT registered")

	return _SmokeAssert.passed()
