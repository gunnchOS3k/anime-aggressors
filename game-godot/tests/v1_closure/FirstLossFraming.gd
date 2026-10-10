extends SceneTree
var failures: Array = []
var rows: Array = []
func _init() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label);push_error(label)
func _run() -> void:
	var c=root.get_node("CampaignRuntime")
	var state=root.get_node("GameState")
	var router=root.get_node("SceneRouter")
	c.save_path="/private/tmp/anime-full-campaign-v2.json"
	c.load_progress()
	var fixture: Dictionary=c.progress.duplicate(true)
	check(fixture["gray_routes"].size()==7,"signed_full_fixture_required")
	c.save_path="/private/tmp/anime-first-loss-framing.json"
	c._save_key=PackedByteArray()
	state.battle_eval_mode=true
	state.battle_eval_max_frames=100000
	for fid in c.campaign["spectral_order"]:
		c.progress=fixture.duplicate(true)
		c.progress["routes"][fid]["completed"]=c.progress["routes"][fid]["completed"].slice(0,10)
		c._rebuild_cursor(fid)
		check(c.select_route(fid),"select_"+fid)
		check(c.begin_encounter(),"playable_loss_"+fid)
		router.go("battle")
		for i in range(10):await physics_frame
		var battle=current_scene
		var expected: String=c.route_data(fid)["consequence"]["interaction"]
		check(battle.fighter2.fighter_id==c.APPROVED_FIRST_LOSS[fid],"lost_identity_"+fid)
		check(battle.get_meta("first_loss_framing","")==expected,"route_framing_"+fid)
		check(battle.fighter1.controls_enabled,"live_player_control_"+fid)
		check(not battle.fighter2.controls_enabled,"lost_actor_holds_space_"+fid)
		if fid=="juno-spark":check(battle._story_objective.escorts.size()==5,"five_escape_team_actors")
		var camera=battle.get_node("Camera2D")
		rows.append({"route":fid,"lost":battle.fighter2.fighter_id,"framing":expected,"camera_zoom":camera.zoom.x,"lost_x":battle.fighter2.position.x,"real_renderer_capture":false,"final_authored_cinematic":false})
		c.abandon_encounter()
		router.go("story")
		for i in range(6):await physics_frame
	var file:=FileAccess.open("res://../artifacts/v1_closure/first_loss_framing_evidence.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"ok":failures.is_empty(),"failures":failures,"rows":rows,"scope":"Seven real source BattleScene candidate camera/actor staging paths with signed checkpoint fixtures; no rendered/cinematic/human acceptance."},"  ")+"\n");file.close()
	print("FIRST_LOSS_FRAMING ",failures.is_empty()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
