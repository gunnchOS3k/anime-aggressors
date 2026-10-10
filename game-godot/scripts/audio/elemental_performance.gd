extends Node
## Owned by a fighter/projectile; lifetime and pause follow the scene.
const Bank = preload("res://scripts/audio/procedural_audio_bank.gd")
var fighter_id := ""
var charge: AudioStreamPlayer
var travel: AudioStreamPlayer
var _charge_ready := false
var events: Array = []
static func mix_option(key: String,fallback: float) -> float:
	var tree := Engine.get_main_loop() as SceneTree
	var dialogue = tree.root.get_node_or_null("StoryDialogue") if tree != null else null
	return float(dialogue.settings.get(key,fallback)) if dialogue != null else fallback
static func path(fid: String,event: String) -> String:
	return "res://assets/audio/elemental_v1/%s/%s.wav" % [fid,event]
static func one_shot(fid: String,event: String,host: Node,intensity: float=1.0) -> Dictionary:
	var mix := mix_option("element_volume",.65)
	var result := Bank.play(path(fid,event),host,linear_to_db(maxf(.0001,mix*clampf(intensity,.2,1.0)))-7)
	result["event"]=event;result["fighter_id"]=fid
	return result
func play(event: String,intensity: float=1.0) -> Dictionary:
	var result := one_shot(fighter_id,event,self,intensity)
	events.append(result);return result
func _loop(event: String) -> AudioStreamPlayer:
	var source := Bank.load_stream(path(fighter_id,event)) as AudioStreamWAV
	if source == null: push_error("Required elemental loop missing: "+path(fighter_id,event)); return null
	var stream := source.duplicate() as AudioStreamWAV
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin=0;stream.loop_end=int(stream.get_length()*stream.mix_rate)
	var player := AudioStreamPlayer.new();player.stream=stream;add_child(player)
	player.volume_db=-18;player.play()
	events.append({"ok":true,"playing":player.playing,"fighter_id":fighter_id,"event":event,"path":path(fighter_id,event),"owned_loop":true})
	return player
func update_charge(on: bool,pct: float) -> void:
	if on:
		if charge==null:
			play("charge_start");charge=_loop("charge_loop");_charge_ready=false
		if charge!=null:charge.volume_db=linear_to_db(maxf(.0001,mix_option("element_volume",.65)*(.12+.4*clampf(pct,0,1))))-6
		if pct>=1 and not _charge_ready:_charge_ready=true;play("charge_ready")
	elif charge!=null:
		charge.stop();charge.queue_free();charge=null;_charge_ready=false;play("charge_release")
func cancel_charge() -> void:
	if charge!=null:
		charge.stop();charge.queue_free();charge=null;_charge_ready=false;play("charge_cancel")
func start_travel() -> void:
	if travel==null:travel=_loop("projectile_travel")
func _process(_delta: float) -> void:
	if travel!=null:travel.volume_db=linear_to_db(maxf(.0001,mix_option("element_volume",.65)*.18))-6
