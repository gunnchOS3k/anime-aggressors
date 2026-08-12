extends RefCounted
class_name CpuController

## Competitive CPU: observation-only decisions, seeded RNG, difficulty tiers 1–5.
## Forbidden: reading opponent private aura / move runner internals / writing opponent state.

const TIER_NAMES := ["", "novice", "standard", "skilled", "expert", "master"]

var level: int = 2
var _timer: float = 0.0
var _fighter
var _rng := RandomNumberGenerator.new()
var _seed: int = 0
var _obs_cache: Dictionary = {}


func setup(fighter, cpu_level: int, match_seed: int = 0) -> void:
	_fighter = fighter
	level = clampi(cpu_level, 1, 5)
	_seed = match_seed if match_seed != 0 else int(hash(str(fighter.fighter_id) + str(fighter.slot) + str(cpu_level)))
	_rng.seed = _seed
	_timer = 0.0


func set_seed(seed_value: int) -> void:
	_seed = seed_value
	_rng.seed = seed_value


func tick(delta: float, opponent: Node2D) -> void:
	if _fighter == null or opponent == null:
		return
	_timer -= delta
	var obs := observe(opponent)
	_obs_cache = obs
	_act(obs, delta)


## Public observation model — only externally visible combat facts.
func observe(opponent: Node2D) -> Dictionary:
	var self_pos: Vector2 = _fighter.global_position
	var opp_pos: Vector2 = opponent.global_position
	var dx: float = opp_pos.x - self_pos.x
	var dy: float = opp_pos.y - self_pos.y
	var dist := absf(dx)
	var opp_attacking := false
	var opp_shielding := false
	var opp_hitstun := false
	var opp_airborne := true
	if opponent.has_method("is_on_floor"):
		opp_airborne = not opponent.is_on_floor()
	if "shielding" in opponent:
		opp_shielding = bool(opponent.shielding)
	if "state_machine" in opponent and opponent.state_machine != null:
		var st: String = str(opponent.state_machine.current_state)
		opp_attacking = st.contains("attack") or st.contains("special") or st.contains("throw") or st.contains("aura_burst")
		opp_hitstun = st.contains("hitstun") or st.contains("hurt") or st.contains("launch") or st.contains("tumble")
	# Visible percents / stocks only — never opponent.aura or private move frames.
	var opp_pct: float = float(opponent.damage_percent) if "damage_percent" in opponent else 0.0
	var opp_stocks: int = int(opponent.stocks) if "stocks" in opponent else 1
	var self_pct: float = float(_fighter.damage_percent)
	var self_aura: float = float(_fighter.aura)  # own meter is legal
	var tags: Array = _fighter.data.get("cpuBehaviorTags", [])
	return {
		"dx": dx,
		"dy": dy,
		"dist": dist,
		"approach": dist > 70.0,
		"in_range": dist < 95.0,
		"close": dist < 40.0,
		"opp_attacking": opp_attacking,
		"opp_shielding": opp_shielding,
		"opp_hitstun": opp_hitstun,
		"opp_airborne": opp_airborne,
		"opp_pct": opp_pct,
		"opp_stocks": opp_stocks,
		"self_pct": self_pct,
		"self_aura": self_aura,
		"self_on_floor": _fighter.is_on_floor(),
		"tags": tags,
		"facing_toward": signf(dx) == float(_fighter.facing) or absf(dx) < 8.0,
	}


func _act(obs: Dictionary, _delta: float) -> void:
	var reaction := _reaction_chance()
	# Tier 1: approach / spacing only.
	if level >= 1:
		if obs.approach and obs.self_on_floor:
			_sim_axis(signf(obs.dx))
		elif obs.close and obs.self_on_floor:
			_sim_axis(-signf(obs.dx) * 0.5)

	# Tier 2: jumps + shield vs visible attack windups.
	if level >= 2:
		if obs.self_on_floor and _chance(0.006 * level):
			_sim_jump()
		if obs.opp_attacking and obs.in_range and _chance(reaction):
			_sim_shield(true)
		elif obs.in_range and _chance(0.008 * level):
			_sim_shield(true)
		elif _chance(0.02):
			_sim_shield(false)

	# Tier 3: punish / poke on timer using observed range & hitstun.
	if level >= 3 and _timer <= 0.0:
		_timer = _decision_interval()
		if obs.opp_hitstun and obs.in_range:
			_sim_attack("attack_neutral" if _chance(0.55) else "special_neutral")
		elif obs.in_range:
			if _chance(0.3):
				_sim_attack("special_neutral")
			elif _chance(0.22):
				_sim_dodge()
			else:
				_sim_attack("attack_neutral")
		elif obs.self_on_floor and _chance(0.18):
			_sim_jump()

	# Tier 4–5: archetype play + legal aura (charge/burst via inputs only — no aura writes).
	if level >= 4 and _timer <= 0.0:
		_timer = _decision_interval() * 0.85
		_act_archetype(obs)
		# Own aura only; never set aura = 100.
		if obs.self_aura >= 100.0 and obs.in_range and _chance(0.32 + 0.05 * float(level)):
			_sim_aura_burst()
		elif obs.self_aura < 40.0 and _chance(0.12 + 0.03 * float(level)):
			_sim_aura_charge()
		if obs.self_pct > 80.0 and obs.dist > 120.0:
			_sim_axis(-signf(obs.dx))

	if level >= 5 and obs.opp_attacking and obs.close and _chance(reaction * 1.2):
		_sim_dodge()


## Per-fighter cpuBehaviorTags — must diverge (GAME-001 anti-reskin).
func _act_archetype(obs: Dictionary) -> void:
	var tags: Array = obs.tags
	# Ember / rushdown: close distance aggressively.
	if ("rushdown" in tags or "approach" in tags) and obs.dist > 55.0:
		_sim_axis(signf(obs.dx))
		if _chance(0.2):
			_sim_attack("special_forward")
		return
	# Rook / tank-punish: shield space then heavy commit.
	if ("tank" in tags or "punish" in tags):
		if obs.opp_attacking and obs.in_range:
			_sim_shield(true)
		elif obs.in_range and _chance(0.35):
			_sim_attack("attack_heavy" if _chance(0.55) else "special_down")
		elif obs.dist > 100.0:
			_sim_axis(signf(obs.dx) * 0.6)
		return
	# Juno / speed-combo: dash-in confirms + aerial chains.
	if ("speed" in tags or "combo" in tags):
		if obs.opp_hitstun and obs.in_range:
			_sim_attack("attack_neutral")
		elif obs.dist > 70.0:
			_sim_axis(signf(obs.dx))
			if _chance(0.25):
				_sim_attack("special_forward")
		elif _chance(0.3):
			_sim_jump()
			_sim_attack("attack_air_neutral" if obs.opp_airborne else "attack_neutral")
		return
	# Kaia / spacing-aerial: keep air advantage + projectiles.
	if ("spacing" in tags or "aerial" in tags):
		if obs.dist < 90.0:
			_sim_axis(-signf(obs.dx))
		if obs.self_on_floor and _chance(0.28):
			_sim_jump()
		elif _chance(0.32):
			_sim_attack("special_neutral")
		elif not obs.self_on_floor and _chance(0.4):
			_sim_attack("attack_air_up" if _chance(0.5) else "attack_air_forward")
		return
	# Nix / control-defensive: freeze space + grab after projectile.
	if ("control" in tags or "defensive" in tags):
		if obs.dist < 110.0 and _chance(0.4):
			_sim_attack("special_neutral")
		elif obs.close and _chance(0.28):
			_sim_attack("grab")
		elif obs.opp_attacking:
			_sim_shield(true)
		elif obs.dist > 130.0:
			_sim_axis(signf(obs.dx) * 0.5)
		return
	# Orion / combo-neutral: pull tools then juggle.
	if "neutral" in tags and "combo" in tags:
		if obs.dist > 80.0 and _chance(0.4):
			_sim_attack("special_forward")
		elif obs.in_range:
			_sim_attack("attack_up" if _chance(0.45) else "special_neutral")
		return
	# Vesper / trickster-mixup: phase tools + crossups.
	if ("trickster" in tags or "mixup" in tags):
		if _chance(0.3):
			_sim_attack("special_down")
		elif obs.dist > 75.0 and _chance(0.35):
			_sim_attack("special_neutral")
		elif obs.close and _chance(0.25):
			_sim_attack("grab")
		elif _chance(0.2):
			_sim_dodge()
		return
	# Legacy fallbacks.
	if "zoner" in tags and obs.dist < 140.0:
		_sim_axis(-signf(obs.dx))
		if _chance(0.28):
			_sim_attack("special_neutral")
	elif "acrobat" in tags and _chance(0.22):
		_sim_jump()


func _reaction_chance() -> float:
	match level:
		1: return 0.04
		2: return 0.08
		3: return 0.14
		4: return 0.22
		_: return 0.32


func _decision_interval() -> float:
	match level:
		1: return 0.55 + _rng.randf() * 0.35
		2: return 0.35 + _rng.randf() * 0.3
		3: return 0.25 + _rng.randf() * 0.25
		4: return 0.18 + _rng.randf() * 0.2
		_: return 0.12 + _rng.randf() * 0.15


func _chance(p: float) -> bool:
	return _rng.randf() < clampf(p, 0.0, 1.0)


func _sim_axis(v: float) -> void:
	var slot: int = int(_fighter.slot)
	if v > 0.1:
		Input.action_press("p%d_right" % slot)
		Input.action_release("p%d_left" % slot)
	elif v < -0.1:
		Input.action_press("p%d_left" % slot)
		Input.action_release("p%d_right" % slot)
	else:
		Input.action_release("p%d_left" % slot)
		Input.action_release("p%d_right" % slot)


func _sim_jump() -> void:
	Input.action_press("p%d_jump" % _fighter.slot)
	_fighter.call_deferred("_release_action", "p%d_jump" % _fighter.slot)


func _sim_shield(on: bool) -> void:
	if on:
		Input.action_press("p%d_shield" % _fighter.slot)
	else:
		Input.action_release("p%d_shield" % _fighter.slot)


func _sim_attack(cmd: String) -> void:
	_fighter.queue_attack_command(cmd)


func _sim_dodge() -> void:
	Input.action_press("p%d_dodge" % _fighter.slot)
	_fighter.call_deferred("_release_action", "p%d_dodge" % _fighter.slot)


func _sim_aura_charge() -> void:
	# Charge via legal inputs only (shield + special). Always schedule a
	# release — previously these action_press calls were sticky, so a CPU that
	# started charging could leave pN_shield/pN_special held for the rest of
	# the match (and after is_cpu flipped false), blocking real H2H damage.
	var slot: int = int(_fighter.slot)
	Input.action_press("p%d_shield" % slot)
	Input.action_press("p%d_special" % slot)
	_fighter.call_deferred("_release_action", "p%d_shield" % slot)
	_fighter.call_deferred("_release_action", "p%d_special" % slot)


func clear_simulated_inputs() -> void:
	if _fighter == null:
		return
	var slot: int = int(_fighter.slot)
	for suffix in ["left", "right", "up", "down", "jump", "attack", "special", "shield", "grab", "dodge"]:
		var action := "p%d_%s" % [slot, suffix]
		if InputMap.has_action(action) and Input.is_action_pressed(action):
			Input.action_release(action)


func _sim_aura_burst() -> void:
	# Must already have 100 aura from legal play — never forge meter.
	if float(_fighter.aura) < 100.0:
		return
	Input.action_press("p%d_attack" % _fighter.slot)
	_fighter.call_deferred("_release_action", "p%d_attack" % _fighter.slot)
