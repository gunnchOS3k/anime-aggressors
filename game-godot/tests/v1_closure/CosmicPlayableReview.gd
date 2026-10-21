extends SceneTree
## Isolated manual candidate review; no unlocks, save seeding or automated input.
func _init() -> void:call_deferred("run")
func run() -> void:
	await process_frame
	var fighter := "yin";var opponent := "juno-spark";var body := "female"
	var local := "--cosmic-local" in OS.get_cmdline_user_args()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--cosmic-fighter="):fighter=arg.get_slice("=",1)
		if arg.begins_with("--cosmic-opponent="):opponent=arg.get_slice("=",1)
		if arg.begins_with("--cosmic-body="):body=arg.get_slice("=",1)
	if fighter not in ["yin","yang"] or opponent not in preload("res://scripts/visual/spectral_feedback_renderer.gd").IDS or body not in ["male","female"]:quit(2);return
	var gs=root.get_node("GameState")
	gs.mode="versus";gs.stage_id="training-grid";gs.p1_fighter_id=fighter;gs.p2_fighter_id=opponent
	gs.p1_is_cpu=false;gs.p2_is_cpu=not local;gs.cpu_level=3;gs.stocks=3;gs.match_timer_seconds=180
	gs.p1_body_variant=body;gs.p2_body_variant=body
	root.get_node("SceneRouter").go("battle")
	for i in range(220):await physics_frame
	var label:=Label.new();label.position=Vector2(30,100)
	label.text="COSMIC KIT TUNING CANDIDATE · "+fighter+" / "+opponent+" · "+body+" · "+("local players" if local else "active CPU")+"\nA/D move · J light · J+K heavy · K shot · W jump · L shield · U grab · I dodge.\nK+L charge normally. Down+K: "+("absorb one weak shot during active window; costs25earned aura" if fighter=="yin" else "stationary0.6s panel; one at a time; vulnerable to stronger shots")+"\nReview-only selection. No Story unlocks or owner-save changes. Balance/art/feel approval pending."
	current_scene.hud.add_child(label)
	if "--cosmic-smoke" in OS.get_cmdline_user_args():
		print("COSMIC_PLAYABLE_READY ",fighter," ",opponent," ",body," CPU=",current_scene.fighter2.is_cpu," paths=",current_scene.fighter1.model_3d._proxy_model.scene_file_path," ",current_scene.fighter2.model_3d._proxy_model.scene_file_path);quit()
