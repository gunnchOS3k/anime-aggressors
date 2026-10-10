extends SceneTree
var failures: Array = []
var played: Dictionary = {}
func _init() -> void: call_deferred("_run")
func check(ok: bool, name: String) -> void:
	if not ok: failures.append(name); push_error(name)
func _run() -> void:
	await process_frame
	var d = root.get_node("StoryDialogue")
	var campaign = root.get_node("CampaignRuntime")
	var before := JSON.stringify(campaign.progress)
	check(d.nodes.size()==145 and d.cues.size()==1025,"complete_manifest")
	var previous_voice: bool = d.settings.voice
	d.settings.voice=false
	for id in d.nodes:
		d.begin(id,"watch")
		for event in d.nodes[id].events: d.fire(event,{"test_only":true})
		var expected: Array = d.nodes[id].ordered_cues
		var seen: Array = []
		while d.is_busy():
			seen.append(d.current.cue_id)
			played[d.current.cue_id] = {"status":"RUNTIME_PRESENTED_ISOLATED_EVENT_TEST","node_id":id,"event":d.current.event}
			check(d._text.text==d.current.subtitle,"subtitle:"+d.current.cue_id)
			check(d.remaining>=2,"readable:"+d.current.cue_id)
			check(not d._voice.playing,"missing_voice_fallback:"+d.current.cue_id)
			d.advance()
		check(seen.size()==expected.size(),"node_exact_once:"+id)
		for event in d.nodes[id].events: d.fire(event)
		check(not d.is_busy(),"deduplicated:"+id)
	d.begin("kaia-windrow:prologue","battle");d.fire("encounter_intro")
	var first: String = d.current.cue_id
	d.remaining=5
	paused=true;d._process(1);d.advance();d.skip_all()
	check(d.remaining==5 and d.current.cue_id==first,"pause_blocks_timer_and_input")
	paused=false;d.set_paused(true);d._process(1)
	check(d.remaining==5,"transcript_pause")
	d.set_paused(false);d.skip_all();check(not d.is_busy(),"skip_drains_queue")
	d.begin("kaia-windrow:prologue","battle");d.fire("encounter_intro")
	check(d.current.cue_id==first,"retry_restarts_seen_set")
	d.cancel();check(not d.is_busy() and not d._voice.playing,"cancel_stops_voice")
	d.settings.voice=previous_voice
	d.begin("kaia-windrow:prologue","battle");d.fire("encounter_intro")
	var locally_generated: bool = FileAccess.file_exists(str(d.current.voice_asset))
	check(d.history.back().voice_playing==locally_generated,"voice_or_missing_asset_fallback")
	d.set_paused(true);check(d._voice.stream_paused,"voice_pauses")
	d.cancel();d.set_paused(false)
	var saved_settings: Dictionary=d.settings.duplicate(true)
	for size in [18,34]:
		d.set_option("font_size",size)
		d.begin("juno-spark:first_loss","watch");d.fire("encounter_intro")
		check(d._text.get_theme_font_size("font_size")==size,"font_setting_"+str(size))
		var width=maxf(320,d.get_viewport().get_visible_rect().size.x-110)
		var height=d._text.get_theme_font("font").get_multiline_string_size(d._text.text,HORIZONTAL_ALIGNMENT_LEFT,width,size).y
		check(d._panel.offset_bottom-d._panel.offset_top>=height+90,"wrapped_caption_fits_"+str(size))
	d.set_option("reading_rate",1.5)
	var slow:float=d.reading_seconds({"subtitle":"one two three four five six seven eight nine ten eleven twelve"})
	d.set_option("reading_rate",6.0)
	check(slow>d.reading_seconds({"subtitle":"one two three four five six seven eight nine ten eleven twelve"}),"reading_speed_changes_duration")
	d.set_option("subtitles",false);check(not d._text.visible and not d._name.visible,"subtitle_toggle")
	d.set_option("reduced_flash",true);d.set_option("reduced_shake",true)
	var cfg:=ConfigFile.new()
	check(cfg.load("user://story_presentation.cfg")==OK and cfg.get_value("presentation","reduced_flash",false) and cfg.get_value("presentation","reduced_shake",false),"accessibility_settings_persist")
	for key in saved_settings:d.set_option(key,saved_settings[key])
	d.cancel()
	check(JSON.stringify(campaign.progress)==before,"presentation_watch_cannot_mutate_progress")
	var file := FileAccess.open("res://../artifacts/v1_closure/dialogue_performance/dialogue_runtime_test.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"ok":failures.is_empty(),"failures":failures,"nodes":145,"cues":played,"scope":"Isolated presentation events, not 145 human/ordinary playthroughs; voice sample locally loaded."},"  ")+"\n");file.close()
	print("DIALOGUE_PRODUCTION ","PASS" if failures.is_empty() else "FAIL", " cues=",played.size())
	quit(0 if failures.is_empty() else 1)
