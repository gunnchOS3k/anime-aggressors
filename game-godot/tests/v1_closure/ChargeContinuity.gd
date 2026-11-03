extends SceneTree
## Public held controls prove that locomotion cannot restart owned charge presentation.
## Idle P2 and roster reconfiguration are declared fixtures, never combo evidence.
const Renderer = preload("res://scripts/visual/spectral_feedback_renderer.gd")
var failures: Array=[]
var rows: Array=[]
var output := ""
func _init() -> void: call_deferred("_run")
func check(value: bool,label: String) -> void:
	if not value: failures.append(label);push_error(label)
func count_event(audio: Node,event: String,since: int=0) -> int:
	return audio.events.slice(since).filter(func(e):return e.get("event","")==event).size()
func _run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState")
	gs.mode="versus";gs.stage_id="training-grid";gs.p1_fighter_id="ember-vale";gs.p2_fighter_id="juno-spark";gs.p2_is_cpu=false;gs.stocks=9
	root.get_node("SceneRouter").go("battle")
	for i in range(220):await physics_frame
	var p=current_scene.fighter1
	var renderer=Renderer.obtain(p)
	for fid in Renderer.IDS:
		p.configure(fid,1,false,9,Vector2(-202,205));p.invincible=false;p.aura=0
		var history_before: int=renderer.history.size()
		var audio_before: int=p._elemental_audio.events.size() if p._elemental_audio!=null else 0
		Input.action_press("p1_special");Input.action_press("p1_shield")
		for i in range(70):await physics_frame
		var audio=p._elemental_audio
		var slot: int=p._spectral_charge_slot
		var charge_starts: int=renderer.history.slice(history_before).filter(func(h):return h.kind==2).size()
		check(charge_starts==1 and slot>=0,fid+":one_owned_emitter_through_fall_and_landing")
		check(count_event(audio,"charge_start",audio_before)==1 and count_event(audio,"charge_cancel",audio_before)==0 and count_event(audio,"charge_release",audio_before)==0,fid+":no_repeated_ignition_or_loop_restart")
		var loop=audio.charge
		Input.action_press("p1_right",.4)
		for i in range(10):await physics_frame
		Input.action_release("p1_right")
		check(p._spectral_charge_slot==slot and audio.charge==loop,fid+":walking_keeps_charge_state_and_loop")
		for i in range(210):await physics_frame
		check(p.aura>=100 and p.state_machine.current_state=="aura_ready" and count_event(audio,"charge_ready",audio_before)==1,fid+":ready_emitted_once")
		Input.action_release("p1_special");Input.action_release("p1_shield")
		for i in range(3):await physics_frame
		check(p._spectral_charge_slot==-1 and audio.charge==null and count_event(audio,"charge_release",audio_before)==1,fid+":release_stops_owned_loop")
		Input.action_press("p1_special");Input.action_press("p1_shield")
		for i in range(3):await physics_frame
		Input.action_press("p1_jump")
		await physics_frame
		Input.action_release("p1_jump");Input.action_release("p1_special");Input.action_release("p1_shield")
		for i in range(3):await physics_frame
		check(p._spectral_charge_slot==-1 and audio.charge==null and count_event(audio,"charge_cancel",audio_before)==1,fid+":public_jump_cancel_cleanup")
		rows.append({"fighter":fid,"charge_starts":charge_starts,"ready_count":count_event(audio,"charge_ready",audio_before),"scope":"public controls, idle P2, reconfigured source fixture"})
		for i in range(70):await physics_frame
	if output!="":
		var f=FileAccess.open(output.path_join("charge_continuity.json"),FileAccess.WRITE)
		f.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"rows":rows,"balance_data_changed":false},"\t"))
	print("CHARGE_CONTINUITY ",failures)
	quit(0 if failures.is_empty() else 1)
