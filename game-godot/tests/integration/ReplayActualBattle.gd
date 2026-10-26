extends "res://tests/integration/OrdinaryMatchCompletion.gd"
## Re-execute the retained successful public-input log in an ACTUAL BattleScene
## with the same active CPU. ReplayStore persists/validates the input file;
## no network toy simulation, state injection or prerecorded result is executed.
const Replay=preload("res://scripts/net/replay_store.gd")
const Checksum=preload("res://scripts/net/rollback_session_gd.gd")
var source_path := ""
var replay_result: Dictionary = {}
var epoch := 0
var source_epoch := 0

func record_contact(a,d,info: Dictionary) -> void:
	super.record_contact(a,d,info)
	contacts[-1].merge({"attacker_slot":a.slot,"defender_slot":d.slot,"damage_after":d.damage_percent})

func signature(records: Array,start: int) -> Array:
	return records.map(func(c):return {"frame":int(c.frame)-start,"attacker_slot":int(c.attacker_slot),"defender_slot":int(c.defender_slot),"move":c.move,"result":c.result,"damage":float(c.damage),"damage_after":float(c.damage_after)})

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.trim_prefix("--ordinary-output=")
		if arg.begins_with("--replay-source="):source_path=arg.trim_prefix("--replay-source=")
	if output.is_empty() or source_path.is_empty() or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Explicit retained source and isolated profile required");quit(2);return
	var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source_path))
	if not source.get("PASS",false) or not source.get("headless",false):
		push_error("Expected retained qualified headless input recording");quit(2);return
	var events: Array=source.inputs.filter(func(e):return e.has("p1_actions"))
	source_epoch=int(events[0].frame)
	var checksum=Checksum.new()
	var frames_to_store: Array=[]
	for event in events:
		var buttons: Dictionary={}
		for key in ["left","right","up","down","attack","special","grab","jump","shield","dodge"]:
			buttons[key]=key in event.p1_actions
		var frame=int(event.frame)-source_epoch
		frames_to_store.append({"frame":frame,"p0":buttons,"p1":{},"checksum":checksum._checksum_for(frame,[buttons,{}])})
	var meta={"seed":0,"roster":["kaia-windrow","juno-spark"],"cpu_level":3,"cpu_driven_slot":2,
		"input_encoding":"change_events","source_sha256":FileAccess.get_sha256(source_path),
		"scope":"Review-only BattleScene re-execution with active seeded CPU, not a shipping replay UI or earned Story receipt"}
	var record=Replay.create_record(meta,frames_to_store)
	var path=output.path_join("RECORDED_PUBLIC_INPUTS.json")
	check(Replay.write_json(record,path),"existing_ReplayStore_write")
	var loaded=Replay.read_json(path)
	check(bool(loaded.ok),"existing_ReplayStore_read_and_checksums")
	if not loaded.ok:finish();return
	var plan: Array=loaded.record.frames
	var gs=root.get_node("GameState")
	check(gs.match_seed==0 and not gs.battle_eval_mode,"same_default_seed_no_privileged_mode")
	gs.mode="versus";gs.stage_id="training-grid";gs.p1_fighter_id="kaia-windrow";gs.p2_fighter_id="juno-spark"
	gs.p1_body_variant=str(source.terminal.actors[0].body);gs.p2_body_variant=str(source.terminal.actors[1].body)
	gs.p1_is_cpu=false;gs.p2_is_cpu=true;gs.cpu_level=3
	gs.ruleset_id="stock-1";gs.stocks=1;gs.match_type="stock";gs.match_timer_seconds=180;gs.reset_match()
	var career_before: int=gs.career_matches
	var campaign=root.get_node("CampaignRuntime");var before_progress=JSON.stringify(campaign.progress)
	root.get_node("SceneRouter").go("battle")
	for i in range(360):
		await physics_frame
		if active_battle():break
	check(active_battle(),"actual_replay_BattleScene_started")
	if not active_battle():finish();return
	battle=current_scene;epoch=Engine.get_physics_frames()
	for actor in [battle.fighter1,battle.fighter2]:
		actor.hit_resolver.hit_confirmed.connect(record_contact)
		actor.koed.connect(stock_lost.bind(actor))
	physics_frame.connect(observe)
	var cursor:=0
	phase="persisted_public_input_playback"
	var cap=mini(3600,int(plan[-1].frame)+120)
	for i in range(cap):
		if not is_instance_valid(battle) or not battle._active:break
		var relative=Engine.get_physics_frames()-epoch
		while cursor<plan.size() and int(plan[cursor].frame)<=relative:
			var buttons: Dictionary=plan[cursor].p0
			keys(buttons.keys().filter(func(key):return buttons[key]))
			cursor+=1
		await physics_frame
	keys([])
	for i in range(90):
		await physics_frame
		if route_is("ResultsScene.tscn"):break
	var expected=signature(source.contacts,source_epoch)
	var actual=signature(contacts,epoch)
	check(actual==expected,"identical_actual_contact_frames_moves_and_damage")
	check(losses.size()==source.stock_losses.size() and not losses.is_empty(),"same_actual_stock_loss_count")
	if not losses.is_empty():
		check(int(losses[0].frame)-epoch==int(source.stock_losses[0].frame)-source_epoch,"identical_actual_KO_frame")
	check(route_is("ResultsScene.tscn") and gs.last_winner_slot==int(source.terminal.winner),"same_actual_winner_and_results")
	check(gs.career_matches==career_before+1,"one_legitimate_replayed_match_result")
	var saved=ConfigFile.new()
	check(saved.load("user://aa_save.cfg")==OK and int(saved.get_value("career","matches",-1))==career_before+1,"replayed_result_persisted")
	check(before_progress==JSON.stringify(campaign.progress),"Story_progress_preserved")
	replay_result={"source_path":source_path,"source_sha256":FileAccess.get_sha256(source_path),
		"stored_input_record":path,"stored_record_sha256":FileAccess.get_sha256(path),
		"expected_contacts":expected,"actual_contacts":actual,"CPU_active":true,"source_epoch":source_epoch,"playback_epoch":epoch}
	finish()

func finish() -> void:
	keys([])
	var result={"PASS":failures.is_empty(),"scope":"Real BattleScene replay of retained public player input with active seeded CPU; no synthetic state simulation or forced outcome. Review-only, not shipping replay UI.","headless":DisplayServer.get_name()=="headless","captured_gameplay_movie":false,"checks":checks,"failures":failures,"replay":replay_result,"contacts":contacts,"stock_losses":losses,"terminal":terminal,"inputs":inputs,"HUMAN_ART_APPROVED":false,"RC2_READY":false,"V1_0_0_RELEASE_AUTHORIZED":false}
	var f=FileAccess.open(output.path_join("ACTUAL_BATTLE_REPLAY.json"),FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close()
	print("ACTUAL_BATTLE_REPLAY ","PASS" if failures.is_empty() else "FAIL"," checks=",checks.size()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
