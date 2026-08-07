extends RefCounted

## Headless unit-ish checks for combat depth + device role contracts.

static func run() -> bool:
	var Assert = preload("res://tests/smoke_assert.gd")
	Assert.reset()

	# CombatMath DI shifts launch sideways.
	var base := Vector2(10.0, -8.0)
	var di_right := CombatMath.apply_di(base, 1.0, 0.0, "heavy")
	Assert.that(di_right.x > base.x, "DI right should increase vx")
	var di_left := CombatMath.apply_di(base, -1.0, 0.0, "heavy")
	Assert.that(di_left.x < base.x, "DI left should decrease vx")
	var light := CombatMath.apply_di(base, 1.0, 0.0, "light")
	Assert.that(is_equal_approx(light.x, base.x), "light DI should be no-op")

	# Short hop is lower impulse magnitude.
	var full := 620.0
	var shortv := CombatMath.short_hop_velocity(full)
	Assert.that(absf(shortv) < absf(full), "short hop weaker than full hop")
	Assert.that(CombatMath.JUMP_SQUAT_FRAMES >= 2, "jump squat frames present")

	# Landing lag ordering.
	Assert.that(
		CombatMath.landing_lag_seconds(true, true) > CombatMath.landing_lag_seconds(false, false),
		"fast-fall aerial lag > normal"
	)

	# Device role matrix on disk.
	var path := "res://data/device/device_role_matrix.json"
	Assert.that(FileAccess.file_exists(path), "device role matrix exists")
	var f := FileAccess.open(path, FileAccess.READ)
	var matrix: Dictionary = JSON.parse_string(f.get_as_text())
	var roles: Dictionary = matrix.get("device_roles", {})
	for role_id in ["student_14_5", "handheld_hybrid", "ds_xl_coder", "edge_io_rings"]:
		Assert.that(roles.has(role_id), "matrix has %s" % role_id)
		var p: Dictionary = roles[role_id]
		Assert.that(str(p.get("fx", "")) != "", "%s fx set" % role_id)

	# Fighter states include air dodge + ledge hang.
	Assert.that(FighterStates.AIR_DODGE in FighterStates.all_states(), "AIR_DODGE registered")
	Assert.that(FighterStates.LEDGE_HANG in FighterStates.all_states(), "LEDGE_HANG registered")
	Assert.that(FighterStates.JUMP_SQUAT in FighterStates.all_states(), "JUMP_SQUAT registered")

	return Assert.ok()
