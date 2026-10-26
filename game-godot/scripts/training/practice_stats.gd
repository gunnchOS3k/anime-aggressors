extends RefCounted
## Observes real MoveRunner / HitResolver / projectile events. Never resolves
## contact, changes a fighter, or substitutes authored damage for applied damage.
var totals: Dictionary = {}
var attempts: Dictionary = {}
var shots: Dictionary = {}
var seen_events: Dictionary = {}
var recent: Array = []

func clear() -> void:
	totals.clear()
	attempts.clear()
	shots.clear()
	seen_events.clear()
	recent.clear()

func slot_stats(slot: int) -> Dictionary:
	if not totals.has(slot):
		totals[slot] = {"started": 0, "finished": 0, "landed": 0, "whiffs": 0,
			"defended": 0, "interrupted": 0, "unclassified": 0, "hits": 0,
			"damage": 0.0, "damage_taken": 0.0, "blocks": 0, "perfect_guards": 0,
			"armor": 0, "grabs": 0, "grab_whiffs": 0, "combo": 0,
			"combo_damage": 0.0, "best_combo": 0, "combo_activation": -1,
			"target": -1, "last_move": "", "last_result": "", "last_damage": 0.0}
	return totals[slot]

func key(slot: int, activation: int) -> String:
	return "%d:%d" % [slot, activation]

func move_started(slot: int, activation: int, move: Dictionary) -> void:
	var counter := slot_stats(slot)
	counter.last_move = str(move.get("move_id", ""))
	var projectile := move.has("projectile")
	var eligible := float(move.get("damage", 0.0)) > 0.0 and (
		projectile or not move.get("hitboxes", []).is_empty() or str(move.get("move_type", "")) == "throw")
	if not eligible:
		return
	var id := key(slot, activation)
	if attempts.has(id): return
	counter.started += 1
	attempts[id] = {"slot": slot, "move": counter.last_move, "ended": false,
		"natural": false, "projectile": projectile, "spawned": 0, "pending": 0,
		"natural_expiration": false, "hit": false, "defended": false, "damage": 0.0}

func move_ended(slot: int, activation: int, natural: bool) -> void:
	var id := key(slot, activation)
	if not attempts.has(id): return
	attempts[id].ended = true
	attempts[id].natural = natural
	_finish_if_ready(id)

func projectile_started(slot: int, activation: int, instance: int) -> void:
	var id := key(slot, activation)
	if not attempts.has(id) or shots.has(instance): return
	shots[instance] = id
	attempts[id].spawned += 1
	attempts[id].pending += 1

func projectile_ended(instance: int, natural_expiration: bool) -> void:
	if not shots.has(instance): return
	var id: String = shots[instance]
	shots.erase(instance)
	if not attempts.has(id): return
	attempts[id].pending -= 1
	attempts[id].natural_expiration = attempts[id].natural_expiration or natural_expiration
	_finish_if_ready(id)

func contact(attacker: int, defender: int, info: Dictionary) -> bool:
	var event := str(info.get("combat_event_id", ""))
	if not bool(info.get("confirmed_contact", false)) or event.is_empty() or seen_events.has(event):
		return false
	seen_events[event] = true
	if seen_events.size() > 512: seen_events.erase(seen_events.keys()[0])
	var source := slot_stats(attacker)
	var target := slot_stats(defender)
	var result := str(info.get("contact_result", ""))
	if result not in ["hit", "shield", "parry", "armor"]: return false
	var applied := maxf(0.0, float(info.get("damage_applied", 0.0)))
	var body_hit := result == "hit" and not bool(info.get("blocked", false))
	source.last_move = str(info.get("move_id", ""))
	source.last_result = result
	source.last_damage = applied
	var id := key(attacker, int(info.get("attack_activation_id", -1)))
	if attempts.has(id):
		attempts[id].hit = attempts[id].hit or body_hit
		attempts[id].defended = attempts[id].defended or result in ["shield", "parry", "armor"]
		if body_hit: attempts[id].damage += applied
	if body_hit:
		source.hits += 1
		source.damage += applied
		target.damage_taken += applied
		target.combo = 0
		target.combo_damage = 0.0
		var activation := int(info.get("attack_activation_id", -1))
		if not bool(info.get("defender_in_hitstun_before", false)) or source.combo == 0 or source.target != defender:
			source.combo = 1
			source.combo_damage = 0.0
		elif activation != source.combo_activation:
			source.combo += 1
		source.combo_activation = activation
		source.combo_damage += applied
		source.best_combo = maxi(source.best_combo, source.combo)
		source.target = defender
	else:
		source.combo = 0
		source.combo_damage = 0.0
		match result:
			"shield": target.blocks += 1
			"parry": target.perfect_guards += 1
			"armor": target.armor += 1
	return true

func recovered(defender: int) -> void:
	for value in totals.values():
		if value.target == defender:
			value.combo = 0
			value.combo_damage = 0.0

func grab(slot: int, result: String) -> void:
	var counter := slot_stats(slot)
	if result == "success": counter.grabs += 1
	elif result == "whiff": counter.grab_whiffs += 1

func _finish_if_ready(id: String) -> void:
	var row: Dictionary = attempts[id]
	if not row.ended or row.pending > 0: return
	var counter := slot_stats(int(row.slot))
	var outcome := "unclassified"
	if row.hit: outcome = "landed"
	elif row.defended: outcome = "defended"
	elif row.projectile:
		# An intercepted/canceled shot is not evidence of a fighter whiff.
		if row.spawned > 0 and row.natural_expiration: outcome = "whiffs"
	elif row.natural: outcome = "whiffs"
	else: outcome = "interrupted"
	counter.finished += 1
	counter[outcome] += 1
	counter.last_move = row.move
	counter.last_result = outcome
	counter.last_damage = row.damage
	recent.append({"slot": row.slot, "move": row.move, "outcome": outcome})
	if recent.size() > 32: recent.pop_front()
	attempts.erase(id)

func snapshot() -> Dictionary:
	return {"slots": totals.duplicate(true), "pending_attempts": attempts.size(),
		"pending_projectiles": shots.size(), "recent": recent.duplicate(true)}
