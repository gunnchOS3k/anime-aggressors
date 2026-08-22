extends SceneTree

## Wave011 COMPONENT_RUNTIME proof — canonical combat scripts, not BattleScene E2E.
## BattleScene E2E lives in Wave011BattleSceneE2E.gd.

const CombatMath = preload("res://scripts/combat/combat_math.gd")
const AuraScaler = preload("res://scripts/combat/aura_scaler.gd")
const AuraIdentity = preload("res://scripts/combat/aura_identity.gd")
const FrameDataTable = preload("res://scripts/combat/frame_data_table.gd")
const CompetitiveRules = preload("res://scripts/combat/competitive_rules.gd")
const ThrowResolver = preload("res://scripts/combat/throw_resolver.gd")
const DataLoader = preload("res://scripts/data/data_loader.gd")

var _failures: PackedStringArray = PackedStringArray()
var _observations: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("Wave011RuntimeTest BEGIN COMPONENT_RUNTIME")
	_test_aura_charge_math()
	_test_idle_decay()
	_test_melee_aura_scale()
	_test_projectile_aura_scale()
	await _test_projectile_hit_resolver_path()
	_test_throws()
	_test_movement_fingerprints()
	_test_defense_constants()
	_test_identities()
	_test_impact_and_stale()
	_test_frame_data()
	_test_competitive_hud_split()
	_test_cpu_legal_observation()
	_test_combat_loop_safety()
	_test_production_independence_static()
	_write_runtime_artifact()
	if _failures.is_empty():
		print("Wave011RuntimeTest PASS")
		print("WAVE011_COMPONENT_RUNTIME_PASS")
		quit(0)
	else:
		for f in _failures:
			push_error(f)
			print("FAIL: ", f)
		print("Wave011RuntimeTest FAIL count=%d" % _failures.size())
		quit(1)


func _fail(msg: String) -> void:
	_failures.append(msg)


func _test_aura_charge_math() -> void:
	if CombatMath.AURA_CHARGE_PER_SECOND < 30.0:
		_fail("AURA_CHARGE_PER_SECOND too low for competitive charge")
	var ember_mult: float = AuraIdentity.charge_rate_mult("ember-vale", "burn_rushdown")
	if ember_mult < 1.11:
		_fail("ember charge_rate_mult collapsed")
	var gained: float = AuraScaler.apply_charge_tick(0.0, 1.0, true, ember_mult)
	if gained < 35.0:
		_fail("ember 1s charge did not accumulate (got %.2f)" % gained)
	var capped: float = AuraScaler.apply_charge_tick(99.0, 2.0, true, ember_mult)
	if capped > 100.0 + 0.01:
		_fail("aura cap exceeded")
	_observations["charge"] = {
		"observed": gained >= 35.0,
		"gained_1s": gained,
		"ember_mult": ember_mult,
		"per_second": CombatMath.AURA_CHARGE_PER_SECOND,
		"capped": capped,
	}


func _test_idle_decay() -> void:
	if CombatMath.AURA_IDLE_DECAY_PER_SECOND < 3.0:
		_fail("idle decay disabled")
	var after: float = AuraScaler.apply_charge_tick(50.0, 1.0, false, 1.0)
	if after > 47.0:
		_fail("idle decay did not reduce aura")
	_observations["idle_decay"] = {"observed": after <= 47.0, "after": after}


func _test_melee_aura_scale() -> void:
	var manifest: Dictionary = DataLoader.load_moves("ember-vale")
	var jab: Dictionary = DataLoader.find_move(manifest, "jab_1")
	if jab.is_empty():
		_fail("jab_1 missing")
		return
	var l0: Dictionary = AuraScaler.apply_to_move(jab, 0.0)
	var l3: Dictionary = AuraScaler.apply_to_move(jab, 80.0)
	var d0: float = float(l0.get("damage", 0))
	var d3: float = float(l3.get("damage", 0))
	if d3 <= d0:
		_fail("aura-scaled melee L3 damage not greater than L0")
	_observations["melee_scale"] = {"observed": d3 > d0, "l0": d0, "l3": d3}


func _test_projectile_aura_scale() -> void:
	var manifest: Dictionary = DataLoader.load_moves("ember-vale")
	var mv: Dictionary = DataLoader.find_move(manifest, "neutral_special_projectile")
	if mv.is_empty() or not mv.has("projectile"):
		_fail("neutral_special_projectile missing")
		return
	var cfg: Dictionary = mv.get("projectile", {})
	var dmg: Array = cfg.get("damage_by_aura", [])
	var spd: Array = cfg.get("speed_by_aura", [])
	if dmg.size() < 3 or float(dmg[2]) <= float(dmg[0]):
		_fail("projectile damage_by_aura not charge-scaled")
	if spd.size() < 3 or float(spd[2]) <= float(spd[0]):
		_fail("projectile speed_by_aura not charge-scaled")
	var v0: float = AuraScaler.projectile_value_by_aura(dmg, 0.0)
	var v3: float = AuraScaler.projectile_value_by_aura(dmg, 80.0)
	if v3 <= v0:
		_fail("projectile_value_by_aura L3 <= L0")
	_observations["projectile"] = {
		"observed": v3 > v0,
		"d0": v0,
		"d3": v3,
		"speed0": float(spd[0]),
		"speed2": float(spd[2]),
	}


func _test_projectile_hit_resolver_path() -> void:
	var packed: PackedScene = load("res://scenes/combat/Projectile2D.tscn")
	if packed == null:
		_fail("Projectile2D.tscn missing")
		return
	var proj: Node = packed.instantiate()
	root.add_child(proj)
	await process_frame
	proj.configure({
		"lifetime_frames": 30,
		"speed": 400,
		"behavior": "straight",
		"damage": 8,
		"move_data": {"move_id": "neutral_special_projectile", "damage": 8},
		"size": Vector2(16, 16),
		"color": Color.ORANGE,
	}, null)
	if int(proj.collision_layer) != 8:
		_fail("projectile collision_layer != 8")
	if int(proj.collision_mask) != 6:
		_fail("projectile collision_mask != 6 (hurtbox+body)")
	if not proj.has_method("_deliver_hit"):
		_fail("projectile missing _deliver_hit")
	_observations["projectile_resolver"] = {
		"observed": int(proj.collision_mask) == 6 and int(proj.collision_layer) == 8,
		"layer": int(proj.collision_layer),
		"mask": int(proj.collision_mask),
	}
	proj.queue_free()


func _test_throws() -> void:
	var manifest: Dictionary = DataLoader.load_moves("ember-vale")
	var fwd: Dictionary = ThrowResolver.resolve_throw(null, null, manifest, "forward")
	var up: Dictionary = ThrowResolver.resolve_throw(null, null, manifest, "up")
	var down: Dictionary = ThrowResolver.resolve_throw(null, null, manifest, "down")
	var back: Dictionary = ThrowResolver.resolve_throw(null, null, manifest, "back")
	var angles := [
		float(fwd.get("angle_deg", 0)),
		float(up.get("angle_deg", 0)),
		float(down.get("angle_deg", 0)),
		float(back.get("angle_deg", 0)),
	]
	var uniq := {}
	for a in angles:
		uniq[snappedf(a, 0.1)] = true
	if uniq.size() < 4:
		_fail("directional throws not distinct")
	if CombatMath.GRAB_RANGE_PX < 60.0:
		_fail("GRAB_RANGE_PX collapsed")
	if CombatMath.GRAB_MASH_PER_PRESS < 0.2:
		_fail("GRAB_MASH_PER_PRESS disabled")
	_observations["throws"] = {
		"observed": uniq.size() >= 4,
		"angles": angles,
		"grab_range": CombatMath.GRAB_RANGE_PX,
		"mash": CombatMath.GRAB_MASH_PER_PRESS,
	}


func _test_movement_fingerprints() -> void:
	var ids: Array = AuraIdentity.all_fighter_ids()
	if ids.size() < 7:
		_fail("launch roster fingerprints < 7")
	var seen := {}
	var collisions := 0
	for fid in ids:
		var fp: Dictionary = AuraIdentity.movement_fingerprint(str(fid), "")
		var key := "%s|%.2f|%.1f|%.1f|%.2f" % [
			str(fp.get("tag", "")),
			float(fp.get("charge_rate_mult", 0)),
			float(fp.get("air_accel", 0)),
			float(fp.get("ground_traction", 0)),
			float(fp.get("charge_move_mult", 0)),
		]
		if seen.has(key):
			collisions += 1
		seen[key] = fid
	var ember_air: float = AuraIdentity.air_accel("ember-vale")
	var rook_air: float = AuraIdentity.air_accel("rook-ironside")
	if ember_air <= rook_air:
		_fail("ember/rook air_accel not distinct")
	if rook_air >= 1000.0:
		_fail("rook air_accel lost heavy fingerprint")
	_observations["movement"] = {
		"observed": collisions == 0 and ids.size() >= 7,
		"count": ids.size(),
		"collisions": collisions,
		"ember_air": ember_air,
		"rook_air": rook_air,
	}


func _test_defense_constants() -> void:
	if CombatMath.SHIELD_REGEN_PER_SECOND < 10.0:
		_fail("shield regen disabled")
	if CombatMath.TECH_WINDOW_SEC < 0.08:
		_fail("tech window collapsed")
	if CombatMath.AURA_HIT_INTERRUPT_LOSS < 15.0:
		_fail("charge interrupt loss disabled")
	var decay: float = CombatMath.shield_decay_per_second({"decayPerSecond": 18.0})
	if decay < 17.0:
		_fail("shield decay from data not applied")
	_observations["defense"] = {
		"observed": true,
		"regen": CombatMath.SHIELD_REGEN_PER_SECOND,
		"tech": CombatMath.TECH_WINDOW_SEC,
		"interrupt": CombatMath.AURA_HIT_INTERRUPT_LOSS,
		"decay": decay,
	}


func _test_identities() -> void:
	var tags := {}
	for fid in AuraIdentity.all_fighter_ids():
		var p: Dictionary = AuraIdentity.profile_for(str(fid))
		tags[str(p.get("tag", ""))] = fid
	if tags.size() < 7:
		_fail("power identities collapsed")
	if not bool(AuraIdentity.profile_for("rook-ironside").get("armor_on_heavies", false)):
		_fail("rook armor identity missing")
	if not bool(AuraIdentity.profile_for("vesper-nyx").get("phase_cancel", false)):
		_fail("vesper phase identity missing")
	if not bool(AuraIdentity.profile_for("juno-spark").get("dash_cancel_after_hit", false)):
		_fail("juno dash-cancel identity missing")
	_observations["identities"] = {"observed": tags.size() >= 7, "tags": tags.keys()}


func _test_impact_and_stale() -> void:
	if CombatMath.STALE_FLOOR >= 0.9:
		_fail("stale floor neutralized")
	var s5: float = CombatMath.stale_multiplier(5)
	if s5 > 0.7:
		_fail("stale multiplier too weak")
	var combo: float = CombatMath.combo_decay(5)
	if combo >= 1.0:
		_fail("combo decay disabled")
	_observations["impact"] = {
		"observed": s5 <= CombatMath.STALE_FLOOR + 0.05,
		"stale5": s5,
		"floor": CombatMath.STALE_FLOOR,
		"combo5": combo,
	}


func _test_frame_data() -> void:
	var integ: Dictionary = FrameDataTable.roster_frame_integrity()
	if not bool(integ.get("ok", false)):
		_fail("core frame data missing: %s" % str(integ.get("missing_fighters", [])))
	var jab: Dictionary = DataLoader.find_move(DataLoader.load_moves("ember-vale"), "jab_1")
	var row: Dictionary = FrameDataTable.row_for_move(jab)
	if int(row.get("startup", 0)) != 3 or int(row.get("active", 0)) != 2:
		_fail("jab_1 frame data not derived from move def")
	_observations["frame_data"] = {
		"observed": bool(integ.get("ok", false)) and int(row.get("startup", 0)) == 3,
		"integrity": integ.get("ok", false),
		"jab_startup": int(row.get("startup", 0)),
	}


func _test_competitive_hud_split() -> void:
	if CompetitiveRules.STOCKS != 3:
		_fail("competitive stocks != 3")
	if CompetitiveRules.TIMER_SECONDS != 180:
		_fail("competitive timer != 180")
	if CompetitiveRules.ITEMS_ENABLED or CompetitiveRules.HAZARDS_ENABLED:
		_fail("competitive items/hazards enabled")
	if CompetitiveRules.HIDDEN_RUBBER_BANDING or CompetitiveRules.FORCED_FINISH_ORDER:
		_fail("hidden competitive assists present")
	var gs = root.get_node_or_null("/root/GameState")
	if gs == null:
		_fail("GameState autoload missing")
		return
	gs.mode = "versus"
	gs.debug_combat_hud = false
	var vs_debug: bool = CompetitiveRules.show_debug_hud(gs)
	gs.mode = "training"
	var tr_debug: bool = CompetitiveRules.show_debug_hud(gs)
	gs.mode = "versus"
	if vs_debug:
		_fail("versus leaked debug HUD")
	if not tr_debug:
		_fail("training debug HUD off")
	_observations["hud"] = {
		"observed": (not vs_debug) and tr_debug and CompetitiveRules.STOCKS == 3,
		"versus_debug": vs_debug,
		"training_debug": tr_debug,
		"stocks": CompetitiveRules.STOCKS,
	}


func _test_cpu_legal_observation() -> void:
	var src: String = FileAccess.get_file_as_string("res://scripts/fighters/cpu_controller.gd")
	if src.find("_fighter.aura =") != -1 or src.find("opponent.aura =") != -1:
		_fail("CPU writes aura directly")
	if src.find("self_aura") == -1:
		_fail("CPU observe missing legal own-aura path")
	if src.find("_sim_aura_charge") == -1 or src.find("Input.action_press") == -1:
		_fail("CPU charge is not input-legal")
	_observations["cpu_legal"] = {
		"observed": src.find("self_aura") != -1 and src.find("_fighter.aura =") == -1,
		"input_charge": src.find("_sim_aura_charge") != -1,
	}


func _test_combat_loop_safety() -> void:
	var a: float = AuraScaler.apply_charge_tick(100.0, 5.0, true, 2.0)
	if a > 100.0001 or is_nan(a):
		_fail("combat loop aura unsafe")
	var d: float = AuraScaler.apply_charge_tick(0.0, 5.0, false, 1.0)
	if d < 0.0 or is_nan(d):
		_fail("combat loop decay unsafe")
	_observations["loop_safety"] = {"observed": a <= 100.0 and d >= 0.0, "cap": a, "floor": d}


func _test_production_independence_static() -> void:
	var hits := 0
	for rel in [
		"res://scripts/combat/aura_scaler.gd",
		"res://scripts/combat/hit_resolver.gd",
		"res://scripts/fighters/fighter.gd",
		"res://scripts/battle/battle_scene.gd",
	]:
		if not FileAccess.file_exists(rel):
			continue
		var t: String = FileAccess.get_file_as_string(rel)
		if t.find("res://tests/") != -1:
			hits += 1
			_fail("%s imports tests/" % rel)
	_observations["production_independence"] = {"observed": hits == 0, "hits": hits}


func _write_runtime_artifact() -> void:
	var dir_res := "res://artifacts/engineering_wave011"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_res))
	var payload := {
		"schema": "gunnchos.engineering_wave011.canonical_runtime.v1",
		"test_class": "COMPONENT_RUNTIME",
		"pass": _failures.is_empty(),
		"failures": Array(_failures),
		"observations": _observations,
	}
	var f := FileAccess.open(dir_res.path_join("CANONICAL_RUNTIME_RESULT.json"), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()
	print("Wave011RuntimeTest observations keys=", _observations.keys())
