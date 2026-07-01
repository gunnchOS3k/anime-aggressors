extends CanvasLayer
class_name DebugHud

@onready var panel: PanelContainer = $Panel
@onready var label: RichTextLabel = $Panel/Label

var visible_debug := true
var show_hitboxes := false
var fighters: Array = []

func _ready() -> void:
	layer = 100
	if label:
		label.scroll_active = false

func bind_fighters(list: Array) -> void:
	fighters = list

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
	lines.append("[b]DEBUG HUD[/b]  F1 toggle  F2 hitboxes")
	for f in fighters:
		if f == null:
			continue
		var name := f.data.get("displayName", "?") if "data" in f else "?"
		var state := f.state_machine.current_state if f.has_method("get") and f.state_machine else "?"
		if "state_machine" in f and f.state_machine:
			state = f.state_machine.current_state
		var status := f.data.get("productionStatus", "?") if "data" in f else "?"
		var proxy_warn := ""
		if status in ["placeholder", "proxy"]:
			proxy_warn = " [color=yellow]PROXY — NOT FINAL ART[/color]"
		lines.append("%s%s  %d%%  x%d  aura:%d  state:%s" % [
			name, proxy_warn,
			int(f.damage_percent) if "damage_percent" in f else 0,
			f.stocks if "stocks" in f else 0,
			int(f.aura) if "aura" in f else 0,
			state,
		])
	label.text = "\n".join(lines)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				visible_debug = not visible_debug
			KEY_F2:
				show_hitboxes = not show_hitboxes
				get_tree().call_group("hitbox_debug", "set_debug_visible", show_hitboxes)
