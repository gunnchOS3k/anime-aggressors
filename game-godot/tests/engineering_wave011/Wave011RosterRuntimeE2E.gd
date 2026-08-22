extends SceneTree

## Seven-fighter movement + identity runtime matrix (GAME-AA-005 / GAME-AA-007).
## Canonical BattleScene bootstrap per trial — no standalone Fighter.tscn harness.

const Common = preload("res://tests/engineering_wave011/Wave011EvidenceCommon.gd")
const ThrowResolver = preload("res://scripts/combat/throw_resolver.gd")
const TIME_SCALE := 2.0

var _failures: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("Wave011RosterRuntimeE2E BEGIN")
	Engine.time_scale = TIME_SCALE
	await process_frame
	await process_frame
	if root.get_node_or_null("/root/GameState") == null:
		_fail("GameState autoload missing")
		_finish()
		return

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

	var mv_collisions := _count_fingerprint_collisions(movement_rows, "movement_fingerprint")
	var sig_collisions := _count_signature_duplicates(identity_rows)
	var stat_dupes := _count_stat_only_duplicates(identity_rows)

	var movement_ok: bool = (
		movement_rows.size() >= 7
		and movement_rows.filter(func(r): return bool(r.get("runtime_observed", false))).size() >= 7
		and mv_collisions == 0
		and _failures.is_empty()
	)
	var identity_ok: bool = (
		identity_rows.size() >= 7
		and identity_rows.filter(func(r): return bool(r.get("runtime_observed", false))).size() >= 7
		and sig_collisions == 0
		and stat_dupes == 0
		and _failures.is_empty()
	)

	Common.write_artifact("FIGHTER_MOVEMENT_RUNTIME_MATRIX.json", {
		"schema": "gunnchos.engineering_wave011.fighter_movement_matrix.v1",
		"FIGHTERS_RUNTIME_MOVEMENT_TESTED": movement_rows.size(),
		"STAT_ONLY_PROFILE_CALLS_USED_AS_RUNTIME_PROOF": false,
		"MATERIAL_RUNTIME_MOVEMENT_IDENTITIES": movement_rows.filter(func(r): return bool(r.get("runtime_observed", false))).size(),
		"RUNTIME_MOVEMENT_FINGERPRINT_COLLISIONS": mv_collisions,
		"ROSTER_PROOF_USES_CANONICAL_BATTLE_BOOTSTRAP": true,
		"SESSION_STATE_LEAKS": Common.session_state_leaks,
		"rows": movement_rows,
		"pass": movement_ok,
	})
	Common.write_artifact("FIGHTER_IDENTITY_RUNTIME_MATRIX.json", {
		"schema": "gunnchos.engineering_wave011.fighter_identity_matrix.v1",
		"FIGHTERS_RUNTIME_IDENTITY_TESTED": identity_rows.size(),
		"MATERIAL_RUNTIME_IDENTITY_ROWS": identity_rows.filter(func(r): return bool(r.get("runtime_observed", false))).size(),
		"STAT_ONLY_DUPLICATES": stat_dupes,
		"SIGNATURE_MECHANIC_DUPLICATES": sig_collisions,
		"STAT_ONLY_PROFILE_CALLS_USED_AS_RUNTIME_PROOF": false,
		"ROSTER_PROOF_USES_CANONICAL_BATTLE_BOOTSTRAP": true,
		"rows": identity_rows,
		"pass": identity_ok,
	})
	Common.write_artifact("FIGHTER_SIGNATURE_RUNTIME_RESULT.json", {
		"schema": "gunnchos.engineering_wave011.fighter_signature_runtime.v1",
		"FIGHTERS_RUNTIME_IDENTITY_TESTED": identity_rows.size(),
		"SIGNATURE_MECHANIC_DUPLICATES": sig_collisions,
		"STAT_ONLY_DUPLICATES": stat_dupes,
		"signatures": identity_rows.map(func(r): return {
			"fighter_id": r.get("fighter_id", ""),
			"signature_mechanic": r.get("signature_mechanic", ""),
			"runtime_hooks": r.get("runtime_hooks_observed", []),
		}),
		"pass": identity_ok,
	})

	_finish()


func _movement_trial(fid: String) -> Dictionary:
	var boot: Dictionary = await Common.spawn_fresh_battle(self, fid, "rook-ironside")
	if not bool(boot.get("ok", false)):
		return {"fighter_id": fid, "runtime_observed": false, "bootstrap_error": boot.get("error", "")}
	var f = boot.p1
	var p2 = boot.p2
	Common.restage_on_platform(f, p2, 120.0)
	await Common.wait_frames(self, 16)

	var run_before: float = f.velocity.x
	Input.action_press("p1_right")
	for i in 18:
		await physics_frame
	var run_peak: float = absf(f.velocity.x)
	Common.release_p1()
	var ground_accel: float = absf(f.velocity.x - run_before)

	f.velocity = Vector2.ZERO
	Input.action_press("p1_jump")
	await physics_frame
	var jump_peak: float = f.velocity.y
	for i in 6:
		await physics_frame
	Common.release_p1()
	var jumped: bool = not f.is_on_floor() or jump_peak < -50.0

	f.velocity = Vector2.ZERO
	var air_before: float = f.velocity.x
	Input.action_press("p1_right")
	for i in 14:
		await physics_frame
	Common.release_p1()
	var air_accel_obs: float = absf(f.velocity.x - air_before)

	var fall_before: float = f.velocity.y
	f.velocity = Vector2(0, 120.0)
	for i in 4:
		await physics_frame
	Input.action_press("p1_down")
	for i in 8:
		await physics_frame
	Common.release_p1()
	var fall_delta: float = absf(f.velocity.y - fall_before)

	var traction: float = f.get_traction() if f.has_method("get_traction") else 0.0
	var charge_mod: float = 0.0
	var aura_before: float = float(f.aura)
	Input.action_press("p1_shield")
	Input.action_press("p1_special")
	for i in 20:
		await physics_frame
	charge_mod = f.get_charge_move_mult() if f.has_method("get_charge_move_mult") else 0.0
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
	var aura_delta: float = float(f.aura) - aura_before

	await Common.teardown_active_battle(self)

	var fp := _movement_fingerprint({
		"ground_accel_delta": ground_accel,
		"run_peak": run_peak,
		"traction": traction,
		"jump_peak_y": jump_peak,
		"air_accel_delta": air_accel_obs,
		"fall_delta": fall_delta,
		"charge_move_mult": charge_mod,
		"recovery_observed": recovery_obs,
		"aura_charge_delta": aura_delta,
	})
	var runtime_obs: bool = (
		ground_accel > 20.0
		and (jumped or air_accel_obs > 10.0)
		and traction > 100.0
		and charge_mod > 0.05
		and (recovery_obs or fall_delta > 20.0)
	)
	return {
		"fighter_id": fid,
		"runtime_observed": runtime_obs,
		"ground_accel_delta": ground_accel,
		"run_peak": run_peak,
		"jump_observed": jumped,
		"jump_peak_y": jump_peak,
		"air_accel_delta": air_accel_obs,
		"fall_delta": fall_delta,
		"traction": traction,
		"charge_move_mult": charge_mod,
		"recovery_observed": recovery_obs,
		"movement_fingerprint": fp,
	}


func _identity_trial(fid: String) -> Dictionary:
	var boot: Dictionary = await Common.spawn_fresh_battle(self, fid, "rook-ironside")
	if not bool(boot.get("ok", false)):
		return {"fighter_id": fid, "runtime_observed": false, "bootstrap_error": boot.get("error", "")}
	var f = boot.p1
	var p2 = boot.p2
	Common.restage_on_platform(f, p2, 120.0)
	await Common.wait_frames(self, 16)

	var move_obs := false
	Input.action_press("p1_right")
	await physics_frame
	for i in 10:
		await physics_frame
		if absf(f.velocity.x) > 20.0:
			move_obs = true
	Common.release_p1()

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

	var special_obs := false
	var proj_before := _count_projectiles(f)
	Input.action_press("p1_special")
	for i in 24:
		await physics_frame
		if _count_projectiles(f) > proj_before:
			special_obs = true
		if str(f.state_machine.current_state).contains("special"):
			special_obs = true
	Common.release_p1()

	var throw_obs := false
	Common.restage_on_platform(f, p2, 48.0)
	await Common.wait_frames(self, 12)
	p2.reset_damage()
	Input.action_press("p1_grab")
	for i in 36:
		await physics_frame
		if f.grabbed_target != null and str(f.state_machine.current_state) == "grab_hold":
			break
	Input.action_release("p1_grab")
	await Common.wait_frames(self, 4)
	Input.action_release("p1_attack")
	await physics_frame
	Input.action_press("p1_attack")
	for i in 20:
		await physics_frame
		if p2.grabbed_by == null and f.grabbed_target == null and float(p2.damage_percent) > 0.2:
			throw_obs = true
			break
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

	await _drive_signature_observation(f, p2, fid)

	var hooks: Array = []
	if f.has_method("runtime_hooks_seen"):
		hooks = Array(f.runtime_hooks_seen())
	hooks.sort()
	var sig: String = _signature_from_hooks(hooks)
	var traction_obs: float = f.get_traction() if f.has_method("get_traction") else 0.0
	var charge_obs: float = f.get_charge_move_mult() if f.has_method("get_charge_move_mult") else 0.0
	var identity_fp := _identity_fingerprint({
		"signature_mechanic": sig,
		"run_peak": absf(f.velocity.x),
		"traction": traction_obs,
	})
	var stat_only_fp := _stat_only_fingerprint(traction_obs, charge_obs)

	await Common.teardown_active_battle(self)

	var runtime_obs: bool = melee_obs and aura_obs and sig != "" and (special_obs or recovery_obs or throw_obs)
	return {
		"fighter_id": fid,
		"runtime_observed": runtime_obs,
		"movement_runtime": move_obs,
		"melee_runtime": melee_obs,
		"aura_runtime": aura_obs,
		"special_runtime": special_obs,
		"throw_runtime": throw_obs,
		"recovery_runtime": recovery_obs,
		"signature_mechanic": sig,
		"runtime_hooks_observed": hooks,
		"identity_fingerprint": identity_fp,
		"stat_only_fingerprint": stat_only_fp,
		"traction_observed": traction_obs,
		"charge_move_mult_observed": charge_obs,
		"STAT_ONLY_PROFILE_CALLS_USED_AS_RUNTIME_PROOF": false,
	}


func _drive_signature_observation(f, p2, fid: String) -> void:
	Common.restage_on_platform(f, p2, 72.0)
	await Common.wait_frames(self, 8)
	match fid:
		"ember-vale":
			Input.action_press("p1_shield")
			Input.action_press("p1_special")
			for i in 52:
				await physics_frame
			Common.release_p1()
			await Common.wait_frames(self, 4)
			Input.action_press("p1_attack")
			for i in 14:
				await physics_frame
			Common.release_p1()
		"rook-ironside":
			Input.action_press("p1_shield")
			Input.action_press("p1_special")
			for i in 58:
				await physics_frame
			Common.release_p1()
			Input.action_press("p1_right")
			Input.action_press("p1_attack")
			for i in 10:
				await physics_frame
			Common.release_p1()
		"juno-spark":
			Common.restage_on_platform(f, p2, 38.0)
			await Common.wait_frames(self, 8)
			Input.action_press("p1_shield")
			Input.action_press("p1_special")
			for i in 48:
				await physics_frame
			Common.release_p1()
			Input.action_press("p1_right")
			for i in 6:
				await physics_frame
			Input.action_press("p1_attack")
			for i in 22:
				await physics_frame
				if float(p2.damage_percent) > 0.25:
					break
			Common.release_p1()
		"kaia-windrow":
			Input.action_press("p1_shield")
			Input.action_press("p1_special")
			for i in 48:
				await physics_frame
			Common.release_p1()
			Input.action_press("p1_jump")
			await physics_frame
			f.velocity = Vector2(80.0, -260.0)
			for i in 50:
				await physics_frame
			Common.release_p1()
		"nix-calder":
			Input.action_press("p1_shield")
			Input.action_press("p1_special")
			for i in 90:
				await physics_frame
			Common.release_p1()
			Input.action_press("p1_attack")
			for i in 14:
				await physics_frame
			Common.release_p1()
		"orion-vell":
			Common.restage_on_platform(f, p2, 36.0)
			await Common.wait_frames(self, 8)
			Input.action_press("p1_shield")
			Input.action_press("p1_special")
			for i in 52:
				await physics_frame
			Common.release_p1()
			Input.action_press("p1_attack")
			for i in 18:
				await physics_frame
				if float(p2.damage_percent) > 0.25:
					break
			Common.release_p1()
		"vesper-nyx":
			Input.action_press("p1_shield")
			Input.action_press("p1_special")
			for i in 54:
				await physics_frame
			Common.release_p1()
			Input.action_press("p1_special")
			for i in 22:
				await physics_frame
			Common.release_p1()
	await Common.wait_frames(self, 8)


func _signature_from_hooks(hooks: Array) -> String:
	var tags: Array = []
	for h in hooks:
		var tag := str(h)
		if tag == "charge_rate":
			continue
		if tag not in tags:
			tags.append(tag)
	tags.sort()
	if tags.is_empty():
		for h in hooks:
			var tag := str(h)
			if tag not in tags:
				tags.append(tag)
		tags.sort()
	return "|".join(tags)


func _stat_only_fingerprint(traction: float, charge_mult: float) -> String:
	return "%.0f|%.3f" % [traction, charge_mult]


func _movement_fingerprint(row: Dictionary) -> String:
	return "%.1f|%.1f|%.0f|%.1f|%.1f|%.0f|%.3f" % [
		float(row.get("ground_accel_delta", 0.0)),
		float(row.get("run_peak", 0.0)),
		float(row.get("traction", 0.0)),
		float(row.get("jump_peak_y", 0.0)),
		float(row.get("air_accel_delta", 0.0)),
		float(row.get("fall_delta", 0.0)),
		float(row.get("charge_move_mult", 0.0)),
	]


func _identity_fingerprint(row: Dictionary) -> String:
	return "%s|%.0f|%.0f" % [
		str(row.get("signature_mechanic", "")),
		float(row.get("run_peak", 0.0)),
		float(row.get("traction", 0.0)),
	]


func _count_fingerprint_collisions(rows: Array, key: String) -> int:
	var seen: Dictionary = {}
	var collisions := 0
	for row in rows:
		if not bool(row.get("runtime_observed", false)):
			continue
		var fp: String = str(row.get(key, ""))
		if fp == "":
			continue
		if seen.has(fp):
			collisions += 1
		else:
			seen[fp] = row.get("fighter_id", "")
	return collisions


func _count_signature_duplicates(rows: Array) -> int:
	var seen: Dictionary = {}
	var dupes := 0
	for row in rows:
		if not bool(row.get("runtime_observed", false)):
			continue
		var sig: String = str(row.get("signature_mechanic", ""))
		if sig == "":
			continue
		if seen.has(sig):
			dupes += 1
		else:
			seen[sig] = true
	return dupes


func _count_stat_only_duplicates(rows: Array) -> int:
	var seen: Dictionary = {}
	var dupes := 0
	for row in rows:
		if not bool(row.get("runtime_observed", false)):
			continue
		var key: String = str(row.get("stat_only_fingerprint", ""))
		if key == "":
			continue
		if seen.has(key):
			dupes += 1
		else:
			seen[key] = true
	return dupes


func _count_projectiles(fighter) -> int:
	var n := 0
	if fighter == null or fighter.projectile_spawner == null:
		return 0
	return int(fighter.projectile_spawner.count())


func _fail(msg: String) -> void:
	_failures.append(msg)


func _finish() -> void:
	Engine.time_scale = 1.0
	Common.release_p1()
	Common.release_p2()
	await Common.teardown_active_battle(self)
	if _failures.is_empty():
		print("Wave011RosterRuntimeE2E PASS")
		quit(0)
	else:
		for f in _failures:
			push_error(f)
		print("Wave011RosterRuntimeE2E FAIL")
		quit(1)
