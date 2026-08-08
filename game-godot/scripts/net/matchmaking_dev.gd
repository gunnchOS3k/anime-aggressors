extends RefCounted
class_name MatchmakingDev

## DEV-only private matchmaking: in-process room pool (no public internet).
## Rooms are host-created; join by code or auto-pair from waiting queue.

const _AntiTamper = preload("res://scripts/net/anti_tamper.gd")

var _rooms: Dictionary = {}  # code -> {host, guests, spectators, status, created_ms}
var _waiting: Array = []  # [{name, since_ms}]
var _next_code: int = 1000


func reset() -> void:
	_rooms.clear()
	_waiting.clear()
	_next_code = 1000


func create_room(host_name: String, now_ms: float = 0.0) -> Dictionary:
	var code: String = "AA-%d" % _next_code
	_next_code += 1
	_rooms[code] = {
		"code": code,
		"host": host_name,
		"guests": [],
		"spectators": [],
		"status": "open",
		"created_ms": now_ms,
		"build": _AntiTamper.BUILD_ID,
	}
	return {"ok": true, "room": _rooms[code].duplicate(true)}


func join_room(code: String, guest_name: String) -> Dictionary:
	if not _rooms.has(code):
		return {"ok": false, "error": "room_not_found"}
	var room: Dictionary = _rooms[code]
	if str(room.get("status", "")) != "open":
		return {"ok": false, "error": "room_closed"}
	if str(room.get("build", "")) != _AntiTamper.BUILD_ID:
		return {"ok": false, "error": "version_incompatible"}
	var guests: Array = room.get("guests", [])
	if guests.size() >= 1:
		return {"ok": false, "error": "room_full"}
	guests.append(guest_name)
	room["guests"] = guests
	room["status"] = "matched"
	return {"ok": true, "room": room.duplicate(true)}


func spectate_room(code: String, name: String) -> Dictionary:
	if not _rooms.has(code):
		return {"ok": false, "error": "room_not_found"}
	var room: Dictionary = _rooms[code]
	var specs: Array = room.get("spectators", [])
	specs.append(name)
	room["spectators"] = specs
	return {"ok": true, "room": room.duplicate(true)}


func enqueue_matchmaking(name: String, now_ms: float = 0.0) -> Dictionary:
	_waiting.append({"name": name, "since_ms": now_ms})
	if _waiting.size() >= 2:
		var a: Dictionary = _waiting.pop_front()
		var b: Dictionary = _waiting.pop_front()
		var created: Dictionary = create_room(str(a.get("name", "A")), now_ms)
		var code: String = str(created.get("room", {}).get("code", ""))
		return join_room(code, str(b.get("name", "B")))
	return {"ok": true, "queued": true, "queue_size": _waiting.size()}


func list_open_rooms() -> Array:
	var out: Array = []
	for code in _rooms.keys():
		var r: Dictionary = _rooms[code]
		if str(r.get("status", "")) == "open":
			out.append(r.duplicate(true))
	return out


static func self_test() -> Dictionary:
	var ScriptRef = load("res://scripts/net/matchmaking_dev.gd")
	var mm = ScriptRef.new()
	mm.reset()
	var c: Dictionary = mm.create_room("Host")
	var code: String = str(c.get("room", {}).get("code", ""))
	var j: Dictionary = mm.join_room(code, "Guest")
	var s: Dictionary = mm.spectate_room(code, "Watcher")
	mm.reset()
	var q1: Dictionary = mm.enqueue_matchmaking("A")
	var q2: Dictionary = mm.enqueue_matchmaking("B")
	var ok: bool = bool(c.get("ok", false)) and bool(j.get("ok", false)) \
		and str(j.get("room", {}).get("status", "")) == "matched" \
		and bool(s.get("ok", false)) and int(s.get("room", {}).get("spectators", []).size()) == 1 \
		and bool(q1.get("queued", false)) and bool(q2.get("ok", false)) \
		and str(q2.get("room", {}).get("status", "")) == "matched"
	return {"ok": ok, "code": code, "queue_pair": q2}
