extends Node
## Original runtime synthesis. No recordings, samples, imported performances or
## generated files. A guard owns exactly two voices; subsequent cues replace a
## voice instead of growing the global audio player tree. Human mix is pending.
const RATE := 22050
const IDS := ["ember-vale","rook-ironside","juno-spark","kaia-windrow","nix-calder","orion-vell","vesper-nyx","yin","yang"]
const EVENTS := ["guard_open","guard_warning","guard_contact","guard_break","perfect_guard"]
static var _streams: Dictionary = {}
static var _measurements: Dictionary = {}
var fighter
var voices: Array[AudioStreamPlayer] = []
var history: Array = []
var _last_event_frame: Dictionary = {}

func setup(actor) -> void:
	fighter = actor
	for i in range(2):
		var voice := AudioStreamPlayer.new()
		voice.name = "GuardVoice%d" % i
		voice.set_meta("audio_category","sfx")
		add_child(voice)
		voices.append(voice)

static func _synthesize(fid: String, event: String) -> AudioStreamWAV:
	var key := fid+":"+event
	if _streams.has(key):return _streams[key]
	var family := maxi(0,IDS.find(fid))
	var duration := .34 if event=="guard_break" else .23 if event=="perfect_guard" else .12 if event=="guard_warning" else .09
	var count := int(duration*RATE)
	var pcm := PackedByteArray();pcm.resize(count*2)
	var peak := 0.0
	var squares := 0.0
	for i in count:
		var time := float(i)/RATE
		var progress := float(i)/maxi(1,count-1)
		# Window endpoints avoid clicks; none of the identities is an aliased
		# single sweep. Deterministic layered transients remain below Nyquist.
		var window := sin(PI*progress)*exp(-progress*(3.0 if event=="guard_break" else 5.0))
		var grain := sin(float(i*73+family*997))*sin(float(i*151+family*29))
		var body := 0.0
		match family:
			0:body = .42*sin(TAU*132*time)+.34*grain*(.6+.4*sin(TAU*47*time))+.16*sin(TAU*372*time)*exp(-progress*7)
			1:body = .62*sin(TAU*76*time)+.2*sin(TAU*151*time)+.25*grain*exp(-progress*12)
			2:body = .34*sin(TAU*480*time)+.44*grain*pow(maxf(0,sin(TAU*103*time)),8)+.16*sin(TAU*1320*time)*exp(-progress*6)
			3:body = .5*grain*(.65+.35*sin(TAU*19*time))+.22*sin(TAU*218*time)+.12*sin(TAU*327*time)
			4:body = .32*sin(TAU*671*time)+.26*sin(TAU*947*time)+.19*sin(TAU*1337*time)*exp(-progress*4)+.14*grain*exp(-progress*9)
			5:body = .45*sin(TAU*98*time)+.26*sin(TAU*147*time)*sin(TAU*11*time)+.16*sin(TAU*392*time)
			6:body = (.28*sin(TAU*313*time)+.25*sin(TAU*337*time)+.2*grain)*(.7+.3*sin(TAU*31*time))
			7:body = .46*sin(TAU*63*time)*(1-progress)+.12*grain*exp(-progress*14)
			8:body = .26*sin(TAU*264*time)+.25*sin(TAU*396*time)+.23*sin(TAU*528*time)+.13*sin(TAU*792*time)
		var accent := 1.0
		if event=="guard_break":body += .3*grain*exp(-progress*4);accent=1.2
		elif event=="perfect_guard":body += .2*sin(TAU*(660+family*33)*time)*exp(-progress*2);accent=.9
		elif event=="guard_warning":accent=.56;window *= .55+.45*pow(sin(PI*progress),2)
		elif event=="guard_open":accent=.52
		var value := clampf(body*window*accent*.42,-.62,.62)
		if family==7:value *= .62
		peak=maxf(peak,absf(value));squares+=value*value
		pcm.encode_s16(i*2,int(value*32767))
	var stream := AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=RATE;stream.stereo=false;stream.data=pcm
	_streams[key]=stream
	_measurements[key]={"peak_linear":peak,"rms_linear":sqrt(squares/maxi(1,count)),"sample_rate":RATE,"samples":count,"duration_seconds":duration,"source":"original_arithmetic_synthesis_guard_audio_8c.gd","human_mix_approved":false}
	return stream

func play(event: String) -> Dictionary:
	if event not in EVENTS or not is_instance_valid(fighter):return {"ok":false,"reason":"invalid_event_or_owner"}
	var frame := Engine.get_physics_frames()
	var cooldown := 30 if event=="guard_warning" else 5 if event=="guard_contact" else 2
	if frame-int(_last_event_frame.get(event,-1000))<cooldown:return {"ok":false,"suppressed":"edge_cooldown","event":event}
	_last_event_frame[event]=frame
	var channel := 0 if event in ["guard_open","guard_warning"] else 1
	var voice: AudioStreamPlayer=voices[channel]
	voice.stop()
	voice.stream=_synthesize(str(fighter.fighter_id),event)
	var tree := get_tree()
	var settings=tree.root.get_node_or_null("StoryDialogue") if tree!=null else null
	var volume := float(settings.settings.get("element_volume",.65)) if settings!=null else .65
	voice.volume_db=linear_to_db(maxf(.0001,clampf(volume,0,1)))-11
	voice.play()
	var result := {"ok":true,"event":event,"fighter":str(fighter.fighter_id),"frame":frame,"voice":channel,"playing":voice.playing,"measurement":_measurements[str(fighter.fighter_id)+":"+event].duplicate(true)}
	history.append(result)
	if history.size()>96:history.pop_front()
	return result

func clear() -> void:
	for voice in voices:voice.stop()
	_last_event_frame.clear()

func snapshot() -> Dictionary:
	var playing := 0
	for voice in voices:
		if voice.playing:playing+=1
	return {"allocated_voices":voices.size(),"playing_voices":playing,"max_voices":2,"events":history.duplicate(true),"licensed_inputs":"none_original_arithmetic_only","human_mix_approved":false}
