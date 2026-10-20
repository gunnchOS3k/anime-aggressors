extends "res://tests/v1_closure/OrdinaryMeleeReview.gd"
## Ordinary local inputs, including intentional crossing. No seeded transforms,
## damage, invulnerability or outcomes. Diagnostic geometry is never displayed.
var spacing_samples:Array=[]
var grabs:Array=[]

func wait(count:int)->void:
	for i in range(count):
		if battle!=null:
			var actors:Array=[]
			for actor in [p,d]:
				var bounds:Rect2=actor.hit_resolver._world_bounds(actor.get_node("CollisionShape2D"))
				actors.append({"slot":actor.slot,"root":[actor.position.x,actor.position.y],"body_bounds":[bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y],"grounded":actor.is_on_floor(),"state":actor.state_machine.current_state,"invincible":actor.invincible,"grabbed":actor.grabbed_by!=null,"velocity":[actor.velocity.x,actor.velocity.y]})
			var sim=battle._battle_sim
			var entry:Dictionary={"physics_frame":Engine.get_physics_frames(),"process_frame":Engine.get_process_frames(),"case":label,"actors":actors,"root_separation_px":absf(p.position.x-d.position.x),"pushbox":sim.body_spacing.last.duplicate(true) if "body_spacing" in sim else {"implemented":false}}
			if review_frames%15==0:entry["head_overlap_px2"]=head_overlap()
			spacing_samples.append(entry)
		await super.wait(1)

func write_evidence(final:bool)->void:
	super.write_evidence(final)
	var f=FileAccess.open(output.path_join("fighter_spacing.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"complete":final,"scope":"ordinary two-controller inputs, no frozen target/seeded position/damage; actual body dimensions, root positions and sampled Head skin convex hulls","samples":spacing_samples,"grabs":grabs,"hits":hits}));f.close()

func _run()->void:
	create_timer(120).timeout.connect(func():push_error("spacing review watchdog");quit(2))
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState")
	gs.mode="versus";gs.stage_id="training-grid";gs.p1_fighter_id="kaia-windrow";gs.p2_fighter_id="juno-spark"
	gs.p1_is_cpu=false;gs.p2_is_cpu=false;gs.stocks=3;gs.match_timer_seconds=180
	gs.p1_body_variant="female";gs.p2_body_variant="male"
	root.get_node("SceneRouter").go("battle");await wait(220)
	battle=current_scene;p=battle.fighter1;d=battle.fighter2
	for actor in [p,d]:mesh_cache[actor.model_3d.get_instance_id()]=cache_meshes(actor.model_3d)
	for actor in [p,d]:
		var other=d if actor==p else p
		actor.combat_feedback.feedback_triggered.connect(func(info):pre_contact(actor,other,info))
		actor.hit_resolver.hit_confirmed.connect(contact)
		actor.grab_event.connect(func(info):grabs.append({"physics_frame":Engine.get_physics_frames(),"slot":actor.slot,"event":info.duplicate(true)}))
	if "--frame-barcode" in OS.get_cmdline_user_args():
		var layer:=CanvasLayer.new();layer.layer=100;battle.add_child(layer)
		for bit in range(20):
			var rect:=ColorRect.new();rect.position=Vector2(20+bit*12,190);rect.size=Vector2(10,24);layer.add_child(rect);bars.append(rect)
	# Exactly the same initial 85-frame walk/settle input stream before/after.
	label="walk into opponent";keys(1,["right"]);keys(2,["left"]);await wait(85)
	keys(1,[]);keys(2,[]);label="grounded close neutral";await wait(30)
	keys(2,["shield"]);await wait(5)
	await strike(1,["attack"],"Kaia light / Juno shield",40)
	keys(2,[]);await wait(10)
	await strike(1,["attack"],"Kaia authored hook",45)
	await strike(2,["attack"],"Juno light",45)
	await strike(1,["attack","special"],"Kaia heavy",60)
	await strike(2,["attack","special"],"Juno heavy",60)
	label="public dodge crossing";keys(1,["dodge"]);await wait(1);keys(1,[]);await wait(20)
	label="public jump crossing";keys(1,["left","jump"]);await wait(20);keys(1,["left"]);await wait(12);keys(1,[]);await wait(35)
	await approach()
	label="public grab";keys(1,["grab"]);await wait(1);keys(1,[]);await wait(20)
	label="public directional throw";keys(1,["right","attack"]);await wait(1);keys(1,[]);await wait(55)
	label="normal movement after contact";keys(1,["left"]);keys(2,["right"]);await wait(12)
	keys(1,[]);keys(2,[]);await wait(12)
	await strike(1,["attack"],"Kaia deliberate whiff",40)
	label="return to neutral";await wait(20)
	write_evidence(true);print("FIGHTER_SPACING_REVIEW_COMPLETE frames=",review_frames," hits=",hits.size()," grabs=",grabs.size());quit()
