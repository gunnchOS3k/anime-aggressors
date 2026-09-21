extends Node2D
## Lightweight stub for CpuController observation/recovery tests.

var slot: int = 2
var facing: int = 1
var damage_percent: float = 0.0
var aura: float = 0.0
var stocks: int = 3
var fighter_id: String = "ember-vale"
var platform_half_width: float = 484.0
var platform_center_x: float = 0.0
var platform_surface_y: float = 280.0
var controls_enabled: bool = true
var data: Dictionary = {"cpuBehaviorTags": ["rushdown"]}
var velocity: Vector2 = Vector2.ZERO
var _on_floor: bool = true
var state_machine = {"current_state": "idle"}


func is_on_floor() -> bool:
	return _on_floor


func is_offstage() -> bool:
	if _on_floor:
		return false
	return absf(global_position.x - platform_center_x) > platform_half_width + 8.0


func nearest_ledge_anchor() -> Vector2:
	var l := Vector2(platform_center_x - platform_half_width, platform_surface_y)
	var r := Vector2(platform_center_x + platform_half_width, platform_surface_y)
	return l if absf(global_position.x - l.x) <= absf(global_position.x - r.x) else r


func begin_cpu_telegraph(_cmd: String, _t: float) -> void:
	pass


func queue_attack_command(_cmd: String) -> void:
	pass


func _release_action(_action: String) -> void:
	if InputMap.has_action(_action) and Input.is_action_pressed(_action):
		Input.action_release(_action)
