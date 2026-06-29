extends Control
class_name AuraMeter

@export var progress_bar_path: NodePath
@export var level_label_path: NodePath
@export var aura_charge_path: NodePath

var progress_bar: Range
var level_label: Label
var fill_bar: ColorRect
var aura_charge: AuraCharge

func _ready() -> void:
	progress_bar = get_node_or_null(progress_bar_path)
	level_label = get_node_or_null(level_label_path) as Label
	if level_label == null:
		level_label = get_node_or_null("Label") as Label
	fill_bar = get_node_or_null("Fill") as ColorRect
	aura_charge = get_node_or_null(aura_charge_path)
	if aura_charge != null:
		aura_charge.meter_changed.connect(_on_meter_changed)
		_on_meter_changed(aura_charge.meter, aura_charge.current_level)

func bind_charge(target_charge: AuraCharge) -> void:
	if aura_charge != null and aura_charge.meter_changed.is_connected(_on_meter_changed):
		aura_charge.meter_changed.disconnect(_on_meter_changed)
	aura_charge = target_charge
	if aura_charge != null:
		aura_charge.meter_changed.connect(_on_meter_changed)
		_on_meter_changed(aura_charge.meter, aura_charge.current_level)

func _on_meter_changed(current_meter: float, level: int) -> void:
	var max_meter := maxf(1.0, aura_charge.max_meter if aura_charge != null else 100.0)
	if progress_bar != null:
		progress_bar.max_value = max_meter
		progress_bar.value = current_meter
	if fill_bar != null:
		var ratio := clampf(current_meter / max_meter, 0.0, 1.0)
		fill_bar.size.x = 200.0 * ratio
	if level_label != null:
		level_label.text = "Aura L%s" % level
