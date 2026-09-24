extends CanvasLayer
class_name TrainingImpactLab

## Pixel-native Training-only impact lab. Hidden outside Training.
## Touch-first: no ADB / keyboard / terminal required.

const _Debug = preload("res://scripts/training/training_impact_debug.gd")
const _Provenance = preload("res://scripts/visual/animation_provenance.gd")
const _Clash = preload("res://scripts/combat/aura_clash_director.gd")

const FIGHTERS := [
	"ember-vale",
	"rook-ironside",
	"juno-spark",
	"kaia-windrow",
	"nix-calder",
	"orion-vell",
	"vesper-nyx",
]
const TIERS := ["light", "medium", "heavy", "aura", "ko"]
const PERCENTS := [0.0, 60.0, 120.0, 150.0]

var _scene
var _status: Label
var _p1_idx: int = 0
var _p2_idx: int = 1
var _charged: bool = false
var _sequence: Array = []


func setup(scene) -> void:
	_scene = scene
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_refresh()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var panel := PanelContainer.new()
	panel.position = Vector2(8, 118)
	panel.custom_minimum_size = Vector2(360, 520)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.12, 0.88)
	style.border_color = Color(0.95, 0.78, 0.22, 1.0)
	style.set_border_width_all(2)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(344, 504)
	panel.add_child(scroll)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	scroll.add_child(col)
	var title := Label.new()
	title.text = "Training Impact Lab"
	title.add_theme_font_size_override("font_size", 20)
	col.add_child(title)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 13)
	col.add_child(_status)
	_row(col, ["P1 prev", "P1 next"], [_cycle_p1.bind(-1), _cycle_p1.bind(1)])
	_row(col, ["P2 prev", "P2 next"], [_cycle_p2.bind(-1), _cycle_p2.bind(1)])
	_btn(col, "Swap P1/P2", _swap)
	_btn(col, "Hide HUD", _hide_hud)
	_row(col, ["Tier Light", "Tier Med", "Tier Heavy"], [_tier.bind("light"), _tier.bind("medium"), _tier.bind("heavy")])
	_row(col, ["Tier Aura", "Tier KO"], [_tier.bind("aura"), _tier.bind("ko")])
	_btn(col, "Replay Last Hit", _replay)
	_row(col, ["Def % 0", "Def % 60"], [_percent.bind(0.0), _percent.bind(60.0)])
	_row(col, ["Def % 120", "Def % 150"], [_percent.bind(120.0), _percent.bind(150.0)])
	_row(col, ["Aura 0", "Aura 25", "Aura 50"], [_aura.bind(0.0), _aura.bind(25.0), _aura.bind(50.0)])
	_row(col, ["Aura 75", "Aura 100"], [_aura.bind(75.0), _aura.bind(100.0)])
	_btn(col, "Cycle Reaction", _reaction)
	_row(col, ["Cam", "VFX", "SFX"], [_cam, _vfx, _sfx])
	_btn(col, "Reset Position", _reset)
	_btn(col, "Charged / Base", _toggle_charged)
	_row(col, ["Freeze", "Step"], [_freeze, _step])
	_btn(col, "Replay Sequence", _replay_sequence)
	_btn(col, "Play authored proof", _play_authored_proof)
	_btn(col, "Debug aura clash", _debug_clash)
	_btn(col, "Open Aura Clash Lab", _open_clash_lab)
	_row(col, ["Rook heavy loop", "Nix hurt loop"], [_preview_action.bind("rook-ironside", "heavy"), _preview_action.bind("nix-calder", "hurt_heavy")])
	_btn(col, "Golden Slice sync preview", _golden_slice_sync)
	_row(col, ["100%", "50%", "25%"], [_preview_speed.bind(1.0), _preview_speed.bind(0.5), _preview_speed.bind(0.25)])
	_row(col, ["Silhouette", "Skeleton", "Collision"], [_toggle_preview.bind("silhouette"), _toggle_preview.bind("skeleton"), _toggle_preview.bind("collision")])


func _btn(col: VBoxContainer, label: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(0, 40)
	b.pressed.connect(cb)
	col.add_child(b)


func _row(col: VBoxContainer, labels: Array, cbs: Array) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for i in labels.size():
		var b := Button.new()
		b.text = str(labels[i])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 40)
		b.pressed.connect(cbs[i])
		row.add_child(b)
	col.add_child(row)


func _f1():
	return _scene.fighter1 if _scene else null


func _f2():
	return _scene.fighter2 if _scene else null


func _log(msg: String) -> void:
	if _scene != null and _scene.has_method("_log"):
		_scene._log(msg)
	_refresh()


func _cycle_p1(dir: int) -> void:
	_p1_idx = (_p1_idx + dir + FIGHTERS.size()) % FIGHTERS.size()
	_apply_roster()


func _cycle_p2(dir: int) -> void:
	_p2_idx = (_p2_idx + dir + FIGHTERS.size()) % FIGHTERS.size()
	_apply_roster()


func _apply_roster() -> void:
	if GameState == null:
		return
	GameState.p1_fighter_id = FIGHTERS[_p1_idx]
	GameState.p2_fighter_id = FIGHTERS[_p2_idx]
	if _scene != null and _scene.has_method("_spawn_fighters"):
		if _f1():
			_f1().queue_free()
		if _f2():
			_f2().queue_free()
		_scene.fighter1 = null
		_scene.fighter2 = null
		_scene._spawn_fighters()
	_log("ROSTER P1 %s P2 %s" % [FIGHTERS[_p1_idx], FIGHTERS[_p2_idx]])


func _swap() -> void:
	var tmp := _p1_idx
	_p1_idx = _p2_idx
	_p2_idx = tmp
	_apply_roster()


func _hide_hud() -> void:
	var hidden := _Debug.toggle_hide_hud()
	if _scene != null and _scene.has_method("_apply_hide_hud"):
		_scene._apply_hide_hud(hidden)
	visible = true
	_log("HUD HIDDEN" if hidden else "HUD VISIBLE")


func _tier(name: String) -> void:
	_log("FORCE TIER %s" % _Debug.set_tier(name))


func _replay() -> void:
	var ok := _Debug.replay_last_hit(_f1(), _f2())
	if ok:
		_sequence.append(GameState.training_last_hit.duplicate(true) if GameState else {})
	_log("REPLAY HIT" if ok else "NO LAST HIT")


func _percent(value: float) -> void:
	if _f2() == null:
		return
	_f2().damage_percent = value
	_log("PERCENT %.0f" % value)


func _aura(value: float) -> void:
	if _f1() == null:
		return
	_f1().aura = value
	if GameState:
		GameState.training_aura_threshold = value
	if _f1().has_method("get_aura_level") and _f1().model_3d != null and _f1().model_3d.has_method("set_aura_level"):
		_f1().model_3d.set_aura_level(_f1().get_aura_level())
	_log("AURA %.0f" % value)


func _reaction() -> void:
	_log("REACTION %s" % _Debug.cycle_reaction())


func _cam() -> void:
	_log("CAMERA %s" % str(_Debug.toggle_camera()))


func _vfx() -> void:
	_log("VFX %s" % str(_Debug.toggle_vfx()))


func _sfx() -> void:
	_log("SFX %s" % str(_Debug.toggle_sfx()))


func _reset() -> void:
	if _f1() and _f1().has_method("reset_position"):
		_f1().reset_position()
	if _f2() and _f2().has_method("reset_position"):
		_f2().reset_position()
	_log("RESET POS")


func _toggle_charged() -> void:
	_charged = not _charged
	_aura(100.0 if _charged else 0.0)


func _freeze() -> void:
	if _scene == null:
		return
	_scene._freeze = not bool(_scene._freeze)
	if _scene._battle_sim:
		_scene._battle_sim.set_freeze(_scene._freeze)
	if _f1():
		_f1().controls_enabled = not _scene._freeze
	if _f2():
		_f2().controls_enabled = not _scene._freeze
	_log("FREEZE" if _scene._freeze else "UNFREEZE")


func _step() -> void:
	if _scene == null:
		return
	if _scene._freeze or _scene._paused:
		if _scene._battle_sim:
			_scene._battle_sim.step_frame()
		_log("STEP 1 FRAME")


func _replay_sequence() -> void:
	if _sequence.is_empty():
		_replay()
		return
	if GameState:
		GameState.training_last_hit = _sequence[_sequence.size() - 1]
	_replay()


func _play_authored_proof() -> void:
	var f = _f1()
	if f == null or f.model_3d == null:
		_log("NO P1 MODEL")
		return
	if f.model_3d.has_method("play_for_state"):
		f.model_3d.play_for_state("idle", {"reaction_clip": "pipeline_proof"})
	_log("AUTHORED PROOF %s" % _Provenance.debug_line(FIGHTERS[_p1_idx], "pipeline_proof"))


func _open_clash_lab() -> void:
	var lab = load("res://scripts/training/training_clash_lab.gd")
	if lab == null:
		_log("CLASH LAB MISSING")
		return
	var node = lab.new()
	node.name = "TrainingClashLab"
	add_child(node)
	if node.has_method("setup"):
		node.setup(_scene)
	_log("AURA CLASH LAB")


func _preview_action(fid: String, action: String) -> void:
	if GameState:
		GameState.p1_fighter_id = fid
	_p1_idx = FIGHTERS.find(fid)
	if _p1_idx < 0:
		_p1_idx = 0
	_apply_roster()
	_log("PREVIEW %s %s %s" % [fid, action, _Provenance.debug_line(fid, action)])


func _golden_slice_sync() -> void:
	_p1_idx = FIGHTERS.find("rook-ironside")
	_p2_idx = FIGHTERS.find("nix-calder")
	_apply_roster()
	_log("GOLDEN SLICE SYNC rook-heavy → nix-hurt_heavy (authored acting pending)")


func _preview_speed(value: float) -> void:
	Engine.time_scale = value
	_log("PREVIEW SPEED %.2f" % value)


func _toggle_preview(kind: String) -> void:
	_log("PREVIEW TOGGLE %s" % kind)


func _debug_clash() -> void:
	var a := {"move_id": "aura_burst", "move_type": "aura", "startup_frames": 12, "active_frames": 8, "choreography": {"clashable": true}}
	var b := {"move_id": "signature_lane_finisher", "move_type": "super", "startup_frames": 16, "active_frames": 6, "choreography": {"clashable": true}}
	var jab := {"move_id": "jab_1", "move_type": "jab", "startup_frames": 4, "active_frames": 2}
	var forced: Dictionary = _Clash.debug_force(a, b, _f1(), _f2())
	var jab_blocked: Dictionary = _Clash.debug_force(jab, a, _f1(), _f2())
	if GameState:
		GameState.last_aura_clash = forced
	_log("CLASH %s jab_clashable=%s" % [forced, _Clash.is_clashable(jab)])


func _refresh() -> void:
	if _status == null:
		return
	var gs = GameState
	var p1_clip := ""
	var p1_prov := _Provenance.status_for(FIGHTERS[_p1_idx], "pipeline_proof")
	if _f1() != null and _f1().model_3d != null:
		if _f1().model_3d.has_method("get_active_animation_clip"):
			p1_clip = str(_f1().model_3d.get_active_animation_clip())
		if _f1().model_3d.has_method("get_clip_provenance"):
			p1_prov = str(_f1().model_3d.get_clip_provenance())
	if gs and p1_prov != "":
		gs.last_animation_provenance = p1_prov
	_status.text = "P1 %s  P2 %s\nTier %s  Aura %.0f  React %s\nCam %s VFX %s SFX %s  HUD %s\nAnim %s  Prov %s\nClash %s" % [
		FIGHTERS[_p1_idx],
		FIGHTERS[_p2_idx],
		str(gs.training_force_hit_tier) if gs else "",
		float(gs.training_aura_threshold) if gs else 0.0,
		str(gs.training_force_reaction) if gs else "",
		str(gs.training_camera_enabled) if gs else "true",
		str(gs.training_vfx_enabled) if gs else "true",
		str(gs.training_sfx_enabled) if gs else "true",
		"hidden" if (gs and gs.training_hide_hud) else "shown",
		p1_clip,
		p1_prov,
		str(gs.last_aura_clash.get("winner", "none")) if gs else "none",
	]
