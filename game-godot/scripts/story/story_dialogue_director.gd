extends CanvasLayer

## Presentation only. No receipt, save, fighter state or unlock authority.
signal cue_started(cue: Dictionary)
signal sequence_finished
const DATA := "res://data/story/dialogue/v1/"
var cues: Dictionary = {}
var nodes: Dictionary = {}
var voice_assets: Dictionary = {}
var settings := {"subtitles":true,"voice":true,"font_size":23,"reading_rate":3.0,"voice_volume":0.75,"element_volume":0.65,"music_volume":0.65,"reduced_flash":false,"reduced_shake":false}
var node_id := ""
var context := ""
var history: Array = []
var _queue: Array = []
var _seen: Dictionary = {}
var current: Dictionary = {}
var remaining := 0.0
var _manual_pause := false
var _panel: PanelContainer
var _name: Label
var _text: Label
var _voice: AudioStreamPlayer
var _generation := 0

func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	cues = _read_json(DATA+"cues.json").get("cues",{})
	nodes = _read_json(DATA+"nodes.json").get("nodes",{})
	voice_assets = _read_json(DATA+"voice_assets.json").get("assets",{})
	var cfg := ConfigFile.new()
	if cfg.load("user://story_presentation.cfg") == OK:
		for key in settings: settings[key] = cfg.get_value("presentation",key,settings[key])
	_build_panel()
	_voice = AudioStreamPlayer.new()
	_voice.name = "TemporaryDialogueVoice"
	_voice.bus = "Dialogue" if AudioServer.get_bus_index("Dialogue") >= 0 else "Master"
	add_child(_voice)
	call_deferred("_apply_accessibility")

func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null: return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.name = "StoryDialoguePanel"
	_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 32; _panel.offset_right = -32
	_panel.offset_top = -200; _panel.offset_bottom = -42
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018,0.023,0.04,0.97)
	style.content_margin_left = 18; style.content_margin_right = 18
	style.content_margin_top = 10; style.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel",style)
	add_child(_panel)
	var column := VBoxContainer.new(); _panel.add_child(column)
	_name = Label.new(); _name.add_theme_color_override("font_color",Color(1,0.83,0.35)); column.add_child(_name)
	_text = Label.new(); _text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size.y = 64; column.add_child(_text)
	var buttons := HBoxContainer.new(); column.add_child(buttons)
	for item in [["Advance · Tab",advance],["Skip dialogue · F6",skip_all],["Transcript · F7",show_transcript]]:
		var button := Button.new(); button.text = item[0]; button.pressed.connect(item[1]); buttons.add_child(button)
	_panel.hide()

func begin(id: String, mode: String = "battle") -> void:
	cancel()
	node_id = id; context = mode; _seen.clear(); _manual_pause = false
	_panel.offset_top = -350 if mode == "watch" else -200
	_panel.offset_bottom = -192 if mode == "watch" else -42

func fire(event: String, detail: Dictionary = {}) -> void:
	if not nodes.has(node_id): return
	for id in nodes[node_id]["events"].get(event,[]):
		if _seen.has(id): continue
		_seen[id] = true
		var cue: Dictionary = cues[id].duplicate(true)
		cue["trigger_detail"] = detail.duplicate(true)
		_queue.append(cue)
	if current.is_empty(): _next()

func is_busy() -> bool:
	return not current.is_empty() or not _queue.is_empty()

func _next() -> void:
	_voice.stop()
	if _queue.is_empty():
		current = {}; _panel.hide(); sequence_finished.emit(); return
	current = _queue.pop_front()
	remaining = reading_seconds(current)
	var asset := str(current.get("voice_asset",""))
	var replacement: Dictionary = voice_assets.get(str(current.cue_id),{})
	if bool(replacement.get("distribution_cleared",false)): asset=str(replacement.get("path",asset))
	var voice_ok := false
	if bool(settings["voice"]) and FileAccess.file_exists(asset):
		var stream := AudioStreamWAV.load_from_file(asset)
		if stream != null:
			_voice.stream = stream
			_voice.volume_db = linear_to_db(maxf(0.0001,float(settings["voice_volume"])))
			_voice.play(); remaining = maxf(remaining,stream.get_length()+0.35); voice_ok = true
	_name.text = str(current["speaker"]) + (" · memory" if current.get("representation") == "memory_echo" else "") + " · Draft dialogue" + (" · Temporary synthetic voice" if voice_ok else "")
	_text.text = str(current["subtitle"])
	_text.add_theme_font_size_override("font_size",clampi(int(settings["font_size"]),18,34))
	_text.visible = bool(settings["subtitles"])
	_name.visible = bool(settings["subtitles"])
	_fit_panel()
	_panel.show()
	history.append({"cue_id":current["cue_id"],"node_id":node_id,"event":current["event"],"context":context,"voice_playing":voice_ok,"duration":remaining,"generation":_generation,"trigger_detail":current["trigger_detail"]})
	cue_started.emit(current)

func reading_seconds(cue: Dictionary) -> float:
	return maxf(2.0,str(cue.get("subtitle","")).split(" ",false).size()/clampf(float(settings["reading_rate"]),1.5,6.0)+0.6)

func _process(delta: float) -> void:
	if _voice == null: return
	var paused := get_tree().paused or _manual_pause
	_voice.stream_paused = paused
	if current.is_empty() or paused: return
	remaining -= delta
	if remaining <= 0: advance()

func _input(event: InputEvent) -> void:
	if get_tree().paused or _manual_pause: return
	if not is_busy() or not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_TAB: advance(); get_viewport().set_input_as_handled()
		KEY_F6: skip_all(); get_viewport().set_input_as_handled()
		KEY_F7: show_transcript(); get_viewport().set_input_as_handled()

func advance() -> void:
	if get_tree().paused or _manual_pause: return
	if current.is_empty(): return
	_voice.stop(); current = {}; _next()

func skip_all() -> void:
	if get_tree().paused or _manual_pause: return
	_queue.clear(); current = {}; _voice.stop(); _panel.hide(); sequence_finished.emit()

func cancel() -> void:
	_generation += 1; _queue.clear(); current = {}
	if _voice != null: _voice.stop(); _voice.stream = null
	if _panel != null: _panel.hide()

func set_paused(paused: bool) -> void:
	_manual_pause = paused
	if _voice != null: _voice.stream_paused = paused

func set_option(key: String, value: Variant) -> void:
	if not settings.has(key): return
	settings[key] = value
	if key == "voice" and not bool(value): _voice.stop()
	if key == "voice_volume": _voice.volume_db=linear_to_db(maxf(.0001,float(value)))
	if _text != null:
		_text.visible=bool(settings.subtitles);_name.visible=bool(settings.subtitles)
		_text.add_theme_font_size_override("font_size",clampi(int(settings.font_size),18,34))
	_fit_panel()
	_apply_accessibility()
	var cfg := ConfigFile.new()
	for k in settings: cfg.set_value("presentation",k,settings[k])
	cfg.save("user://story_presentation.cfg")

func transcript(id: String = "") -> String:
	if id.is_empty(): id = node_id
	var lines := PackedStringArray()
	for cue_id in nodes.get(id,{}).get("ordered_cues",[]):
		var cue: Dictionary = cues[cue_id]
		lines.append(str(cue["speaker"])+( " (memory)" if cue.get("representation")=="memory_echo" else "")+": "+str(cue["subtitle"]))
	return "\n\n".join(lines)

func show_transcript() -> void:
	var dialog := AcceptDialog.new(); dialog.title = "Draft Story transcript"
	var scroll := ScrollContainer.new(); scroll.custom_minimum_size = Vector2(880,360)
	var label := Label.new(); label.text = transcript(); label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 840; label.add_theme_font_size_override("font_size",23)
	scroll.add_child(label); dialog.add_child(scroll); add_child(dialog)
	var previously_paused := _manual_pause
	set_paused(true)
	dialog.confirmed.connect(func(): set_paused(previously_paused); dialog.queue_free())
	dialog.canceled.connect(func(): set_paused(previously_paused); dialog.queue_free())
	dialog.popup_centered(Vector2i(920,430))

func watch_phase(phase: String) -> void:
	for id in nodes.get(node_id,{}).get("ordered_cues",[]):
		if cues[id]["phase"] == phase: fire(str(cues[id]["event"]),{"watch_editorial_phase":phase,"read_only":true})

func watch_duration(id: String) -> float:
	var seconds := 1.0
	for cue_id in nodes.get(id,{}).get("ordered_cues",[]): seconds += reading_seconds(cues[cue_id])
	return seconds

func show_settings() -> void:
	var dialog := AcceptDialog.new(); dialog.title = "Dialogue and combat presentation"
	var column := VBoxContainer.new(); column.custom_minimum_size = Vector2(670,430)
	dialog.add_child(column)
	for item in [["Subtitles","subtitles"],["Temporary voices","voice"],["Subtitle size","font_size"],["Reading speed","reading_rate"],["Voice volume","voice_volume"],["Element effects volume","element_volume"],["Music volume","music_volume"],["Reduced flashes","reduced_flash"],["Reduced camera shake","reduced_shake"]]:
		var row := HBoxContainer.new(); column.add_child(row)
		var label := Label.new(); label.text = item[0]; label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(label)
		var button := Button.new(); row.add_child(button)
		var key: String = item[1]
		button.text = str(settings[key])
		button.pressed.connect(func():
			var value: Variant = settings[key]
			if value is bool: value = not value
			elif key == "font_size": value = 18 if int(value) >= 32 else int(value)+4
			elif key == "reading_rate": value = 1.5 if float(value) >= 5 else float(value)+0.5
			else: value = 0.0 if float(value) >= 0.99 else minf(1.0,float(value)+0.25)
			set_option(key,value); button.text = str(value))
	add_child(dialog); dialog.confirmed.connect(dialog.queue_free); dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(710,500))

func _fit_panel() -> void:
	if _text == null or _panel == null: return
	var size := clampi(int(settings.font_size),18,34)
	var font := _text.get_theme_font("font")
	var width := maxf(320,get_viewport().get_visible_rect().size.x-110)
	var text_height := font.get_multiline_string_size(_text.text,HORIZONTAL_ALIGNMENT_LEFT,width,size).y
	_panel.offset_top = _panel.offset_bottom-maxf(158,text_height+90)

func _apply_accessibility() -> void:
	var bus = get_node_or_null("/root/JuiceEventBus")
	if bus != null: bus.set_accessibility(bool(settings.reduced_flash),bool(settings.reduced_shake),false)
