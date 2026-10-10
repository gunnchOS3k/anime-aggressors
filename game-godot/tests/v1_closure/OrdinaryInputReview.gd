extends Node

## Actual BootScene/menu game, normal rules, observation + public input only.
## Injected ONLY by launch_ordinary_review.py; never a shipping autoload.
var output := ""
var rows: Array = []
var trace: Array = []
var held: Array = []
var scene_id := 0
var frame := 0
var local_frame := 0
var action_delay := 0
var node_id := ""
var attempt := {}
var failures: Array = []
var retries := 0
var capture_busy := false
var captured: Array = []
var resume := false
var max_nodes := 20
var route_id := "kaia-windrow"
var replay_nodes: Array = []
var replay_index := 0
var video_frames := false
var video_counts := {}
var start_progress := {}
var navigation := {}
var seeded_prerequisites := false

func _ready() -> void:
	process_physics_priority = -100
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.trim_prefix("--ordinary-output=")
		if arg == "--ordinary-resume": resume = true
		if arg.begins_with("--ordinary-max-nodes="): max_nodes=int(arg.trim_prefix("--ordinary-max-nodes="))
		if arg.begins_with("--ordinary-route="): route_id=arg.trim_prefix("--ordinary-route=")
		if arg.begins_with("--ordinary-replay="): replay_nodes=Array(arg.trim_prefix("--ordinary-replay=").split(","))
		if arg == "--ordinary-video-frames": video_frames=true
		if arg == "--ordinary-seeded-prerequisites": seeded_prerequisites=true
	if output.is_empty(): set_physics_process(false); return
	DirAccess.make_dir_recursive_absolute(output)
	print("ORDINARY_PROFILE ", OS.get_user_data_dir())
	call_deferred("_start_check")

func _start_check() -> void:
	print("ORDINARY_SAVE_RESOLUTION path=",CampaignRuntime.save_path," resolved=",ProjectSettings.globalize_path(CampaignRuntime.save_path)," exists=",FileAccess.file_exists(CampaignRuntime.save_path)," bytes=",FileAccess.get_file_as_bytes(CampaignRuntime.save_path).size())
	CampaignRuntime.load_progress()
	start_progress=CampaignRuntime.progress.duplicate(true)
	print("ORDINARY_START_PROGRESS ",JSON.stringify(CampaignRuntime.progress["routes"]["kaia-windrow"]["completed"]), " error=",CampaignRuntime.last_error)
	if not resume and not CampaignRuntime.progress["routes"]["kaia-windrow"]["completed"].is_empty():
		failures.append("Profile is not fresh; choose a new profile rather than reset saves.")
		_finish()
	if GameState.battle_eval_mode or CampaignRuntime.route_review_enabled():
		failures.append("Privileged mode prohibited")
		_finish()

func _physics_process(_delta: float) -> void:
	frame += 1
	local_frame += 1
	action_delay -= 1
	var scene = get_tree().current_scene
	if scene == null: return
	if scene_id != scene.get_instance_id():
		scene_id = scene.get_instance_id(); local_frame = 0; action_delay = 50
		_inputs([])
		print("ORDINARY_SCENE ",scene.scene_file_path)
		if scene.scene_file_path.ends_with("BattleScene.tscn"):
			node_id = str(CampaignRuntime.active_encounter.get("node_id", ""))
			attempt = {"node":node_id,"player_hits":0,"enemy_hits":0,"blocks":0,"enemy_moves":0,"max_player_damage":0.0,"start_stocks":GameState.stocks,"normal_rules":true}
			for actor in scene.fighters_root.get_children():
				if not actor.has_method("training_play_move"): continue
				actor.hit_resolver.hit_confirmed.connect(_hit)
				actor.koed.connect(_ko_observed.bind(actor))
				if actor != scene.fighter1:
					actor.move_runner.move_started.connect(func(_mid): attempt["enemy_moves"] += 1)
	if scene.scene_file_path.ends_with("BootScene.tscn"):
		_press_button(scene, "Start Game")
	elif scene.scene_file_path.ends_with("MainMenuScene.tscn"):
		_press_button(scene, "Story")
	elif scene.scene_file_path.ends_with("TutorialScene.tscn"):
		_press_button(scene, "Skip")
	elif scene.scene_file_path.ends_with("StoryCampaignScene.tscn"):
		if CampaignRuntime.progress["selected_route"] != route_id:
			if action_delay > 0: return
			for i in range(scene._route_picker.item_count):
				if scene._route_picker.get_item_metadata(i) == route_id:
					if scene._route_picker.is_item_disabled(i): failures.append("Requested route is locked: "+route_id); _finish(); return
					scene._route_picker.select(i); scene._route_picker.item_selected.emit(i); action_delay=55; return
		if not replay_nodes.is_empty():
			if replay_index >= replay_nodes.size(): _finish(); return
			if action_delay > 0: return
			for i in range(scene._replay_picker.item_count):
				if scene._replay_picker.get_item_metadata(i) == replay_nodes[replay_index]:
					scene._replay_picker.select(i); _press_button(scene,"Replay Selected Encounter"); return
			failures.append("Replay chapter was not earned: "+str(replay_nodes[replay_index])); _finish(); return
		if CampaignRuntime.progress["routes"][route_id]["completed"].size() >= max_nodes:
			if route_id == "kaia-windrow" and (CampaignRuntime.route_available("sevenfold-convergence") or CampaignRuntime.progress["yin_unlocked"]): failures.append("Kaia alone unlocked Convergence/cosmic")
			if route_id == "kaia-windrow" and CampaignRuntime.progress["routes"][route_id]["complete"]:
				action_delay=0; _press_button(scene,"Next Route")
				navigation={"next_route_button_used":true,"selected_after":CampaignRuntime.progress["selected_route"]}
				if CampaignRuntime.progress["selected_route"]==route_id: failures.append("Next Route navigation did not leave completed Kaia")
			_finish(); return
		if action_delay <= 0:
			if scene._action.disabled: failures.append("Story action unavailable"); _finish(); return
			if CampaignRuntime.current_node().get("kind") == "INTERACTIVE_DIALOGUE":
				rows.append({"node":CampaignRuntime.current_node()["id"],"kind":"scene","ui_acknowledgment":true})
			scene._action.pressed.emit(); action_delay = 55
	elif scene.scene_file_path.ends_with("ResultsScene.tscn"):
		if action_delay <= 0:
			attempt["receipt"] = CampaignRuntime.last_result.duplicate(true)
			attempt["winner"] = GameState.last_winner_slot
			if CampaignRuntime.last_result.is_empty(): failures.append("Result has no authentic receipt: "+node_id); _finish(); return
			attempt["frames"] = trace.back().get("frame",0) if not trace.is_empty() else 0
			rows.append(attempt.duplicate(true))
			print("ORDINARY_RESULT ",JSON.stringify(attempt))
			if not replay_nodes.is_empty():
				replay_index += 1
				scene.rematch_btn.pressed.emit(); action_delay=55; return
			if GameState.last_winner_slot != 1:
				retries += 1
				if retries > 4: failures.append("Ordinary-input driver lost repeatedly at "+node_id); _finish(); return
			scene.rematch_btn.pressed.emit(); action_delay = 55
	elif scene.scene_file_path.ends_with("BattleScene.tscn"):
		var timeout := 1400 if scene._story_objective != null and scene._story_objective.kind == "SEVENFOLD_TRIAL" else 220
		if local_frame > 60*timeout: failures.append("Objective timeout: "+node_id); _finish(); return
		if not scene._active or not scene.fighter1.controls_enabled: return
		attempt["max_player_damage"] = maxf(attempt["max_player_damage"],scene.fighter1.damage_percent)
		_drive(scene)
		if local_frame % 60 == 0:
			trace.append({"node":node_id,"frame":local_frame,"p1_position":[scene.fighter1.position.x,scene.fighter1.position.y],"p1_damage":scene.fighter1.damage_percent,"p1_stocks":scene.fighter1.stocks,"p1_state":scene.fighter1.state_machine.current_state,"p1_facing":scene.fighter1.facing,"p1_shield":scene.fighter1.shield_health,"p2_state":scene.fighter2.state_machine.current_state,"p2_position":[scene.fighter2.position.x,scene.fighter2.position.y],"p2_shield":scene.fighter2.shield_health,"p2_damage":scene.fighter2.damage_percent,"p2_stocks":scene.fighter2.stocks,"inputs":held.duplicate(),"objective":scene._story_objective.evidence() if scene._story_objective != null else {}})
			if local_frame % 600 == 0: print("ORDINARY_PROGRESS ",JSON.stringify(trace.back()))
		if DisplayServer.get_name() != "headless" and local_frame == 330 and not capture_busy: _capture(node_id.replace(":","_")+".png")
		if video_frames and DisplayServer.get_name() != "headless" and local_frame >= 200 and local_frame < 920 and local_frame % 6 == 0 and not capture_busy:
			var count: int = video_counts.get(node_id,0)
			var directory := output.path_join("frames_"+node_id.replace(":","_"))
			DirAccess.make_dir_recursive_absolute(directory)
			_capture("frames_"+node_id.replace(":","_")+"/frame_%04d.png"%count)
			video_counts[node_id]=count+1
	if DisplayServer.get_name() != "headless" and local_frame == 40 and not capture_busy:
		if scene.scene_file_path.ends_with("ResultsScene.tscn"): _capture(node_id.replace(":","_")+"_result.png")
		elif scene.scene_file_path.ends_with("StoryCampaignScene.tscn"): _capture(str(CampaignRuntime.current_node().get("id","route_complete")).replace(":","_")+"_menu.png")

func _ko_observed(actor) -> void:
	if not attempt.has("kos"): attempt["kos"] = []
	attempt["kos"].append({"fighter":actor.fighter_id,"slot":actor.slot,"position":[actor.position.x,actor.position.y],"damage":actor.damage_percent,"remaining_stocks":actor.stocks})

func _hit(attacker, defender, info: Dictionary) -> void:
	if info.get("blocked",false): attempt["blocks"] += 1
	elif attacker.slot == 1: attempt["player_hits"] += 1
	elif defender.slot == 1: attempt["enemy_hits"] += 1

func _press_button(scene: Node, text: String) -> void:
	if action_delay > 0: return
	for candidate in scene.find_children("*", "Button", true, false):
		if candidate.visible and not candidate.disabled and text.to_lower() in candidate.text.to_lower():
			candidate.pressed.emit(); action_delay = 60; return

func _inputs(actions: Array) -> void:
	for action in held:
		if action not in actions: Input.action_release("p1_"+action)
	for action in actions:
		if action not in held: Input.action_press("p1_"+action, 0.55 if action in ["left","right"] else 1.0)
	held = actions

func _walk_to(p, x: float, radius := 25.0) -> Array:
	if p.position.x < x-radius: return ["right"]
	if p.position.x > x+radius: return ["left"]
	return []

func _combat(scene, target) -> Array:
	var p = scene.fighter1
	var actions := _walk_to(p,target.position.x,25)
	# Genuine recovery inputs; no transform, physics or stock writes.
	if absf(p.position.x-p.platform_center_x)>p.platform_half_width-30:
		actions = _walk_to(p,p.platform_center_x)
		if not p.is_on_floor() and local_frame%40<2: actions.append("jump")
		if not p.is_on_floor() and p.position.y > p.platform_surface_y-30 and local_frame%45<2: actions.append("up"); actions.append("special")
		return actions
	if target.state_machine.current_state == "ledge_hang": return _walk_to(p,0)
	if absf(target.position.y-p.position.y)>75 and p.is_on_floor() and local_frame%50<2: actions.append("jump")
	if p.grabbed_target != null:
		return ["right" if p.facing==1 else "left", "attack"]
	if absf(target.position.x-p.position.x)<100:
		if signf(target.position.x-p.position.x) != p.facing and absf(target.position.x-p.position.x)>5: return _walk_to(p,target.position.x,0)
		if target.shielding and absf(target.position.x-p.position.x)<65 and local_frame%45<2: return ["grab"]
		if (local_frame+retries*13)%41<2:
			if (local_frame/41)%3==0:
				actions = _walk_to(p,target.position.x,0); actions.append("special")
			else:
				actions=[]; actions.append("attack"); actions.append("special")
		elif local_frame%35>24 and target.move_runner.active: actions.append("shield")
	return actions

func _drive(scene) -> void:
	var p = scene.fighter1
	var o = scene._story_objective
	if o == null:
		if scene._story_survival:
			var target := -220.0 if (local_frame/180)%2==0 else 220.0
			var actions := _walk_to(p,target)
			if local_frame%100<25: actions = ["shield"]
			_inputs(actions)
		else: _inputs(_combat(scene,scene.fighter2))
		return
	match o.kind:
		"FIRST_LOSS":
			if o.node["consequence"]["interaction"] == "LAST_VECTOR_ESCORT":
				if o.decision.is_empty(): _inputs(["shield"] if local_frame%6<2 else [])
				else: _inputs(_walk_to(p,80 if o.steps==0 else 280))
			elif o.steps==0:
				var actions := _walk_to(p,0)
				if actions.is_empty() and local_frame%35<2: actions.append("attack")
				_inputs(actions)
			else: _inputs(_walk_to(p,240))
		"PUPPET_IMBALANCE":
			if o.player_hits==0: _inputs(_combat(scene,o.puppets[0]))
			else:
				var actions := _walk_to(p,0,60)
				if actions.is_empty(): actions.append("shield")
				_inputs(actions)
		"FIRST_RELEASE", "PAIRED_RELEASE":
			var target = null
			for actor in o.puppets:
				if actor.fighter_id in o.released: continue
				var side: String = actor.get_meta("story_team")
				if o.kind=="FIRST_RELEASE" and side!="yin": continue
				var same := false
				for fid in o.released:
					if fid in o.node["puppets"][side]: same=true
				if same: continue
				if target==null or p.position.distance_to(actor.position)<p.position.distance_to(target.position): target=actor
			if target != null:
				var actions: Array = _combat(scene,target)
				if o.player_damage.get(target.fighter_id,0)>=40 and p.position.distance_to(target.position)<105:
					actions = ["special"] if local_frame%6<2 else []
				_inputs(actions)
		"PUPPET_EQUILIBRIUM":
			var actions := _walk_to(p,0,60)
			if actions.is_empty(): actions.append("shield")
			_inputs(actions)
		"PRISMATIC_TRANSFORMATION":
			if p.position.y < o.ground_y-70: _inputs(_walk_to(p,0))
			else: _inputs(_walk_to(p,-250+o.steps*100) if o.steps<6 else ["shield"])
		"SEVENFOLD_REUNION":
			if p.position.y < o.ground_y-70: _inputs(_walk_to(p,0))
			else: _inputs(_walk_to(p,-250+o.steps*100) if o.steps<6 else [])
		"SEVENFOLD_TRIAL":
			_inputs(_combat(scene,scene.fighter2))
		"SEVENFOLD_EQUILIBRIUM":
			if p.position.y < o.ground_y-70: _inputs(_walk_to(p,0)); return
			var actions := _walk_to(p,-180 if o.alternations%2==0 else 180,40)
			if actions.is_empty(): actions=["shield"]
			_inputs(actions)
		"GRAY_DEMONSTRATION":
			var actions := _walk_to(p,-220 if (local_frame/180)%2==0 else 220)
			if local_frame%100<25: actions=["shield"]
			elif local_frame%100<28: actions=["attack"]
			_inputs(actions)

func _capture(name: String) -> void:
	capture_busy = true
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join(name))
	captured.append(name)
	capture_busy = false

func _finish() -> void:
	set_physics_process(false); _inputs([])
	var report := {"evidence_type":"ORDINARY_INPUT_AUTOMATION","human_playthrough":false,"new_profile":not resume,"route":route_id,"replay_nodes":replay_nodes,"profile_path":OS.get_user_data_dir(),"gameplay_overrides":[],"rows":rows,"trace":trace,"failures":failures,"ok":failures.is_empty(),"start_progress":start_progress,"progress":CampaignRuntime.progress,"navigation":navigation,"captures":captured,"video_frames":video_counts,"V1_AUTOMATED_READY":false}
	var f := FileAccess.open(output.path_join("ordinary_input_evidence.json"),FileAccess.WRITE)
	if seeded_prerequisites:
		report["evidence_type"]="SEEDED_PREREQUISITES_ORDINARY_INPUT"
		report["ordinary_earned_campaign"]=false
	f.store_string(JSON.stringify(report,"  ")+"\n");f.close()
	print("ORDINARY_COMPLETE ",failures)
	var scene = get_tree().current_scene
	if scene != null: scene.queue_free()
	for i in range(4): await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)
