extends "res://scripts/ui/console_menu_base.gd"

@onready var stock_label: Label = %StockLabel
@onready var cpu_label: Label = %CpuLabel

var _timer_label: Label
var _p2_label: Label
var _damage_label: Label
var _preset_label: Label

const TIMER_OPTIONS := [0, 60, 120, 180, 300]
const PRESETS := ["default", "tournament", "casual", "local-multi"]

func _ready() -> void:
	super._ready()
	GameState.ensure_save_loaded()
	if title_label:
		title_label.text = "Rulesets"
	_ensure_extra_rows()
	_update_labels()

func _ensure_extra_rows() -> void:
	var vbox := get_node_or_null("VBox") as VBoxContainer
	if vbox == null:
		return
	if vbox.get_node_or_null("TimerLabel") == null:
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
	else:
		_timer_label = vbox.get_node_or_null("TimerLabel")

	if vbox.get_node_or_null("P2ModeLabel") == null:
		_p2_label = Label.new()
		_p2_label.name = "P2ModeLabel"
		vbox.add_child(_p2_label)
		var p2row := HBoxContainer.new()
		var p2btn := Button.new()
		p2btn.text = "Toggle P2 Human/CPU"
		p2btn.pressed.connect(_on_toggle_p2)
		p2row.add_child(p2btn)
		var local_btn := Button.new()
		local_btn.text = "Local Multi (2P)"
		local_btn.pressed.connect(_on_local_multi)
		p2row.add_child(local_btn)
		vbox.add_child(p2row)
	else:
		_p2_label = vbox.get_node_or_null("P2ModeLabel")

	if vbox.get_node_or_null("DamageLabel") == null:
		_damage_label = Label.new()
		_damage_label.name = "DamageLabel"
		vbox.add_child(_damage_label)
		var drow := HBoxContainer.new()
		var dm := Button.new()
		dm.text = "Dmg -"
		dm.pressed.connect(_on_damage_minus)
		drow.add_child(dm)
		var dp := Button.new()
		dp.text = "Dmg +"
		dp.pressed.connect(_on_damage_plus)
		drow.add_child(dp)
		var team := Button.new()
		team.text = "Toggle Team Attack"
		team.pressed.connect(_on_toggle_team)
		drow.add_child(team)
		vbox.add_child(drow)
	else:
		_damage_label = vbox.get_node_or_null("DamageLabel")

	if vbox.get_node_or_null("PresetLabel") == null:
		_preset_label = Label.new()
		_preset_label.name = "PresetLabel"
		vbox.add_child(_preset_label)
		var prow := HBoxContainer.new()
		var cycle := Button.new()
		cycle.text = "Cycle Preset"
		cycle.pressed.connect(_on_cycle_preset)
		prow.add_child(cycle)
		var savep := Button.new()
		savep.text = "Save Preset"
		savep.pressed.connect(_on_save_preset)
		prow.add_child(savep)
		var loadp := Button.new()
		loadp.text = "Load Preset"
		loadp.pressed.connect(_on_load_preset)
		prow.add_child(loadp)
		vbox.add_child(prow)
	else:
		_preset_label = vbox.get_node_or_null("PresetLabel")

	var confirm := vbox.get_node_or_null("Confirm")
	if confirm:
		vbox.move_child(confirm, vbox.get_child_count() - 1)

func _update_labels() -> void:
	if stock_label:
		stock_label.text = "Stocks: %d" % GameState.stocks
	if cpu_label:
		cpu_label.text = "CPU Level: %d / 5" % GameState.cpu_level
	if _timer_label:
		if GameState.match_timer_seconds <= 0:
			_timer_label.text = "Match Time: ∞"
		else:
			_timer_label.text = "Match Time: %ds" % GameState.match_timer_seconds
	if _p2_label:
		_p2_label.text = "P2: %s" % ("CPU" if GameState.p2_is_cpu else "Human (local multi)")
	if _damage_label:
		_damage_label.text = "Damage Ratio: %.2f  |  Team Attack: %s" % [
			GameState.damage_ratio,
			"On" if GameState.team_attack else "Off",
		]
	if _preset_label:
		_preset_label.text = "Preset: %s" % GameState.ruleset_preset_name

func _on_stock_minus() -> void:
	GameState.stocks = clampi(GameState.stocks - 1, 1, 9)
	_update_labels()

func _on_stock_plus() -> void:
	GameState.stocks = clampi(GameState.stocks + 1, 1, 9)
	_update_labels()

func _on_cpu_minus() -> void:
	GameState.cpu_level = clampi(GameState.cpu_level - 1, 1, 5)
	_update_labels()

func _on_cpu_plus() -> void:
	GameState.cpu_level = clampi(GameState.cpu_level + 1, 1, 5)
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

func _on_toggle_p2() -> void:
	GameState.p2_is_cpu = not GameState.p2_is_cpu
	GameState.p1_is_cpu = false
	_update_labels()

func _on_local_multi() -> void:
	GameState.begin_local_multiplayer()
	_update_labels()

func _on_damage_minus() -> void:
	GameState.damage_ratio = clampf(GameState.damage_ratio - 0.1, 0.5, 2.0)
	_update_labels()

func _on_damage_plus() -> void:
	GameState.damage_ratio = clampf(GameState.damage_ratio + 0.1, 0.5, 2.0)
	_update_labels()

func _on_toggle_team() -> void:
	GameState.team_attack = not GameState.team_attack
	_update_labels()

func _on_cycle_preset() -> void:
	var idx := PRESETS.find(GameState.ruleset_preset_name)
	idx = (idx + 1) % PRESETS.size()
	GameState.ruleset_preset_name = PRESETS[idx]
	match GameState.ruleset_preset_name:
		"tournament":
			GameState.stocks = 3
			GameState.match_timer_seconds = 420
			GameState.damage_ratio = 1.0
			GameState.team_attack = false
			GameState.cpu_level = 5
		"casual":
			GameState.stocks = 5
			GameState.match_timer_seconds = 180
			GameState.damage_ratio = 1.2
			GameState.cpu_level = 2
		"local-multi":
			GameState.begin_local_multiplayer()
			GameState.stocks = 3
			GameState.match_timer_seconds = 180
		_:
			GameState.stocks = 3
			GameState.match_timer_seconds = 180
			GameState.damage_ratio = 1.0
	_update_labels()

func _on_save_preset() -> void:
	GameState.save_ruleset_preset(GameState.ruleset_preset_name)
	_update_labels()

func _on_load_preset() -> void:
	GameState.load_ruleset_preset(GameState.ruleset_preset_name)
	_update_labels()

func _on_confirm_pressed() -> void:
	GameState.ruleset_id = "stock-%d" % GameState.stocks
	GameState.match_type = "stock" if GameState.match_timer_seconds > 0 else "stock_untimed"
	GameState._persist_save()
	SceneRouter.go("fighter_select")

func on_back() -> void:
	SceneRouter.go("mode_select")
