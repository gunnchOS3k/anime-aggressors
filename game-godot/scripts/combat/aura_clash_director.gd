extends RefCounted
class_name AuraClashDirector

## Production clash director. Deterministic. No mash. Jabs never clash.
## Acting/content stays WIP. HUMAN_AURA_CLASH_PASS must stay false.

const READY := true
const HIGH_TIERS := ["aura", "super"]
const HIGH_TYPES := ["aura", "super", "beam", "aura_burst", "signature", "burst"]
const LIGHT_TYPES := ["jab", "light", "tilt", "aerial", "dash_attack"]

const STATE_NONE := "NONE"
const STATE_QUALIFY := "QUALIFY"
const STATE_SNAP := "SNAP"
const STATE_CONTACT := "CONTACT"
const STATE_LOCK := "LOCK"
const STATE_ESCALATE := "ESCALATE"
const STATE_RESOLVE_A := "RESOLVE_A"
const STATE_RESOLVE_B := "RESOLVE_B"
const STATE_RESOLVE_NEUTRAL := "RESOLVE_NEUTRAL"
const STATE_RECOVER := "RECOVER"

const STATES := [
	STATE_NONE, STATE_QUALIFY, STATE_SNAP, STATE_CONTACT, STATE_LOCK,
	STATE_ESCALATE, STATE_RESOLVE_A, STATE_RESOLVE_B, STATE_RESOLVE_NEUTRAL, STATE_RECOVER,
]

const ACTING_HOOKS := ["clash_start", "clash_lock", "clash_push", "clash_losing", "clash_winning", "clash_break"]

const _Impact = preload("res://scripts/combat/impact_profile_resolver.gd")
const _Cinematic = preload("res://scripts/combat/combat_cinematic_director.gd")
const _Camera = preload("res://scripts/combat/clash_camera.gd")
const _Env = preload("res://scripts/combat/clash_environment.gd")
const _Audio = preload("res://scripts/combat/clash_audio_mixer.gd")

static var last_result: Dictionary = {}
static var _machine: Dictionary = {}
static var _eligibility: Dictionary = {}
static var _loaded := false


static func _gs():
	if Engine.get_main_loop() == null:
		return null
	return Engine.get_main_loop().root.get_node_or_null("/root/GameState")


static func _gs_flag(prop: String, default_value: bool = true) -> bool:
	var gs = _gs()
	if gs == null:
		return default_value
	return bool(gs.get(prop))


static func _schema() -> Dictionary:
	if _loaded:
		return _eligibility
	var path := "res://data/combat/clash_eligibility.json"
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		f.close()
		if typeof(parsed) == TYPE_DICTIONARY:
			_eligibility = parsed
	_loaded = true
	return _eligibility


static func clash_block_for(move: Dictionary) -> Dictionary:
	var declared: Dictionary = move.get("clash", {})
	if not declared.is_empty():
		return declared
	var schema: Dictionary = _schema()
	var moves: Dictionary = schema.get("moves", {})
	var mid := str(move.get("move_id", ""))
	if moves.has(mid):
		return moves[mid]
	return {}


static func is_clashable(move: Dictionary) -> bool:
	if move.is_empty():
		return false
	var block: Dictionary = clash_block_for(move)
	if block.has("eligible"):
		return bool(block.get("eligible"))
	var choreo: Dictionary = move.get("choreography", {})
	if choreo.has("clashable"):
		return bool(choreo.get("clashable"))
	var move_type := str(move.get("move_type", "")).to_lower()
	var move_id := str(move.get("move_id", "")).to_lower()
	for token in LIGHT_TYPES:
		if move_type == token or move_id.begins_with(token) or move_id.contains("jab"):
			return false
	if move_type == "melee" and not (move_id.contains("aura") or move_id.contains("super") or move_id.contains("burst")):
		return false
	if move_type in HIGH_TYPES:
		return true
	if move_id.contains("aura") or move_id.contains("super") or move_id.contains("beam"):
		return true
	if move_id.contains("signature_lane") and (move_id.contains("burst") or move_id.contains("finisher")):
		return true
	var profile: Dictionary = {}
	if _Impact:
		profile = _Impact.resolve(move, {})
	var tier := str(profile.get("tier", choreo.get("cinematic_hook", "")))
	return tier in HIGH_TIERS


static func in_commitment_window(runner) -> bool:
	if runner == null:
		return false
	if not ("active" in runner) or not bool(runner.active):
		return false
	var phase := str(runner.phase) if "phase" in runner else ""
	return phase in ["startup", "active"]


static func commitment_score(fighter, move: Dictionary) -> int:
	var aura := 0
	var fid := ""
	if fighter is Dictionary:
		aura = int(fighter.get("aura", 0))
		fid = str(fighter.get("fighter_id", ""))
	elif fighter != null:
		if fighter.has_method("get_aura"):
			aura = int(fighter.get_aura())
		elif "aura" in fighter:
			aura = int(fighter.aura)
		if "fighter_id" in fighter:
			fid = str(fighter.fighter_id)
	var frames := int(move.get("startup_frames", 0)) + int(move.get("active_frames", 0))
	var specified := int(move.get("choreography", {}).get("clash_weight", 0))
	var block: Dictionary = clash_block_for(move)
	var power := int(block.get("power", 0))
	var meter := int(block.get("meter_commitment", 0))
	var seed := 0
	for i in fid.length():
		seed = (seed * 33 + fid.unicode_at(i)) & 0x7fffffff
	# Stable, no input mash. Later frames do not add player agency. No hidden RNG.
	return aura * 10 + frames * 3 + specified * 20 + power + meter + (seed % 17)


static func _winner_from_scores(a_score: int, b_score: int) -> String:
	if a_score > b_score:
		return "a"
	if b_score > a_score:
		return "b"
	return "draw"


static func _advance(state: String, winner: String) -> String:
	match state:
		STATE_NONE:
			return STATE_QUALIFY
		STATE_QUALIFY:
			return STATE_SNAP
		STATE_SNAP:
			return STATE_CONTACT
		STATE_CONTACT:
			return STATE_LOCK
		STATE_LOCK:
			return STATE_ESCALATE
		STATE_ESCALATE:
			if winner == "a":
				return STATE_RESOLVE_A
			if winner == "b":
				return STATE_RESOLVE_B
			return STATE_RESOLVE_NEUTRAL
		STATE_RESOLVE_A, STATE_RESOLVE_B, STATE_RESOLVE_NEUTRAL:
			return STATE_RECOVER
		STATE_RECOVER:
			return STATE_NONE
		_:
			return STATE_NONE


static func run_machine(a_move: Dictionary, b_move: Dictionary, a_fighter = null, b_fighter = null, force_winner: String = "") -> Dictionary:
	if not is_clashable(a_move) or not is_clashable(b_move):
		_machine = {"state": STATE_NONE, "clash": false, "reason": "not_high_commitment"}
		return _machine
	var a_score := commitment_score(a_fighter, a_move)
	var b_score := commitment_score(b_fighter, b_move)
	var winner := _winner_from_scores(a_score, b_score)
	if force_winner in ["a", "b", "draw"]:
		winner = force_winner
	var a_id := ""
	var b_id := ""
	if a_fighter is Dictionary:
		a_id = str(a_fighter.get("fighter_id", ""))
	elif a_fighter != null and "fighter_id" in a_fighter:
		a_id = str(a_fighter.fighter_id)
	if b_fighter is Dictionary:
		b_id = str(b_fighter.get("fighter_id", ""))
	elif b_fighter != null and "fighter_id" in b_fighter:
		b_id = str(b_fighter.fighter_id)
	var timestamps: Dictionary = {}
	var state := STATE_NONE
	var steps: Array = []
	var guard := 0
	while state != STATE_RECOVER and guard < 16:
		state = _advance(state, winner)
		timestamps[state] = guard
		steps.append(state)
		guard += 1
	if state == STATE_RECOVER:
		steps.append(STATE_NONE)
	var camera: Dictionary = _Camera.shot_plan(winner, a_id, b_id)
	var env: Dictionary = _Env.pulse(a_id, b_id)
	var audio: Dictionary = _Audio.mix(a_id, b_id, winner)
	_machine = {
		"clash": true,
		"state": STATE_RECOVER,
		"steps": steps,
		"participants": [a_id, b_id],
		"attacks": [str(a_move.get("move_id", "")), str(b_move.get("move_id", ""))],
		"meter_committed": [
			int(clash_block_for(a_move).get("meter_commitment", 0)),
			int(clash_block_for(b_move).get("meter_commitment", 0)),
		],
		"score_inputs": {"a": a_score, "b": b_score},
		"state_timestamps": timestamps,
		"result": winner,
		"winner": winner,
		"camera_class": _Cinematic.CLASS_CLASH,
		"camera": camera,
		"environment": env,
		"audio": audio,
		"acting_hooks": ACTING_HOOKS,
		"acting_status": "PROCEDURAL_FALLBACK",
		"a11y_mode": {
			"reduce_camera": not bool(_gs_flag("training_camera_enabled", true)),
			"reduce_vfx": not bool(_gs_flag("training_vfx_enabled", true)),
		},
		"mash_used": false,
		"rng": false,
		"teleport": false,
		"HUMAN_AURA_CLASH_PASS": false,
		"debug": true,
	}
	last_result = _machine
	if Engine.get_main_loop() != null:
		var gs = Engine.get_main_loop().root.get_node_or_null("/root/GameState")
		if gs != null:
			gs.last_aura_clash = last_result
	return _machine


static func try_resolve(attacker, defender, incoming: Dictionary) -> Dictionary:
	last_result = {}
	if not READY:
		return {}
	if attacker == null or defender == null:
		return {}
	if not is_clashable(incoming):
		return {}
	var def_runner = defender.move_runner if "move_runner" in defender else null
	if not in_commitment_window(def_runner):
		return {}
	var outgoing: Dictionary = def_runner.move_data if def_runner and "move_data" in def_runner else {}
	if not is_clashable(outgoing):
		return {}
	var machine: Dictionary = run_machine(incoming, outgoing, attacker, defender)
	var mapped := "draw"
	if str(machine.get("winner")) == "a":
		mapped = "attacker"
	elif str(machine.get("winner")) == "b":
		mapped = "defender"
	last_result = machine.duplicate(true)
	last_result["winner"] = mapped
	last_result["attacker_id"] = str(attacker.fighter_id) if attacker and "fighter_id" in attacker else ""
	last_result["defender_id"] = str(defender.fighter_id) if defender and "fighter_id" in defender else ""
	last_result["attacker_score"] = int(machine.get("score_inputs", {}).get("a", 0))
	last_result["defender_score"] = int(machine.get("score_inputs", {}).get("b", 0))
	last_result["attacker_move"] = str(incoming.get("move_id", ""))
	last_result["defender_move"] = str(outgoing.get("move_id", ""))
	last_result["mixed_identity"] = last_result["attacker_id"] != last_result["defender_id"]
	last_result["cinematic_class"] = _Cinematic.CLASS_CLASH
	if Engine.get_main_loop() != null:
		var gs = Engine.get_main_loop().root.get_node_or_null("/root/GameState")
		if gs != null:
			gs.last_aura_clash = last_result
	return last_result


static func debug_force(a_move: Dictionary, b_move: Dictionary, a_fighter = null, b_fighter = null) -> Dictionary:
	var machine: Dictionary = run_machine(a_move, b_move, a_fighter, b_fighter)
	if not bool(machine.get("clash")):
		return {"clash": false, "reason": machine.get("reason", "not_high_commitment")}
	return {
		"clash": true,
		"winner": machine.get("winner"),
		"a_score": int(machine.get("score_inputs", {}).get("a", 0)),
		"b_score": int(machine.get("score_inputs", {}).get("b", 0)),
		"mash_used": false,
		"cinematic_class": _Cinematic.CLASS_CLASH,
		"state": machine.get("state"),
		"steps": machine.get("steps"),
		"HUMAN_AURA_CLASH_PASS": false,
	}


static func preset(id: String) -> Dictionary:
	var schema: Dictionary = _schema()
	for row in schema.get("presets", []):
		if str(row.get("id")) == id:
			return row
	return {}


static func cannot_deadlock() -> bool:
	for winner in ["a", "b", "draw"]:
		var state := STATE_NONE
		var seen := {}
		var hops := 0
		while hops < 12:
			state = _advance(state, winner)
			hops += 1
			if state == STATE_NONE and hops > 1:
				break
			if seen.has(state) and state != STATE_NONE:
				return false
			seen[state] = true
	return true
