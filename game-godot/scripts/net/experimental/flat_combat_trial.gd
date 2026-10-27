extends Node2D
## EXPERIMENTAL, NOT shipping enabled. Fully owned flat-ground movement and
## canonical jab -> shield/Perfect Guard or whiff only. No CharacterBody,
## PhysicsServer, timers, audio, visual effects, Story writes or network grants.
## Both original advance and replay execute these SAME rules/components.

const Runner = preload("res://scripts/combat/move_runner.gd")
const Guard = preload("res://scripts/combat/perfect_guard.gd")
const Machine = preload("res://scripts/fighters/fighter_state_machine.gd")
const Outcome = preload("res://scripts/combat/combat_outcome.gd")
const MathRules = preload("res://scripts/combat/combat_math.gd")
const States = preload("res://scripts/fighters/fighter_states.gd")
const STEP := 1.0 / 60.0
const LIMIT := 4096
const ACTOR_FIELDS := ["position", "velocity", "grounded", "floor_normal", "facing", "shield_health", "shielding", "_shield_stun_limit", "_hitstop", "held", "attack_count", "activation_contact", "whiffed", "hooks"]
const SUPPORTED_STATES := ["idle", "walk", "run", "dash", "attack_startup", "attack_active", "attack_recovery", "shield_start", "shield_hold", "shield_hit", "shield_stun"]

class TimelineResolver extends "res://scripts/combat/hit_resolver.gd":
	var world

	func _contact_contract(attacker: Node, defender: Node, move: Dictionary, info: Dictionary) -> Dictionary:
		# Retain the production contact metadata, replacing ONLY unstable
		# engine-instance/wall clocks with owned epoch/frame/event identity.
		var result: Dictionary = super._contact_contract(attacker, defender, move, info)
		result["combat_event_id"] = "flat:%d:%d:%d:%d:%d:%d" % [world.epoch, world.frame, attacker.slot, defender.slot, attacker.move_runner.activation_id, _contact_sequence]
		result["gameplay_frame"] = world.frame
		result["timestamp_usec"] = int(round(float(world.frame) * 1000000.0 / 60.0))
		result["timeline_epoch"] = world.epoch
		result["contact_world"] = attacker.attack_bounds().intersection(defender.hurt_bounds()).get_center()
		return result

	func _record_hit_telemetry(info: Dictionary) -> void:
		# A replay creates/replaces INTENTS, never global telemetry, audio,
		# progression or irreversible presentation. Native effect binding is
		# deliberately outside this isolated proof.
		world.record_contact_intent(info)

class Actor extends Node2D:
	var world
	var slot := 0
	var fighter_id := ""
	var body_variant := ""
	var data: Dictionary = {}
	var jab: Dictionary = {}
	var body_rect := Rect2()
	var hurt_rect := Rect2()
	var run_speed := 0.0
	var dash_speed := 0.0
	var traction := 0.0
	var velocity := Vector2.ZERO
	var grounded := true
	var floor_normal := Vector2.UP
	var facing := 1
	var damage_percent := 0.0
	var aura := 0.0
	var combo_count := 0
	var invincible := false
	var controls_enabled := true
	var combat_closed := false
	var grabbed_by = null
	var grabbed_target = null
	var shielding := false
	var shield_health := 0.0
	var _shield_stun_limit := 0.25
	var _hitstop := 0.0
	var state_machine
	var move_runner
	var perfect_guard
	var held := {"axis":0.0, "attack":false, "shield":false}
	var attack_count := 0
	var activation_contact := false
	var whiffed := false
	var hooks: Dictionary = {}
	signal hit_landed(info: Dictionary)

	func setup(owner, index: int, source: Node, source_jab: Dictionary) -> void:
		world = owner
		slot = index
		fighter_id = str(source.fighter_id)
		body_variant = str(source.model_3d.get_body_variant())
		data = source.data.duplicate(true)
		jab = source_jab.duplicate(true)
		run_speed = float(source.get_run_speed())
		dash_speed = float(source.get_dash_speed())
		traction = float(source.get_traction())
		body_rect = local_source_rect(source, "CollisionShape2D")
		hurt_rect = local_source_rect(source, "Hurtbox/HurtShape")
		shield_health = float(data.get("shieldProfile", {}).get("maxHealth", 100.0))
		facing = 1 if slot == 1 else -1
		state_machine = Machine.new()
		add_child(state_machine)
		state_machine.setup(self)
		move_runner = Runner.new()
		add_child(move_runner)
		# Bind owner without starting a fabricated move or emitting a signal.
		move_runner._fighter_body = self
		move_runner.active_frames_tick.connect(_active)
		move_runner.phase_changed.connect(_phase)
		move_runner.move_ended.connect(_ended)
		perfect_guard = Guard.new()
		perfect_guard.setup(self)

	func local_source_rect(source: Node2D, path: String) -> Rect2:
		var shape: CollisionShape2D = source.get_node(path)
		return (source.global_transform.affine_inverse() * shape.global_transform) * shape.shape.get_rect()

	func is_on_floor() -> bool:
		return grounded

	func get_weight() -> float:
		return float(data.get("weight", 100.0))

	func get_damage_dealt_mult() -> float:
		return float(data.get("damageDealt_mult", data.get("damageDealtMult", 1.0)))

	func get_aura() -> float:
		return aura

	func get_effective_combat_aura() -> float:
		return aura

	func stale_repeat_count(_move: String) -> int:
		# This bounded world accepts exactly ONE initiating jab. No stale
		# history or combo damage is invented for subsequent moves.
		return 0

	func stamp_runtime_hook(hook: String) -> void:
		hooks[hook] = true

	func body_bounds() -> Rect2:
		return Rect2(position + body_rect.position, body_rect.size)

	func hurt_bounds() -> Rect2:
		return Rect2(position + hurt_rect.position, hurt_rect.size)

	func attack_bounds() -> Rect2:
		var boxes: Array = move_runner.move_data.get("hitboxes", [])
		if boxes.is_empty(): return Rect2()
		var box: Dictionary = boxes[0]
		var size := Vector2(float(box.width), float(box.height))
		var center := position + Vector2(float(box.offset_x) * facing, float(box.offset_y))
		return Rect2(center - size * 0.5, size)

	func pre_step(input: Dictionary) -> void:
		if _hitstop > 0.0:
			_hitstop -= STEP
			return
		# Same ordering as Fighter: regen, state update/held decay, movement,
		# guard/action reads, then actual position integration.
		if not shielding and state_machine.current_state not in ["shield_hold", "shield_start", "shield_break", "shield_stun"]:
			shield_health = minf(float(data.get("shieldProfile", {}).get("maxHealth", 100.0)), shield_health + MathRules.SHIELD_REGEN_PER_SECOND * STEP)
		state_machine.update(STEP)
		var axis := float(input.axis)
		if not state_machine.can_move():
			velocity.x = move_toward(velocity.x, 0.0, run_speed * STEP * 8.0)
		elif absf(axis) > 0.1:
			facing = 1 if axis > 0.0 else -1
			var speed := dash_speed if absf(axis) > 0.75 else run_speed
			state_machine.enter("dash" if absf(axis) > 0.75 else ("run" if absf(velocity.x) > speed * 0.5 else "walk"))
			velocity.x = move_toward(velocity.x, axis * speed, traction * STEP)
		else:
			velocity.x = move_toward(velocity.x, 0.0, traction * STEP)
			if absf(velocity.x) < 10.0: state_machine.enter("idle")
		var shield_edge := bool(input.shield) and not bool(held.shield)
		var guard_step: Dictionary = Outcome.guard_transition(state_machine.current_state, bool(input.shield), shield_edge, grounded, true, not state_machine.can_attack())
		if str(guard_step.state) != state_machine.current_state:
			if bool(guard_step.begin_parry): perfect_guard.begin()
			shielding = str(guard_step.state) in ["shield_start", "shield_hold"]
			state_machine.enter(str(guard_step.state))
		var attack_edge := bool(input.attack) and not bool(held.attack)
		held = input.duplicate(true)
		if attack_edge and state_machine.can_attack() and not shielding:
			if slot != 1 or attack_count != 0:
				world.reject("Only the one canonical initiating jab is supported")
				return
			attack_count += 1
			activation_contact = false
			move_runner.start_move(jab, self)
			state_machine.enter("attack_startup")
		position += velocity * STEP
		# This is a deliberately GROUNDED finite-platform candidate. It does
		# not pretend that floor clamping implements ledges, falls or slopes.
		grounded = true
		floor_normal = Vector2.UP
		if not is_zero_approx(velocity.y) or body_bounds().position.x < world.platform.position.x or body_bounds().end.x > world.platform.end.x:
			world.reject("Unsupported aerial or platform-edge movement")

	func combat_step() -> void:
		perfect_guard.tick()
		if _hitstop <= 0.0: move_runner.tick_sim_frame()

	func _active(_move: Dictionary) -> void:
		state_machine.enter("attack_active")
		world.resolve_active(self)

	func _phase(phase: String) -> void:
		if phase == "recovery" and state_machine.current_state == "attack_active":
			state_machine.enter("attack_recovery")
			if not activation_contact and not whiffed:
				whiffed = true
				world.record_whiff(self)

	func _ended(_move: String) -> void:
		# Matches Fighter's recovery ownership; no extra cancel windows.
		state_machine.enter("idle")

	func receive_hit(attacker: Node, info: Dictionary) -> void:
		if not shielding or not bool(info.get("blocked", false)):
			world.reject("Body-hit reaction/knockback is not implemented by this trial")
			return
		var result: Dictionary = Outcome.shield_contact(shield_health, float(info.get("shield_damage", 0.0)), false, int(info.get("shield_stun_frames", 0)))
		if result.state != "shield_hit":
			world.reject("Shield break is not implemented by this trial")
			return
		shield_health = float(result.shield_health)
		info["damage_applied"] = 0.0
		info["stocks_delta"] = 0
		info["shield_event"] = str(result.event)
		_hitstop = MathRules.frames_to_seconds(int(info.get("hitstop_frames", 3)))
		attacker._hitstop = _hitstop * 0.5
		_shield_stun_limit = Outcome.stun_seconds(int(result.shield_stun_frames), Outcome.SHIELD_STUN_FALLBACK_SECONDS)
		state_machine.enter("shield_hit")
		hit_landed.emit(info)

	func capture() -> Dictionary:
		var row: Dictionary = {"identity":{"instance":get_instance_id(), "slot":slot, "fighter":fighter_id, "body":body_variant}}
		for key in ACTOR_FIELDS:
			var value = get(key)
			row[key] = value.duplicate(true) if value is Dictionary or value is Array else value
		row["runner"] = move_runner.capture_component_state()
		row["guard"] = perfect_guard.capture_component_state()
		row["machine"] = state_machine.capture_component_state()
		return row

	func valid_state(row: Dictionary) -> bool:
		var baseline := capture()
		if row.size() != baseline.size() or row.get("identity", {}) != baseline.identity: return false
		for key in baseline:
			if not row.has(key) or typeof(row[key]) != typeof(baseline[key]): return false
		if not world.finite_value(row) or not row.grounded or row.floor_normal != Vector2.UP or not is_zero_approx(row.velocity.y): return false
		if row.facing not in [-1, 1] or row.attack_count < 0 or row.attack_count > 1 or (slot != 1 and row.attack_count != 0): return false
		if row.shield_health <= 0.0 or row.shield_health > float(data.get("shieldProfile", {}).get("maxHealth", 100.0)) or row._hitstop < -STEP or row._hitstop > 0.1: return false
		if row._shield_stun_limit <= 0.0 or row._shield_stun_limit > 0.25 or not world.valid_input(row.held): return false
		if absf(float(row.position.y) + body_rect.end.y - world.platform.position.y) > 0.00001: return false
		if row.position.x + body_rect.position.x < world.platform.position.x or row.position.x + body_rect.end.x > world.platform.end.x: return false
		# Production validators execute on detached shadow COMPONENTS bound to
		# this same actor; they cannot mutate this actor or emit live callbacks.
		var runner_check = Runner.new()
		runner_check._fighter_body = self
		var runner_ok: bool = runner_check.restore_component_state(row.runner)
		runner_check.free()
		var guard_check = Guard.new()
		guard_check.setup(self)
		var guard_ok: bool = guard_check.restore_component_state(row.guard)
		var machine_check = Machine.new()
		machine_check.setup(self)
		var machine_ok: bool = machine_check.restore_component_state(row.machine)
		machine_check.free()
		if not runner_ok or not guard_ok or not machine_ok: return false
		if row.runner.activation_id != row.attack_count: return false
		# Nested fields are inspected only AFTER real component schema/type
		# validation, so malformed records cannot throw halfway through restore.
		if row.machine.current_state not in SUPPORTED_STATES or row.machine.previous_state not in SUPPORTED_STATES: return false
		if row.runner.active and row.runner.move_data != jab: return false
		if not row.runner.move_data.is_empty() and row.runner.move_data != jab: return false
		for key in row.runner.hit_targets:
			if key != str(world.actors[1].get_instance_id()) or typeof(row.runner.hit_targets[key]) != TYPE_BOOL or not row.runner.hit_targets[key]: return false
		return true

	func install_validated(row: Dictionary) -> void:
		# Called only after BOTH actors, events and world state validate. No
		# start_move, FSM enter, shield event or ownership transfer is emitted.
		for key in ACTOR_FIELDS:
			var value = row[key]
			set(key, value.duplicate(true) if value is Dictionary or value is Array else value)
		var restored_runner: bool = move_runner.restore_component_state(row.runner)
		var restored_guard: bool = perfect_guard.restore_component_state(row.guard)
		var restored_machine: bool = state_machine.restore_component_state(row.machine)
		assert(restored_runner and restored_guard and restored_machine)

var actors: Array = []
var resolver
var epoch := 0
var frame := 0
var events: Array = []
var last_retired_events: Array = []
var failure := ""
var platform := Rect2()
var _contract := ""
var _rules_ratio := 1.0
var _advancing := false
var _ready_trial := false

func reject(reason: String) -> void:
	if failure.is_empty(): failure = reason

func configure_from_live(p: Node, d: Node, stage: Dictionary, epoch_value: int) -> bool:
	var accepted := _configure_from_live_impl(p, d, stage, epoch_value)
	if not accepted: reject("Source configuration is outside the isolated flat-jab trial contract")
	return accepted

func _configure_from_live_impl(p: Node, d: Node, stage: Dictionary, epoch_value: int) -> bool:
	if not is_inside_tree() or _ready_trial or epoch_value <= 0: return false
	if stage.get("layoutType", "") != "flat" or not stage.get("sidePlatforms", []).is_empty() or stage.get("ledges", true): return false
	var move: Dictionary = p.move_runner.move_data.duplicate(true)
	if move.get("move_id", "") != "jab_1" or move.get("move_type", "") != "melee" or move.has("projectile") or move.get("grounded_air", "") != "grounded" or move.get("_party_move", false) or move.get("form_override_applied", false): return false
	if float(p.aura) >= 25.0 or float(d.aura) >= 25.0 or bool(p.invincible) or bool(d.invincible): return false
	for source in [p, d]:
		# Live base IDs are character-owned (KAIA_BASE, JUNO_BASE, ...), not
		# the visual/canonical umbrella label "BASE".
		var base_id := str(source.get_forms_doc().get("default_form", ""))
		if source.get_current_form_id() != base_id or source.party_overdrive.state != "BASE": return false
	# This first proof uses the actual Kaia jab's unit-scale authored box.
	# Other profile scaling requires the same resolved runtime shape contract.
	if float(p.data.get("hitHurtProfile", {}).get("hitboxScale", 1.0)) != 1.0: return false
	if not move.get("self_movement", {}).is_empty() or int(move.get("armor_frames", 0)) > 0: return false
	if move.get("hitboxes", []).size() != 1 or int(move.get("startup_frames", 0)) <= 0 or int(move.get("active_frames", 0)) <= 0: return false
	if stage.get("spawnPoints", []).size() != 2: return false
	var main: Dictionary = stage.get("mainPlatform", {})
	if not main.has_all(["x", "y", "width", "height"]) or float(main.width) <= 0.0: return false
	platform = Rect2(Vector2(float(main.x) - float(main.width) * 0.5, float(main.y)), Vector2(float(main.width), float(main.height)))
	epoch = epoch_value
	_rules_ratio = float(GameState.damage_ratio)
	if not is_finite(_rules_ratio) or _rules_ratio <= 0.0: return false
	for i in range(2):
		var source: Node = p if i == 0 else d
		for path in ["CollisionShape2D", "Hurtbox/HurtShape"]:
			var shape = source.get_node_or_null(path)
			if shape == null or not shape.shape is RectangleShape2D: return false
		if not source.global_transform.is_finite(): return false
		var spawn: Dictionary = stage.spawnPoints[i]
		if not spawn.has_all(["x", "y"]): return false
	for i in range(2):
		var source: Node = p if i == 0 else d
		var actor = Actor.new()
		actor.name = "TrialActor%d" % (i + 1)
		add_child(actor)
		actor.setup(self, i + 1, source, move if i == 0 else {})
		var spawn: Dictionary = stage.spawnPoints[i]
		actor.position = Vector2(float(spawn.x), platform.position.y - actor.body_rect.end.y)
		actors.append(actor)
	resolver = TimelineResolver.new()
	resolver.world = self
	add_child(resolver)
	_contract = digest({"stage":stage, "actors":actors.map(func(actor): return {"fighter":actor.fighter_id, "body":actor.body_variant, "data":actor.data, "jab":actor.jab, "body_rect":actor.body_rect, "hurt_rect":actor.hurt_rect, "run":actor.run_speed, "dash":actor.dash_speed, "traction":actor.traction}), "rules_ratio":_rules_ratio})
	_ready_trial = true
	return true

func valid_input(input: Dictionary) -> bool:
	return input.size() == 3 and input.has_all(["axis", "attack", "shield"]) and typeof(input.axis) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(input.axis)) and absf(float(input.axis)) <= 1.0 and typeof(input.attack) == TYPE_BOOL and typeof(input.shield) == TYPE_BOOL

func advance_owned(input_epoch: int, input_frame: int, p1: Dictionary, p2: Dictionary) -> bool:
	# Local source-owned input history, not an authorization to accept remote
	# combat state. Reject duplicates/gaps/foreign epochs BEFORE any mutation.
	if input_epoch != epoch or input_frame != frame + 1: return false
	return advance(p1, p2)

func advance(p1: Dictionary, p2: Dictionary) -> bool:
	if not _ready_trial or _advancing or not failure.is_empty() or frame >= LIMIT: return false
	if not valid_input(p1) or not valid_input(p2) or bool(p2.attack): return false
	if float(GameState.damage_ratio) != _rules_ratio: reject("Prematch damage rules changed"); return false
	_advancing = true
	frame += 1
	actors[0].pre_step(p1)
	actors[1].pre_step(p2)
	if actors[0].body_bounds().intersects(actors[1].body_bounds()): reject("Body-overlap/pushbox case is outside the bounded trial")
	if failure.is_empty():
		# Preserve the existing per-actor BattleSim order, including each
		# PerfectGuard tick before that actor's own runner, not a new rule.
		for actor in actors: actor.combat_step()
	for actor in actors:
		if actor.state_machine.current_state not in SUPPORTED_STATES: reject("Unsupported state")
	_advancing = false
	return failure.is_empty()

func resolve_active(attacker: Node) -> void:
	if not failure.is_empty(): return
	var defender = actors[1]
	if not attacker.attack_bounds().intersects(defender.hurt_bounds()): return
	if not defender.shielding:
		reject("Unshielded body contact is deliberately unsupported, not a fabricated miss")
		return
	var info: Dictionary = resolver.resolve(attacker, defender, attacker.move_runner.move_data, attacker.damage_percent)
	if not info.is_empty(): attacker.activation_contact = true

func record_contact_intent(info: Dictionary) -> void:
	if str(info.get("contact_result", "")) not in ["shield", "parry"]:
		reject("Resolver produced an unsupported contact")
		return
	events.append(info.duplicate(true))

func record_whiff(actor: Node) -> void:
	events.append({"combat_event_id":"flat-whiff:%d:%d:%d:%d" % [epoch, frame, actor.slot, actor.move_runner.activation_id], "timeline_epoch":epoch, "gameplay_frame":frame, "contact_result":"whiff", "confirmed_contact":false, "attacker_id":actor.fighter_id, "move_id":actor.move_runner.current_move_id(), "damage_applied":0.0})

func capture() -> Dictionary:
	assert(_ready_trial and not _advancing)
	return {"schema":"flat_combat_trial/v1", "world":get_instance_id(), "epoch":epoch, "frame":frame, "contract":_contract, "actors":actors.map(func(actor):return actor.capture()), "events":events.duplicate(true), "contact_sequence":resolver._contact_sequence, "resolver_logs":resolver.recent_logs(), "failure":failure}

func restore(record: Dictionary) -> bool:
	if not _ready_trial or _advancing: return false
	var baseline := capture()
	if record.size() != baseline.size() or record.get("schema", "") != baseline.schema or record.get("world", 0) != get_instance_id() or record.get("epoch", 0) != epoch or record.get("contract", "") != _contract: return false
	for key in baseline:
		if not record.has(key) or typeof(record[key]) != typeof(baseline[key]): return false
	if not finite_value(record) or record.frame < 0 or record.frame > frame or record.frame > LIMIT or record.actors.size() != 2 or record.events.size() > LIMIT or record.contact_sequence < 0 or record.contact_sequence > LIMIT or record.resolver_logs.size() > 24 or not record.failure.is_empty(): return false
	var ids: Dictionary = {}
	for event in record.events:
		if typeof(event) != TYPE_DICTIONARY or event.get("timeline_epoch", -1) != epoch or typeof(event.get("gameplay_frame")) != TYPE_INT or event.gameplay_frame < 1 or event.gameplay_frame > record.frame or typeof(event.get("combat_event_id")) != TYPE_STRING or event.combat_event_id.is_empty() or ids.has(event.combat_event_id) or event.get("contact_result", "") not in ["shield", "parry", "whiff"]: return false
		ids[event.combat_event_id] = true
	for line in record.resolver_logs:
		if typeof(line) != TYPE_STRING: return false
	for i in range(2):
		if typeof(record.actors[i]) != TYPE_DICTIONARY or not actors[i].valid_state(record.actors[i]): return false
		if record.actors[i].guard.clock != record.frame: return false
	var first_body := Rect2(record.actors[0].position + actors[0].body_rect.position, actors[0].body_rect.size)
	var second_body := Rect2(record.actors[1].position + actors[1].body_rect.position, actors[1].body_rect.size)
	if first_body.intersects(second_body): return false
	# Every validation completed before touching live world/components. Retire
	# abandoned intents even if a replacement later reuses the SAME stable ID
	# with a different outcome (shield -> Perfect Guard, for example).
	last_retired_events = events.filter(func(event): return not record.events.any(func(old):return old == event)).duplicate(true)
	for i in range(2): actors[i].install_validated(record.actors[i])
	frame = record.frame
	events = record.events.duplicate(true)
	resolver._contact_sequence = record.contact_sequence
	resolver._logs = record.resolver_logs.duplicate(true)
	failure = ""
	return true

func finite_value(value: Variant, depth: int = 0) -> bool:
	if depth > 32: return false
	match typeof(value):
		TYPE_FLOAT: return is_finite(value)
		TYPE_VECTOR2: return is_finite(value.x) and is_finite(value.y)
		TYPE_RECT2: return finite_value(value.position, depth + 1) and finite_value(value.size, depth + 1)
		TYPE_ARRAY:
			for item in value:
				if not finite_value(item, depth + 1): return false
		TYPE_DICTIONARY:
			for key in value:
				if typeof(key) not in [TYPE_STRING, TYPE_INT] or not finite_value(value[key], depth + 1): return false
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING: pass
		_: return false
	return true

func digest(value: Variant) -> String:
	var hash_context := HashingContext.new()
	hash_context.start(HashingContext.HASH_SHA256)
	hash_context.update(var_to_bytes(value))
	return hash_context.finish().hex_encode()
