extends SceneTree
const Sound = preload("res://scripts/audio/elemental_performance.gd")
const Model = preload("res://scripts/fighters/fighter_model_3d.gd")
const Data = preload("res://scripts/data/data_loader.gd")
var failures: Array=[]
var rows: Array=[]
var confirmed_audio: Array=[]
func _init() -> void:call_deferred("_run")
func check(ok: bool,label: String) -> void:
	if not ok:failures.append(label);push_error(label)
func _run() -> void:
	await process_frame
	var state=root.get_node("GameState")
	state.mode="versus";state.battle_eval_mode=true;state.battle_eval_max_frames=100000
	state.p1_fighter_id="ember-vale";state.p2_fighter_id="juno-spark";state.stocks=9
	root.get_node("SceneRouter").go("battle")
	for i in range(10):await physics_frame
	var p=current_scene.fighter1;p.controls_enabled=false;current_scene.fighter2.controls_enabled=false
	for fid in ["ember-vale","juno-spark","rook-ironside","kaia-windrow","nix-calder","orion-vell","vesper-nyx","yin","yang"]:
		for event in ["charge_start","charge_loop","charge_ready","charge_release","charge_cancel","projectile_launch","projectile_travel","projectile_impact","projectile_dissipate","heavy","signature","signature_release","block"]:
			var result = Sound.one_shot(fid,event,root,.2)
			check(result.get("playing",false) and result.path.contains(fid),"required_event_live:"+fid+":"+event)
		p.configure(fid,1,false,9,Vector2(-100,180))
		if p._elemental_audio != null: p._elemental_audio.events.clear()
		p.state_machine.enter("aura_charge");p._set_aura_vfx(true)
		var sound=p._elemental_audio
		for i in range(10):sound.update_charge(true,.5)
		check(sound.events.filter(func(row):return row.event=="charge_start").size()==1,"one_charge_start:"+fid)
		check(sound.charge!=null and sound.charge.playing,"charge_plays:"+fid)
		sound.update_charge(true,1);sound.update_charge(true,1)
		check(sound.events.filter(func(row):return row.event=="charge_ready").size()==1,"one_ready:"+fid)
		p.state_machine.enter("hitstun")
		check(sound.charge==null and sound.events.back().event=="charge_cancel","interrupt_stops:"+fid)
		p.state_machine.enter("idle")
		p.training_play_move("neutral_special_projectile")
		for i in range(60):await physics_frame
		var projectiles=p.projectile_spawner.get("_projectiles")
		# Launch path is observed through the actual projectile nodes.
		var found:=false
		for node in current_scene.find_children("*","AAProjectile",true,false):
			if node.fighter_id==fid and node._elemental_audio!=null:
				found=true;check(node._elemental_audio.travel!=null and node._elemental_audio.travel.playing,"travel_plays:"+fid)
		check(found,"real_launch:"+fid)
		p.projectile_spawner.clear_all();p.move_runner.cancel()
		p.state_machine.enter("idle")
		p.training_play_move("aura_burst")
		for i in range(60):await physics_frame
		check(sound.events.filter(func(row):return row.event=="signature_release" and row.playing).size()==1,"real_signature_release_once:"+fid)
		p.move_runner.cancel()
		var target=current_scene.fighter2
		var feedback: Array=[]
		var observer=func(info: Dictionary):feedback.append(info)
		p.combat_feedback.feedback_triggered.connect(observer)
		# Declared contact fixtures exercise the live HitResolver -> feedback -> bank.
		# These are not natural-input gameplay or qualifying Story evidence.
		for spec in [{"move":"heavy_attack","event":"heavy","blocked":false},{"move":"aura_burst","event":"signature","blocked":false},{"move":"heavy_attack","event":"block","blocked":true}]:
			target.configure("ember-vale" if fid=="juno-spark" else "juno-spark",2,false,9,Vector2(100,180))
			target.controls_enabled=false;target.invincible=false;target.shielding=spec.blocked
			if spec.blocked:target.state_machine.enter("shield_hold")
			p.move_runner.cancel();p.state_machine.enter("idle");p.training_play_move(spec.move)
			feedback.clear();p.hit_resolver.resolve(p,target,p._current_move,0.0)
			check(feedback.size()==1,"confirmed_contact:"+fid+":"+spec.event)
			if feedback.size()==1:
				var layer: Dictionary=feedback[0].get("elemental_block",{}) if spec.blocked else feedback[0].get("played_audio",{}).get("elemental_layer",{})
				check(layer.get("playing",false) and layer.get("event","")==spec.event and layer.get("fighter_id","")==fid,"confirmed_elemental_playback:"+fid+":"+spec.event)
				if not spec.blocked:check(feedback[0].played_audio.get("playing",false),"original_impact_still_plays:"+fid+":"+spec.event)
				confirmed_audio.append({"fighter_id":fid,"event":spec.event,"playback":layer,"scope":"declared versus contact fixture through live HitResolver"})
		p.combat_feedback.feedback_triggered.disconnect(observer)
		p.move_runner.cancel()
		for presentation in ["male","female"]:
			var model=Model.new();root.add_child(model);model.configure(Data.load_fighter(fid),presentation)
			await process_frame
			var controller=model.get_animation_controller()
			var player=controller.get_animation_player()
			check(player.has_animation_library("authored_studies"),"visible_library:"+fid+":"+presentation)
			# Test the rendered deformation rather than clip-name differences.
			controller.play_for_state("attack_startup",{"move_id":"jab_1"})
			controller.synchronize_move(0,{"move_id":"jab_1"})
			var skeleton=controller.get_skeleton();skeleton.force_update_all_bone_transforms()
			var hand=skeleton.find_bone("Hand_R");var initial=skeleton.get_bone_global_pose(hand).origin
			var spec=JSON.parse_string(FileAccess.get_file_as_string("res://data/animation/authored_studies/%s.json"%fid))
			var frame=int(spec.clips.jab_1.contact_frame)
			controller.synchronize_move(frame,{"move_id":"jab_1"});skeleton.force_update_all_bone_transforms()
			var contact=skeleton.get_bone_global_pose(hand).origin
			check(initial.distance_to(contact)>.03,"visible_hand_travel:"+fid+":"+presentation)
			check(absf(player.current_animation_position-float(frame)/60)<.001,"simulation_frame_alignment:"+fid+":"+presentation)
			rows.append({"fighter_id":fid,"presentation":presentation,"contact_frame":frame,"hand_travel":initial.distance_to(contact),"contact_pose":str(contact),"loop_events":sound.events.duplicate(true),"geometry_to_hitbox_review":"PENDING_RENDERED_OWNER_REVIEW"})
			model.queue_free();await process_frame
	var file=FileAccess.open("res://../artifacts/v1_closure/dialogue_performance/elemental_runtime_test.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"ok":failures.is_empty(),"failures":failures,"rows":rows,"confirmed_audio":confirmed_audio,"scope":"Real Fighter state interruptions and projectile creation; declared HitResolver contact fixtures; real GLB bone deformation and timeline seek. Not natural Story or human acoustic/taste acceptance."},"  ")+"\n");file.close()
	print("ELEMENTAL_PERFORMANCE ",failures.is_empty()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
