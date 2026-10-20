extends SceneTree
## Manual review of the real BattleScene. No automated input or seeded aura.
func _init() -> void: call_deferred("run")
func run() -> void:
	await process_frame
	var local := "--projectile-review-local" in OS.get_cmdline_user_args()
	var body := "male" if "--projectile-review-male" in OS.get_cmdline_user_args() else "female"
	var gs = root.get_node("GameState")
	gs.mode = "versus"; gs.stage_id = "training-grid"; gs.p1_fighter_id = "kaia-windrow"; gs.p2_fighter_id = "juno-spark"; gs.p1_body_variant = body; gs.p2_body_variant = body
	gs.p1_is_cpu = false; gs.p2_is_cpu = not local; gs.cpu_level = 3; gs.stocks = 3; gs.match_timer_seconds = 180
	root.get_node("SceneRouter").go("battle")
	for i in range(220): await physics_frame
	var help := Label.new()
	help.text = "PROJECTILE DEVELOPMENT REVIEW · " + ("local two-player" if local else "active CPU") + " · " + body + "\nKaia: A/D move · J attack · K special · L shield. Juno: arrows · M attack · comma special · period shield.\nSpecial: shot · Special + Shield: charge · 50 aura: medium · 75 aura: full\nEqual integrity cancels; stronger survives with reduced integrity/damage. Story saves untouched."
	if "--melee-owner-review" in OS.get_cmdline_user_args():
		help.text = "GROUNDED SPACING REVIEW · " + ("local two-player" if local else "active CPU") + " · " + body + "\nKaia: A/D move · J light · J+K heavy · L shield · W jump · I dodge · U grab.\nJuno: arrows move/up jump · M light · M+comma heavy · period shield · slash dodge · semicolon grab.\nWalk together; test strikes, shield, dodge/jump crossing and directional throws. Floor/art fit still pending. Story saves untouched."
	help.position = Vector2(30, 110)
	current_scene.hud.add_child(help)
	if "--projectile-review-smoke" in OS.get_cmdline_user_args():
		print("PROJECTILE_PLAYABLE_REVIEW_READY controls=", current_scene.fighter1.controls_enabled, " CPU=", current_scene.fighter2.is_cpu, " body=", body)
		print("REVIEW_MODEL_PATHS ", current_scene.fighter1.model_3d._proxy_model.scene_file_path, " ", current_scene.fighter2.model_3d._proxy_model.scene_file_path)
		quit()
