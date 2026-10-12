extends SceneTree
const Data = preload("res://scripts/data/data_loader.gd")
var failures: Array = []
var rows: Array = []

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
		push_error(label)

func frames(n: int) -> void:
	for i in range(n):
		await physics_frame

func press(actions: Array) -> void:
	for action in actions: Input.action_press(action)
	await frames(3)
	for action in actions: Input.action_release(action)
	await frames(2)

func wait_scene(suffix: String, maximum: int = 300) -> bool:
	for i in range(maximum):
		await physics_frame
		if current_scene != null and current_scene.scene_file_path.ends_with(suffix):
			await frames(5)
			return true
	return false

func _run() -> void:
	await process_frame
	# Explicit signed staged campaign fixture for the two earned-only cosmic fighters.
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--roster-staged-unlocks="):
			var campaign = root.get_node("CampaignRuntime")
			campaign.save_path=arg.get_slice("=",1)
			campaign.load_progress()
			check(campaign.progress.gray_routes.size()==7,"seven_signed_staged_gray_routes_required")
	var state = root.get_node("GameState")
	var router = root.get_node("SceneRouter")
	state.mode = "versus"
	state.arcade_active = false
	state.battle_eval_mode = false
	state.p2_is_cpu = false
	state.hazards_enabled = false
	state.items_enabled = false
	state.stocks = 1
	state.match_timer_seconds = 600
	for fid in Data.roster_ids():
		for variant in ["male", "female"]:
			var failure_start := failures.size()
			var label: String = str(fid) + ":" + variant
			router.go("fighter_select")
			check(await wait_scene("FighterSelectScene.tscn"), "select_scene:"+label)
			var select = current_scene
			var roster: Array = select.get("_roster")
			if fid not in roster:
				check(false,"not_selectable:"+label)
				continue
			select._set_pending_body_variant(variant)
			select.set("_cursor",roster.find(fid))
			select._on_lock_in_pressed()
			select.set("_cursor",roster.find("rook-ironside" if fid != "rook-ironside" else "ember-vale"))
			select._on_lock_in_pressed()
			check(select.can_start_match(), "lock_in:"+label)
			select._on_start_match_pressed()
			check(await wait_scene("StageSelectScene.tscn"), "stage_scene:"+label)
			check(state.p1_fighter_id == fid and state.p1_body_variant == variant, "selection_payload:"+label)
			current_scene._on_confirm_pressed()
			check(await wait_scene("BattleScene.tscn",600), "versus_to_battle:"+label)
			await frames(220) # Real shipping countdown and respawn invulnerability.
			var battle = current_scene
			var player = battle.fighter1
			var other = battle.fighter2
			other.controls_enabled = false
			check(player.model_3d.truth_flags().CURRENT_MODEL_SOURCE == "COLLECTIBLE_V1_CANDIDATE", "battle_model:"+label)
			var x: float = player.position.x
			await press(["p1_right"])
			check(player.position.x != x,"move:"+label)
			await press(["p1_jump"])
			check(player.velocity.y < 0 or not player.is_on_floor(),"jump:"+label)
			await frames(100)
			await press(["p1_attack"])
			check(str(player._current_move.get("move_id","")) == "jab_1","light_input:"+label)
			await frames(90)
			await press(["p1_attack","p1_special"])
			check(str(player._current_move.get("move_id","")) == "heavy_attack","heavy_input:"+label)
			await frames(110)
			await press(["p1_special"])
			check(str(player._current_move.get("move_id","")) == "neutral_special_projectile","special_input:"+label)
			await frames(140)
			player.aura = 100.0
			await press(["p1_attack"])
			check(str(player._current_move.get("move_id","")) == "aura_burst","super_input:"+label)
			await frames(170)
			player.aura = 0.0
			player.invincible = false
			other.training_play_move("jab_1")
			var resolver = load("res://scripts/combat/hit_resolver.gd").new()
			resolver.combat_feedback = other.combat_feedback
			root.add_child(resolver)
			var before: float = player.damage_percent
			resolver.resolve(other,player,other._current_move,0.0)
			check(player.damage_percent > before,"confirmed_take_hit:"+label)
			await frames(100)
			check(player.state_machine.current_state not in ["hitstun","hurt_light","hurt_heavy","launched","tumble"],"recover_hitstun:"+label)
			player.shielding = true
			player.state_machine.enter("shield_hold")
			other.training_play_move("heavy_attack")
			before = player.damage_percent
			resolver.resolve(other,player,other._current_move,0.0)
			check(player.damage_percent == before and player._last_hit_result.get("blocked",false),"confirmed_block:"+label)
			player.shielding = false
			await frames(100)
			resolver.queue_free()
			player.position = player.spawn_point
			player.velocity = Vector2.ZERO
			await frames(40)
			await press(["p1_up","p1_special"])
			check(str(player._current_move.get("move_id","")) == "up_special_recovery","recovery_input:"+label)
			await frames(100)
			other.stocks = 1
			other.position.x = float(battle.blast.get("right",2000))+100
			check(await wait_scene("ResultsScene.tscn",180),"victory_results:"+label)
			check(state.last_winner_slot == 1,"victory:"+label)
			current_scene._on_rematch_pressed()
			check(await wait_scene("BattleScene.tscn",600),"rematch:"+label)
			await frames(220)
			battle = current_scene
			battle.fighter2.controls_enabled = false
			battle.fighter1.stocks = 1
			battle.fighter1.position.x = float(battle.blast.get("left",-2000))-100
			check(await wait_scene("ResultsScene.tscn",180),"defeat_results:"+label)
			check(state.last_winner_slot == 2,"defeat:"+label)
			current_scene.on_back()
			await frames(6)
			rows.append({"ok":failures.size() == failure_start,"failures":failures.slice(failure_start),"fighter_id":fid,"presentation":variant,"form":"BASE","select_lock_stage_versus":true,"movement_jump_input":true,"light_heavy_special_super_input":true,"resolved_hit_block":true,"recovery_input":true,"scripted_blast_KO_victory_defeat":true,"rematch_return":true,"human_playthrough":false})
			print("SHIPPING_PATH_CHECK ",label)
	var output := FileAccess.open("res://../artifacts/v1_closure/shipping_roster_evidence.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"ok":failures.is_empty(),"failures":failures,"rows":rows,"scope":"Explicit staged earned cosmic unlock fixture where provided; 18 base presentations through real shipping selection, versus, countdown, input commands, hit/block resolver, scripted blast KOs, results, rematch and return. All other form battle paths and human taste remain unproved.","V1_AUTOMATED_READY":false,"V1_ANIME_HUMAN_PASS":false},"  ")+"\n")
	output.close()
	print("SHIPPING_ROSTER ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
