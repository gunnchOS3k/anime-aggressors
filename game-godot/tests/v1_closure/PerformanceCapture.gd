extends SceneTree
## Native rendered BattleScene; automated ordinary input against active opponents.
## Match fixture selection is explicit. Never earns Story receipts.
var held: Array=[]
var events: Array=[]
var output := ""
var fid := "ember-vale"
var source_sha := ""
var idle_opponent := false
func _init() -> void:call_deferred("_run")
func inputs(actions: Array) -> void:
	for action in held:
		if action not in actions:Input.action_release("p1_"+action)
	for action in actions:
		if action not in held:Input.action_press("p1_"+action)
	held=actions
func _run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--performance-fighter="):fid=arg.get_slice("=",1)
		if arg.begins_with("--source-sha="):source_sha=arg.get_slice("=",1)
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
		if arg == "--performance-opponent=idle":idle_opponent=true
	var state=root.get_node("GameState")
	state.mode="versus";state.p1_is_cpu=false;state.cpu_level=3;state.battle_eval_mode=false;state.p1_fighter_id=fid;state.p2_fighter_id="ember-vale" if fid=="juno-spark" else "juno-spark"
	state.p1_body_variant="female";state.p2_body_variant="female";state.p2_is_cpu=not idle_opponent;state.stocks=9;state.match_timer_seconds=180
	root.get_node("SceneRouter").go("battle")
	for i in range(220):await physics_frame
	var battle=current_scene
	print("CAPTURE_RULES cpu=",battle.fighter2.is_cpu," mode=",state.mode," controls=",battle.fighter2.controls_enabled)
	var p=battle.fighter1
	p.move_runner.move_started.connect(func(mid):events.append({"fighter":fid,"move":mid,"physics_frame":Engine.get_physics_frames()}))
	battle.fighter2.move_runner.move_started.connect(func(mid):events.append({"fighter":battle.fighter2.fighter_id,"move":mid,"opponent":true,"physics_frame":Engine.get_physics_frames()}))
	var label:=Label.new();label.text="AUTOMATED NORMAL INPUT · "+("idle P2 signature fixture" if idle_opponent else "active CPU")+" · candidates · "+source_sha.left(12);label.position=Vector2(30,90);battle.hud.add_child(label)
	for frame in range(3000):
		if current_scene!=battle:break
		var phase:=frame%1200
		var dx:float=battle.fighter2.position.x-p.position.x
		var actions: Array=[]
		if idle_opponent:
			# Charge through the public controls; no aura assignment or move calls.
			if phase<650:actions.append_array(["special","shield"])
			elif phase<670:actions.append("attack")
		elif phase<260:
			if absf(dx)>55:actions.append("right" if dx>0 else "left")
			if frame%30<4:actions.append("attack")
		elif phase<440:
			if absf(dx)>55:actions.append("right" if dx>0 else "left")
			if frame%65<5:actions.append_array(["attack","special"])
		elif phase<600:
			if frame%65<5:actions.append("special")
		elif phase<960:actions.append_array(["special","shield"])
		elif phase<1010:
			if frame%20<4:actions.append("attack")
		elif phase<1100:actions.append("shield")
		else:
			if frame%40<4:actions.append("dodge")
		inputs(actions)
		if frame%30==0 and not output.is_empty():
			var f=FileAccess.open(output.path_join("normal_input_capture_events.json"),FileAccess.WRITE)
			f.store_string(JSON.stringify({"fixture":"versus nine-stock match; no forced damage/positions/move methods","opponent_cpu":battle.fighter2.is_cpu,"player_damage":p.damage_percent,"opponent_damage":battle.fighter2.damage_percent,"events":events,"human_playthrough":false,"story_unlocks_earned":false},"  ")+"\n");f.close()
		await physics_frame
	inputs([]);quit()
