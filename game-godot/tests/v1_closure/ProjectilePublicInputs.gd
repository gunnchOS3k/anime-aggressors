extends SceneTree
## Two ordinary local-player input streams. Neither fighter is frozen or has
## seeded aura/damage. This is not active-CPU or human-owner acceptance.
var output := ""
var p; var d; var battle
var held := [[], []]
var frames := 0
var inputs: Array = []
var cases: Array = []
var hits: Array = []
var bars: Array = []
var stamps: Array = []
func _init() -> void: call_deferred("run")
func keys(slot: int, actions: Array) -> void:
	if held[slot - 1] == actions: return
	inputs.append({"frame": Engine.get_physics_frames(), "slot": slot, "actions": actions.duplicate()})
	for key in held[slot - 1]:
		if key not in actions: Input.action_release("p%d_%s" % [slot, key])
	for key in actions:
		if key not in held[slot - 1]: Input.action_press("p%d_%s" % [slot, key], .55 if key in ["left", "right"] else 1.0)
	held[slot - 1] = actions.duplicate()
func wait(count: int) -> void:
	for i in range(count):
		if not bars.is_empty():
			var observed := Engine.get_process_frames() - 1
			for bit in range(20): bars[bit].color = Color.WHITE if observed & (1 << bit) else Color.BLACK
			stamps.append({"trace_frame": observed, "physics_frame": Engine.get_physics_frames()})
		frames += 1
		if battle != null and frames % 30 == 0: write_evidence()
		await physics_frame
func write_evidence() -> void:
	var f = FileAccess.open(output.path_join("projectile_public_inputs.json"), FileAccess.WRITE)
	var renderer = preload("res://scripts/visual/spectral_feedback_renderer.gd").obtain(p)
	var presentation: Dictionary = renderer.clash_presentation.evidence() if "clash_presentation" in renderer else {}
	f.store_string(JSON.stringify({"scope": "two normal public-input players in native BattleScene; neither CPU nor human owner acceptance; no seeded aura/damage/position or forced outcomes", "frames": frames, "cases": cases, "hits": hits, "inputs": inputs, "frame_stamps": stamps, "presentation_history": renderer.history, "clash_presentation": presentation, "controls_enabled": [p.controls_enabled, d.controls_enabled], "unmodified_aura_requirements": true, "history": battle._battle_sim.projectile_interactions.history}, "  ")); f.close()
func shoot(label: String) -> void:
	var begin: int = battle._battle_sim.projectile_interactions.history.size()
	var damage_before := [p.damage_percent, d.damage_percent]
	var aura := [p.aura, d.aura]
	var shot_frame := Engine.get_physics_frames()
	keys(1, ["special"]); keys(2, ["special"]); await wait(1)
	keys(1, []); keys(2, []); await wait(130)
	cases.append({"case": label, "public_input_frame": shot_frame, "aura_at_input": aura, "damage_before": damage_before, "damage_after": [p.damage_percent, d.damage_percent], "interceptions": battle._battle_sim.projectile_interactions.history.slice(begin)})
func charge_both(target: float) -> void:
	var ready := [false, false]
	for i in range(240):
		ready[0] = ready[0] or p.aura >= target
		ready[1] = ready[1] or d.aura >= target
		keys(1, [] if ready[0] else ["special", "shield"])
		keys(2, [] if ready[1] else ["special", "shield"])
		await wait(1)
		if ready[0] and ready[1]: break
	keys(1, []); keys(2, []); await wait(4)
func run() -> void:
	create_timer(60).timeout.connect(func(): push_error("public projectile watchdog"); quit(2))
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.get_slice("=", 1)
		if arg.begins_with("--review-vfx-mode="): root.get_node("StoryDialogue").set_option("vfx_intensity", arg.get_slice("=", 1))
	var gs = root.get_node("GameState")
	gs.mode = "versus"; gs.stage_id = "training-grid"; gs.p1_fighter_id = "kaia-windrow"; gs.p2_fighter_id = "juno-spark"; gs.p1_is_cpu = false; gs.p2_is_cpu = false; gs.stocks = 9; gs.match_timer_seconds = 180
	root.get_node("SceneRouter").go("battle")
	await wait(220)
	battle = current_scene; p = battle.fighter1; d = battle.fighter2
	if "--frame-barcode" in OS.get_cmdline_user_args():
		var layer := CanvasLayer.new(); layer.layer = 100; battle.add_child(layer)
		for bit in range(20):
			var rect := ColorRect.new(); rect.position = Vector2(20 + bit * 12, 190); rect.size = Vector2(10, 24); layer.add_child(rect); bars.append(rect)
	for actor in [p, d]:
		actor.hit_resolver.hit_confirmed.connect(func(a, b, info): hits.append({"frame": Engine.get_physics_frames(), "attacker_slot": a.slot, "defender_slot": b.slot, "result": info.contact_result, "damage": info.damage, "owner": info.contact_owner}))
	# Reach the exchange with movement inputs; never assign positions/facing.
	for i in range(120):
		if d.position.x - p.position.x <= 155: break
		keys(1, ["right"]); keys(2, ["left"]); await wait(1)
	keys(1, []); keys(2, []); await wait(8)
	await shoot("equal_quick")
	if not "--clash-quick-breakthrough" in OS.get_cmdline_user_args():
		await charge_both(66)
		await shoot("equal_medium")
		if "--clash-major-exchange" in OS.get_cmdline_user_args():
			await charge_both(88)
			await shoot("equal_full_major")
		# Genuine passive decay; the short movie recipe omits this exchange.
		for i in range(1000):
			if p.aura < 15 and d.aura < 15: break
			await wait(1)
	for i in range(240):
		if d.aura >= 88: break
		keys(2, ["special", "shield"]); await wait(1)
	keys(2, []); await wait(4)
	await shoot("juno_full_vs_kaia_quick")
	keys(1, []); keys(2, [])
	write_evidence()
	print("PROJECTILE_PUBLIC_INPUTS_COMPLETE cases=", cases.size(), " interceptions=", battle._battle_sim.projectile_interactions.history.size())
	quit()
