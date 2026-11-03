extends RefCounted
class_name EchoesGauntletSim
## Survival Gauntlet / Echoes of Convergence.
## Echoes are not real Puppets/souls; bosses are simulations; no canonical cosmic defeat.

const Authority = preload("res://scripts/trials/mode_authority.gd")
const SIM_HZ := 60

const BOSS_WAVES := [
	{"id": "echo_rook", "label": "Ironside Echo", "hp": 120, "is_simulation": true},
	{"id": "echo_yin_yang_fracture", "label": "Fractured Dual Echo", "hp": 200, "is_simulation": true},
	{"id": "echo_origin_mirage", "label": "Origin Mirage", "hp": 300, "is_simulation": true, "not_true_rosamere": true},
]


static func create(seed: int = 1, coop: bool = false) -> Dictionary:
	var players: Array = [{"slot": 0, "fighter_id": "kaia-windrow", "hp": 100, "alive": true}]
	if coop:
		players.append({"slot": 1, "fighter_id": "ember-vale", "hp": 100, "alive": true})
	return {
		"mode": "echoes_gauntlet",
		"frame": 0,
		"seed": seed,
		"phase": "wave_intro",
		"wave_index": 0,
		"players": players,
		"coop": coop,
		"boss": {},
		"echo_adds": [],
		"score": 0,
		"canonical_cosmic_defeat": false,
		"lore": {
			"echoes_are_real_puppets": false,
			"echoes_are_souls": false,
			"bosses_are_simulations": true,
			"kaia_philosophical_victory_preserved": true,
			"yin_not_evil": true,
			"yang_not_simple_good": true,
		},
	}


static func _start_wave(state: Dictionary) -> void:
	var idx: int = int(state.get("wave_index", 0))
	if idx >= BOSS_WAVES.size():
		state["phase"] = "cleared"
		## Cleared simulation — never a true cosmic defeat of Rosamere / cosmos.
		state["canonical_cosmic_defeat"] = false
		return
	var spec: Dictionary = BOSS_WAVES[idx].duplicate(true)
	state["boss"] = {
		"id": spec.get("id", ""),
		"label": spec.get("label", ""),
		"hp": int(spec.get("hp", 100)),
		"max_hp": int(spec.get("hp", 100)),
		"is_simulation": true,
		"not_true_rosamere": bool(spec.get("not_true_rosamere", false)),
	}
	state["phase"] = "fight"
	state["echo_adds"] = []


static func deal_damage(state: Dictionary, amount: int) -> void:
	if str(state.get("phase", "")) != "fight":
		return
	var boss: Dictionary = state.get("boss", {})
	if boss.is_empty():
		return
	boss["hp"] = maxi(0, int(boss.get("hp", 0)) - amount)
	state["boss"] = boss
	state["score"] = int(state.get("score", 0)) + amount
	if int(boss["hp"]) <= 0:
		state["wave_index"] = int(state.get("wave_index", 0)) + 1
		state["phase"] = "wave_intro"
		## Origin Mirage KO is avatar/sim only.
		if bool(boss.get("not_true_rosamere", false)):
			state["canonical_cosmic_defeat"] = false


static func step(state: Dictionary, attack: bool = false) -> Dictionary:
	var next: Dictionary = state.duplicate(true)
	if str(next.get("phase", "")) in ["cleared", "defeated"]:
		return next
	next["frame"] = int(next.get("frame", 0)) + 1
	var phase := str(next.get("phase", ""))
	if phase == "wave_intro":
		_start_wave(next)
		return next
	if phase == "fight":
		var rng: Callable = Authority.mulberry32(int(next.get("seed", 1)) + int(next.get("frame", 0)))
		if attack:
			deal_damage(next, 6 + int(rng.call() * 4))
		## Echo adds are simulations.
		if int(next.get("frame", 0)) % (SIM_HZ * 2) == 0:
			var adds: Array = next.get("echo_adds", [])
			adds.append({"kind": "fracture_echo", "is_real_soul": false, "frame": next["frame"]})
			next["echo_adds"] = adds
		## Boss chip damage — if all players down, defeated (local only; not canon cosmic).
		if int(next.get("frame", 0)) % 45 == 0:
			for p in next.get("players", []):
				if bool(p.get("alive", true)):
					p["hp"] = maxi(0, int(p.get("hp", 0)) - 2)
					if int(p["hp"]) <= 0:
						p["alive"] = false
		var any: bool = false
		for p in next.get("players", []):
			if bool(p.get("alive", false)):
				any = true
		if not any:
			next["phase"] = "defeated"
			next["canonical_cosmic_defeat"] = false
	return next


static func state_hash(state: Dictionary) -> String:
	var boss_hp: int = 0
	if typeof(state.get("boss", {})) == TYPE_DICTIONARY:
		boss_hp = int(state["boss"].get("hp", 0))
	return Authority.hash_parts(int(state.get("seed", 0)), [
		state.get("frame", 0), state.get("phase", ""), state.get("wave_index", 0),
		boss_hp, state.get("score", 0), state.get("canonical_cosmic_defeat", false),
	])


static func notify_player_attack(state: Dictionary, damage: int = 8) -> Dictionary:
	## Live HitResolver / attack ownership feeds boss damage — still simulation bosses only.
	var next: Dictionary = state.duplicate(true)
	if str(next.get("phase", "")) != "fight":
		return next
	deal_damage(next, maxi(1, damage))
	next["player_owned_boss_hits"] = int(next.get("player_owned_boss_hits", 0)) + 1
	next["canonical_cosmic_defeat"] = false
	next["live_shared_combat"] = true
	return next


static func tick_live_from_battle(state: Dictionary, attacking: bool, coop_attacking: bool = false) -> Dictionary:
	## Advance gauntlet from live BattleScene attack states; bosses remain simulations.
	var next: Dictionary = step(state, attacking)
	if coop_attacking and bool(next.get("coop", false)):
		next = notify_player_attack(next, 5)
	elif attacking:
		next["live_attack_ticks"] = int(next.get("live_attack_ticks", 0)) + 1
	next["canonical_cosmic_defeat"] = false
	next["live_shared_combat"] = true
	next["real_enemies"] = true
	return next


static func live_hud(state: Dictionary) -> Dictionary:
	var boss: Dictionary = state.get("boss", {})
	return {
		"phase": str(state.get("phase", "")),
		"wave_index": int(state.get("wave_index", 0)),
		"boss_id": str(boss.get("id", "")),
		"boss_hp": int(boss.get("hp", 0)),
		"boss_is_simulation": bool(boss.get("is_simulation", true)),
		"canonical_cosmic_defeat": false,
		"player_owned_boss_hits": int(state.get("player_owned_boss_hits", 0)),
		"echo_adds": (state.get("echo_adds", []) as Array).size(),
		"live": true,
	}


static func run_clear_smoke(seed: int = 5, coop: bool = false) -> Dictionary:
	var s := create(seed, coop)
	var guard: int = 0
	while str(s.get("phase", "")) not in ["cleared", "defeated"] and guard < SIM_HZ * 120:
		s = step(s, true)
		guard += 1
	return s
