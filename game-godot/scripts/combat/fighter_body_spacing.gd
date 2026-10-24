extends RefCounted
## Grounded pushboxes use the existing main body shapes, never hurt/attack boxes
## or projected art. One deterministic, horizontal-only post-movement pass.
const States = preload("res://scripts/fighters/fighter_states.gd")
const FREE_CROSSING := [States.DODGE_START,States.DODGE_ACTIVE,States.DODGE_RECOVERY,States.AIR_DODGE,
	States.GRAB_HOLD,States.THROW_STARTUP,States.THROW_RELEASE,States.LEDGE_HANG,States.LEDGE_GETUP,
	States.HURT_LIGHT,States.HURT_HEAVY,States.HITSTUN,States.LAUNCHED,States.TUMBLE,
	States.KO,States.RESPAWN,States.VICTORY,States.DEFEAT]
var previous_order:Dictionary={}
var last:Dictionary={}

func eligible(actor)->bool:
	if not is_instance_valid(actor) or not actor is CharacterBody2D or not actor.has_method("tick_combat_frame"):return false
	if actor.stocks<=0 or not actor.controls_enabled or not actor.is_physics_processing():return false
	if not actor.is_on_floor() or actor.velocity.y<0 or actor.invincible:return false
	if actor.grabbed_by!=null or actor.grabbed_target!=null:return false
	if actor.state_machine.current_state in FREE_CROSSING:return false
	if actor.phase_cancel_remaining>0:return false
	if actor.get_meta("story_cosmic_contract",false) or actor.get_meta("story_released",false):return false
	# Authored locomoting attacks retain their existing crossing/trajectory.
	if actor.move_runner.active and float(actor.move_runner.move_data.get("self_movement",{}).get("x",0))!=0:return false
	var shape=actor.get_node_or_null("CollisionShape2D")
	return shape!=null and not shape.disabled and shape.shape!=null

func bounds(actor)->Rect2:
	return actor.hit_resolver._world_bounds(actor.get_node("CollisionShape2D"))

func pair_allowed(a,b)->bool:
	if a.has_meta("story_team") and a.get_meta("story_team")==b.get_meta("story_team",""):return false
	# Separate platforms never become opponent-platforms through this solver.
	return absf(bounds(a).end.y-bounds(b).end.y)<=maxf(a.safe_margin,b.safe_margin)*2+.001

func supported(actor,dx:float)->bool:
	var body:=bounds(actor)
	var point:=Vector2(body.get_center().x+dx,body.end.y)
	var query:=PhysicsRayQueryParameters2D.create(point-Vector2(0,1),point+Vector2(0,1),actor.collision_mask)
	var floor_hit:Dictionary=actor.get_world_2d().direct_space_state.intersect_ray(query)
	return not floor_hit.is_empty() and floor_hit.normal.dot(Vector2.UP)>.7

func allowed_motion(actor,dx:float)->float:
	if absf(dx)<.00001:return 0.0
	var collision:=KinematicCollision2D.new()
	if actor.test_move(actor.global_transform,Vector2(dx,0),collision,actor.safe_margin):
		# Recovery can report travel opposite to the requested push. Its
		# magnitude is not permission to advance into a wall on the next pass.
		dx=signf(dx)*clampf(collision.get_travel().x*signf(dx),0,absf(dx))
	# A push may not force a grounded center off its supporting stage surface.
	# This does not restrict the player's own movement/launch/dodge off an edge.
	if supported(actor,dx):return dx
	var low:=0.0;var high:=absf(dx)
	for i in range(12):
		var mid:float=(low+high)*.5
		if supported(actor,signf(dx)*mid):low=mid
		else:high=mid
	return signf(dx)*low

func resolve(fighters:Array)->void:
	var started:=Time.get_ticks_usec()
	var live:Array=[]
	for actor in fighters:
		if eligible(actor):live.append(actor)
	live.sort_custom(func(a,b):return a.slot<b.slot if a.slot!=b.slot else str(a.get_path())<str(b.get_path()))
	var pairs:Array=[];var next_order:Dictionary={};var remaining:Dictionary={};var starts:Dictionary={}
	for actor in live:
		# Existing run speed limits recovery from a pre-existing overlap; no snap
		# across a whole body width on landing or after an intentional crossover.
		remaining[actor]=actor.get_run_speed()/60.0
		starts[actor]=actor.global_position
	for i in range(live.size()):
		for j in range(i+1,live.size()):
			var a=live[i];var b=live[j]
			if not pair_allowed(a,b):continue
			var key:="%d:%d"%[a.get_instance_id(),b.get_instance_id()]
			var left=a if bounds(a).get_center().x<=bounds(b).get_center().x else b
			# Retain order only across consecutive eligible ticks. Aerial, dodge,
			# phase, grab and hurt crossings establish their new side naturally.
			if previous_order.has(key):left=a if previous_order[key]==a.get_instance_id() else b
			var right=b if left==a else a
			pairs.append([left,right]);next_order[key]=left.get_instance_id()
	var corrections:=0
	for iteration in range(maxi(4,live.size()*2)):
		var changed:=false
		for pair in pairs:
			var a=pair[0];var b=pair[1]
			var overlap:=bounds(a).end.x-bounds(b).position.x
			if overlap<=.0001:continue
			var ca:float=absf(allowed_motion(a,-minf(overlap,remaining[a])))
			var cb:float=absf(allowed_motion(b,minf(overlap,remaining[b])))
			var da:=minf(overlap*.5,ca);var db:=minf(overlap*.5,cb)
			var missing:=maxf(0,overlap-da-db)
			var extra:=minf(missing,maxf(0,ca-da));da+=extra;missing-=extra
			db+=minf(missing,maxf(0,cb-db))
			if da+db<=.00001:continue
			a.global_position.x-=da;b.global_position.x+=db
			remaining[a]-=da;remaining[b]-=db;corrections+=1;changed=true
		if not changed:break
	previous_order=next_order
	var moved:Array=[]
	for actor in live:
		var dx:float=actor.global_position.x-starts[actor].x
		if absf(dx)>.00001:moved.append({"slot":actor.slot,"dx":dx})
	last={"physics_frame":Engine.get_physics_frames(),"eligible_slots":live.map(func(a):return a.slot),"pair_count":pairs.size(),"corrections":corrections,"moved":moved,"cpu_usec":Time.get_ticks_usec()-started}
