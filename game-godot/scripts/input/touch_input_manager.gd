extends Node

## Synthesizes p1 input actions from the touch overlay. Keyboard/gamepad remain active.

enum TouchMode { AUTO, ON, OFF }

const MODE_LABELS := ["Auto", "On", "Off"]

var touch_mode: TouchMode = TouchMode.AUTO
var overlay: CanvasLayer = null

var _axis_x: float = 0.0
var _axis_y: float = 0.0
var _held: Dictionary = {}
var _just_pressed: Dictionary = {}
var _just_released: Dictionary = {}

func _ready() -> void:
	var scene := preload("res://scenes/ui/TouchControlsOverlay.tscn")
	overlay = scene.instantiate()
	get_tree().root.call_deferred("add_child", overlay)
	if overlay.has_method("bind_manager"):
		overlay.bind_manager(self)
	call_deferred("_sync_overlay")

func _sync_overlay() -> void:
	if overlay and overlay.has_method("set_visible_controls"):
		overlay.set_visible_controls(should_show_touch())

func should_show_touch() -> bool:
	match touch_mode:
		TouchMode.ON:
			return true
		TouchMode.OFF:
			return false
		_:
			return _detect_touch_device()

func _detect_touch_device() -> bool:
	if DisplayServer.is_touchscreen_available():
		return true
	var os_name := OS.get_name()
	return os_name in ["Android", "iOS"]

func cycle_touch_mode() -> void:
	touch_mode = ((touch_mode + 1) % 3) as TouchMode
	_sync_overlay()

func touch_mode_label() -> String:
	return MODE_LABELS[touch_mode]

func set_stick(axis: Vector2) -> void:
	_axis_x = clampf(axis.x, -1.0, 1.0)
	_axis_y = clampf(axis.y, -1.0, 1.0)

func set_button(action_suffix: String, pressed: bool, just_edge: bool = false) -> void:
	var key := action_suffix
	if just_edge and pressed:
		_just_pressed[key] = true
	if just_edge and not pressed:
		_just_released[key] = true
	_held[key] = pressed

func get_axis(slot: int) -> float:
	if slot != 1 or not should_show_touch():
		return 0.0
	return _axis_x

func get_vertical(slot: int) -> float:
	if slot != 1 or not should_show_touch():
		return 0.0
	return _axis_y

func is_touch_pressed(slot: int, suffix: String) -> bool:
	if slot != 1 or not should_show_touch():
		return false
	return bool(_held.get(suffix, false))

func consume_touch_just_pressed(slot: int, suffix: String) -> bool:
	if slot != 1 or not should_show_touch():
		return false
	if _just_pressed.get(suffix, false):
		_just_pressed[suffix] = false
		return true
	return false

func is_aura_charge_touch(slot: int) -> bool:
	return is_touch_pressed(slot, "aura_charge")

func _process(_delta: float) -> void:
	if not should_show_touch():
		_axis_x = 0.0
		_axis_y = 0.0
		_held.clear()
		_just_pressed.clear()
		_just_released.clear()
		return
	_apply_synthetic_actions()
	_just_pressed.clear()
	_just_released.clear()

func _apply_synthetic_actions() -> void:
	var slot := 1
	var prefix := "p%d_" % slot
	_set_axis_actions(prefix, _axis_x, _axis_y)
	for suffix in ["jump", "attack", "special", "shield", "grab", "dodge"]:
		_set_action(prefix + suffix, bool(_held.get(suffix, false)))
	if bool(_held.get("aura_charge", false)):
		_set_action(prefix + "shield", true)
		_set_action(prefix + "special", true)

func _set_axis_actions(prefix: String, axis_x: float, axis_y: float) -> void:
	var dead := 0.22
	_set_action(prefix + "left", axis_x < -dead)
	_set_action(prefix + "right", axis_x > dead)
	_set_action(prefix + "up", axis_y < -dead)
	_set_action(prefix + "down", axis_y > dead)

func _set_action(action: String, pressed: bool) -> void:
	if pressed:
		if not Input.is_action_pressed(action):
			Input.action_press(action)
	else:
		if Input.is_action_pressed(action):
			Input.action_release(action)
