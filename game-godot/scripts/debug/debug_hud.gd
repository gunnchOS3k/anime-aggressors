extends CanvasLayer
class_name DebugHud

@onready var panel: PanelContainer = $Panel
@onready var label: RichTextLabel = $Panel/Label

var visible_debug := true
var show_hitboxes := false
var show_hurtboxes := false
var fighters: Array = []
var hit_logs: Array = []

func _ready() -> void:
	layer = 100
	if label:
		label.scroll_active = false

func bind_fighters(list: Array) -> void:
	fighters = list
	for f in fighters:
		if f and f.has_signal("hit_landed"):
			f.hit_landed.connect(_on_hit_landed)
		if f and f.has_signal("grab_event"):
			f.grab_event.connect(_on_grab)

func push_log(text: String) -> void:
	hit_logs.append(text)
	if hit_logs.size() > 12:
		hit_logs.pop_front()

func _on_hit_landed(info: Dictionary) -> void:
	var tag := "SHIELD" if info.get("blocked", false) else "HIT"
	push_log("%s %s" % [tag, info.get("move_id", "?")])

func _on_grab(info: Dictionary) -> void:
	push_log("GRAB %s" % info.get("result", "?"))

func _process(_delta: float) -> void:
	if not visible_debug:
		if panel:
			panel.visible = false
		return
	if panel:
		panel.visible = true
	_update_text()

func _update_text() -> void:
	if label == null:
		return
	var lines: PackedStringArray = []
	lines.append("[b]DEBUG HUD[/b]  F1 HUD  F2 hitboxes  F6 hurtboxes")
	for f in fighters:
		if f == null:
			continue
		var name := f.data.get("displayName", "?") if "data" in f else "?"
		var state := f.state_machine.current_state if f.state_machine else "?"
		var proxy := " [color=yellow]PROXY — NOT FINAL ART[/color]"
		var mr := ""
		if f.move_runner:
			mr = f.move_runner.debug_summary()
		lines.append("%s%s" % [name, proxy])
		lines.append("  %d%% x%d aura:%d state:%s" % [
			int(f.damage_percent), f.stocks, int(f.aura), state,
		])
		lines.append("  %s" % mr)
		if f.has_method("input_display"):
			lines.append("  input: %s" % f.input_display())
	if hit_logs.size():
		lines.append("[b]Hit log[/b]")
		for i in range(mini(hit_logs.size(), 6)):
			lines.append("  %s" % hit_logs[hit_logs.size() - 1 - i])
	label.text = "\n".join(lines)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				visible_debug = not visible_debug
			KEY_F2:
				show_hitboxes = not show_hitboxes
				get_tree().call_group("hitbox_debug", "set_debug_visible", show_hitboxes)
			KEY_F6:
				show_hurtboxes = not show_hurtboxes
				get_tree().call_group("hurtbox_debug", "set_debug_visible", show_hurtboxes)
