extends "res://tests/v1_closure/ContactIntegrationReview.gd"
## Bounded ordinary spacing attempt; both players retain normal controls.
## No teleports, seeded damage, frozen targets or guaranteed contact.
func _run() -> void:
	create_timer(90).timeout.connect(func(): push_error("outer review watchdog"); quit(2))
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.get_slice("=", 1)
	var gs = root.get_node("GameState")
	gs.mode = "versus"; gs.stage_id = "training-grid"
	gs.p1_fighter_id = "kaia-windrow"; gs.p2_fighter_id = "juno-spark"
	gs.p1_is_cpu = false; gs.p2_is_cpu = false; gs.stocks = 3; gs.match_timer_seconds = 180
	gs.p1_body_variant = "female"; gs.p2_body_variant = "male"
	root.get_node("SceneRouter").go("battle"); await wait(220)
	battle = current_scene; p = battle.fighter1; d = battle.fighter2
	for actor in [p, d]:
		mesh_cache[actor.model_3d.get_instance_id()] = cache_meshes(actor.model_3d)
		var other = d if actor == p else p
		actor.combat_feedback.feedback_triggered.connect(func(info): pre_contact(actor, other, info))
		actor.hit_resolver.hit_confirmed.connect(contact)
	label = "public approach to outer range"
	for i in range(90):
		if absf(d.position.x - p.position.x) <= 88: break
		keys(1, ["right"]); keys(2, ["left"]); await wait(1)
	keys(1, []); keys(2, []); await wait(18)
	keys(2, ["shield"]); await wait(5)
	await strike(1, ["attack"], "outer Kaia light / Juno shield", 45)
	keys(2, []); await wait(12)
	await strike(2, ["attack", "special"], "outer Juno heavy counter", 70)
	await strike(1, ["attack", "special"], "outer Kaia heavy response", 70)
	label = "public retreat and whiff"; keys(1, ["left"]); keys(2, ["right"]); await wait(12)
	keys(1, []); keys(2, []); await wait(18)
	await strike(1, ["attack"], "outer deliberate whiff", 40)
	label = "outer return to neutral"; await wait(20)
	write_evidence(true)
	print("OUTER_MELEE_REVIEW_COMPLETE frames=", review_frames, " contacts=", hits.size()); quit()
