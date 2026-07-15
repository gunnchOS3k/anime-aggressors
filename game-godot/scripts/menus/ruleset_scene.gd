extends "res://scripts/ui/console_menu_base.gd"

@onready var stock_label: Label = %StockLabel
@onready var cpu_label: Label = %CpuLabel

func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Rulesets"
	_update_labels()

func _update_labels() -> void:
	if stock_label:
		stock_label.text = "Stocks: %d" % GameState.stocks
	if cpu_label:
		cpu_label.text = "CPU Level: %d" % GameState.cpu_level

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

func _on_confirm_pressed() -> void:
	GameState.ruleset_id = "stock-%d" % GameState.stocks
	SceneRouter.go("fighter_select")

func on_back() -> void:
	SceneRouter.go("main_menu")
