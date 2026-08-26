extends Node2D
const _DataLoader = preload("res://scripts/data/data_loader.gd")
const _CompetitiveRules = preload("res://scripts/combat/competitive_rules.gd")
const _BattleHudPanel = preload("res://scripts/ui/battle_hud_panel.gd")
const _BattleSim = preload("res://scripts/battle/battle_sim.gd")
const _HazardItemRuntime = preload("res://scripts/battle/hazard_item_runtime.gd")
const _BattleCamera = preload("res://scripts/battle/battle_camera_controller.gd")

@onready var fighters_root: Node2D = $Fighters
@onready var stage_root: Node2D = $Stage
@onready var hud: CanvasLayer = $HUD
@onready var countdown_label: Label = %CountdownLabel
@onready var p1_hud: Label = %P1Hud
@onready var p2_hud: Label = %P2Hud
@onready var ko_label: Label = %KoLabel

var fighter1
var fighter2
var blast: Dictionary = {}
var _active := false
var _paused := false
var _ko_lock := false
var _debug_hud
var _battle_sim
var _hazard_runtime
var _pause_panel: PanelContainer
var _pause_center: CenterContainer
var _p1_panel
var _p2_panel
var _timer_label: Label
var _time_remaining: float = 180.0
var _time_enabled := true
var _eval_mode := false
var _eval_max_frames := 2400
var _eval_frames := 0
var _pad_prompt: Label
var _controller_watchdog
var _flight_accum: float = 0.0
var _battle_camera
var _stage_camera_profile: Dictionary = {}
var _wave018_vis_accum: float = 0.0
var _wave018_last_telemetry_ids: Array = []

const FIGHTER_SCENE := preload("res://scenes/fighters/Fighter.tscn")
const DEBUG_HUD_SCENE := preload("res://scenes/ui/DebugHud.tscn")
const MOVE_LIST_PANEL := preload("res://scripts/ui/move_list_panel.gd")

var _move_list_panel: Control
var _training_pin_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_stage()
	_spawn_fighters()
	_setup_hud_panels()
	_apply_device_role()
	_time_remaining = float(GameState.match_timer_seconds)
	_time_enabled = GameState.match_timer_seconds > 0 and GameState.match_type != "stock_untimed"
	_battle_sim = _BattleSim.new()
	add_child(_battle_sim)
	_battle_sim.bind_fighters([fighter1, fighter2])
	if GameState.mode == "hazards" or GameState.hazards_enabled or GameState.items_enabled:
		_hazard_runtime = _HazardItemRuntime.new()
		add_child(_hazard_runtime)
		_hazard_runtime.hazards_enabled = GameState.hazards_enabled or GameState.mode == "hazards"
		_hazard_runtime.items_enabled = GameState.items_enabled or GameState.mode == "hazards"
		_hazard_runtime.configure(self, [fighter1, fighter2], GameState.match_seed, stage_root)
	var show_debug := _CompetitiveRules.show_debug_hud(GameState)
	if show_debug:
		_debug_hud = DEBUG_HUD_SCENE.instantiate()
		add_child(_debug_hud)
		_debug_hud.bind_fighters([fighter1, fighter2])
		_debug_hud.visible_debug = DeviceRoleRuntime.debug_hud_default
		if _debug_hud.has_node("Panel"):
			_debug_hud.get_node("Panel").visible = DeviceRoleRuntime.debug_hud_default
	fighter1.controls_enabled = false
	fighter2.controls_enabled = false
	_eval_mode = bool(GameState.battle_eval_mode)
	_eval_max_frames = int(GameState.battle_eval_max_frames)
	_eval_frames = 0
	MatchTelemetry.start_match({
		"p1": GameState.p1_fighter_id,
		"p2": GameState.p2_fighter_id,
		"stage": GameState.stage_id,
		"stocks": GameState.stocks,
		"timer": GameState.match_timer_seconds,
		"device_role": DeviceRoleRuntime.active_role,
		"eval_mode": _eval_mode,
	})
	var rec = get_node_or_null("/root/RuntimeFlightRecorder")
	if rec and rec.has_method("set_scene_instance"):
		rec.set_scene_instance(self)
	if _eval_mode:
		if countdown_label:
			countdown_label.visible = false
		fighter1.controls_enabled = true
		fighter2.controls_enabled = true
		_active = true
		return
	await _run_countdown()
	fighter1.controls_enabled = true
	fighter2.controls_enabled = true
	_active = true

func _apply_device_role() -> void:
	var cam := get_node_or_null("Camera2D") as Camera2D
	DeviceRoleRuntime.apply_layout_hint(cam)
	if hud:
		DeviceRoleRuntime.apply_to_battle_hud(hud)
	# Bind combat feedback cameras when FX allows shake.
	for f in [fighter1, fighter2]:
		if f and f.combat_feedback and cam:
			f.combat_feedback.bind_camera(cam)
	if cam and fighter1 and fighter2:
		if _battle_camera == null:
			_battle_camera = _BattleCamera.new()
			_battle_camera.name = "BattleCameraController"
			add_child(_battle_camera)
		_battle_camera.configure(cam, _stage_camera_profile, [fighter1, fighter2], blast)
	TouchInputManager._sync_overlay()

func _setup_hud_panels() -> void:
	var top := hud.get_node_or_null("TopBar") as HBoxContainer
	if top == null:
		return
	for c in top.get_children():
		c.visible = false
	_p1_panel = _BattleHudPanel.new()
	_p1_panel.name = "P1Panel"
	_p1_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_p1_panel.custom_minimum_size = Vector2(280, 72)
	top.add_child(_p1_panel)
	_timer_label = Label.new()
	_timer_label.name = "MatchTimer"
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_timer_label.add_theme_font_size_override("font_size", 26)
	_timer_label.custom_minimum_size = Vector2(110, 0)
	top.add_child(_timer_label)
	_p2_panel = _BattleHudPanel.new()
	_p2_panel.name = "P2Panel"
	_p2_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_p2_panel.custom_minimum_size = Vector2(280, 72)
	top.add_child(_p2_panel)
	var a1 := Color(fighter1.data.get("color", Color(1, 0.5, 0.2))) if fighter1 else Color(1, 0.5, 0.2)
	var a2 := Color(fighter2.data.get("color", Color(0.3, 0.6, 1.0))) if fighter2 else Color(0.3, 0.6, 1.0)
	_p1_panel.configure(fighter1.data.get("displayName", "P1"), a1, GameState.stocks, false)
	_p2_panel.configure(fighter2.data.get("displayName", "P2"), a2, GameState.stocks, true)
	_update_timer_label()
	_ensure_pad_prompt()

func _build_stage() -> void:
	var stage_data: Dictionary = GameState.load_stage(GameState.stage_id)
	if str(stage_data.get("id", "")) == "":
		stage_data["id"] = GameState.stage_id
	blast = stage_data.get("blastZones", {})
	_stage_camera_profile = stage_data.get("cameraProfile", {})
	var reduce := false
	var device = get_node_or_null("/root/DeviceRoleRuntime")
	if device != null:
		reduce = bool(device.reduce_motion)
	var builder = load("res://scripts/battle/stage_procedural_builder.gd")
	builder.build(stage_root, stage_data, reduce)

func _spawn_fighters() -> void:
	for c in fighters_root.get_children():
		c.queue_free()
	var stage_data: Dictionary = GameState.load_stage(GameState.stage_id)
	var spawns: Array = stage_data.get("spawnPoints", [])
	var s1 := Vector2(-200, 200)
	var s2 := Vector2(200, 200)
	var main: Dictionary = stage_data.get("mainPlatform", {})
	for sp in spawns:
		if sp.slot == 1:
			s1 = Vector2(sp.x, sp.y)
		if sp.slot == 2:
			s2 = Vector2(sp.x, sp.y)
	fighter1 = FIGHTER_SCENE.instantiate()
	fighter2 = FIGHTER_SCENE.instantiate()
	fighter1.name = "Fighter1"
	fighter2.name = "Fighter2"
	fighters_root.add_child(fighter1)
	fighters_root.add_child(fighter2)
	var p1_cpu := bool(GameState.p1_is_cpu) or bool(GameState.battle_eval_mode)
	var p2_cpu := bool(GameState.p2_is_cpu) or bool(GameState.battle_eval_mode)
	fighter1.configure(GameState.p1_fighter_id, 1, p1_cpu, GameState.stocks, s1)
	fighter2.configure(GameState.p2_fighter_id, 2, p2_cpu, GameState.stocks, s2)
	fighter1.global_position = s1
	fighter2.global_position = s2
	for f in [fighter1, fighter2]:
		f.platform_half_width = float(main.get("width", 800)) / 2.0
		f.platform_center_x = float(main.get("x", 0))
		# Wave018: battle must not inherit select-preview ghosts / stuck visibility.
		if f.has_method("ensure_visible_presentation"):
			f.ensure_visible_presentation()
		if f.model_3d != null and f.model_3d.has_method("heal_visibility_if_needed"):
			f.model_3d.heal_visibility_if_needed()
		if f.model_3d != null and f.model_3d.has_method("set_select_mode"):
			f.model_3d.set_select_mode(false)
	_emit_battle_visibility_telemetry()
	_connect_hitboxes(fighter1, fighter2)
	_connect_hitboxes(fighter2, fighter1)
	fighter1.koed.connect(_on_ko.bind(fighter1))
	fighter2.koed.connect(_on_ko.bind(fighter2))
	_update_hud()


func _emit_battle_visibility_telemetry() -> void:
	var telem = get_node_or_null("/root/Wave018VisibilityTelemetry")
	if telem == null or not telem.has_method("emit_battle_row"):
		return
	_wave018_last_telemetry_ids.clear()
	for f in [fighter1, fighter2]:
		if f == null or not is_instance_valid(f):
			continue
		var model = f.get("model_3d")
		var snap: Dictionary = {}
		if telem.has_method("snapshot_model"):
			snap = telem.snapshot_model(model)
		var inv: Dictionary = {}
		if f.has_method("assert_visible_body_invariant"):
			inv = f.assert_visible_body_invariant()
		var stocks_left: int = int(f.get("stocks"))
		var logic_active: bool = bool(inv.get("FIGHTER_LOGIC_ACTIVE", stocks_left > 0 and f.visible))
		var expected: bool = bool(inv.get("FIGHTER_EXPECTED_VISIBLE", logic_active and f.is_inside_tree()))
		var state_name: String = ""
		var sm = f.get("state_machine")
		if sm != null:
			state_name = str(sm.current_state)
		var ko_state: bool = (state_name == "ko") or (stocks_left <= 0)
		var respawn_state: bool = state_name == "respawn"
		var rid: String = str(telem.emit_battle_row({
			"fighter_slot": int(f.get("slot")),
			"fighter_id": str(f.get("fighter_id")),
			"logic_active": logic_active,
			"expected_visible": expected,
			"model_root_valid": bool(snap.get("model_root_valid", false)),
			"model_visible_in_tree": bool(snap.get("model_visible_in_tree", false)),
			"renderable_mesh_count": int(snap.get("renderable_mesh_count", 0)),
			"visible_renderable_mesh_count": int(snap.get("visible_renderable_mesh_count", 0)),
			"skeleton_valid": bool(snap.get("skeleton_valid", false)),
			"controller_valid": bool(snap.get("controller_valid", false)),
			"fallback_active": bool(snap.get("fallback_active", false)),
			"ko_state": ko_state,
			"respawn_state": respawn_state,
			"visibility_invariant_pass": bool(inv.get("PASS", true)),
		}))
		_wave018_last_telemetry_ids.append(rid)
	set_meta("wave018_last_telemetry_record_ids", _wave018_last_telemetry_ids.duplicate())


func _connect_hitboxes(attacker, defender) -> void:
	var hb: Area2D = attacker.get_node("Hitbox")
	var hurt: Area2D = defender.get_node("Hurtbox")
	hb.area_entered.connect(func(area: Area2D):
		if area != hurt or not hb.monitoring or not attacker.move_runner.is_active_phase():
			return
		var move = attacker._current_move
		if move.is_empty():
			move = _DataLoader.find_move(attacker.move_manifest, attacker.move_runner.current_move_id())
		if move.is_empty() or move.get("move_id") == "grab":
			return
		attacker.hit_resolver.resolve(attacker, defender, move, attacker.damage_percent)
	)

func _run_countdown() -> void:
	for i in range(3, 0, -1):
		if countdown_label:
			countdown_label.text = str(i)
		await get_tree().create_timer(1.0).timeout
	if countdown_label:
		countdown_label.text = "FIGHT!"
	await get_tree().create_timer(0.6).timeout
	if countdown_label:
		countdown_label.visible = false

func _physics_process(delta: float) -> void:
	_wave018_vis_accum += delta
	if _wave018_vis_accum >= 0.5:
		_wave018_vis_accum = 0.0
		_emit_battle_visibility_telemetry()
	if not _active or _paused:
		return
	if _eval_mode:
		_eval_frames += 1
		GameState.battle_eval_frames = _eval_frames
		if _eval_frames >= _eval_max_frames:
			_finish_eval_timeout()
			return
	if _hazard_runtime:
		_hazard_runtime.tick(delta)
	if _time_enabled:
		_time_remaining = maxf(0.0, _time_remaining - delta)
		_update_timer_label()
		if _time_remaining <= 0.0:
			_end_match_on_time()
			return
	_update_hud()
	_check_blast(fighter1)
	_check_blast(fighter2)
	_check_match_end()
	_flight_accum += delta
	if _flight_accum >= 0.2:
		_flight_accum = 0.0
		_emit_flight_snapshot()


func _emit_flight_snapshot() -> void:
	var rec = get_node_or_null("/root/RuntimeFlightRecorder")
	if rec == null or not rec.has_method("record_battlescene_snapshot"):
		return
	rec.record_battlescene_snapshot(self, fighter1, fighter2, {
		"active": _active,
		"paused": _paused,
		"eval_mode": _eval_mode,
		"eval_frames": _eval_frames,
		"time_remaining": _time_remaining,
	})

func _update_timer_label() -> void:
	if _timer_label == null:
		return
	if not _time_enabled:
		_timer_label.text = "?"
		return
	var secs := int(ceil(_time_remaining))
	_timer_label.text = "%d:%02d" % [secs / 60, secs % 60]

func _end_match_on_time() -> void:
	# Higher stocks wins; tie-break lower percent.
	var winner := 1
	if fighter2.stocks > fighter1.stocks:
		winner = 2
	elif fighter2.stocks == fighter1.stocks:
		winner = 1 if fighter1.damage_percent <= fighter2.damage_percent else 2
	_finish_match(winner)

func _check_blast(f) -> void:
	if f == null or f.stocks <= 0 or _ko_lock:
		return
	var pos: Vector2 = f.global_position
	if pos.x < blast.get("left", -9999) or pos.x > blast.get("right", 9999) or pos.y < blast.get("top", -9999) or pos.y > blast.get("bottom", 9999):
		_ko_lock = true
		if ko_label:
			ko_label.text = "%s KO!" % f.data.get("displayName", "?")
			ko_label.visible = true
		f.lose_stock()
		get_tree().create_timer(0.8).timeout.connect(func():
			if ko_label:
				ko_label.visible = false
			_ko_lock = false
		, CONNECT_ONE_SHOT)

func _on_ko(_f) -> void:
	pass

func _check_match_end() -> void:
	if fighter1.stocks <= 0 or fighter2.stocks <= 0:
		var winner := 2 if fighter1.stocks <= 0 else 1
		_finish_match(winner)

func _update_hud() -> void:
	if _p1_panel and fighter1:
		_p1_panel.update_from_fighter(fighter1)
	elif p1_hud and fighter1:
		p1_hud.text = "%s  %d%%  x%d  aura:%d" % [fighter1.data.get("displayName","P1"), int(fighter1.damage_percent), fighter1.stocks, int(fighter1.aura)]
	if _p2_panel and fighter2:
		_p2_panel.update_from_fighter(fighter2)
	elif p2_hud and fighter2:
		p2_hud.text = "%s  %d%%  x%d  aura:%d%s" % [fighter2.data.get("displayName","P2"), int(fighter2.damage_percent), fighter2.stocks, int(fighter2.aura), " (CPU L%d)" % GameState.cpu_level if GameState.p2_is_cpu else ""]

func _toggle_pause() -> void:
	_paused = not _paused
	# Freeze the SceneTree so CharacterBody2D physics / CPU / hazards stop.
	# Prior behavior only flipped controls_enabled + BattleSim.paused, so
	# fighters kept sliding under gravity/velocity while the pause panel showed
	# " keyboard/gamepad players saw a non-frozen "pause".
	var resuming := not _paused
	get_tree().paused = _paused
	if resuming:
		var ach := get_node_or_null("/root/AchievementRuntime")
		if ach != null and ach.has_method("report_event"):
			ach.report_event("pause_resume")
	if _battle_sim:
		_battle_sim.set_paused(_paused)
	if fighter1:
		fighter1.controls_enabled = not _paused
		if _paused:
			fighter1.velocity = Vector2.ZERO
	if fighter2:
		fighter2.controls_enabled = not _paused
		if _paused:
			fighter2.velocity = Vector2.ZERO
	_ensure_pause_panel()
	if _pause_panel:
		_pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
		_pause_panel.visible = _paused
	if _pause_center:
		_pause_center.visible = _paused
		_pause_center.process_mode = Node.PROCESS_MODE_ALWAYS
	if _move_list_panel != null and is_instance_valid(_move_list_panel) and _move_list_panel.visible and _paused:
		_move_list_panel.close_panel()
	# BattleScene must keep receiving ui_cancel/ui_accept while the tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	TouchInputManager._sync_overlay()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_ensure_pause_panel()
		_toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if _paused and event.is_action_pressed("ui_accept"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
	if event is InputEventJoypadButton and event.pressed:
		_refresh_pad_prompt()


func _ensure_pad_prompt() -> void:
	if _pad_prompt:
		return
	var Watchdog := load("res://scripts/input/controller_watchdog.gd")
	_controller_watchdog = Watchdog.new()
	add_child(_controller_watchdog)
	_controller_watchdog.controller_reconnected.connect(func(_id): _refresh_pad_prompt())
	_controller_watchdog.controller_disconnected.connect(func(_id): _refresh_pad_prompt())
	_pad_prompt = Label.new()
	_pad_prompt.name = "PadPrompt"
	_pad_prompt.text = "Press any gamepad button to wake P1/P2 pads (keyboard still works)."
	_pad_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pad_prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_pad_prompt.offset_top = -72
	_pad_prompt.add_theme_font_size_override("font_size", 16)
	_pad_prompt.process_mode = Node.PROCESS_MODE_ALWAYS
	hud.add_child(_pad_prompt)
	_refresh_pad_prompt()


func _refresh_pad_prompt() -> void:
	if _pad_prompt == null:
		return
	var pads: Array = Input.get_connected_joypads()
	_pad_prompt.visible = pads.is_empty() and not DisplayServer.is_touchscreen_available()


func _ensure_pause_panel() -> void:
	if _pause_panel:
		return
	## Wave020 CP2: centered pause shell (not bottom-right clipped).
	var center := CenterContainer.new()
	center.name = "PauseCenter"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.process_mode = Node.PROCESS_MODE_ALWAYS
	hud.add_child(center)
	_pause_panel = PanelContainer.new()
	_pause_panel.name = "PausePanel"
	var vp := get_viewport().get_visible_rect().size
	_pause_panel.custom_minimum_size = Vector2(minf(420.0, vp.x * 0.55), minf(280.0, vp.y * 0.55))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.09, 0.16, 0.94)
	style.border_color = Color(0.95, 0.75, 0.2, 1.0)
	style.set_border_width_all(3)
	style.set_content_margin_all(18)
	_pause_panel.add_theme_stylebox_override("panel", style)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	v.add_child(title)
	var resume_btn := Button.new()
	resume_btn.text = "Resume"
	resume_btn.pressed.connect(_toggle_pause)
	v.add_child(resume_btn)
	var rematch_btn := Button.new()
	rematch_btn.text = "Rematch"
	rematch_btn.pressed.connect(_on_pause_rematch)
	v.add_child(rematch_btn)
	var move_list_btn := Button.new()
	move_list_btn.text = "Move List / Command Guide"
	move_list_btn.pressed.connect(_open_move_list_from_pause)
	v.add_child(move_list_btn)
	var menu_btn := Button.new()
	menu_btn.text = "Return to Menu"
	menu_btn.pressed.connect(_on_pause_return_menu)
	v.add_child(menu_btn)
	_pause_panel.add_child(v)
	center.add_child(_pause_panel)
	_pause_panel.visible = false
	_pause_center = center


func _open_move_list_from_pause() -> void:
	TouchInputManager._sync_overlay()
	if _move_list_panel == null or not is_instance_valid(_move_list_panel):
		_move_list_panel = MOVE_LIST_PANEL.new()
		_move_list_panel.name = "MoveListPanel"
		_move_list_panel.process_mode = Node.PROCESS_MODE_ALWAYS
		hud.add_child(_move_list_panel)
		_move_list_panel.pin_requested.connect(_on_move_list_pin)
		_move_list_panel.closed.connect(func(): pass)
	var fid := ""
	if fighter1 != null and "fighter_id" in fighter1:
		fid = str(fighter1.fighter_id)
	elif GameState.p1_fighter_id:
		fid = str(GameState.p1_fighter_id)
	else:
		fid = "ember-vale"
	_move_list_panel.open_for_fighter(fid)


func _on_move_list_pin(entry: Dictionary) -> void:
	if _training_pin_label == null or not is_instance_valid(_training_pin_label):
		_training_pin_label = Label.new()
		_training_pin_label.name = "PinnedMoveReminder"
		_training_pin_label.position = Vector2(24, 120)
		_training_pin_label.add_theme_font_size_override("font_size", 16)
		_training_pin_label.modulate = Color(1.0, 0.9, 0.45)
		_training_pin_label.process_mode = Node.PROCESS_MODE_ALWAYS
		hud.add_child(_training_pin_label)
	var glyphs: Dictionary = entry.get("input_glyphs", {})
	_training_pin_label.text = "TRY THIS: %s  %s" % [
		str(entry.get("display_name", "")),
		str(glyphs.get("compact", "")),
	]
	_training_pin_label.visible = true


func _clear_pause_for_nav() -> void:
	_paused = false
	get_tree().paused = false
	if _battle_sim:
		_battle_sim.set_paused(false)
	if _pause_panel:
		_pause_panel.visible = false
	process_mode = Node.PROCESS_MODE_INHERIT
	TouchInputManager._sync_overlay()


func _on_pause_rematch() -> void:
	_clear_pause_for_nav()
	GameState.reset_match()
	SceneRouter.go("battle")


func _on_pause_return_menu() -> void:
	_clear_pause_for_nav()
	SceneRouter.go("main_menu")


func _finish_match(winner: int) -> void:
	_active = false
	GameState.last_winner_slot = winner
	MatchTelemetry.record_match_end(winner)
	if _eval_mode:
		_complete_eval(winner, "stocks_or_time")
		return
	if not GameState.battle_eval_mode:
		GameState.record_career_result(winner)
		if GameState.mode == "challenges":
			var p1_stocks: int = int(fighter1.stocks) if fighter1 else 0
			var p2_dmg: float = float(fighter2.damage_percent) if fighter2 else 0.0
			GameState.resolve_challenge(winner, p1_stocks, p2_dmg)
	get_tree().create_timer(0.5).timeout.connect(func(): SceneRouter.go("results"), CONNECT_ONE_SHOT)


func _complete_eval(winner: int, reason: String) -> void:
	GameState.battle_eval_finished = true
	GameState.battle_eval_result = {
		"ok": true,
		"winner_slot": winner,
		"reason": reason,
		"frames": _eval_frames,
		"p1": GameState.p1_fighter_id,
		"p2": GameState.p2_fighter_id,
		"p1_stocks": fighter1.stocks if fighter1 else -1,
		"p2_stocks": fighter2.stocks if fighter2 else -1,
		"p1_pct": fighter1.damage_percent if fighter1 else -1.0,
		"p2_pct": fighter2.damage_percent if fighter2 else -1.0,
		"cpu_level": GameState.cpu_level,
		"seed": GameState.match_seed,
		"stage": GameState.stage_id,
		"hidden_state_cheat": false,
		"observation_cpu": true,
	}
	_active = false


func _finish_eval_timeout() -> void:
	var winner := 1
	if fighter2 and fighter1:
		if fighter2.stocks > fighter1.stocks:
			winner = 2
		elif fighter2.stocks == fighter1.stocks:
			winner = 1 if fighter1.damage_percent <= fighter2.damage_percent else 2
	GameState.last_winner_slot = winner
	_complete_eval(winner, "frame_cap")
