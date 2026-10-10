extends SceneTree
var failures: Array = []
func _init() -> void:
	call_deferred("_run")
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label); push_error(label)
func _run() -> void:
	var state = root.get_node("GameState")
	state.mode = "versus"
	state.battle_eval_mode = true
	state.battle_eval_max_frames = 100000
	state.p1_fighter_id = "kaia-windrow"
	state.p2_fighter_id = "ember-vale"
	state.p2_is_cpu = false
	state.stocks = 10
	root.get_node("SceneRouter").go("battle")
	for i in range(10): await physics_frame
	var player = current_scene.fighter1
	var other = current_scene.fighter2
	player.controls_enabled = false
	other.controls_enabled = false
	player.velocity = Vector2.ZERO
	player.training_play_move("up_special_recovery")
	var move: Dictionary = player._current_move
	player.move_runner.frame_in_phase = 1
	player._on_move_active(move)
	var first_velocity: Vector2 = player.velocity
	for frame in range(2,int(move.active_frames)+1):
		player.move_runner.frame_in_phase = frame
		player._on_move_active(move)
	check(player.velocity == first_velocity and first_velocity.y == float(move.self_movement.y),"one_recovery_impulse_per_activation")
	player.projectile_spawner.clear_all()
	player.training_play_move("neutral_special_projectile")
	move = player._current_move
	for frame in range(1,int(move.active_frames)+1):
		player.move_runner.frame_in_phase = frame
		player._on_move_active(move)
	check(player.projectile_spawner.count() == 1,"one_projectile_per_cast")
	player.move_runner.cancel()
	player.invincible = false
	player.shielding = true
	player.state_machine.enter("shield_hold")
	other.training_play_move("heavy_attack")
	var resolver = load("res://scripts/combat/hit_resolver.gd").new()
	resolver.combat_feedback = other.combat_feedback
	root.add_child(resolver)
	var feedback: Array = []
	other.combat_feedback.feedback_triggered.connect(func(info: Dictionary): feedback.append(info))
	resolver.resolve(other,player,other._current_move,0.0)
	check(feedback.size()==1 and feedback[0].blocked and feedback[0].sfx_event == "block", "confirmed_block_sound")
	check(feedback.size()==1 and feedback[0].launch == Vector2.ZERO and not feedback[0].has("launch_prediction"), "block_has_no_launch_cue")
	check(player.damage_percent == 0.0 and player._hitstop > 0.0,"shield_contact_hitstop_without_body_damage")
	feedback.clear()
	player.state_machine.enter("shield_start")
	check(feedback.is_empty(),"raising_shield_emits_no_hit_feedback")
	player._hitstop=0
	player.controls_enabled=true
	player.state_machine.enter("shield_hold")
	Input.action_release("p1_shield")
	player._handle_actions()
	check(not player.shielding,"shield_release_respected_while_action_locked")
	player.move_runner.cancel()
	player.state_machine.enter("hitstun")
	player.queue_attack_command("attack_heavy")
	player._handle_actions()
	check(not player.move_runner.active,"queued_cpu_attack_cannot_bypass_hitstun")
	player.state_machine.enter("idle")
	player._handle_actions()
	check(player.move_runner.active,"queued_cpu_attack_runs_after_recovery")
	var file := FileAccess.open("res://../artifacts/v1_closure/combat_activation_evidence.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"ok":failures.is_empty(),"failures":failures,"scope":"Real Fighter active callbacks over every active frame; HitResolver confirmed block and feedback. Regression coverage for repeated impulses/casts and shield contact classification."},"  ")+"\n");file.close()
	print("COMBAT_ACTIVATION ","PASS" if failures.is_empty() else "FAIL"," failures=",failures)
	resolver.queue_free()
	current_scene.queue_free()
	call_deferred("_finish")

func _finish() -> void:
	# Release scene-local references and allow legitimate recovery timers to drain.
	for i in range(180): await physics_frame
	quit(0 if failures.is_empty() else 1)
