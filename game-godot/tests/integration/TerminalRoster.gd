extends SceneTree
## Declared configuration/respawn/attack fixtures against real public-model
## actors. Verifies terminal ownership, not earned forms, combat or original art.
const IDS=preload("res://scripts/visual/spectral_feedback_renderer.gd").IDS
var output := ""
var rows: Array = []
var failures: Array = []

func _initialize() -> void:call_deferred("run")

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.trim_prefix("--ordinary-output=")
	if not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Refusing owner profile");quit(2);return
	var gs=root.get_node("GameState")
	var campaign=root.get_node("CampaignRuntime")
	var story_before=JSON.stringify(campaign.progress)
	gs.mode="versus";gs.stage_id="training-grid";gs.p2_is_cpu=false
	root.get_node("SceneRouter").go("battle")
	for i in range(360):
		await physics_frame
		if current_scene != null and "fighter1" in current_scene and current_scene._active:break
	var battle=current_scene
	if battle==null or not "fighter1" in battle or not battle._active:push_error("Battle not active");quit(1);return
	battle._battle_sim.set_paused(true) # Explicit teardown fixture, no combo/CPU claim.
	var p=battle.fighter1;var d=battle.fighter2
	for fid in IDS:
		for body in ["male","female"]:
			for facing in [1,-1]:
				gs.p1_body_variant=body;gs.p2_body_variant=body
				p.configure(fid,1,true,3,Vector2(-202,200))
				d.configure("juno-spark" if fid!="juno-spark" else "kaia-windrow",2,false,3,Vector2(202,200))
				p.facing=facing;p.model_3d.set_facing(facing)
				p.state_machine.enter("idle");d.state_machine.enter("idle")
				var label=fid+":"+body+":"+str(facing)
				var valid_before=not p.combat_closed
				var catalog=JSON.stringify(p.move_manifest)
				# Pending real respawn callback must not reopen terminal acting later.
				p.reset_fighter();p.invincible=false
				var ladder: Array=p.get_forms_doc().get("form_ladder",[])
				if not ladder.is_empty():p.apply_form(str(ladder[-1]))
				var form=p.get_current_form_id()
				p.aura=87.0
				var projectile_moves=p.move_manifest.moves.filter(func(m):return m.has("projectile"))
				if not projectile_moves.is_empty():p.projectile_spawner.spawn_from_move(projectile_moves[0],0)
				p.move_runner.start_move(p.move_manifest.moves[0],p)
				p.queue_attack_command("attack_forward")
				Input.action_press("p1_right");Input.action_press("p1_shield")
				p.close_combat_for_match_end(true)
				var closed=p.combat_closed and not p.controls_enabled and not p.move_runner.active and p._pending_attack_cmd.is_empty() and p.projectile_spawner.count()==0
				var contact_move: Dictionary=p.move_manifest.moves[0].duplicate(true);contact_move["_from_projectile"]=true
				var late_attacker=p.hit_resolver.resolve(p,d,contact_move,0).is_empty()
				var late_defender=d.hit_resolver.resolve(d,p,contact_move,0).is_empty()
				var unchanged=catalog==JSON.stringify(p.move_manifest) and p.get_current_form_id()==form and p.aura==87.0 and p.stocks==3
				for i in range(2):await physics_frame
				var passed=valid_before and closed and late_attacker and late_defender and unchanged and not p.hitbox.monitoring and p.state_machine.current_state=="victory" and not Input.is_action_pressed("p1_right") and p.model_3d.get_body_variant()==body and p.facing==facing
				if not passed:failures.append(label)
				rows.append({"fighter":fid,"body":body,"facing":facing,"PASS":passed,"closed":closed,"late_attacker_rejected":late_attacker,"late_defender_rejected":late_defender,"catalog_form_aura_stocks_preserved":unchanged,"retained_form":form,"model":p.model_3d.get_current_model_source()})
	for i in range(80):await physics_frame
	if p.state_machine.current_state!="victory" or not p.combat_closed:failures.append("respawn_callback_cannot_reopen_terminal_actor")
	if JSON.stringify(campaign.progress)!=story_before:failures.append("Story_progress_changed")
	var f=FileAccess.open(output.path_join("TERMINAL_ROSTER.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":failures.is_empty(),"rows":rows,"failures":failures,"scope":"36 real public-actor identity/body/facing configurations with declared lifecycle fixtures. No earned progression, original-art, native visual or balance acceptance."},"  "));f.close()
	print("TERMINAL_ROSTER ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
