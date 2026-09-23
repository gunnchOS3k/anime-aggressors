extends CanvasLayer
class_name TrainingClashLab

## Touch-friendly Aura Clash Lab. No ADB after install.

const _Clash = preload("res://scripts/combat/aura_clash_director.gd")
const _Provenance = preload("res://scripts/visual/animation_provenance.gd")

const FIGHTERS := [
	"ember-vale",
	"rook-ironside",
	"juno-spark",
	"kaia-windrow",
	"nix-calder",
	"orion-vell",
	"vesper-nyx",
]

const PRESETS := ["rook_orion", "juno_kaia", "ember_nix", "vesper_ember", "nix_rook"]

var _scene
var _status: Label
var _a_idx: int = 1
var _b_idx: int = 4
var _frozen: bool = false


func setup(scene) -> void:
	_scene = scene
	layer = 85
	_build()
	_refresh()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var panel := PanelContainer.new()
	panel.position = Vector2(380, 118)
	panel.custom_minimum_size = Vector2(360, 540)
	root.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(344, 524)
	panel.add_child(scroll)
	var col := VBoxContainer.new()
	scroll.add_child(col)
	var title := Label.new()
	title.text = "Aura Clash Lab"
	title.add_theme_font_size_override("font_size", 20)
	col.add_child(title)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_status)
	_row(col, ["A prev", "A next"], [_cycle_a.bind(-1), _cycle_a.bind(1)])
	_row(col, ["B prev", "B next"], [_cycle_b.bind(-1), _cycle_b.bind(1)])
	_btn(col, "Aura A/B 100", _aura_full)
	_btn(col, "Force Neutral", _play.bind("draw"))
	_btn(col, "Force A win", _play.bind("a"))
	_btn(col, "Force B win", _play.bind("b"))
	_btn(col, "Play full sequence", _play.bind(""))
	_row(col, ["Freeze", "Step"], [_freeze, _step])
	_row(col, ["Cam", "VFX", "Audio"], [_tog.bind("training_camera_enabled"), _tog.bind("training_vfx_enabled"), _tog.bind("training_sfx_enabled")])
	_btn(col, "Reduce motion", _reduce)
	for pid in PRESETS:
		_btn(col, "Preset %s" % pid, _preset.bind(pid))


func _btn(col: VBoxContainer, label: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(0, 40)
	b.pressed.connect(cb)
	col.add_child(b)


func _row(col: VBoxContainer, labels: Array, cbs: Array) -> void:
	var row := HBoxContainer.new()
	for i in labels.size():
		var b := Button.new()
		b.text = str(labels[i])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 40)
		b.pressed.connect(cbs[i])
		row.add_child(b)
	col.add_child(row)


func _cycle_a(dir: int) -> void:
	_a_idx = (_a_idx + dir + FIGHTERS.size()) % FIGHTERS.size()
	_refresh()


func _cycle_b(dir: int) -> void:
	_b_idx = (_b_idx + dir + FIGHTERS.size()) % FIGHTERS.size()
	_refresh()


func _aura_full() -> void:
	if GameState:
		GameState.training_aura_threshold = 100.0
	_refresh()


func _play(force: String) -> void:
	var a := {"move_id": "aura_burst", "move_type": "aura", "startup_frames": 12, "active_frames": 8}
	var b := {"move_id": "signature_lane_finisher", "move_type": "super", "startup_frames": 16, "active_frames": 6}
	var fa := {"fighter_id": FIGHTERS[_a_idx], "aura": 100}
	var fb := {"fighter_id": FIGHTERS[_b_idx], "aura": 100}
	var result: Dictionary = _Clash.run_machine(a, b, fa, fb, force)
	if GameState:
		GameState.last_aura_clash = result
	_refresh()


func _freeze() -> void:
	_frozen = not _frozen
	_refresh()


func _step() -> void:
	_refresh()


func _tog(prop: String) -> void:
	if GameState:
		GameState.set(prop, not bool(GameState.get(prop)))
	_refresh()


func _reduce() -> void:
	if JuiceEventBus:
		JuiceEventBus.set_accessibility(true, true, true)
	if GameState:
		GameState.training_camera_enabled = false
		GameState.training_vfx_enabled = false
	_refresh()


func _preset(id: String) -> void:
	var row: Dictionary = _Clash.preset(id)
	if row.is_empty():
		return
	_a_idx = FIGHTERS.find(str(row.get("a")))
	_b_idx = FIGHTERS.find(str(row.get("b")))
	_play("")


func _refresh() -> void:
	if _status == null:
		return
	var clash: Dictionary = GameState.last_aura_clash if GameState else {}
	_status.text = "A %s  B %s\nstate %s  winner %s\nprov %s\nSYSTEM/VFX PLACEHOLDER — AUTHORED ACTING PENDING\nHUMAN_AURA_CLASH_PASS=false" % [
		FIGHTERS[_a_idx],
		FIGHTERS[_b_idx],
		str(clash.get("state", "NONE")),
		str(clash.get("winner", "none")),
		_Provenance.debug_line(FIGHTERS[_a_idx], "clash_lock"),
	]
