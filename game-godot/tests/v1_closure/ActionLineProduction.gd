extends SceneTree
## Public whiff/rig sampling, followed by declared collision-authority fixtures.
## Idle defender. Not CPU, combo, KO or artistic acceptance evidence.
const Renderer=preload("res://scripts/visual/spectral_feedback_renderer.gd")
var output := ""
var failures: Array=[]
var rows: Array=[]
func _init() -> void:call_deferred("_run")
func check(ok: bool,label: String) -> void:
	if not ok:failures.append(label)
func count(renderer,kind: int) -> int:
	return renderer.history.filter(func(row):return row.kind==kind).size()
func _run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=1800
	root.get_node("SceneRouter").go("battle")
	for i in range(200):await physics_frame
	var p=current_scene.fighter1;var d=current_scene.fighter2;d.controls_enabled=false;d.position=Vector2(300,240)
	var renderer=Renderer.obtain(p)
	for fid in Renderer.IDS:
		for body in ["male","female"]:
			gs.p1_body_variant=body;p.configure(fid,1,false,9,Vector2(-200,240));p.move_runner.cancel();p.state_machine.enter("idle");p.controls_enabled=true;p.invincible=false;p.clear_aura();p.velocity=Vector2.ZERO;p._hitstop=0
			for i in range(40):await physics_frame
			var label: String=fid+":"+body
			var lines=p.get_node("CombatExpressionDirector").action_lines
			var before_confirmed:=count(renderer,16)
			var before_primary:=count(renderer,0)
			var before_start: int=lines.emitted.anticipation;var before_smear: int=lines.emitted.limb_smear
			Input.action_press("p1_attack");await physics_frame;await physics_frame;Input.action_release("p1_attack")
			for i in range(48):await physics_frame
			check(count(renderer,16)==before_confirmed and count(renderer,0)==before_primary,label+":whiff_has_no_confirmed_expression")
			check(lines.emitted.anticipation>before_start,label+":resolved_startup_anticipation")
			check(lines.emitted.limb_smear>before_smear,label+":actual_authored_limb_path")
			for item in lines.history:
				if item.fighter_id==fid and item.kind=="limb_smear":check(item.phase=="active",label+":smear_uses_active_runner_phase")
			# Explicit fixture to distinguish confirmed hit/light/shield/dedup.
			p.controls_enabled=false;p.training_play_move("heavy_attack");d.invincible=false;d.shielding=false;d.damage_percent=0;d.state_machine.enter("idle");d._hitstop=0
			var info: Dictionary=p.hit_resolver.resolve(p,d,p._current_move,0)
			check(not info.is_empty() and count(renderer,16)==before_confirmed+1,label+":confirmed_heavy_expression_once")
			var after_contact:=count(renderer,16);renderer.contact(info,d)
			check(count(renderer,16)==after_contact,label+":event_id_dedup")
			d.shielding=true;d.state_machine.enter("shield_hold");p.training_play_move("heavy_attack")
			var shield: Dictionary=p.hit_resolver.resolve(p,d,p._current_move,0)
			check(shield.get("contact_result","")=="shield" and count(renderer,16)==after_contact,label+":shield_has_no_body_hit_expression")
			d.shielding=false;p.move_runner.cancel();p.state_machine.enter("idle")
			rows.append({"fighter":fid,"body":body,"expression":lines.evidence(),"confirmed_contact":info,"shield":shield.get("contact_result","")})
	var f=FileAccess.open(output.path_join("action_line_production.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"rows":rows,"pool":renderer.stats(),"scope":"18public whiffs and declared direct contact fixtures; no CPU/combo/art approval"},"  "));f.close()
	print("ACTION_LINE_PRODUCTION ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size()," failures=",failures.size());quit(0 if failures.is_empty() else 1)
