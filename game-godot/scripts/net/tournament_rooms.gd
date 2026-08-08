extends RefCounted
class_name TournamentRooms

## Private/dev tournament rooms — bracket seed + lobby. Not a public tournament platform.

const SCOPE := "private_dev_only"


var _rooms: Dictionary = {}


func create_room(host: String, size: int = 4) -> Dictionary:
	var code := "TR-%d" % (1000 + (_rooms.size() % 9000))
	var bracket: Array = []
	for i in range(size):
		bracket.append({"slot": i + 1, "player": "", "ready": false})
	_rooms[code] = {
		"code": code,
		"host": host,
		"size": size,
		"bracket": bracket,
		"status": "open",
		"spectators": [],
	}
	# Host takes slot 1
	join_player(code, host)
	return {"ok": true, "room": _rooms[code].duplicate(true)}


func join_player(code: String, name: String) -> Dictionary:
	if not _rooms.has(code):
		return {"ok": false, "error": "missing_room"}
	var room: Dictionary = _rooms[code]
	for slot in room.bracket:
		if str(slot.player) == "":
			slot.player = name
			slot.ready = false
			return {"ok": true, "room": room.duplicate(true)}
	return {"ok": false, "error": "full"}


func add_spectator(code: String, name: String) -> Dictionary:
	if not _rooms.has(code):
		return {"ok": false, "error": "missing_room"}
	_rooms[code].spectators.append(name)
	return {"ok": true, "spectators": _rooms[code].spectators.duplicate()}


func seed_bracket(code: String) -> Dictionary:
	if not _rooms.has(code):
		return {"ok": false, "error": "missing_room"}
	var room: Dictionary = _rooms[code]
	var players: Array = []
	for slot in room.bracket:
		if str(slot.player) != "":
			players.append(str(slot.player))
	# Stable seed by name hash for digital determinism.
	players.sort_custom(func(a, b): return str(a).hash() < str(b).hash())
	var matches: Array = []
	var i := 0
	while i + 1 < players.size():
		matches.append({"p1": players[i], "p2": players[i + 1], "status": "pending"})
		i += 2
	if players.size() % 2 == 1:
		matches.append({"p1": players[players.size() - 1], "p2": "BYE", "status": "bye"})
	room["matches"] = matches
	room["status"] = "seeded"
	return {"ok": true, "matches": matches, "room": room.duplicate(true)}


static func digital_self_test() -> Dictionary:
	var ScriptRef = load("res://scripts/net/tournament_rooms.gd")
	var tr = ScriptRef.new()
	var created: Dictionary = tr.create_room("HostA", 4)
	var code := str(created.get("room", {}).get("code", ""))
	tr.join_player(code, "P2")
	tr.join_player(code, "P3")
	tr.join_player(code, "P4")
	var spec: Dictionary = tr.add_spectator(code, "Spec1")
	var seeded: Dictionary = tr.seed_bracket(code)
	var ok := bool(created.get("ok")) and bool(spec.get("ok")) \
		and bool(seeded.get("ok")) and int(seeded.get("matches", []).size()) >= 2
	return {
		"ok": ok,
		"scope": SCOPE,
		"public_deploy": false,
		"features": ["create", "join", "spectator", "bracket_seed"],
		"room_code": code,
		"matches": seeded.get("matches", []),
	}
