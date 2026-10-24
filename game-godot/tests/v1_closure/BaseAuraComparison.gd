extends SceneTree
## Explicit aura/spacing fixtures; public tilt inputs, idle defender. Candidate
## single-pass is opt-in metadata, never a changed accepted BASE default.
const IDs=preload("res://scripts/visual/spectral_feedback_renderer.gd").IDS
var output: String=""
var pilot:=false
var rows: Array=[]
var failures: Array=[]
var contacts: Array=[]
func _init() -> void:call_deferred("run")
func frames(n: int) -> void:
	for i in range(n):await physics_frame
func check(ok: bool,label: String) -> void:
	if not ok:failures.append(label);push_error(label)
func release() -> void:
	for slot in [1,2]:
		for key in ["left","right","attack","special","shield"]:Input.action_release("p%d_%s"%[slot,key])
func write(complete: bool) -> void:
	var f=FileAccess.open(output.path_join("base_aura_comparison.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":complete and failures.is_empty(),"complete":complete,"rows":rows,"failures":failures,"accepted_BASE_default":"historical_unchanged","scope":"Paired controlled BASE aura fixtures, idle P2; no balance/human/CPU/device acceptance"},"\t"));f.close()
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
		if arg=="--pilot":pilot=true
	var gs=root.get_node("GameState")
	gs.mode="versus";gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0;gs.match_type="stock_untimed"
	root.get_node("SceneRouter").go("battle");await frames(220)
	var p=current_scene.fighter1;var d=current_scene.fighter2
	p.hit_resolver.hit_confirmed.connect(func(a,b,info):if a==p and b==d:contacts.append(info.duplicate(true)))
	for fid in (IDs.slice(0,1) if pilot else IDs):
		for body in (["male"] if pilot else ["male","female"]):
			for facing in ([1] if pilot else [1,-1]):
				for amount in ([75.5] if pilot else [0.5,75.5]):
					var pair: Dictionary={"fighter":fid,"body":body,"facing":facing,"aura_fixture":amount}
					for candidate in [false,true]:
						release();gs.p1_body_variant=body;gs.p2_body_variant=body
						p.configure(fid,1,false,9,Vector2(-40,240));d.configure("juno-spark",2,false,9,Vector2(-40+48*facing,240))
						p.global_position=Vector2(-40,240);d.global_position=Vector2(-40+48*facing,240)
						for actor in [p,d]:
							actor.move_runner.cancel();actor.projectile_spawner.clear_all();actor.state_machine.enter("idle")
							actor.controls_enabled=true;actor.invincible=false;actor.armor_frames_remaining=0;actor.shielding=false
							actor.damage_percent=0;actor.aura=0;actor._hitstop=0;actor.velocity=Vector2.ZERO
							actor._recent_move_ids.clear();actor.combo_count=0;actor._input_edge_held.clear()
						p.facing=facing;d.facing=-facing
						current_scene._battle_sim.body_spacing.previous_order.clear()
						for i in range(90):
							await physics_frame
							if p.is_on_floor() and d.is_on_floor() and p.state_machine.can_attack() and d.state_machine.can_attack():break
						p.set_meta("base_aura_single_pass_candidate",candidate);p.aura=amount;contacts.clear()
						Input.action_press("p1_right" if facing==1 else "p1_left",0.5);Input.action_press("p1_attack")
						await frames(2);release();await frames(45)
						var label: String=fid+body+str(facing)+str(amount)+str(candidate)
						check(contacts.size()==1,label+":one_real_contact")
						var expected: float=float(p._current_move.damage)*p.get_damage_dealt_mult()*float(gs.damage_ratio)
						if not contacts.is_empty():expected+=float(contacts[0].get("burn_trail",0))*0.35
						if candidate and not contacts.is_empty():check(is_equal_approx(float(contacts[0].damage),expected),label+":one_resolution_pass")
						pair["candidate" if candidate else "historical"]={"contact_count":contacts.size(),"resolved_start_damage":p._current_move.get("damage",0),"expected_once":expected,"damage":contacts[0].get("damage",0) if not contacts.is_empty() else 0,"launch":str(contacts[0].get("launch",Vector2.ZERO)) if not contacts.is_empty() else "","hitboxes":p._current_move.get("hitboxes",[]),"form":p.get_current_form_id()}
					check(pair.candidate.hitboxes==pair.historical.hitboxes,fid+":same_authoritative_geometry")
					rows.append(pair);write(false)
	p.remove_meta("base_aura_single_pass_candidate");release();write(true);quit(0 if failures.is_empty() else 1)
