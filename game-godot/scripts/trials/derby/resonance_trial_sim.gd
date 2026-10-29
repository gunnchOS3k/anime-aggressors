extends RefCounted
class_name ResonanceTrialSim
## Impact Dummy Derby / Resonance Trial — native 60 Hz sim.
## game-core 10s damage contract wins over older 45s Godot prototype.
## Original Kinetic Bat + dummy; deterministic trajectory; scoring/records/replay.

const Authority = preload("res://scripts/trials/mode_authority.gd")
const ResonanceDummy = preload("res://scripts/trials/derby/resonance_dummy_actor.gd")

const SIM_HZ := 60
const FP := 1000
const DAMAGE_PHASE_FRAMES := 10 * SIM_HZ
const COUNTDOWN_FRAMES := 3 * SIM_HZ
const LAUNCH_WINDOW_FRAMES := 3 * SIM_HZ
const PLATFORM_Y := 900 * FP
const PLATFORM_LEFT := 200 * FP
const PLATFORM_RIGHT := 2200 * FP
const RUN_SPEED := int((10.2 * FP) / SIM_HZ)
const JUMP_V := int((-17.5 * FP) / SIM_HZ)
const GRAVITY := int((12.0 * FP) / SIM_HZ)
const BAT_STARTUP := 8
const BAT_ACTIVE := 5
const BAT_RECOVERY := 24
const BAT_BASE_LAUNCH := 32 * FP
const ATTACK_ACTIVE_START := 4
const ATTACK_ACTIVE_END := 8


static func create(seed: int = 1, fighter_id: String = "ember-vale", personal_best: int = 0) -> Dictionary:
	return {
		"mode": "resonance_trial",
		"legacy_mode": "impactDummyDerby",
		"frame": 0,
		"phase": "ready",
		"phase_frame": 0,
		"seed": seed,
		"fighter_id": fighter_id,
		"player": {
			"x": 600 * FP, "y": PLATFORM_Y - 64 * FP, "vx": 0, "vy": 0,
			"facing": 1, "on_ground": true, "jumps": 1, "action": "idle", "action_frame": 0,
		},
		"dummy": {
			"x": 1200 * FP, "y": PLATFORM_Y - 64 * FP, "vx": 0, "vy": 0,
			"damage": 0, "hitstun": 0, "grounded": true, "launched": false, "landed": false,
			"actor_id": ResonanceDummy.DUMMY_ID,
		},
		"dummy_actor": ResonanceDummy.identity(),
		"bat": {"available": false, "equipped": false, "swing": "idle", "swing_frame": 0, "sweet": false},
		"bat_launch_enabled": true,
		"distance_scoring_enabled": true,
		"timer_frames": DAMAGE_PHASE_FRAMES,
		"final_launch_frames": LAUNCH_WINDOW_FRAMES,
		"combo": 0, "best_combo": 0, "hits": 0,
		"final_distance": 0, "final_launch_speed": 0, "launch_origin_x": 1200 * FP,
		"score": 0, "grade": "—", "personal_best": personal_best,
		"events": [],
		"challenge": "solo",  # solo | alternating | coop | fighter_challenge
		"round_time_seconds_contract": 10,
		"supersedes_prototype_seconds": 45,
		"result_kind": "SIMULATION",
		"earned_personal_best": false,
	}


static func _push(state: Dictionary, ev: Dictionary) -> void:
	var events: Array = state.get("events", [])
	events.append(ev)
	state["events"] = events


static func _integrate_player(p: Dictionary, inp: Dictionary) -> void:
	var action := str(p.get("action", "idle"))
	var af := int(p.get("action_frame", 0))
	if action == "attacking" and af > 14:
		p["action"] = "idle"
		p["action_frame"] = 0
		action = "idle"
	if action in ["idle", "running", "falling", "jumping"]:
		if bool(inp.get("left", false)):
			p["vx"] = -RUN_SPEED
			p["facing"] = -1
			if bool(p.get("on_ground", false)):
				p["action"] = "running"
		elif bool(inp.get("right", false)):
			p["vx"] = RUN_SPEED
			p["facing"] = 1
			if bool(p.get("on_ground", false)):
				p["action"] = "running"
		elif bool(p.get("on_ground", false)) and action == "running":
			p["vx"] = 0
			p["action"] = "idle"
		if bool(inp.get("jump", false)):
			if bool(p.get("on_ground", false)):
				p["vy"] = JUMP_V
				p["on_ground"] = false
				p["jumps"] = 1
				p["action"] = "jumping"
			elif int(p.get("jumps", 0)) > 0:
				p["vy"] = int(JUMP_V * 0.94)
				p["jumps"] = 0
				p["action"] = "jumping"
		if bool(inp.get("attack", false)) and action in ["idle", "running", "falling", "jumping"]:
			p["action"] = "attacking"
			p["action_frame"] = 0
	p["vy"] = int(p.get("vy", 0)) + GRAVITY
	p["x"] = int(p.get("x", 0)) + int(p.get("vx", 0))
	p["y"] = int(p.get("y", 0)) + int(p.get("vy", 0))
	if int(p.get("y", 0)) >= PLATFORM_Y - 64 * FP:
		p["y"] = PLATFORM_Y - 64 * FP
		p["vy"] = 0
		p["on_ground"] = true
		if str(p.get("action", "")) == "jumping" or str(p.get("action", "")) == "falling":
			p["action"] = "idle"
	else:
		p["on_ground"] = false
		if int(p.get("vy", 0)) > 0:
			p["action"] = "falling"
	p["x"] = clampi(int(p.get("x", 0)), PLATFORM_LEFT, PLATFORM_RIGHT)
	p["action_frame"] = int(p.get("action_frame", 0)) + 1


static func _try_attack(state: Dictionary) -> void:
	var p: Dictionary = state["player"]
	var d: Dictionary = state["dummy"]
	if str(p.get("action", "")) != "attacking":
		return
	var af := int(p.get("action_frame", 0))
	if af < ATTACK_ACTIVE_START or af > ATTACK_ACTIVE_END:
		return
	if int(d.get("hitstun", 0)) > 0:
		return
	var dx: int = absi(int(p.get("x", 0)) - int(d.get("x", 0)))
	if dx > 90 * FP:
		return
	var dmg: int = 8
	d["damage"] = int(d.get("damage", 0)) + dmg
	d["hitstun"] = 8
	d["vx"] = int(p.get("facing", 1)) * (4 * FP + int(d.get("damage", 0)) * 20)
	d["vy"] = -6 * FP
	d["grounded"] = false
	state["hits"] = int(state.get("hits", 0)) + 1
	state["combo"] = int(state.get("combo", 0)) + 1
	state["best_combo"] = maxi(int(state.get("best_combo", 0)), int(state.get("combo", 0)))
	_push(state, {"type": "hit", "frame": state["frame"], "damage": dmg})


static func _advance_bat(bat: Dictionary, attack: bool) -> void:
	var swing := str(bat.get("swing", "idle"))
	var sf := int(bat.get("swing_frame", 0))
	if swing == "idle" and attack and bool(bat.get("equipped", false)):
		bat["swing"] = "startup"
		bat["swing_frame"] = 0
		bat["sweet"] = false
		return
	if swing == "startup":
		sf += 1
		if sf >= BAT_STARTUP:
			bat["swing"] = "active"
			bat["swing_frame"] = 0
			bat["sweet"] = true
		else:
			bat["swing_frame"] = sf
	elif swing == "active":
		sf += 1
		bat["sweet"] = sf >= 2 and sf <= 3
		if sf >= BAT_ACTIVE:
			bat["swing"] = "recovery"
			bat["swing_frame"] = 0
			bat["sweet"] = false
		else:
			bat["swing_frame"] = sf
	elif swing == "recovery":
		sf += 1
		if sf >= BAT_RECOVERY:
			bat["swing"] = "idle"
			bat["swing_frame"] = 0
		else:
			bat["swing_frame"] = sf


static func _try_bat_launch(state: Dictionary, attack: bool) -> bool:
	var bat: Dictionary = state["bat"]
	var d: Dictionary = state["dummy"]
	var p: Dictionary = state["player"]
	_advance_bat(bat, attack)
	if str(bat.get("swing", "")) != "active":
		return false
	if bool(d.get("launched", false)):
		return true
	var dx: int = absi(int(p.get("x", 0)) - int(d.get("x", 0)))
	if dx > 110 * FP:
		return false
	var mult: float = 1.25 if bool(bat.get("sweet", false)) else 0.85
	var speed: int = int((BAT_BASE_LAUNCH + int(d.get("damage", 0)) * 32) * mult)
	d["vx"] = int(p.get("facing", 1)) * speed
	d["vy"] = -int(speed * 0.55)
	d["launched"] = true
	d["grounded"] = false
	state["final_launch_speed"] = speed
	state["launch_origin_x"] = int(d.get("x", 0))
	state["phase"] = "flight"
	state["phase_frame"] = 0
	_push(state, {"type": "bat_launch", "frame": state["frame"], "speed": speed, "sweet": bat.get("sweet", false)})
	return true


static func _fallback_launch(state: Dictionary) -> void:
	var d: Dictionary = state["dummy"]
	if bool(d.get("launched", false)):
		return
	var speed: int = 12 * FP + int(d.get("damage", 0)) * 40
	d["vx"] = speed
	d["vy"] = -int(speed * 0.4)
	d["launched"] = true
	d["grounded"] = false
	state["final_launch_speed"] = speed
	state["launch_origin_x"] = int(d.get("x", 0))
	state["phase"] = "flight"
	state["phase_frame"] = 0
	_push(state, {"type": "fallback_launch", "frame": state["frame"], "speed": speed})


static func _integrate_dummy(state: Dictionary) -> void:
	var d: Dictionary = state["dummy"]
	if int(d.get("hitstun", 0)) > 0:
		d["hitstun"] = int(d.get("hitstun", 0)) - 1
	d["vy"] = int(d.get("vy", 0)) + GRAVITY
	d["x"] = int(d.get("x", 0)) + int(d.get("vx", 0))
	d["y"] = int(d.get("y", 0)) + int(d.get("vy", 0))
	if bool(d.get("launched", false)) and not bool(d.get("landed", false)):
		state["final_distance"] = absi(int(d.get("x", 0)) - int(state.get("launch_origin_x", 0)))
		state["flight_frames"] = int(state.get("flight_frames", 0)) + 1
		var grounded_now: bool = int(d.get("y", 0)) >= PLATFORM_Y - 64 * FP and int(d.get("vy", 0)) >= 0
		## Cap extreme flights so journeys always resolve (still deterministic).
		var flight_cap: bool = int(state.get("flight_frames", 0)) >= SIM_HZ * 8
		if grounded_now or flight_cap:
			d["y"] = PLATFORM_Y - 64 * FP
			d["vx"] = 0
			d["vy"] = 0
			d["landed"] = true
			d["grounded"] = true
			state["phase"] = "landed"
			state["phase_frame"] = 0
			_push(state, {"type": "landed", "frame": state["frame"], "distance": state["final_distance"], "capped": flight_cap})
	elif int(d.get("y", 0)) >= PLATFORM_Y - 64 * FP:
		d["y"] = PLATFORM_Y - 64 * FP
		d["vy"] = 0
		d["vx"] = int(d.get("vx", 0) * 0.7)
		d["grounded"] = true


static func _score(state: Dictionary) -> int:
	var dist_units: int = int(state.get("final_distance", 0)) / FP
	var timing: int = int(state.get("final_launch_frames", 0)) / 6
	return dist_units * 10 + int(state["dummy"]["damage"]) * 20 + int(state.get("final_launch_speed", 0)) / FP * 5 + int(state.get("best_combo", 0)) * 50 + timing


static func _grade(score: int) -> String:
	if score >= 6000:
		return "SS"
	if score >= 3500:
		return "S"
	if score >= 2000:
		return "A"
	if score >= 1000:
		return "B"
	if score >= 500:
		return "C"
	return "D"


static func _advance_phase(state: Dictionary) -> void:
	state["phase_frame"] = int(state.get("phase_frame", 0)) + 1
	var phase := str(state.get("phase", "ready"))
	var pf := int(state.get("phase_frame", 0))
	if phase == "ready" and pf >= 1:
		state["phase"] = "countdown"
		state["phase_frame"] = 0
		_push(state, {"type": "phase", "frame": state["frame"], "phase": "countdown"})
	elif phase == "countdown" and pf >= COUNTDOWN_FRAMES:
		state["phase"] = "damage"
		state["phase_frame"] = 0
		state["timer_frames"] = DAMAGE_PHASE_FRAMES
		_push(state, {"type": "phase", "frame": state["frame"], "phase": "damage"})
	elif phase == "damage":
		state["timer_frames"] = maxi(0, DAMAGE_PHASE_FRAMES - pf)
		if pf >= DAMAGE_PHASE_FRAMES:
			state["phase"] = "finalLaunch"
			state["phase_frame"] = 0
			state["final_launch_frames"] = LAUNCH_WINDOW_FRAMES
			state["bat"]["available"] = true
			state["bat"]["equipped"] = true
			_push(state, {"type": "phase", "frame": state["frame"], "phase": "finalLaunch"})
			_push(state, {"type": "bat_equipped", "frame": state["frame"]})
	elif phase == "finalLaunch":
		state["final_launch_frames"] = maxi(0, LAUNCH_WINDOW_FRAMES - pf)
		if pf >= LAUNCH_WINDOW_FRAMES and not bool(state["dummy"].get("launched", false)):
			_fallback_launch(state)
	elif phase == "landed" and pf >= SIM_HZ:
		state["score"] = _score(state)
		state["grade"] = _grade(int(state["score"]))
		if int(state["score"]) > int(state.get("personal_best", 0)):
			state["personal_best"] = int(state["score"])
		state["phase"] = "results"
		state["phase_frame"] = 0
		_push(state, {"type": "scored", "frame": state["frame"], "score": state["score"], "grade": state["grade"]})


static func step(state: Dictionary, inp: Dictionary = {}) -> Dictionary:
	var next: Dictionary = state.duplicate(true)
	if str(next.get("phase", "")) == "results":
		return next
	next["frame"] = int(next.get("frame", 0)) + 1
	_integrate_player(next["player"], inp)
	var phase := str(next.get("phase", ""))
	if phase == "damage":
		_try_attack(next)
	elif phase == "finalLaunch":
		if not _try_bat_launch(next, bool(inp.get("attack", false))):
			_try_attack(next)
	_integrate_dummy(next)
	_advance_phase(next)
	return next


static func replay(initial: Dictionary, inputs: Array) -> Dictionary:
	var s: Dictionary = initial.duplicate(true)
	for inp in inputs:
		s = step(s, inp if typeof(inp) == TYPE_DICTIONARY else {})
	return s


static func state_hash(state: Dictionary) -> String:
	return Authority.hash_parts(int(state.get("seed", 0)), [
		state.get("frame", 0), state.get("phase", ""), state["player"].get("x", 0),
		state["dummy"].get("damage", 0), state["dummy"].get("x", 0),
		state.get("final_distance", 0), state.get("score", 0), state.get("best_combo", 0),
	])


static func run_solo_to_results(seed: int, fighter_id: String, attack_every: int = 12) -> Dictionary:
	## Headless SIMULATION smoke only — never an earned REAL_PLAYER personal-best receipt.
	var s: Dictionary = create(seed, fighter_id)
	var guard: int = 0
	while str(s.get("phase", "")) != "results" and guard < 60 * 90:
		var inp: Dictionary = {"right": true, "attack": guard % attack_every == 0}
		if str(s.get("phase", "")) == "finalLaunch":
			## Real bat-launch input path (not a skip-to-results cheat).
			s["bat"]["available"] = true
			s["bat"]["equipped"] = true
			inp = {"attack": true}
		s = step(s, inp)
		guard += 1
	return seal_simulation(s)


static func seal_simulation(state: Dictionary) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	s["result_kind"] = "SIMULATION"
	s["earned_personal_best"] = false
	s["player_owned_events"] = false
	s["honesty"] = "SIMULATION — not REAL_PLAYER earned record"
	return s


static func seal_real_player(state: Dictionary, player_owned: bool) -> Dictionary:
	## Only player-owned live events earn REAL_PLAYER results / personal bests.
	var s: Dictionary = state.duplicate(true)
	if player_owned and str(s.get("phase", "")) == "results":
		s["result_kind"] = "REAL_PLAYER"
		s["earned_personal_best"] = true
		s["player_owned_events"] = true
		s["honesty"] = "REAL_PLAYER — local Trials receipt from player-owned combat events"
	else:
		return seal_simulation(s)
	return s


static func apply_damage_event(state: Dictionary, damage: int, facing: int = 1) -> Dictionary:
	## Bridge live BattleScene hits into Resonance damage→bat→flight contract.
	var next: Dictionary = state.duplicate(true)
	if str(next.get("phase", "")) != "damage":
		return next
	var d: Dictionary = next["dummy"]
	var dmg: int = maxi(1, damage)
	d["damage"] = int(d.get("damage", 0)) + dmg
	d["hitstun"] = 8
	d["vx"] = facing * (4 * FP + int(d.get("damage", 0)) * 20)
	d["vy"] = -6 * FP
	d["grounded"] = false
	next["hits"] = int(next.get("hits", 0)) + 1
	next["combo"] = int(next.get("combo", 0)) + 1
	next["best_combo"] = maxi(int(next.get("best_combo", 0)), int(next.get("combo", 0)))
	next["player_owned_events"] = true
	_push(next, {"type": "hit", "frame": next["frame"], "damage": dmg, "source": "live_battle"})
	return next
