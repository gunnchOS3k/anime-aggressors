extends SceneTree
var failures: Array = []
func _init() -> void: call_deferred("_run")
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label); push_error(label)
func _run() -> void:
	var c=root.get_node("CampaignRuntime")
	var state=root.get_node("GameState")
	var router=root.get_node("SceneRouter")
	c.save_path="/private/tmp/anime-full-campaign-v2.json"
	c.load_progress()
	check(c.progress["gray_routes"].size()==7,"fresh_process_seven_gray")
	check(c.progress["yin_unlocked"] and c.progress["yang_unlocked"],"fresh_process_cosmic_unlocks")
	check("yin" in state.selectable_roster_ids() and "yang" in state.selectable_roster_ids(),"normal_roster_unlocks")
	var count:=0
	for route in c.campaign["routes"]:
		var id:String=route["id"]
		check(c.progress["routes"][id]["complete"],"fresh_process_complete_"+id)
		count+=c.progress["routes"][id]["completed"].size()
	check(count==145,"fresh_process_all_145")
	var saved:=JSON.stringify(c.progress)
	var watch_rows:=[]
	for fid in c.campaign["spectral_order"]:
		c.watch_route_id=fid
		c.watch_presentation="female"
		router.go("ova")
		for i in range(20): await physics_frame
		var watch=current_scene
		check(watch.route["anchor"]==fid,"watch_anchor_"+fid)
		watch._toggle_pause()
		var elapsed:float=watch.elapsed
		for i in range(8): await physics_frame
		check(watch.elapsed==elapsed,"watch_pause_"+fid)
		await watch.seek(10)
		check(watch._battle.fighter2.fighter_id==c.APPROVED_FIRST_LOSS[fid],"watch_shared_first_loss_"+fid)
		await watch.seek(11)
		check(watch._watch_presenter.puppets.size()==5,"watch_five_puppets_"+fid)
		check(watch._watch_presenter.puppets[0].get_meta("story_form")=="BLACK_PUPPET","watch_puppet_forms_"+fid)
		await watch.seek(13)
		check(watch._watch_presenter.puppets.size()==4,"watch_equilibrium_"+fid)
		await watch.seek(17)
		check(watch._watch_presenter.actors.size()==3,"watch_two_cosmic_manifests_"+fid)
		await watch.seek(16)
		check(watch._battle.fighter1.get_meta("story_form","")=="PRISMATIC_GRAY","watch_shared_gray_"+fid)
		await watch.seek(19)
		check(watch.node_index==19,"watch_ending_reachable_"+fid)
		router.go("story")
		for i in range(6): await physics_frame
		check(JSON.stringify(c.progress)==saved,"watch_never_writes_story_"+fid)
		watch_rows.append({"route":fid,"pause_seek_return":true,"shared_loss_and_gray_models":true,"progress_unchanged":true,"full_ova_complete":false})
	state.mode="versus"
	state.battle_eval_mode=true
	state.battle_eval_max_frames=100000
	state.p1_fighter_id="juno-spark"
	state.p2_fighter_id="orion-vell"
	state.p1_story_skin="PRISMATIC_GRAY"
	router.go("battle")
	for i in range(15): await physics_frame
	check(current_scene.fighter1.data.get("collectible_review_form")=="PRISMATIC_GRAY","earned_competitive_gray_skin")
	check(current_scene.fighter1.move_manifest==preload("res://scripts/data/data_loader.gd").load_moves("juno-spark"),"gray_preserves_move_authority")
	check(not current_scene.fighter1.get_meta("story_cosmic_contract",false),"competitive_contract_is_separate")
	var output:=FileAccess.open("res://../artifacts/v1_closure/campaign_restart_evidence.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"ok":failures.is_empty(),"failures":failures,"fresh_process":true,"completed_nodes":count,"watch":watch_rows,"scope":"Separate Godot process loads signed FullCampaign staged source save; watch isolation and competitive skin checks. No exported or human acceptance."},"  ")+"\n");output.close()
	print("CAMPAIGN_RESTART ",failures.is_empty()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
