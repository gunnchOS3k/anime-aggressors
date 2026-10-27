extends "res://tests/integration/OrdinaryMatchCompletion.gd"
## Real production components seeded by an actual public-input BattleScene
## whiff. Component replay is NOT a claim of live movement/collision rollback.
const Runner = preload("res://scripts/combat/move_runner.gd")
const Guard = preload("res://scripts/combat/perfect_guard.gd")
const Machine = preload("res://scripts/fighters/fighter_state_machine.gd")
var component_result: Dictionary = {}

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.trim_prefix("--ordinary-output=")
	if output.is_empty() or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Isolated profile/output required"); quit(2); return
	var gs = root.get_node("GameState")
	gs.mode="versus"; gs.p1_fighter_id="ember-vale"; gs.p2_fighter_id="juno-spark"
	gs.p1_is_cpu=false; gs.p2_is_cpu=false; gs.stage_id="training-grid"
	root.get_node("SceneRouter").go("battle")
	for i in range(420):
		await physics_frame
		if active_battle(): break
	check(active_battle(), "real_BattleScene_started")
	if not active_battle(): finish(); return
	battle=current_scene
	var p=battle.fighter1
	for i in range(90):
		if p.is_on_floor() and p.state_machine.can_attack(): break
		await physics_frame
	keys(["attack"]); await frames(2); keys([])
	check(p.move_runner.active and p.move_runner.current_move_id()=="jab_1", "public_input_produced_real_whiff_runner")
	var source: Dictionary=p.move_runner.capture_component_state()
	var first=Runner.new();var second=Runner.new()
	# Isolated production runners have NO collision/presentation listeners and
	# do not replace the live fighters. Bind the same real actor, restore exact
	# captured frame, and execute their actual phase code to recovery.
	first.start_move(p.move_runner.move_data,p); second.start_move(p.move_runner.move_data,p)
	var dispatches: Array=[]
	first.move_started.connect(func(mid):dispatches.append(mid))
	first.move_ended.connect(func(mid):dispatches.append(mid))
	first.phase_changed.connect(func(name):dispatches.append(name))
	check(first.restore_component_state(source) and second.restore_component_state(source), "actual_MoveRunner_state_restore")
	check(dispatches.is_empty(), "restore_emits_no_move_or_phase_events")
	var other: Dictionary=source.duplicate(true);other.owner.instance=0
	check(not first.restore_component_state(other),"snapshot_cannot_transfer_fighter_ownership")
	var poisoned: Dictionary=source.duplicate(true);poisoned.active="invalid"
	check(not first.restore_component_state(poisoned) and first.capture_component_state()==source,"invalid_component_restore_is_atomic")
	var frames_equal:=true
	var replay: Array=[]
	for i in range(45):
		first.tick_sim_frame();second.tick_sim_frame()
		var a: Dictionary=first.capture_component_state();var b: Dictionary=second.capture_component_state()
		frames_equal=frames_equal and a==b
		replay.append({"step":i,"phase":a.phase,"frame":a.total_frame,"activation":a.activation_id})
	check(frames_equal and not first.active,"actual_runner_replay_matches_through_recovery")
	# A snapshot must never share mutable move or target-ledger dictionaries.
	first.move_data["damage"]=999
	first.hit_targets["shadow-only"]=true
	check(not source.hit_targets.has("shadow-only") and float(source.move_data.damage)!=999,"snapshot_move_and_target_ledgers_are_deep_copies")
	var guard=Guard.new();guard.setup(p)
	var captured_guard: Dictionary=p.perfect_guard.capture_component_state()
	check(guard.restore_component_state(captured_guard),"actual_PerfectGuard_clock_window_rearm_restore")
	for i in range(12):guard.tick()
	var future: Dictionary=guard.capture_component_state()
	check(guard.restore_component_state(captured_guard),"guard_component_rewind")
	for i in range(12):guard.tick()
	check(guard.capture_component_state()==future,"guard_window_replay_is_identical")
	var machine=Machine.new();machine.setup(p)
	var state: Dictionary=p.state_machine.capture_component_state()
	var transitions: Array=[]
	machine.state_changed.connect(func(a,b):transitions.append([a,b]))
	check(machine.restore_component_state(state) and machine.capture_component_state()==state,"actual_state_machine_clocks_restore")
	check(transitions.is_empty(),"state_restore_does_not_reenter_or_dispatch_gameplay")
	check(battle.fighter2.damage_percent==0,"public_whiff_and_shadow_replay_never_apply_damage")
	component_result={"source_runner":source,"guard":captured_guard,"state":state,"replay":replay}
	first.free();second.free();machine.free()
	finish()

func finish() -> void:
	keys([])
	var result={"PASS":failures.is_empty(),"checks":checks,"failures":failures,"components":component_result,
		"scope":"Actual production MoveRunner/PerfectGuard/state-machine component capture, atomic side-effect-free restore and isolated phase replay from live public-input whiff. NOT full Fighter, CharacterBody, projectile, contact or BattleScene/LAN rollback.",
		"HUMAN_ART_APPROVED":false,"RC2_READY":false,"V1_0_0_RELEASE_AUTHORIZED":false}
	var file=FileAccess.open(output.path_join("NATIVE_COMBAT_COMPONENTS.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"  "));file.close()
	print("NATIVE_COMBAT_COMPONENTS ","PASS" if failures.is_empty() else "FAIL"," checks=",checks.size()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
