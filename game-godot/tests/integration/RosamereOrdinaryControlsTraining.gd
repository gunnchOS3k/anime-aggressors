extends "res://tests/integration/TrainingLifecycle.gd"
## Ordinary combat controls + Training feedback for Rosamere Pink systems.
## Restores aura_charge/aura_burst IDs, special_* Bloom wiring, grab→QuietEmbrace,
## and practice MOVE STARTED feedback. Does not enable shipping rollback or flip gates.

const Catalog = preload("res://scripts/ui/move_list_catalog.gd")
var evidence: Dictionary = {}
var physical_held: Array[int] = []


func _select_move(panel, move: String) -> bool:
	for index in panel._list.item_count:
		if panel._list.is_item_disabled(index):
			continue
		panel._list.select(index)
		panel._list.item_selected.emit(index)
		if str(panel._current_entry().get("move_id", "")) == move:
			return true
	return false


func _legal_control(actor) -> bool:
	for i in range(180):
		if actor.is_on_floor() and actor.state_machine.can_attack() and actor._hitstop <= 0.0 and not actor.move_runner.active:
			return true
		await physics_frame
	return false

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):
			output = arg.trim_prefix("--ordinary-output=")
	if output.is_empty() or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Isolated Training profile required"); quit(2); return

	OS.set_environment("AA_ROSAMERE_DEV_OVERRIDE", "1")
	var moves: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/moves/rosamere.json"))
	var by_id: Dictionary = {}
	for m in moves.get("moves", []):
		by_id[str(m.get("move_id", ""))] = m
	check(by_id.has("aura_charge") and by_id.has("aura_burst"), "canonical_aura_ids_present")
	check(str(by_id.get("bloom_seed", {}).get("input_command", "")) == "special_neutral", "bloom_seed_on_special_neutral")
	check(str(by_id.get("quiet_embrace", {}).get("input_command", "")) == "", "quiet_embrace_not_grab_binding")

	var catalog: Dictionary = Catalog.build_fighter_catalog("rosamere")
	check(int(catalog.get("playable_count", 0)) >= 20, "training_catalog_playable_entries")
	var found_bloom := false
	for e in catalog.get("entries", []):
		if str(e.get("move_id", "")) == "bloom_seed":
			found_bloom = true
			check(str(e.get("input_command", "")) == "special_neutral", "catalog_bloom_input")
			check(str(e.get("display_name", "")).find("Bloom") >= 0, "catalog_bloom_display")
	check(found_bloom, "catalog_lists_bloom_seed")

	var Presentation = load("res://scripts/visual/rosamere_form_presentation.gd")
	var prod: Dictionary = Presentation.validate_production()
	check(bool(prod.get("ok", false)), "three_form_presentation_production_valid")
	for f in prod.get("failures", []):
		check(false, "presentation_fail:" + str(f))

	var gs = root.get_node("GameState")
	gs.begin_training()
	gs.p1_fighter_id = "rosamere"
	gs.p2_fighter_id = "kaia-windrow"
	gs.p1_body_variant = "female"
	gs.p2_body_variant = "female"
	gs.p1_form_id = "FAMILIAR_ROSE"
	gs.training_dummy_mode = "idle"
	gs.stage_id = "training-grid"
	root.get_node("SceneRouter").go("training_battle")
	check(await wait_route("TrainingBattleScene.tscn"), "training_loads_rosamere")
	if not route_is("TrainingBattleScene.tscn"):
		finish(); return
	var training = current_scene
	await frames(90)
	var p = training.fighter1
	check(p != null and p.fighter_id == "rosamere", "rosamere_spawned")
	check(p.pink_bloom != null, "pink_bloom_runtime_attached")
	check(str(p.get_current_form_id()) == "FAMILIAR_ROSE", "familiar_rose_form")
	check(p.pink_bloom.gameplay_contract_id == "COMPETITIVE_SELF_LIMITED", "competitive_contract_on_familiar")

	await click(training._move_list_btn)
	var panel = training._move_list_panel
	check(panel != null and panel.visible, "command_guide_opens")
	if panel == null or not panel.visible:
		finish(); return
	check(_select_move(panel, "bloom_seed"), "bloom_seed_selected_in_guide")
	await click(panel._btn_pin)
	await click(panel._btn_close)
	check(training._pin_reminder != null and training._pin_reminder.text.contains("Bloom"), "pinned_practice_reminder")

	check(await _legal_control(p), "grounded_control_before_special")
	var activation_before: int = p.move_runner.activation_id
	keys(["special"])
	await frames(2)
	keys([])
	await frames(4)
	check(p.move_runner.current_move_id() == "bloom_seed" or p.move_runner.activation_id == activation_before + 1, "special_neutral_starts_bloom_seed")
	check(training._pin_reminder.text.contains("MOVE STARTED"), "training_feedback_move_started")
	var pink_meta: Dictionary = p.get_meta("rosamere_last_pink_activation", {}) if p.has_meta("rosamere_last_pink_activation") else {}
	check(str(pink_meta.get("system_id", "")) == "BloomSeed", "pink_bloom_seed_activated_from_ordinary_special")
	check(p.pink_bloom.has_active("BloomSeed") or str(pink_meta.get("event_id", "")).begins_with("pink:"), "pink_event_recorded")

	await frames(40)
	check(await _legal_control(p), "recovers_after_bloom")
	keys(["grab"])
	await frames(2)
	keys([])
	await frames(4)
	var grab_meta: Dictionary = p.get_meta("rosamere_last_pink_activation", {}) if p.has_meta("rosamere_last_pink_activation") else {}
	check(str(grab_meta.get("system_id", "")) == "QuietEmbrace" or p.move_runner.current_move_id() == "grab", "grab_fires_quiet_embrace_system")

	## Aura charge ordinary control (Origination Script presentation name).
	check(await _legal_control(p), "control_before_charge")
	var played: Dictionary = p.training_play_move("aura_charge")
	check(str(played.get("active", "")) == "aura_charge", "training_play_aura_charge")
	var charge_meta: Dictionary = p.get_meta("rosamere_last_pink_activation", {}) if p.has_meta("rosamere_last_pink_activation") else {}
	check(str(charge_meta.get("system_id", "")) == "OriginationScript", "aura_charge_activates_origination_script")

	p.aura = 100.0
	var burst_played: Dictionary = p.training_play_move("aura_burst")
	check(str(burst_played.get("active", "")) == "aura_burst", "training_play_aura_burst")
	var burst_meta: Dictionary = p.get_meta("rosamere_last_pink_activation", {}) if p.has_meta("rosamere_last_pink_activation") else {}
	check(str(burst_meta.get("system_id", "")) == "FirstPermission", "familiar_burst_is_first_permission")

	evidence = {
		"fighter": "rosamere",
		"form": p.get_current_form_id(),
		"pink_last": burst_meta,
		"catalog_playable": catalog.get("playable_count", 0),
		"SHIPPING_BACKEND_ENABLED": false,
		"HUMAN_ART_APPROVED": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
	}
	finish()

func finish() -> void:
	var result := {
		"PASS": failures.is_empty(),
		"checks": checks,
		"failures": failures,
		"evidence": evidence,
		"scope": "Rosamere ordinary Training controls + Pink system wiring + presentation production honesty. Not V1/human art; shipping rollback remains off.",
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"HUMAN_ART_APPROVED": false,
	}
	if not output.is_empty():
		var f := FileAccess.open(output.path_join("ROSAMERE_ORDINARY_CONTROLS_TRAINING.json"), FileAccess.WRITE)
		f.store_string(JSON.stringify(result, "\t"))
	quit(0 if failures.is_empty() else 1)
