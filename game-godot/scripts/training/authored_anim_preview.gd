extends Node2D
class_name AuthoredAnimPreview

## Deterministic authored-clip preview. No ADB. Not a quality claim.

const _Provenance = preload("res://scripts/visual/animation_provenance.gd")
const _Loader = preload("res://scripts/visual/authored_clip_loader.gd")

const FIGHTERS := [
	"ember-vale",
	"rook-ironside",
	"juno-spark",
	"kaia-windrow",
	"nix-calder",
	"orion-vell",
	"vesper-nyx",
]

var fighter_id: String = "rook-ironside"
var action_id: String = "heavy"
var combined: bool = false
var speed: float = 1.0
var paused: bool = false
var frame_i: int = 1
var knockback_on: bool = true
var hitstop_on: bool = true
var vfx_on: bool = true
var camera_on: bool = true
var audio_on: bool = true
var silhouette: bool = false
var skeleton_overlay: bool = false
var collision_overlay: bool = false
var _status: Label
var _player: AnimationPlayer


func _ready() -> void:
	_parse_args()
	_build_ui()
	_status_refresh()


func _parse_args() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--fighter":
				if i + 1 < args.size():
					fighter_id = args[i + 1]
					i += 1
			"--action":
				if i + 1 < args.size():
					action_id = args[i + 1]
					i += 1
			"--combined":
				combined = true
		i += 1
	if GameState:
		if str(GameState.get("preview_fighter") if false else "") != "":
			pass


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	var panel := PanelContainer.new()
	panel.position = Vector2(8, 8)
	panel.custom_minimum_size = Vector2(420, 640)
	root.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(404, 624)
	panel.add_child(scroll)
	var col := VBoxContainer.new()
	scroll.add_child(col)
	var title := Label.new()
	title.text = "Authored Animation Preview"
	title.add_theme_font_size_override("font_size", 20)
	col.add_child(title)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_status)
	_btn(col, "Play / loop action", _play)
	_btn(col, "Rook heavy loop", _rook_heavy)
	_btn(col, "Nix hurt-heavy loop", _nix_hurt)
	_btn(col, "Combined Golden Slice sync", _combined)
	_row(col, ["100%", "50%", "25%"], [_spd.bind(1.0), _spd.bind(0.5), _spd.bind(0.25)])
	_row(col, ["Pause", "Step"], [_pause, _step])
	_row(col, ["KB", "Hitstop", "VFX"], [_tog.bind("knockback_on"), _tog.bind("hitstop_on"), _tog.bind("vfx_on")])
	_row(col, ["Cam", "Audio"], [_tog.bind("camera_on"), _tog.bind("audio_on")])
	_row(col, ["Silhouette", "Skeleton", "Collision"], [_tog.bind("silhouette"), _tog.bind("skeleton_overlay"), _tog.bind("collision_overlay")])
	_player = AnimationPlayer.new()
	add_child(_player)


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


func _play() -> void:
	paused = false
	Engine.time_scale = speed
	_status_refresh()


func _rook_heavy() -> void:
	fighter_id = "rook-ironside"
	action_id = "heavy"
	combined = false
	_play()


func _nix_hurt() -> void:
	fighter_id = "nix-calder"
	action_id = "hurt_heavy"
	combined = false
	_play()


func _combined() -> void:
	combined = true
	fighter_id = "rook-ironside"
	action_id = "heavy"
	_play()


func _spd(v: float) -> void:
	speed = v
	Engine.time_scale = 0.0 if paused else speed
	_status_refresh()


func _pause() -> void:
	paused = not paused
	Engine.time_scale = 0.0 if paused else speed
	_status_refresh()


func _step() -> void:
	frame_i += 1
	_status_refresh()


func _tog(prop: String) -> void:
	set(prop, not bool(get(prop)))
	if GameState:
		match prop:
			"camera_on":
				GameState.training_camera_enabled = camera_on
			"vfx_on":
				GameState.training_vfx_enabled = vfx_on
			"audio_on":
				GameState.training_sfx_enabled = audio_on
	_status_refresh()


func _status_refresh() -> void:
	if _status == null:
		return
	var prov := _Provenance.debug_line(fighter_id, action_id)
	var contact := 10 if action_id == "heavy" and fighter_id == "rook-ironside" else 1
	_status.text = "%s / %s\n%s\nframe %d  speed %.2f  pause %s\nactive window shown  contact %d\nKB %s hitstop %s VFX %s cam %s audio %s\nsilhouette %s skeleton %s collision %s\ncombined %s\nHUMAN_APPROVED false" % [
		fighter_id,
		action_id,
		prov,
		frame_i,
		speed,
		str(paused),
		contact,
		str(knockback_on),
		str(hitstop_on),
		str(vfx_on),
		str(camera_on),
		str(audio_on),
		str(silhouette),
		str(skeleton_overlay),
		str(collision_overlay),
		str(combined),
	]
