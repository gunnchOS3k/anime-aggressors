extends "res://tests/integration/OrdinaryMatchCompletion.gd"
## Real Party pickup/taunt/ultimate paths, with EXPLICIT staged item pickups.
## No earned-item, active-opponent, art, network or full rollback acceptance.
const IDS := ["ember-vale", "rook-ironside", "juno-spark", "kaia-windrow", "nix-calder", "orion-vell", "vesper-nyx", "yin", "yang"]
var rows: Array = []

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.trim_prefix("--ordinary-output=")
	if output.is_empty() or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Isolated profile/output required"); quit(2); return
	var campaign_before := JSON.stringify(root.get_node("CampaignRuntime").progress)
	for fid in IDS:
		for body in ["male", "female"]:
			await exercise(fid, body)
	check(campaign_before == JSON.stringify(root.get_node("CampaignRuntime").progress), "component_cases_preserve_Story_progress")
	finish()

func exercise(fid: String, body: String) -> void:
	keys([])
	var gs = root.get_node("GameState")
	# Legal pre-match settings. The pickup below is a declared fixture, not a
	# naturally earned item or manufactured combat contact.
	gs.mode = "versus"; gs.items_enabled = true; gs.hazards_enabled = false
	gs.p1_fighter_id = fid; gs.p1_body_variant = body
	gs.p2_fighter_id = "juno-spark" if fid != "juno-spark" else "kaia-windrow"
	gs.p2_body_variant = "male"; gs.p1_is_cpu = false; gs.p2_is_cpu = false
	gs.stage_id = "training-grid"; gs.stocks = 3; gs.match_timer_seconds = 0; gs.match_type = "stock_untimed"
	root.get_node("SceneRouter").go("battle")
	for i in range(420):
		await physics_frame
		if active_battle(): break
	var label := fid + ":" + body
	check(active_battle(), label + ":actual_BattleScene")
	if not active_battle(): return
	battle = current_scene
	var p = battle.fighter1
	for i in range(90):
		if p.is_on_floor() and p.state_machine.can_attack(): break
		await physics_frame
	if body == "female":
		keys(["left"]); await frames(1); keys([]); await frames(2)
	var face: int = p.facing
	check(p.model_3d.get_body_variant() == body and face == (-1 if body == "female" else 1), label + ":real_body_and_public_facing")
	# Main --script is compiled before autoload registration. Reuse the exact
	# production script already loaded by the live Fighter after GameState,
	# rather than preloading its autoload dependency before the scene exists.
	var shadow = p.party_overdrive.get_script().new(); shadow.setup(p)
	var base: Dictionary = p.party_overdrive.capture_component_state()
	check(shadow.restore_component_state(base), label + ":base_restore")
	var invalid: Dictionary = base.duplicate(true); invalid.owner.instance = 0
	check(not shadow.restore_component_state(invalid) and shadow.capture_component_state() == base, label + ":ownership_reject_atomic")
	invalid = base.duplicate(true); invalid._resetting = true
	check(not shadow.restore_component_state(invalid) and shadow.capture_component_state() == base, label + ":mid_reset_rejected")
	invalid = base.duplicate(true); invalid.remaining = int(shadow.doc.duration_frames) + 1
	check(not shadow.restore_component_state(invalid) and shadow.capture_component_state() == base, label + ":extended_duration_rejected")
	invalid = base.duplicate(true); invalid.pulses_fired[-1] = true
	check(not shadow.restore_component_state(invalid) and shadow.capture_component_state() == base, label + ":nonexistent_pulse_rejected")
	var token: int = battle._hazard_runtime.spawn_party_item("prism_heart", p.global_position + Vector2(0, -24))
	await frames(2)
	check(token > 0 and p.party_overdrive.state == "ITEM_ACQUIRED", label + ":declared_real_pickup")
	keys(["taunt"]); await frames(2); keys([])
	var startup: Dictionary = p.party_overdrive.capture_component_state()
	var startup_ok: bool = startup.state == "TRANSFORMATION_STARTUP" and startup.startup_left > 12
	check(startup_ok, label + ":public_transform_countdown")
	var restored: bool = shadow.restore_component_state(startup)
	check(restored, label + ":startup_restore")
	if not startup_ok or not restored:
		await leave_case(); return
	for i in range(10): shadow.tick()
	var first: Dictionary = shadow.capture_component_state()
	shadow.restore_component_state(startup)
	for i in range(10): shadow.tick()
	check(shadow.capture_component_state() == first and p.party_overdrive.capture_component_state() == startup, label + ":startup_replay_no_live_side_effects")
	await frames(38)
	var active: Dictionary = p.party_overdrive.capture_component_state()
	var active_ok: bool = active.state == "OVERDRIVE_ACTIVE" and active.remaining > 12 and not active._previous_presentation.is_empty()
	check(active_ok, label + ":actual_active_state_and_restore_look")
	restored = shadow.restore_component_state(active)
	check(restored, label + ":active_restore")
	if not active_ok or not restored:
		await leave_case(); return
	for i in range(12): shadow.tick()
	first = shadow.capture_component_state()
	shadow.restore_component_state(active)
	for i in range(12): shadow.tick()
	check(shadow.capture_component_state() == first and p.party_overdrive.capture_component_state() == active, label + ":duration_replay_no_expiry_or_live_mutation")
	# Ensure mutable restoration history/look records never alias the source.
	shadow.history.append({"probe":"shadow-only"})
	shadow._previous_presentation["component_probe"] = true
	check(not active._previous_presentation.has("component_probe") and active.history.size() + 1 == shadow.history.size(), label + ":deep_copied_restore_containers")
	keys(["taunt"]); await frames(2); keys([])
	var ultimate: Dictionary = p.party_overdrive.capture_component_state()
	check(ultimate.state == "ULTIMATE_STARTUP" and ultimate.ultimate_used, label + ":public_original_ultimate")
	check(shadow.restore_component_state(ultimate), label + ":ultimate_ownership_restore")
	var pulses: Array = p._current_move.get("pulses", [])
	var pulse_result: Dictionary = {"applicable":pulses.size() > 1}
	if pulses.size() > 1:
		# Frame1 also owns recoil/audio. Only replay an already-fired SECOND
		# pulse at its exact actual active frame; this cannot reapply frame1.
		var second_frame := int(pulses[1].frame)
		for i in range(100):
			if p.party_overdrive.pulses_fired.has(1): break
			await physics_frame
		var captured: Dictionary = p.party_overdrive.capture_component_state()
		var exact: bool = p.move_runner.phase == "active" and p.move_runner.frame_in_phase == second_frame and second_frame > 1
		check(exact and captured.pulses_fired.has(1), label + ":actual_second_pulse_captured")
		var before_shots: int = p.projectile_spawner.count()
		var velocity_before: Vector2 = p.velocity
		restored = shadow.restore_component_state(captured)
		check(restored, label + ":pulse_ledger_restore")
		if exact and captured.pulses_fired.has(1) and restored: shadow.on_active(p.move_runner.move_data)
		check(p.projectile_spawner.count() == before_shots and p.velocity == velocity_before, label + ":restored_pulse_cannot_respawn_or_reapply_impulse")
		pulse_result = {"applicable":true, "frame":p.move_runner.frame_in_phase, "ledger":captured.pulses_fired.duplicate(true), "shots":before_shots}
	else:
		check(fid == "rook-ironside" and shadow.counter_armed == ultimate.counter_armed, label + ":authored_retaliation_not_invented_pulse")
	rows.append({"fighter":fid, "body":body, "facing":face, "startup":startup, "active":active, "ultimate":ultimate, "pulse":pulse_result})
	# No shadow lifecycle callback is attached to the live fighter. Exit owns
	# actual projectile/form cleanup; never reset stats to manufacture a pass.
	shadow = null
	await leave_case()

func leave_case() -> void:
	keys([])
	root.get_node("SceneRouter").go("main_menu")
	await frames(5)
	battle = null

func finish() -> void:
	keys([])
	var result := {"PASS":failures.is_empty(), "checks":checks, "failures":failures, "rows":rows,
		"scope":"Nine fighters/both bodies, alternating public facings; declared live item pickups and ordinary taunt/ultimate. Actual Party logic capture, no-side-effect shadow restore/replay and second-pulse idempotency. NOT full live Fighter/projectile/physics rollback, earned pickups, active CPU, native art or human approval.",
		"HUMAN_ART_APPROVED":false, "RC2_READY":false, "V1_0_0_RELEASE_AUTHORIZED":false}
	var file = FileAccess.open(output.path_join("PARTY_COMBAT_COMPONENTS.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  ")); file.close()
	print("PARTY_COMBAT_COMPONENTS ", "PASS" if failures.is_empty() else "FAIL", " rows=", rows.size(), " failures=", failures)
	quit(0 if failures.is_empty() else 1)
