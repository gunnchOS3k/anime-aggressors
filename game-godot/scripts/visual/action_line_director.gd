extends RefCounted
## One observer per fighter, using the existing bounded spectral mesh pool.
## No damage, hitstop, frame-data, collision, receipt or meter authority.
const Renderer=preload("res://scripts/visual/spectral_feedback_renderer.gd")
var profile: Dictionary={}
var _last_fighter := ""
var _last_position := Vector2.INF
var _last_hand := Vector2.INF
var _last_frame := -1
var _anticipation_activation := -1
var _maximum := false
var _last_limb := ""
var emitted := {"movement":0,"anticipation":0,"limb_smear":0,"arrival":0}
var history: Array=[]
func _record(kind: String,p,runner,origin: Vector2) -> void:
	var event={"kind":kind,"fighter_id":p.fighter_id,"physics_frame":Engine.get_physics_frames(),"activation":runner.activation_id,"move_id":runner.current_move_id(),"phase":runner.phase,"frame_in_phase":runner.frame_in_phase,"origin":[origin.x,origin.y],"source":"actual body displacement / visible rig / resolved runner; never contact authority"}
	history.append(event)
	if history.size()>128:history.pop_front()
	emitted[kind]+=1
func observe(p,snapshot: Dictionary) -> void:
	var frame:=Engine.get_physics_frames()
	if frame==_last_frame:return
	_last_frame=frame
	if p.fighter_id!=_last_fighter:
		_last_fighter=p.fighter_id;_last_position=Vector2.INF;_last_hand=Vector2.INF;_anticipation_activation=-1;_maximum=false
		var f=FileAccess.open("res://data/animation/combat_expression_profiles.json",FileAccess.READ)
		profile=JSON.parse_string(f.get_as_text()).fighters.get(p.fighter_id,{})
	var chest: Vector2=p.model_3d.project_bone_to_combat_world("Chest")
	var controller=p.model_3d.get_animation_controller()
	var limb: String=str(profile.get("limb","Hand_R"))
	if controller!=null:
		var clip: String=str(controller.get_animation_player().current_animation).get_slice("/",1)
		limb=str(controller._choreography_timing.get(clip,{}).get("striking_limb",limb))
	if limb!=_last_limb:_last_hand=Vector2.INF;_last_limb=limb
	var hand: Vector2=p.model_3d.project_bone_to_combat_world(limb)
	if not chest.is_finite() or not hand.is_finite():return
	var previous:=_last_position;var previous_hand:=_last_hand
	_last_position=p.global_position;_last_hand=hand
	if not p.visible or p.state_machine.current_state in ["ko","respawn"]:return
	var renderer=Renderer.obtain(p)
	if renderer==null:return
	var runner=p.move_runner
	var reduced: bool=bool(snapshot.get("reduced_particles",false)) or snapshot.get("intensity","")=="Reduced"
	var stride: int=int(profile.get("movement_spacing_frames",5))*(2 if reduced else 1)
	if bool(snapshot.get("active",false)) and previous.is_finite() and (p.global_position-previous).length()>1.0 and p.velocity.length()>80 and frame%stride==0:
		var dir: Vector2=p.global_position-previous
		renderer.emit_effect(p.fighter_id,13,chest-dir.normalized()*18,dir.normalized(),84,.13)
		_record("movement",p,runner,chest)
	var maximum: bool=bool(snapshot.get("super_ready",false))
	if maximum and not _maximum:
		renderer.emit_effect(p.fighter_id,17,chest,Vector2(p.facing,0),112,.24)
		_record("arrival",p,runner,chest)
	_maximum=maximum
	if p._hitstop>0:return
	if runner.active and runner.phase=="startup":
		var startup: int=int(runner.move_data.get("startup_frames",0))
		# The transition tick is already active: the last observable startup
		# sample is startup-1 (including frame0 for a one-frame startup).
		var trigger:=clampi(int(ceil(startup*float(profile.get("anticipation_phase",.7)))),0,maxi(0,startup-1))
		if runner.frame_in_phase>=trigger and _anticipation_activation!=runner.activation_id:
			_anticipation_activation=runner.activation_id
			renderer.emit_effect(p.fighter_id,14,hand,Vector2(p.facing,0),65,.09)
			_record("anticipation",p,runner,hand)
	if runner.active and runner.phase=="active" and previous_hand.is_finite() and (hand-previous_hand).length()>1.25 and frame%(2 if reduced else 1)==0:
		var path: Vector2=hand-previous_hand
		var extent:=clampf(path.length()*2.0,20,90)
		renderer.emit_effect(p.fighter_id,15,(hand+previous_hand)*.5,path.normalized(),extent,float(profile.get("smear_life",.10)))
		_record("limb_smear",p,runner,hand)
func evidence() -> Dictionary:
	return {"profile":profile.duplicate(true),"emitted":emitted.duplicate(),"history":history.duplicate(true),"ground_contact_accents":"BLOCKED: visible sole/floor coordinate contract; no invented footsteps","gameplay_writes":false}
