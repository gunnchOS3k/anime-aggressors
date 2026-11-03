extends SceneTree
const Data = preload("res://scripts/data/data_loader.gd")
var rows: Array = []
var capture_root := "res://../artifacts/v1_closure/review/runtime"
func _init() -> void:
	call_deferred("_run")

func physics(n: int) -> void:
	for i in range(n): await physics_frame

func capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	image.save_png(path)

func _run() -> void:
	var state = root.get_node("GameState")
	var router = root.get_node("SceneRouter")
	state.mode = "versus"
	state.arcade_active = false
	state.battle_eval_mode = true
	state.battle_eval_max_frames = 100000
	state.p2_is_cpu = false
	state.stage_id = "skyline-arena"
	state.stocks = 99
	state.hazards_enabled = false
	state.items_enabled = false
	for fid in Data.roster_ids():
		state.p1_fighter_id = fid
		state.p1_body_variant = "female" if fid == "kaia-windrow" else "male"
		state.p2_fighter_id = "rook-ironside" if fid != "rook-ironside" else "ember-vale"
		router.go("battle")
		await physics(18)
		var battle = current_scene
		var player = battle.fighter1
		var defender = battle.fighter2
		defender.controls_enabled = false
		player.controls_enabled = false
		await capture(capture_root + "/" + fid + "/battle.png")
		var model = player.model_3d
		model.set_presentation_context("showcase")
		model.set_process(false)
		player.set_physics_process(false)
		for i in range(16):
			model.clear_attack_facing_lock()
			model.get("_loaded_model").rotation_degrees.y = i * 22.5
			await capture(capture_root + "/" + fid + "/turntable/%02d.png" % i)
		model.set_process(true)
		player.set_physics_process(true)
		model.set_presentation_context("battle")
		for mid in ["jab_1","heavy_attack","side_special","aura_burst"]:
			player.position = Vector2(-130,160)
			player.velocity = Vector2.ZERO
			defender.position = Vector2(-80,160)
			defender.velocity = Vector2.ZERO
			player.state_machine.enter("idle")
			player.move_runner.cancel()
			player.invincible = false
			defender.invincible = false
			defender.damage_percent = 0.0
			defender.state_machine.enter("idle")
			player.training_play_move(mid,100.0 if mid == "aura_burst" else 0.0,1)
			var move: Dictionary = player._current_move
			var startup := int(move.get("startup_frames",8))
			var active := int(move.get("active_frames",6))
			var recovery := int(move.get("recovery_frames",12))
			var step := maxi(1,ceili(float(startup+active+recovery)/12.0))
			for frame in range(12):
				await physics(step)
				await capture(capture_root + "/" + fid + "/" + mid + "/%02d.png" % frame)
			rows.append({"fighter_id":fid,"move_id":mid,"scope":"Staged training move in real BattleScene, natural hitbox polling and visible renderer. Candidate motion and SFX; not human taste or complete competitive form proof."})
		print("CAPTURE_REVIEW ",fid)
	state.battle_eval_mode = false
	var f := FileAccess.open(capture_root+"/capture_manifest.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"rows":rows,"owner_approved":false,"capture_mode":"real Godot macOS Compatibility renderer"},"  ")+"\n");f.close()
	quit()
