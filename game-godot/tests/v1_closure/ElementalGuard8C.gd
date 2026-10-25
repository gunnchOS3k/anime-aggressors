extends "res://tests/v1_closure/PerfectGuardRuntime.gd"
## Controlled real BattleScene/public-input checks. Initial shield durability
## and geometry are declared fixture setup, never earned play or CPU evidence.
const GuardShader=preload("res://shaders/elemental_guard_8c.gdshader")
const BaseShader=preload("res://shaders/spectral_feedback.gdshader")
var _shield_events: Array = []
var _source_hashes: Dictionary = {}

func release() -> void:
	for slot in [1,2]:
		for key in ["left","right","up","down","jump","attack","special","shield","grab","dodge","taunt"]:Input.action_release("p%d_%s" % [slot,key])

func write(done: bool) -> void:
	var f=FileAccess.open(output.path_join("elemental_guard_8c.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":done and failures.is_empty(),"complete":done,"rows":rows,"failures":failures,"scope":"Controlled real BattleScene public guard/attack inputs; initial durability/body/facing/position fixtures; no active CPU, earned progression, native rendering, device or human quality claim","candidate":"Opt-in metadata only; 66-frame/45% candidate unapproved; accepted .4s/full restore tested separately","source_hashes":_source_hashes},"\t"));f.close()

func _ready_pair(p,d,fid: String,body: String,face: int) -> void:
	await prepare(p,d,fid,body,face)
	for actor in [p,d]:
		actor.remove_meta("shield_break_8c_candidate")
		actor.shield_break_8c.reset("test_setup")
		actor.shield_health=float(actor.data.get("shieldProfile",{}).get("maxHealth",100))
	_shield_events.clear()

func _strike(p,face: int) -> void:
	Input.action_press("p1_right" if face==1 else "p1_left",.5)
	Input.action_press("p1_attack")
	await frames(2)
	Input.action_release("p1_attack");Input.action_release("p1_left");Input.action_release("p1_right")

func _wait_contact(count: int) -> bool:
	for i in range(50):
		if contacts.size()>=count:return true
		await physics_frame
	return false

func _last_policy_event(actor,kind: String) -> Dictionary:
	for index in range(actor.shield_break_8c.history.size()-1,-1,-1):
		var row: Dictionary=actor.shield_break_8c.history[index]
		if str(row.get("result",""))==kind:return row
	return {}

func _guard_and_parry(p,d,fid: String,body: String,face: int,mode: String) -> void:
	var label:=fid+":"+body+":"+str(face)+":"+mode
	var settings=root.get_node("StoryDialogue").settings
	settings["vfx_intensity"]=mode;settings["reduced_particles"]=mode=="Reduced";settings["reduced_flash"]=true;settings["high_contrast_vfx"]=true
	await _ready_pair(p,d,fid,body,face)
	Input.action_press("p2_shield");await frames(12)
	var guard=d._guard_presentation.snapshot()
	check(guard.guarding and guard.guard_visible,label+":persistent_public_guard")
	check(int(guard.audio.allocated_voices)==2,label+":bounded_two_audio_voices")
	check(not d.shield_break_8c.requested(),label+":candidate_not_default")
	var renderer=d._guard_presentation.renderer
	if guard.guard_slot>=0:
		var mesh=renderer.slots[guard.guard_slot].mesh
		check(mesh.material.shader==GuardShader,label+":guard_shader_selected")
		check(int(mesh.material.get_shader_parameter("family"))==IDs.find(fid),label+":defender_element")
	await _strike(p,face)
	check(await _wait_contact(1),label+":ordinary_contact")
	if not contacts.is_empty():
		var info: Dictionary=contacts[0]
		check(info.contact_result=="shield" and not info.get("perfect_guard",false),label+":ordinary_shield_distinct")
		check(d.damage_percent==0 and info.played_audio.get("owned_guard_audio",false),label+":block_damage_and_owned_audio")
		var old_audio_count:int=d._guard_presentation.audio.history.size()
		var duplicate: Dictionary=d._guard_presentation.confirmed_contact(info)
		check(duplicate.get("duplicate",false) and d._guard_presentation.audio.history.size()==old_audio_count,label+":deduplicated_contact_audio")
		check(info.get("elemental_guard_owned_cue",false),label+":primary_guard_cue")
		check(not info.get("screen_flash",true) and str(info.get("camera_event","x")).is_empty(),label+":no_flash_or_camera")
	rows.append({"fighter":fid,"body":body,"facing":face,"mode":mode,"case":"ordinary_shield","contact":contacts[0] if not contacts.is_empty() else {},"presentation":d._guard_presentation.snapshot()});write(false)
	await _ready_pair(p,d,fid,body,face)
	await _strike(p,face)
	for i in range(40):
		if p.move_runner.active and p.move_runner.total_frame>=int(p._current_move.startup_frames)-1:break
		await physics_frame
	Input.action_press("p2_shield")
	check(await _wait_contact(1),label+":perfect_contact")
	if not contacts.is_empty():
		var info: Dictionary=contacts[0]
		check(info.get("perfect_guard",false) and info.contact_result=="parry",label+":fresh_four_frame_guard")
		check(info.played_audio.get("event","")=="perfect_guard" and info.played_audio.get("owned_guard_audio",false),label+":distinct_perfect_audio")
		check(d.damage_percent==0 and not d.invincible,label+":perfect_guard_no_immunity")
	rows.append({"fighter":fid,"body":body,"facing":face,"mode":mode,"case":"perfect_guard","contact":contacts[0] if not contacts.is_empty() else {}});write(false)

func _warnings(p,d,fid: String) -> void:
	await _ready_pair(p,d,fid,"female",-1)
	Input.action_press("p2_shield");await frames(5)
	var maximum:=float(d.data.get("shieldProfile",{}).get("maxHealth",100))
	var observed: Array=[]
	for step in [[.55,"strained"],[.25,"low"],[.10,"imminent"],[.15,"imminent"],[.20,"low"],[.32,"low"],[.38,"strained"],[.62,"strained"],[.68,"healthy"]]:
		d.shield_health=maximum*float(step[0]) # Declared durability fixture, never battle damage.
		await frames(2)
		var report=d._guard_presentation.snapshot()
		check(report.stage==step[1],fid+":durability_hysteresis:"+str(step[0]))
		check(absf(float(report.normalized_durability)-float(d.shield_health)/maximum)<.01,fid+":normalized_actual_health")
		observed.append({"initial_ratio_fixture":step[0],"observed_stage":report.stage,"actual_ratio":report.normalized_durability})
	rows.append({"fighter":fid,"case":"normalized_durability_hysteresis","setup":"direct initial durability assignments; no progression or damage changes","observed":observed});write(false)

func _break_from_real_contact(p,d,fid: String,candidate: bool) -> bool:
	await _ready_pair(p,d,fid,"male",1)
	if candidate:d.set_meta("shield_break_8c_candidate",true)
	Input.action_press("p2_shield");await frames(12)
	await _strike(p,1)
	for i in range(40):
		if p.move_runner.active and p.move_runner.total_frame>=int(p._current_move.startup_frames)-1:break
		await physics_frame
	# This is the only damage-condition fixture. The following 3-shield-damage
	# canonical attack, not a direct break-state call, owns the actual rupture.
	d.shield_health=2.5
	var found:=await _wait_contact(1)
	check(found,fid+":break_contact_exists:"+str(candidate))
	check(d.state_machine.current_state=="shield_break" and d.shield_health==0,fid+":actual_contact_break:"+str(candidate))
	check(d.shield_break_8c.candidate==candidate,fid+":explicit_candidate_selection")
	check(_shield_events.filter(func(e):return e.get("result","")=="shield_break").size()==1,fid+":one_owned_break_event")
	if d.state_machine.current_state!="shield_break":return false
	var event:=_last_policy_event(d,"shield_break")
	var audio_count:int=d._guard_presentation.audio.history.size()
	d._guard_presentation.break_event(str(event.get("event_id","")))
	check(d._guard_presentation.audio.history.size()==audio_count,fid+":duplicate_break_no_audio")
	return true

func _break_recovery(p,d,fid: String,candidate: bool) -> void:
	if not await _break_from_real_contact(p,d,fid,candidate):return
	var label:=fid+":candidate" if candidate else fid+":baseline"
	var frame0:=Engine.get_physics_frames()
	var last_locked_frame:=0
	var last_locked_seconds:=0.0
	# Real held controls must not cut short locked recovery. Their release is
	# ordinary public input; guard deliberately remains held after recovery.
	if candidate:
		for key in ["attack","jump","taunt","dodge"]:Input.action_press("p2_"+key)
	for i in range(100):
		if d.state_machine.current_state!="shield_break":break
		check(not d.state_machine.can_attack() and not d.state_machine.can_move() and not d.shielding,label+":locked_recovery")
		last_locked_frame=d.state_machine.state_frame;last_locked_seconds=d.state_machine.state_time
		if i==12:
			for key in ["attack","jump","taunt","dodge"]:Input.action_release("p2_"+key)
		await physics_frame
	var recovery:=_last_policy_event(d,"shield_recovered")
	check(not recovery.is_empty(),label+":finite_recovery")
	var maximum:=float(d.data.get("shieldProfile",{}).get("maxHealth",100))
	if candidate:
		check(last_locked_frame==65 and absf(float(recovery.get("health",-1))-maximum*.45)<.001,label+":exact_66_frames_45percent")
		check(not d.shielding and d.shield_break_8c.needs_guard_release,label+":held_guard_cannot_bypass")
		Input.action_release("p2_shield");await frames(2);Input.action_press("p2_shield");await frames(3)
		check(d.shielding and not d.shield_break_8c.needs_guard_release,label+":fresh_guard_reentry")
	else:
		check(last_locked_seconds<=.400001 and last_locked_seconds+1.0/60.0>.4,label+":unchanged_strict_point4seconds")
		check(absf(float(recovery.get("health",-1))-maximum)<.001,label+":unchanged_full_health_restore")
	rows.append({"fighter":fid,"case":"shield_break_recovery","candidate":candidate,"initial_shield_health_fixture":2.5,"contact":contacts[0] if not contacts.is_empty() else {},"last_locked_state_frame":last_locked_frame,"last_locked_seconds":last_locked_seconds,"elapsed_physics_frames_including_hitstop":Engine.get_physics_frames()-frame0,"recovery":recovery,"policy":d.shield_break_8c.snapshot(),"presentation":d._guard_presentation.snapshot()});write(false)

func _punish(p,d,fid: String) -> void:
	if not await _break_from_real_contact(p,d,fid,true):return
	for i in range(50):
		if p.state_machine.can_attack() and not p.move_runner.active:break
		await physics_frame
	var before_frame:int=d.state_machine.state_frame
	await _strike(p,1)
	check(await _wait_contact(2),fid+":public_punish_contact")
	check(contacts.size()==2 and not contacts[1].get("blocked",true) and d.damage_percent>0,fid+":real_unblocked_punish")
	check(not d.invincible and not d.shield_break_8c.active,fid+":punish_retires_break_without_immunity")
	rows.append({"fighter":fid,"case":"candidate_public_punish","initial_shield_health_fixture":2.5,"attempt_state_frame":before_frame,"contacts":contacts.duplicate(true),"damage":d.damage_percent,"policy":d.shield_break_8c.snapshot()});write(false)

func _pool_and_cleanup(p,d) -> void:
	await _ready_pair(p,d,"kaia-windrow","female",1)
	Input.action_press("p2_shield");await frames(5)
	var guard=d._guard_presentation
	var renderer=guard.renderer
	var slot:int=guard.snapshot().guard_slot
	var event_id:String=renderer.slots[slot].event_id
	# Pool pressure is a presentation fixture only; no collision or damage.
	for i in range(120):renderer.emit_effect("juno-spark",5,Vector2.ZERO,Vector2.RIGHT,40,.3,"stressdecoration:"+str(i))
	await frames(2)
	check(guard.snapshot().guard_visible and renderer.slots[slot].event_id==event_id,"pool:primary_guard_survives_decoration")
	check(renderer.active_count()<=int(renderer.stats().presentation_budget),"pool:bounded_under_decoration")
	guard.clear("pool_reuse_fixture")
	check(renderer.slots[slot].mesh.material.shader==BaseShader,"pool:shader_restored_on_explicit_retirement")
	var reused:int=renderer.emit_effect("ember-vale",0,Vector2.ZERO,Vector2.RIGHT,40,.2,"generic_after_guard")
	check(reused<0 or renderer.slots[reused].mesh.material.shader==BaseShader,"pool:generic_shader_on_reuse")
	await frames(2)
	d.state_machine.enter("ko") # Declared terminal-lifecycle fixture, not earned KO.
	check(not guard.snapshot().owned_guard_active and not guard.snapshot().owned_pulse_active,"cleanup:terminal_retires_guard")
	check(int(guard.snapshot().audio.playing_voices)==0,"cleanup:terminal_stops_audio")
	await _ready_pair(p,d,"juno-spark","male",-1)
	Input.action_press("p2_shield");await frames(3)
	d.close_transformation_for_match_end()
	check(not d._guard_presentation.snapshot().owned_guard_active and not d.shield_break_8c.active,"cleanup:match_end_owner")
	rows.append({"case":"pool_and_cleanup","pool":renderer.stats(),"scope":"declared presentation saturation and terminal lifecycle fixtures, not earned KO"});write(false)

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
		if arg=="--pilot":pilot=true
		if arg=="--timing-smoke":timing_smoke=true
	for path in ["res://scripts/visual/elemental_guard_8c.gd","res://scripts/audio/guard_audio_8c.gd","res://shaders/elemental_guard_8c.gdshader","res://scripts/combat/shield_break_8c.gd","res://data/combat/shield_break_candidate_8c.json"]:
		_source_hashes[path]=FileAccess.get_sha256(path)
	var gs=root.get_node("GameState")
	gs.mode="versus";gs.items_enabled=false;gs.hazards_enabled=false;gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0;gs.match_type="stock_untimed"
	var campaign=root.get_node("CampaignRuntime")
	var progress_before:=JSON.stringify(campaign.progress)
	var saved_before:PackedByteArray=FileAccess.get_file_as_bytes(campaign.save_path) if FileAccess.file_exists(campaign.save_path) else PackedByteArray()
	root.get_node("SceneRouter").go("battle");await frames(220)
	var p=current_scene.fighter1;var d=current_scene.fighter2
	p.hit_resolver.hit_confirmed.connect(func(a,b,info):
		if a==p and b==d:contacts.append(info.duplicate(true)))
	d.shield_event.connect(func(event):_shield_events.append(event.duplicate(true)))
	var configured_fighters=IDs.slice(0,1) if pilot else IDs
	var sequence:=0
	for fid in configured_fighters:
		for body in (["male"] if pilot or timing_smoke else ["male","female"]):
			for face in ([1] if pilot or timing_smoke else [1,-1]):
				await _guard_and_parry(p,d,fid,body,face,["Full","Balanced","Reduced"][sequence%3]);sequence+=1
		await _warnings(p,d,fid)
		await _break_recovery(p,d,fid,false)
		await _break_recovery(p,d,fid,true)
		await _punish(p,d,fid)
	await _pool_and_cleanup(p,d)
	check(progress_before==JSON.stringify(campaign.progress),"Story:progress_unchanged")
	var saved_after:PackedByteArray=FileAccess.get_file_as_bytes(campaign.save_path) if FileAccess.file_exists(campaign.save_path) else PackedByteArray()
	check(saved_before==saved_after,"Story:save_unchanged")
	release();write(true);quit(0 if failures.is_empty() else 1)
