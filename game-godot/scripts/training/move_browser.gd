extends Control
class_name TrainingMoveBrowser

## Debug-only training truth tool: fighter → move → aura → facing → target → play.

const _Catalog = preload("res://scripts/combat/move_content_catalog.gd")
const _DataLoader = preload("res://scripts/data/data_loader.gd")
const _AuraScaler = preload("res://scripts/combat/aura_scaler.gd")

signal play_requested(fighter_id: String, move_id: String, aura: float, facing: int)

var _fighter_id: String = "ember-vale"
var _move_id: String = "jab_1"
var _aura: float = 0.0
var _facing: int = 1
var _target_state: String = "stand"
var _log: Label
var _status: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func bind_fighter(fighter_id: String) -> void:
	_fighter_id = fighter_id
	_refresh_status()


func _build() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(24, 120)
	panel.custom_minimum_size = Vector2(420, 360)
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "TRAINING MOVE BROWSER (debug)"
	box.add_child(title)
	_add_option(box, "Fighter", _Catalog.FIGHTERS, func(v): _fighter_id = v)
	_add_option(box, "Move", _Catalog.REQUIRED_MOVES, func(v): _move_id = v)
	_add_option(box, "Aura", ["0", "25", "50", "75", "100"], func(v): _aura = float(v))
	_add_option(box, "Facing", ["right", "left"], func(v): _facing = 1 if v == "right" else -1)
	_add_option(box, "Target", ["stand", "shield", "air", "crouch"], func(v): _target_state = v)
	var play := Button.new()
	play.text = "Play move"
	play.pressed.connect(_play)
	box.add_child(play)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status)
	_log = Label.new()
	_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_log)
	_refresh_status()


func _add_option(box: VBoxContainer, label: String, values: Array, cb: Callable) -> void:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = label
	l.custom_minimum_size.x = 72
	row.add_child(l)
	var opt := OptionButton.new()
	for v in values:
		opt.add_item(str(v))
	opt.item_selected.connect(func(i): cb.call(str(values[i])); _refresh_status())
	row.add_child(opt)
	box.add_child(row)


func _play() -> void:
	play_requested.emit(_fighter_id, _move_id, _aura, _facing)
	_refresh_status()


func report_result(info: Dictionary) -> void:
	if _log == null:
		return
	_log.text = "result:%s hitstop:%s dmg:%s kb:%s vfx:%s sfx:%s particles:%s" % [
		str(info.get("result", "played")),
		str(info.get("hitstop_frames", "")),
		str(info.get("damage", "")),
		str(info.get("base_knockback", "")),
		str(info.get("vfx_event", "")),
		str(info.get("sfx_event", "")),
		str(info.get("particle_profile", "")),
	]


func _refresh_status() -> void:
	if _status == null:
		return
	var manifest: Dictionary = _DataLoader.load_moves(_fighter_id)
	var move: Dictionary = _DataLoader.find_move(manifest, _move_id)
	if move.is_empty():
		_status.text = "state:missing move"
		return
	var scaled: Dictionary = _AuraScaler.apply_to_move(move, _aura)
	var fb: Dictionary = scaled.get("feedback", {})
	_status.text = "\n".join([
		"state:training move:%s phase:— frame:— " % _move_id,
		"active hitbox:%s cancel:%s aura:%s" % [
			"yes" if scaled.get("hitboxes", []) else "throw/proj",
			str(not scaled.get("cancel_windows", []).is_empty()),
			str(_AuraScaler.aura_level(_aura)),
		],
		"projectile:%s throw:%s facing:%s target:%s" % [
			str(scaled.get("projectile", {}).get("type", "none")),
			str(scaled.get("throw", {}).get("direction", "none")),
			"right" if _facing > 0 else "left",
			_target_state,
		],
		"hitstop:%s dmg:%s kb:%s vfx:%s particles:%s sfx:%s" % [
			str(fb.get("hitstop_frames", scaled.get("hitstop_frames", 0))),
			str(scaled.get("damage", 0)),
			str(scaled.get("base_knockback", 0)),
			str(fb.get("vfx_event", "")),
			str(fb.get("particle_profile", "")),
			str(fb.get("sfx_event", "")),
		],
	])
