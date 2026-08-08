extends RefCounted
class_name OnlineMatchmakingArchitecture

## Ranked + unranked online architecture (private/dev only).
## Does NOT claim public matchmaking deploy.

const SCOPE := "private_dev_only"
const TOKEN_SCOPE := "ANIME_DIGITAL_RC_ONLINE_ARCH"

var _unranked_queue: Array = []
var _ranked_ladder: Dictionary = {}  # name -> rating
var _rooms: Dictionary = {}
var _ranked_wait: Array = []


func enqueue_unranked(name: String) -> Dictionary:
	_unranked_queue.append({"name": name, "ts": Time.get_ticks_msec()})
	if _unranked_queue.size() >= 2:
		var a = _unranked_queue.pop_front()
		var b = _unranked_queue.pop_front()
		var code := "UQ-%d" % (Time.get_ticks_msec() % 100000)
		_rooms[code] = {"mode": "unranked", "players": [a.name, b.name], "status": "ready"}
		return {"ok": true, "paired": true, "room": code, "players": [a.name, b.name], "mode": "unranked"}
	return {"ok": true, "paired": false, "queue_depth": _unranked_queue.size(), "mode": "unranked"}


func ensure_rated(name: String, seed_rating: int = 1000) -> int:
	if not _ranked_ladder.has(name):
		_ranked_ladder[name] = seed_rating
	return int(_ranked_ladder[name])


func enqueue_ranked(name: String) -> Dictionary:
	var rating := ensure_rated(name)
	_ranked_wait.append({"name": name, "rating": rating})
	if _ranked_wait.size() >= 2:
		var a = _ranked_wait.pop_front()
		var b = _ranked_wait.pop_front()
		var code := "RQ-%d" % (Time.get_ticks_msec() % 100000)
		_rooms[code] = {"mode": "ranked", "players": [a.name, b.name], "status": "ready"}
		return {
			"ok": true,
			"paired": true,
			"room": code,
			"players": [a.name, b.name],
			"ratings": [a.rating, b.rating],
			"mode": "ranked",
		}
	return {"ok": true, "paired": false, "rating": rating, "mode": "ranked"}


func apply_ranked_result(winner: String, loser: String, k: int = 32) -> Dictionary:
	var rw := float(ensure_rated(winner))
	var rl := float(ensure_rated(loser))
	var expected_w := 1.0 / (1.0 + pow(10.0, (rl - rw) / 400.0))
	var expected_l := 1.0 - expected_w
	_ranked_ladder[winner] = int(round(rw + k * (1.0 - expected_w)))
	_ranked_ladder[loser] = int(round(rl + k * (0.0 - expected_l)))
	return {
		"ok": true,
		"winner": winner,
		"loser": loser,
		"ratings": {"winner": _ranked_ladder[winner], "loser": _ranked_ladder[loser]},
	}


func room_snapshot(code: String) -> Dictionary:
	return _rooms.get(code, {}).duplicate(true)


static func digital_self_test() -> Dictionary:
	var ScriptRef = load("res://scripts/net/online_matchmaking_architecture.gd")
	var mm = ScriptRef.new()
	var u1: Dictionary = mm.enqueue_unranked("U1")
	var u2: Dictionary = mm.enqueue_unranked("U2")
	var r1: Dictionary = mm.enqueue_ranked("R1")
	var r2: Dictionary = mm.enqueue_ranked("R2")
	var result: Dictionary = mm.apply_ranked_result("R1", "R2")
	var ok := bool(u1.get("ok")) and bool(u2.get("paired")) \
		and bool(r1.get("ok")) and bool(r2.get("paired")) \
		and bool(result.get("ok")) \
		and int(result.get("ratings", {}).get("winner", 0)) != 1000
	return {
		"ok": ok,
		"scope": SCOPE,
		"public_deploy": false,
		"features": ["unranked_queue", "ranked_ladder", "elo_update", "private_rooms"],
		"unranked": u2,
		"ranked": r2,
		"result": result,
		"token_scope": TOKEN_SCOPE,
	}
