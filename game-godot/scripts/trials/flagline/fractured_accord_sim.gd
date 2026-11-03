extends RefCounted
class_name FracturedAccordSim
## Flagline Clash / Fractured Accord — five-room push-pull (-2..+2).
## Internal IDs solar/lunar; display aliases Beaconward / Veilward (lunar→Veilward).
## 2v2 + CPU fill; capture / overtime / stronghold. Yin/Yang not ordinary captains.

const Authority = preload("res://scripts/trials/mode_authority.gd")
const SIM_HZ := 60

const TEAM_PUSH := {"solar": -1, "lunar": 1}
const DISPLAY_ALIAS := {"solar": "Beaconward", "lunar": "Veilward"}
## Proposed territory names — art direction only; gameplay uses room indices.
const ART_TERRITORY_NAMES := {
	-2: "Veilward Sanctum",
	-1: "Moonlit Corridor",
	0: "Accord Fracture",
	1: "Sunward Corridor",
	2: "Beaconward Keep",
}


static func display_team(team_id: String) -> String:
	return str(DISPLAY_ALIAS.get(team_id, team_id))


static func create(seed: int = 1, start_room: int = 0, connected_humans: int = 2) -> Dictionary:
	## 2v2 + capture. connected_humans = real human seats only; remainder are CPU bots.
	## Never invent human seats. 2-fighter BattleScene still ≠ 4 simultaneous humans.
	var humans: int = clampi(connected_humans, 0, 4)
	var roster := [
		{"fighter_id": "ember-vale", "team_id": "solar"},
		{"fighter_id": "rook-ironside", "team_id": "lunar"},
		{"fighter_id": "juno-spark", "team_id": "solar"},
		{"fighter_id": "kaia-windrow", "team_id": "lunar"},
	]
	var slots: Array = []
	for i in range(4):
		var entry: Dictionary = roster[i].duplicate(true)
		entry["player_id"] = i
		entry["is_bot"] = i >= humans
		entry["is_human"] = i < humans
		slots.append(entry)
	return {
		"mode": "fractured_accord",
		"legacy_mode": "flaglineClash",
		"frame": 0,
		"seed": seed,
		"phase": "intro",
		"current_room": clampi(start_room, -2, 2),
		"rooms_won": {"solar": 0, "lunar": 0},
		"room_history": [],
		"capture": {"solar": 0.0, "lunar": 0.0, "contested": false, "controlling": ""},
		"winning_team": "",
		"room_winner": "",
		"room_win_reason": "",
		"room_timer_frames": 180 * SIM_HZ,
		"intro_frames": 3 * SIM_HZ,
		"transition_frames": 0,
		"team_slots": slots,
		"connected_humans": humans,
		"battle_scene_fighter_slots": 4,
		"stocks": [3, 3, 3, 3],
		"in_core": [false, false, false, false],
		## Four actor world positions — live BattleSim bodies when trial_four_body.
		"actor_positions": [
			{"x": 720.0, "y": 540.0},
			{"x": 1200.0, "y": 540.0},
			{"x": 640.0, "y": 620.0},
			{"x": 1280.0, "y": 620.0},
		],
		"multi_actor_depth": true,
		"logical_actor_count": 4,
		"actual_combat_bodies": false,
		"logical_cpu_only": true,
		"config": {
			"capture_to_win": 100.0,
			"capture_rate": 12.0,
			"decay_rate": 4.0,
			"contested_pause": true,
			"overtime_enabled": true,
			"team_wipe_wins_room": false,
			"bots_enabled": true,
			"twovstwo_plus_capture": true,
			"independent_cpu_fill": true,
		},
		"yin_yang_not_ordinary_captains": true,
		"display_alias": DISPLAY_ALIAS.duplicate(),
		"art_territory_name": str(ART_TERRITORY_NAMES.get(clampi(start_room, -2, 2), "")),
		"result_kind": "SIMULATION",
		"honesty": {
			"battle_scene_fighter_slots": 4,
			"logical_actors": 4,
			"extra_seats_are_cpu_or_lobby": humans < 4,
			"not_four_simultaneous_human_bodies": humans < 4,
			"actual_combat_bodies_require_live_bridge": true,
		},
	}


static func next_room(current: int, winner: String) -> Variant:
	var delta: int = int(TEAM_PUSH.get(winner, 0))
	if winner == "solar" and current == -2:
		return "solarWinsGame"
	if winner == "lunar" and current == 2:
		return "lunarWinsGame"
	var nxt: int = current + delta
	if nxt < -2 or nxt > 2:
		return "solarWinsGame" if winner == "solar" else "lunarWinsGame"
	return nxt


static func _counts_in_core(state: Dictionary) -> Dictionary:
	var solar: int = 0
	var lunar: int = 0
	var slots: Array = state.get("team_slots", [])
	var in_core: Array = state.get("in_core", [])
	var stocks: Array = state.get("stocks", [])
	for i in range(mini(slots.size(), in_core.size())):
		if int(stocks[i]) <= 0:
			continue
		if not bool(in_core[i]):
			continue
		if str(slots[i].get("team_id", "")) == "solar":
			solar += 1
		else:
			lunar += 1
	return {"solar": solar, "lunar": lunar}


static func _update_capture(state: Dictionary) -> void:
	var cfg: Dictionary = state["config"]
	var counts: Dictionary = _counts_in_core(state)
	var cap: Dictionary = state["capture"]
	var contested: bool = int(counts.solar) > 0 and int(counts.lunar) > 0
	cap["contested"] = contested
	var rate: float = float(cfg.get("capture_rate", 12.0)) / float(SIM_HZ)
	var decay: float = float(cfg.get("decay_rate", 4.0)) / float(SIM_HZ)
	if contested and bool(cfg.get("contested_pause", true)):
		cap["controlling"] = ""
	elif int(counts.solar) > 0:
		cap["controlling"] = "solar"
		cap["solar"] = minf(100.0, float(cap.get("solar", 0.0)) + rate)
		cap["lunar"] = maxf(0.0, float(cap.get("lunar", 0.0)) - decay)
	elif int(counts.lunar) > 0:
		cap["controlling"] = "lunar"
		cap["lunar"] = minf(100.0, float(cap.get("lunar", 0.0)) + rate)
		cap["solar"] = maxf(0.0, float(cap.get("solar", 0.0)) - decay)
	else:
		cap["controlling"] = ""
		cap["solar"] = maxf(0.0, float(cap.get("solar", 0.0)) - decay)
		cap["lunar"] = maxf(0.0, float(cap.get("lunar", 0.0)) - decay)
	state["capture"] = cap


static func _team_alive(state: Dictionary, team_id: String) -> bool:
	var slots: Array = state.get("team_slots", [])
	var stocks: Array = state.get("stocks", [])
	for i in range(slots.size()):
		if str(slots[i].get("team_id", "")) == team_id and int(stocks[i]) > 0:
			return true
	return false


static func _resolve_room_win(state: Dictionary, winner: String, reason: String) -> void:
	state["room_winner"] = winner
	state["room_win_reason"] = reason
	state["rooms_won"][winner] = int(state["rooms_won"].get(winner, 0)) + 1
	var hist: Array = state.get("room_history", [])
	hist.append({
		"room": state["current_room"],
		"winner": winner,
		"display_winner": display_team(winner),
		"reason": reason,
		"frame": state["frame"],
	})
	state["room_history"] = hist
	state["phase"] = "roomWon"
	state["transition_frames"] = 2 * SIM_HZ
	var nxt = next_room(int(state["current_room"]), winner)
	if typeof(nxt) == TYPE_STRING:
		state["phase"] = "gameWon"
		state["winning_team"] = winner
	else:
		state["pending_room"] = int(nxt)


static func set_presence(state: Dictionary, slot: int, in_core: bool) -> void:
	var arr: Array = state.get("in_core", [false, false, false, false])
	if slot >= 0 and slot < arr.size():
		arr[slot] = in_core
	state["in_core"] = arr


static func apply_stock_loss(state: Dictionary, slot: int) -> void:
	var stocks: Array = state.get("stocks", [])
	if slot < 0 or slot >= stocks.size():
		return
	stocks[slot] = maxi(0, int(stocks[slot]) - 1)
	state["stocks"] = stocks


static func step(state: Dictionary, _inputs: Array = []) -> Dictionary:
	var next: Dictionary = state.duplicate(true)
	if str(next.get("phase", "")) == "gameWon":
		return next
	next["frame"] = int(next.get("frame", 0)) + 1
	var phase := str(next.get("phase", "intro"))

	if phase == "intro":
		next["intro_frames"] = maxi(0, int(next.get("intro_frames", 0)) - 1)
		if int(next["intro_frames"]) <= 0:
			next["phase"] = "roomFight"
		return next

	if phase == "roomWon":
		next["transition_frames"] = maxi(0, int(next.get("transition_frames", 0)) - 1)
		if int(next["transition_frames"]) <= 0 and next.has("pending_room"):
			next["current_room"] = int(next["pending_room"])
			next["art_territory_name"] = str(ART_TERRITORY_NAMES.get(int(next["current_room"]), ""))
			next.erase("pending_room")
			next["capture"] = {"solar": 0.0, "lunar": 0.0, "contested": false, "controlling": ""}
			next["stocks"] = [3, 3, 3, 3]
			next["in_core"] = [false, false, false, false]
			next["room_timer_frames"] = 180 * SIM_HZ
			next["phase"] = "roomFight"
			next["room_winner"] = ""
			next["room_win_reason"] = ""
		return next

	if phase != "roomFight":
		return next

	## CPU fill bots drift into core when bots_enabled — deterministic from seed+frame.
	if bool(next["config"].get("bots_enabled", true)):
		var rng: Callable = Authority.mulberry32(int(next.get("seed", 1)) + int(next.get("frame", 0)))
		var slots: Array = next.get("team_slots", [])
		var in_core: Array = next.get("in_core", [])
		for i in range(slots.size()):
			if bool(slots[i].get("is_bot", false)):
				in_core[i] = rng.call() > 0.55
		next["in_core"] = in_core

	_update_capture(next)
	var cap: Dictionary = next["capture"]
	var to_win: float = float(next["config"].get("capture_to_win", 100.0))
	if float(cap.get("solar", 0.0)) >= to_win:
		_resolve_room_win(next, "solar", "flagCapture")
		return next
	if float(cap.get("lunar", 0.0)) >= to_win:
		_resolve_room_win(next, "lunar", "flagCapture")
		return next

	if not _team_alive(next, "solar") and _team_alive(next, "lunar"):
		if bool(next["config"].get("team_wipe_wins_room", false)):
			_resolve_room_win(next, "lunar", "teamWipe")
			return next
	if not _team_alive(next, "lunar") and _team_alive(next, "solar"):
		if bool(next["config"].get("team_wipe_wins_room", false)):
			_resolve_room_win(next, "solar", "teamWipe")
			return next

	next["room_timer_frames"] = maxi(0, int(next.get("room_timer_frames", 0)) - 1)
	if int(next["room_timer_frames"]) <= 0:
		if bool(next["config"].get("overtime_enabled", true)):
			## Stronghold overtime: higher capture wins; tie → contested hold breaks for leading rooms_won.
			var s: float = float(cap.get("solar", 0.0))
			var l: float = float(cap.get("lunar", 0.0))
			if s > l:
				_resolve_room_win(next, "solar", "overtime")
			elif l > s:
				_resolve_room_win(next, "lunar", "overtime")
			else:
				var rw: Dictionary = next.get("rooms_won", {})
				if int(rw.get("solar", 0)) >= int(rw.get("lunar", 0)):
					_resolve_room_win(next, "solar", "overtime")
				else:
					_resolve_room_win(next, "lunar", "overtime")
		else:
			_resolve_room_win(next, "solar" if int(next["current_room"]) <= 0 else "lunar", "overtime")
	return next


static func state_hash(state: Dictionary) -> String:
	return Authority.hash_parts(int(state.get("seed", 0)), [
		state.get("frame", 0), state.get("phase", ""), state.get("current_room", 0),
		state["capture"].get("solar", 0), state["capture"].get("lunar", 0),
		state.get("winning_team", ""), state["rooms_won"].get("solar", 0), state["rooms_won"].get("lunar", 0),
	])


static func run_capture_journey(seed: int = 7, connected_humans: int = 2) -> Dictionary:
	## Headless SIMULATION journey: force Beaconward presence until capture → push rooms.
	## Not a REAL_PLAYER earned receipt.
	var s := create(seed, 0, connected_humans)
	s["config"]["bots_enabled"] = false
	while str(s.get("phase", "")) == "intro":
		s = step(s)
	var guard: int = 0
	while str(s.get("phase", "")) != "gameWon" and guard < 60 * 900:
		## Beaconward (solar) holds core uncontested; Veilward kept out.
		set_presence(s, 0, true)
		set_presence(s, 2, true)
		set_presence(s, 1, false)
		set_presence(s, 3, false)
		s = step(s)
		guard += 1
	s["result_kind"] = "SIMULATION"
	s["earned_personal_best"] = false
	s["honesty"] = "run_capture_journey is SIMULATION — 2v2+capture rules exercised, not REAL_PLAYER"
	return s


static func actor_slots(state: Dictionary) -> Array:
	## Real 2v2 logical actors (humans + CPU fill) — not HUD-only.
	return state.get("team_slots", [])


static func occupancy_summary(state: Dictionary) -> Dictionary:
	var counts: Dictionary = _counts_in_core(state)
	var cap: Dictionary = state.get("capture", {})
	## Contested is live occupancy truth (both teams in core), not HUD-only.
	var contested_live: bool = int(counts.get("solar", 0)) > 0 and int(counts.get("lunar", 0)) > 0
	return {
		"solar_in_core": int(counts.get("solar", 0)),
		"lunar_in_core": int(counts.get("lunar", 0)),
		"contested": contested_live or bool(cap.get("contested", false)),
		"controlling": str(cap.get("controlling", "")),
		"solar_capture": float(cap.get("solar", 0.0)),
		"lunar_capture": float(cap.get("lunar", 0.0)),
		"current_room": int(state.get("current_room", 0)),
		"phase": str(state.get("phase", "")),
		"rooms_won": state.get("rooms_won", {}),
		"art_territory_name": str(state.get("art_territory_name", "")),
		"overtime_enabled": bool(state.get("config", {}).get("overtime_enabled", true)),
		"stronghold_rooms": [-2, 2],
		"actor_count": actor_slots(state).size(),
		"connected_humans": int(state.get("connected_humans", 0)),
		"battle_scene_fighter_slots": int(state.get("battle_scene_fighter_slots", 4)),
		"multi_actor_depth": bool(state.get("multi_actor_depth", false)),
		"logical_actor_count": int(state.get("logical_actor_count", actor_slots(state).size())),
		"independent_cpu_fill": bool(state.get("config", {}).get("independent_cpu_fill", false)),
		"actual_combat_bodies": bool(state.get("actual_combat_bodies", false)),
		"logical_cpu_only": bool(state.get("logical_cpu_only", not bool(state.get("actual_combat_bodies", false)))),
		"actor_positions": state.get("actor_positions", []),
	}


static func _set_actor_position(state: Dictionary, slot: int, pos: Vector2) -> void:
	var arr: Array = state.get("actor_positions", [])
	while arr.size() < 4:
		arr.append({"x": 960.0, "y": 540.0})
	if slot < 0 or slot >= arr.size():
		return
	arr[slot] = {"x": pos.x, "y": pos.y}
	state["actor_positions"] = arr


static func _teammate_human_position(state: Dictionary, bot_slot: int) -> Vector2:
	## Prefer the first human on the same team as an anchor (independent fill, not hard mirror).
	var slots: Array = state.get("team_slots", [])
	var positions: Array = state.get("actor_positions", [])
	if bot_slot < 0 or bot_slot >= slots.size():
		return Vector2(960, 540)
	var team: String = str(slots[bot_slot].get("team_id", ""))
	for i in range(slots.size()):
		if i == bot_slot:
			continue
		if bool(slots[i].get("is_human", false)) and str(slots[i].get("team_id", "")) == team:
			var p: Dictionary = positions[i] if i < positions.size() else {}
			return Vector2(float(p.get("x", 960.0)), float(p.get("y", 540.0)))
	return Vector2(960, 540)


static func _advance_independent_cpu_fill(
	state: Dictionary,
	core_center: Vector2,
	core_radius: float
) -> void:
	## CPU seats are independent actors beyond BattleScene's 2 slots — not hard mirrors.
	## Soft-anchor to teammate human so occupancy stays honest under 2-body live sync.
	if not bool(state.get("config", {}).get("independent_cpu_fill", true)):
		return
	var rng: Callable = Authority.mulberry32(int(state.get("seed", 1)) * 7919 + int(state.get("frame", 0)))
	var slots: Array = state.get("team_slots", [])
	var positions: Array = state.get("actor_positions", [])
	for i in range(mini(slots.size(), positions.size())):
		if not bool(slots[i].get("is_bot", false)):
			continue
		var cur: Dictionary = positions[i]
		var pos := Vector2(float(cur.get("x", 960.0)), float(cur.get("y", 540.0)))
		var anchor: Vector2 = _teammate_human_position(state, i)
		var cap: Dictionary = state.get("capture", {})
		var solar_cap: float = float(cap.get("solar", 0.0))
		var lunar_cap: float = float(cap.get("lunar", 0.0))
		var team: String = str(slots[i].get("team_id", ""))
		var press_core: bool = true
		if team == "solar":
			press_core = solar_cap <= lunar_cap + 8.0 or rng.call() > 0.4
		else:
			press_core = lunar_cap <= solar_cap + 8.0 or rng.call() > 0.4
		## Blend teammate anchor (keeps team occupancy coherent) with core pressure (depth).
		var to_anchor: Vector2 = (anchor - pos) * 0.35
		var toward_core: Vector2 = (core_center - pos).normalized() if pos.distance_to(core_center) > 1.0 else Vector2.ZERO
		var step_px: float = 14.0 + float(rng.call()) * 18.0
		pos += to_anchor
		if press_core and anchor.distance_to(core_center) <= core_radius * 1.35:
			pos += toward_core * step_px
		elif not press_core:
			pos -= toward_core * step_px * 0.45
			pos.x += (float(rng.call()) - 0.5) * 20.0
		else:
			## Human teammate outside core → bot loiters near teammate (no false contested).
			pos += (anchor - pos) * 0.25
		positions[i] = {"x": pos.x, "y": pos.y}
		set_presence(state, i, pos.distance_to(core_center) <= core_radius)
	state["actor_positions"] = positions


static func sync_live_presence_from_actor_positions(
	state: Dictionary,
	positions: Array,
	core_center: Vector2 = Vector2(960, 540),
	core_radius: float = 160.0
) -> Dictionary:
	## Accept up to 4 world positions for logical 2v2 actors.
	## Missing slots keep prior positions / independent CPU fill.
	var next: Dictionary = state.duplicate(true)
	var count: int = mini(positions.size(), 4)
	for i in range(count):
		var p: Variant = positions[i]
		if typeof(p) != TYPE_VECTOR2:
			continue
		_set_actor_position(next, i, p)
		set_presence(next, i, p.distance_to(core_center) <= core_radius)
	## Fill remaining bot seats with independent multi-actor AI (beyond BattleScene 2 slots).
	_advance_independent_cpu_fill(next, core_center, core_radius)
	next["live_actor_sync"] = true
	next["multi_actor_depth"] = true
	next["core_center"] = {"x": core_center.x, "y": core_center.y, "radius": core_radius}
	return next


static func sync_live_presence_from_positions(
	state: Dictionary,
	p1_pos: Vector2,
	p2_pos: Vector2,
	core_center: Vector2 = Vector2(960, 540),
	core_radius: float = 160.0
) -> Dictionary:
	## Map 2 BattleScene fighters onto logical slots 0/1; slots 2/3 run independent CPU fill.
	## Honest: battle_scene_fighter_slots remains 2 — extra actors are CPU/lobby depth, not 4 humans.
	return sync_live_presence_from_actor_positions(
		state, [p1_pos, p2_pos], core_center, core_radius
	)


static func tick_live(state: Dictionary, p1_pos: Vector2, p2_pos: Vector2, core_center: Vector2 = Vector2(960, 540), core_radius: float = 160.0) -> Dictionary:
	## One live frame: sync multi-actor occupancy → contested capture → OT/stronghold rules.
	var next: Dictionary = sync_live_presence_from_positions(state, p1_pos, p2_pos, core_center, core_radius)
	## Disable legacy RNG bot drift; independent CPU fill owns bot occupancy.
	next["config"]["bots_enabled"] = false
	return step(next)


static func tick_live_multi(
	state: Dictionary,
	positions: Array,
	core_center: Vector2 = Vector2(960, 540),
	core_radius: float = 160.0
) -> Dictionary:
	## Live tick with explicit up-to-4 actor positions (PartyLink lobby / future multi-body).
	var next: Dictionary = sync_live_presence_from_actor_positions(state, positions, core_center, core_radius)
	next["config"]["bots_enabled"] = false
	return step(next)
