extends "res://tests/v1_closure/RosterContactRange.gd"
## Bounded two-controller gameplay. All movement and attacks use public input;
## neither character is frozen, repositioned, seeded or given forced results.
var battle
var held := [[], []]
var inputs: Array = []
var hits: Array = []
var trace: Array = []
var bars: Array = []
var stamps: Array = []
var label := "approach"
var review_frames := 0

func keys(slot: int, actions: Array) -> void:
	if held[slot-1] == actions: return
	inputs.append({"frame":Engine.get_physics_frames(),"slot":slot,"actions":actions.duplicate()})
	for key in held[slot-1]:
		if key not in actions: Input.action_release("p%d_%s" % [slot,key])
	for key in actions:
		if key not in held[slot-1]: Input.action_press("p%d_%s" % [slot,key],.55 if key in ["left","right"] else 1.0)
	held[slot-1] = actions.duplicate()

func polygon_area(poly: PackedVector2Array) -> float:
	var area := 0.0
	for i in range(poly.size()): area += poly[i].cross(poly[(i+1)%poly.size()])
	return absf(area)*.5

func head_overlap() -> float:
	var area := 0.0
	for poly in Geometry2D.intersect_polygons(projected_surface(p.model_3d,"Head"),projected_surface(d.model_3d,"Head")):
		area += polygon_area(poly)
	return area

func posture(actor) -> Dictionary:
	var c=actor.model_3d.get_animation_controller()
	return c._strike_posture.last.duplicate(true) if "_strike_posture" in c else {"admitted":false,"reason":"baseline"}

func pre_contact(actor,other,info: Dictionary) -> void:
	pre_reaction_body[str(info.combat_event_id)]={"head_overlap_px2":head_overlap(),"attacker_posture":posture(actor),"defender_posture":posture(other)}

func contact(actor,other,info: Dictionary) -> void:
	var c=actor.model_3d.get_animation_controller()
	var row:Dictionary={"case":label,"event_id":info.combat_event_id,"physics_frame":Engine.get_physics_frames(),"process_frame":Engine.get_process_frames(),"attacker_slot":actor.slot,"defender_slot":other.slot,"move":info.move_id,"result":info.contact_result,"damage":info.damage,"owner":info.contact_owner,"world":[info.contact_world.x,info.contact_world.y],"runtime_frame":actor.move_runner.total_frame,"animation_time_s":c.get_animation_player().current_animation_position,"defender_state":other.state_machine.current_state,"defender_hitstun_s":other.hitstun_remaining,"defender_velocity":[other.velocity.x,other.velocity.y],"damage_after":[p.damage_percent,d.damage_percent]}
	row.merge(pre_reaction_body.get(str(info.combat_event_id),{}));hits.append(row)

func wait(count: int) -> void:
	for i in range(count):
		review_frames += 1
		if battle != null:
			var observed:=Engine.get_process_frames()-1
			if not bars.is_empty():
				for bit in range(20): bars[bit].color=Color.WHITE if observed & (1<<bit) else Color.BLACK
				stamps.append({"trace_frame":observed,"physics_frame":Engine.get_physics_frames()})
			var states:Array=[]
			for actor in [p,d]:
				states.append({"slot":actor.slot,"position":[actor.position.x,actor.position.y],"velocity":[actor.velocity.x,actor.velocity.y],"facing":actor.facing,"state":actor.state_machine.current_state,"move":actor.move_runner.move_data.get("move_id",""),"move_frame":actor.move_runner.total_frame,"damage":actor.damage_percent,"grounded":actor.is_on_floor(),"hitstun_s":actor.hitstun_remaining,"can_attack":actor.state_machine.can_attack(),"posture":posture(actor)})
			trace.append({"physics_frame":Engine.get_physics_frames(),"process_frame":Engine.get_process_frames(),"case":label,"actors":states})
			if review_frames%30==0: write_evidence(false)
		await physics_frame

func approach() -> void:
	label="public approach"
	for i in range(90):
		if absf(d.position.x-p.position.x)<=70: break
		keys(1,["right" if d.position.x>p.position.x else "left"])
		keys(2,["left" if d.position.x>p.position.x else "right"])
		await wait(1)
	keys(1,[]);keys(2,[]);await wait(12)

func strike(slot: int, actions: Array, case_name: String, settle: int) -> void:
	label=case_name;keys(slot,actions);await wait(1);keys(slot,[]);await wait(settle)

func write_evidence(final: bool) -> void:
	var f=FileAccess.open(output.path_join("ordinary_melee.json"),FileAccess.WRITE)
	var effects=battle.get_node("SpectralFeedback").history
	f.store_string(JSON.stringify({"complete":final,"scope":"two ordinary automated public-input controllers; real movement/hit/shield/whiff, no CPU/human taste acceptance, no forced state/damage/position","frames":review_frames,"hits":hits,"inputs":inputs,"trace":trace,"frame_stamps":stamps,"presentation_history":effects,"controls_enabled":[p.controls_enabled,d.controls_enabled],"model_paths":[p.model_3d._proxy_model.scene_file_path,d.model_3d._proxy_model.scene_file_path]},"  "));f.close()

func _run() -> void:
	create_timer(120).timeout.connect(func():push_error("ordinary melee watchdog");quit(2))
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
	if "--frame-barcode" in OS.get_cmdline_user_args():
		var layer:=CanvasLayer.new();layer.layer=100;battle.add_child(layer)
		for bit in range(20):
			var rect:=ColorRect.new();rect.position=Vector2(20+bit*12,190);rect.size=Vector2(10,24);layer.add_child(rect);bars.append(rect)
	await approach()
	keys(2,["shield"]);await wait(5)
	await strike(1,["attack"],"Kaia light / Juno shield",40)
	keys(2,[]);await wait(10)
	await strike(1,["attack"],"Kaia light",50)
	await approach();await strike(2,["attack"],"Juno light",50)
	await approach();await strike(1,["attack","special"],"Kaia heavy",70)
	await approach();await strike(2,["attack","special"],"Juno heavy",70)
	label="public retreat";keys(1,["left"]);keys(2,["right"]);await wait(12)
	keys(1,[]);keys(2,[]);await wait(12)
	await strike(1,["attack"],"Kaia deliberate whiff",45)
	keys(1,[]);keys(2,[]);label="return to neutral";await wait(30)
	write_evidence(true)
	print("ORDINARY_MELEE_COMPLETE contacts=",hits.size()," frames=",review_frames)
	quit()
