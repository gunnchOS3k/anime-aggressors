extends SceneTree
## Real resolver/emitter stress fixture with explicit position/aura prerequisites.
## Separate from ordinary-input movie evidence and human aesthetic acceptance.
const Data = preload("res://scripts/data/data_loader.gd")
const Resolver = preload("res://scripts/combat/projectile_interactions.gd")
var output := ""
var failures: Array = []
var rows: Array = []
var p; var d; var renderer
func _init() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label); push_error(label)
func phase(label: String) -> void:
	print("CLASH_FIXTURE_PHASE ", label)
	if output.is_empty(): return
	var path := output.path_join("fixture_phases.jsonl")
	var f = FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	if f:
		f.seek_end(); f.store_line(JSON.stringify({"phase": label, "milliseconds": Time.get_ticks_msec()})); f.close()
func snapshot(name: String) -> void:
	phase("render:" + name)
	# Flush deferred CanvasItem transforms before forcing this diagnostic draw.
	# A background native window need not emit frame_post_draw; do not wait on it.
	await process_frame
	RenderingServer.force_sync()
	RenderingServer.force_draw(false, 0.0)
	var picture := root.get_texture().get_image()
	check(not picture.is_empty() and picture.save_png(output.path_join(name)) == OK, "native_snapshot:" + name)
func pair(amounts: Array, point: Vector2) -> Dictionary:
	var shots: Array = []
	for i in range(2):
		var actor = p if i == 0 else d
		var shot = actor.projectile_spawner.spawn_from_move(Data.find_move(actor.move_manifest, "neutral_special_projectile"), amounts[i])
		shot.global_position = point; shot.spawn_bounds = shot.world_bounds(); shots.append(shot)
	var sim = Resolver.new(); var signaled: Array = []
	sim.interception_confirmed.connect(func(e): signaled.append(e))
	sim.begin_frame([p, d]); sim.resolve_frame([p, d])
	check(sim.history.size() == 1 and signaled.size() == 1, "one_authoritative_signal")
	return {"event": sim.history[0], "a": shots[0], "b": shots[1]}
func clear() -> void:
	p.projectile_spawner.clear_all(); d.projectile_spawner.clear_all()
	renderer._process(.7)
func run() -> void:
	create_timer(60).timeout.connect(func(): phase("WATCHDOG"); quit(2))
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.get_slice("=", 1)
	phase("scene_setup")
	var gs = root.get_node("GameState"); gs.mode = "versus"; gs.stage_id = "training-grid"; gs.p1_fighter_id = "kaia-windrow"; gs.p2_fighter_id = "juno-spark"; gs.p2_is_cpu = false; gs.stocks = 9
	root.get_node("SceneRouter").go("battle")
	for i in range(220): await physics_frame
	p = current_scene.fighter1; d = current_scene.fighter2
	p.controls_enabled = false; d.controls_enabled = false
	renderer = preload("res://scripts/visual/spectral_feedback_renderer.gd").obtain(p)
	check(is_instance_valid(renderer.clash_presentation.indicator) == ("--clash-indicators" in OS.get_cmdline_user_args()), "indicator_only_opt_in")
	for mode in ["Full", "Balanced", "Reduced"]:
		root.get_node("StoryDialogue").set_option("vfx_intensity", mode)
		for amounts in [[0, 0], [50, 50], [0, 75], [75, 75], [75, 50]]:
			phase(mode + ":" + str(amounts))
			clear()
			for i in range(40): await physics_frame
			var start: int = renderer.history.size()
			var result := pair(amounts, Vector2(0, 268))
			var event: Dictionary = result.event
			var cue: Dictionary = renderer.clash_presentation.history[-1]
			var major: bool = maxi(event.before[0], event.before[1]) >= 4 and mini(event.before[0], event.before[1]) >= 2
			check(cue.primary_slot >= 0 and cue.primary_kind == (22 if major else 20 if event.result == "mutual_cancel" else 21), mode + ":distinct_primary")
			var slot: Dictionary = renderer.slots[cue.primary_slot]
			check(slot.active and slot.world == Vector2(0, 268) and slot.mesh.z_index + renderer.z_index == 25, mode + ":exact_contact_and_layer")
			check(float(slot.mesh.material.get_shader_parameter("flash")) == 0, mode + ":nonflashing_primary")
			check(cue.primary_life >= .26 and cue.primary_life <= .36, mode + ":bounded_recognition_beat")
			check(renderer.history.slice(start).filter(func(e): return e.kind == 5).is_empty(), mode + ":no_two_extra_dissipations")
			if major and mode == "Full":
				var surfaces: Array = renderer.history.slice(start).filter(func(e): return e.kind == 18)
				check(surfaces.size() == 2 and surfaces[0].fid != surfaces[1].fid, "major_full_mixed_environment")
			if event.result == "breakthrough":
				var winner = result.a if result.a.active else result.b
				check(cue.direction == [winner.direction.x, winner.direction.y], mode + ":winner_direction")
				check(int(renderer.slots[winner._flight_slot].get("integrity_layers", 0)) == winner.integrity, mode + ":counted_remaining_shells")
				check(renderer.slots[winner._flight_slot].strength >= .7, mode + ":survivor_core_stays_readable")
			if mode == "Reduced": check(not cue.secondary_admitted, "reduced_primary_without_decoration")
			var before_count: int = renderer.clash_presentation.confirmed_count
			renderer.projectile_contact(p.fighter_id, d.fighter_id, Vector2(0, 268), Vector2.RIGHT, event.result, event.event_id, p, event)
			check(renderer.clash_presentation.confirmed_count == before_count, "presentation_dedup")
			rows.append({"mode": mode, "case": amounts, "event": event, "cue": cue.duplicate(true), "scope": "authoritative collision fixture, not ordinary input"})
			if major and "--clash-stress-png" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
				await snapshot("clash_major_" + mode + "_" + str(amounts[1]) + ".png")
		clear()
		for i in range(40): await physics_frame
		var count: int = renderer.clash_presentation.confirmed_count
		var primaries: int = renderer.clash_presentation.primary_count
		var suppressed: int = renderer.clash_presentation.decoration_suppressed
		for i in range(12): pair([0, 0], Vector2((i % 4 - 1.5) * 26, 250 + (i / 4) * 12))
		check(renderer.clash_presentation.confirmed_count == count + 12 and renderer.clash_presentation.primary_count == primaries + 12, mode + ":all_stress_events_have_primary")
		check(renderer.clash_presentation.decoration_suppressed >= suppressed + 9, mode + ":repetition_reduces_decoration")
		check(renderer.clash_presentation.voices.size() <= (2 if mode == "Reduced" else 3 if mode == "Balanced" else 4), mode + ":bounded_audio_concurrency")
		check(renderer.active_count() <= (32 if mode == "Reduced" else 96), mode + ":bounded_pool")
		var simplified: Array = renderer.slots.filter(func(s): return s.active and s.kind in [20,21] and float(s.clash_ornament) <= .12)
		check(simplified.size() >= 12, mode + ":crowded_primary_ornament_reduced_without_hiding_result")
		var stress := {"mode": mode, "scenario": "12 nearby confirmed quick collisions in one fixed frame; explicit stress prerequisites", "events": 12, "primary_cues": renderer.clash_presentation.primary_count - primaries, "secondary_suppressed": renderer.clash_presentation.decoration_suppressed - suppressed, "audio_voices": renderer.clash_presentation.voices.size(), "active_meshes": renderer.active_count(), "camera_impulses": 0, "source": "real native resolver/spawner, not forced fighter damage"}
		rows.append(stress)
		if "--clash-stress-png" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
			await snapshot("clash_stress_" + mode + ".png")
		var major_busy := pair([75, 75], Vector2(0, 268))
		check(renderer.clash_presentation.history[-1].audio_admitted and renderer.clash_presentation.history[-1].primary_kind == 22, mode + ":major_cue_preempts_minor_sound_window")
		rows.append({"mode": mode, "scenario": "major immediately after quick-shot burst", "event": major_busy.event, "cue": renderer.clash_presentation.history[-1].duplicate(true)})
		clear()
		check(renderer.clash_presentation.voices.is_empty(), mode + ":audio_envelopes_cleaned_up")
	clear()
	var f = FileAccess.open(output.path_join("clash_readability.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS": failures.is_empty(), "failures": failures, "rows": rows, "metrics": renderer.clash_presentation.evidence(), "scope": "declared stress/prerequisite fixture; ordinary public play and native movies separate"}, "  ")); f.close()
	print("CLASH_READABILITY ", "PASS" if failures.is_empty() else "FAIL", " rows=", rows.size(), " failures=", failures.size()); quit(0 if failures.is_empty() else 1)
