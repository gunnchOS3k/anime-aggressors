extends "res://tests/integration/TrainingLifecycle.gd"
## Actual guide UI + physical keyboard events in an isolated Training profile.
## No move/aura/contact/position/state grant. Idle dummy is declared practice
## setup, not active-CPU, native visual, controller-device or combo acceptance.
const Glyphs = preload("res://scripts/ui/input_glyph_presenter.gd")
const Catalog = preload("res://scripts/ui/move_list_catalog.gd")
var control_rows: Array = []
var started_moves: Array = []
var saved_bindings: Dictionary = {}
var physical_held: Array[int] = []
var profile_hash_before := ""

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.trim_prefix("--ordinary-output=")
	if output.is_empty() or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Isolated Training profile required"); quit(2); return
	profile_hash_before = _profile_hash()
	for suffix in ["attack", "special", "shield", "grab", "dodge", "jump"]:
		var action: String = "p1_" + suffix
		saved_bindings[action] = _copy_events(action)
	var campaign = root.get_node("CampaignRuntime")
	var story_before := JSON.stringify(campaign.progress)
	_check_catalogue_guidance()
	_check_live_binding_labels()
	# Remap in memory only. Never call persisted remapping or edit owner files.
	_replace_keyboard("p1_attack", KEY_Q)
	check(Glyphs.glyphs_for_command("attack_neutral", "keyboard").compact == "[Q]", "guide_reads_remapped_keyboard_InputMap")
	var temporary_attack: Array = _copy_events("p1_attack")
	for event in InputMap.action_get_events("p1_attack"):
		if event is InputEventKey: InputMap.action_erase_event("p1_attack", event)
	check(Glyphs.glyphs_for_command("attack_neutral", "keyboard").compact.contains("unbound"), "missing_keyboard_binding_is_explicit_not_invented_J")
	_restore_events("p1_attack", temporary_attack)
	check(Glyphs.glyphs_for_command("not_a_real_command", "keyboard").compact == "[NOT_A_REAL_COMMAND]", "unknown_command_fallback_stays_explicit")
	var temporary_special: Array = _copy_events("p1_special")
	for event in InputMap.action_get_events("p1_special"):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion: InputMap.action_erase_event("p1_special", event)
	var pad := InputEventJoypadButton.new()
	pad.device = 0; pad.button_index = JOY_BUTTON_RIGHT_SHOULDER
	InputMap.action_add_event("p1_special", pad)
	check(Glyphs.glyphs_for_command("special_neutral", "gamepad").compact == "[RB/R1]", "controller_glyph_reads_actual_remapped_button")
	_restore_events("p1_special", temporary_special)
	var gs = root.get_node("GameState")
	gs.begin_training()
	gs.p1_fighter_id = "kaia-windrow"; gs.p1_body_variant = "female"
	gs.p2_fighter_id = "rook-ironside"; gs.p2_body_variant = "male"
	gs.training_dummy_mode = "idle"; gs.stage_id = "training-grid"
	root.get_node("SceneRouter").go("training_battle")
	check(await wait_route("TrainingBattleScene.tscn"), "actual_training_scene_loaded")
	if not route_is("TrainingBattleScene.tscn"): finish(); return
	var training = current_scene
	await frames(120)
	var p = training.fighter1
	check(p.fighter_id == "kaia-windrow" and p.model_3d.get_body_variant() == "female" and training.fighter2.model_3d.get_body_variant() == "male", "declared_fighter_and_body_presentations_load")
	check(training.fighter2.dummy_mode == "idle" and not training.fighter2.is_cpu, "declared_idle_practice_target_not_CPU_proof")
	p.move_runner.move_started.connect(func(move: String): started_moves.append({"move":move, "frame":Engine.get_physics_frames(), "activation":p.move_runner.activation_id}))
	await click(training._move_list_btn)
	var panel = training._move_list_panel
	check(panel != null and panel.visible, "actual_guide_opens")
	if panel == null or not panel.visible: finish(); return
	check(_select_move(panel, "heavy_attack"), "canonical_heavy_selected_from_actual_catalogue")
	var heavy_text: String = panel._glyph_label.text
	check(heavy_text.contains("[Q]") and heavy_text.contains("[K]") and not heavy_text.contains("[L]"), "actual_heavy_UI_shows_Attack_Special_not_Shield")
	await click(panel._btn_pin)
	await click(panel._btn_close)
	check(not panel.visible and training._pin_reminder.text.contains("[Q]") and training._pin_reminder.text.contains("[K]"), "pinned_practice_reminder_uses_current_chord")
	check(await _legal_control(p), "real_grounded_control_before_heavy")
	var activation_before: int = p.move_runner.activation_id
	_keyboard(["attack", "special"])
	await frames(2)
	_keyboard([])
	control_rows.append({"phase":"heavy", "guide":heavy_text, "move":p.move_runner.current_move_id(), "activation":p.move_runner.activation_id, "state":p.state_machine.current_state})
	check(p.move_runner.current_move_id() == "heavy_attack" and p.move_runner.activation_id == activation_before + 1 and started_moves.size() == 1, "displayed_remapped_physical_chord_starts_exact_real_heavy_once")
	check(training._pin_reminder.text.contains("MOVE STARTED: heavy_attack"), "real_move_start_updates_practice_feedback")
	await frames(100)
	check(await _legal_control(p), "heavy_naturally_recovers")
	# A chord cannot manufacture a form before the real aura requirement.
	var base_form: String = p.get_current_form_id()
	var initial_count: int = p.get_transform_activations()
	_keyboard(["shield", "special", "attack"]); await frames(2); _keyboard([])
	await frames(8)
	check(p.get_current_form_id() == base_form and p.get_transform_activations() == initial_count and not p._transform_sequence_active, "low_aura_chord_cannot_grant_form")
	var before_charge: float = p.aura
	_keyboard(["shield", "special"])
	var charge_frames := 0
	for i in range(240):
		await physics_frame; charge_frames += 1
		if p.aura >= 80.0: break
	_keyboard([])
	await frames(4)
	check(p.aura >= 75.0 and p.aura > before_charge, "displayed_charge_chord_earns_real_Tier3_aura")
	check(await _legal_control(p), "released_charge_returns_real_control_before_fresh_chord")
	control_rows.append({"phase":"charge", "start_aura":before_charge, "end_aura":p.aura, "frames":charge_frames, "guide":Glyphs.glyphs_for_command("aura_charge", "keyboard")})
	await click(training._move_list_btn)
	var ladder: Array = p.get_forms_doc().get("form_ladder", [])
	check(ladder.size() >= 2, "fighter_has_existing_canonical_form_ladder")
	if ladder.size() < 2: finish(); return
	var target_form := str(ladder[1])
	check(_select_move(panel, "form_" + target_form.to_lower()), "existing_Awakened_form_selected_without_new_form_or_values")
	var form_text: String = panel._glyph_label.text
	check(form_text.contains("[L]") and form_text.contains("[K]") and form_text.contains("[Q]") and form_text.contains("Tier 3") and not form_text.contains("SHIELD_SPECIAL_ATTACK"), "real_form_UI_teaches_bound_chord_and_existing_tier")
	await click(panel._btn_close)
	check(await _legal_control(p), "real_control_before_transform")
	var before_form_aura: float = p.aura
	var before_form_count: int = p.get_transform_activations()
	_keyboard(["shield", "special", "attack"])
	await frames(2)
	check(p._transform_sequence_active, "fresh_displayed_chord_starts_existing_transform_pipeline")
	_keyboard([])
	for i in range(120):
		if p.get_transform_activations() > before_form_count: break
		await physics_frame
	check(p.get_current_form_id() == target_form and p.get_transform_activations() == before_form_count + 1 and not p._transform_sequence_active, "earned_charge_and_public_chord_complete_actual_named_form_once")
	check(p.aura <= before_form_aura - 25.0, "existing_successful_transform_cost_applies_without_aura_grant")
	control_rows.append({"phase":"form", "guide":form_text, "source_form":base_form, "target_form":target_form, "actual_form":p.get_current_form_id(), "before_aura":before_form_aura, "after_aura":p.aura, "activations":p.get_transform_activations()})
	await frames(30)
	check(p.get_transform_activations() == before_form_count + 1, "released_chord_cannot_repeat_activation")
	check(JSON.stringify(campaign.progress) == story_before, "control_practice_preserves_earned_Story_progress")
	finish()

func _check_catalogue_guidance() -> void:
	var ids: PackedStringArray = Catalog.roster_ids()
	check(ids.size() == 9, "all_nine_canonical_catalogues_present")
	var forms := 0
	for fighter in ids:
		var catalogue: Dictionary = Catalog.build_fighter_catalog(str(fighter))
		for entry in catalogue.get("entries", []):
			if str(entry.get("input_command", "")) != "shield_special_attack": continue
			forms += 1
			for device in ["keyboard", "gamepad", "touch"]:
				var glyph: Dictionary = Glyphs.enrich_entry(entry, device).input_glyphs
				check(not glyph.compact.contains("SHIELD_SPECIAL_ATTACK") and glyph.compact.contains("Tier 3"), "%s_%s_%s_has_real_form_chord" % [fighter, entry.move_id, device])
	check(forms >= 18, "spectrum_and_cosmic_catalogue_forms_keep_their_existing_names")
	for command in ["throw_forward", "throw_back", "throw_up", "throw_down"]:
		var guide: Dictionary = Glyphs.glyphs_for_command(command, "keyboard")
		check(guide.tokens.has("ATK") and not guide.tokens.has("GRB") and guide.compact.contains("TARGET HELD"), command + "_teaches_actual_held_target_Attack_release")
	var dash: Dictionary = Glyphs.glyphs_for_command("attack_dash", "keyboard")
	check(dash.compact.contains("FULL") and not dash.compact.contains("→→"), "dash_teaches_full_direction_not_double_tap")
	check(Glyphs.glyphs_for_command("aura_charge", "touch").compact.contains("AURA●") and Glyphs.glyphs_for_command("shield_special_attack", "touch").compact.contains("SHD●"), "existing_touch_charge_shortcut_and_multitouch_chord_remain_visible")

func _check_live_binding_labels() -> void:
	for row in [["grab","grab"], ["dodge","dodge"], ["jump","jump"], ["attack_neutral","attack"], ["special_neutral","special"]]:
		var key := _physical_key("p1_" + str(row[1]))
		check(key > 0 and Glyphs.glyphs_for_command(str(row[0]), "keyboard").compact.contains(OS.get_keycode_string(key)), str(row[0]) + "_keyboard_label_matches_real_InputMap")
	var special_button := -1
	for event in InputMap.action_get_events("p1_special"):
		if event is InputEventJoypadButton: special_button = event.button_index; break
	check(special_button == JOY_BUTTON_B and Glyphs.glyphs_for_command("special_neutral", "gamepad").compact == "[B/○]", "current_Special_controller_binding_is_B_not_stale_Y")

func _select_move(panel, move: String) -> bool:
	for index in panel._list.item_count:
		if panel._list.is_item_disabled(index): continue
		panel._list.select(index); panel._list.item_selected.emit(index)
		if str(panel._current_entry().get("move_id", "")) == move: return true
	return false

func _legal_control(actor) -> bool:
	for i in range(180):
		if actor.is_on_floor() and actor.state_machine.can_attack() and actor._hitstop <= 0.0 and not actor.move_runner.active: return true
		await physics_frame
	return false

func _keyboard(actions: Array) -> void:
	var codes: Array[int] = []
	for action in actions:
		var code := _physical_key("p1_" + str(action))
		check(code > 0, "physical_binding_exists_for_" + str(action))
		if code > 0 and not codes.has(code): codes.append(code)
	for code in physical_held:
		if not codes.has(code): _key_event(code, false)
	for code in codes:
		if not physical_held.has(code): _key_event(code, true)
	physical_held = codes
	inputs.append({"frame":Engine.get_physics_frames(), "physical_keycodes":codes.duplicate(), "logical_intent":actions.duplicate()})

func _key_event(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code; event.keycode = code; event.pressed = pressed
	Input.parse_input_event(event)

func _physical_key(action: String) -> int:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return int(event.physical_keycode) if event.physical_keycode != 0 else int(event.keycode)
	return 0

func _copy_events(action: String) -> Array:
	var events: Array = []
	for event in InputMap.action_get_events(action): events.append(event.duplicate())
	return events

func _replace_keyboard(action: String, code: int) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey: InputMap.action_erase_event(action, event)
	var event := InputEventKey.new()
	event.physical_keycode = code; event.keycode = code
	InputMap.action_add_event(action, event)

func _restore_events(action: String, events: Array) -> void:
	InputMap.action_erase_events(action)
	for event in events: InputMap.action_add_event(action, event.duplicate())

func _profile_hash() -> String:
	var path := "user://input_profiles.cfg"
	return FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "ABSENT"

func finish() -> void:
	_keyboard([])
	for action in saved_bindings:
		_restore_events(str(action), saved_bindings[action])
		var restored: Array = _copy_events(str(action))
		var expected: Array = saved_bindings[action]
		var exact := restored.size() == expected.size()
		for index in mini(restored.size(), expected.size()):
			exact = exact and restored[index].as_text() == expected[index].as_text() and restored[index].device == expected[index].device
		check(exact, str(action) + "_temporary_binding_restored_in_memory")
	check(_profile_hash() == profile_hash_before, "temporary_remap_never_writes_input_profile")
	var result := {"PASS":failures.is_empty(), "checks":checks, "failures":failures, "observations":control_rows, "move_starts":started_moves, "inputs":inputs,
		"scope":"Real Training guide UI, in-memory keyboard/pad remapping, physical keyboard events for Heavy, earned aura charge and existing named transform. Nine catalogues checked; runtime Kaia/female versus declared idle Rook/male only. Not all-body gameplay, active CPU, physical-controller, native visual, art, combo or human acceptance."}
	var file := FileAccess.open(output.path_join("TRAINING_CONTROLS.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  ")); file.close()
	print("TRAINING_CONTROLS ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks.size(), " failures=", failures)
	quit(0 if failures.is_empty() else 1)
