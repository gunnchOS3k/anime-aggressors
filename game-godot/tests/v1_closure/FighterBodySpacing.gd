extends SceneTree
## Explicit geometry/state prerequisites plus real public walk/attack controls.
## No fixture result is human quality, earned Story or combo acceptance.
const Solver=preload("res://scripts/combat/fighter_body_spacing.gd")
var output:=""
var failures:Array=[]
var rows:Array=[]
var p
var d
var battle
var contacts:Array=[]
var body_filter:=""
func _init()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	if not ok:failures.append(label);push_error(label)
func frames(n:int)->void:
	for i in range(n):await physics_frame
func release()->void:
	for slot in [1,2]:
		for action in ["left","right","attack","special","shield","jump","dodge","grab"]:Input.action_release("p%d_%s"%[slot,action])
func rect(actor)->Rect2:return actor.hit_resolver._world_bounds(actor.get_node("CollisionShape2D"))
func gap(a,b)->float:
	var x:=rect(a);var y:=rect(b)
	return maxf(x.position.x-y.end.x,y.position.x-x.end.x)
func save_output(complete:bool)->void:
	if output.is_empty():return
	var f=FileAccess.open(output.path_join("fighter_body_spacing.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":complete and failures.is_empty(),"complete":complete,"rows":rows,"failures":failures,"scope":"shared full-roster actual body shape/public movement and shield fixtures, explicit boundary/state/Story setup; not human/earned campaign acceptance"}));f.close()
func run()->void:
	create_timer(120).timeout.connect(func():save_output(false);quit(2))
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
		if arg.begins_with("--spacing-body="):body_filter=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=1800
	root.get_node("SceneRouter").go("battle");await frames(220)
	battle=current_scene;p=battle.fighter1;d=battle.fighter2
	p.hit_resolver.hit_confirmed.connect(func(a,b,info):contacts.append(info.duplicate(true)))
	for fid in preload("res://scripts/visual/spectral_feedback_renderer.gd").IDS:
		for body in ([body_filter] if body_filter in ["male","female"] else ["male","female"]):
			for direction in [1,-1]:
				release();gs.p1_body_variant=body;gs.p2_body_variant=body
				p.configure(fid,1,false,9,Vector2(-80*direction,240));d.configure("juno-spark" if fid!="juno-spark" else "kaia-windrow",2,false,9,Vector2(80*direction,240))
				# configure loads assets/stats; it does not reposition/reset an
				# existing actor. These are explicit geometry prerequisites.
				reset_pair();p.position=Vector2(-80*direction,240);d.position=Vector2(80*direction,240)
				battle._battle_sim.body_spacing.previous_order.clear()
				await frames(35)
				var dimensions:Vector2=rect(p).size;var hurt:Vector2=p.get_node("Hurtbox/HurtShape").shape.size
				var floor_y:Vector2=Vector2(p.position.y,d.position.y);var manifest:=JSON.stringify(p.move_manifest)
				Input.action_press("p1_"+("right" if direction==1 else "left"),.55);Input.action_press("p2_"+("left" if direction==1 else "right"),.55)
				var gaps:Array=[]
				for i in range(75):
					await physics_frame
					check(p.is_on_floor() and d.is_on_floor(),fid+body+str(direction)+":floor")
					check(gap(p,d)>=-.001,fid+body+str(direction)+":no_body_overlap")
					check((d.position.x-p.position.x)*direction>0,fid+body+str(direction)+":no_unintended_side_switch")
					if i>55:gaps.append(gap(p,d))
				release();await frames(12)
				check(gaps.max()-gaps.min()<.001 and absf(gaps.max())<.001,fid+body+str(direction)+":stable_exact_shape_contact")
				check(absf(p.position.y-floor_y.x)<.001 and absf(d.position.y-floor_y.y)<.001,fid+":no_vertical_displacement")
				check(rect(p).size==dimensions and p.get_node("Hurtbox/HurtShape").shape.size==hurt and JSON.stringify(p.move_manifest)==manifest,fid+":geometry_and_move_values_preserved")
				check(p.collision_layer==2 and p.collision_mask==1,fid+":stage_only_physics_mask")
				contacts.clear();Input.action_press("p2_shield");await frames(3);Input.action_press("p1_attack");await frames(1);Input.action_release("p1_attack");await frames(35)
				check(contacts.size()==1 and contacts[0].contact_result in ["shield","armor"],fid+body+str(direction)+":one_real_defensive_contact")
				release();await frames(10)
				rows.append({"fighter":fid,"body":body,"direction":direction,"body_widths":[rect(p).size.x,rect(d).size.x],"root_separation":absf(p.position.x-d.position.x),"contact_gap_range":[gaps.min(),gaps.max()],"model_paths":[p.model_3d._proxy_model.scene_file_path,d.model_3d._proxy_model.scene_file_path]})
				save_output(false)
	release();await frames(20)
	await boundary_and_exceptions()
	await multi_actor_story()
	save_output(true)
	print("FIGHTER_BODY_SPACING ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size()," failures=",failures.size());quit(0 if failures.is_empty() else 1)

func reset_pair()->void:
	for actor in [p,d]:
		actor.move_runner.cancel();actor.grabbed_target=null;actor.grabbed_by=null;actor.invincible=false;actor.phase_cancel_remaining=0;actor.velocity=Vector2.ZERO;actor._hitstop=0;actor.state_machine.enter("idle");actor.controls_enabled=true
	p.position.x=-10;d.position.x=10

func boundary_and_exceptions()->void:
	reset_pair();var y:=Vector2(p.position.y,d.position.y)
	var a=Solver.new();a.resolve([p,d]);var expected:=Vector2(p.position.x,d.position.x)
	reset_pair();var b=Solver.new();b.resolve([d,p])
	check(Vector2(p.position.x,d.position.x).distance_to(expected)<.00001,"input_array_order_independent")
	check(Vector2(p.position.y,d.position.y)==y and p.velocity==Vector2.ZERO and d.velocity==Vector2.ZERO,"solver_changes_no_y_or_velocity")
	for state in Solver.FREE_CROSSING:
		reset_pair();p.state_machine.enter(state);var before:=Vector2(p.position.x,d.position.x);Solver.new().resolve([p,d]);check(before==Vector2(p.position.x,d.position.x),"crossing_exception_"+state)
	reset_pair();p.invincible=true;Solver.new().resolve([p,d]);check(p.position.x==-10 and d.position.x==10,"invulnerability_exception")
	reset_pair();p.set_meta("story_team","ally");d.set_meta("story_team","ally");Solver.new().resolve([p,d]);check(p.position.x==-10 and d.position.x==10,"same_story_team_crossing");p.remove_meta("story_team");d.remove_meta("story_team")
	reset_pair();p.set_meta("story_cosmic_contract",true);Solver.new().resolve([p,d]);check(p.position.x==-10 and d.position.x==10,"cosmic_staging_exception");p.remove_meta("story_cosmic_contract")
	reset_pair();d.position.y-=100;Solver.new().resolve([p,d]);check(p.position.x==-10 and d.position.x==10,"different_floor_plane");d.position.y=y.y
	reset_pair();var edge:float=d.platform_center_x+d.platform_half_width
	d.position.x=edge-.1;p.position.x=d.position.x-10;var solver=Solver.new()
	for i in range(12):solver.resolve([p,d])
	check(d.position.x<=edge+.0001 and gap(p,d)>=-.001,"push_does_not_force_stage_edge_exit")
	var wall:=StaticBody2D.new();wall.collision_layer=1;wall.collision_mask=2
	var cs:=CollisionShape2D.new();var shape:=RectangleShape2D.new();shape.size=Vector2(20,120);cs.shape=shape;wall.add_child(cs);battle.stage_root.add_child(wall);wall.position=Vector2(160,rect(d).end.y-60)
	await frames(1);reset_pair();d.position.x=150-rect(d).size.x*.5;p.position.x=d.position.x-10;solver=Solver.new()
	for i in range(12):solver.resolve([d,p])
	check(rect(d).end.x<=150+.001 and gap(p,d)>=-.001,"stage_wall_clips_push")
	wall.queue_free();reset_pair();await frames(10)

func multi_actor_story()->void:
	# Instantiate the real puppet objective in this isolated fixture. Never
	# begin/finish a campaign encounter or issue an authenticated receipt.
	var campaign=root.get_node("CampaignRuntime");var node:Dictionary={}
	for chapter in campaign.route_data("kaia-windrow").nodes:
		if chapter.get("objective_contract","")=="PUPPET_IMBALANCE":node=chapter;break
	check(not node.is_empty(),"story_puppet_fixture_exists")
	var saved:=JSON.stringify(campaign.progress)
	var objective=load("res://scripts/story/v1_story_encounter.gd").new()
	objective.setup(battle,{"node":node,"route_state":campaign.progress.routes["kaia-windrow"]})
	objective.activate_controls();await frames(80)
	check(objective.actors.size()>2 and battle._battle_sim.fighters.size()==objective.actors.size(),"real_multi_actor_story_binding")
	var active_cpu:=0
	for actor in objective.actors:
		if actor!=p and actor.is_cpu and actor.controls_enabled:active_cpu+=1
	check(active_cpu>1,"story_multi_actor_cpu_preserved")
	# Adversarial array order must not change one simultaneous crowd solve.
	var original:Dictionary={}
	for actor in objective.actors:original[actor]=actor.global_position
	var list:Array=objective.actors.duplicate();Solver.new().resolve(list);var result:Dictionary={}
	for actor in list:result[actor]=actor.global_position;actor.global_position=original[actor]
	list.reverse();Solver.new().resolve(list)
	for actor in list:check(actor.global_position.distance_to(result[actor])<.0001,"story_crowd_order_"+str(actor.slot))
	check(JSON.stringify(campaign.progress)==saved and campaign.active_encounter.is_empty(),"story_fixture_mints_no_progress_or_receipt")
	rows.append({"case":"multi_actor_story","objective":objective.kind,"actors":objective.actors.size(),"active_cpu":active_cpu,"earned_progress":false})
	objective.battle=null
