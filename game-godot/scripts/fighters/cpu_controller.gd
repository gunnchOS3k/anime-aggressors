extends RefCounted
class_name CpuController

## Competitive CPU: observation-only decisions, seeded RNG, difficulty tiers 1–5.
## Forbidden: reading opponent private aura / move runner internals / writing opponent state.
## VXP-2.2: edge awareness, recovery priority, countdown-safe (caller gates tick).

const TIER_NAMES := ["", "novice", "standard", "skilled", "expert", "master"]

var level: int = 2
var _timer: float = 0.0
var _fighter
var _rng := RandomNumberGenerator.new()
var _seed: int = 0
var _obs_cache: Dictionary = {}
var _charge_hold_remaining: float = 0.0
var _recovery_used: bool = false
var _last_goal: String = "neutral"


func setup(fighter, cpu_level: int, match_seed: int = 0) -> void:
	_fighter = fighter
	level = clampi(cpu_level, 1, 5)
	_seed = match_seed if match_seed != 0 else int(hash(str(fighter.fighter_id) + str(fighter.slot) + str(cpu_level)))
	_rng.seed = _seed
	_timer = 0.0
	_recovery_used = false
	_last_goal = "neutral"


func set_seed(seed_value: int) -> void:
	_seed = seed_value
	_rng.seed = seed_value


func tick(delta: float, opponent: Node2D) -> void:
	if _fighter == null or opponent == null:
		return
	# Hard gate: never synthesize inputs while fighter controls are locked (countdown).
	if "controls_enabled" in _fighter and not bool(_fighter.controls_enabled):
		clear_simulated_inputs()
		return
	_timer -= delta
	if _charge_hold_remaining > 0.0:
		_charge_hold_remaining -= delta
		var slot: int = int(_fighter.slot)
		Input.action_press("p%d_shield" % slot)
		Input.action_press("p%d_special" % slot)
		if _charge_hold_remaining <= 0.0:
			Input.action_release("p%d_shield" % slot)
			Input.action_release("p%d_special" % slot)
		return
	var obs := observe(opponent)
	_obs_cache = obs
	# Recovery / edge danger always outranks aggression at every tier.
	if obs.offstage or obs.edge_danger:
		_act_recovery(obs, delta)
		return
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
	var opp_pct: float = float(opponent.damage_percent) if "damage_percent" in opponent else 0.0
	var opp_stocks: int = int(opponent.stocks) if "stocks" in opponent else 1
	var self_pct: float = float(_fighter.damage_percent)
	var self_aura: float = float(_fighter.aura)  # own meter is legal
	var tags: Array = _fighter.data.get("cpuBehaviorTags", [])
	var on_floor: bool = _fighter.is_on_floor()
	var offstage: bool = false
	if _fighter.has_method("is_offstage"):
		offstage = bool(_fighter.is_offstage())
	elif not on_floor and "platform_half_width" in _fighter:
		offstage = absf(self_pos.x - float(_fighter.platform_center_x)) > float(_fighter.platform_half_width) + 8.0
	var edge_dist := 9999.0
	if "platform_half_width" in _fighter:
		edge_dist = float(_fighter.platform_half_width) - absf(self_pos.x - float(_fighter.platform_center_x))
	var edge_danger := on_floor and edge_dist < 48.0 and absf(dx) > 20.0 and signf(dx) == signf(self_pos.x - float(_fighter.platform_center_x))
	var stage_dx := 0.0
	if "platform_center_x" in _fighter:
		stage_dx = float(_fighter.platform_center_x) - self_pos.x
	var ledge := Vector2.ZERO
	if _fighter.has_method("nearest_ledge_anchor"):
		ledge = _fighter.nearest_ledge_anchor()
	var hanging := false
	if "state_machine" in _fighter and _fighter.state_machine != null:
		hanging = str(_fighter.state_machine.current_state) == "ledge_hang"
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
		"self_on_floor": on_floor,
		"tags": tags,
		"facing_toward": signf(dx) == float(_fighter.facing) or absf(dx) < 8.0,
		"offstage": offstage,
		"edge_danger": edge_danger,
		"edge_dist": edge_dist,
		"stage_dx": stage_dx,
		"ledge_x": ledge.x,
		"ledge_y": ledge.y,
		"hanging": hanging,
	}


func _act_recovery(obs: Dictionary, _delta: float) -> void:
	_last_goal = "recovery"
	# Grounded edge danger: stop chasing outward; face stage / back up.
	if obs.edge_danger and obs.self_on_floor:
		var inward := signf(obs.stage_dx)
		if inward == 0.0:
			inward = -signf(_fighter.global_position.x - float(_fighter.platform_center_x))
		_sim_axis(inward)
		if level >= 3 and obs.in_range and _chance(0.12 * float(level)):
			_sim_attack("attack_neutral")
		return
	# Ledge hang options by tier.
	if obs.hanging:
		if level <= 1:
			if _chance(0.02):
				_sim_jump()
		elif level == 2:
			if _chance(0.04):
				_sim_jump()
			elif _chance(0.03):
				_sim_attack("attack_neutral")
		else:
			if _chance(0.06 + 0.02 * float(level)):
				_sim_jump()
			elif _chance(0.05):
				_sim_attack("attack_neutral")
		return
	# Airborne offstage: move toward stage / nearest ledge; use recovery tools.
	var toward := signf(obs.stage_dx)
	if toward == 0.0 and absf(obs.ledge_x) > 0.01:
		toward = signf(obs.ledge_x - _fighter.global_position.x)
	_sim_axis(toward)
	var quality := _recovery_quality()
	if not obs.self_on_floor:
		# Jump toward stage when below ledge / falling.
		if _fighter.velocity.y > -40.0 and _chance(quality * 0.55):
			_sim_jump()
		# Up-special recovery — more reliable at higher tiers; Lv1 still tries late.
		if not _recovery_used and _chance(quality):
			_sim_attack("special_up")
			if level >= 3:
				_recovery_used = true
		elif level >= 4 and absf(obs.dy) > 40.0 and _chance(0.08):
			_sim_attack("special_forward")
	if obs.self_on_floor:
		_recovery_used = false


func _recovery_quality() -> float:
	match level:
		1: return 0.08
		2: return 0.16
		3: return 0.28
		4: return 0.42
		_: return 0.58


func _act(obs: Dictionary, _delta: float) -> void:
	_last_goal = "neutral"
	_recovery_used = false
	var reaction := _reaction_chance()
	# Tier 1: slow approach / spacing only — never walk off outward edges.
	if level >= 1:
		var axis := 0.0
		if obs.approach and obs.self_on_floor:
			axis = signf(obs.dx)
		elif obs.close and obs.self_on_floor:
			axis = -signf(obs.dx) * 0.5
		axis = _safe_ground_axis(axis, obs)
		_sim_axis(axis)

	# Tier 2: jumps + shield vs visible attack windups.
	if level >= 2:
		if obs.self_on_floor and _chance(0.006 * level) and obs.edge_dist > 60.0:
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
		elif obs.self_on_floor and _chance(0.18) and obs.edge_dist > 70.0:
			_sim_jump()

	# Tier 4–5: archetype play + legal aura (charge/burst via inputs only — no aura writes).
	if level >= 4 and _timer <= 0.0:
		_timer = _decision_interval() * 0.85
		_act_archetype(obs)
		if obs.self_aura >= 100.0 and obs.in_range and _chance(0.32 + 0.05 * float(level)):
			_sim_aura_burst()
		elif obs.self_aura < 40.0 and _chance(0.12 + 0.03 * float(level)):
			_sim_aura_charge()
		if obs.self_pct > 80.0 and obs.dist > 120.0:
			_sim_axis(_safe_ground_axis(-signf(obs.dx), obs))

	if level >= 5 and obs.opp_attacking and obs.close and _chance(reaction * 1.2):
		_sim_dodge()
	# Lv5: mild DI-like dodge when launched (visible hurt states on self).
	if level >= 5 and "state_machine" in _fighter and _fighter.state_machine != null:
		var self_st: String = str(_fighter.state_machine.current_state)
		if (self_st.contains("launch") or self_st.contains("tumble") or self_st.contains("hitstun")) and _chance(0.18):
			_sim_axis(signf(obs.stage_dx))


## Clamp approach so grounded motion never drives toward the outer blast.
func _safe_ground_axis(desired: float, obs: Dictionary) -> float:
	if not obs.self_on_floor:
		return desired
	if absf(desired) < 0.05:
		return desired
	# Near ledge: only allow inward motion.
	if obs.edge_dist < 52.0:
		var inward := signf(obs.stage_dx)
		if inward == 0.0:
			inward = -signf(_fighter.global_position.x - float(_fighter.platform_center_x))
		if signf(desired) != inward:
			return inward * 0.85
	return desired


## Per-fighter cpuBehaviorTags — must diverge (GAME-001 anti-reskin).
func _act_archetype(obs: Dictionary) -> void:
	var tags: Array = obs.tags
	if ("rushdown" in tags or "approach" in tags) and obs.dist > 55.0:
		_sim_axis(_safe_ground_axis(signf(obs.dx), obs))
		if _chance(0.2):
			_sim_attack("special_forward")
		return
	if ("tank" in tags or "punish" in tags):
		if obs.opp_attacking and obs.in_range:
			_sim_shield(true)
		elif obs.in_range and _chance(0.35):
			_sim_attack("attack_heavy" if _chance(0.55) else "special_down")
		elif obs.dist > 100.0:
			_sim_axis(_safe_ground_axis(signf(obs.dx) * 0.6, obs))
		return
	if ("speed" in tags or "combo" in tags):
		if obs.opp_hitstun and obs.in_range:
			_sim_attack("attack_neutral")
		elif obs.dist > 70.0:
			_sim_axis(_safe_ground_axis(signf(obs.dx), obs))
			if _chance(0.25):
				_sim_attack("special_forward")
		elif _chance(0.3) and obs.edge_dist > 70.0:
			_sim_jump()
			_sim_attack("attack_air_neutral" if obs.opp_airborne else "attack_neutral")
		return
	if ("spacing" in tags or "aerial" in tags):
		if obs.dist < 90.0:
			_sim_axis(_safe_ground_axis(-signf(obs.dx), obs))
		if obs.self_on_floor and _chance(0.28) and obs.edge_dist > 70.0:
			_sim_jump()
		elif _chance(0.32):
			_sim_attack("special_neutral")
		elif not obs.self_on_floor and _chance(0.4):
			_sim_attack("attack_air_up" if _chance(0.5) else "attack_air_forward")
		return
	if ("control" in tags or "defensive" in tags):
		if obs.dist < 110.0 and _chance(0.4):
			_sim_attack("special_neutral")
		elif obs.close and _chance(0.28):
			_sim_attack("grab")
		elif obs.opp_attacking:
			_sim_shield(true)
		elif obs.dist > 130.0:
			_sim_axis(_safe_ground_axis(signf(obs.dx) * 0.5, obs))
		return
	if "neutral" in tags and "combo" in tags:
		if obs.dist > 80.0 and _chance(0.4):
			_sim_attack("special_forward")
		elif obs.in_range:
			_sim_attack("attack_up" if _chance(0.45) else "special_neutral")
		return
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
	if "zoner" in tags and obs.dist < 140.0:
		_sim_axis(_safe_ground_axis(-signf(obs.dx), obs))
		if _chance(0.28):
			_sim_attack("special_neutral")
	elif "acrobat" in tags and _chance(0.22) and obs.edge_dist > 70.0:
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
	## GAME-RC-003: expose a short telegraph so players can read CPU commitment.
	if _fighter != null and _fighter.has_method("begin_cpu_telegraph"):
		_fighter.begin_cpu_telegraph(cmd, 0.18 + 0.02 * float(6 - level))
	_fighter.queue_attack_command(cmd)


func _sim_dodge() -> void:
	Input.action_press("p%d_dodge" % _fighter.slot)
	_fighter.call_deferred("_release_action", "p%d_dodge" % _fighter.slot)


func _sim_aura_charge() -> void:
	var slot: int = int(_fighter.slot)
	Input.action_press("p%d_shield" % slot)
	Input.action_press("p%d_special" % slot)
	_charge_hold_remaining = 0.55 + _rng.randf() * 0.35


func clear_simulated_inputs() -> void:
	_charge_hold_remaining = 0.0
	if _fighter == null:
		return
	var slot: int = int(_fighter.slot)
	for suffix in ["left", "right", "up", "down", "jump", "attack", "special", "shield", "grab", "dodge"]:
		var action := "p%d_%s" % [slot, suffix]
		if InputMap.has_action(action) and Input.is_action_pressed(action):
			Input.action_release(action)


func _sim_aura_burst() -> void:
	if float(_fighter.aura) < 100.0:
		return
	Input.action_press("p%d_attack" % _fighter.slot)
	_fighter.call_deferred("_release_action", "p%d_attack" % _fighter.slot)


## Test/harness helper — behavioral fingerprint by tier (no private opponent reads).
func difficulty_fingerprint() -> Dictionary:
	return {
		"level": level,
		"tier_name": TIER_NAMES[level] if level < TIER_NAMES.size() else "master",
		"reaction_chance": _reaction_chance(),
		"decision_interval_nominal": _decision_interval(),
		"recovery_quality": _recovery_quality(),
		"last_goal": _last_goal,
	}
