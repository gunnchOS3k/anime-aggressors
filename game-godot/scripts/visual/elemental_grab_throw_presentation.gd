extends Node
## Observes the existing paired grab and confirmed throw. Never resolves combat.
const Renderer = preload("res://scripts/visual/spectral_feedback_renderer.gd")
const AudioBank = preload("res://scripts/audio/procedural_audio_bank.gd")
const ElementAudio = preload("res://scripts/audio/elemental_performance.gd")
var fighter: Node2D
var contract: Dictionary={}
var history: Array=[]
var _renderer: Node2D
var _hold_slot := -1
var _held: WeakRef
var _flights: Array=[]
var _voices: Array=[]
var _voice_cursor := 0
var _event := ""
func setup(actor: Node2D) -> void:
	fighter=actor
	contract=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat/elemental_grab_throw.json"))
	fighter.grab_event.connect(_on_grab)
func _record(phase_name: String, detail: Dictionary={}) -> void:
	history.append({"phase":phase_name,"fighter":fighter.fighter_id,"event_id":_event,"physics_frame":Engine.get_physics_frames(),"detail":detail})
	if history.size()>128:history.pop_front()
func _audio(phase_name: String) -> void:
	var spec: Dictionary=contract.get("fighters",{}).get(fighter.fighter_id,{})
	var cue: String=spec.get("audio",{}).get(phase_name,"")
	if cue.is_empty():return
	var path:=ElementAudio.path(fighter.fighter_id,cue)
	var stream:=AudioBank.load_stream(path)
	if stream==null:_record("missing_audio",{"path":path});return
	# Two actor-owned source-family layers; no new loops or global bus changes.
	if _voices.size()<2:
		var voice:=AudioStreamPlayer.new();voice.set_meta("audio_category","sfx");add_child(voice);_voices.append(voice)
	var voice: AudioStreamPlayer=_voices[_voice_cursor%_voices.size()];_voice_cursor+=1
	voice.stop();voice.stream=stream
	voice.volume_db=linear_to_db(maxf(.0001,ElementAudio.mix_option("element_volume",.65)*.55))-9
	voice.play();_record("audio",{"cue":cue,"path":path,"playing":voice.playing,"original_family_reuse":true})
func _stop_hold() -> void:
	if is_instance_valid(_renderer):_renderer.stop_slot(_hold_slot)
	_hold_slot=-1;_held=null
func clear(reason: String) -> void:
	_stop_hold();_flights.clear()
	for voice in _voices:voice.stop()
	_record("cleanup",{"reason":reason})
func _on_grab(info: Dictionary) -> void:
	_renderer=Renderer.obtain(fighter)
	if _renderer==null:return
	var result: String=info.get("result","")
	if result=="attempt":
		_event="grab:%d:%d" % [fighter.get_instance_id(),fighter.move_runner.activation_id]
		_renderer.emit_effect(fighter.fighter_id,29,fighter.global_position+Vector2(12*fighter.facing,-22),Vector2(fighter.facing,0),46,.12,_event+":attempt")
		_record("attempt")
	elif result=="success":
		_stop_hold()
		if not is_instance_valid(fighter.grabbed_target):return
		_held=weakref(fighter.grabbed_target)
		_hold_slot=_renderer.emit_effect(fighter.fighter_id,25,fighter.global_position,Vector2(fighter.facing,0),66,-1,_event+":hold")
		_renderer.set_clash_parameters(_hold_slot,fighter.grabbed_target.fighter_id,false)
		_update_hold();_audio("acquire");_record("hold",{"target":fighter.grabbed_target.fighter_id})
	elif result=="throw":
		var target=instance_from_id(int(info.get("target_instance",0)))
		_stop_hold()
		var contact: Dictionary=info.get("contact",{})
		if not is_instance_valid(target) or not contact.get("confirmed_contact",false):return
		var origin: Vector2=contact.get("contact_world",target.global_position+Vector2(0,-22))
		var direction: Vector2=contact.get("contact_direction",Vector2(fighter.facing,0))
		_event=str(contact.combat_event_id)
		# HitResolver already emitted the ONE contact bloom, hitstop and punch SFX.
		# This open directional release smear does not claim a second impact.
		_renderer.emit_effect(fighter.fighter_id,26,origin,direction,88,.16,_event+":release")
		_audio("release");_record("release",{"target":target.fighter_id,"direction":[direction.x,direction.y],"contact_result":contact.contact_result})
		if contact.get("contact_result","")=="hit":
			_flights.append({"target":weakref(target),"last":target.global_position,"distance":0.0,"frames":0,"left_floor":not target.is_on_floor(),"id":_event,"fid":fighter.fighter_id})
	elif result in ["mash_escape","released"]:
		_stop_hold();_record("release_without_hit",info)
		if result=="mash_escape":
			_renderer.emit_effect(fighter.fighter_id,29,fighter.global_position+Vector2(0,-22),Vector2(-fighter.facing,0),50,.16,_event+":escape")
			_audio("escape")
	elif result=="whiff":
		_stop_hold();_record("whiff",info)
func _update_hold() -> void:
	var target=_held.get_ref() if _held!=null else null
	if not is_instance_valid(target) or fighter.grabbed_target!=target or target.grabbed_by!=fighter:
		_stop_hold();return
	var center: Vector2=fighter.global_position.lerp(target.global_position,.55)+Vector2(0,-22)
	_renderer.update_slot(_hold_slot,center,Vector2(fighter.facing,0),66,0)
	var charge: float=1.0 if fighter.party_overdrive.active() else clampf(fighter.get_effective_combat_aura()/100.0,0,1)
	_renderer.set_slot_strength(_hold_slot,.58+.32*charge)
func _physics_process(_delta: float) -> void:
	if not is_instance_valid(fighter):return
	if fighter._transform_match_closed or fighter.stocks<=0:
		if _hold_slot>=0 or not _flights.is_empty():clear("match_or_stock_end")
		return
	if not is_instance_valid(_renderer):return
	if _hold_slot>=0:_update_hold()
	for i in range(_flights.size()-1,-1,-1):
		var flight: Dictionary=_flights[i]
		var target=flight.target.get_ref()
		if not is_instance_valid(target) or target._transform_match_closed or target.stocks<=0 or target.invincible or target.grabbed_by!=null or str(target._last_hit_result.get("combat_event_id",""))!=str(flight.id):
			_flights.remove_at(i);continue
		flight.frames+=1
		if target._hitstop>0:continue
		var moved: Vector2=target.global_position-flight.last;flight.last=target.global_position
		flight.distance+=moved.length()
		if not target.is_on_floor():flight.left_floor=true
		# Only actual airborne-to-floor contact owns a landing, never a timeout.
		if flight.left_floor and target.is_on_floor():
			var query:=PhysicsRayQueryParameters2D.create(target.global_position+Vector2.UP*8,target.global_position+Vector2.DOWN*80,1)
			query.collide_with_areas=false
			var surface: Dictionary=target.get_world_2d().direct_space_state.intersect_ray(query)
			if not surface.is_empty() and surface.collider is StaticBody2D and surface.normal.y<-.6:
				var slot: int=_renderer.emit_effect(flight.fid,28,surface.position+Vector2.UP*2,Vector2.RIGHT,96,.28,flight.id+":landing")
				if slot>=0:
					_renderer.slots[slot].aspect=Vector2(1,.3);_renderer.slots[slot].mesh.scale=Vector2(96,28.8)
				_audio("landing");_record("landing",{"world":[surface.position.x,surface.position.y],"source_event":flight.id})
			_flights.remove_at(i);continue
		var hurt: bool=target.state_machine.current_state in ["hurt_light","hurt_heavy","hitstun","launched","tumble"]
		if flight.frames>120 or not hurt:
			_flights.remove_at(i);continue
		if flight.distance>=(14.0 if _renderer.option("reduced_particles") else 7.0):
			flight.distance=0.0
			_renderer.emit_effect(flight.fid,27,target.global_position+Vector2(0,-22),moved.normalized(),42,.18,flight.id+":wake:"+str(flight.frames))
func _exit_tree() -> void:
	_stop_hold()
