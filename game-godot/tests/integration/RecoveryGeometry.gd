extends SceneTree
## Actual-source unit tests with declared reaction/shape fixtures.
## No BattleScene, earned KO, CPU, rendered models or visual acceptance.
const States=preload("res://scripts/fighters/fighter_states.gd")
const Machine=preload("res://scripts/fighters/fighter_state_machine.gd")
const Space=preload("res://scripts/combat/combat_space_contract.gd")
const IDS=["ember-vale","rook-ironside","juno-spark","kaia-windrow","nix-calder","orion-vell","vesper-nyx","yin","yang"]
class ReactionActor extends Node2D:
	var grounded := false
	var controls_enabled := true
	var shielding := false
	var velocity := Vector2(-16,-11)
	var hitstun_remaining := .234146347045898
	var state_machine
	var landed := false
	var di_ticks := 0
	func is_on_floor() -> bool:return grounded
	func apply_hitstun_di(_delta: float) -> void:di_ticks+=1
	func try_tech() -> bool:return false
	func begin_landing(_from_air: bool,_fast: bool) -> void:
		landed=true;state_machine.enter(States.LAND)

var failures: Array=[]
var rows: Array=[]
var checks:=0
func _initialize() -> void:call_deferred("run")
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures.append(label)
func run() -> void:
	for duration in [.08,.234146347045898,.333409400939941,.55]:
		var actor=ReactionActor.new();var machine=Machine.new()
		actor.state_machine=machine;actor.hitstun_remaining=duration;machine.setup(actor)
		machine.enter(States.LAUNCHED)
		var limit=int(ceil(duration*60))
		for i in range(limit-1):machine.update(1.0/60.0)
		check(machine.current_state==States.LAUNCHED,"launch_held_before_deadline:"+str(duration))
		check(not machine.can_attack() and not machine.can_move(),"no_early_control:"+str(duration))
		var before=actor.velocity
		for i in range(2):machine.update(1.0/60.0)
		check(machine.current_state==States.FALL and machine.can_attack() and machine.can_move(),"air_control_after_deadline:"+str(duration))
		check(actor.velocity==before,"no_velocity_rewrite:"+str(duration))
		rows.append({"reaction_hitstun_seconds":duration,"state_after":machine.current_state,"resolved_control":machine.can_move()})
		# Existing grounded landing wins over the airborne timeout.
		actor.grounded=true;actor.velocity.y=0;machine.enter(States.LAUNCHED);machine.update(1.0/60.0)
		check(actor.landed and machine.current_state==States.LAND,"ground_landing_preserved:"+str(duration))
		machine.free();actor.free()
	for fid in IDS:
		var moves: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/moves/"+fid+".json"))
		var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/fighters/"+fid+".json"))
		var grab: Dictionary=moves.moves.filter(func(m):return m.move_id=="grab")[0]
		var size=Space.hurt_size_from_profile(data.get("hitHurtProfile",{}))
		var hurt_rect=Rect2(-size*.5,size)
		for face in [1,-1]:
			var actor_transform=Transform2D(Vector2(face,0),Vector2(0,1),Vector2(-517,280))
			var hurt_transform=Transform2D(0,Vector2(-535,256)) # HurtShape(0,-24), root y280.
			check(Space.grab_height_overlaps(actor_transform,grab.hitboxes,hurt_transform,hurt_rect),fid+str(face)+":floor_overlap")
			hurt_transform.origin.y=192-24 # Observed invalid recovery-grab baseline.
			check(not Space.grab_height_overlaps(actor_transform,grab.hitboxes,hurt_transform,hurt_rect),fid+str(face)+":air_gap_rejected")
			hurt_transform.origin.y=360-24
			check(not Space.grab_height_overlaps(actor_transform,grab.hitboxes,hurt_transform,hurt_rect),fid+str(face)+":below_reach_rejected")
			var top=280+float(grab.hitboxes[0].offset_y)-float(grab.hitboxes[0].height)*.5
			hurt_transform.origin.y=top-hurt_rect.end.y
			check(Space.grab_height_overlaps(actor_transform,grab.hitboxes,hurt_transform,hurt_rect),fid+str(face)+":touching_boundary")
			hurt_transform.origin.y-=.01
			check(not Space.grab_height_overlaps(actor_transform,grab.hitboxes,hurt_transform,hurt_rect),fid+str(face)+":outside_boundary")
			check(not Space.grab_height_overlaps(actor_transform,[],hurt_transform,hurt_rect),fid+str(face)+":no_authored_box")
			rows.append({"fighter":fid,"facing":face,"source_grab_box":grab.hitboxes[0],"profile_hurt_size":str(size),"scope":"source geometry, not body-art/native acceptance"})
	var output=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.trim_prefix("--ordinary-output=")
	if not output.is_empty():
		var f=FileAccess.open(output.path_join("RECOVERY_GEOMETRY.json"),FileAccess.WRITE)
		f.store_string(JSON.stringify({"PASS":failures.is_empty(),"checks":checks,"rows":rows,"failures":failures,"scope":"Actual-source unit tests; declared reaction actors/shape transforms; no BattleScene, earned KO or visual acceptance."},"  "));f.close()
	print("RECOVERY_GEOMETRY ","PASS" if failures.is_empty() else "FAIL"," checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
