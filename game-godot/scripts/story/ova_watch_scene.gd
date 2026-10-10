extends Control

## Continuous candidate adaptation of the SAME route graph, models, moves, combat and audio.
## A watch cursor is not Story completion. Stops at the first unimplemented/open-canon chapter.
const BATTLE := preload("res://scenes/battle/BattleScene.tscn")
var route: Dictionary = {}
var node_index := 0
var playing := true
var elapsed := 0.0
var _battle
var _watch_presenter
var _viewport: SubViewport
var _title: Label
var _subtitle: Label
var _copy: Label
var _pause: Button
var _session_before: Dictionary = {}
var _shot := -1
var _saved_progress := ""
var _swap_busy := false
var _closing := false
var _dialogue_speaker: Node2D
const SESSION_KEYS := ["mode", "arcade_active", "battle_eval_mode", "battle_eval_max_frames", "p1_fighter_id", "p2_fighter_id", "p1_body_variant", "p2_body_variant", "p1_is_cpu", "p2_is_cpu", "stocks", "match_type", "match_timer_seconds", "stage_id", "hazards_enabled", "items_enabled", "cpu_level", "team_mode", "battle_eval_finished", "battle_eval_frames", "battle_eval_result", "last_winner_slot"]

func _ready() -> void:
	route = CampaignRuntime.route_data(CampaignRuntime.watch_route_id)
	_saved_progress = JSON.stringify(CampaignRuntime.progress)
	for key in SESSION_KEYS:
		_session_before[key] = GameState.get(key)
	_build_ui()
	StoryDialogue.cue_started.connect(_on_dialogue_cue)
	await _present_node()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.025, 0.028, 0.06)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var container := SubViewportContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.offset_bottom = -170
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1280, 550)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.handle_input_locally = false
	_viewport.gui_disable_input = true
	container.add_child(_viewport)
	var panel := VBoxContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 32
	panel.offset_top = -165
	panel.offset_right = -32
	panel.add_theme_constant_override("separation", 6)
	add_child(panel)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 24)
	_title.text = str(route.get("watch_title", "Campaign Preview"))
	panel.add_child(_title)
	_subtitle = Label.new()
	panel.add_child(_subtitle)
	_copy = Label.new()
	_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_copy)
	var controls := HBoxContainer.new()
	panel.add_child(controls)
	_pause = _button(controls, "Pause", _toggle_pause)
	_button(controls, "Previous Chapter", func(): await seek(maxi(0, node_index - 1)))
	_button(controls, "Next Chapter", func(): await seek(node_index + 1))
	_button(controls, "Return to Story", func(): SceneRouter.go("story"))
	_pause.grab_focus()

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _toggle_pause() -> void:
	playing = not playing
	StoryDialogue.set_paused(not playing)
	_pause.text = "Pause" if playing else "Resume"
	if _battle != null:
		_battle.process_mode = Node.PROCESS_MODE_INHERIT if playing else Node.PROCESS_MODE_DISABLED
		for actor in _battle.fighters_root.get_children():
			if actor.get("model_3d") != null:
				actor.model_3d.get("_viewport").process_mode = Node.PROCESS_MODE_INHERIT if playing else Node.PROCESS_MODE_DISABLED

func seek(index: int) -> void:
	if _swap_busy:
		return
	var limit: int = route.get("nodes", []).size() - 1
	for i in range(route.get("nodes", []).size()):
		if not bool(route["nodes"][i].get("implemented", false)):
			limit = i
			break
	node_index = clampi(index, 0, limit)
	await _present_node()

func _present_node() -> void:
	var tree := get_tree()
	if _closing or tree == null: return
	_swap_busy = true
	StoryDialogue.cancel()
	_dialogue_speaker = null
	elapsed = 0
	_shot = -1
	if _watch_presenter != null:
		_watch_presenter.battle = null
		_watch_presenter = null
	if _battle != null:
		_battle.queue_free()
		_battle = null
		await tree.process_frame
		if _closing or not is_inside_tree(): return
	var nodes: Array = route.get("nodes", [])
	if nodes.is_empty():
		_swap_busy = false
		return
	var chapter: Dictionary = nodes[node_index]
	_subtitle.text = "%s · Draft adaptation · Preview" % chapter["title"]
	_copy.text = str(chapter.get("body", chapter.get("block_reason", "")))
	if not bool(chapter.get("implemented", false)):
		playing = false
		_pause.disabled = true
		_copy.text = "Preview ends here. " + str(chapter.get("block_reason", "Chapter production remains unfinished.")) + " Story saves and unlocks are unchanged."
		_swap_busy = false
		return
	_pause.disabled = false
	playing = true
	_pause.text = "Pause"
	GameState.mode = "ova"
	GameState.arcade_active = false
	GameState.team_mode = false
	GameState.battle_eval_mode = true
	GameState.battle_eval_max_frames = 100000000
	GameState.p1_fighter_id = str(route["anchor"])
	GameState.p2_fighter_id = str(chapter.get("opponent", route["recruitment_pairs"][0][0]))
	GameState.p1_body_variant = CampaignRuntime.watch_presentation
	GameState.p2_body_variant = "male" if CampaignRuntime.watch_presentation == "female" else "female"
	GameState.p1_is_cpu = true
	GameState.p2_is_cpu = true
	GameState.cpu_level = 3
	GameState.stocks = 99
	GameState.match_type = "stock_untimed"
	GameState.match_timer_seconds = 0
	GameState.hazards_enabled = false
	GameState.items_enabled = false
	GameState.stage_id = str(chapter.get("stage", "skyline-arena"))
	_battle = BATTLE.instantiate()
	_viewport.add_child(_battle)
	await tree.process_frame
	if _closing or not is_inside_tree(): return
	_battle.hud.visible = false
	_battle.set_process_unhandled_input(false)
	var form := "PRISMATIC_GRAY" if node_index >= 16 else "BASE"
	_watch_presenter = preload("res://scripts/story/v1_story_encounter.gd").new()
	var objective: String = chapter.get("objective_contract", "STOCK_WIN")
	if objective not in ["STOCK_WIN", "COSMIC_SURVIVAL"]:
		var released := []
		var essence := 0
		if chapter.has("puppets"):
			if node_index >= 13: released.append(chapter["puppets"]["yin"][0])
			if node_index >= 15:
				released.append(chapter["puppets"]["yin"][1])
				released.append(chapter["puppets"]["yang"][0])
			if node_index >= 16: released = chapter["puppets"]["yin"] + chapter["puppets"]["yang"]
			if node_index >= 11: essence = 1 + released.size()
		_watch_presenter.setup(_battle, {"node":chapter, "route_state":{"released":released, "essence":essence, "form":form}})
		_watch_presenter._label.visible = false
		_watch_presenter._marker.visible = false
		# Visual staging only: the watch clock never calls objective tick or issues a result.
		for actor in _watch_presenter.actors:
			actor.set_meta("watch_only_actor", true)
	_watch_presenter.set_form(_battle.fighter1, form)
	if chapter.has("first_loss"):
		_battle.fighter2.model_3d.set_cinematic_expression("grief")
		_battle.fighter2.model_3d.play_clip("aura_charge")
	if chapter.get("objective_contract") == "PRISMATIC_TRANSFORMATION":
		_battle.fighter1.model_3d.play_clip("aura_charge")
		_battle.fighter1.model_3d.set_cinematic_expression("determination")

	if chapter.get("objective_contract") == "COSMIC_SURVIVAL":
		_battle._setup_story_cosmic_encounter(chapter)
	if objective == "FIRST_LOSS":
		# Read-only dialogue blocking: gameplay CPU jumps must not displace faces.
		# This staging is confined to watch mode and never ticks Story objectives.
		for actor in _battle.fighters_root.get_children():
			actor.cpu.clear_simulated_inputs()
			actor.controls_enabled = false
			actor.is_cpu = false
			actor.dummy_mode = "idle"
			actor.move_runner.cancel()
			actor.velocity = Vector2.ZERO
			actor.position.y = _watch_presenter.ground_y - 2
			actor.set_physics_process(false)
			actor.model_3d.play_clip("story_dialogue_neutral")
	if chapter["kind"] != "STORY_BATTLE":
		_battle.fighter1.controls_enabled = false
		_battle.fighter2.controls_enabled = false
		_battle.fighter1.cpu.clear_simulated_inputs()
		_battle.fighter2.cpu.clear_simulated_inputs()
		_battle.fighter1.position = Vector2(-70, 180)
		_battle.fighter2.position = Vector2(100, 180)
		_battle.fighter1.model_3d.play_clip("idle")
		_battle.fighter1.model_3d.set_cinematic_expression(str(chapter.get("expression", "determination")))
	StoryDialogue.begin(str(chapter["id"]),"watch")
	StoryDialogue.watch_phase("pre")
	_swap_busy = false

func _process(delta: float) -> void:
	if _swap_busy or not playing or _battle == null:
		return
	elapsed += delta
	var chapter: Dictionary = route["nodes"][node_index]
	var duration := maxf(float(chapter.get("watch_seconds",14)),StoryDialogue.watch_duration(str(chapter["id"])) + 2.0)
	var shot := int(elapsed / (duration / 3.0))
	if shot != _shot:
		_shot = shot
		if shot == 1: StoryDialogue.watch_phase("mid")
		if shot >= 2: StoryDialogue.watch_phase("post")
		var battle_camera = _battle.get("_battle_camera")
		if battle_camera != null:
			battle_camera.set_process(false)
			battle_camera.set_physics_process(false)
		var camera := _battle.get_node_or_null("Camera2D") as Camera2D
		if camera != null:
			var closeup: bool = chapter["kind"] != "STORY_BATTLE"
			camera.zoom = Vector2.ONE * (1.5 if chapter.get("objective_contract") == "FIRST_LOSS" else 2.8 if closeup else 1.15 + 0.12 * shot)
	var camera := _battle.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		var closeup: bool = chapter["kind"] != "STORY_BATTLE"
		var target: Vector2 = (_dialogue_speaker.position if _dialogue_speaker != null and is_instance_valid(_dialogue_speaker) and StoryDialogue.is_busy() else _battle.fighter1.position if closeup else (_battle.fighter1.position + _battle.fighter2.position) * 0.5) + Vector2(0, -60 if closeup else -45)
		camera.position = camera.position.lerp(target, 1.0 - exp(-delta * 4.0))
	if elapsed >= duration and not StoryDialogue.is_busy():
		if node_index + 1 < route["nodes"].size():
			await seek(node_index + 1)
		else:
			playing = false

func _exit_tree() -> void:
	_closing = true
	StoryDialogue.cancel()
	if _watch_presenter != null:
		_watch_presenter.battle = null
		_watch_presenter = null
	for key in _session_before:
		GameState.set(key, _session_before[key])
	# CPU synthesis uses global actions; clear them on exit to leave human gameplay clean.
	for slot in range(1, 10):
		for action in ["left", "right", "jump", "attack", "special", "shield", "grab"]:
			var name := "p%d_%s" % [slot, action]
			if InputMap.has_action(name):
				Input.action_release(name)

func _on_dialogue_cue(cue: Dictionary) -> void:
	if StoryDialogue.context != "watch" or _battle == null: return
	if str(cue.node_id) != str(route.nodes[node_index].id): return
	_dialogue_speaker = null
	if cue.get("representation") == "memory_echo": return
	for actor in _battle.fighters_root.get_children():
		if actor.fighter_id != cue.speaker_id: continue
		_dialogue_speaker = actor
		var expression: String = {"grief":"grief","strained":"shock","soft":"calm"}.get(cue.performance,"determination")
		actor.model_3d.set_cinematic_expression(expression)
		if route.nodes[node_index].get("objective_contract","") == "FIRST_LOSS": actor.model_3d.play_clip("story_dialogue_intense" if cue.performance in ["grief","strained"] else "story_dialogue_neutral")
		break
