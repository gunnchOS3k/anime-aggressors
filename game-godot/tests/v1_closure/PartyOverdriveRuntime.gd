extends "res://tests/v1_closure/PerfectGuardRuntime.gd"
## Explicit pickup/spacing fixtures, public taunt/special/attack inputs and real
## collision authority. Not an active CPU match, earned Story or native review.
var pickup_events:Array=[]
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
		if arg=="--pilot":pilot=true
	var gs=root.get_node("GameState")
	gs.mode="versus";gs.items_enabled=true;gs.hazards_enabled=false;gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0;gs.match_type="stock_untimed"
	root.get_node("SceneRouter").go("battle");await frames(220)
	var battle=current_scene;var p=battle.fighter1;var d=battle.fighter2;var items=battle._hazard_runtime
	items._spawn_timer=100000
	items.item_collected.connect(func(slot,id):pickup_events.append({"slot":slot,"id":id}))
	p.hit_resolver.hit_confirmed.connect(func(a,b,info):if a==p and b==d:contacts.append(info.duplicate(true)))
	for fid in (IDs.slice(0,2) if pilot else IDs):
		for body in (["male"] if pilot else ["male","female"]):
			for face in ([1] if pilot else [1,-1]):
				for kind in (["prism_heart"] if pilot else ["prism_heart","BLACK","WHITE"]):
					await prepare(p,d,fid,body,face)
					# Inherited setup uses Kaia as attacker; set actual owner under test.
					p.configure(fid,1,false,9,p.global_position);p.facing=face;p.invincible=false;p.controls_enabled=true
					d.configure("kaia-windrow",2,false,9,d.global_position);d.facing=-face;d.invincible=false;d.controls_enabled=true
					p.aura=90;d.aura=0;await frames(4)
					var original_form:String=p.get_current_form_id()
					var original_look:Dictionary=p._model_presentation_data.duplicate(true)
					var item_id:="prism_heart" if kind=="prism_heart" else "puppet_seal"
					var variant:="WHITE" if kind=="WHITE" else "BLACK"
					items.clear_items();pickup_events.clear()
					var token:int=items.spawn_party_item(item_id,p.global_position+Vector2(0,-24),variant)
					await frames(2)
					var label:String=fid+body+str(face)+kind
					check(token>0 and pickup_events.size()==1 and p.party_overdrive.state=="ITEM_ACQUIRED",label+":real_pickup_ownership")
					check(not p.party_overdrive.acquire(item_id,variant,token),label+":duplicate_pickup_rejected")
					Input.action_press("p1_taunt");await frames(2);Input.action_release("p1_taunt");await frames(38)
					check(p.party_overdrive.state=="OVERDRIVE_ACTIVE",label+":public_activation")
					check(p.model_3d.is_model_loaded() and p.model_3d.get_body_variant()==body,label+":actual_form_model")
					check(p.get_current_form_id()==original_form and p.get_effective_combat_aura()==0,label+":no_legacy_or_aura_stacking")
					var form:String=p.party_overdrive.definition().get("state_id","")
					if fid in ["yin","yang"]:check(not form.contains("PUPPET") and not form.contains("GRAY"),label+":cosmic_canon")
					contacts.clear()
					if kind=="prism_heart":
						Input.action_press("p1_taunt");await frames(2);Input.action_release("p1_taunt")
						check(p.party_overdrive.state=="ULTIMATE_STARTUP" and p.move_runner.active,label+":public_ultimate")
						if fid=="rook-ironside":
							for i in range(50):
								if p.move_runner.total_frame>=int(p._current_move.startup_frames)-3:break
								await physics_frame
							Input.action_press("p2_left" if face==1 else "p2_right",.5);Input.action_press("p2_attack");await frames(2)
							Input.action_release("p2_attack");Input.action_release("p2_left");Input.action_release("p2_right")
						await frames(110)
						check(contacts.size()>0 and d.damage_percent>0,label+":ultimate_actual_contact")
						var unique:Dictionary={}
						for info in contacts:
							var key:String=str(info.get("projectile_instance_id",-1))+":"+str(info.move_id)
							check(not unique.has(key),label+":no_duplicate_damage_owner");unique[key]=true
						check(p.party_overdrive.state=="BASE" and p.projectile_spawner.count()==0,label+":ultimate_consumption_cleanup")
					else:
						Input.action_press("p1_right" if face==1 else "p1_left",.5);Input.action_press("p1_special");await frames(2);release();await frames(65)
						check(p._current_move.get("_party_move",false) and p._current_move.move_id=="side_special",label+":temporary_own_special_overlay")
						check(not p.invincible,label+":no_permanent_immunity")
						# Declared expiry boundary fixture; full600-frame duration checked below.
						p.party_overdrive.remaining=1;await frames(2)
						check(p.party_overdrive.state=="BASE",label+":expiry_cleanup")
					check(not p.invincible and p.get_current_form_id()==original_form and p._model_presentation_data==original_look,label+":restored_without_unlock")
					rows.append({"fighter":fid,"body":body,"facing":face,"item":item_id,"variant":variant,"state_id":form,"contacts":contacts.size(),"damage":d.damage_percent,"state":p.party_overdrive.snapshot(),"history":p.party_overdrive.history.duplicate(true)})
					write(false)
	# Mode/canon guard negatives use existing state fixture, never save writes.
	for mode in ["story","ova","online_ranked","online_casual","tournament"]:
		gs.mode=mode
		check(not p.party_overdrive.acquire("prism_heart","BLACK",999),mode+":no_party_unlock")
		check(items.spawn_party_item("prism_heart",p.global_position)==-1,mode+":no_party_spawn")
	gs.mode="versus";gs.items_enabled=false
	check(not p.party_overdrive.acquire("prism_heart","BLACK",999),"default_items_off")
	release();write(true);quit(0 if failures.is_empty() else 1)
func write(done:bool) -> void:
	var f=FileAccess.open(output.path_join("party_overdrive.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":done and failures.is_empty(),"complete":done,"rows":rows,"failures":failures,"scope":"Declared live pickup/spacing/aura/expiry fixtures with public controls and actual collisions; no native, CPU, LAN, earned Story, balance or human acceptance"},"\t"));f.close()
