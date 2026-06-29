extends Node
class_name AuraCharge

signal meter_changed(current_value: float, level: int)
signal super_ready

@export var max_meter: float = 100.0
@export var charge_per_second: float = 22.0
@export var passive_gain_multiplier: float = 0.35
@export var burst_cost: float = 15.0
@export var level_thresholds: PackedFloat32Array = PackedFloat32Array([25.0, 50.0, 75.0, 100.0])

var meter: float = 0.0
var charging: bool = false
var current_level: int = 0

func start_charging() -> void:
	charging = true

func stop_charging() -> void:
	charging = false

func tick(delta: float) -> void:
	if charging:
		add_meter(charge_per_second * delta)
	else:
		add_meter(charge_per_second * passive_gain_multiplier * delta)

func add_meter(amount: float) -> void:
	var old_level := current_level
	meter = clampf(meter + amount, 0.0, max_meter)
	current_level = _resolve_level()
	meter_changed.emit(meter, current_level)
	if old_level < level_thresholds.size() and current_level >= level_thresholds.size():
		super_ready.emit()

func spend_meter(amount: float) -> bool:
	if meter < amount:
		return false
	meter -= amount
	current_level = _resolve_level()
	meter_changed.emit(meter, current_level)
	return true

func consume_small_burst() -> bool:
	return spend_meter(burst_cost)

func is_super_ready() -> bool:
	return meter >= max_meter

func _resolve_level() -> int:
	var level := 0
	for threshold in level_thresholds:
		if meter >= threshold:
			level += 1
	return level
