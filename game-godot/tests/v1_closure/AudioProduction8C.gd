extends SceneTree
## Actual original PCM validation and compact owner listening samples.
const Guard = preload("res://scripts/audio/guard_audio_8c.gd")
const Form = preload("res://scripts/audio/transformation_audio_8c.gd")
var output := ""
func _init() -> void:call_deferred("run")
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var rows: Array=[];var failures: Array=[];var unique: Dictionary={};var files: Array=[]
	var directory:=output.path_join("listening");DirAccess.make_dir_recursive_absolute(directory)
	for fid in Guard.IDS:
		for category in ["guard","transformation","party"]:
			var listening:=PackedByteArray()
			var events: Array=Guard.EVENTS if category=="guard" else Form.PARTY_EVENTS if category=="party" else ["gather","climax","reveal","cancel"]
			for stage in ([0] if category=="guard" else [3] if category=="party" else [1,2]):
				for event in events:
					var stream: AudioStreamWAV=Guard._synthesize(fid,event) if category=="guard" else Form.synthesize(fid,stage,event)
					var pcm:=stream.data;var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(pcm);var digest:=hash.finish().hex_encode()
					var peak:=0.0;var squares:=0.0
					for sample in range(pcm.size()/2):
						var v:=float(pcm.decode_s16(sample*2))/32768;peak=maxf(peak,absf(v));squares+=v*v
					var key:String=fid+":"+category+":"+str(stage)+":"+event
					if unique.has(digest) or peak>.62001 or peak<=0 or pcm.decode_s16(0)!=0 or pcm.decode_s16(pcm.size()-2)!=0:failures.append(key)
					unique[digest]=true
					rows.append({"fighter":fid,"category":category,"stage":stage,"event":event,"sha256_pcm":digest,"peak_linear":peak,"rms_linear":sqrt(squares/(pcm.size()/2)),"samples":pcm.size()/2,"sample_rate":22050})
					listening.append_array(pcm);var gap:=PackedByteArray();gap.resize(22050/4*2);listening.append_array(gap)
			var sample:=AudioStreamWAV.new();sample.format=AudioStreamWAV.FORMAT_16_BITS;sample.mix_rate=22050;sample.data=listening
			var path:=directory.path_join(fid+"_"+category+".wav");var err:=sample.save_to_wav(path)
			if err!=OK:failures.append(path+":write")
			files.append({"path":path,"sha256":FileAccess.get_sha256(path),"bytes":FileAccess.get_file_as_bytes(path).size(),"ordered_events":events,"stages":[0] if category=="guard" else [3] if category=="party" else [1,2]})
	var f=FileAccess.open(output.path_join("audio_production_8c.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":failures.is_empty(),"rows":rows,"failures":failures,"files":files,"source":"Original arithmetic only; no external recordings/models/actors/samples","listening_status":"UNREVIEWED_HUMAN_MIX_PENDING","scope":"Measured standalone PCM. Not integrated mix loudness/device/hearing-safety acceptance."},"\t"));f.close();quit(0 if failures.is_empty() else 1)
