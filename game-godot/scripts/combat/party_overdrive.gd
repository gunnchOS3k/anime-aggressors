extends RefCounted
class_name PartyOverdrive
## Temporary item domain. Legacy forms, Story receipts and permanent unlocks are
## never written. All values are source-authoritative tuning candidates.
const DATA_PATH := "res://data/combat/party_overdrive.json"
const Spectral = preload("res://scripts/visual/spectral_feedback_renderer.gd")
const Audio = preload("res://scripts/audio/elemental_performance.gd")
var fighter
var doc: Dictionary = {}
var state := "BASE"
var item := ""
var variant := ""
var activation := 0
var clock := 0
var remaining := 0
var startup_left := 0
var ultimate_used := false
var counter_armed := false
var history: Array = []
var pulses_fired: Dictionary = {}
var _previous_presentation: Dictionary = {}
var _glyph: Node2D
var _resetting := false
func setup(actor) -> void:
	fighter = actor
	doc = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
func allowed() -> bool:
	return GameState.mode in ["versus","hazards","training"] and GameState.items_enabled and not fighter._transform_match_closed and not fighter.get_meta("story_cosmic_contract",false)
func active() -> bool:
	return state in ["OVERDRIVE_ACTIVE","ULTIMATE_STARTUP","ULTIMATE_ACTIVE","ULTIMATE_RECOVERY"]
func owns_motion() -> bool:
	return state in ["TRANSFORMATION_STARTUP","ULTIMATE_STARTUP","ULTIMATE_ACTIVE","ULTIMATE_RECOVERY"]
func definition() -> Dictionary:
	var entry: Dictionary = doc.get("fighters",{}).get(fighter.fighter_id,{})
	return entry.get("prism_heart",{}) if item=="prism_heart" else entry.get("puppet_seal",{}).get(variant,{})
func transition(next: String, reason: String) -> void:
	state=next
	if is_instance_valid(fighter._form_audio_8c):fighter._form_audio_8c.party_event(next,reason,activation)
	history.append({"clock":clock,"state":state,"reason":reason,"activation":activation,"slot":fighter.slot,"fighter":fighter.fighter_id})
	if history.size()>64:history.pop_front()
func acquire(id: String, seal_variant: String, token: int) -> bool:
	if not allowed() or state!="BASE" or id not in ["prism_heart","puppet_seal"] or fighter.stocks<=0 or not fighter.controls_enabled: return false
	if not seal_variant in ["BLACK","WHITE"]: return false
	item=id;variant=seal_variant;activation=token;ultimate_used=false
	transition("ITEM_ACQUIRED","pickup")
	return true
func action() -> bool:
	if not allowed() or not fighter.state_machine.can_attack() or fighter.move_runner.active or not fighter.is_on_floor() or fighter.grabbed_by!=null or fighter.grabbed_target!=null:return false
	if state=="ITEM_ACQUIRED":
		startup_left=int(doc.transform_startup_frames)
		fighter.velocity=Vector2.ZERO
		fighter.state_machine.enter("party_transform")
		transition("TRANSFORMATION_STARTUP","public_taunt")
		if not is_instance_valid(fighter._form_audio_8c):Audio.one_shot(fighter.fighter_id,"charge_start",fighter)
		show_cue(2,100,.35)
		return true
	if state=="OVERDRIVE_ACTIVE" and item=="prism_heart" and not ultimate_used:
		ultimate_used=true;counter_armed=false;pulses_fired.clear()
		var u:Dictionary=doc.fighters[fighter.fighter_id].ultimate.duplicate(true)
		u["_party_ultimate"]=true;u["_party_move"]=true;u["party_activation"]=activation
		u["move_type"]="party_ultimate";u["damage"]=float(u.get("damage",0));u["hitstop_frames"]=4
		u["knockback_growth"]=1.1;u["element_effect"]=fighter._party_element()
		u["feedback"]={"tier":"heavy","hitstop_frames":5}
		u["cancel_windows"]=[]
		transition("ULTIMATE_STARTUP","public_taunt")
		fighter._start_move_dict(u)
		show_cue(12,150,float(u.startup_frames)/60.0)
		if not is_instance_valid(fighter._form_audio_8c):Audio.one_shot(fighter.fighter_id,"charge_ready",fighter)
		return true
	return false
func tick() -> void:
	clock+=1
	if state=="BASE":return
	if not allowed():reset("mode_or_match_closed");return
	if fighter.stocks<=0:reset("no_stock");return
	if state=="TRANSFORMATION_STARTUP":
		startup_left-=1
		if startup_left<=0:
			remaining=int(doc.duration_frames)
			fighter.phase_cancel_remaining=0;fighter.dash_cancel_remaining=0;fighter.armor_frames_remaining=0
			_previous_presentation=fighter._model_presentation_data.duplicate(true)
			var look:Dictionary=_previous_presentation.duplicate(true)
			look["collectible_review_form"]=str(definition().get("asset_form","BASE"))
			if fighter.model_3d!=null:
				fighter.model_3d.configure(look)
				fighter.model_3d.set_form_id("PARTY:"+str(definition().get("state_id","")),{"body_scale":1.0})
			_glyph=preload("res://scripts/visual/party_form_glyph.gd").new()
			fighter.add_child(_glyph);_glyph.configure(fighter,item,str(definition().get("state_id","")))
			transition("OVERDRIVE_ACTIVE","startup_complete")
			fighter.state_machine.enter("idle")
			if not is_instance_valid(fighter._form_audio_8c):Audio.one_shot(fighter.fighter_id,"charge_release",fighter)
	elif active():
		remaining-=1
		if remaining<=0:reset("expired")
func overlay(move: Dictionary) -> Dictionary:
	var result:=move.duplicate(true)
	# Grabs/throws retain their original ownership; they gain no Party damage.
	var patch:Dictionary=definition().get("overrides",{}).get(str(move.get("move_id","")),{})
	result.merge(patch,true)
	result["_party_move"]=true;result["party_activation"]=activation
	return result
func on_phase(phase: String) -> bool:
	if _resetting or state not in ["ULTIMATE_STARTUP","ULTIMATE_ACTIVE","ULTIMATE_RECOVERY"]:return false
	var next:="ULTIMATE_"+phase.to_upper()
	transition(next,"move_runner")
	fighter.state_machine.enter(next.to_lower())
	if phase=="recovery":fighter.armor_frames_remaining=0;fighter.hitbox.monitoring=false
	return true
func on_active(move: Dictionary) -> bool:
	if not bool(move.get("_party_ultimate",false)):return false
	if not active() or int(move.get("party_activation",-1))!=activation:return true
	var frame:int=fighter.move_runner.frame_in_phase
	if frame==1:
		if not is_instance_valid(fighter._form_audio_8c):Audio.one_shot(fighter.fighter_id,"signature_release",fighter)
		show_cue(9,150,.24)
		var impulse:Dictionary=move.get("impulse",{})
		fighter.velocity+=Vector2(float(impulse.get("x",0))*fighter.attack_direction,float(impulse.get("y",0)))
	if str(move.get("mechanic",""))=="guarded_retaliation":
		fighter.armor_frames_remaining=2.0/60.0 if frame<=int(move.counter_window_frames) else 0.0
		if frame==int(move.retaliation_frame) and counter_armed:
			fighter.hitbox.monitoring=true
			fighter._update_hitbox_from_move(move)
		elif frame>int(move.retaliation_frame)+2:fighter.hitbox.monitoring=false
		return true
	for i in range(move.get("pulses",[]).size()):
		var pulse:Dictionary=move.pulses[i]
		if frame!=int(pulse.frame) or pulses_fired.has(i):continue
		pulses_fired[i]=true
		var attack:Dictionary={"move_id":str(move.move_id)+":pulse:"+str(i),"move_type":"projectile","damage":pulse.damage,
			"base_knockback":pulse.base_knockback,"knockback_growth":1.1,"angle_deg":pulse.launch_angle,"hitstop_frames":3,
			"projectile":pulse.projectile.duplicate(true),"element_effect":fighter._party_element(),"_party_move":true,
			"party_activation":activation,"projectile_tier":"projectile_medium","feedback":{"tier":"medium","hitstop_frames":3}}
		fighter.projectile_spawner.spawn_from_move(attack,0)
	return true
func armor_contact() -> void:
	if state=="ULTIMATE_ACTIVE" and fighter.fighter_id=="rook-ironside" and fighter.move_runner.frame_in_phase<=8:
		counter_armed=true
func move_ended(mid: String) -> bool:
	if not mid.begins_with("party_ultimate:") or _resetting:return false
	# MoveRunner emits before clearing itself. Never recursively cancel it.
	reset("ultimate_consumed",false)
	return true
func interrupt() -> void:
	if state=="TRANSFORMATION_STARTUP" or state.begins_with("ULTIMATE_"):reset("body_hit")
func reset(reason: String, cancel_move: bool=true, restore_motion: bool=true) -> void:
	if _resetting or state=="BASE":return
	_resetting=true
	var owned_motion:=owns_motion()
	transition("TRANSFORMATION_EXPIRE",reason)
	if cancel_move and fighter.move_runner!=null and int(fighter.move_runner.move_data.get("party_activation",-1))==activation:
		fighter.move_runner.cancel();fighter.hitbox.monitoring=false
	if fighter.projectile_spawner!=null:
		for shot in fighter.projectile_spawner.active_projectiles.duplicate():
			if is_instance_valid(shot) and int(shot.move_data.get("party_activation",-1))==activation:shot.cancel_immediate()
	if is_instance_valid(_glyph):_glyph.queue_free()
	_glyph=null
	if not _previous_presentation.is_empty() and fighter.model_3d!=null:
		fighter.model_3d.configure(_previous_presentation)
		fighter.apply_form(fighter.get_current_form_id())
	_previous_presentation.clear()
	if owned_motion:fighter.armor_frames_remaining=0
	if owned_motion and restore_motion:
		fighter.state_machine.enter("idle" if fighter.is_on_floor() else "fall")
	transition("RESET",reason)
	item="";variant="";remaining=0;startup_left=0;pulses_fired.clear();counter_armed=false
	transition("BASE",reason)
	_resetting=false
func show_cue(kind: int, size: float, life: float) -> void:
	var renderer=Spectral.obtain(fighter)
	if renderer!=null:renderer.emit_effect(fighter.fighter_id,kind,fighter.global_position+Vector2(0,-24),Vector2(fighter.facing,0),size,life)
func snapshot() -> Dictionary:
	return {"schema":"party_state.v1","fighter":fighter.fighter_id,"slot":fighter.slot,"clock":clock,"state":state,"item":item,"variant":variant,"activation":activation,"remaining":remaining,"ultimate_used":ultimate_used,"counter_armed":counter_armed,"status":"TUNING_CANDIDATE","network_transport_verified":false}

# Trusted local simulation COMPONENT, separate from the diagnostic snapshot.
# Capture only at completed steps. Models/glyphs, projectiles, Fighter motion
# and committed presentation events require their own restoration barrier.
# This API is never a peer-authorized form grant or a full-match snapshot.
func capture_component_state() -> Dictionary:
	var result := {"schema":"party_overdrive/v1", "owner":{
		"instance":fighter.get_instance_id() if is_instance_valid(fighter) else 0,
		"fighter":str(fighter.fighter_id) if is_instance_valid(fighter) else "",
		"slot":int(fighter.slot) if is_instance_valid(fighter) else 0}}
	for key in ["state", "item", "variant", "activation", "clock", "remaining", "startup_left", "ultimate_used", "counter_armed", "pulses_fired", "history", "_previous_presentation", "_resetting"]:
		var value = get(key)
		result[key] = value.duplicate(true) if value is Dictionary or value is Array else value
	return result

func restore_component_state(record: Dictionary) -> bool:
	var baseline := capture_component_state()
	if record.size() != baseline.size() or record.get("schema", "") != baseline.schema or record.get("owner", {}) != baseline.owner: return false
	for key in baseline:
		if not record.has(key) or typeof(record[key]) != typeof(baseline[key]): return false
	# A synchronous reset is not a complete-step boundary. Never resume half
	# of its cancellation, presentation teardown or ownership release.
	if _resetting or record._resetting: return false
	if record.state not in ["BASE", "ITEM_ACQUIRED", "TRANSFORMATION_STARTUP", "OVERDRIVE_ACTIVE", "ULTIMATE_STARTUP", "ULTIMATE_ACTIVE", "ULTIMATE_RECOVERY"]: return false
	if record.item not in ["", "prism_heart", "puppet_seal"] or record.variant not in ["", "BLACK", "WHITE"]: return false
	if record.state != "BASE" and (record.item.is_empty() or record.variant.is_empty()): return false
	for key in ["activation", "clock", "remaining", "startup_left"]:
		if int(record[key]) < 0: return false
	if record.remaining > int(doc.get("duration_frames", 0)) or record.startup_left > int(doc.get("transform_startup_frames", 0)) or record.history.size() > 64: return false
	var authored_pulses: Array = doc.get("fighters", {}).get(str(fighter.fighter_id), {}).get("ultimate", {}).get("pulses", [])
	for key in record.pulses_fired:
		if typeof(key) != TYPE_INT or key < 0 or key >= authored_pulses.size() or typeof(record.pulses_fired[key]) != TYPE_BOOL or not record.pulses_fired[key]: return false
	# All checks precede writes. Do not transition/reset/start a move, spend
	# meter, emit audio, spawn a pulse or reconfigure source art on restoration.
	for key in baseline:
		if key in ["schema", "owner"]: continue
		var value = record[key]
		set(key, value.duplicate(true) if value is Dictionary or value is Array else value)
	return true
