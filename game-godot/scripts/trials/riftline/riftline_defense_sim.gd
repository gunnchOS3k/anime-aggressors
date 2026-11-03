extends RefCounted
class_name RiftlineDefenseSim
## 4-Lane Blaster / Riftline Defense — seeded waves (no Math.random).
## Fighter-identity projectiles; Fracture Echoes lore (not enslaved fighters).

const Authority = preload("res://scripts/trials/mode_authority.gd")
const SIM_HZ := 60
const LANES := 4
const START_LIVES := 3

const PROJECTILE_BY_FIGHTER := {
	"ember-vale": "ember_bolt",
	"juno-spark": "spark_arc",
	"kaia-windrow": "gale_needle",
	"nix-calder": "frost_shard",
	"orion-vell": "star_lance",
	"rook-ironside": "iron_slug",
	"vesper-nyx": "veil_dart",
	"yin": "umbra_pulse",
	"yang": "sol_flare",
	"rosamere": "petal_seed",
}


static func create(seed: int = 1, fighter_id: String = "ember-vale", seats: int = 1) -> Dictionary:
	var players: Array = []
	for i in range(clampi(seats, 1, 2)):
		players.append({
			"slot": i,
			"fighter_id": fighter_id if i == 0 else "rook-ironside",
			"lane": i * 2,
			"lives": START_LIVES,
			"projectile_id": str(PROJECTILE_BY_FIGHTER.get(fighter_id if i == 0 else "rook-ironside", "ember_bolt")),
			"cooldown": 0,
		})
	return {
		"mode": "riftline_defense",
		"legacy_mode": "laneBlaster",
		"frame": 0,
		"seed": seed,
		"phase": "play",
		"wave": 1,
		"players": players,
		"echoes": [],  # Fracture Echoes — simulations, not enslaved fighters
		"projectiles": [],
		"spawn_cooldown": SIM_HZ,
		"score": 0,
		"lore": {
			"fracture_echoes": true,
			"enslaved_fighters": false,
			"note": "Echoes are rift simulations — not captured Puppets or souls",
		},
	}


static func _spawn_echo(state: Dictionary) -> void:
	var rng: Callable = Authority.mulberry32(int(state.get("seed", 1)) * 10007 + int(state.get("frame", 0)))
	var lane: int = int(rng.call() * LANES) % LANES
	var echoes: Array = state.get("echoes", [])
	echoes.append({
		"id": "echo_%d_%d" % [state.get("frame", 0), lane],
		"lane": lane,
		"y": 0,
		"speed": 40 + int(state.get("wave", 1)) * 8,
		"kind": "fracture_echo",
		"is_real_puppet": false,
	})
	state["echoes"] = echoes


static func fire(state: Dictionary, slot: int) -> void:
	var players: Array = state.get("players", [])
	if slot < 0 or slot >= players.size():
		return
	var p: Dictionary = players[slot]
	if int(p.get("cooldown", 0)) > 0 or int(p.get("lives", 0)) <= 0:
		return
	p["cooldown"] = 12
	var projectiles: Array = state.get("projectiles", [])
	projectiles.append({
		"owner": slot,
		"lane": int(p.get("lane", 0)),
		"y": 1000,
		"vy": -18,
		"identity": str(p.get("projectile_id", "ember_bolt")),
	})
	state["projectiles"] = projectiles


static func set_lane(state: Dictionary, slot: int, lane: int) -> void:
	var players: Array = state.get("players", [])
	if slot < 0 or slot >= players.size():
		return
	players[slot]["lane"] = clampi(lane, 0, LANES - 1)


static func step(state: Dictionary, actions: Array = []) -> Dictionary:
	var next: Dictionary = state.duplicate(true)
	if str(next.get("phase", "")) == "results":
		return next
	next["frame"] = int(next.get("frame", 0)) + 1
	for a in actions:
		if typeof(a) != TYPE_DICTIONARY:
			continue
		var slot: int = int(a.get("slot", 0))
		if a.has("lane"):
			set_lane(next, slot, int(a.get("lane", 0)))
		if bool(a.get("fire", false)):
			fire(next, slot)

	for p in next.get("players", []):
		p["cooldown"] = maxi(0, int(p.get("cooldown", 0)) - 1)

	next["spawn_cooldown"] = int(next.get("spawn_cooldown", 0)) - 1
	if int(next["spawn_cooldown"]) <= 0:
		_spawn_echo(next)
		next["spawn_cooldown"] = maxi(20, SIM_HZ * 2 - int(next.get("wave", 1)) * 5)

	var projectiles: Array = []
	for pr in next.get("projectiles", []):
		pr["y"] = int(pr.get("y", 0)) + int(pr.get("vy", 0))
		if int(pr.get("y", 0)) > -50:
			projectiles.append(pr)
	next["projectiles"] = projectiles

	var echoes: Array = []
	for echo in next.get("echoes", []):
		echo["y"] = int(echo.get("y", 0)) + int(echo.get("speed", 40))
		var hit: bool = false
		var kept_proj: Array = []
		for pr in next["projectiles"]:
			if not hit and int(pr.get("lane", -1)) == int(echo.get("lane", -2)) and absi(int(pr.get("y", 0)) - int(echo.get("y", 0))) < 40:
				hit = true
				next["score"] = int(next.get("score", 0)) + 100
			else:
				kept_proj.append(pr)
		if hit:
			next["projectiles"] = kept_proj
			continue
		if int(echo.get("y", 0)) >= 1000:
			for p in next.get("players", []):
				if int(p.get("lane", -1)) == int(echo.get("lane", -2)):
					p["lives"] = maxi(0, int(p.get("lives", 0)) - 1)
			continue
		echoes.append(echo)
	next["echoes"] = echoes

	if int(next.get("score", 0)) > 0 and int(next.get("score", 0)) % 500 == 0:
		next["wave"] = int(next.get("wave", 1)) + 1

	var any_alive: bool = false
	for p in next.get("players", []):
		if int(p.get("lives", 0)) > 0:
			any_alive = true
	if not any_alive:
		next["phase"] = "results"
	return next


static func state_hash(state: Dictionary) -> String:
	return Authority.hash_parts(int(state.get("seed", 0)), [
		state.get("frame", 0), state.get("wave", 0), state.get("score", 0),
		state.get("echoes", []).size(), state.get("projectiles", []).size(),
		state.get("phase", ""),
	])


static func tick_live_from_battle(
	state: Dictionary,
	p1_pos: Vector2,
	p2_pos: Vector2 = Vector2.ZERO,
	p1_attacking: bool = false,
	p2_attacking: bool = false,
	p2_present: bool = false
) -> Dictionary:
	## Live shared combat: lane from fighter Y; fire from attack state; dual seat when present.
	var actions: Array = [{
		"slot": 0,
		"fire": p1_attacking,
		"lane": clampi(int(p1_pos.y / 180.0), 0, LANES - 1),
	}]
	if p2_present and state.get("players", []).size() >= 2:
		actions.append({
			"slot": 1,
			"fire": p2_attacking,
			"lane": clampi(int(p2_pos.y / 180.0), 0, LANES - 1),
		})
	var next: Dictionary = step(state, actions)
	next["live_shared_combat"] = true
	next["real_enemies"] = true
	next["real_attacks"] = true
	return next


static func notify_echo_hit(state: Dictionary, lane: int, damage: int = 100) -> Dictionary:
	## Player-owned HitResolver path can delete a Fracture Echo on the matching lane.
	var next: Dictionary = state.duplicate(true)
	var echoes: Array = []
	var hit: bool = false
	for echo in next.get("echoes", []):
		if not hit and int(echo.get("lane", -2)) == lane:
			hit = true
			next["score"] = int(next.get("score", 0)) + damage
			next["player_owned_echo_hits"] = int(next.get("player_owned_echo_hits", 0)) + 1
			continue
		echoes.append(echo)
	next["echoes"] = echoes
	return next


static func live_hud(state: Dictionary) -> Dictionary:
	return {
		"wave": int(state.get("wave", 1)),
		"score": int(state.get("score", 0)),
		"echoes": (state.get("echoes", []) as Array).size(),
		"projectiles": (state.get("projectiles", []) as Array).size(),
		"player_owned_echo_hits": int(state.get("player_owned_echo_hits", 0)),
		"fracture_echoes": bool(state.get("lore", {}).get("fracture_echoes", false)),
		"enslaved_fighters": bool(state.get("lore", {}).get("enslaved_fighters", true)),
		"live": true,
	}


static func run_seeded_smoke(seed: int = 11) -> Dictionary:
	var s := create(seed, "ember-vale", 1)
	for i in range(SIM_HZ * 8):
		s = step(s, [{"slot": 0, "fire": i % 15 == 0, "lane": i % LANES}])
		if str(s.get("phase", "")) == "results":
			break
	return s
