extends "res://scripts/ui/console_menu_base.gd"
const _DataLoader = preload("res://scripts/data/data_loader.gd")

@onready var dummy_option: OptionButton = %DummyBehavior
@onready var p1_option: OptionButton = %P1Fighter
@onready var p2_option: OptionButton = %P2Fighter
@onready var stage_option: OptionButton = %StageSelect
@onready var cpu_option: OptionButton = %CpuLevel
@onready var log_label: Label = %HitLog

var _roster: Array = []
var _stages: Array = []

func _ready() -> void:
	_roster = _DataLoader.roster_ids()
	_stages = GameState.production_stage_ids()
	if _stages.is_empty():
		_stages = ["training-grid", "skyline-arena"]
	super._ready()
	if title_label:
		title_label.text = "Training Mode"
	_fill_fighter_options(p1_option)
	_fill_fighter_options(p2_option)
	if stage_option:
		for sid in _stages:
			var sd: Dictionary = GameState.load_stage(sid)
			stage_option.add_item(sd.get("displayName", sid))
	if cpu_option:
		for i in range(1, 5):
			cpu_option.add_item("Level %d" % i, i - 1)
		cpu_option.select(1)
	if dummy_option:
		dummy_option.add_item("idle", 0)
		dummy_option.add_item("shield", 1)
		dummy_option.add_item("jump", 2)
		dummy_option.add_item("attack", 3)
		dummy_option.add_item("cpu", 4)
		dummy_option.select(4)
	if log_label:
		log_label.text = "Configure fighters, stage, dummy behavior, then Start. In battle: F1 HUD, F2 hitboxes, F3–F10 tools."

func _fill_fighter_options(opt: OptionButton) -> void:
	if opt == null:
		return
	for id in _roster:
		var d: Dictionary = _DataLoader.load_fighter(id)
		opt.add_item(d.get("displayName", id))

func _on_start_pressed() -> void:
	GameState.stage_id = _stages[stage_option.selected] if stage_option else "training-grid"
	GameState.p1_fighter_id = _roster[p1_option.selected] if p1_option else "ember-vale"
	GameState.p2_fighter_id = _roster[p2_option.selected] if p2_option else "rook-ironside"
	GameState.p2_is_cpu = false
	GameState.stocks = 99
	GameState.cpu_level = cpu_option.selected + 1 if cpu_option else 2
	GameState.training_dummy_mode = dummy_option.get_item_text(dummy_option.selected) if dummy_option else "cpu"
	SceneRouter.go("training_battle")

func on_back() -> void:
	SceneRouter.go("main_menu")

func footer_hint() -> String:
	return "[A] Start Training   [B] Back   F1–F10 in battle (see on-screen help)"
