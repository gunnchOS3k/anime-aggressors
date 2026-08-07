extends "res://scripts/ui/console_menu_base.gd"

@onready var stock_label: Label = %StockLabel
@onready var cpu_label: Label = %CpuLabel

var _timer_label: Label

const TIMER_OPTIONS := [0, 60, 120, 180, 300]

func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Rulesets"
	_ensure_timer_row()
	_update_labels()

func _ensure_timer_row() -> void:
	var vbox := get_node_or_null("VBox") as VBoxContainer
	if vbox == null or vbox.get_node_or_null("TimerLabel") != null:
		_timer_label = vbox.get_node_or_null("TimerLabel") if vbox else null
		return
	_timer_label = Label.new()
	_timer_label.name = "TimerLabel"
	vbox.add_child(_timer_label)
	var row := HBoxContainer.new()
	row.name = "TimerRow"
	var minus := Button.new()
	minus.text = "Time -"
	minus.pressed.connect(_on_timer_minus)
	row.add_child(minus)
	var plus := Button.new()
	plus.text = "Time +"
	plus.pressed.connect(_on_timer_plus)
	row.add_child(plus)
	vbox.add_child(row)
	# Keep Confirm at the bottom.
	var confirm := vbox.get_node_or_null("Confirm")
	if confirm:
		vbox.move_child(_timer_label, confirm.get_index())
		vbox.move_child(row, confirm.get_index())

func _update_labels() -> void:
	if stock_label:
		stock_label.text = "Stocks: %d" % GameState.stocks
	if cpu_label:
		cpu_label.text = "CPU Level: %d" % GameState.cpu_level
	if _timer_label:
		if GameState.match_timer_seconds <= 0:
			_timer_label.text = "Match Time: ∞"
		else:
			_timer_label.text = "Match Time: %ds" % GameState.match_timer_seconds

func _on_stock_minus() -> void:
	GameState.stocks = clampi(GameState.stocks - 1, 1, 9)
	_update_labels()

func _on_stock_plus() -> void:
	GameState.stocks = clampi(GameState.stocks + 1, 1, 9)
	_update_labels()

func _on_cpu_minus() -> void:
	GameState.cpu_level = clampi(GameState.cpu_level - 1, 1, 3)
	_update_labels()

func _on_cpu_plus() -> void:
	GameState.cpu_level = clampi(GameState.cpu_level + 1, 1, 3)
	_update_labels()

func _on_timer_minus() -> void:
	var idx := TIMER_OPTIONS.find(GameState.match_timer_seconds)
	if idx < 0:
		idx = 3
	idx = maxi(0, idx - 1)
	GameState.match_timer_seconds = TIMER_OPTIONS[idx]
	_update_labels()

func _on_timer_plus() -> void:
	var idx := TIMER_OPTIONS.find(GameState.match_timer_seconds)
	if idx < 0:
		idx = 3
	idx = mini(TIMER_OPTIONS.size() - 1, idx + 1)
	GameState.match_timer_seconds = TIMER_OPTIONS[idx]
	_update_labels()

func _on_confirm_pressed() -> void:
	GameState.ruleset_id = "stock-%d" % GameState.stocks
	GameState.match_type = "stock" if GameState.match_timer_seconds > 0 else "stock_untimed"
	SceneRouter.go("fighter_select")

func on_back() -> void:
	SceneRouter.go("main_menu")
