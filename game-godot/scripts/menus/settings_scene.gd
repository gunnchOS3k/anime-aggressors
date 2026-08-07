extends "res://scripts/ui/console_menu_base.gd"

@onready var touch_mode_label: Label = %TouchModeValue

var _reduce_label: Label
var _ui_label: Label
var _role_label: Label

func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Settings"
	_ensure_accessibility_rows()
	_refresh_touch_label()
	_refresh_access_labels()

func _ensure_accessibility_rows() -> void:
	var vbox := get_node_or_null("VBox") as VBoxContainer
	if vbox == null:
		return
	if vbox.get_node_or_null("ReduceMotionRow") != null:
		_reduce_label = vbox.get_node_or_null("ReduceMotionRow/ReduceValue")
		_ui_label = vbox.get_node_or_null("LargerUiRow/LargerValue")
		_role_label = vbox.get_node_or_null("DeviceRoleRow/RoleValue")
		return

	var note := vbox.get_node_or_null("Note") as Label
	if note:
		note.text = "Accessibility + device-role profiles (G2-C6). Original characters only."

	var reduce_row := HBoxContainer.new()
	reduce_row.name = "ReduceMotionRow"
	reduce_row.add_theme_constant_override("separation", 12)
	var reduce_title := Label.new()
	reduce_title.text = "Reduce Motion"
	reduce_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reduce_row.add_child(reduce_title)
	_reduce_label = Label.new()
	_reduce_label.name = "ReduceValue"
	reduce_row.add_child(_reduce_label)
	var reduce_btn := Button.new()
	reduce_btn.text = "Toggle"
	reduce_btn.pressed.connect(_on_reduce_motion_pressed)
	reduce_row.add_child(reduce_btn)
	vbox.add_child(reduce_row)

	var ui_row := HBoxContainer.new()
	ui_row.name = "LargerUiRow"
	ui_row.add_theme_constant_override("separation", 12)
	var ui_title := Label.new()
	ui_title.text = "Larger UI"
	ui_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui_row.add_child(ui_title)
	_ui_label = Label.new()
	_ui_label.name = "LargerValue"
	ui_row.add_child(_ui_label)
	var ui_btn := Button.new()
	ui_btn.text = "Toggle"
	ui_btn.pressed.connect(_on_larger_ui_pressed)
	ui_row.add_child(ui_btn)
	vbox.add_child(ui_row)

	var role_row := HBoxContainer.new()
	role_row.name = "DeviceRoleRow"
	role_row.add_theme_constant_override("separation", 12)
	var role_title := Label.new()
	role_title.text = "Device Role"
	role_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	role_row.add_child(role_title)
	_role_label = Label.new()
	_role_label.name = "RoleValue"
	role_row.add_child(_role_label)
	var role_btn := Button.new()
	role_btn.text = "Cycle"
	role_btn.pressed.connect(_on_device_role_pressed)
	role_row.add_child(role_btn)
	vbox.add_child(role_row)

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

func on_back() -> void:
	if TouchInputManager.should_show_touch():
		SceneRouter.go("mobile_playtest")
	else:
		SceneRouter.go("main_menu")
