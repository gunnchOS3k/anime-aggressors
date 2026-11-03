extends RefCounted
## Presentation observes existing shield authority only. No move, damage,
## shield health, state, timing, hitstop, invulnerability or save writes.
const Spectral = preload("res://scripts/visual/spectral_feedback_renderer.gd")
const GuardShader = preload("res://shaders/elemental_guard_8c.gdshader")
const Audio = preload("res://scripts/audio/guard_audio_8c.gd")
const STAGES := ["healthy","strained","low","imminent"]
var fighter
var renderer
var audio
var _guard_slot := -1
var _pulse_slot := -1
var _tier := 0
var _guarding := false
var _ratio := 1.0
var _last_identity := ""
var _break_ids: Dictionary = {}
var _contact_ids: Dictionary = {}
var _slot_events: Dictionary = {}
var _history: Array = []
var _fallback_evictions := 0
var _allocation_failures := 0
var _clear_reason := ""
var _guard_bounds: Dictionary = {}

func setup(actor) -> void:
	fighter=actor
	audio=Audio.new();audio.name="ElementalGuardAudio8C"
	fighter.add_child(audio);audio.setup(fighter)

func _record(event: String, detail: Dictionary={}) -> void:
	var row := {"event":event,"frame":Engine.get_physics_frames(),"fighter":str(fighter.fighter_id),"stage":STAGES[_tier],"normalized_durability":_ratio}
	row.merge(detail,true);_history.append(row)
	if _history.size()>128:_history.pop_front()

func _owns(slot: int) -> bool:
	return is_instance_valid(renderer) and slot>=0 and slot<renderer.slots.size() and renderer.slots[slot].active and int(renderer.slots[slot].get("guard8c_owner",-1))==get_instance_id() and _slot_events.has(slot) and str(renderer.slots[slot].get("event_id",""))==str(_slot_events[slot])

func _retire(slot: int) -> void:
	if not _owns(slot):return
	# Restore the shared shader before returning the borrowed mesh to its pool.
	renderer.slots[slot].mesh.material.shader=Spectral.SHADER
	renderer.slots[slot].erase("guard8c_owner")
	renderer.stop_slot(slot)

func _allocate(kind: int, life: float, event_id: String) -> int:
	if not is_instance_valid(renderer):renderer=Spectral.obtain(fighter)
	if renderer==null:return -1
	var slot: int=renderer.emit_effect(str(fighter.fighter_id),kind,fighter.global_position+Vector2(0,-24),Vector2(float(fighter.facing),0),100,life,event_id,fighter if life<0 else null)
	if slot<0:
		# At all-primary saturation the oldest *finite* presentation can yield.
		# Never retire owned projectiles, persistent guard/charge, or gameplay.
		var oldest := -1
		for i in renderer.slots.size():
			var item: Dictionary=renderer.slots[i]
			if not item.active or float(item.get("life",-1))<=0 or item.has("guard8c_owner") or item.get("follow")!=null:continue
			if item.kind not in [0,1,7,8,10,20,21,22,24,25] or float(item.age)<.05:continue
			if oldest<0 or float(item.age)>float(renderer.slots[oldest].age):oldest=i
		if oldest>=0:
			renderer.stop_slot(oldest);_fallback_evictions+=1
			slot=renderer.emit_effect(str(fighter.fighter_id),kind,fighter.global_position+Vector2(0,-24),Vector2(float(fighter.facing),0),100,life,event_id,fighter if life<0 else null)
	if slot<0:_allocation_failures+=1;return -1
	var item: Dictionary=renderer.slots[slot]
	item["guard8c_owner"]=get_instance_id()
	_slot_events[slot]=event_id
	item.mesh.material.shader=GuardShader
	var family:=maxi(0,Spectral.IDS.find(str(fighter.fighter_id)))
	item.mesh.material.set_shader_parameter("family",family)
	var ink: Color=Color(.70,.71,.84) if family==7 else Spectral.COLORS[family]
	item["base_ink"]=ink
	if renderer.option("high_contrast_vfx"):ink=Color(1,.95,.76)
	if renderer.option("reduced_flash"):ink.a*=.55
	item.mesh.material.set_shader_parameter("accent",ink)
	item.mesh.material.set_shader_parameter("density",renderer.density_multiplier())
	item.mesh.material.set_shader_parameter("flash",0.0)
	item.mesh.material.set_shader_parameter("cue",0.0)
	item.mesh.material.set_shader_parameter("strain",1.0-_ratio)
	item.mesh.material.set_shader_parameter("warning_tier",float(_tier))
	return slot

func _set_stage(ratio: float) -> void:
	var next := 0
	# Lower crossings enter immediately; upward recovery has a 5% dead band.
	if ratio<=.12:next=3
	elif ratio<=.30:next=2
	elif ratio<=.60:next=1
	if next<_tier:
		if _tier==3 and ratio<=.17:next=3
		elif _tier==2 and ratio<=.35:next=2
		elif _tier==1 and ratio<=.65:next=1
	if next==_tier:return
	var previous := _tier;_tier=next
	_record("durability_stage",{"previous":STAGES[previous]})
	if _guarding and next>=2 and next>previous:audio.play("guard_warning")

func tick(_delta: float) -> void:
	if not is_instance_valid(fighter):return
	var state := str(fighter.state_machine.current_state)
	var closed := bool(fighter._transform_match_closed) or int(fighter.stocks)<=0 or state in ["ko","respawn","victory","defeat"]
	if closed:clear("match_or_actor_closed");return
	var maximum := float(fighter.data.get("shieldProfile",{}).get("maxHealth",100))
	_ratio=clampf(float(fighter.shield_health)/maxf(.001,maximum),0,1)
	var on := bool(fighter.shielding) and state in ["shield_start","shield_hold","shield_stun"] and not closed
	if _last_identity!=str(fighter.fighter_id):
		clear("identity_changed");_last_identity=str(fighter.fighter_id)
	_set_stage(_ratio)
	# Reserve one hidden primary mesh before exchanges fill the pool. An idle
	# guard consumes no drawing; its slot remains within the shared 32/96 cap.
	if not closed and not _owns(_guard_slot):_guard_slot=_allocate(12,-1,"guard8c_owned:"+str(fighter.get_instance_id()))
	if not on:
		if _guarding:_record("guard_retired",{"reason":state})
		_guarding=false
		if _owns(_guard_slot):
			renderer.set_slot_strength(_guard_slot,0.0);renderer.slots[_guard_slot].mesh.hide()
		if closed:clear("match_or_actor_closed")
		return
	if not _guarding:
		_guarding=true;_record("guard_open");audio.play("guard_open")
		if _tier>=2:audio.play("guard_warning")
	if _owns(_guard_slot):
		var item: Dictionary=renderer.slots[_guard_slot]
		renderer.set_slot_strength(_guard_slot,1.0);item.mesh.show()
		var shape=fighter.get_node_or_null("Hurtbox/HurtShape") as CollisionShape2D
		var dimensions: Vector2=shape.shape.get_rect().size if shape!=null and shape.shape!=null else Vector2(38,50)
		var height:=maxf(86,(dimensions.y+22)*1.45)
		var width:=maxf(76,(dimensions.x+24)*1.4)
		var center: Vector2=fighter.global_position+Vector2(0,-24)
		var model=fighter.model_3d
		if model!=null and model.has_method("project_bone_to_combat_world"):
			var head: Vector2=model.project_bone_to_combat_world("Head")
			var left: Vector2=model.project_bone_to_combat_world("Foot_L")
			var right: Vector2=model.project_bone_to_combat_world("Foot_R")
			if head.is_finite() and left.is_finite() and right.is_finite():
				var feet: Vector2=(left+right)*.5
				var visible_height:=absf(feet.y-head.y)+18.0
				# The analytical rim lies at .64 of quad height. Enclose the
				# projected rig, rather than an unrelated gameplay hurtbox.
				center=(head+feet)*.5+Vector2(0,-4)
				height=maxf(height,visible_height/.64)
				width=maxf(width,visible_height*.72/.64)
				_guard_bounds={"source":"live_projected_head_and_support_feet","head":head,"feet":feet,"center":center,"quad_size":Vector2(width,height)}
		renderer.update_slot(_guard_slot,center,Vector2(float(fighter.facing),0),height,0)
		item["follow_offset"]=center-fighter.global_position
		item.mesh.scale=Vector2(width,height)
		item.mesh.material.set_shader_parameter("strain",1.0-_ratio)
		item.mesh.material.set_shader_parameter("warning_tier",float(_tier))

func _pulse(cue: float, event_id: String, point: Vector2, attacker_id: String="") -> bool:
	_retire(_pulse_slot);_pulse_slot=_allocate(7 if cue==2 else 24 if cue==3 else 1,.34 if cue==2 else .22,event_id)
	if not _owns(_pulse_slot):return false
	var item: Dictionary=renderer.slots[_pulse_slot]
	item.mesh.global_position=point;item.world=point
	item.mesh.material.set_shader_parameter("cue",cue)
	var other:=maxi(0,Spectral.IDS.find(attacker_id))
	item.mesh.material.set_shader_parameter("secondary_family",other)
	item.mesh.material.set_shader_parameter("secondary_accent",Spectral.COLORS[other])
	return true

func confirmed_contact(info: Dictionary) -> Dictionary:
	var event_id:=str(info.get("combat_event_id",""))
	if event_id.is_empty() or not bool(info.get("confirmed_contact",false)):return {"ok":false,"reason":"unconfirmed_contact"}
	if _contact_ids.has(event_id):
		var duplicate: Dictionary=_contact_ids[event_id].duplicate(true);duplicate["duplicate"]=true
		return duplicate
	var result:=str(info.get("contact_result",""))
	if result not in ["shield","parry"]:return {"ok":false,"reason":"not_guard_contact"}
	var perfect:=result=="parry"
	var shown:=_pulse(3 if perfect else 1,event_id,info.get("contact_world",fighter.global_position+Vector2(0,-24)),str(info.get("attacker_id","")))
	var sound: Dictionary=audio.play("perfect_guard" if perfect else "guard_contact")
	_record("perfect_guard" if perfect else "shield_contact",{"combat_event_id":event_id,"attacker":info.get("attacker_id",""),"pool_cue":shown,"audio":sound})
	var report: Dictionary=sound.duplicate(true)
	# A deliberately rate-limited primary is handled here, not a reason for
	# the caller to add the old global sound on top of an already playing cue.
	if sound.has("suppressed"):report["ok"]=true;report["playing"]=false
	report["pool_cue"]=shown;report["combat_event_id"]=event_id;report["owned_guard_audio"]=true
	_contact_ids[event_id]=report.duplicate(true)
	if _contact_ids.size()>128:_contact_ids.erase(_contact_ids.keys()[0])
	return report

func break_event(event_id: String) -> bool:
	if event_id.is_empty() or _break_ids.has(event_id) or not is_instance_valid(fighter):return false
	if str(fighter.state_machine.current_state)!="shield_break":return false
	_break_ids[event_id]=true
	if _break_ids.size()>64:_break_ids.erase(_break_ids.keys()[0])
	_ratio=0;_tier=3;_guarding=false
	if _owns(_guard_slot):renderer.set_slot_strength(_guard_slot,0);renderer.slots[_guard_slot].mesh.hide()
	var shown:=_pulse(2,event_id,fighter.global_position+Vector2(0,-24))
	var sound: Dictionary=audio.play("guard_break")
	_record("shield_rupture",{"break_event_id":event_id,"pool_cue":shown,"audio":sound})
	return shown

func clear(reason: String) -> void:
	_retire(_guard_slot);_retire(_pulse_slot)
	_guard_slot=-1;_pulse_slot=-1;_guarding=false;_tier=0;_clear_reason=reason
	_slot_events.clear()
	if is_instance_valid(audio):audio.clear()

func snapshot() -> Dictionary:
	return {"schema":"elemental_guard_8c.v1","fighter":str(fighter.fighter_id) if is_instance_valid(fighter) else "","guarding":_guarding,"normalized_durability":_ratio,"stage":STAGES[_tier],"owned_guard_active":_owns(_guard_slot),"guard_slot":_guard_slot,"projected_bounds":_guard_bounds.duplicate(true),"guard_visible":_owns(_guard_slot) and renderer.slots[_guard_slot].mesh.visible,"owned_pulse_active":_owns(_pulse_slot),"pulse_slot":_pulse_slot,"max_owned_meshes":2,"fallback_transient_evictions":_fallback_evictions,"allocation_failures":_allocation_failures,"clear_reason":_clear_reason,"history":_history.duplicate(true),"audio":audio.snapshot() if is_instance_valid(audio) else {},"gameplay_writes":false,"human_visual_approved":false,"native_visual_verified":false}
