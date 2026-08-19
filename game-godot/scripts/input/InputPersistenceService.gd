extends RefCounted
class_name InputPersistenceService

## Wave 001 — persisted InputMap remapping (user://input_profiles.cfg).

const SAVE_PATH := "user://input_profiles.cfg"
const SCHEMA_VERSION := 1
const PROFILE_ID := "keyboard_default"

## Normalized contract actions → Godot InputMap action names (player 1 + UI).
const NORMALIZED_TO_INPUT: Dictionary = {
	"move_left": "p1_left",
	"move_right": "p1_right",
	"jump": "p1_jump",
	"shield": "p1_shield",
	"attack": "p1_attack",
	"special": "p1_special",
	"grab": "p1_grab",
	"pause": "ui_cancel",
	"ui_accept": "ui_accept",
}

const DEFAULT_KEY_BINDINGS: Dictionary = {
	"move_left": KEY_A,
	"move_right": KEY_D,
	"jump": KEY_W,
	"shield": KEY_L,
	"attack": KEY_J,
	"special": KEY_K,
	"grab": KEY_U,
	"pause": KEY_ESCAPE,
	"ui_accept": KEY_ENTER,
}


static func normalized_actions() -> Array[String]:
	var out: Array[String] = []
	for key in NORMALIZED_TO_INPUT.keys():
		out.append(str(key))
	out.sort()
	return out


static func default_bindings() -> Dictionary:
	return DEFAULT_KEY_BINDINGS.duplicate(true)


static func load_bindings() -> Dictionary:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		return default_bindings()
	var version := int(cfg.get_value("meta", "schema_version", 0))
	if version != SCHEMA_VERSION:
		return default_bindings()
	var loaded := default_bindings()
	for action in NORMALIZED_TO_INPUT.keys():
		if cfg.has_section_key("bindings", action):
			loaded[action] = int(cfg.get_value("bindings", action, loaded.get(action, 0)))
	return loaded


static func save_bindings(bindings: Dictionary) -> bool:
	if not _validate_bindings(bindings):
		return false
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "schema_version", SCHEMA_VERSION)
	cfg.set_value("meta", "profile_id", PROFILE_ID)
	for action in NORMALIZED_TO_INPUT.keys():
		cfg.set_value("bindings", action, int(bindings.get(action, DEFAULT_KEY_BINDINGS.get(action, 0))))
	return cfg.save(SAVE_PATH) == OK


static func set_binding(normalized_action: String, physical_keycode: int) -> bool:
	if not NORMALIZED_TO_INPUT.has(normalized_action):
		return false
	if physical_keycode <= 0:
		return false
	var bindings := load_bindings()
	for other in bindings.keys():
		if other != normalized_action and int(bindings[other]) == physical_keycode:
			return false
	bindings[normalized_action] = physical_keycode
	if not save_bindings(bindings):
		return false
	apply_profile(bindings)
	return true


static func reset() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	apply_profile(default_bindings())


static func apply_profile(bindings: Dictionary) -> void:
	if not _validate_bindings(bindings):
		bindings = default_bindings()
	for normalized in NORMALIZED_TO_INPUT.keys():
		var input_action: String = NORMALIZED_TO_INPUT[normalized]
		var keycode := int(bindings.get(normalized, DEFAULT_KEY_BINDINGS.get(normalized, 0)))
		_apply_keyboard_binding(input_action, keycode)


static func ensure_loaded() -> void:
	apply_profile(load_bindings())


static func keyboard_key_for(normalized_action: String) -> int:
	if not NORMALIZED_TO_INPUT.has(normalized_action):
		return 0
	var input_action: String = NORMALIZED_TO_INPUT[normalized_action]
	for ev in InputMap.action_get_events(input_action):
		if ev is InputEventKey:
			return int(ev.physical_keycode)
	return 0


static func probe_roundtrip() -> Dictionary:
	var detail: Dictionary = {}
	var backup_path := "user://input_profiles.cfg.probe_backup"
	var had_file := FileAccess.file_exists(SAVE_PATH)
	if had_file:
		DirAccess.copy_absolute(
			ProjectSettings.globalize_path(SAVE_PATH),
			ProjectSettings.globalize_path(backup_path),
		)
	else:
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))

	reset()
	detail["defaults_exist"] = DEFAULT_KEY_BINDINGS.size() == NORMALIZED_TO_INPUT.size()
	apply_profile(default_bindings())
	detail["default_applied_to_input_map"] = keyboard_key_for("move_left") == KEY_A

	var probe_key := KEY_Q
	if not set_binding("move_left", probe_key):
		_restore_probe_backup(had_file, backup_path)
		detail["reason"] = "set_binding failed"
		return {"ok": false, "detail": detail}
	detail["changed_key"] = probe_key
	detail["file_written"] = FileAccess.file_exists(SAVE_PATH)

	var reloaded := load_bindings()
	detail["reload_matches"] = int(reloaded.get("move_left", 0)) == probe_key
	apply_profile(reloaded)
	detail["input_map_receives"] = keyboard_key_for("move_left") == probe_key

	var invalid_rejected := not set_binding("move_left", -1)
	detail["invalid_rejected"] = invalid_rejected

	reset()
	detail["reset_restores_defaults"] = (
		keyboard_key_for("move_left") == KEY_A and not FileAccess.file_exists(SAVE_PATH)
	)

	_restore_probe_backup(had_file, backup_path)
	var ok: bool = (
		bool(detail["defaults_exist"])
		and bool(detail["default_applied_to_input_map"])
		and bool(detail["file_written"])
		and bool(detail["reload_matches"])
		and bool(detail["input_map_receives"])
		and bool(detail["invalid_rejected"])
		and bool(detail["reset_restores_defaults"])
	)
	return {"ok": ok, "detail": detail}


static func _restore_probe_backup(had_file: bool, backup_path: String) -> void:
	if had_file and FileAccess.file_exists(backup_path):
		DirAccess.copy_absolute(
			ProjectSettings.globalize_path(backup_path),
			ProjectSettings.globalize_path(SAVE_PATH),
		)
		apply_profile(load_bindings())
		DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))
	elif not had_file and FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		apply_profile(default_bindings())


static func _validate_bindings(bindings: Dictionary) -> bool:
	var seen: Dictionary = {}
	for action in NORMALIZED_TO_INPUT.keys():
		if not bindings.has(action):
			return false
		var keycode := int(bindings[action])
		if keycode <= 0:
			return false
		if seen.has(keycode):
			return false
		seen[keycode] = true
	return true


static func _apply_keyboard_binding(input_action: String, physical_keycode: int) -> void:
	if not InputMap.has_action(input_action):
		return
	var kept: Array[InputEvent] = []
	for ev in InputMap.action_get_events(input_action):
		if not (ev is InputEventKey):
			kept.append(ev)
	InputMap.action_erase_events(input_action)
	for ev in kept:
		InputMap.action_add_event(input_action, ev)
	var key_ev := InputEventKey.new()
	key_ev.physical_keycode = physical_keycode
	InputMap.action_add_event(input_action, key_ev)
