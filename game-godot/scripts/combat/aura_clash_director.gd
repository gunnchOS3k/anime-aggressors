extends RefCounted
class_name AuraClashDirector

## High-commitment clash only. Deterministic. No mash. Jabs never clash.

const READY := true
const HIGH_TIERS := ["aura", "super"]
const HIGH_TYPES := ["aura", "super", "beam", "aura_burst", "signature"]
const LIGHT_TYPES := ["jab", "light", "tilt", "aerial", "dash_attack"]

const _Impact = preload("res://scripts/combat/impact_profile_resolver.gd")
const _Cinematic = preload("res://scripts/combat/combat_cinematic_director.gd")

static var last_result: Dictionary = {}


static func is_clashable(move: Dictionary) -> bool:
	if move.is_empty():
		return false
	var choreo: Dictionary = move.get("choreography", {})
	if choreo.has("clashable"):
		return bool(choreo.get("clashable"))
	var move_type := str(move.get("move_type", "")).to_lower()
	var move_id := str(move.get("move_id", "")).to_lower()
	for token in LIGHT_TYPES:
		if move_type == token or move_id.begins_with(token) or move_id.contains("jab"):
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
	var seed := 0
	for i in fid.length():
		seed = (seed * 33 + fid.unicode_at(i)) & 0x7fffffff
	# Stable, no input mash. Later frames do not add player agency.
	return aura * 10 + frames * 3 + specified * 20 + (seed % 17)


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
	var a_score := commitment_score(attacker, incoming)
	var b_score := commitment_score(defender, outgoing)
	var winner := "draw"
	if a_score > b_score:
		winner = "attacker"
	elif b_score > a_score:
		winner = "defender"
	var a_id := str(attacker.fighter_id) if attacker and "fighter_id" in attacker else ""
	var b_id := str(defender.fighter_id) if defender and "fighter_id" in defender else ""
	last_result = {
		"clash": true,
		"winner": winner,
		"attacker_id": a_id,
		"defender_id": b_id,
		"attacker_score": a_score,
		"defender_score": b_score,
		"attacker_move": str(incoming.get("move_id", "")),
		"defender_move": str(outgoing.get("move_id", "")),
		"mixed_identity": a_id != b_id,
		"mash_used": false,
		"cinematic_class": _Cinematic.CLASS_CLASH,
		"debug": true,
	}
	if Engine.get_main_loop() != null:
		var gs = Engine.get_main_loop().root.get_node_or_null("/root/GameState")
		if gs != null:
			gs.last_aura_clash = last_result
	return last_result


static func debug_force(a_move: Dictionary, b_move: Dictionary, a_fighter = null, b_fighter = null) -> Dictionary:
	if not is_clashable(a_move) or not is_clashable(b_move):
		return {"clash": false, "reason": "not_high_commitment"}
	var a_score := commitment_score(a_fighter, a_move)
	var b_score := commitment_score(b_fighter, b_move)
	var winner := "draw"
	if a_score > b_score:
		winner = "a"
	elif b_score > a_score:
		winner = "b"
	return {
		"clash": true,
		"winner": winner,
		"a_score": a_score,
		"b_score": b_score,
		"mash_used": false,
		"cinematic_class": _Cinematic.CLASS_CLASH,
	}
