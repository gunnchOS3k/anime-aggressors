extends Node
class_name ControllerWatchdog

## Digital RC controller disconnect/reconnect handling (local device).

signal controller_disconnected(device_id: int)
signal controller_reconnected(device_id: int)

var last_event: Dictionary = {}
var connected_ids: Array = []


func _ready() -> void:
	if not Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_refresh()


func _refresh() -> void:
	connected_ids.clear()
	for id in Input.get_connected_joypads():
		connected_ids.append(int(id))


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	_refresh()
	last_event = {
		"device": device,
		"connected": connected,
		"at_ms": Time.get_ticks_msec(),
	}
	if connected:
		controller_reconnected.emit(device)
	else:
		controller_disconnected.emit(device)


func is_any_connected() -> bool:
	return not Input.get_connected_joypads().is_empty()


static func self_test() -> Dictionary:
	## Headless-safe: exercise API without requiring physical pads.
	var ScriptRef = load("res://scripts/input/controller_watchdog.gd")
	var w = ScriptRef.new()
	var before: Array = Input.get_connected_joypads()
	w._refresh()
	w._on_joy_connection_changed(0, false)
	var disc: Dictionary = w.last_event.duplicate(true)
	w._on_joy_connection_changed(0, true)
	var recon: Dictionary = w.last_event.duplicate(true)
	var ok: bool = int(disc.get("device", -1)) == 0 and bool(disc.get("connected", true)) == false \
		and int(recon.get("device", -1)) == 0 and bool(recon.get("connected", false)) == true
	return {
		"ok": ok,
		"pads_at_test": before.size(),
		"disconnect_event": disc,
		"reconnect_event": recon,
	}
