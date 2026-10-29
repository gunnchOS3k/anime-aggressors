extends RefCounted
class_name FlaglineFourBody
## Actual four-body Flagline combat authority — real Fighter nodes in BattleSim.
## Not logical CPU-only occupancy. Humans + CPU fill still honest; seats ≤ humans.
## HUMAN_ART remains false. SHIPPING_ROLLBACK remains false.

const Flagline = preload("res://scripts/trials/flagline/fractured_accord_sim.gd")


static func is_active(gs: Node = null) -> bool:
	var state := gs
	if state == null:
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null and tree.root != null:
			state = tree.root.get_node_or_null("GameState")
	if state == null:
		return false
	return str(state.mode) == "trials" \
		and str(state.trial_mode_id) == "fractured_accord" \
		and bool(state.trial_live_combat) \
		and bool(state.get("trial_four_body"))


static func roster_from_sim(sim: Dictionary) -> Array:
	## Map Flagline team_slots → BattleScene body roster (4 fighters).
	var out: Array = []
	var slots: Array = sim.get("team_slots", [])
	for i in range(mini(slots.size(), 4)):
		var entry: Dictionary = slots[i]
		out.append({
			"slot": i + 1,
			"fighter_id": str(entry.get("fighter_id", "ember-vale")),
			"team_id": str(entry.get("team_id", "solar")),
			"is_bot": bool(entry.get("is_bot", true)),
			"is_human": bool(entry.get("is_human", false)),
			"display_team": Flagline.display_team(str(entry.get("team_id", ""))),
		})
	return out


static func spawn_offsets() -> Array:
	## World spawn offsets relative to stage spawn midpoints (slot 1/2 anchors).
	return [
		Vector2(-220, 200),
		Vector2(220, 200),
		Vector2(-280, 280),
		Vector2(280, 280),
	]


static func collect_positions(battle: Node) -> Array:
	## Up to four real body positions from BattleScene fighters_root / named refs.
	var positions: Array = []
	if battle == null:
		return positions
	var named: Array = []
	for key in ["fighter1", "fighter2", "fighter3", "fighter4"]:
		if key in battle:
			var f = battle.get(key)
			if f != null and is_instance_valid(f):
				named.append(f)
	if named.size() >= 4:
		for f in named:
			positions.append(f.global_position)
		return positions
	var root = battle.get("fighters_root") if "fighters_root" in battle else battle.get_node_or_null("Fighters")
	if root == null:
		return positions
	for child in root.get_children():
		if child != null and is_instance_valid(child) and "global_position" in child:
			positions.append(child.global_position)
		if positions.size() >= 4:
			break
	return positions


static func connect_cross_team_hitboxes(battle: Node, bodies: Array, connect_fn: Callable) -> int:
	## Wire HitResolver ownership across opposing teams only (unless team_attack).
	var links: int = 0
	var gs = battle.get_node_or_null("/root/GameState") if battle != null else null
	var allow_ff: bool = gs != null and bool(gs.team_attack)
	for a in bodies:
		if a == null or not is_instance_valid(a):
			continue
		for d in bodies:
			if d == null or not is_instance_valid(d) or d == a:
				continue
			var ta := str(a.get_meta("flagline_team_id", ""))
			var td := str(d.get_meta("flagline_team_id", ""))
			if not allow_ff and ta != "" and ta == td:
				continue
			connect_fn.call(a, d)
			links += 1
	return links


static func rematch_payload(sim: Dictionary) -> Dictionary:
	## Rematch keeps four-body Flagline authority; resets room to fracture mid.
	return {
		"mode": "fractured_accord",
		"four_body": true,
		"battle_scene_fighter_slots": 4,
		"actual_combat_bodies": true,
		"logical_cpu_only": false,
		"seed": int(sim.get("seed", 42)),
		"connected_humans": int(sim.get("connected_humans", 0)),
		"SHIPPING_ROLLBACK_ENABLED": false,
		"HUMAN_ART_APPROVED": false,
	}


static func honesty(sim: Dictionary, body_count: int) -> Dictionary:
	var humans: int = int(sim.get("connected_humans", 0))
	return {
		"battle_scene_fighter_slots": body_count,
		"actual_combat_bodies": body_count >= 4,
		"logical_cpu_only": false,
		"logical_actors": 4,
		"connected_humans": humans,
		"cpu_fill_seats": maxi(0, 4 - humans),
		"not_four_simultaneous_human_bodies": humans < 4,
		"combat_authority": "BattleSim+HitResolver",
		"SHIPPING_ROLLBACK_ENABLED": false,
		"HUMAN_ART_APPROVED": false,
	}
