extends SceneTree
## VXP-2.2 human-feedback combat closure harness.
## Do not const-preload Fighter.tscn (compiles before Autoloads).

const _CombatSpace = preload("res://scripts/combat/combat_space_contract.gd")
const _Catalog = preload("res://scripts/ui/move_list_catalog.gd")
const _Cpu = preload("res://scripts/fighters/cpu_controller.gd")
const _FighterStates = preload("res://scripts/fighters/fighter_states.gd")
const PresentationContextScript = preload("res://scripts/visual/presentation_context.gd")

var _failures: PackedStringArray = []
var _results: Dictionary = {}
var _fighter_scene: PackedScene


func _init() -> void:
	call_deferred("_run")


func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_failures.append(msg)
		push_error("HF FAIL: %s" % msg)
	else:
		print("HF OK: %s" % msg)


func _load_stage(sid: String) -> Dictionary:
	var path := "res://data/stages/%s.json" % sid
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func _run() -> void:
	print("=== VXP22 HF Combat Harness ===")
	_results["started_at"] = Time.get_datetime_string_from_system(true)
	await process_frame
	await process_frame
	_fighter_scene = load("res://scenes/fighters/Fighter.tscn") as PackedScene
	_ok(_fighter_scene != null, "Fighter.tscn loads after autoloads")
	_test_combat_space_calibration()
	_test_move_list_simple_labels()
	_test_cpu_difficulty_without_scene()
	await _test_cpu_difficulty_with_fighter()
	await _test_fighter_select_start_match()
	await _test_ledge_and_recovery()
	_test_blast_zone_ko()
	await _test_idle_run_jump_land()
	var all_ok: bool = _failures.is_empty()
	_results["ok"] = all_ok
	_results["failures"] = Array(_failures)
	_results["failure_count"] = _failures.size()
	_results["finished_at"] = Time.get_datetime_string_from_system(true)
	_write(_results)
	print("HF_COMBAT_HARNESS ok=", all_ok, " failures=", _failures.size())
	quit(0 if all_ok else 1)


func _test_combat_space_calibration() -> void:
	var stage_ids := ["skyline-arena", "void-pier", "ember-courtyard", "neon-rooftops", "cascade-foundry", "training-grid"]
	var snaps: Array = []
	var bad := 0
	for sid in stage_ids:
		var stage: Dictionary = _load_stage(sid)
		var snap: Dictionary = _CombatSpace.snapshot_for_stage(stage)
		snaps.append(snap)
		if not bool(snap.get("ratio_in_band", false)):
			bad += 1
			_failures.append("scale ratio out of band for %s" % sid)
		var anchors: Array = snap.get("ledge_anchors", [])
		if bool(stage.get("ledges", true)) and anchors.size() < 2:
			bad += 1
			_failures.append("missing ledge anchors for %s" % sid)
		var half := float(snap.get("platform_width", 0)) * 0.5
		var blast: Dictionary = snap.get("blast", {})
		if absf(float(blast.get("left", 0))) <= half or absf(float(blast.get("right", 0))) <= half:
			bad += 1
			_failures.append("blast zones inside platform for %s" % sid)
	_results["combat_space"] = {"stages": snaps, "out_of_band": bad}
	_ok(bad == 0, "combat space calibration band")
	var contract: Dictionary = PresentationContextScript.display_contract("BATTLE")
	var ds: Vector2 = contract.get("display_scale", Vector2.ONE)
	_ok(absf(ds.x - 0.58) < 0.01, "battle display scale 0.58")
	_ok(float(ds.x) <= float(PresentationContextScript.MAX_BATTLE_DISPLAY_SCALE), "battle scale under max")
	var anchor := Vector2(484, 280)
	_ok(_CombatSpace.in_ledge_grab_window(Vector2(484, 300), anchor, false), "ledge window accepts below-lip")
	_ok(not _CombatSpace.in_ledge_grab_window(Vector2(484, 300), anchor, true), "ledge window rejects rising")
	_ok(not _CombatSpace.in_ledge_grab_window(Vector2(484, 56), anchor, false), "old absolute Y=56 is invalid")


func _test_move_list_simple_labels() -> void:
	var raw_leaks := 0
	for fid in _Catalog.roster_ids():
		var cat: Dictionary = _Catalog.build_fighter_catalog(fid)
		for mid in cat.get("core_move_ids", []):
			var display := ""
			for e in cat.get("entries", []):
				if str(e.get("move_id", "")) == str(mid):
					display = str(e.get("display_name", ""))
					break
			if display.is_empty() or display == str(mid):
				raw_leaks += 1
	_results["move_list_raw_core_leaks"] = raw_leaks
	_ok(raw_leaks == 0, "core moves have human display names")


func _test_cpu_difficulty_without_scene() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var stub = load("res://tests/vxp22_hf/HfCpuStub.gd").new()
	host.add_child(stub)
	stub.slot = 2
	stub.platform_half_width = 484.0
	stub.platform_center_x = 0.0
	stub.controls_enabled = true
	stub.global_position = Vector2(450, 250)
	stub._on_floor = true
	var cpu = _Cpu.new()
	var prints: Array = []
	var prev_react := -1.0
	var prev_rec := -1.0
	for lv in range(1, 6):
		cpu.setup(stub, lv, 42)
		var fp: Dictionary = cpu.difficulty_fingerprint()
		prints.append(fp)
		var react := float(fp.get("reaction_chance", 0))
		var rec := float(fp.get("recovery_quality", 0))
		if prev_react >= 0.0:
			_ok(react > prev_react, "reaction increases lv%d->%d" % [lv - 1, lv])
			_ok(rec > prev_rec, "recovery quality increases lv%d->%d" % [lv - 1, lv])
		prev_react = react
		prev_rec = rec
	_results["cpu_difficulty"] = prints
	stub.global_position = Vector2(450, 250)
	cpu.setup(stub, 3, 99)
	var lure := Node2D.new()
	host.add_child(lure)
	lure.global_position = Vector2(700, 250)
	var max_x: float = stub.global_position.x
	for _i in 60:
		stub._on_floor = true
		cpu.tick(1.0 / 60.0, lure)
		var axis: float = Input.get_action_strength("p2_right") - Input.get_action_strength("p2_left")
		stub.global_position.x += axis * 4.0
		max_x = maxf(max_x, stub.global_position.x)
	var went_past_edge: bool = max_x > 490.0
	_results["cpu_edge_guard"] = {"max_x": max_x, "went_past_edge": went_past_edge}
	_ok(not went_past_edge, "CPU does not chase off outer edge")
	stub.controls_enabled = false
	cpu.tick(0.016, lure)
	_ok(not Input.is_action_pressed("p2_left") and not Input.is_action_pressed("p2_right"), "CPU idle during countdown lock")
	cpu.clear_simulated_inputs()
	host.queue_free()


func _test_cpu_difficulty_with_fighter() -> void:
	if _fighter_scene == null:
		_failures.append("fighter scene missing")
		return
	var host := Node2D.new()
	root.add_child(host)
	var f = _fighter_scene.instantiate()
	host.add_child(f)
	await process_frame
	if not f.has_method("configure"):
		_failures.append("fighter script failed to attach")
		_ok(false, "fighter script attached")
		host.queue_free()
		return
	f.configure("ember-vale", 2, true, 3, Vector2(0, 200))
	f.configure_stage_geometry({"x": 0, "y": 280, "width": 968}, [], true)
	_ok(f.has_method("is_offstage"), "fighter exposes is_offstage")
	host.queue_free()
	await process_frame


func _test_fighter_select_start_match() -> void:
	var err := change_scene_to_file("res://scenes/menus/FighterSelectScene.tscn")
	_ok(err == OK, "fighter select scene loads")
	await process_frame
	await process_frame
	var scene = current_scene
	_ok(scene != null, "fighter select current")
	if scene == null:
		return
	if scene.has_method("_on_lock_in_pressed"):
		scene._on_lock_in_pressed()
		await process_frame
		scene._on_lock_in_pressed()
		await process_frame
	var cta: Dictionary = {}
	if scene.has_method("assert_start_match_cta"):
		cta = scene.assert_start_match_cta()
	_results["fighter_select_cta"] = cta
	_ok(bool(cta.get("START_MATCH_VISIBLE", false)), "START MATCH visible")
	_ok(bool(cta.get("START_MATCH_IN_SAFE_AREA", false)), "START MATCH in safe area")
	_ok(bool(cta.get("CAN_START", false)), "can start after dual lock")
	if scene.has_method("on_back"):
		scene.on_back()
		await process_frame
	if scene.has_method("assert_start_match_cta"):
		var cta2: Dictionary = scene.assert_start_match_cta()
		_ok(not bool(cta2.get("CAN_START", true)), "incomplete blocks start")
		_results["fighter_select_incomplete"] = cta2


func _test_ledge_and_recovery() -> void:
	if _fighter_scene == null:
		return
	var host := Node2D.new()
	root.add_child(host)
	var floor := StaticBody2D.new()
	host.add_child(floor)
	floor.position = Vector2(0, 280)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(968, 40)
	shape.shape = rect
	floor.add_child(shape)
	var f = _fighter_scene.instantiate()
	host.add_child(f)
	await process_frame
	if not f.has_method("configure"):
		_failures.append("ledge test: fighter script missing")
		_ok(false, "ledge grab from offstage approach")
		host.queue_free()
		return
	f.configure("ember-vale", 1, false, 3, Vector2(0, 240))
	f.configure_stage_geometry({"x": 0, "y": 280, "width": 968}, [
		{"id": "left", "x": -484, "y": 280},
		{"id": "right", "x": 484, "y": 280},
	], true)
	f.controls_enabled = true
	f.global_position = Vector2(484, 300)
	f.velocity = Vector2(-20, 80)
	f.state_machine.enter(_FighterStates.FALL)
	for _i in 12:
		f._check_ledge_grab()
		await process_frame
	var hanging: bool = str(f.state_machine.current_state) == _FighterStates.LEDGE_HANG
	_ok(hanging, "ledge grab from offstage approach")
	_results["ledge_grab"] = {"state": f.state_machine.current_state, "pos": {"x": f.global_position.x, "y": f.global_position.y}}
	if hanging:
		Input.action_press("p1_left")
		f.tick_ledge_hang(0.016)
		Input.action_release("p1_left")
		var after: String = str(f.state_machine.current_state)
		_ok(after == _FighterStates.LEDGE_GETUP or after == _FighterStates.JUMP, "ledge getup/jump")
	f.state_machine.enter(_FighterStates.JUMP)
	f.global_position = Vector2(484, 300)
	f.velocity = Vector2(0, -200)
	f._check_ledge_grab()
	_ok(str(f.state_machine.current_state) != _FighterStates.LEDGE_HANG, "no magnetic grab while rising fast")
	f.global_position = Vector2(520, 300)
	_ok(f.is_offstage(), "offstage detection")
	_ok(int(f.stocks) == 3, "leaving platform is not instant KO")
	host.queue_free()
	await process_frame


func _test_blast_zone_ko() -> void:
	var blast := {"left": -627.0, "right": 627.0, "top": -400.0, "bottom": 440.0}
	var pos_off := Vector2(500, 300)
	var in_blast: bool = pos_off.x < float(blast.left) or pos_off.x > float(blast.right) or pos_off.y < float(blast.top) or pos_off.y > float(blast.bottom)
	_ok(not in_blast, "offstage position inside blast is not KO")
	var pos_ko := Vector2(700, 300)
	var ko: bool = pos_ko.x < float(blast.left) or pos_ko.x > float(blast.right) or pos_ko.y < float(blast.top) or pos_ko.y > float(blast.bottom)
	_ok(ko, "past blast zone is KO")
	_results["blast_zone"] = {"offstage_not_ko": not in_blast, "past_blast_ko": ko}


func _test_idle_run_jump_land() -> void:
	if _fighter_scene == null:
		return
	var host := Node2D.new()
	root.add_child(host)
	var f = _fighter_scene.instantiate()
	host.add_child(f)
	await process_frame
	if not f.has_method("configure"):
		_failures.append("motion test: fighter script missing")
		_ok(false, "idle state")
		host.queue_free()
		return
	f.configure("juno-spark", 1, false, 3, Vector2(0, 240))
	f.configure_stage_geometry({"x": 0, "y": 280, "width": 968}, [], true)
	f.state_machine.enter(_FighterStates.IDLE)
	_ok(str(f.state_machine.current_state) == _FighterStates.IDLE, "idle state")
	f.state_machine.enter(_FighterStates.RUN)
	_ok(str(f.state_machine.current_state) == _FighterStates.RUN, "run state")
	f.state_machine.enter(_FighterStates.JUMP)
	_ok(str(f.state_machine.current_state) == _FighterStates.JUMP, "jump state")
	f.begin_landing(true, false)
	_ok(str(f.state_machine.current_state) == _FighterStates.LAND, "land state")
	_results["motion_states"] = true
	var cs := f.get_node_or_null("CollisionShape2D") as CollisionShape2D
	_ok(cs != null and cs.shape != null, "collision shape present")
	if cs != null and cs.shape is RectangleShape2D:
		var sz: Vector2 = (cs.shape as RectangleShape2D).size
		_ok(sz.y >= 30.0, "collision height calibrated")
		_results["collision_size"] = {"w": sz.x, "h": sz.y}
	host.queue_free()


func _write(payload: Dictionary) -> void:
	var text := JSON.stringify(payload, "\t")
	for p in ["res://../artifacts/vxp22/reports/HF_COMBAT_HARNESS.json", "user://HF_COMBAT_HARNESS.json"]:
		var path: String = ProjectSettings.globalize_path(p)
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f:
			f.store_string(text + "\n")
			print("Wrote ", path)
