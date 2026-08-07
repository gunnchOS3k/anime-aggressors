extends Node

## Lightweight match telemetry hooks — match_start / hit / ko / stock_loss.
## No PII; ring-buffer only for training/debug and validation.

signal event_recorded(event: Dictionary)

const MAX_EVENTS := 128

var _events: Array = []
var _match_id: String = ""
var _started_at_ms: int = 0

func start_match(info: Dictionary = {}) -> void:
	_events.clear()
	_started_at_ms = Time.get_ticks_msec()
	_match_id = "m_%d" % _started_at_ms
	record("match_start", {
		"match_id": _match_id,
		"p1": info.get("p1", ""),
		"p2": info.get("p2", ""),
		"stage": info.get("stage", ""),
		"stocks": info.get("stocks", 3),
		"timer": info.get("timer", 0),
		"device_role": info.get("device_role", ""),
	})

func record_hit(info: Dictionary) -> void:
	record("hit", {
		"move_id": info.get("move_id", ""),
		"damage": info.get("damage", 0.0),
		"blocked": info.get("blocked", false),
		"hitstop_frames": info.get("hitstop_frames", 0),
	})

func record_ko(fighter_id: String, stocks_left: int) -> void:
	record("ko", {"fighter_id": fighter_id, "stocks_left": stocks_left})

func record_stock_loss(fighter_id: String, stocks_left: int) -> void:
	record("stock_loss", {"fighter_id": fighter_id, "stocks_left": stocks_left})

func record_match_end(winner_slot: int) -> void:
	record("match_end", {"winner_slot": winner_slot, "match_id": _match_id})

func record(kind: String, payload: Dictionary = {}) -> void:
	var evt := {
		"t_ms": Time.get_ticks_msec() - _started_at_ms,
		"kind": kind,
		"payload": payload,
	}
	_events.append(evt)
	if _events.size() > MAX_EVENTS:
		_events.pop_front()
	event_recorded.emit(evt)

func recent(limit: int = 24) -> Array:
	if _events.size() <= limit:
		return _events.duplicate(true)
	return _events.slice(_events.size() - limit)

func count_of(kind: String) -> int:
	var n := 0
	for e in _events:
		if e.get("kind", "") == kind:
			n += 1
	return n

func clear() -> void:
	_events.clear()
	_match_id = ""
