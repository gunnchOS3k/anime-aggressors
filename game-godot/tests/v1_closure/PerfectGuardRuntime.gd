extends SceneTree
const IDs=preload("res://scripts/visual/spectral_feedback_renderer.gd").IDS
var output:=""
var pilot:=false
var rows:Array=[]
var failures:Array=[]
var contacts:Array=[]
func _init() -> void:call_deferred("run")
func frames(n:int) -> void:
	for i in range(n):await physics_frame
func check(ok:bool,label:String) -> void:
	if not ok:failures.append(label);push_error(label)
func release() -> void:
	for slot in [1,2]:
		for key in ["left","right","attack","special","shield","grab"]:Input.action_release("p%d_%s"%[slot,key])
func write(done:bool) -> void:
	var f=FileAccess.open(output.path_join("perfect_guard.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":done and failures.is_empty(),"complete":done,"rows":rows,"failures":failures,"scope":"Controlled live BattleScene public inputs; idle opponent; tuning candidate; no native/CPU/device/human acceptance"},"\t"));f.close()
func prepare(p,d,fid:String,body:String,face:int) -> void:
	release();var gs=root.get_node("GameState");gs.p1_body_variant=body;gs.p2_body_variant=body
	p.configure("kaia-windrow",1,false,9,Vector2(-40,240));d.configure(fid,2,false,9,Vector2(-40+48*face,240))
	p.global_position=Vector2(-40,240);d.global_position=Vector2(-40+48*face,240)
	for a in [p,d]:
		a.move_runner.cancel();a.projectile_spawner.clear_all();a.state_machine.enter("idle");a.controls_enabled=true;a.invincible=false
		a.aura=0;a.damage_percent=0;a.velocity=Vector2.ZERO;a._hitstop=0;a.shielding=false;a.armor_frames_remaining=0
		a._input_edge_held.clear();a._recent_move_ids.clear();a.combo_count=0
	p.facing=face;d.facing=-face;current_scene._battle_sim.body_spacing.previous_order.clear()
	for i in range(90):
		await physics_frame
		if p.is_on_floor() and d.is_on_floor() and p.state_machine.can_attack() and d.state_machine.can_attack():break
	contacts.clear()
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
		if arg=="--pilot":pilot=true
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0;gs.match_type="stock_untimed"
	root.get_node("SceneRouter").go("battle");await frames(220)
	var p=current_scene.fighter1;var d=current_scene.fighter2
	p.hit_resolver.hit_confirmed.connect(func(a,b,info):if a==p and b==d:var record:Dictionary=info.duplicate(true);record["shield_at_contact"]=d.shield_health;contacts.append(record))
	for fid in (IDs.slice(0,1) if pilot else IDs):
		for body in (["male"] if pilot else ["male","female"]):
			for face in ([1] if pilot else [1,-1]):
				for timing in (["success"] if pilot else ["success","early","late"]):
					await prepare(p,d,fid,body,face)
					if timing=="early":Input.action_press("p2_shield");await frames(12)
					Input.action_press("p1_right" if face==1 else "p1_left",.5);Input.action_press("p1_attack");await frames(2)
					Input.action_release("p1_attack");Input.action_release("p1_right");Input.action_release("p1_left")
					if timing=="success":
						for i in range(40):
							if p.move_runner.active and p.move_runner.total_frame>=int(p._current_move.startup_frames)-1:break
							await physics_frame
						Input.action_press("p2_shield")
					await frames(35)
					var label=fid+body+str(face)+timing
					check(contacts.size()==1,label+":one_contact")
					if contacts.size()==1:
						var hit:Dictionary=contacts[0]
						check(bool(hit.get("perfect_guard",false))==(timing=="success"),label+":classification")
						check(not d.invincible,label+":no_invulnerability")
						if timing=="success":check(d.damage_percent==0 and float(hit.shield_at_contact)>float(d.data.get("shieldProfile",{}).get("maxHealth",100))-1.0 and hit.get("contact_result")=="parry" and hit.get("played_audio",{}).get("ok",false),label+":zero_damage_and_distinct_feedback")
						if timing=="early":check(hit.blocked and not hit.get("perfect_guard",false),label+":ordinary_shield")
						if timing=="late":check(d.damage_percent>0,label+":late_is_body_hit")
						rows.append({"fighter":fid,"body":body,"facing":face,"timing":timing,"result":hit.contact_result,"guard_age":hit.get("guard_age_frames",-1),"damage":d.damage_percent,"audio":hit.get("played_audio",{}),"shield_at_contact":hit.get("shield_at_contact",0),"window":d.perfect_guard.snapshot()})
					write(false)
	# Controlled resolver boundary fixtures, separate from the real contacts above.
	await prepare(p,d,"kaia-windrow","male",1)
	d.shielding=true
	for age in range(6):
		d.perfect_guard.reset();check(d.perfect_guard.begin(),"fresh_guard_attempt")
		d.perfect_guard.clock=d.perfect_guard.opened+age
		var boundary:Dictionary=d.perfect_guard.try_contact(p,{"move_id":"forward_tilt","move_type":"melee"})
		check((not boundary.is_empty())==(age<4),"exact_four_frame_boundary:"+str(age))
		check(not d.perfect_guard.begin(),"no_rearm_during_cooldown")
		d.perfect_guard.clock+=24
		check(d.perfect_guard.begin(),"rearm_after_cooldown")
	release();write(true);quit(0 if failures.is_empty() else 1)
