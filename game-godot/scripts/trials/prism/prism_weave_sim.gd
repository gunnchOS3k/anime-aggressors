extends RefCounted
class_name PrismWeaveSim
## Paint the Floor / Prism Weave — 60s territorial weave.
## Ten-fighter capacity; harmonic tiles (bounded); accessibility beyond color.

const Authority = preload("res://scripts/trials/mode_authority.gd")
const SIM_HZ := 60
const MATCH_FRAMES := 60 * SIM_HZ
const COLS := 24
const ROWS := 14
const MAX_FIGHTERS := 10

## Pattern markers for colorblind / high-contrast (not color-only).
const TEAM_MARKERS := ["circle", "square", "triangle", "diamond", "cross", "star", "hex", "wave", "ring", "bar"]


static func create(seed: int = 1, fighter_count: int = 2) -> Dictionary:
	var n: int = clampi(fighter_count, 2, MAX_FIGHTERS)
	var fighters: Array = []
	var roster := ["ember-vale", "rook-ironside", "juno-spark", "kaia-windrow", "nix-calder", "orion-vell", "vesper-nyx", "yin", "yang", "rosamere"]
	for i in range(n):
		fighters.append({
			"slot": i,
			"fighter_id": roster[i % roster.size()],
			"x": 1 + (i % 5) * 4,
			"y": 1 + (i / 5) * 6,
			"team": i,
			"marker": TEAM_MARKERS[i % TEAM_MARKERS.size()],
			"score": 0,
			"alive": true,
		})
	var grid: Array = []
	for _y in range(ROWS):
		var row: Array = []
		for _x in range(COLS):
			row.append(-1)
		grid.append(row)
	return {
		"mode": "prism_weave",
		"legacy_mode": "paintFloor",
		"frame": 0,
		"seed": seed,
		"phase": "play",
		"timer_frames": MATCH_FRAMES,
		"fighters": fighters,
		"grid": grid,
		"harmonic_tiles": _seed_harmonics(seed),
		"accessibility": {"markers_beyond_color": true, "high_contrast_ready": true},
		"winner_slot": -1,
		"max_fighters": MAX_FIGHTERS,
	}


static func _seed_harmonics(seed: int) -> Array:
	## Bounded harmonic tiles — fixed count, seeded positions (not unbounded spam).
	var rng: Callable = Authority.mulberry32(seed ^ 0xA11CE)
	var tiles: Array = []
	for i in range(6):
		tiles.append({
			"x": int(rng.call() * COLS) % COLS,
			"y": int(rng.call() * ROWS) % ROWS,
			"pulse": int(rng.call() * 30) + 20,
			"owner": -1,
		})
	return tiles


static func paint(state: Dictionary, slot: int, x: int, y: int) -> void:
	if slot < 0 or slot >= state["fighters"].size():
		return
	if x < 0 or y < 0 or x >= COLS or y >= ROWS:
		return
	state["grid"][y][x] = slot
	for h in state.get("harmonic_tiles", []):
		if int(h.get("x", -1)) == x and int(h.get("y", -1)) == y:
			h["owner"] = slot


static func _recount(state: Dictionary) -> void:
	for f in state["fighters"]:
		f["score"] = 0
	for y in range(ROWS):
		for x in range(COLS):
			var owner: int = int(state["grid"][y][x])
			if owner >= 0 and owner < state["fighters"].size():
				state["fighters"][owner]["score"] = int(state["fighters"][owner]["score"]) + 1
	## Harmonic bonus (bounded).
	for h in state.get("harmonic_tiles", []):
		var o: int = int(h.get("owner", -1))
		if o >= 0 and o < state["fighters"].size():
			state["fighters"][o]["score"] = int(state["fighters"][o]["score"]) + 3


static func step(state: Dictionary, moves: Array = []) -> Dictionary:
	var next: Dictionary = state.duplicate(true)
	if str(next.get("phase", "")) == "results":
		return next
	next["frame"] = int(next.get("frame", 0)) + 1
	next["timer_frames"] = maxi(0, int(next.get("timer_frames", 0)) - 1)
	var fighters: Array = next["fighters"]
	for m in moves:
		if typeof(m) != TYPE_DICTIONARY:
			continue
		var slot: int = int(m.get("slot", -1))
		if slot < 0 or slot >= fighters.size():
			continue
		var f: Dictionary = fighters[slot]
		f["x"] = clampi(int(f.get("x", 0)) + int(m.get("dx", 0)), 0, COLS - 1)
		f["y"] = clampi(int(f.get("y", 0)) + int(m.get("dy", 0)), 0, ROWS - 1)
		paint(next, slot, int(f["x"]), int(f["y"]))
	## Seeded idle weave for empty seats so solo tests progress.
	if moves.is_empty():
		var rng: Callable = Authority.mulberry32(int(next.get("seed", 1)) + int(next.get("frame", 0)))
		for f in fighters:
			var dx: int = 1 if rng.call() > 0.5 else -1
			var dy: int = 1 if rng.call() > 0.5 else 0
			f["x"] = clampi(int(f["x"]) + dx, 0, COLS - 1)
			f["y"] = clampi(int(f["y"]) + dy, 0, ROWS - 1)
			paint(next, int(f["slot"]), int(f["x"]), int(f["y"]))
	_recount(next)
	if int(next["timer_frames"]) <= 0:
		next["phase"] = "results"
		var best: int = -1
		var best_score: int = -1
		for f in fighters:
			if int(f.get("score", 0)) > best_score:
				best_score = int(f.get("score", 0))
				best = int(f.get("slot", -1))
		next["winner_slot"] = best
	return next


static func state_hash(state: Dictionary) -> String:
	var scores: Array = []
	for f in state.get("fighters", []):
		scores.append(f.get("score", 0))
	return Authority.hash_parts(int(state.get("seed", 0)), [
		state.get("frame", 0), state.get("phase", ""), state.get("timer_frames", 0), state.get("winner_slot", -1),
	] + scores)


static func run_to_results(seed: int = 3, fighters: int = 4) -> Dictionary:
	var s := create(seed, fighters)
	var guard: int = 0
	while str(s.get("phase", "")) != "results" and guard < MATCH_FRAMES + 10:
		s = step(s)
		guard += 1
	return s
