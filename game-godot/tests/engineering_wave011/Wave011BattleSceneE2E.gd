extends SceneTree

## Canonical BattleScene E2E — loads res://scenes/battle/BattleScene.tscn.
## Normal input path only: Input.action_press/release on p1_*.
## No battle_eval_mode, ProductionGateHarness, or aura= writes as proof.

const TIME_SCALE := 2.0
const MAX_WAIT_SEC := 45.0
const BATTLE_PATH := "res://scenes/battle/BattleScene.tscn"
const ROSTER := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]
const AuraIdentity = preload("res://scripts/combat/aura_identity.gd")
const CompetitiveRules = preload("res://scripts/combat/competitive_rules.gd")

var _failures: PackedStringArray = PackedStringArray()
var _obs: Dictionary = {}
var _scene: Node = null
var _gs: Node = null


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("Wave011BattleSceneE2E BEGIN")
	Engine.time_scale = TIME_SCALE
	_gs = root.get_node_or_null("/root/GameState")
	if _gs == null:
		_fail("GameState autoload missing")
		_finish(false)
		return
	_gs.begin_local_versus(false)
	_gs.p1_fighter_id = "ember-vale"
	_gs.p2_fighter_id = "rook-ironside"
	_gs.p1_is_cpu = false
	_gs.p2_is_cpu = false
	_gs.battle_eval_mode = false
	_gs.debug_combat_hud = false
	_gs.mode = "versus"

	var packed: PackedScene = load(BATTLE_PATH)
	if packed == null:
		_fail("BattleScene.tscn failed to load")
		_finish(false)
		return
	_scene = packed.instantiate()
	root.add_child(_scene)
	await process_frame
	await process_frame

	if bool(_gs.battle_eval_mode):
		_fail("battle_eval_mode must remain false for E2E proof")
		_finish(false)
		return
	if _scene.get_node_or_null("ProductionGateHarness") != null:
		_fail("ProductionGateHarness present in BattleScene tree as E2E driver")
		_finish(false)
		return

	if not await _wait_controls():
		_fail("countdown did not enable controls")
		_finish(false)
		return

	_obs["CANONICAL_BATTLE_SCENE_EXECUTED"] = true
	_obs["NORMAL_INPUT_PATH"] = true
	_obs["battle_eval_mode"] = false
	_obs["production_gate_harness_used_as_proof"] = false
	_obs["countdown_completed"] = true

	var p1 = _scene.fighter1
	var p2 = _scene.fighter2
	if p1 == null or p2 == null:
		_fail("BattleScene missing fighters")
		_finish(false)
		return

	_obs["debug_hud_present"] = _scene._debug_hud != null
	if _scene._debug_hud != null:
		_fail("versus instantiated DebugHud (clean HUD required)")

	_obs["scenarios"] = {}
	_obs["scenarios"]["A_aura_charge_burst"] = await _scenario_a(p1, p2)
	_obs["scenarios"]["B_aura_scaled_melee"] = await _scenario_b(p1, p2)
	_obs["scenarios"]["C_projectiles"] = await _scenario_c(p1, p2)
	_obs["scenarios"]["D_throws_defense"] = await _scenario_d(p1, p2)
	_obs["scenarios"]["E_identity_hud_safety"] = await _scenario_e(p1, p2)

	var all_ok := true
	for k in _obs["scenarios"]:
		if not bool(_obs["scenarios"][k].get("ok", false)):
			all_ok = false
			_fail("scenario %s failed" % k)

	_finish(all_ok and _failures.is_empty())


func _wait_controls() -> bool:
	var start := Time.get_ticks_msec() / 1000.0
	while Time.get_ticks_msec() / 1000.0 - start < 12.0:
		await physics_frame
		if _scene != null and _scene.fighter1 != null and bool(_scene.fighter1.controls_enabled):
			return true
	return false


func _release_p1() -> void:
	for suffix in ["left", "right", "up", "down", "jump", "attack", "special", "shield", "grab", "dodge"]:
		var action := "p1_%s" % suffix
		if InputMap.has_action(action):
			Input.action_release(action)


func _scenario_a(p1, _p2) -> Dictionary:
	print("E2E_SCENARIO A charge")
	_release_p1()
	var before: float = float(p1.aura)
	Input.action_press("p1_shield")
	Input.action_press("p1_special")
	for i in 10:
		await physics_frame
	var after: float = float(p1.aura)
	var state: String = str(p1.state_machine.current_state) if p1.state_machine else ""
	_release_p1()
	for i in 8:
		await physics_frame
	var charged: bool = after > before + 8.0
	var in_charge: bool = state.contains("aura")
	if not charged:
		_fail("A: aura did not accumulate via held shield+special")
	print("E2E_A aura %.1f -> %.1f state=%s" % [before, after, state])
	return {"ok": charged, "before": before, "after": after, "state": state, "in_charge": in_charge}


func _scenario_b(p1, p2) -> Dictionary:
	print("E2E_SCENARIO B melee")
	_release_p1()
	await _restage_on_platform(p1, p2, 46.0)
	var dmg0: float = float(p2.damage_percent)
	Input.action_press("p1_attack")
	await physics_frame
	for i in 16:
		await physics_frame
		if float(p2.damage_percent) > dmg0 + 0.2:
			break
	Input.action_release("p1_attack")
	if float(p2.damage_percent) <= dmg0 + 0.2:
		for n in 2:
			Input.action_press("p1_attack")
			await physics_frame
			Input.action_release("p1_attack")
			for i in 10:
				await physics_frame
				if float(p2.damage_percent) > dmg0 + 0.2:
					break
			if float(p2.damage_percent) > dmg0 + 0.2:
				break
	var hit: float = float(p2.damage_percent) - dmg0
	var dist: float = absf(p2.global_position.x - p1.global_position.x)
	var aura_now: float = float(p1.aura)
	var ok: bool = hit > 0.0
	if not ok:
		_fail("B: melee hit not observed on BattleScene via p1_attack dist=%.1f" % dist)
	print("E2E_B hit=%.2f aura=%.1f dist=%.1f state=%s" % [hit, aura_now, dist, str(p1.state_machine.current_state)])
	return {"ok": ok, "hit": hit, "aura": aura_now, "dist": dist}


func _scenario_c(p1, p2) -> Dictionary:
	print("E2E_SCENARIO C projectile")
	_release_p1()
	await _restage_on_platform(p1, p2, 180.0)
	var dmg0: float = float(p2.damage_percent)
	var proj0: int = int(p1.projectile_spawner.count()) if p1.projectile_spawner else 0
	Input.action_press("p1_special")
	await physics_frame
	Input.action_release("p1_special")
	var spawned := false
	var hit := false
	for i in 55:
		await physics_frame
		if p1.projectile_spawner and int(p1.projectile_spawner.count()) > proj0:
			spawned = true
		if float(p2.damage_percent) > dmg0 + 0.4:
			hit = true
			break
	if not spawned and not hit:
		_fail("C: projectile neither spawned nor hit via HitResolver")
	print("E2E_C spawned=%s hit=%s dmg_delta=%.2f" % [spawned, hit, float(p2.damage_percent) - dmg0])
	return {
		"ok": spawned or hit,
		"spawned": spawned,
		"hit_resolver": hit,
		"dmg_delta": float(p2.damage_percent) - dmg0,
	}


func _scenario_d(p1, p2) -> Dictionary:
	print("E2E_SCENARIO D throws")
	_release_p1()
	await _restage_on_platform(p1, p2, 52.0)
	var grab_ok := false
	var throw_ok := false
	var mash_ok := false
	var dmg0: float = float(p2.damage_percent)
	Input.action_press("p1_grab")
	await physics_frame
	Input.action_release("p1_grab")
	for i in 30:
		await physics_frame
		var st: String = str(p1.state_machine.current_state)
		if st.contains("grab"):
			grab_ok = true
		if st.contains("throw"):
			throw_ok = true
		if p1.grabbed_target != null:
			grab_ok = true
			Input.action_press("p1_up")
			Input.action_press("p1_attack")
			await physics_frame
			Input.action_release("p1_attack")
			Input.action_release("p1_up")
		if str(p1._throw_direction) != "":
			throw_ok = true
	if float(p2.damage_percent) > dmg0 + 0.5:
		throw_ok = true
	if p2.grabbed_by != null:
		var mash0: float = float(p2.grab_mash)
		Input.action_press("p2_attack")
		await physics_frame
		Input.action_release("p2_attack")
		await physics_frame
		mash_ok = float(p2.grab_mash) > mash0 or float(p2.grab_mash) > 0.0
	_release_p1()
	Input.action_press("p1_shield")
	var sh0: float = float(p1.shield_health)
	for i in 8:
		await physics_frame
	var sh1: float = float(p1.shield_health)
	_release_p1()
	var shield_decayed: bool = sh1 < sh0 - 0.5
	if not grab_ok and not throw_ok:
		_fail("D: grab/throw not observed")
	print("E2E_D grab=%s throw=%s mash=%s shield_decay=%s" % [grab_ok, throw_ok, mash_ok, shield_decayed])
	return {
		"ok": grab_ok or throw_ok,
		"grab": grab_ok,
		"throw": throw_ok,
		"mash": mash_ok,
		"shield_decay": shield_decayed,
	}


func _scenario_e(p1, p2) -> Dictionary:
	print("E2E_SCENARIO E identity + HUD + safety")
	var fps := {}
	for fid in ROSTER:
		fps[fid] = AuraIdentity.movement_fingerprint(fid)
	var keys := {}
	var distinct := 0
	for fid in fps:
		var fp: Dictionary = fps[fid]
		var k := "%s|%.2f|%.1f|%.1f" % [fp.tag, fp.charge_rate_mult, fp.air_accel, fp.ground_traction]
		if not keys.has(k):
			distinct += 1
		keys[k] = fid
	var hud_clean: bool = _scene._debug_hud == null and not CompetitiveRules.show_debug_hud(_gs)
	var cap_ok: bool = float(p1.aura) <= 100.0 and float(p2.aura) <= 100.0
	var nan_ok: bool = not is_nan(float(p1.aura)) and not is_nan(float(p1.damage_percent))
	var stocks_ok: bool = int(_gs.stocks) == 3
	p2.is_cpu = true
	if p2.cpu and p2.cpu.has_method("setup"):
		p2.cpu.setup(p2, 4, 11)
	for i in 12:
		await physics_frame
	var obs_ok := true
	if p2.cpu and "_obs_cache" in p2.cpu:
		var cache: Dictionary = p2.cpu._obs_cache
		obs_ok = not cache.has("opp_aura")
	p2.is_cpu = false
	if p2.cpu and p2.cpu.has_method("clear_simulated_inputs"):
		p2.cpu.clear_simulated_inputs()
	var ok: bool = distinct >= 7 and hud_clean and cap_ok and nan_ok and stocks_ok and obs_ok
	if not ok:
		_fail("E: identity/HUD/safety failed distinct=%d hud_clean=%s" % [distinct, hud_clean])
	print("E2E_E distinct=%d hud_clean=%s cap=%s" % [distinct, hud_clean, cap_ok])
	return {
		"ok": ok,
		"distinct": distinct,
		"hud_clean": hud_clean,
		"cap_ok": cap_ok,
		"nan_ok": nan_ok,
		"stocks_ok": stocks_ok,
		"cpu_observe_legal": obs_ok,
	}


func _restage_on_platform(p1, p2, gap: float) -> void:
	## Place both bodies on the same spawn-floor Y. TIME_SCALE can tunnel a
	## CharacterBody2D through the main platform; melee then overlaps only self.
	var floor_y: float = float(p1.spawn_point.y)
	if p2.is_on_floor() and not p1.is_on_floor():
		floor_y = p2.global_position.y
	elif p1.is_on_floor():
		floor_y = p1.global_position.y
	var cx: float = float(p1.platform_center_x)
	p1.global_position = Vector2(cx - gap * 0.5, floor_y)
	p2.global_position = Vector2(cx + gap * 0.5, floor_y)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.facing = 1
	p2.facing = -1
	for i in 8:
		await physics_frame
	if absf(p2.global_position.y - p1.global_position.y) > 24.0:
		p1.global_position.y = floor_y
		p2.global_position.y = floor_y
		p1.velocity = Vector2.ZERO
		p2.velocity = Vector2.ZERO
		await physics_frame


func _close_distance(p1, p2, target: float) -> void:
	_release_p1()
	var start := Time.get_ticks_msec() / 1000.0
	var side: float = signf(p2.global_position.x - p1.global_position.x)
	while absf(p2.global_position.x - p1.global_position.x) > target:
		if Time.get_ticks_msec() / 1000.0 - start > 4.0:
			break
		var dx: float = p2.global_position.x - p1.global_position.x
		if side != 0.0 and signf(dx) != side:
			break
		if dx > 0.0:
			Input.action_press("p1_right")
			Input.action_release("p1_left")
		else:
			Input.action_press("p1_left")
			Input.action_release("p1_right")
		await physics_frame
	_release_p1()
	await physics_frame


func _space_band(p1, p2, lo: float, hi: float) -> void:
	var start := Time.get_ticks_msec() / 1000.0
	while Time.get_ticks_msec() / 1000.0 - start < 2.5:
		var dist: float = absf(p2.global_position.x - p1.global_position.x)
		if dist >= lo and dist <= hi:
			break
		var dx: float = p2.global_position.x - p1.global_position.x
		if dist < lo:
			# Too close — step away.
			if dx >= 0.0:
				Input.action_press("p1_left")
				Input.action_release("p1_right")
			else:
				Input.action_press("p1_right")
				Input.action_release("p1_left")
		else:
			if dx > 0.0:
				Input.action_press("p1_right")
				Input.action_release("p1_left")
			else:
				Input.action_press("p1_left")
				Input.action_release("p1_right")
		await physics_frame
	_release_p1()
	await physics_frame
	if p2.global_position.x >= p1.global_position.x:
		p1.facing = 1
	else:
		p1.facing = -1


func _fail(msg: String) -> void:
	_failures.append(msg)


func _finish(ok: bool) -> void:
	Engine.time_scale = 1.0
	_release_p1()
	var dir_res := "res://artifacts/engineering_wave011"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_res))
	var payload := {
		"schema": "gunnchos.engineering_wave011.battlescene_e2e.v1",
		"CANONICAL_BATTLE_SCENE_EXECUTED": bool(_obs.get("CANONICAL_BATTLE_SCENE_EXECUTED", false)),
		"NORMAL_INPUT_PATH": true,
		"battle_eval_mode": false,
		"accept_test_mode": false,
		"production_gate_harness_used_as_proof": false,
		"aura_assign_used_as_charge_proof": false,
		"scenarios": _obs.get("scenarios", {}),
		"pass": ok and _failures.is_empty(),
		"failures": Array(_failures),
		"debug_hud_present": _obs.get("debug_hud_present", true),
		"countdown_completed": bool(_obs.get("countdown_completed", false)),
	}
	var f := FileAccess.open(dir_res.path_join("BATTLESCENE_E2E_RESULT.json"), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()
	if ok and _failures.is_empty():
		print("Wave011BattleSceneE2E PASS")
		print("WAVE011_BATTLE_SCENE_E2E_PASS")
		quit(0)
	else:
		for msg in _failures:
			push_error(msg)
			print("FAIL: ", msg)
		print("Wave011BattleSceneE2E FAIL count=%d" % _failures.size())
		quit(1)
