extends "res://scripts/ui/console_menu_base.gd"

@onready var touch_mode_label: Label = %TouchModeValue

var _reduce_label: Label
var _ui_label: Label
var _role_label: Label
var _contrast_label: Label
var _cb_label: Label
var _vol_label: Label
var _career_label: Label

func _ready() -> void:
	super._ready()
	GameState.ensure_save_loaded()
	if title_label:
		title_label.text = "Settings"
	_ensure_accessibility_rows()
	_refresh_touch_label()
	_refresh_access_labels()

func _ensure_accessibility_rows() -> void:
	var vbox := get_node_or_null("VBox") as VBoxContainer
	if vbox == null:
		return
	var note := vbox.get_node_or_null("Note") as Label
	if note:
		note.text = "Accessibility, audio, progression save (Alpha exit). Original characters only."

	if vbox.get_node_or_null("ReduceMotionRow") == null:
		_reduce_label = _add_toggle_row(vbox, "ReduceMotionRow", "Reduce Motion", _on_reduce_motion_pressed)
		_ui_label = _add_toggle_row(vbox, "LargerUiRow", "Larger UI", _on_larger_ui_pressed)
		_role_label = _add_toggle_row(vbox, "DeviceRoleRow", "Device Role", _on_device_role_pressed, "Cycle")
		_contrast_label = _add_toggle_row(vbox, "ContrastRow", "High Contrast HUD", _on_contrast_pressed)
		_cb_label = _add_toggle_row(vbox, "ColorblindRow", "Colorblind Markers", _on_colorblind_pressed)
		_vol_label = _add_toggle_row(vbox, "VolumeRow", "Master Volume", _on_volume_pressed, "Cycle")
		_career_label = Label.new()
		_career_label.name = "CareerLabel"
		vbox.add_child(_career_label)
		var save_btn := Button.new()
		save_btn.text = "Save Progress Now"
		save_btn.pressed.connect(_on_save_pressed)
		vbox.add_child(save_btn)
	else:
		_reduce_label = vbox.get_node_or_null("ReduceMotionRow/ReduceValue")
		_ui_label = vbox.get_node_or_null("LargerUiRow/LargerValue")
		_role_label = vbox.get_node_or_null("DeviceRoleRow/RoleValue")
		_contrast_label = vbox.get_node_or_null("ContrastRow/ReduceValue")
		_cb_label = vbox.get_node_or_null("ColorblindRow/ReduceValue")
		_vol_label = vbox.get_node_or_null("VolumeRow/ReduceValue")
		_career_label = vbox.get_node_or_null("CareerLabel")

func _add_toggle_row(vbox: VBoxContainer, row_name: String, title: String, cb: Callable, btn_text: String = "Toggle") -> Label:
	var row := HBoxContainer.new()
	row.name = row_name
	row.add_theme_constant_override("separation", 12)
	var t := Label.new()
	t.text = title
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(t)
	var val := Label.new()
	val.name = "ReduceValue"
	row.add_child(val)
	var btn := Button.new()
	btn.text = btn_text
	btn.pressed.connect(cb)
	row.add_child(btn)
	vbox.add_child(row)
	return val

func _on_touch_mode_pressed() -> void:
	TouchInputManager.cycle_touch_mode()
	_refresh_touch_label()

func _on_reduce_motion_pressed() -> void:
	DeviceRoleRuntime.set_reduce_motion(not DeviceRoleRuntime.reduce_motion)
	_refresh_access_labels()

func _on_larger_ui_pressed() -> void:
	DeviceRoleRuntime.set_larger_ui(not DeviceRoleRuntime.larger_ui)
	_refresh_access_labels()

func _on_device_role_pressed() -> void:
	DeviceRoleRuntime.cycle_role()
	_refresh_access_labels()

func _on_contrast_pressed() -> void:
	GameState.high_contrast = not GameState.high_contrast
	GameState._persist_save()
	_refresh_access_labels()

func _on_colorblind_pressed() -> void:
	GameState.colorblind_markers = not GameState.colorblind_markers
	GameState._persist_save()
	_refresh_access_labels()

func _on_volume_pressed() -> void:
	var steps := [0.0, 0.25, 0.5, 0.75, 1.0]
	var idx := 0
	for i in range(steps.size()):
		if is_equal_approx(GameState.master_volume, steps[i]):
			idx = i
			break
	idx = (idx + 1) % steps.size()
	GameState.master_volume = steps[idx]
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, GameState.master_volume)) if GameState.master_volume > 0.0 else -80.0)
	GameState._persist_save()
	_refresh_access_labels()

func _on_save_pressed() -> void:
	GameState._persist_save()
	_refresh_access_labels()

func _refresh_touch_label() -> void:
	if touch_mode_label:
		touch_mode_label.text = TouchInputManager.touch_mode_label()

func _refresh_access_labels() -> void:
	if _reduce_label:
		_reduce_label.text = "On" if DeviceRoleRuntime.reduce_motion else "Off"
	if _ui_label:
		_ui_label.text = "On" if DeviceRoleRuntime.larger_ui else "Off"
	if _role_label:
		_role_label.text = DeviceRoleRuntime.active_role
	if _contrast_label:
		_contrast_label.text = "On" if GameState.high_contrast else "Off"
	if _cb_label:
		_cb_label.text = "On" if GameState.colorblind_markers else "Off"
	if _vol_label:
		_vol_label.text = "%d%%" % int(GameState.master_volume * 100.0)
	if _career_label:
		_career_label.text = "Career W-L-M: %d-%d-%d  |  Unlocks: %d fighters / %d stages" % [
			GameState.career_wins, GameState.career_losses, GameState.career_matches,
			GameState.unlocked_fighters.size() if GameState.unlocked_fighters.size() > 0 else GameState.roster_ids().size(),
			GameState.unlocked_stages.size() if GameState.unlocked_stages.size() > 0 else GameState.production_stage_ids().size(),
		]

func on_back() -> void:
	GameState._persist_save()
	if TouchInputManager.should_show_touch():
		SceneRouter.go("mobile_playtest")
	else:
		SceneRouter.go("main_menu")
