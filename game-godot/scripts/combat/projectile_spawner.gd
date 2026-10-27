extends Node
class_name ProjectileSpawner
const _AuraScaler = preload("res://scripts/combat/aura_scaler.gd")
const _AAProjectile = preload("res://scripts/combat/projectile.gd")

## Spawns _AAProjectile instances from move projectile config.

const PROJECTILE_SCENE := preload("res://scenes/combat/Projectile2D.tscn")
signal projectile_spawned(projectile: Node)

var owner_fighter: Node = null
var active_projectiles: Array = []
var _spawn_sequence := 0
var _interaction_data: Dictionary = {}
# Trusted-local component history, not a network packet restore endpoint.
# Deliberately disabled in live LAN until whole-world physics replay exists.
var _history_epoch := 0
var _history_frame := -1
var _history_floor := 0
var _retained: Dictionary = {}
var _history_simulation: WeakRef

func setup(fighter: Node) -> void:
	owner_fighter = fighter
	_interaction_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat/projectile_interactions.json"))

func spawn_from_move(move: Dictionary, aura_amount: float) -> Node:
	var proj_cfg: Dictionary = move.get("projectile", {})
	if proj_cfg.is_empty():
		return null
	var level: int = int(_AuraScaler.aura_level(aura_amount))
	var speed_arr: Array = proj_cfg.get("speed_by_aura", [400])
	var dmg_arr: Array = proj_cfg.get("damage_by_aura", [move.get("damage", 8)])
	var size_arr: Array = proj_cfg.get("size_by_aura", [16])
	var life_arr: Array = proj_cfg.get("lifetime_frames_by_aura", [90])
	var beh_arr: Array = proj_cfg.get("behavior_by_aura", ["straight"])
	var speed: float = float(_AuraScaler.projectile_value_by_aura(speed_arr, aura_amount))
	var dmg: float = float(_AuraScaler.projectile_value_by_aura(dmg_arr, aura_amount))
	var sz: float = float(_AuraScaler.projectile_value_by_aura(size_arr, aura_amount))
	var life := int(_AuraScaler.projectile_value_by_aura(life_arr, aura_amount))
	var beh_idx := mini(level, beh_arr.size() - 1)
	var behavior: String = beh_arr[beh_idx]
	var spawn_frame: int = int(proj_cfg.get("spawn_frame", 0))
	if owner_fighter == null:
		return null
	var limit := int(proj_cfg.get("max_active_per_move", 0))
	if limit > 0:
		var same: Array = active_projectiles.filter(func(p): return is_instance_valid(p) and p.active and p.move_id == str(move.get("move_id", "")))
		while same.size() >= limit:
			same.pop_front().cancel_immediate()
		owner_fighter.stamp_runtime_hook("construct_limit")
	var proj = PROJECTILE_SCENE.instantiate()
	var battle_root := owner_fighter.get_parent()
	if battle_root:
		battle_root.add_child(proj)
	else:
		owner_fighter.add_child(proj)
	var facing: int = owner_fighter.facing if "facing" in owner_fighter else 1
	if "attack_direction" in owner_fighter and int(owner_fighter.attack_direction) != 0:
		facing = int(owner_fighter.attack_direction)
	var offset := Vector2(float(proj_cfg.get("offset_x", 40)) * facing, float(proj_cfg.get("offset_y", -12)))
	proj.global_position = owner_fighter.global_position + offset
	var element: String = move.get("element_effect", {}).get("type", "")
	var tier := str(move.get("projectile_tier", ""))
	if tier.is_empty():
		match level:
			0, 1:
				tier = "projectile_tap"
			2:
				tier = "projectile_medium"
			_:
				tier = "projectile_full"
	var projectile_move := move.duplicate(true)
	projectile_move["_attack_activation_id"] = owner_fighter.move_runner.activation_id
	_spawn_sequence += 1
	var fighter_id: String = owner_fighter.fighter_id if "fighter_id" in owner_fighter else ""
	var interaction: Dictionary = _interaction_data.get("fighters", {}).get(fighter_id, {}).get(str(move.get("move_id", "")), {})
	if bool(move.get("_party_move",false)) and interaction.is_empty():
		interaction={"eligible_behaviors":["straight"],"integrity_by_aura":[1],"residual_damage_exponent":1.0}
	var integrity_values: Array = interaction.get("integrity_by_aura", [1])
	var team := "story:" + str(owner_fighter.get_meta("story_team")) if owner_fighter.has_meta("story_team") else "slot:" + str(owner_fighter.slot)
	var cfg := {
		"fighter_id": owner_fighter.fighter_id if "fighter_id" in owner_fighter else "",
		"move_id": move.get("move_id", ""),
		"aura_level": level,
		"projectile_tier": tier,
		"team_slot": owner_fighter.slot if "slot" in owner_fighter else 1,
		"team_key": team,
		"order_id": owner_fighter.slot * 1000000 + _spawn_sequence,
		"clash_eligible": behavior in interaction.get("eligible_behaviors", []),
		"integrity": int(integrity_values[mini(level, integrity_values.size() - 1)]),
		"residual_damage_exponent": float(interaction.get("residual_damage_exponent", 1.0)),
		"lifetime_frames": life,
		"speed": speed,
		"behavior": behavior,
		# Motion classification (including beam) grants no fighter piercing.
		"pierces_fighters": bool(proj_cfg.get("pierce", false)),
		"damage": dmg,
		"move_data": projectile_move,
		"angle_deg": float(proj_cfg.get("angle_deg", 0)),
		"size": Vector2(sz, sz),
		"color": _element_color(element),
	}
	proj.configure(cfg, owner_fighter)
	if _history_epoch > 0:
		proj._history_retained = true
		_retained[proj.order_id] = {"shot":proj, "last_live_frame":-1}
	if str(proj_cfg.get("type", "")) == "definition_panel": owner_fighter.stamp_runtime_hook("definition_construct")
	active_projectiles.append(proj)
	proj.projectile_expired.connect(func(): active_projectiles.erase(proj))
	projectile_spawned.emit(proj)
	return proj

func tick_all() -> void:
	for p in active_projectiles.duplicate():
		if is_instance_valid(p):
			p.tick_sim_frame()

func clear_all() -> void:
	for p in active_projectiles.duplicate():
		if is_instance_valid(p):
			p.cancel_immediate()
	active_projectiles.clear()

func count() -> int:
	var n := 0
	for p in active_projectiles:
		if is_instance_valid(p):
			n += 1
	return n

func set_debug_visible(v: bool) -> void:
	for p in active_projectiles:
		if is_instance_valid(p):
			p.set_debug_visible(v)

func begin_network_component_history(epoch: int, simulation: Node) -> bool:
	if epoch <= 0 or _history_epoch != 0 or not is_instance_valid(owner_fighter): return false
	if not is_instance_valid(simulation) or not "fighters" in simulation or owner_fighter not in simulation.fighters: return false
	_history_simulation = weakref(simulation)
	_history_epoch = epoch; _history_frame = -1; _history_floor = 0
	for shot in active_projectiles:
		if is_instance_valid(shot) and shot.active:
			shot._history_retained = true
			_retained[shot.order_id] = {"shot":shot, "last_live_frame":-1}
	return true

func capture_network_component(epoch: int, frame: int) -> Dictionary:
	if epoch != _history_epoch or epoch <= 0 or frame < _history_frame or frame < _history_floor: return {}
	var states: Array = []
	for shot in active_projectiles:
		if not is_instance_valid(shot) or not shot.active: return {}
		var state: Dictionary = shot.capture_network_component()
		if state.is_empty() or not _retained.has(shot.order_id): return {}
		states.append({"id":shot.order_id, "state":state})
	# Do not partially advance retention if any component could not be closed.
	for row in states: _retained[row.id].last_live_frame = frame
	_history_frame = frame
	return {"schema":1, "epoch":epoch, "frame":frame, "owner":owner_fighter.get_instance_id(),
		"slot":owner_fighter.slot, "fighter":owner_fighter.fighter_id,
		"spawn_sequence":_spawn_sequence, "shots":states}

func validates_network_component(state: Dictionary) -> bool:
	if not is_instance_valid(owner_fighter) or _history_epoch <= 0: return false
	# Immediate Area monitoring changes are illegal inside PhysicsServer query
	# flush. This limited component transaction requires an idle, halted world;
	# a future historical physics coordinator must supply its own real backend.
	if Engine.is_in_physics_frame() or _history_simulation == null: return false
	var simulation = _history_simulation.get_ref()
	if not is_instance_valid(simulation) or not simulation.paused or not simulation._pending_frame.is_empty(): return false
	for actor in simulation.fighters:
		if is_instance_valid(actor) and actor.is_physics_processing() and not get_tree().paused: return false
	if state.get("schema") != 1 or state.get("epoch") != _history_epoch or state.get("owner") != owner_fighter.get_instance_id(): return false
	if state.get("slot") != owner_fighter.slot or state.get("fighter") != owner_fighter.fighter_id: return false
	if typeof(state.get("frame")) != TYPE_INT or state.frame < _history_floor or state.frame > _history_frame: return false
	if typeof(state.get("spawn_sequence")) != TYPE_INT or state.spawn_sequence < 0 or state.spawn_sequence > _spawn_sequence: return false
	if not state.get("shots") is Array: return false
	var ids: Dictionary = {}
	for row in state.shots:
		if not row is Dictionary or typeof(row.get("id")) != TYPE_INT or not row.get("state") is Dictionary: return false
		if ids.has(row.id) or not _retained.has(row.id): return false
		if row.id <= owner_fighter.slot * 1000000 or row.id > owner_fighter.slot * 1000000 + state.spawn_sequence: return false
		var shot = _retained[row.id].shot
		if not is_instance_valid(shot) or not shot.validates_network_component(row.state) or not row.state.active: return false
		ids[row.id] = true
	return true

func restore_network_component(state: Dictionary) -> bool:
	# All validation precedes any mutation. Historical CharacterBody physics,
	# fighter damage, event ledgers and interaction manager are NOT restored
	# here; callers must never present this as complete combat rollback.
	if not validates_network_component(state): return false
	for id in _retained.keys():
		var shot = _retained[id].shot
		if is_instance_valid(shot): shot.deactivate_network_component_silent()
		# IDs beyond the restored spawn serial belong to a discarded future.
		# Historical snapshots after this frame are invalidated by the caller.
		if id > owner_fighter.slot * 1000000 + state.spawn_sequence:
			if is_instance_valid(shot): shot.queue_free()
			_retained.erase(id)
	active_projectiles.clear()
	for row in state.shots:
		var shot = _retained[row.id].shot
		shot.restore_network_component_silent(row.state)
		_retained[row.id].last_live_frame = state.frame
		active_projectiles.append(shot)
	_spawn_sequence = state.spawn_sequence; _history_frame = state.frame
	return true

func prune_network_component_history(oldest_frame: int) -> bool:
	if _history_epoch <= 0 or oldest_frame < _history_floor or oldest_frame > _history_frame + 1: return false
	_history_floor = oldest_frame
	for id in _retained.keys():
		var row: Dictionary = _retained[id]
		if not is_instance_valid(row.shot): _retained.erase(id)
		elif not row.shot.active and row.last_live_frame < oldest_frame:
			row.shot.deactivate_network_component_silent(); row.shot.queue_free(); _retained.erase(id)
	return true

func end_network_component_history() -> void:
	for row in _retained.values():
		if not is_instance_valid(row.shot): continue
		row.shot._history_retained = false
		if not row.shot.active:
			row.shot.deactivate_network_component_silent(); row.shot.queue_free()
	_retained.clear(); _history_epoch = 0; _history_frame = -1; _history_floor = 0; _history_simulation = null

func _exit_tree() -> void:
	# Retained shots are siblings of the fighter, not spawner children. Never
	# leak them when the match actor exits with a pending component history.
	for row in _retained.values():
		if is_instance_valid(row.shot):
			row.shot.deactivate_network_component_silent(); row.shot.queue_free()
	_retained.clear()

func _element_color(element: String) -> Color:
	match element:
		"flame": return Color(1.0, 0.4, 0.1, 0.8)
		"impact": return Color(0.9, 0.7, 0.2, 0.8)
		"volt": return Color(1.0, 0.95, 0.2, 0.8)
		"gale": return Color(0.3, 0.85, 0.5, 0.8)
		"frost": return Color(0.4, 0.7, 1.0, 0.8)
		"gravity": return Color(0.5, 0.4, 0.8, 0.8)
		"void": return Color(0.6, 0.2, 0.8, 0.8)
		_: return Color(0.9, 0.5, 0.2, 0.7)
