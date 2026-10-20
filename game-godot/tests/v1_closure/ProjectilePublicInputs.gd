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
var observed_shots: Dictionary = {}
var fighter_impacts: Array = []
var flight_samples: Array = []
var physical_samples: Array = []
func observe_impact_review() -> void:
	if battle == null or not "--fighter-impact-review" in OS.get_cmdline_user_args(): return
	for actor in [p,d]:
		for shot in actor.projectile_spawner.active_projectiles:
			var id:int=shot.get_instance_id()
			if observed_shots.has(id):continue
			observed_shots[id]=weakref(shot)
			shot.projectile_hit.connect(func(target,info):
				fighter_impacts.append({"event_id":info.combat_event_id,"physics_frame":Engine.get_physics_frames(),"process_frame":Engine.get_process_frames(),"owner_slot":shot.team_slot,"target_slot":target.slot,"behavior":shot.behavior,"integrity":shot.integrity,"damage":info.damage,"world":[info.contact_world.x,info.contact_world.y],"active_after_contact":shot.active,"flight_slot_after_contact":shot._flight_slot,"travel_after_contact":shot._elemental_audio.travel.playing,"position_after_contact":[shot.global_position.x,shot.global_position.y]})
			)
		var c=actor.model_3d.get_animation_controller();var sk:Skeleton3D=c.get_skeleton()
		sk.force_update_all_bone_transforms()
		var directions:Array=[]
		for side in ["L","R"]:
			var a:Vector3=sk.get_bone_global_pose(sk.find_bone("UpperLeg_"+side)).origin
			var b:Vector3=sk.get_bone_global_pose(sk.find_bone("LowerLeg_"+side)).origin
			var f:Vector3=sk.get_bone_global_pose(sk.find_bone("Foot_"+side)).origin
			var axis:Vector3=(f-a).normalized()
			directions.append((b-a-axis*(b-a).dot(axis)).dot((Vector3.BACK-axis*Vector3.BACK.dot(axis)).normalized()))
		physical_samples.append({"process_frame":Engine.get_process_frames(),"slot":actor.slot,"grounded":actor.is_on_floor(),"state":actor.state_machine.current_state,"knee_forward_m":directions,"clip":c.get_animation_player().current_animation,"damage":actor.damage_percent})
	for id in observed_shots:
		var shot=observed_shots[id].get_ref()
		if not is_instance_valid(shot):continue
		flight_samples.append({"process_frame":Engine.get_process_frames(),"id":id,"slot":shot.team_slot,"position":[shot.global_position.x,shot.global_position.y],"active":shot.active,"flight_slot":shot._flight_slot,"travel":shot._elemental_audio.travel.playing})
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
		observe_impact_review()
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
	f.store_string(JSON.stringify({"scope": "two normal public-input players in native BattleScene; neither CPU nor human owner acceptance; no seeded aura/damage/position or forced outcomes", "frames": frames, "cases": cases, "hits": hits, "inputs": inputs, "frame_stamps": stamps, "fighter_impacts":fighter_impacts,"flight_samples":flight_samples,"physical_samples":physical_samples,"presentation_history": renderer.history, "clash_presentation": presentation, "controls_enabled": [p.controls_enabled, d.controls_enabled], "unmodified_aura_requirements": true, "history": battle._battle_sim.projectile_interactions.history}, "  ")); f.close()
func shoot_one(label:String,slot:int)->void:
	var start:int=fighter_impacts.size()
	keys(slot,["special"]);await wait(1);keys(slot,[]);await wait(49)
	cases.append({"case":label,"impacts":fighter_impacts.slice(start),"damage_after":[p.damage_percent,d.damage_percent]})
func charge_juno()->void:
	for i in range(240):
		if d.aura>=88:break
		keys(2,["special","shield"]);await wait(1)
	keys(2,[]);await wait(4)
func impact_and_motion_review()->void:
	await shoot_one("kaia_quick_fighter",1)
	await shoot_one("juno_quick_fighter",2)
	await charge_juno();await shoot_one("juno_charged_fighter",2)
	await charge_juno();await shoot("breakthrough_then_fighter",50)
	# Normal approach, shield, light/heavy exchanges and return to neutral.
	# Both public controllers stay enabled. No forced pose, damage or result.
	for i in range(90):
		if d.position.x-p.position.x<=60:break
		keys(1,["right"]);keys(2,["left"]);await wait(1)
	keys(1,[]);keys(2,[]);await wait(10)
	for i in range(180):
		var first:Array=[];var second:Array=[]
		if i<30:second=["shield"]
		if i in [1,40,80,120]:first=["attack"]
		if i in [60,140]:second=["attack","special"]
		if i==100:first=["jump"]
		keys(1,first);keys(2,second);await wait(1)
	keys(1,[]);keys(2,[]);await wait(30)
	write_evidence()
	print("FIGHTER_IMPACT_PUBLIC_COMPLETE cases=",cases.size()," fighter_impacts=",fighter_impacts.size()," contacts=",hits.size())
func shoot(label: String, settle_frames: int = 130) -> void:
	var begin: int = battle._battle_sim.projectile_interactions.history.size()
	var damage_before := [p.damage_percent, d.damage_percent]
	var aura := [p.aura, d.aura]
	var shot_frame := Engine.get_physics_frames()
	keys(1, ["special"]); keys(2, ["special"]); await wait(1)
	keys(1, []); keys(2, []); await wait(settle_frames)
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
	if "--fighter-impact-review" in OS.get_cmdline_user_args():
		await impact_and_motion_review();quit();return
	await shoot("equal_quick")
	if "--clash-repeat-exchanges" in OS.get_cmdline_user_args():
		# Bounded ordinary inputs at 25-frame intervals; no position/aura edits,
		# waiting for fabricated hitstun, or repeated forced resolver calls.
		for i in range(8): await shoot("repeated_quick_" + str(i + 1), 24)
		keys(1, []); keys(2, []); await wait(30)
		write_evidence()
		print("PROJECTILE_PUBLIC_REPEAT_COMPLETE cases=", cases.size(), " interceptions=", battle._battle_sim.projectile_interactions.history.size())
		quit(); return
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
