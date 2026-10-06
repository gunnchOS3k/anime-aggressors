extends SceneTree
var failures: Array = []
var rows: Array = []
func _init() -> void: call_deferred("_run")
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label); push_error(label)
func _run() -> void:
	var state = root.get_node("GameState")
	var campaign = root.get_node("CampaignRuntime")
	check(campaign.campaign.get("routes",[]).size()==8,"packed_story_json")
	check(state.roster_ids().size()==9,"packed_roster_json")
	state.mode = "versus"
	state.battle_eval_mode = true
	state.battle_eval_max_frames = 100000
	state.p2_is_cpu = false
	state.stocks = 10
	for fid in state.roster_ids():
		state.p1_fighter_id = fid
		state.p2_fighter_id = "rook-ironside" if fid != "rook-ironside" else "ember-vale"
		root.get_node("SceneRouter").go("battle")
		for i in range(12): await physics_frame
		var fighter = current_scene.fighter1
		fighter.cpu.clear_simulated_inputs()
		fighter.is_cpu = false
		fighter.dummy_mode = "idle"
		Input.action_release("p1_shield")
		for i in range(220): await physics_frame
		current_scene.fighter2.controls_enabled = false
		check(fighter.model_3d.truth_flags().CURRENT_MODEL_SOURCE=="COLLECTIBLE_V1_CANDIDATE","packed_model:"+str(fid))
		check(not fighter.move_manifest.get("moves",[]).is_empty(),"packed_moves:"+str(fid))
		Input.action_press("p1_right")
		for i in range(12):await physics_frame
		Input.action_release("p1_right")
		for i in range(100):await physics_frame
		Input.action_press("p1_attack")
		for i in range(4):await physics_frame
		Input.action_release("p1_attack")
		check(str(fighter._current_move.get("move_id",""))!="","packed_attack_input:"+str(fid))
		rows.append({"fighter_id":fid,"model_source":fighter.model_3d.get_current_model_source(),"active_move":str(fighter._current_move.get("move_id","")),"fighter_state":fighter.state_machine.current_state,"controls_enabled":fighter.controls_enabled})
	var identity=JSON.parse_string(FileAccess.get_file_as_string("res://data/runtime/build_identity.json"))
	check(identity is Dictionary and identity.get("git_sha","")==OS.get_environment("AA_EXPECTED_BUILD_SHA"),"packed_exact_source_sha")
	var out=FileAccess.open("/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/packed_runtime_evidence.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"ok":failures.is_empty(),"failures":failures,"rows":rows,"source_sha":identity.get("git_sha","") if identity is Dictionary else "","scope":"Actual exported PCK: JSON data, exact build identity, nine BASE fighter BattleScene model/move loads and attack input. Does not prove full exported Story, every form lifecycle, Web or Android."},"  ")+"\n");out.close()
	print("PACKED_RUNTIME ","PASS" if failures.is_empty() else "FAIL"," failures=",failures)
	quit(0 if failures.is_empty() else 1)
