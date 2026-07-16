extends CanvasLayer

var _manager: Node = null
var _stick_center := Vector2.ZERO
var _stick_touch_id := -1
var _stick_vector := Vector2.ZERO
var _stick_radius := 72.0

@onready var root: Control = $Root
@onready var stick_base: Control = $Root/StickBase
@onready var stick_knob: Control = $Root/StickBase/StickKnob
@onready var btn_jump: Button = $Root/Buttons/Jump
@onready var btn_attack: Button = $Root/Buttons/Attack
@onready var btn_special: Button = $Root/Buttons/Special
@onready var btn_shield: Button = $Root/Buttons/Shield
@onready var btn_grab: Button = $Root/Buttons/Grab
@onready var btn_dodge: Button = $Root/Buttons/Dodge
@onready var btn_aura: Button = $Root/Buttons/AuraCharge

func _ready() -> void:
	layer = 128
	# Start hidden — never cover Boot/Start Game before the first scene sync.
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	_wire_button(btn_jump, "jump")
	_wire_button(btn_attack, "attack")
	_wire_button(btn_special, "special")
	_wire_button(btn_shield, "shield")
	_wire_button(btn_grab, "grab")
	_wire_button(btn_dodge, "dodge")
	_wire_button(btn_aura, "aura_charge")
	if stick_base:
		stick_base.gui_input.connect(_on_stick_gui_input)
	visibility_changed.connect(func():
		if root:
			root.visible = visible
	)
	if root:
		root.visible = false
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_interactive_filters(false)

func bind_manager(manager: Node) -> void:
	_manager = manager

func set_visible_controls(on: bool) -> void:
	visible = on
	if root:
		root.visible = on
		# When hidden, never intercept menu taps — full ignore + no processing.
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE if not on else Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_DISABLED if not on else Node.PROCESS_MODE_INHERIT
	_set_interactive_filters(on)
	if not on:
		_stick_touch_id = -1
		_stick_vector = Vector2.ZERO
		_reset_knob()
		_push_stick()
		# Release any held combat buttons so menus don't inherit press state.
		for suffix in ["jump", "attack", "special", "shield", "grab", "dodge", "aura_charge"]:
			_set_btn(suffix, false, false)


func _set_interactive_filters(interactive: bool) -> void:
	var filter := Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	if stick_base:
		stick_base.mouse_filter = filter
	for btn in [btn_jump, btn_attack, btn_special, btn_shield, btn_grab, btn_dodge, btn_aura]:
		if btn:
			btn.mouse_filter = filter
			btn.disabled = not interactive
			btn.visible = interactive
	if stick_base:
		stick_base.visible = interactive

func _wire_button(btn: Button, suffix: String) -> void:
	if btn == null:
		return
	btn.button_down.connect(func(): _set_btn(suffix, true, true))
	btn.button_up.connect(func(): _set_btn(suffix, false, false))
	btn.focus_mode = Control.FOCUS_NONE

func _set_btn(suffix: String, pressed: bool, edge: bool) -> void:
	if _manager and _manager.has_method("set_button"):
		_manager.set_button(suffix, pressed, edge)

func _on_stick_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and _stick_touch_id < 0:
			_stick_touch_id = t.index
			_update_stick(t.position)
		elif not t.pressed and t.index == _stick_touch_id:
			_stick_touch_id = -1
			_stick_vector = Vector2.ZERO
			_push_stick()
			_reset_knob()
	elif event is InputEventScreenDrag and event.index == _stick_touch_id:
		_update_stick(event.position)

func _update_stick(local_pos: Vector2) -> void:
	var center := stick_base.size / 2.0
	var delta := local_pos - center
	if delta.length() > _stick_radius:
		delta = delta.normalized() * _stick_radius
	_stick_vector = delta / _stick_radius
	if stick_knob:
		stick_knob.position = center + delta - stick_knob.size / 2.0
	_push_stick()

func _reset_knob() -> void:
	if stick_knob and stick_base:
		stick_knob.position = stick_base.size / 2.0 - stick_knob.size / 2.0

func _push_stick() -> void:
	if _manager and _manager.has_method("set_stick"):
		_manager.set_stick(_stick_vector)
