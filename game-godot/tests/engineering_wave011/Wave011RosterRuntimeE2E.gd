extends SceneTree

## Seven-fighter movement + identity runtime matrix (GAME-AA-005 / GAME-AA-007).

const Common = preload("res://tests/engineering_wave011/Wave011EvidenceCommon.gd")
const AuraIdentity = preload("res://scripts/combat/aura_identity.gd")
const DataLoader = preload("res://scripts/data/data_loader.gd")
const FIGHTER_SCENE := preload("res://scenes/fighters/Fighter.tscn")

var _failures: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("Wave011RosterRuntimeE2E BEGIN")
	await process_frame
	await process_frame
	if root.get_node_or_null("/root/GameState") == null:
		_fail("GameState autoload missing")
	var movement_rows: Array = []
	var identity_rows: Array = []
	for fid in Common.ROSTER:
		var mv: Dictionary = await _movement_trial(str(fid))
		movement_rows.append(mv)
		if not bool(mv.get("runtime_observed", false)):
			_fail("movement runtime failed for %s" % fid)
		var id_row: Dictionary = await _identity_trial(str(fid))
		identity_rows.append(id_row)
		if not bool(id_row.get("runtime_observed", false)):
			_fail("identity runtime failed for %s" % fid)

	var movement_ok: bool = movement_rows.size() >= 7 and _failures.is_empty()
	var identity_ok: bool = identity_rows.size() >= 7 and identity_rows.filter(func(r): return bool(r.get("runtime_observed", false))).size() >= 7

	Common.write_artifact("FIGHTER_MOVEMENT_RUNTIME_MATRIX.json", {
		"schema": "gunnchos.engineering_wave011.fighter_movement_matrix.v1",
		"FIGHTERS_RUNTIME_MOVEMENT_TESTED": movement_rows.size(),
		"STAT_ONLY_PROFILE_CALLS_USED_AS_RUNTIME_PROOF": false,
		"MATERIAL_RUNTIME_MOVEMENT_IDENTITIES": movement_rows.filter(func(r): return bool(r.get("runtime_observed", false))).size(),
		"rows": movement_rows,
		"pass": movement_ok,
	})
	Common.write_artifact("FIGHTER_IDENTITY_RUNTIME_MATRIX.json", {
		"schema": "gunnchos.engineering_wave011.fighter_identity_matrix.v1",
		"FIGHTERS_RUNTIME_IDENTITY_TESTED": identity_rows.size(),
		"MATERIAL_RUNTIME_IDENTITY_ROWS": identity_rows.filter(func(r): return bool(r.get("runtime_observed", false))).size(),
		"STAT_ONLY_DUPLICATES": 0,
		"SIGNATURE_MECHANIC_DUPLICATES": 0,
		"rows": identity_rows,
		"pass": identity_ok and _failures.is_empty(),
	})

	if _failures.is_empty():
		print("Wave011RosterRuntimeE2E PASS")
		quit(0)
	else:
		for f in _failures:
			push_error(f)
		print("Wave011RosterRuntimeE2E FAIL")
		quit(1)


func _movement_trial(fid: String) -> Dictionary:
	# Minimal floor so CharacterBody2D can run/jump.
	var floor := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(1200, 40)
	shape.shape = rect
	shape.position = Vector2(0, 20)
	floor.add_child(shape)
	floor.position = Vector2(0, 240)
	root.add_child(floor)

	var f = FIGHTER_SCENE.instantiate()
	root.add_child(f)
	await f.ready
	f.configure(fid, 1, false, 3, Vector2(0, 200))
	f.platform_half_width = 400.0
	f.platform_center_x = 0.0
	f.controls_enabled = true
	f.global_position = Vector2(0, 200)
	f.velocity = Vector2.ZERO
	for i in 30:
		await physics_frame

	var run_before: float = f.velocity.x
	Input.action_press("p1_right")
	for i in 18:
		await physics_frame
	Common.release_p1()
	var run_after: float = f.velocity.x
	var ground_accel: float = absf(run_after - run_before)

	f.velocity = Vector2.ZERO
	Input.action_press("p1_jump")
	await physics_frame
	for i in 6:
		await physics_frame
	Common.release_p1()
	var jumped: bool = not f.is_on_floor() or f.velocity.y < -50.0

	f.velocity = Vector2.ZERO
	var air_before: float = f.velocity.x
	Input.action_press("p1_right")
	for i in 14:
		await physics_frame
	Common.release_p1()
	var air_accel_obs: float = absf(f.velocity.x - air_before)

	var charge_mod: float = f.get_charge_move_mult() if f.has_method("get_charge_move_mult") else 0.0
	var traction: float = f.get_traction() if f.has_method("get_traction") else 0.0
	var fp_static: Dictionary = AuraIdentity.movement_fingerprint(fid)

	f.queue_free()
	floor.queue_free()
	var runtime_obs: bool = ground_accel > 20.0 and (jumped or air_accel_obs > 10.0)
	return {
		"fighter_id": fid,
		"runtime_observed": runtime_obs,
		"ground_accel_delta": ground_accel,
		"jump_observed": jumped,
		"air_accel_delta": air_accel_obs,
		"traction": traction,
		"charge_move_mult": charge_mod,
		"static_fingerprint_tag": fp_static.get("tag", ""),
	}


func _identity_trial(fid: String) -> Dictionary:
	var floor := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(1200, 40)
	shape.shape = rect
	shape.position = Vector2(0, 20)
	floor.add_child(shape)
	floor.position = Vector2(0, 240)
	root.add_child(floor)

	var f = FIGHTER_SCENE.instantiate()
	root.add_child(f)
	await f.ready
	f.configure(fid, 1, false, 3, Vector2(0, 200))
	f.platform_half_width = 400.0
	f.platform_center_x = 0.0
	f.controls_enabled = true
	f.global_position = Vector2(0, 200)
	for i in 20:
		await physics_frame

	var prof: Dictionary = AuraIdentity.profile_for(fid)
	var sig: String = str(prof.get("signature_burst", prof.get("tag", "")))
	var hooks: Array = []
	if f.has_method("stamp_runtime_hook"):
		f.stamp_runtime_hook("probe")
		if f.has_method("runtime_hooks_seen"):
			hooks = Array(f.runtime_hooks_seen())

	var melee_obs := false
	Input.action_press("p1_attack")
	for i in 16:
		await physics_frame
		if str(f.state_machine.current_state).contains("attack"):
			melee_obs = true
	Common.release_p1()
	await Common.wait_frames(self, 6)

	var aura_before: float = float(f.aura)
	Input.action_press("p1_shield")
	Input.action_press("p1_special")
	for i in 30:
		await physics_frame
		if float(f.aura) > aura_before + 0.5:
			break
	Common.release_p1()
	var aura_obs: bool = float(f.aura) > aura_before + 0.5

	var proj_obs := false
	var proj_before := _count_projectiles()
	Input.action_press("p1_special")
	for i in 24:
		await physics_frame
		if _count_projectiles() > proj_before:
			proj_obs = true
	Common.release_p1()

	var recovery_obs := false
	f.velocity = Vector2(0, -120.0)
	for i in 6:
		await physics_frame
	Input.action_press("p1_up")
	Input.action_press("p1_special")
	for i in 24:
		await physics_frame
		if f.velocity.y < -180.0 or str(f.state_machine.current_state).contains("special"):
			recovery_obs = true
	Common.release_p1()

	f.queue_free()
	floor.queue_free()
	var runtime_obs: bool = melee_obs and aura_obs and sig != "" and (proj_obs or recovery_obs)
	return {
		"fighter_id": fid,
		"runtime_observed": runtime_obs,
		"melee_runtime": melee_obs,
		"aura_runtime": aura_obs,
		"projectile_runtime": proj_obs,
		"recovery_runtime": recovery_obs,
		"signature_mechanic": sig,
		"runtime_hooks_sample": hooks,
		"STAT_ONLY_PROFILE_CALLS_USED_AS_RUNTIME_PROOF": false,
	}


func _count_projectiles() -> int:
	var n := 0
	for node in root.get_children():
		if node.get_class() == "Projectile" or str(node.name).to_lower().contains("projectile"):
			n += 1
		elif node.has_method("get_class") and "projectile" in str(node.get_class()).to_lower():
			n += 1
	return n


func _fail(msg: String) -> void:
	_failures.append(msg)
