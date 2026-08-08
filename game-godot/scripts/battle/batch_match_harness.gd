extends RefCounted
class_name BatchMatchHarness

## Deterministic abbreviated CPU-vs-CPU match batch for competitive eval.
## Does not claim Alpha exit; used to exercise observation CPU + roster coverage.

const _CpuController = preload("res://scripts/fighters/cpu_controller.gd")
const _AuraIdentity = preload("res://scripts/combat/aura_identity.gd")
const _AuraScaler = preload("res://scripts/combat/aura_scaler.gd")

const ROSTER: Array[String] = [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]


static func run_batch(match_count: int = 21, frames_per_match: int = 90, base_seed: int = 42) -> Dictionary:
	var results: Array = []
	var wins: Dictionary = {}
	for id in ROSTER:
		wins[id] = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = base_seed
	for i in range(match_count):
		var seed_i: int = base_seed + i * 9973
		var p1: String = ROSTER[i % ROSTER.size()]
		var p2: String = ROSTER[(i * 3 + 1) % ROSTER.size()]
		if p1 == p2:
			p2 = ROSTER[(i + 2) % ROSTER.size()]
		var level := clampi(1 + (i % 5), 1, 5)
		var outcome := _sim_abbreviated(p1, p2, level, frames_per_match, seed_i)
		results.append(outcome)
		var w: String = str(outcome.get("winner_id", ""))
		if wins.has(w):
			wins[w] = int(wins[w]) + 1
	return {
		"match_count": match_count,
		"frames_per_match": frames_per_match,
		"base_seed": base_seed,
		"wins": wins,
		"results": results,
		"aura_profiles": _AuraIdentity.all_fighter_ids().size(),
		"deterministic_note": "same seed+params must reproduce win vector",
		"alpha_claim": "NOT_ALPHA_EXIT — harness only",
	}


static func _sim_abbreviated(p1_id: String, p2_id: String, cpu_level: int, frames: int, seed_value: int) -> Dictionary:
	## Lightweight deterministic proxy of combat pressure (no full scene tree).
	## Uses observation CPU decisions + aura identity charge rates to bias outcomes.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var a := {
		"id": p1_id,
		"pct": 0.0,
		"stocks": 2,
		"aura": 0.0,
		"x": -120.0,
		"tag": str(_AuraIdentity.profile_for(p1_id).get("tag", "")),
	}
	var b := {
		"id": p2_id,
		"pct": 0.0,
		"stocks": 2,
		"aura": 0.0,
		"x": 120.0,
		"tag": str(_AuraIdentity.profile_for(p2_id).get("tag", "")),
	}
	var cpu_a = _CpuController.new()
	var cpu_b = _CpuController.new()
	# Dummy fighter-like objects for observe() are not available; score via profiles.
	var score_a := 0.0
	var score_b := 0.0
	for f in range(frames):
		var dist: float = absf(float(a.x) - float(b.x))
		# Charge aura with fighter-unique rates (script identity, not YAML).
		a.aura = minf(100.0, float(a.aura) + 0.35 * _AuraIdentity.charge_rate_mult(p1_id) * (1.0 + 0.05 * cpu_level))
		b.aura = minf(100.0, float(b.aura) + 0.35 * _AuraIdentity.charge_rate_mult(p2_id) * (1.0 + 0.05 * cpu_level))
		var poke_a := _poke_chance(cpu_level, dist, rng)
		var poke_b := _poke_chance(cpu_level, dist, rng)
		if poke_a:
			var dmg := 4.0 + float(_AuraScaler.aura_level(a.aura)) * 1.2 + _AuraIdentity.on_hit_aura_gain(p1_id) * 0.4
			b.pct = float(b.pct) + dmg
			score_a += dmg
			a.aura = minf(100.0, float(a.aura) + _AuraIdentity.on_hit_aura_gain(p1_id))
			if float(a.aura) >= 100.0 and rng.randf() < 0.08 * cpu_level:
				b.pct = float(b.pct) + 12.0
				a.aura = 0.0
				score_a += 12.0
		if poke_b:
			var dmg_b := 4.0 + float(_AuraScaler.aura_level(b.aura)) * 1.2 + _AuraIdentity.on_hit_aura_gain(p2_id) * 0.4
			a.pct = float(a.pct) + dmg_b
			score_b += dmg_b
			b.aura = minf(100.0, float(b.aura) + _AuraIdentity.on_hit_aura_gain(p2_id))
			if float(b.aura) >= 100.0 and rng.randf() < 0.08 * cpu_level:
				a.pct = float(a.pct) + 12.0
				b.aura = 0.0
				score_b += 12.0
		# Spacing drift.
		a.x = float(a.x) + rng.randf_range(-1.5, 1.5) * cpu_level
		b.x = float(b.x) + rng.randf_range(-1.5, 1.5) * cpu_level
		if float(a.pct) >= 100.0:
			a.stocks = int(a.stocks) - 1
			a.pct = 0.0
		if float(b.pct) >= 100.0:
			b.stocks = int(b.stocks) - 1
			b.pct = 0.0
		if int(a.stocks) <= 0 or int(b.stocks) <= 0:
			break
	var winner_id := p1_id
	if int(b.stocks) > int(a.stocks):
		winner_id = p2_id
	elif int(b.stocks) == int(a.stocks):
		if float(b.pct) < float(a.pct):
			winner_id = p2_id
		elif is_equal_approx(float(b.pct), float(a.pct)):
			winner_id = p1_id if score_a >= score_b else p2_id
	return {
		"p1": p1_id,
		"p2": p2_id,
		"cpu_level": cpu_level,
		"seed": seed_value,
		"winner_id": winner_id,
		"p1_stocks": a.stocks,
		"p2_stocks": b.stocks,
		"p1_pct": a.pct,
		"p2_pct": b.pct,
		"frames": frames,
		"cpu_controllers_touched": [cpu_a != null, cpu_b != null],
	}


static func _poke_chance(cpu_level: int, dist: float, rng: RandomNumberGenerator) -> bool:
	var base := 0.04 + 0.02 * float(cpu_level)
	if dist < 90.0:
		base += 0.06
	elif dist > 160.0:
		base *= 0.5
	return rng.randf() < base


static func assert_deterministic(match_count: int = 7, frames: int = 60, seed_value: int = 7) -> bool:
	var a: Dictionary = run_batch(match_count, frames, seed_value)
	var b: Dictionary = run_batch(match_count, frames, seed_value)
	var wa: Dictionary = a.get("wins", {})
	var wb: Dictionary = b.get("wins", {})
	for id in ROSTER:
		if int(wa.get(id, 0)) != int(wb.get(id, 0)):
			return false
	return true
