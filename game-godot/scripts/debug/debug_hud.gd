extends CanvasLayer
class_name DebugHud

@onready var panel: PanelContainer = $Panel
@onready var label: RichTextLabel = $Panel/Label

var visible_debug := true
var show_hitboxes := false
var show_hurtboxes := false
var show_projectile_boxes := false
var show_grab_range := false
var show_aura_fields := false
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
	lines.append("[b]DEBUG HUD[/b]  F1 HUD  F2 hitboxes  F6 hurtboxes  F11 proj  F12 grab")
	lines.append("hitboxes:%s hurtboxes:%s projectile_boxes:%s grab_range:%s" % [
		str(show_hitboxes).to_lower(), str(show_hurtboxes).to_lower(),
		str(show_projectile_boxes).to_lower(), str(show_grab_range).to_lower(),
	])
	for f in fighters:
		if f == null:
			continue
		var name := f.data.get("displayName", "?") if "data" in f else "?"
		var state := f.state_machine.current_state if f.state_machine else "?"
		var proxy := " [color=yellow]PROXY — NOT FINAL ART[/color]"
		var mr := ""
		if f.move_runner:
			mr = f.move_runner.debug_summary()
		var combat := {}
		if f.has_method("debug_combat_summary"):
			combat = f.debug_combat_summary()
		lines.append("%s%s" % [name, proxy])
		lines.append("  %d%% x%d aura:%d aura_level:%d state:%s" % [
			int(f.damage_percent), f.stocks, int(f.aura),
			combat.get("aura_level", f.get_aura_level() if f.has_method("get_aura_level") else 0),
			state,
		])
		lines.append("  %s" % mr)
		lines.append("  cancel:%s combo:%d proj:%d throw:%s" % [
			str(combat.get("cancel_window", false)).to_lower(),
			combat.get("combo_count", 0),
			combat.get("projectile_count", 0),
			combat.get("throw_direction", "—"),
		])
		lines.append("  last_hit:%s hitstop:%d kb:(%.0f,%.0f) shield_dmg:%.1f element:%s" % [
			combat.get("last_hit_result", "—"),
			combat.get("hitstop_frames", 0),
			combat.get("knockback_vector", Vector2.ZERO).x,
			combat.get("knockback_vector", Vector2.ZERO).y,
			combat.get("shield_damage", 0.0),
			combat.get("element_effect", "—"),
		])
		if f.has_method("input_display"):
			lines.append("  input: %s" % f.input_display())
	if hit_logs.size():
		lines.append("[b]Hit log[/b]")
		for i in range(mini(hit_logs.size(), 6)):
			lines.append("  %s" % hit_logs[hit_logs.size() - 1 - i])
	label.text = "\n".join(lines)

func _apply_hitbox_overlay(v: bool) -> void:
	show_hitboxes = v
	for f in fighters:
		if f and f.has_method("set_debug_hitboxes"):
			f.set_debug_hitboxes(v)

func _apply_hurtbox_overlay(v: bool) -> void:
	show_hurtboxes = v
	for f in fighters:
		if f and f.has_method("set_debug_hurtboxes"):
			f.set_debug_hurtboxes(v)

func _apply_projectile_overlay(v: bool) -> void:
	show_projectile_boxes = v
	for f in fighters:
		if f and f.has_method("set_debug_projectiles"):
			f.set_debug_projectiles(v)

func _apply_grab_range_overlay(v: bool) -> void:
	show_grab_range = v
	for f in fighters:
		if f and f.has_method("set_debug_grab_range"):
			f.set_debug_grab_range(v)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				visible_debug = not visible_debug
			KEY_F2:
				_apply_hitbox_overlay(not show_hitboxes)
			KEY_F6:
				_apply_hurtbox_overlay(not show_hurtboxes)
			KEY_F11:
				_apply_projectile_overlay(not show_projectile_boxes)
			KEY_F12:
				_apply_grab_range_overlay(not show_grab_range)
