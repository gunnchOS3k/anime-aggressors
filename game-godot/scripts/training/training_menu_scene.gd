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
var p1_body_option: OptionButton
var p2_body_option: OptionButton

func _ready() -> void:
	# Establish training defaults before the player chooses stage/dummy/fighters.
	# Doing this in the battle after those choices would overwrite the setup.
	if str(GameState.mode) != "training":
		GameState.begin_training()
	_roster = _DataLoader.roster_ids()
	_stages = GameState.production_stage_ids()
	if _stages.is_empty():
		_stages = ["training-grid", "skyline-arena"]
	super._ready()
	if title_label:
		title_label.text = "Training Mode"
	_fill_fighter_options(p1_option)
	_fill_fighter_options(p2_option)
	if p1_option:
		p1_option.select(maxi(0, _roster.find(GameState.p1_fighter_id)))
		p1_body_option = _body_option(p1_option.get_parent(), GameState.p1_body_variant)
	if p2_option:
		p2_option.select(maxi(0, _roster.find(GameState.p2_fighter_id)))
		p2_body_option = _body_option(p2_option.get_parent(), GameState.p2_body_variant)
	if stage_option:
		for sid in _stages:
			var sd: Dictionary = GameState.load_stage(sid)
			stage_option.add_item(sd.get("displayName", sid))
		stage_option.select(maxi(0, _stages.find(GameState.stage_id)))
	if cpu_option:
		for i in range(1, 6):
			cpu_option.add_item("Level %d" % i, i - 1)
		cpu_option.select(clampi(GameState.cpu_level - 1, 0, 4))
	if dummy_option:
		dummy_option.add_item("idle", 0)
		dummy_option.add_item("shield", 1)
		dummy_option.add_item("jump", 2)
		dummy_option.add_item("attack", 3)
		dummy_option.add_item("cpu", 4)
		dummy_option.add_item("di_in", 5)
		dummy_option.add_item("di_out", 6)
		var modes := ["idle", "shield", "jump", "attack", "cpu", "di_in", "di_out"]
		dummy_option.select(maxi(0, modes.find(GameState.training_dummy_mode)))
	if log_label:
		log_label.text = "Configure fighters, stage, dummy behavior, then Start. In battle: F1 HUD, F2 hitboxes, F3–F10 tools."

func _fill_fighter_options(opt: OptionButton) -> void:
	if opt == null:
		return
	for id in _roster:
		var d: Dictionary = _DataLoader.load_fighter(id)
		opt.add_item(d.get("displayName", id))


func _body_option(row: Node, selected: String) -> OptionButton:
	var option := OptionButton.new()
	option.add_item("Male body")
	option.add_item("Female body")
	option.select(1 if selected == "female" else 0)
	row.add_child(option)
	return option

func _on_start_pressed() -> void:
	GameState.stage_id = _stages[stage_option.selected] if stage_option else "training-grid"
	GameState.p1_fighter_id = _roster[p1_option.selected] if p1_option else "ember-vale"
	GameState.p2_fighter_id = _roster[p2_option.selected] if p2_option else "rook-ironside"
	if p1_body_option: GameState.p1_body_variant = "female" if p1_body_option.selected == 1 else "male"
	if p2_body_option: GameState.p2_body_variant = "female" if p2_body_option.selected == 1 else "male"
	GameState.p2_is_cpu = false
	GameState.stocks = 99
	GameState.cpu_level = cpu_option.selected + 1 if cpu_option else 2
	GameState.training_dummy_mode = dummy_option.get_item_text(dummy_option.selected) if dummy_option else "cpu"
	SceneRouter.go("training_battle")

func on_back() -> void:
	SceneRouter.go("main_menu")

func footer_hint() -> String:
	return "[A] Start Training   [B] Back   F1–F10 in battle (see on-screen help)"
