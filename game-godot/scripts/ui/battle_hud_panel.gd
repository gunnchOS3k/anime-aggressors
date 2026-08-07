extends Control
class_name BattleHudPanel

## Compact stock / % / aura meters without clutter.

var _name_label: Label
var _pct_label: Label
var _stock_row: HBoxContainer
var _aura_bar: ProgressBar
var _shield_bar: ProgressBar
var _stock_pips: Array = []
var _max_stocks: int = 3
var _accent: Color = Color(0.95, 0.55, 0.2)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()

func _build() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	root.add_child(top)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 18)
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_name_label)

	_pct_label = Label.new()
	_pct_label.add_theme_font_size_override("font_size", 28)
	_pct_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(_pct_label)

	_stock_row = HBoxContainer.new()
	_stock_row.add_theme_constant_override("separation", 6)
	root.add_child(_stock_row)

	_aura_bar = ProgressBar.new()
	_aura_bar.max_value = 100.0
	_aura_bar.show_percentage = false
	_aura_bar.custom_minimum_size = Vector2(0, 10)
	_aura_bar.tooltip_text = "Aura"
	root.add_child(_aura_bar)

	_shield_bar = ProgressBar.new()
	_shield_bar.max_value = 100.0
	_shield_bar.show_percentage = false
	_shield_bar.custom_minimum_size = Vector2(0, 6)
	_shield_bar.modulate = Color(0.45, 0.75, 1.0, 0.85)
	root.add_child(_shield_bar)

func configure(display_name: String, accent: Color, max_stocks: int, align_right: bool = false) -> void:
	_accent = accent
	_max_stocks = maxi(1, max_stocks)
	if _name_label:
		_name_label.text = display_name
		_name_label.add_theme_color_override("font_color", accent.lightened(0.25))
	if align_right and _name_label:
		_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_rebuild_pips()

func _rebuild_pips() -> void:
	for c in _stock_row.get_children():
		c.queue_free()
	_stock_pips.clear()
	for i in _max_stocks:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(14, 14)
		pip.color = _accent
		_stock_row.add_child(pip)
		_stock_pips.append(pip)

func update_from_fighter(f: Node) -> void:
	if f == null:
		return
	var pct: float = float(f.damage_percent) if "damage_percent" in f else 0.0
	var stocks: int = int(f.stocks) if "stocks" in f else 0
	var aura: float = float(f.aura) if "aura" in f else 0.0
	var shield: float = float(f.shield_health) if "shield_health" in f else 100.0
	if _pct_label:
		_pct_label.text = "%d%%" % int(pct)
		var heat := clampf(pct / 120.0, 0.0, 1.0)
		_pct_label.add_theme_color_override("font_color", Color(1.0, 1.0 - heat * 0.55, 1.0 - heat * 0.7))
	if _aura_bar:
		_aura_bar.value = aura
		var fill := StyleBoxFlat.new()
		fill.bg_color = _accent
		_aura_bar.add_theme_stylebox_override("fill", fill)
	if _shield_bar:
		_shield_bar.value = shield
		_shield_bar.visible = shield < 99.5 or (f.has_method("configure") and bool(f.shielding) if "shielding" in f else false)
	for i in _stock_pips.size():
		var pip: ColorRect = _stock_pips[i]
		pip.modulate = Color(1, 1, 1, 1) if i < stocks else Color(1, 1, 1, 0.18)
