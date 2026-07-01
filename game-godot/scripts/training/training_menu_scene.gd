extends ConsoleMenuBase

@onready var dummy_option: OptionButton = %DummyBehavior
@onready var p1_option: OptionButton = %P1Fighter
@onready var p2_option: OptionButton = %P2Fighter
@onready var log_label: Label = %HitLog

var _roster: Array = []

func _ready() -> void:
	_roster = DataLoader.roster_ids()
	super._ready()
	if title_label:
		title_label.text = "Training Mode"
	_fill_fighter_options(p1_option)
	_fill_fighter_options(p2_option)
	if dummy_option:
		dummy_option.add_item("idle", 0)
		dummy_option.add_item("shield", 1)
		dummy_option.add_item("jump", 2)
		dummy_option.add_item("attack", 3)
		dummy_option.add_item("cpu", 4)
		dummy_option.select(4)

func _fill_fighter_options(opt: OptionButton) -> void:
	if opt == null:
		return
	for id in _roster:
		var d: Dictionary = DataLoader.load_fighter(id)
		opt.add_item(d.get("displayName", id))

func _on_start_pressed() -> void:
	GameState.stage_id = "training-grid"
	GameState.p1_fighter_id = _roster[p1_option.selected] if p1_option else "ember-vale"
	GameState.p2_fighter_id = _roster[p2_option.selected] if p2_option else "rook-ironside"
	GameState.p2_is_cpu = false
	GameState.stocks = 99
	GameState.training_dummy_mode = dummy_option.get_item_text(dummy_option.selected) if dummy_option else "cpu"
	SceneRouter.go("training_battle")

func on_back() -> void:
	SceneRouter.go("main_menu")

func footer_hint() -> String:
	return "[A] Start Training   [B] Back   DEBUG instrumentation available in battle (F1–F5)"
