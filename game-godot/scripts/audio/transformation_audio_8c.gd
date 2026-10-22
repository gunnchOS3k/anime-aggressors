extends Node
## Original bounded arithmetic form score. Pipeline progress owns cue edges;
## no independent transformation timer, mechanics or licensed sample input.
const RATE := 22050
const IDs := ["ember-vale","rook-ironside","juno-spark","kaia-windrow","nix-calder","orion-vell","vesper-nyx","yin","yang"]
static var _cache: Dictionary = {}
static var _levels: Dictionary = {}
var actor
var voices: Array[AudioStreamPlayer] = []
var active := false
var step := 0
var target := ""
var edges: Dictionary = {}
var history: Array = []
func setup(owner_actor) -> void:
	actor=owner_actor
	for i in range(2):
		var voice:=AudioStreamPlayer.new();voice.set_meta("audio_category","sfx");add_child(voice);voices.append(voice)
static func synthesize(fid: String,stage: int,event: String) -> AudioStreamWAV:
	var key:=fid+":"+str(stage)+":"+event
	if _cache.has(key):return _cache[key]
	var family:=maxi(0,IDs.find(fid));var duration:=.48 if event=="gather" else .38 if event=="climax" else .24 if event=="reveal" else .16
	var count:=int(RATE*duration);var pcm:=PackedByteArray();pcm.resize(count*2)
	var peak:=0.0;var squares:=0.0
	for i in count:
		var t:=float(i)/RATE;var u:=float(i)/maxi(1,count-1)
		var grain:=sin(float(i*137+family*233))*sin(float(i*71+family*17))
		var rise:=pow(u,.6) if event=="gather" else exp(-u*4.0)
		var envelope:=sin(PI*u)*rise
		var body:=0.0
		match family:
			0:body=.40*sin(TAU*83*t)+.48*grain*(.5+.5*sin(TAU*31*t))+.18*sin(TAU*166*t)
			1:body=.62*sin(TAU*57*t)+.25*sin(TAU*114*t)+.18*grain*exp(-u*6)
			2:body=.35*sin(TAU*351*t)+.44*grain*pow(maxf(0,sin(TAU*83*t)),6)+.18*sin(TAU*1053*t)
			3:body=.55*grain*(.65+.35*sin(TAU*13*t))+.22*sin(TAU*194*t)+.12*sin(TAU*291*t)
			4:body=.31*sin(TAU*587*t)+.23*sin(TAU*829*t)+.22*sin(TAU*1174*t)*exp(-u*3)+.10*grain
			5:body=.48*sin(TAU*73*t)+.29*sin(TAU*109.5*t)*sin(TAU*7*t)+.16*sin(TAU*292*t)
			6:body=(.30*sin(TAU*277*t)+.28*sin(TAU*293*t)+.20*grain)*(.65+.35*sin(TAU*23*t))
			7:body=.54*sin(TAU*43*t)*(1-u)+.12*grain*exp(-u*12)
			8:body=.27*sin(TAU*220*t)+.26*sin(TAU*330*t)+.24*sin(TAU*440*t)+.13*sin(TAU*660*t)
		# Stage two introduces alternating pressure/definition and a longer body,
		# rather than merely pitching the same sample or raising global gain.
		if stage==2:body=body*(.75+.25*cos(TAU*9*t))+.16*sin(TAU*(93+family*29)*t)*sin(PI*u)
		if event=="climax":body+=.22*grain*exp(-u*9)
		elif event=="reveal":body+=.18*sin(TAU*(396+family*37)*t)*sin(PI*u)
		elif event=="cancel":body=body*(1-u)+.13*grain*exp(-u*10)
		var value:=clampf(body*envelope*.40,-.58,.58)
		if family==7:value*=.65
		peak=maxf(peak,absf(value));squares+=value*value;pcm.encode_s16(i*2,int(value*32767))
	var stream:=AudioStreamWAV.new();stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=RATE;stream.data=pcm
	_cache[key]=stream;_levels[key]={"peak_linear":peak,"rms_linear":sqrt(squares/count),"duration_seconds":duration,"sample_rate":RATE,"source":"original_arithmetic_transformation_audio_8c.gd","mix_approved":false}
	return stream
func _play(event: String,channel: int) -> void:
	if not is_instance_valid(actor) or voices.size()!=2:return
	var key:=str(actor.fighter_id)+":"+str(step)+":"+event
	var voice: AudioStreamPlayer=voices[channel];voice.stop();voice.stream=synthesize(str(actor.fighter_id),step,event)
	var dialogue=get_node_or_null("/root/StoryDialogue")
	var volume:=float(dialogue.settings.get("element_volume",.65)) if dialogue!=null else .65
	voice.volume_db=linear_to_db(maxf(.0001,volume))-12;voice.play()
	history.append({"event":event,"target":target,"frame":Engine.get_physics_frames(),"step":step,"voice":channel,"levels":_levels[key]})
	if history.size()>48:history.pop_front()
func begin(form_id: String,stage: int) -> void:
	clear();target=form_id;step=stage;active=true;edges.clear();_play("gather",0)
func sample(progress: float) -> void:
	if not active:return
	if progress>=.58 and not edges.has("climax"):edges["climax"]=true;_play("climax",1)
	if progress>=.85 and not edges.has("reveal"):edges["reveal"]=true;_play("reveal",0)
func complete() -> void:
	sample(1);active=false
func cancel() -> void:
	var owned:=active;clear()
	if owned:_play("cancel",1)
func clear() -> void:
	active=false
	for voice in voices:voice.stop()
func snapshot() -> Dictionary:
	var playing:=0
	for voice in voices:
		if voice.playing:playing+=1
	return {"active":active,"voices":voices.size(),"playing":playing,"history":history.duplicate(true),"licensed_inputs":"none_original_arithmetic_only","human_mix_approved":false}
