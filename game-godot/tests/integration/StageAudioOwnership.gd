extends SceneTree
## Real stage builder, WAV streams and AudioStreamPlayer lifetime. Dummy output:
## no acoustic/native mixing approval and no claim that every shutdown leak ends.
const Bank=preload("res://scripts/audio/procedural_audio_bank.gd")
const Builder=preload("res://scripts/battle/stage_procedural_builder.gd")
const BED="res://assets/audio/procedural/stages/training-grid/bed.wav"
const HIT="res://assets/audio/procedural/shared/hit.wav"
class MixSettings extends Node:
	var settings={"music_volume":1.0}
var failures: Array=[]
var checks: Array=[]
var observations: Array=[]
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks.append({"check":label,"pass":ok})
	if not ok:failures.append(label)
func players(node: Node,category: String) -> Array:
	var result: Array=[]
	for child in node.get_children():
		if child is AudioStreamPlayer and child.get_meta("audio_category","")==category and not child.is_queued_for_deletion():result.append(child)
		result.append_array(players(child,category))
	return result
func frames(n: int) -> void:
	for i in range(n):await process_frame
func run() -> void:
	await process_frame
	var mix=MixSettings.new();mix.name="StoryDialogue";root.add_child(mix)
	var global_host=Node.new();root.add_child(global_host);Bank.ensure_bus_player(global_host)
	# Load actual retained WAV bytes without an editor/import campaign.
	Bank._cache[BED]=AudioStreamWAV.load_from_file(BED)
	Bank._cache[HIT]=AudioStreamWAV.load_from_file(HIT)
	var data={"id":"training-grid","mainPlatform":{"x":0,"y":280,"width":1062,"height":40},"audioBed":{"path":BED}}
	var stage=Node2D.new();root.add_child(stage)
	var built=Builder.build(stage,data,true)
	await frames(2)
	var initial=players(root,"music")
	check(built.audioBedLoaded and initial.size()==1,"one_real_stage_bed_started")
	check(initial.size()==1 and stage.is_ancestor_of(initial[0]),"stage_owns_ambience")
	observations.append({"phase":"first_build","music_players":initial.size(),"stage_music_children":players(stage,"music").size()})
	Builder.build(stage,data,true)
	await frames(2)
	check(players(root,"music").size()==1,"rebuild_does_not_layer_ambience")
	stage.queue_free();await frames(2)
	check(players(root,"music").is_empty(),"stage_exit_retires_ambience")
	observations.append({"phase":"after_stage_exit","music_players":players(root,"music").size()})
	var rematch=Node2D.new();root.add_child(rematch);Builder.build(rematch,data,true);await frames(2)
	check(players(root,"music").size()==1,"rematch_has_one_bed")
	rematch.queue_free();await frames(2)
	check(players(root,"music").is_empty(),"rematch_exit_has_no_bed")
	var transient=Node.new();root.add_child(transient)
	var hit=Bank.play(HIT,transient)
	check(bool(hit.get("playing",false)),"original_hit_sound_starts")
	transient.queue_free();await frames(2)
	check(players(root,"sfx").size()==1,"one_shot_tail_keeps_shared_owner")
	# Observe real mixer retirement while a paused voice's owner exits. This
	# must not change the separately verified shared punch-tail policy above.
	var owned=Node.new();root.add_child(owned)
	Bank.play(HIT,owned,-6,true)
	var owned_voice=players(owned,"sfx")[0]
	owned_voice.stream_paused=true
	var retirement: Array=[]
	owned_voice.tree_exiting.connect(func():retirement.append({"playing":owned_voice.playing,"stream_released":owned_voice.stream==null}))
	owned.queue_free();await frames(2)
	check(retirement.size()==1 and not retirement[0].playing and retirement[0].stream_released,"paused_voice_stops_and_releases_stream_before_owner_exit")
	var director=load("res://scripts/audio/AudioDirector.gd").new();root.add_child(director)
	var controlled=Node2D.new();root.add_child(controlled);Builder.build(controlled,data,true);await frames(2)
	director.on_pause()
	check(players(root,"music").all(func(p):return p.stream_paused),"director_pauses_scene_owned_music")
	director.on_resume()
	check(players(root,"music").all(func(p):return not p.stream_paused),"director_resumes_scene_owned_music")
	director.set_enabled(false);await frames(2)
	check(players(root,"music").is_empty(),"director_stop_reaches_scene_owned_music")
	check(players(root,"sfx").size()==1,"music_stop_preserves_punch_tail")
	var output=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.trim_prefix("--ordinary-output=")
	var result={"PASS":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Actual public WAV/stage/AudioDirector node lifetime; declared volume-only autoload fixture and Dummy output. Not gameplay, acoustic, native visual or complete shutdown acceptance."}
	var f=FileAccess.open(output.path_join("STAGE_AUDIO_OWNERSHIP.json"),FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close()
	print("STAGE_AUDIO_OWNERSHIP ","PASS" if failures.is_empty() else "FAIL"," failures=",failures)
	quit(0 if failures.is_empty() else 1)
