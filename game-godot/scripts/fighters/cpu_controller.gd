extends RefCounted
class_name CpuController

## Tiered CPU behavior using fighter archetype tags from JSON.

var level: int = 2
var _timer: float = 0.0
var _fighter: AAFighter

func setup(fighter: AAFighter, cpu_level: int) -> void:
	_fighter = fighter
	level = clampi(cpu_level, 1, 4)

func tick(delta: float, opponent: Node2D) -> void:
	if _fighter == null or opponent == null:
		return
	_timer -= delta
	var dx := opponent.global_position.x - _fighter.global_position.x
	var dist := absf(dx)
	var tags: Array = _fighter.data.get("cpuBehaviorTags", [])
	var approach := dist > 70.0
	var in_range := dist < 95.0

	if level >= 1:
		if approach and _fighter.is_on_floor():
			_sim_axis(signf(dx))
		elif dist < 40.0 and _fighter.is_on_floor():
			_sim_axis(-signf(dx) * 0.5)

	if level >= 2:
		if _fighter.is_on_floor() and randf() < 0.008 * level:
			_sim_jump()
		if in_range and randf() < 0.01 * level:
			_sim_shield(true)
		elif randf() < 0.02:
			_sim_shield(false)

	if level >= 3 and _timer <= 0.0:
		_timer = 0.25 + randf() * 0.45
		if in_range:
			if randf() < 0.35:
				_sim_attack("special_neutral")
			elif randf() < 0.25:
				_sim_dodge()
			else:
				_sim_attack("attack_neutral")
		elif _fighter.is_on_floor() and randf() < 0.2:
			_sim_jump()

	if level >= 4 and _timer <= 0.0:
		_timer = 0.2 + randf() * 0.35
		if "zoner" in tags and dist < 140.0:
			_sim_axis(-signf(dx))
			if randf() < 0.3:
				_sim_attack("special_neutral")
		elif "rushdown" in tags and dist > 60.0:
			_sim_axis(signf(dx))
		elif "acrobat" in tags and randf() < 0.25:
			_sim_jump()
		if _fighter.aura >= 100.0 and in_range and randf() < 0.35:
			_sim_aura_burst()
		elif _fighter.aura < 40.0 and randf() < 0.15:
			_sim_aura_charge()
		if _fighter.damage_percent > 80.0 and dist > 120.0:
			_sim_axis(signf(dx) * -1.0)

func _sim_axis(v: float) -> void:
	var slot := _fighter.slot
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
	Input.action_press("p%d_shield" % _fighter.slot)
	Input.action_press("p%d_special" % _fighter.slot)

func _sim_aura_burst() -> void:
	_fighter.aura = 100.0
	Input.action_press("p%d_attack" % _fighter.slot)
	_fighter.call_deferred("_release_action", "p%d_attack" % _fighter.slot)
