extends SceneTree
## Real public charge/chord/attack inputs in BattleScene. Reconfigured, idle P2
## fixtures; not active-CPU balance, competitive KO or earned Story evidence.
const SPECTRUM := ["ember-vale", "rook-ironside", "juno-spark", "kaia-windrow", "nix-calder", "orion-vell", "vesper-nyx"]
const Forms = preload("res://scripts/combat/form_definition.gd")
const Scaling = preload("res://scripts/combat/aura_scaler.gd")
const Identity = preload("res://scripts/combat/aura_identity.gd")
const Loader = preload("res://scripts/data/data_loader.gd")
var output := ""
var single := false
var cosmic_only := false
var failures: Array = []
var rows: Array = []
func _init() -> void: call_deferred("_run")
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label); push_error(label)
func release_inputs() -> void:
	for slot in [1,2]:
		for key in ["attack","special","shield","jump","grab","dodge","left","right","up","down"]:
			Input.action_release("p%d_%s" % [slot,key])
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func chord() -> void:
	Input.action_press("p1_shield"); Input.action_press("p1_special"); Input.action_press("p1_attack")
	await frames(2)
	release_inputs()
func charge(p) -> void:
	Input.action_press("p1_shield"); Input.action_press("p1_special")
	for i in range(600):
		await physics_frame
		if p.aura >= 99.99: break
	release_inputs(); await frames(3)
func fixture(p,d,fid: String,body: String,direction: int) -> void:
	release_inputs()
	var gs=root.get_node("GameState")
	gs.p1_body_variant=body; gs.p2_body_variant=body
	p.configure(fid,1,false,9,Vector2(-80*direction,240))
	d.configure("juno-spark" if fid!="juno-spark" else "kaia-windrow",2,false,9,Vector2(240*direction,240))
	for f in [p,d]:
		f.move_runner.cancel(); f._hitstop=0; f.invincible=false; f.aura=0; f.damage_percent=0
		f.state_machine.enter("idle"); f.velocity=Vector2.ZERO; f.hitstun_remaining=0
		f.controls_enabled=true; f.armor_frames_remaining=0
	p.facing=direction; d.facing=-direction
	await frames(8)
func _run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output=arg.get_slice("=",1)
		if arg=="--single": single=true
		if arg=="--cosmic-only": cosmic_only=true
	var gs=root.get_node("GameState")
	gs.mode="versus"; gs.stage_id="training-grid"; gs.p1_fighter_id="ember-vale"; gs.p2_fighter_id="juno-spark"; gs.p2_is_cpu=false; gs.stocks=9
	# One scene hosts many reset lifecycle fixtures; use the existing untimed
	# stock rules so a real match timer cannot route this test to Results midway.
	gs.match_timer_seconds=0; gs.match_type="stock_untimed"
	root.get_node("SceneRouter").go("battle"); await frames(220)
	var p=current_scene.fighter1; var d=current_scene.fighter2
	var fighters: Array=SPECTRUM.slice(0,1) if single else SPECTRUM
	if cosmic_only: fighters=["yin","yang"]
	for fid in fighters:
		for body in (["male"] if single else ["male","female"]):
			for direction in ([1] if single else [1,-1]):
				await fixture(p,d,fid,body,direction)
				var prefix: String=fid+":"+body+":"+str(direction)
				var ladder: Array=p.get_forms_doc().form_ladder
				if fid in ["yin","yang"]:
					p.set_meta("story_cosmic_contract",true)
					check(not p.can_start_transform_sequence(),prefix+":boss_context_excluded")
					p.remove_meta("story_cosmic_contract")
				await chord(); await frames(6)
				check(not p._transform_sequence_active and p.get_current_form_id()==ladder[0],prefix+":low_aura_rejected")
				# Clear the ordinary low-meter charge/attack with its natural recovery.
				await frames(70)
				var chain: Array=[]; var costs: Array=[]
				for step in [1,2]:
					await charge(p)
					var before: float=p.aura; var count: int=p.get_transform_activations()
					await chord()
					check(p._transform_sequence_active,prefix+":step%d_public_start" % step)
					for i in range(100):
						if not p._transform_sequence_active: break
						await physics_frame
					chain.append(p.get_current_form_id()); costs.append(before-p.aura)
					check(p.get_current_form_id()==ladder[step],prefix+":step%d_exact_destination" % step)
					check(p.get_transform_activations()==count+1 and not p._transform_sequence_active,prefix+":step%d_once" % step)
					check(before-p.aura>=25 and before-p.aura<25.2,prefix+":step%d_existing_cost_once" % step)
					var entry: Dictionary=Forms.form_entry(p.get_forms_doc(),str(ladder[step]))
					# Execute the real public tilt and compare exactly one application of
					# the pre-existing form -> aura -> identity composition. No new buffs.
					Input.action_press("p1_right" if direction==1 else "p1_left",0.5)
					Input.action_press("p1_attack"); await frames(2); release_inputs()
					var base_move: Dictionary=Loader.find_move(p.move_manifest,"forward_tilt")
					var expected: Dictionary=Identity.apply_to_scaled_move(Scaling.apply_to_move(Forms.apply_move_override(base_move,entry,"forward_tilt"),p.aura),fid,p.aura,str(p.data.get("combatTag","")))
					check(p._current_move.get("form_id","")==ladder[step],prefix+":step%d_override_executed" % step)
					check(is_equal_approx(float(p._current_move.damage),float(expected.damage)),prefix+":step%d_existing_composition_once" % step)
					await frames(70)
				check(p.model_3d.get_body_scale_contract().body_scale==1.0,prefix+":canonical_scale")
				# A completed form cannot survive stock/reset into the next life.
				p.reset_fighter()
				check(p.get_current_form_id()==ladder[0] and not p._transform_sequence_active,prefix+":respawn_base")
				await frames(85)
				# Genuine public P2 jab interrupts transformation startup.
				await fixture(p,d,fid,body,direction); await charge(p); await chord()
				d.global_position=p.global_position+Vector2(50*direction,0); d.facing=-direction
				Input.action_press("p2_attack"); await frames(25); release_inputs()
				var damage: float=p.damage_percent
				check(damage>0,prefix+":real_jab_contact")
				check(not p._transform_sequence_active,prefix+":hit_cancels_sequence")
				await frames(95)
				check(p.get_current_form_id()==ladder[0],prefix+":no_late_transform_after_hit")
				var post_hit_form: String=p.get_current_form_id()
				# Stock-loss entry during another public-input startup must not fire a
				# deferred transformation on the replacement life. This direct call is
				# an explicit lifecycle fixture, never a claimed earned competitive KO.
				await frames(45); await charge(p); await chord()
				p.lose_stock(); await frames(100)
				check(p.get_current_form_id()==ladder[0] and not p._transform_sequence_active,prefix+":stock_during_startup_cleanup")
				rows.append({"fighter":fid,"body":body,"facing":direction,"chain":chain,"aura_spent_at_completion":costs,"interrupt_damage":damage,"post_hit_form":post_hit_form,"post_stock_form":p.get_current_form_id(),"scope":"public input, reconfigured idle P2; direct respawn/stock-loss lifecycle fixtures, not competitive stock loss"})
				write_result(false)
	release_inputs()
	write_result(true)
	print("ASCENDED_LIFECYCLE rows=",rows.size()," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
func write_result(complete: bool) -> void:
	if output!="":
		var f=FileAccess.open(output.path_join("ascended_lifecycle.json"),FileAccess.WRITE)
		f.store_string(JSON.stringify({"PASS":complete and failures.is_empty(),"complete":complete,"rows":rows,"failures":failures,"human_approved":false},"\t")); f.close()
