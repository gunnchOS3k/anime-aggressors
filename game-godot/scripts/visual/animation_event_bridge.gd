extends Node
class_name AnimationEventBridge

## Bridge procedural animation events to JuiceEventBus without duplicating combat authority.

const _JuiceBusScript = preload("res://scripts/juice/juice_event_bus.gd")

var _bus: Node


func _ready() -> void:
	_bus = get_node_or_null("/root/JuiceEventBus")
	if _bus == null:
		_bus = _JuiceBusScript.new()
		_bus.name = "JuiceEventBridgeFallback"
		add_child(_bus)


func emit_from_anim_event(event_type: String, payload: Dictionary = {}) -> void:
	if _bus == null or not _bus.has_method("emit_event"):
		return
	match event_type:
		"hitbox_on", "active_start":
			_bus.emit_event("impact_vfx", payload)
			_bus.emit_event("hitstop", payload)
		"projectile_release":
			_bus.emit_event("projectile_trail", payload)
		"throw_release":
			_bus.emit_event("grab_flash", payload)
		"dodge_iframe":
			_bus.emit_event("dodge_phase", payload)
		"footstep":
			_bus.emit_event("landing_dust", payload)
		"aura_build":
			_bus.emit_event("aura_buildup", payload)
		"recovery_start":
			_bus.emit_event("recovery_trail", payload)
		_:
			_bus.emit_event("sfx", payload.merge({"event_type": event_type}))
