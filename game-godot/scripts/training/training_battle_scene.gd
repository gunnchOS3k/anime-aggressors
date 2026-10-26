extends Node2D
const _FrameDataTable = preload("res://scripts/combat/frame_data_table.gd")
const _DataLoader = preload("res://scripts/data/data_loader.gd")
const _BattleSim = preload("res://scripts/battle/battle_sim.gd")
const _FighterStates = preload("res://scripts/fighters/fighter_states.gd")
const _PracticeStats = preload("res://scripts/training/practice_stats.gd")
const _TrainingClock = preload("res://scripts/training/training_frame_clock.gd")

@onready var fighters_root: Node2D = $Fighters
@onready var stage_root: Node2D = $Stage
@onready var hud: CanvasLayer = $HUD

var fighter1
var fighter2
var _debug_hud
var _battle_sim
var _hit_log: Label
var _combo_p1: int = 0
var _combo_activation := -1
var _combo_seen:Dictionary={}
var _paused := false
var _slow_mo := false
var _freeze := false
var _frame_overlay: Label
var _practice = _PracticeStats.new()
var _practice_label: Label
var _practice_panel: PanelContainer
var _dummy_option: OptionButton
var _pinned_entry: Dictionary = {}
var _frame_clock
var _buffered_inputs: Dictionary = {}
var _injected_inputs: Array[String] = []
var _step_time_scale := 1.0

const FIGHTER_SCENE := preload("res://scenes/fighters/Fighter.tscn")
const DEBUG_HUD_SCENE := preload("res://scenes/ui/DebugHud.tscn")
const MOVE_LIST_PANEL := preload("res://scripts/ui/move_list_panel.gd")
const MOVE_BROWSER := preload("res://scripts/training/move_browser.gd")

var _move_list_panel: Control
var _move_browser: Control
var _pin_reminder: Label
var _move_list_btn: Button
var _pause_panel: PanelContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_meta("training_physics_clock", true)
	# Keep pause controls live without making the fighters inherit ALWAYS.
	fighters_root.process_mode = Node.PROCESS_MODE_PAUSABLE
	stage_root.process_mode = Node.PROCESS_MODE_PAUSABLE
	if GameState.has_method("begin_training") and str(GameState.mode) not in ["training", "tutorial"]:
		GameState.begin_training()
	_build_stage()
	_spawn_fighters()
	_battle_sim = _BattleSim.new()
	add_child(_battle_sim)
	_battle_sim.bind_fighters([fighter1, fighter2])
	_frame_clock = _TrainingClock.new()
	_frame_clock.frame_started.connect(_begin_physics_step)
	_frame_clock.frame_finished.connect(_end_physics_step)
	add_child(_frame_clock)
	var rules = load("res://scripts/combat/competitive_rules.gd")
	var show_debug := true
	if rules != null:
		show_debug = bool(rules.show_debug_hud(GameState))
	if show_debug:
		_debug_hud = DEBUG_HUD_SCENE.instantiate()
		add_child(_debug_hud)
		_debug_hud.bind_fighters([fighter1, fighter2])
		_debug_hud.visible_debug = true
		if _debug_hud.has_node("Panel"):
			_debug_hud.get_node("Panel").visible = true
	_hit_log = get_node_or_null("%HitLog") as Label
	_update_help()
	_ensure_frame_overlay()
	_ensure_move_list_access()
	if str(GameState.mode) == "training":
		_ensure_move_browser()
		_ensure_practice_controls()


func _ensure_move_list_access() -> void:
	if _move_list_btn != null:
		return
	_move_list_btn = Button.new()
	_move_list_btn.text = "Move List / Command Guide"
	_move_list_btn.position = Vector2(24, 48)
	_move_list_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_move_list_btn.pressed.connect(_open_training_move_list)
	if hud:
		hud.add_child(_move_list_btn)
	_pin_reminder = Label.new()
	_pin_reminder.position = Vector2(24, 112)
	_pin_reminder.add_theme_font_size_override("font_size", 15)
	_pin_reminder.modulate = Color(1.0, 0.88, 0.4)
	_pin_reminder.process_mode = Node.PROCESS_MODE_ALWAYS
	if hud:
		hud.add_child(_pin_reminder)


func _ensure_move_browser() -> void:
	if _move_browser != null:
		return
	_move_browser = MOVE_BROWSER.new()
	_move_browser.name = "TrainingMoveBrowser"
	_move_browser.process_mode = Node.PROCESS_MODE_ALWAYS
	if hud:
		hud.add_child(_move_browser)
	else:
		add_child(_move_browser)
	if _move_browser.has_signal("play_requested"):
		_move_browser.play_requested.connect(_on_browser_play)
	if fighter1 != null and "fighter_id" in fighter1 and _move_browser.has_method("bind_fighter"):
		_move_browser.bind_fighter(str(fighter1.fighter_id))


func _on_browser_play(fid: String, move_id: String, aura_amount: float, facing: int) -> void:
	if fighter1 == null:
		return
	if fighter1.has_method("training_play_move"):
		var played: Dictionary = fighter1.training_play_move(move_id, aura_amount, facing)
		if _move_browser != null and _move_browser.has_method("report_result"):
			var move: Dictionary = fighter1._current_move if "_current_move" in fighter1 else {}
			var fb: Dictionary = move.get("feedback", {})
			_move_browser.report_result({
				"result": played.get("active", move_id),
				"hitstop_frames": fb.get("hitstop_frames", move.get("hitstop_frames", 0)),
				"damage": move.get("damage", 0),
				"base_knockback": move.get("base_knockback", 0),
				"vfx_event": fb.get("vfx_event", ""),
				"sfx_event": fb.get("sfx_event", ""),
				"particle_profile": fb.get("particle_profile", ""),
			})


func _open_training_move_list() -> void:
	TouchInputManager._sync_overlay()
	if _move_list_panel == null or not is_instance_valid(_move_list_panel):
		_move_list_panel = MOVE_LIST_PANEL.new()
		_move_list_panel.name = "TrainingMoveList"
		_move_list_panel.process_mode = Node.PROCESS_MODE_ALWAYS
		if hud:
			hud.add_child(_move_list_panel)
		else:
			add_child(_move_list_panel)
		_move_list_panel.pin_requested.connect(_on_training_pin)
	var fid := str(GameState.p1_fighter_id) if GameState.p1_fighter_id else "ember-vale"
	if fighter1 != null and "fighter_id" in fighter1:
		fid = str(fighter1.fighter_id)
	_move_list_panel.open_for_fighter(fid)


func _on_training_pin(entry: Dictionary) -> void:
	_pinned_entry = entry.duplicate(true)
	var glyphs: Dictionary = entry.get("input_glyphs", {})
	if _pin_reminder:
		var goal := "land a confirmed hit" if float(entry.get("damage", 0.0)) > 0 else "perform the action"
		if entry.get("move_id", "") == "grab": goal = "acquire an actual target"
		if str(entry.get("move_id", "")).begins_with("form_"): goal = "form activation; completion tracking pending"
		_pin_reminder.text = "PRACTICE: %s  %s · %s" % [
			str(entry.get("display_name", "")),
			str(glyphs.get("compact", "")),
			goal,
		]
		_pin_reminder.visible = true

func _build_stage() -> void:
	var stage_id := GameState.stage_id if GameState.stage_id != "" else "training-grid"
	var stage_data: Dictionary = GameState.load_stage(stage_id)
	if str(stage_data.get("id", "")) == "":
		stage_data["id"] = stage_id
	var builder = load("res://scripts/battle/stage_procedural_builder.gd")
	builder.build(stage_root, stage_data, false)

func _spawn_fighters() -> void:
	var stage_data: Dictionary = GameState.load_stage(GameState.stage_id if GameState.stage_id != "" else "training-grid")
	var main: Dictionary = stage_data.get("mainPlatform", {})
	var s1 := Vector2(-180, 200)
	var s2 := Vector2(180, 200)
	fighter1 = FIGHTER_SCENE.instantiate()
	fighter2 = FIGHTER_SCENE.instantiate()
	fighters_root.add_child(fighter1)
	fighters_root.add_child(fighter2)
	fighter1.configure(GameState.p1_fighter_id, 1, false, 99, s1)
	fighter2.configure(GameState.p2_fighter_id, 2, false, 99, s2)
	fighter2.configure_training_dummy(GameState.training_dummy_mode, GameState.cpu_level)
	fighter1.global_position = s1
	fighter2.global_position = s2
	for f in [fighter1, fighter2]:
		f.use_training_physics_clock = true
		if f.model_3d != null: f.model_3d.set_training_physics_clock()
		f.platform_half_width = float(main.get("width", 800)) / 2.0
		f.platform_center_x = float(main.get("x", 0))
		if f.has_method("ensure_visible_presentation"):
			f.ensure_visible_presentation()
		if f.model_3d != null and f.model_3d.has_method("heal_visibility_if_needed"):
			f.model_3d.heal_visibility_if_needed()
	_connect_hits(fighter1, fighter2)
	_connect_hits(fighter2, fighter1)
	fighter2.hit_landed.connect(_on_dummy_hit)
	fighter2.state_machine.state_changed.connect(_on_dummy_control_state)
	fighter1.grab_event.connect(_on_grab)
	fighter2.grab_event.connect(_on_grab)
	for actor in [fighter1, fighter2]:
		actor.move_runner.move_started.connect(_practice_move_started.bind(actor))
		actor.move_runner.move_ended.connect(_practice_move_ended.bind(actor))
		actor.hit_resolver.hit_confirmed.connect(_practice_contact)
		actor.projectile_spawner.projectile_spawned.connect(_practice_projectile.bind(actor))
		actor.state_machine.state_changed.connect(_practice_control.bind(actor.slot))
		actor.grab_event.connect(_practice_grab.bind(actor.slot))

func _connect_hits(attacker, defender) -> void:
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

func _on_dummy_hit(info: Dictionary) -> void:
	var event_id:=str(info.get("combat_event_id",""))
	if not bool(info.get("confirmed_contact",false)) or event_id.is_empty() or _combo_seen.has(event_id):return
	_combo_seen[event_id]=true
	if _combo_seen.size()>64:_combo_seen.erase(_combo_seen.keys()[0])
	var result:=str(info.get("contact_result",""))
	if result!="hit" or bool(info.get("blocked",false)) or bool(info.get("armor_block",false)):
		_combo_p1 = 0
		_combo_activation=-1
		_log("%s %s" % [result.to_upper(),str(info.get("move_id",""))])
		return
	var activation:=int(info.get("attack_activation_id",-1))
	if not bool(info.get("defender_in_hitstun_before",false)) or _combo_p1==0:
		_combo_p1=1
	elif activation>=0 and activation!=_combo_activation:
		_combo_p1 += 1
	_combo_activation=activation
	var hint:=_authored_link_hint(info)
	_log("HIT %s combo:%d meter:%.1f%s" % [info.get("move_id", "?"), _combo_p1, float(info.get("defender_damage_after", 0.0)), " · "+hint if not hint.is_empty() else ""])

func _on_dummy_control_state(_from:String,to:String) -> void:
	if _combo_p1>0 and not _FighterStates.locks_actions(to):
		_combo_p1=0;_combo_activation=-1
		_log("Opponent recovered. Combo ended.")

func _authored_link_hint(info:Dictionary) -> String:
	if not is_instance_valid(fighter1) or fighter1.move_runner==null:return ""
	var runner=fighter1.move_runner
	if not runner.active or int(info.get("attack_activation_id",-1))!=runner.activation_id or str(info.get("contact_owner",""))!="melee":return ""
	for window in runner.move_data.get("cancel_windows",[]):
		if str(window.get("requires",""))!="hit_confirm" or str(window.get("to","")).is_empty() or runner.total_frame>int(window.get("end",-1)):continue
		var next_move:Dictionary=_DataLoader.find_move(fighter1.move_manifest,str(window.to))
		var command:=str(next_move.get("input_command",""))
		var input_label:=str({"attack_neutral":"Attack","attack_up":"Up + Attack","attack_down":"Down + Attack","attack_forward":"Side + Attack","attack_dash":"Dash + Attack"}.get(command,""))
		if not input_label.is_empty():return "On-hit link: "+input_label
	return ""

func _on_grab(info: Dictionary) -> void:
	_log("GRAB %s" % info.get("result", "?"))


func _practice_move_started(_move: String, actor) -> void:
	_practice.move_started(actor.slot, actor.move_runner.activation_id, actor.move_runner.move_data)
	if actor == fighter1 and _pinned_entry.get("move_id", "") == _move:
		_pin_reminder.text = "MOVE STARTED: %s · %s" % [_move, "awaiting actual contact" if float(_pinned_entry.get("damage", 0.0)) > 0 else "action observed"]


func _practice_move_ended(_move: String, actor) -> void:
	var runner = actor.move_runner
	var natural: bool = runner.phase == "recovery" and runner.frame_in_phase >= int(runner.move_data.get("recovery_frames", 0))
	_practice.move_ended(actor.slot, runner.activation_id, natural)


func _practice_contact(attacker, defender, info: Dictionary) -> void:
	if not _practice.contact(attacker.slot, defender.slot, info): return
	if attacker == fighter1 and _pinned_entry.get("move_id", "") == str(info.get("move_id", "")):
		var result := str(info.get("contact_result", ""))
		_pin_reminder.text = "%s: %s · applied %.2f%%" % [result.to_upper(), str(info.get("move_id", "")), float(info.get("damage_applied", 0.0))]
	if str(info.get("contact_result", "")) == "hit" and float(info.get("damage_applied", 0.0)) == 0.0:
		_log("Confirmed zero-damage contact: %s" % str(info.get("damage_zero_reason", "unspecified")))


func _practice_projectile(shot, actor) -> void:
	var instance: int = shot.get_instance_id()
	_practice.projectile_started(actor.slot, int(shot.move_data.get("_attack_activation_id", -1)), instance)
	shot.projectile_expired.connect(func():
		_practice.projectile_ended(instance, shot.frame_count >= shot.lifetime_frames and shot.intercepted_ids.is_empty())
	)


func _practice_control(_from: String, to: String, slot: int) -> void:
	if not _FighterStates.locks_actions(to): _practice.recovered(slot)


func _practice_grab(info: Dictionary, slot: int) -> void:
	_practice.grab(slot, str(info.get("result", "")))
	if slot == 1 and _pinned_entry.get("move_id", "") == "grab" and _pin_reminder:
		_pin_reminder.text = "GRAB %s · actual acquisition" % str(info.get("result", "?")).to_upper()


func _ensure_practice_controls() -> void:
	_practice_panel = PanelContainer.new()
	_practice_panel.name = "PracticeControls"
	_practice_panel.custom_minimum_size = Vector2(330, 0)
	var column := VBoxContainer.new()
	_practice_panel.add_child(column)
	_practice_label = Label.new()
	_practice_label.add_theme_font_size_override("font_size", 15)
	_practice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_practice_label.custom_minimum_size.x = 324
	column.add_child(_practice_label)
	var dummy := OptionButton.new()
	_dummy_option = dummy
	var modes := ["idle", "shield", "jump", "attack", "cpu", "di_in", "di_out"]
	for mode in modes: dummy.add_item("Dummy: " + mode)
	dummy.select(maxi(0, modes.find(fighter2.dummy_mode)))
	dummy.item_selected.connect(func(index):
		fighter2.configure_training_dummy(modes[index], GameState.cpu_level)
		GameState.training_dummy_mode = fighter2.dummy_mode
	)
	column.add_child(dummy)
	var reset := Button.new()
	reset.text = "Reset practice (respawn fighters)"
	reset.pressed.connect(_reset_practice)
	column.add_child(reset)
	hud.add_child(_practice_panel)


func _reset_practice() -> void:
	for actor in [fighter1, fighter2]:
		actor.reset_training_practice()
	_practice.clear()
	_combo_p1 = 0
	_combo_activation = -1
	_combo_seen.clear()
	_log("Practice reset. Existing respawn immunity lasts 1.2s; wait before attacking.")


func _refresh_practice_hud() -> void:
	if _practice_label == null or not is_instance_valid(fighter1) or not is_instance_valid(fighter2): return
	_practice_panel.position = Vector2(maxf(24, get_viewport_rect().size.x - 354), 24)
	var lines := PackedStringArray()
	lines.append("%s · stepped frames %d · queued taps %d" % ["PAUSED" if _paused or _freeze else "LIVE", _frame_clock.frames if _frame_clock != null else 0, _buffered_inputs.size()])
	for actor in [fighter1, fighter2]:
		var row: Dictionary = _practice.slot_stats(actor.slot)
		lines.append("P%d %s %.1f%% %s" % [actor.slot, actor.fighter_id, actor.damage_percent, "INVULNERABLE" if actor.invincible else ""])
		lines.append("Session hits %d · total %.2f%% · misses %d" % [row.hits, row.damage, row.whiffs])
		lines.append("Combo %d / %.2f%% · best %d" % [row.combo, row.combo_damage, row.best_combo])
		lines.append("Blocks %d · Perfect Guard %d · armor %d" % [row.blocks, row.perfect_guards, row.armor])
		lines.append("Last %s %s +%.2f%%" % [row.last_move, row.last_result, row.last_damage])
	_practice_label.text = "\n".join(lines)
	if _pinned_entry.get("move_id", "") == "aura_charge" and fighter1.state_machine.current_state == "aura_charge" and _pin_reminder:
		_pin_reminder.text = "AURA CHARGE OBSERVED · %.1f" % fighter1.aura

func _log(msg: String) -> void:
	if _hit_log:
		_hit_log.text = msg
	if _debug_hud:
		_debug_hud.push_log(msg)

func _update_help() -> void:
	if _hit_log:
		_hit_log.text = "Training — F1 HUD F2 hit | Pause: Esc/Back/Touch II | Move List | F3 pos F4 dmg F5 aura F7 clear F8 dummy F9 pause F10 slow F11 freeze F12 step"


func _toggle_pause() -> void:
	_paused = not _paused
	_apply_clock_pause()
	_ensure_pause_panel()
	if _pause_panel:
		_pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
		_pause_panel.visible = _paused
	if _move_list_panel != null and is_instance_valid(_move_list_panel) and _move_list_panel.visible and _paused:
		_move_list_panel.close_panel()
	process_mode = Node.PROCESS_MODE_ALWAYS
	TouchInputManager._sync_overlay()
	_log("PAUSED" if _paused else "RESUMED")


func _apply_clock_pause() -> void:
	var stopped := _paused or _freeze
	get_tree().paused = stopped
	if _battle_sim:
		_battle_sim.set_freeze(_freeze)
		_battle_sim.set_paused(stopped)
	# Pause preserves velocity, control ownership, hitstop and pending moves.
	# In particular it must not enable the tutorial's disabled practice target.
	if not stopped:
		_buffered_inputs.clear()
		if is_instance_valid(_frame_clock): _frame_clock.cancel()
		Engine.time_scale = 0.35 if _slow_mo else 1.0


func _request_physics_step() -> void:
	if not (_paused or _freeze) or _frame_clock == null: return
	if not _frame_clock.request_frame(): return
	_step_time_scale = Engine.time_scale
	# One step is one 60Hz simulation frame, including from slow motion.
	Engine.time_scale = 1.0


func _begin_physics_step() -> void:
	get_tree().paused = false
	_battle_sim.set_freeze(false)
	_battle_sim.set_paused(false)
	_battle_sim.step_frame()
	for action in _buffered_inputs:
		if not Input.is_action_pressed(action):
			Input.action_press(action, float(_buffered_inputs[action]))
			_injected_inputs.append(action)
	_buffered_inputs.clear()


func _end_physics_step(_delta: float) -> void:
	for action in _injected_inputs: Input.action_release(action)
	_injected_inputs.clear()
	Engine.time_scale = _step_time_scale
	_apply_clock_pause()
	_refresh_practice_hud()
	_log("STEPPED FULL PHYSICS FRAME %d" % _frame_clock.frames)


func _input(event: InputEvent) -> void:
	if not (_paused or _freeze) or event.is_echo(): return
	for slot in [1, 2]:
		for suffix in ["left", "right", "up", "down", "attack", "special", "jump", "shield", "dodge", "grab"]:
			var action := "p%d_%s" % [slot, suffix]
			if InputMap.has_action(action) and event.is_action_pressed(action):
				_buffered_inputs[action] = event.get_action_strength(action)


func _ensure_pause_panel() -> void:
	if _pause_panel:
		return
	_pause_panel = PanelContainer.new()
	_pause_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_pause_panel.custom_minimum_size = Vector2(420, 220)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.09, 0.16, 0.94)
	style.border_color = Color(0.95, 0.75, 0.2, 1.0)
	style.set_border_width_all(3)
	style.set_content_margin_all(18)
	_pause_panel.add_theme_stylebox_override("panel", style)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	var title := Label.new()
	title.text = "Training Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	v.add_child(title)
	var resume_btn := Button.new()
	resume_btn.text = "Resume"
	resume_btn.pressed.connect(_toggle_pause)
	v.add_child(resume_btn)
	var move_list_btn := Button.new()
	move_list_btn.text = "Move List / Command Guide"
	move_list_btn.pressed.connect(_open_training_move_list)
	v.add_child(move_list_btn)
	var menu_btn := Button.new()
	menu_btn.text = "Return to Training Menu"
	menu_btn.pressed.connect(_on_training_pause_return)
	v.add_child(menu_btn)
	_pause_panel.add_child(v)
	if hud:
		hud.add_child(_pause_panel)
	else:
		add_child(_pause_panel)
	_pause_panel.visible = false


func _on_training_pause_return() -> void:
	_restore_training_time()
	if _pause_panel:
		_pause_panel.visible = false
	process_mode = Node.PROCESS_MODE_INHERIT
	TouchInputManager._sync_overlay()
	SceneRouter.go("training")


func _restore_training_time() -> void:
	_paused = false
	_freeze = false
	_slow_mo = false
	if is_instance_valid(_frame_clock): _frame_clock.cancel()
	for action in _injected_inputs: Input.action_release(action)
	_injected_inputs.clear()
	_buffered_inputs.clear()
	if is_inside_tree():
		get_tree().paused = false
	if is_instance_valid(fighters_root): fighters_root.process_mode = Node.PROCESS_MODE_PAUSABLE
	if is_instance_valid(_battle_sim):
		_battle_sim.set_freeze(false)
		_battle_sim.set_paused(false)
	Engine.time_scale = 1.0


func _exit_tree() -> void:
	# Pause/slow/freeze are training-owned; a routed menu must remain usable.
	_restore_training_time()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F3:
				fighter1.reset_position()
				fighter2.reset_position()
				_practice.recovered(1)
				_practice.recovered(2)
			KEY_F4:
				fighter1.reset_damage()
				fighter2.reset_damage()
				_combo_p1 = 0
				_combo_activation = -1
				_practice.recovered(1)
				_practice.recovered(2)
			KEY_F5:
				fighter1.fill_aura()
			KEY_F7:
				fighter1.clear_aura()
			KEY_F8:
				_cycle_dummy()
			KEY_F9:
				_toggle_pause()
			KEY_F10:
				_slow_mo = not _slow_mo
				Engine.time_scale = 0.35 if _slow_mo else 1.0
				_log("SLOW-MO" if _slow_mo else "NORMAL SPEED")
			KEY_F11:
				_freeze = not _freeze
				_apply_clock_pause()
				_log("FREEZE" if _freeze else "UNFREEZE")
			KEY_F12:
				_request_physics_step()
	if event.is_action_pressed("ui_cancel"):
		_ensure_pause_panel()
		_toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if _paused and event.is_action_pressed("ui_accept"):
		_toggle_pause()
		get_viewport().set_input_as_handled()

func _cycle_dummy() -> void:
	var modes := ["idle", "shield", "jump", "attack", "cpu", "di_in", "di_out"]
	var idx := modes.find(fighter2.dummy_mode)
	idx = (idx + 1) % modes.size()
	fighter2.configure_training_dummy(modes[idx], GameState.cpu_level)
	GameState.training_dummy_mode = fighter2.dummy_mode
	if is_instance_valid(_dummy_option): _dummy_option.select(idx)
	_log("Dummy: %s" % fighter2.dummy_mode)


func _ensure_frame_overlay() -> void:
	if _frame_overlay != null:
		return
	_frame_overlay = Label.new()
	_frame_overlay.name = "FrameDataOverlay"
	_frame_overlay.position = Vector2(24, 86)
	_frame_overlay.add_theme_font_size_override("font_size", 16)
	if hud:
		hud.add_child(_frame_overlay)
	else:
		add_child(_frame_overlay)


func _process(_delta: float) -> void:
	_refresh_practice_hud()
	if _frame_overlay == null or fighter1 == null:
		return
	var move: Dictionary = fighter1._current_move if "_current_move" in fighter1 else {}
	if move.is_empty() and fighter1.move_manifest:
		move = _DataLoader.find_move(fighter1.move_manifest, fighter1.move_runner.current_move_id() if fighter1.move_runner else "")
	_frame_overlay.text = _FrameDataTable.overlay_line(move, fighter1.move_runner)
