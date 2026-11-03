extends SceneTree
## Identified gameplay defect: a confirmed body hit must cancel the victim's ongoing move.
var output := ""
func _init() -> void:call_deferred("_run")
func _run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState")
	gs.mode="versus";gs.p1_fighter_id="ember-vale";gs.p2_fighter_id="juno-spark";gs.p2_is_cpu=false;gs.battle_eval_mode=true;gs.battle_eval_max_frames=100000;gs.stocks=9
	root.get_node("SceneRouter").go("battle")
	for i in range(15):await physics_frame
	var p=current_scene.fighter1
	var d=current_scene.fighter2
	p.controls_enabled=false;d.controls_enabled=false;p.invincible=false;d.invincible=false
	p.global_position=Vector2(-200,200);d.global_position=Vector2(200,200)
	d.training_play_move("heavy_attack")
	p.training_play_move("heavy_attack")
	var result: Dictionary=p.hit_resolver.resolve(p,d,p._current_move,0)
	var ok: bool=not result.is_empty() and not d.move_runner.active and not d.hitbox.monitoring and d.hitstun_remaining>0
	var f=FileAccess.open(output.path_join("interrupted_move.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"ok":ok,"victim_move_still_active":d.move_runner.active,"victim_hitbox_monitoring":d.hitbox.monitoring,"victim_state":d.state_machine.current_state,"hitstun_seconds":d.hitstun_remaining,"launch":[d.velocity.x,d.velocity.y],"scope":"direct counterhit fixture; not natural collision/combos; preserves CombatMath and manifests"},"  ")+"\n");f.close()
	print("INTERRUPTED_MOVE ","PASS" if ok else "FAIL")
	quit(0 if ok else 1)
