extends CharacterBody2D
class_name AAFighter
const _DataLoader = preload("res://scripts/data/data_loader.gd")
const _FighterStateMachine = preload("res://scripts/fighters/fighter_state_machine.gd")
const _FighterStates = preload("res://scripts/fighters/fighter_states.gd")
const _MoveRunner = preload("res://scripts/combat/move_runner.gd")
const _HitResolver = preload("res://scripts/combat/hit_resolver.gd")
const _ProjectileSpawner = preload("res://scripts/combat/projectile_spawner.gd")
const _CombatFeedback = preload("res://scripts/combat/combat_feedback.gd")
const _CpuController = preload("res://scripts/fighters/cpu_controller.gd")
const _FighterAnimator = preload("res://scripts/fighters/fighter_animator.gd")
const _ThrowResolver = preload("res://scripts/combat/throw_resolver.gd")
const _AuraScaler = preload("res://scripts/combat/aura_scaler.gd")
const _AuraIdentity = preload("res://scripts/combat/aura_identity.gd")
const _AuraSpecialRuntime = preload("res://scripts/combat/aura_special_runtime.gd")
const _CombatMath = preload("res://scripts/combat/combat_math.gd")
const _MoveResolver = preload("res://scripts/visual/runtime_move_resolver.gd")

signal damaged(amount: float, total: float)
signal koed()
signal respawned()
signal hit_landed(info: Dictionary)
signal grab_event(info: Dictionary)
signal state_changed(state: String)

const GRAVITY := 1800.0
const FAST_FALL_MULT := 1.45
const EDGE_MARGIN := 28.0

@export var slot: int = 1
@export var fighter_id: String = "ember-vale"
@export var is_cpu: bool = false
@export var facing: int = 1
@export var dummy_mode: String = "idle"  # "cpu" is training-only; default idle so human P1 is not dual-driven

var data: Dictionary = {}
var move_manifest: Dictionary = {}
var damage_percent: float = 0.0
var stocks: int = 3
var aura: float = 0.0
var shield_health: float = 100.0
var air_jumps_left: int = 1
var invincible: bool = false
var shielding: bool = false
var controls_enabled: bool = true
var _input_edge_held: Dictionary = {}
var spawn_point: Vector2 = Vector2.ZERO
var combo_count: int = 0
var hitstun_remaining: float = 0.0
var grabbed_target = null
var grabbed_by = null
var platform_half_width: float = 400.0
var platform_center_x: float = 0.0

var state_machine
var move_runner
var hit_resolver
var projectile_spawner
var combat_feedback
var cpu
var animator

@onready var body: ColorRect = $Body
@onready var model_3d = $Model3D
@onready var hurtbox: Area2D = $Hurtbox
@onready var hitbox: Area2D = $Hitbox
@onready var label: Label = $NameLabel
@onready var hitbox_debug: ColorRect = $HitboxDebug
@onready var hurtbox_debug: ColorRect = $HurtboxDebug
@onready var aura_vfx: ColorRect = $AuraVfx
@onready var grab_range_debug: ColorRect = $GrabRangeDebug

var _hitstop: float = 0.0
var _current_move: Dictionary = {}
var _pending_attack_cmd: String = ""
var _last_state: String = ""
var _aura_sfx_hook: bool = false
var _last_hit_result: Dictionary = {}
var _last_knockback: Vector2 = Vector2.ZERO
var _last_shield_damage: float = 0.0
var _cpu_telegraph_remaining: float = 0.0
var _cpu_telegraph_cmd: String = ""
var _telegraph_pulse: ColorRect = null
var _base_modulate: Color = Color.WHITE
var _last_element_effect: String = ""
var _throw_direction: String = ""
var _grab_throw_latch: bool = false
var _jab_chain: int = 0
var _show_grab_range: bool = false
var _show_projectile_boxes: bool = false
var _jump_short_hop: bool = false
var _was_airborne: bool = false
var _fast_falling: bool = false
var _air_dodge_used: bool = false
var _dodge_cooldown: float = 0.0
var _ledge_side: int = 0
var _di_strength: String = "medium"
var _pending_landing_from_attack: bool = false
var armor_frames_remaining: float = 0.0
var phase_cancel_remaining: float = 0.0
var dash_cancel_remaining: float = 0.0
var _runtime_hooks_seen: Dictionary = {}
var grab_mash: float = 0.0
var _recent_move_ids: Array = []
var last_impact_readable: bool = false
var last_feedback_tier: String = ""

func _ready() -> void:
	add_to_group("fighters")
	state_machine = _FighterStateMachine.new()
	add_child(state_machine)
	state_machine.setup(self)
	state_machine.state_changed.connect(_on_state_changed)
	move_runner = _MoveRunner.new()
	add_child(move_runner)
	move_runner.active_frames_tick.connect(_on_move_active)
	move_runner.move_ended.connect(_on_move_ended)
	move_runner.phase_changed.connect(_on_phase_changed)
	hit_resolver = _HitResolver.new()
	add_child(hit_resolver)
	projectile_spawner = _ProjectileSpawner.new()
	add_child(projectile_spawner)
	projectile_spawner.setup(self)
	combat_feedback = _CombatFeedback.new()
	add_child(combat_feedback)
	hit_resolver.combat_feedback = combat_feedback
	cpu = _CpuController.new()
	animator = _FighterAnimator.new()
	add_child(animator)
	if body:
		animator.setup(self, body)
	facing = 1 if slot == 1 else -1
	_setup_shapes()
	if hitbox_debug:
		hitbox_debug.visible = false
		hitbox_debug.add_to_group("hitbox_debug")
	if hurtbox_debug:
		hurtbox_debug.visible = false
		hurtbox_debug.add_to_group("hurtbox_debug")
	if aura_vfx:
		aura_vfx.visible = false
	if grab_range_debug:
		grab_range_debug.visible = false
		grab_range_debug.size = Vector2(_CombatMath.GRAB_RANGE_PX, 36)
		grab_range_debug.color = Color(0.2, 0.8, 1.0, 0.25)

func get_aura() -> float:
	return aura

func get_aura_level() -> int:
	return _AuraScaler.aura_level(aura)

func configure(id: String, player_slot: int, cpu_flag: bool, stock_count: int, spawn: Vector2) -> void:
	fighter_id = id
	slot = player_slot
	is_cpu = cpu_flag
	# Human-controlled slots must not inherit the training "cpu" dummy default,
	# or CpuController keeps synthesizing pN_shield/attack on top of real input
	# (production local-versus P1 was dual-driven and could trap in shield_hold).
	if not cpu_flag and dummy_mode == "cpu":
		dummy_mode = "idle"
	stocks = stock_count
	spawn_point = spawn
	data = _DataLoader.load_fighter(id)
	move_manifest = _DataLoader.load_moves(id)
	var model_loaded: bool = model_3d != null and model_3d.configure(data)
	if body:
		body.visible = not model_loaded
	if model_3d:
		model_3d.set_facing(facing)
	if animator:
		animator.set_proxy_visible(not model_loaded)
	ensure_visible_presentation()
	shield_health = float(data.get("shieldProfile", {}).get("maxHealth", 100))
	var gs = get_node_or_null("/root/GameState")
	var cpu_seed: int = 0
	var cpu_level: int = 2
	if gs != null:
		if "match_seed" in gs:
			cpu_seed = int(gs.match_seed)
		if is_cpu and "cpu_level" in gs:
			cpu_level = int(gs.cpu_level)
	cpu.setup(self, cpu_level, cpu_seed)
	if body and data.has("color"):
		body.color = Color(data.get("color"))
	if label:
		_apply_slot_combat_label()
	if aura_vfx and data.has("auraColor"):
		aura_vfx.color = Color(data.get("auraColor"))
		aura_vfx.color.a = 0.35


func is_model_loaded() -> bool:
	return model_3d != null and model_3d.is_model_loaded()


## Wave016/017: never leave nameplate visible with no fighter body representation.
## Invariant: FIGHTER_LOGIC_ACTIVE && FIGHTER_EXPECTED_VISIBLE -> VISIBLE_RENDERABLE_FIGHTER_BODY_REQUIRED
func ensure_visible_presentation() -> void:
	var model_ok := is_model_loaded()
	if model_ok and model_3d != null and model_3d.has_method("is_visible_renderable_body"):
		if not model_3d.is_visible_renderable_body():
			if model_3d.has_method("heal_visibility_if_needed"):
				model_3d.heal_visibility_if_needed()
			model_ok = model_3d.is_visible_renderable_body() if model_3d.has_method("is_visible_renderable_body") else is_model_loaded()
	var body_ok := body != null and body.visible
	if not model_ok and body != null:
		body.visible = true
		body_ok = true
		if animator and animator.has_method("set_proxy_visible"):
			animator.set_proxy_visible(true)
	if label:
		# Wave017: subtle P1/P2/CPU tags — never floating full name as sole identity.
		_apply_slot_combat_label()
		label.visible = model_ok or body_ok
	if model_ok and body != null:
		body.visible = false
	# Never allow floating name as only representation.
	if label and label.visible and not model_ok and not body_ok:
		label.visible = false


func _apply_slot_combat_label() -> void:
	if label == null:
		return
	var tag := "P%d" % slot
	if is_cpu:
		tag = "CPU" if slot != 1 else "P1"
	label.text = tag
	label.add_theme_font_size_override("font_size", 11)
	label.modulate = Color(1, 1, 1, 0.72)


func assert_visible_body_invariant() -> Dictionary:
	var logic_active := stocks > 0 and visible
	var expected := logic_active and is_inside_tree()
	var model_ok := is_model_loaded()
	if model_ok and model_3d != null and model_3d.has_method("is_visible_renderable_body"):
		model_ok = model_3d.is_visible_renderable_body()
	var body_ok := body != null and body.visible and body.modulate.a > 0.05
	var ok := (not expected) or model_ok or body_ok
	var name_only := label != null and label.visible and not model_ok and not body_ok
	return {
		"FIGHTER_LOGIC_ACTIVE": logic_active,
		"FIGHTER_EXPECTED_VISIBLE": expected,
		"VISIBLE_RENDERABLE_FIGHTER_BODY": model_ok or body_ok,
		"NAMEPLATE_ONLY_GHOST": name_only,
		"PASS": ok and not name_only,
	}


## Test harness hook — forces airborne resolution without inventing player controls.
var _force_airborne_test: bool = false

var _wave017_vis_accum: float = 0.0
var _wave017_ghost_events: int = 0

func force_airborne_for_test(airborne: bool) -> void:
	_force_airborne_test = airborne


func get_weight() -> float:
	return float(data.get("weight", 100))

func get_damage_dealt_mult() -> float:
	return float(data.get("damageDealt_mult", data.get("damageDealtMult", 1.0)))

func get_run_speed() -> float:
	return float(data.get("runSpeed", 280))

func get_dash_speed() -> float:
	return float(data.get("dashSpeed", 420))

func get_air_speed() -> float:
	var base := float(data.get("airSpeed", 220))
	var bonus: float = _AuraIdentity.air_drift_bonus(fighter_id, aura, str(data.get("combatTag", "")))
	return base * (1.0 + bonus)

func get_air_accel() -> float:
	var from_data := float(data.get("airAccel", 0.0))
	if from_data > 1.0:
		return from_data
	return _AuraIdentity.air_accel(fighter_id, str(data.get("combatTag", "")))

func get_traction() -> float:
	var from_data := float(data.get("groundTraction", 0.0))
	if from_data > 1.0:
		return from_data
	return _AuraIdentity.ground_traction(fighter_id, str(data.get("combatTag", "")))

func get_charge_move_mult() -> float:
	return _AuraIdentity.charge_move_mult(fighter_id, str(data.get("combatTag", "")))

func get_jump_strength() -> float:
	return float(data.get("jumpStrength", 620))

func get_fall_speed() -> float:
	return float(data.get("fallSpeed", 1800))

func tick_combat_frame() -> void:
	if _hitstop > 0.0:
		return
	move_runner.tick_sim_frame()
	projectile_spawner.tick_all()
	_sync_attack_phase_state()
	if move_runner != null and move_runner.is_active_phase():
		_poll_hitbox_overlaps()

func _physics_process(delta: float) -> void:
	_wave017_vis_accum += delta
	if _wave017_vis_accum >= 0.25:
		_wave017_vis_accum = 0.0
		var inv := assert_visible_body_invariant()
		if not bool(inv.get("PASS", true)):
			_wave017_ghost_events += 1
			ensure_visible_presentation()

	_tick_cpu_telegraph(delta)
	if _hitstop > 0.0:
		_hitstop -= delta
		return
	if _dodge_cooldown > 0.0:
		_dodge_cooldown = maxf(0.0, _dodge_cooldown - delta)
	_AuraSpecialRuntime.tick_fighter(self, delta)
	_tick_shield_regen(delta)
	# Kaia air-drift stamp (runtime, not data-only).
	if not is_on_floor() and _AuraIdentity.air_drift_bonus(fighter_id, aura, str(data.get("combatTag", ""))) > 0.0:
		stamp_runtime_hook("air_drift")
	if grabbed_target != null and state_machine.current_state not in [
		_FighterStates.GRAB_HOLD, _FighterStates.THROW_STARTUP, _FighterStates.THROW_RELEASE,
	]:
		state_machine.enter(_FighterStates.GRAB_HOLD)
	state_machine.update(delta)
	if grabbed_by != null:
		global_position = grabbed_by.global_position + Vector2(24 * grabbed_by.facing, -8)
		velocity = Vector2.ZERO
		return
	if state_machine.current_state == _FighterStates.LEDGE_HANG:
		return
	if state_machine.current_state in [_FighterStates.HITSTUN, _FighterStates.LAUNCHED, _FighterStates.TUMBLE, _FighterStates.HURT_LIGHT, _FighterStates.HURT_HEAVY]:
		if dummy_mode in ["di_in", "di_out"]:
			_dummy_apply_di()
		velocity.y += get_fall_speed() * delta
		move_and_slide()
		_check_ledge_grab()
		_check_edge()
		_track_landing()
		return
	if is_cpu or dummy_mode == "cpu":
		cpu.tick(delta, _find_opponent())
	elif dummy_mode != "idle":
		_dummy_tick(delta)
	if controls_enabled:
		_apply_movement(delta)
		# Handle attack/special BEFORE idle aura decay so a full meter (100)
		# can still trigger aura_burst on the same frame it would otherwise decay.
		_handle_actions()
	else:
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0.0, get_run_speed() * delta * 8.0)
	_tick_idle_aura_decay(delta)
	move_and_slide()
	_sync_motion_state()
	_check_ledge_grab()
	_check_edge()
	_track_landing()
	_play_current_animation(state_machine.current_state)

func _apply_movement(delta: float) -> void:
	if state_machine.current_state == _FighterStates.JUMP_SQUAT:
		velocity.x = move_toward(velocity.x, 0.0, get_run_speed() * delta * 4.0)
		if not _read_jump_held():
			_jump_short_hop = true
		return
	if state_machine.current_state in [_FighterStates.LAND, _FighterStates.AIR_DODGE, _FighterStates.DODGE_ACTIVE, _FighterStates.DODGE_RECOVERY]:
		if not is_on_floor() and state_machine.current_state == _FighterStates.AIR_DODGE:
			velocity.y += get_fall_speed() * 0.35 * delta
		elif is_on_floor():
			velocity.x = move_toward(velocity.x, 0.0, get_run_speed() * delta * 6.0)
		return
	if not state_machine.can_move():
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0.0, get_run_speed() * delta * 8.0)
		return
	var axis: float = _read_axis()
	if not is_on_floor():
		_fast_falling = velocity.y > 80 and not _read_jump_held() and _read_down()
		var ff: float = FAST_FALL_MULT if _fast_falling else 1.0
		velocity.y += get_fall_speed() * ff * delta
	else:
		air_jumps_left = int(data.get("maxJumps", 2)) - 1
		_air_dodge_used = false
		_fast_falling = false
		if velocity.y > 0:
			velocity.y = 0.0
	if absf(axis) > 0.1:
		# Grounded facing follows stick. Airborne facing stays put so back-airs
		# remain reachable (stick opposite facing) — matches facing-relative aerials.
		if is_on_floor():
			facing = 1 if axis > 0 else -1
		var spd: float = get_run_speed()
		if absf(axis) > 0.75 and is_on_floor():
			spd = get_dash_speed()
			state_machine.enter(_FighterStates.DASH)
		else:
			if is_on_floor():
				state_machine.enter(_FighterStates.RUN if absf(velocity.x) > spd * 0.5 else _FighterStates.WALK)
		if state_machine.current_state == _FighterStates.AURA_CHARGE:
			spd *= get_charge_move_mult()
		var target_x: float = axis * (spd if is_on_floor() else get_air_speed())
		if is_on_floor():
			velocity.x = move_toward(velocity.x, target_x, get_traction() * delta)
		else:
			velocity.x = move_toward(velocity.x, target_x, get_air_accel() * delta)
		if body:
			body.scale.x = absf(body.scale.x) * facing
		if model_3d:
			model_3d.set_facing(facing)
	else:
		var stop: float = get_traction() if is_on_floor() else get_air_accel() * 0.45
		velocity.x = move_toward(velocity.x, 0.0, stop * delta)
		if is_on_floor() and not _FighterStates.is_attack_state(state_machine.current_state):
			if absf(velocity.x) < 10.0:
				state_machine.enter(_FighterStates.IDLE)
	if _read_jump_pressed():
		if is_on_floor() and state_machine.current_state != _FighterStates.JUMP_SQUAT:
			_jump_short_hop = false
			state_machine.enter(_FighterStates.JUMP_SQUAT)
		elif air_jumps_left > 0 and not is_on_floor():
			velocity.y = -get_jump_strength() * 0.9
			air_jumps_left -= 1
			state_machine.enter(_FighterStates.DOUBLE_JUMP)

func _handle_actions() -> void:
	if _pending_attack_cmd != "":
		_start_move_by_command(_pending_attack_cmd)
		_pending_attack_cmd = ""
	# Vesper phase cancel / Juno dash cancel — interrupt recovery when windows are live.
	if _try_identity_cancel():
		return
	if state_machine.current_state == _FighterStates.GRAB_HOLD:
		_throw_direction = _ThrowResolver.read_throw_direction(self)
		if grab_range_debug:
			grab_range_debug.visible = _show_grab_range
		return
	if not state_machine.can_attack():
		return
	if is_aura_input_held():
		tick_aura_charge(get_physics_process_delta_time())
		if aura < 100.0:
			state_machine.enter(_FighterStates.AURA_CHARGE)
			_set_aura_vfx(true)
		else:
			state_machine.enter(_FighterStates.AURA_READY)
			_set_aura_vfx(true)
		# Jump cancels charge (platform-fighter interrupt, not locked).
		if _read_jump_pressed() and is_on_floor() and state_machine.current_state != _FighterStates.JUMP_SQUAT:
			_set_aura_vfx(false)
			_jump_short_hop = false
			state_machine.enter(_FighterStates.JUMP_SQUAT)
			return
	elif state_machine.current_state in [_FighterStates.AURA_CHARGE, _FighterStates.AURA_READY]:
		state_machine.enter(_FighterStates.IDLE)
		_set_aura_vfx(false)
	if _read_aura_burst() and aura >= 100.0:
		_start_move_by_command("aura_burst")
		return
	if _read_shield() and is_on_floor() and not is_aura_input_held():
		if state_machine.current_state != _FighterStates.SHIELD_HOLD:
			state_machine.enter(_FighterStates.SHIELD_START)
		state_machine.enter(_FighterStates.SHIELD_HOLD)
		shielding = true
		return
	if state_machine.current_state in [_FighterStates.SHIELD_HOLD, _FighterStates.SHIELD_START]:
		shielding = false
		state_machine.enter(_FighterStates.IDLE)
	if _read_dodge_pressed():
		_start_dodge()
	if _read_grab_pressed():
		_start_move("grab")
	if _read_attack_pressed():
		if aura >= 100.0:
			_start_move_by_command("aura_burst")
			return
		var cmd: String = _resolve_attack_command()
		_start_move_by_command(cmd)
	if _read_special_pressed() and not is_aura_input_held():
		_start_move_by_command(_resolve_special_command())

func _start_move(move_id: String) -> void:
	var m: Dictionary = _DataLoader.find_move(move_manifest, move_id)
	if not m.is_empty():
		_start_move_dict(m)

func _resolve_attack_command() -> String:
	if not is_on_floor():
		var axis: float = _read_axis()
		var up: bool = _read_up()
		var down: bool = _read_down()
		if up: return "attack_air_up"
		if down: return "attack_air_down"
		# Facing-relative aerial: stick with facing = forward air; opposite = back air.
		# Matches docs/CONTROLS.md back aerial without inventing a new button.
		if absf(axis) > 0.3:
			var stick_forward := (axis > 0.0 and facing > 0) or (axis < 0.0 and facing < 0)
			return "attack_air_forward" if stick_forward else "attack_air_back"
		return "attack_air_neutral"
	var axis: float = _read_axis()
	var up: bool = _read_up()
	var down: bool = _read_down()
	if absf(axis) > 0.75 and is_on_floor():
		return "attack_dash"
	if up: return "attack_up"
	if down: return "attack_down"
	if absf(axis) > 0.3: return "attack_forward"
	# heavy_attack / smash remain DESIGN_ONLY: CONTROLS do not distinguish tilt vs smash/heavy.
	if _jab_chain == 0: return "attack_neutral"
	if _jab_chain == 1: return "attack_neutral"
	return "attack_neutral"

func _resolve_special_command() -> String:
	var up: bool = _read_up()
	var down: bool = _read_down()
	var axis: float = _read_axis()
	if up: return "special_up"
	if down: return "special_down"
	if absf(axis) > 0.3: return "special_forward"
	return "special_neutral"

func is_aura_input_held() -> bool:
	if TouchInputManager.is_aura_charge_touch(slot):
		return true
	return Input.is_action_pressed("p%d_special" % slot) and Input.is_action_pressed("p%d_shield" % slot)

func queue_attack_command(cmd: String) -> void:
	var rec = get_node_or_null("/root/RuntimeFlightRecorder")
	if rec and rec.has_method("record_action"):
		rec.record_action(fighter_id, cmd, "Fighter.queue_attack_command", {})
	_pending_attack_cmd = cmd

## GAME-RC-003 — short visible CPU wind-up flash before the queued attack commits.
func begin_cpu_telegraph(cmd: String, duration: float = 0.2) -> void:
	_cpu_telegraph_cmd = cmd
	_cpu_telegraph_remaining = maxf(_cpu_telegraph_remaining, duration)
	_ensure_telegraph_pulse()
	if _telegraph_pulse != null:
		_telegraph_pulse.visible = true
		_telegraph_pulse.modulate = Color(1.0, 0.85, 0.2, 0.85)

func _ensure_telegraph_pulse() -> void:
	if _telegraph_pulse != null:
		return
	_telegraph_pulse = ColorRect.new()
	_telegraph_pulse.name = "CpuTelegraphPulse"
	_telegraph_pulse.size = Vector2(40, 56)
	_telegraph_pulse.position = Vector2(-20, -60)
	_telegraph_pulse.color = Color(1.0, 0.8, 0.15, 0.55)
	_telegraph_pulse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_telegraph_pulse.visible = false
	add_child(_telegraph_pulse)

func _tick_cpu_telegraph(delta: float) -> void:
	if _cpu_telegraph_remaining <= 0.0:
		if _telegraph_pulse != null:
			_telegraph_pulse.visible = false
		return
	_cpu_telegraph_remaining = maxf(0.0, _cpu_telegraph_remaining - delta)
	if _telegraph_pulse != null:
		var pulse := 0.45 + 0.4 * absf(sin(Time.get_ticks_msec() * 0.02))
		_telegraph_pulse.modulate.a = pulse
		_telegraph_pulse.visible = _cpu_telegraph_remaining > 0.0
	# Soft body flash while telegraphing (a11y: still visible with reduce_motion via alpha only).
	if body != null and _cpu_telegraph_remaining > 0.0:
		body.modulate = Color(1.25, 1.1, 0.7, 1.0)
	elif body != null:
		body.modulate = _base_modulate

func _start_move_by_command(cmd: String) -> void:
	var m: Dictionary = {}
	var airborne := (not is_on_floor()) or _force_airborne_test
	if cmd == "aura_burst":
		# Direct lookup — input_command routing can miss burst when airborne flag races.
		m = _DataLoader.find_move(move_manifest, "aura_burst")
	elif cmd == "attack_neutral" and not airborne:
		match _jab_chain:
			0: m = _DataLoader.find_move(move_manifest, "jab_1")
			1: m = _DataLoader.find_move(move_manifest, "jab_2")
			_: m = _DataLoader.find_move(move_manifest, "jab_finisher")
		if not m.is_empty():
			if _jab_chain < 2:
				_jab_chain += 1
			else:
				_jab_chain = 0
	else:
		m = _DataLoader.find_move_by_input(move_manifest, cmd, airborne)
	if m.is_empty():
		return
	_start_move_dict(m)

func _start_move_dict(m: Dictionary) -> void:
	_current_move = _AuraScaler.apply_to_move(m, aura)
	_current_move = _AuraIdentity.apply_to_scaled_move(
		_current_move, fighter_id, aura, str(data.get("combatTag", ""))
	)
	# Neutral special cast clip follows aura tier (tap/medium/full) — no new buttons.
	var mid0 := str(_current_move.get("move_id", m.get("move_id", "")))
	if mid0 == "neutral_special_projectile" or str(m.get("move_type", "")) == "projectile":
		var tier_clip := _MoveResolver.projectile_clip_for_aura(get_aura_level())
		_current_move["visual_move_id"] = tier_clip
		_current_move["projectile_tier"] = tier_clip
	elif mid0 == "aura_burst":
		# Normal-match signature access: aura burst plays signature_lane_burst.
		_current_move["visual_move_id"] = "signature_lane_burst"
	_AuraSpecialRuntime.begin_move_armor(self, _current_move)
	record_move_use(str(_current_move.get("move_id", "")))
	if bool(_current_move.get("dash_cancel_enabled", false)):
		stamp_runtime_hook("dash_cancel")
	if int(_current_move.get("phase_cancel_frames", 0)) > 0:
		stamp_runtime_hook("phase_cancel")
	if _AuraIdentity.charge_rate_mult(fighter_id, str(data.get("combatTag", ""))) != 1.0:
		stamp_runtime_hook("charge_rate")
	var scaled_boxes: Array = _current_move.get("hitboxes", [])
	var base_boxes: Array = m.get("hitboxes", [])
	if not scaled_boxes.is_empty() and not base_boxes.is_empty():
		if int(scaled_boxes[0].get("width", 40)) > int(base_boxes[0].get("width", 40)):
			stamp_runtime_hook("hitbox_extend")
	move_runner.start_move(_current_move, self)
	var mid = str(m.get("move_id", ""))
	var mt = str(m.get("move_type", "melee"))
	if mid == "grab" or mt == "grab":
		state_machine.enter(_FighterStates.GRAB_STARTUP)
	elif mt == "throw" or mid.begins_with("throw_"):
		state_machine.enter(_FighterStates.THROW_STARTUP)
	elif mid == "aura_burst" or mt == "burst":
		aura = 0.0
		_set_aura_vfx(false)
		state_machine.enter(_FighterStates.AURA_BURST_STARTUP)
	elif mt == "projectile" or str(m.get("input_command", "")).begins_with("special"):
		state_machine.enter(_FighterStates.SPECIAL_STARTUP)
	else:
		state_machine.enter(_FighterStates.ATTACK_STARTUP)

func _start_dodge() -> void:
	if _dodge_cooldown > 0.0:
		return
	var axis_x: float = _read_axis()
	var axis_y: float = 0.0
	if _read_up():
		axis_y = -1.0
	elif _read_down():
		axis_y = 1.0
	var dir_x: float = axis_x if absf(axis_x) > 0.25 else float(facing)
	if not is_on_floor():
		if _air_dodge_used:
			return
		_air_dodge_used = true
		_dodge_cooldown = 0.35
		state_machine.dodge_recovery = _CombatMath.AIR_DODGE_RECOVERY
		state_machine.dodge_invuln = _CombatMath.AIR_DODGE_INVULN
		state_machine.enter(_FighterStates.AIR_DODGE)
		velocity.x = dir_x * get_dash_speed() * 0.95
		velocity.y = axis_y * get_dash_speed() * (0.75 if axis_y < 0.0 else 0.45)
		invincible = _CombatMath.AIR_DODGE_INVULN > 0.0
		return
	_dodge_cooldown = 0.28
	state_machine.dodge_recovery = _CombatMath.GROUND_DODGE_RECOVERY
	state_machine.dodge_invuln = _CombatMath.GROUND_DODGE_INVULN
	state_machine.enter(_FighterStates.DODGE_START)
	state_machine.enter(_FighterStates.DODGE_ACTIVE)
	invincible = _CombatMath.GROUND_DODGE_INVULN > 0.0
	facing = 1 if dir_x >= 0.0 else -1
	velocity.x = dir_x * get_dash_speed() * 1.15
	velocity.y = 0.0
	state_machine.enter(_FighterStates.DODGE_RECOVERY)

func complete_jump_squat() -> void:
	var short_hop := _jump_short_hop or not _read_jump_held()
	var strength := get_jump_strength()
	velocity.y = -_CombatMath.short_hop_velocity(strength) if short_hop else -strength
	_jump_short_hop = false
	state_machine.enter(_FighterStates.JUMP)

func apply_hitstun_di(_delta: float) -> void:
	var sx := _read_axis()
	var sy := 0.0
	if _read_up():
		sy = -1.0
	elif _read_down():
		sy = 1.0
	velocity = _CombatMath.apply_di(velocity, sx, sy, _di_strength)

func begin_landing(from_aerial: bool, from_fast_fall: bool = false) -> void:
	var override := -1.0
	if _current_move.has("landing_lag"):
		override = float(_current_move.get("landing_lag"))
	elif _pending_landing_from_attack:
		override = _CombatMath.LANDING_LAG_AERIAL
	state_machine.landing_lag = _CombatMath.landing_lag_seconds(from_aerial, from_fast_fall, override)
	_pending_landing_from_attack = false
	state_machine.enter(_FighterStates.LAND)

func _track_landing() -> void:
	var airborne := not is_on_floor()
	if _was_airborne and not airborne:
		var from_attack := _FighterStates.is_attack_state(state_machine.previous_state) or _pending_landing_from_attack
		var from_hurt: bool = state_machine.current_state in [_FighterStates.LAUNCHED, _FighterStates.TUMBLE, _FighterStates.HITSTUN, _FighterStates.FALL, _FighterStates.FAST_FALL, _FighterStates.AIR_DODGE]
		if from_hurt or from_attack or state_machine.current_state in [_FighterStates.FALL, _FighterStates.FAST_FALL, _FighterStates.JUMP, _FighterStates.DOUBLE_JUMP]:
			begin_landing(true, _fast_falling)
	_was_airborne = airborne

func _check_ledge_grab() -> void:
	if is_on_floor() or invincible:
		return
	if state_machine.current_state in [_FighterStates.LEDGE_HANG, _FighterStates.LEDGE_GETUP, _FighterStates.KO, _FighterStates.RESPAWN]:
		return
	if velocity.y < -40.0:
		return
	var edge_l := platform_center_x - platform_half_width
	var edge_r := platform_center_x + platform_half_width
	var near_l := absf(global_position.x - edge_l) < 36.0 and global_position.y > 40.0 and global_position.y < 120.0
	var near_r := absf(global_position.x - edge_r) < 36.0 and global_position.y > 40.0 and global_position.y < 120.0
	if near_l or near_r:
		_ledge_side = -1 if near_l else 1
		global_position = Vector2(edge_l if near_l else edge_r, 56.0)
		velocity = Vector2.ZERO
		facing = -_ledge_side
		state_machine.enter(_FighterStates.LEDGE_HANG)

func tick_ledge_hang(_delta: float) -> void:
	velocity = Vector2.ZERO
	if _read_jump_pressed() or _read_up():
		velocity.y = -get_jump_strength() * 0.85
		invincible = false
		state_machine.enter(_FighterStates.JUMP)
		return
	if _read_attack_pressed() or _read_dodge_pressed() or (_ledge_side < 0 and _read_axis() > 0.4) or (_ledge_side > 0 and _read_axis() < -0.4):
		global_position.x += float(-_ledge_side) * 28.0
		global_position.y -= 24.0
		state_machine.enter(_FighterStates.LEDGE_GETUP)
		return
	if _read_down() or state_machine.state_time > 2.5:
		invincible = false
		state_machine.enter(_FighterStates.FALL)

func _on_move_active(move: Dictionary) -> void:
	var mid = str(move.get("move_id", ""))
	var mt = str(move.get("move_type", "melee"))
	if mid == "grab" or mt == "grab":
		state_machine.enter(_FighterStates.GRAB_ACTIVE)
		_try_grab_connect()
		return
	if mt == "throw" or mid.begins_with("throw_"):
		state_machine.enter(_FighterStates.THROW_RELEASE)
	if mt == "projectile" or move.has("projectile"):
		projectile_spawner.spawn_from_move(_current_move, aura)
		state_machine.enter(_FighterStates.SPECIAL_ACTIVE)
		return
	var sm: Dictionary = move.get("self_movement", {})
	if sm is Dictionary and (sm.get("x", 0) != 0 or sm.get("y", 0) != 0):
		velocity += Vector2(float(sm.get("x", 0)) * facing, float(sm.get("y", 0)))
	hitbox.monitoring = true
	_update_hitbox_from_move(move)
	_poll_hitbox_overlaps()
	call_deferred("_poll_hitbox_overlaps")
	if mt == "burst" or mid == "aura_burst":
		state_machine.enter(_FighterStates.AURA_BURST_ACTIVE)
	elif str(move.get("input_command", "")).begins_with("special") or mt in ["field", "trap", "movement"]:
		state_machine.enter(_FighterStates.SPECIAL_ACTIVE)
	else:
		state_machine.enter(_FighterStates.ATTACK_ACTIVE)


func _poll_hitbox_overlaps() -> void:
	## Active-frame overlap poll: Area2D.area_entered can miss if the hurtbox
	## was already overlapping when monitoring flipped on.
	if hitbox == null or not hitbox.monitoring:
		return
	if move_runner == null or not move_runner.is_active_phase():
		return
	var move: Dictionary = _current_move
	if move.is_empty():
		move = _DataLoader.find_move(move_manifest, move_runner.current_move_id())
	if move.is_empty() or str(move.get("move_id", "")) == "grab":
		return
	for area in hitbox.get_overlapping_areas():
		if area == null or area == hurtbox:
			continue
		if str(area.name) != "Hurtbox":
			continue
		var defender: Node = area.get_parent()
		if defender == null or defender == self:
			continue
		if not defender.has_method("receive_hit"):
			continue
		hit_resolver.resolve(self, defender, move, damage_percent)


func _try_grab_connect() -> void:
	var opp = _find_opponent()
	if opp == null or not opp != null and opp.has_method("configure"):
		state_machine.enter(_FighterStates.GRAB_WHIFF)
		grab_event.emit({"result": "whiff"})
		return
	if opp.invincible or opp.grabbed_by != null:
		state_machine.enter(_FighterStates.GRAB_WHIFF)
		grab_event.emit({"result": "whiff", "reason": "invuln"})
		return
	var dist = absf(opp.global_position.x - global_position.x)
	if dist > _CombatMath.GRAB_RANGE_PX:
		state_machine.enter(_FighterStates.GRAB_WHIFF)
		grab_event.emit({"result": "whiff", "reason": "range"})
		return
	grabbed_target = opp
	opp.grabbed_by = self
	opp.grab_mash = 0.0
	grab_mash = 0.0
	_grab_throw_latch = false
	_throw_direction = ""
	_input_edge_held["attack"] = false
	_input_edge_held["grab"] = false
	state_machine.enter(_FighterStates.GRAB_HOLD)
	opp.state_machine.enter(_FighterStates.GRAB_HOLD)
	grab_event.emit({"result": "success", "target": opp.fighter_id})

func execute_throw() -> void:
	if grabbed_target == null:
		return
	var target = grabbed_target
	grabbed_target = null
	target.grabbed_by = null
	var direction: String = _ThrowResolver.read_throw_direction(self)
	_throw_direction = direction
	state_machine.enter(_FighterStates.THROW_STARTUP)
	var throw_move: Dictionary = _ThrowResolver.resolve_throw(self, target, move_manifest, direction)
	_ThrowResolver.apply_victim_offset(self, target, throw_move)
	_start_move_dict(throw_move)
	target.state_machine.enter(_FighterStates.HITSTUN)
	hit_resolver.resolve(self, target, throw_move, damage_percent)
	grab_event.emit({"result": "throw", "target": target.fighter_id, "direction": direction})
	if combat_feedback != null and combat_feedback.has_method("spawn_grab_recovery_flash"):
		combat_feedback.spawn_grab_recovery_flash(self, global_position + Vector2(0, -24), direction)

func _update_hitbox_from_move(move: Dictionary) -> void:
	var boxes: Array = move.get("hitboxes", [])
	if boxes.is_empty():
		return
	var hb: Dictionary = boxes[0]
	var w: float = float(hb.get("width", 40))
	var h: float = float(hb.get("height", 32))
	hitbox.position = Vector2(float(hb.get("offset_x", 36)) * float(facing), float(hb.get("offset_y", -8)))
	var cs := hitbox.get_node_or_null("HitShape") as CollisionShape2D
	if cs:
		cs.position = Vector2.ZERO
		var rect := cs.shape as RectangleShape2D
		if rect == null:
			rect = RectangleShape2D.new()
			cs.shape = rect
		rect.size = Vector2(w, h)
	if hitbox_debug:
		hitbox_debug.size = Vector2(w, h)
		hitbox_debug.position = hitbox.position - hitbox_debug.size / 2.0

func set_armor_frames(seconds: float) -> void:
	armor_frames_remaining = maxf(armor_frames_remaining, seconds)


func enable_dash_cancel(seconds: float) -> void:
	dash_cancel_remaining = maxf(dash_cancel_remaining, seconds)
	stamp_runtime_hook("dash_cancel")


func enable_phase_cancel(seconds: float) -> void:
	phase_cancel_remaining = maxf(phase_cancel_remaining, seconds)
	# Brief phase invuln on Vesper cancel window.
	invincible = true
	stamp_runtime_hook("phase_cancel")
	stamp_runtime_hook("phase_invuln")
	get_tree().create_timer(minf(seconds, 0.12)).timeout.connect(func():
		if phase_cancel_remaining <= 0.0:
			invincible = false
	, CONNECT_ONE_SHOT)


func tick_aura_charge(delta: float) -> void:
	var charge_mult: float = _AuraIdentity.charge_rate_mult(fighter_id, str(data.get("combatTag", "")))
	var before := aura
	aura = _AuraScaler.apply_charge_tick(aura, delta, true, charge_mult)
	stamp_runtime_hook("charge_rate")
	if aura > before:
		_set_aura_vfx(true)


func _tick_idle_aura_decay(delta: float) -> void:
	if is_aura_input_held():
		return
	if state_machine != null and str(state_machine.current_state).begins_with("aura_burst"):
		return
	if aura <= 0.0:
		return
	aura = _AuraScaler.apply_charge_tick(aura, delta, false, 1.0)


func _tick_shield_regen(delta: float) -> void:
	if shielding or state_machine == null:
		return
	if state_machine.current_state in [_FighterStates.SHIELD_HOLD, _FighterStates.SHIELD_START, _FighterStates.SHIELD_BREAK, _FighterStates.SHIELD_STUN]:
		return
	var mx: float = float(data.get("shieldProfile", {}).get("maxHealth", 100))
	if shield_health >= mx:
		return
	shield_health = minf(mx, shield_health + _CombatMath.SHIELD_REGEN_PER_SECOND * delta)


func tick_grab_hold(_delta: float) -> void:
	if grabbed_target == null:
		state_machine.enter(_FighterStates.IDLE)
		return
	_throw_direction = _ThrowResolver.read_throw_direction(self)
	var attack_action := "p%d_attack" % slot
	var attack_now := Input.is_action_pressed(attack_action)
	if not attack_now:
		_input_edge_held["attack"] = false
		_grab_throw_latch = false
	elif attack_now and not _grab_throw_latch:
		_grab_throw_latch = true
		_input_edge_held["attack"] = true
		execute_throw()
		return
	if grabbed_target.has_method("tick_grab_mash"):
		grabbed_target.tick_grab_mash(_delta)
	if float(grabbed_target.grab_mash) >= _CombatMath.GRAB_MASH_ESCAPE:
		_break_grab_mash()
		return
	if state_machine.state_time > 2.0:
		execute_throw()


func tick_grab_mash(_delta: float) -> void:
	if grabbed_by == null:
		return
	if _read_attack_pressed() or _read_jump_pressed() or _read_grab_pressed():
		grab_mash = minf(_CombatMath.GRAB_MASH_ESCAPE, grab_mash + _CombatMath.GRAB_MASH_PER_PRESS)


func _break_grab_mash() -> void:
	var attacker = grabbed_by
	grabbed_by = null
	grab_mash = 0.0
	if attacker != null:
		attacker.grabbed_target = null
		if attacker.state_machine:
			attacker.state_machine.enter(_FighterStates.GRAB_WHIFF)
	state_machine.enter(_FighterStates.IDLE)
	velocity.x = -float(facing) * 180.0
	grab_event.emit({"result": "mash_escape"})


func try_tech() -> bool:
	if not is_on_floor():
		return false
	if not _read_dodge_pressed() and not _read_shield():
		return false
	invincible = true
	velocity = Vector2.ZERO
	state_machine.landing_lag = 0.04
	state_machine.enter(_FighterStates.LAND)
	get_tree().create_timer(_CombatMath.TECH_WINDOW_SEC).timeout.connect(func():
		invincible = false
	, CONNECT_ONE_SHOT)
	stamp_runtime_hook("tech")
	return true


func record_move_use(move_id: String) -> int:
	_recent_move_ids.append(move_id)
	if _recent_move_ids.size() > 8:
		_recent_move_ids.pop_front()
	var repeats := 0
	for mid in _recent_move_ids:
		if str(mid) == move_id:
			repeats += 1
	return maxi(0, repeats - 1)


func stale_repeat_count(move_id: String) -> int:
	var repeats := 0
	for mid in _recent_move_ids:
		if str(mid) == move_id:
			repeats += 1
	return maxi(0, repeats - 1)


func stamp_runtime_hook(hook: String) -> void:
	_runtime_hooks_seen[hook] = true


func runtime_hooks_seen() -> Array:
	return _runtime_hooks_seen.keys()


func _try_identity_cancel() -> bool:
	if not _FighterStates.is_attack_state(state_machine.current_state):
		return false
	if phase_cancel_remaining > 0.0 and (_read_dodge_pressed() or _read_special_pressed()):
		move_runner.cancel()
		hitbox.monitoring = false
		phase_cancel_remaining = 0.0
		stamp_runtime_hook("phase_cancel")
		if _read_dodge_pressed():
			_start_dodge()
		else:
			state_machine.enter(_FighterStates.IDLE)
			_start_move_by_command(_resolve_special_command())
		return true
	if dash_cancel_remaining > 0.0 and absf(_read_axis()) > 0.75 and is_on_floor():
		move_runner.cancel()
		hitbox.monitoring = false
		dash_cancel_remaining = 0.0
		stamp_runtime_hook("dash_cancel")
		state_machine.enter(_FighterStates.DASH)
		velocity.x = _read_axis() * get_dash_speed()
		return true
	return false


func receive_hit(attacker: Node, info: Dictionary) -> void:
	if invincible or grabbed_by != null:
		return
	if str(info.get("move_id", "")) == "grab":
		return
	_last_hit_result = info.duplicate(true)
	_last_knockback = info.get("launch", Vector2.ZERO)
	_last_shield_damage = float(info.get("shield_damage", 0.0))
	_last_element_effect = str(info.get("element", info.get("element_effect", "")))
	if info.get("armor_block", false):
		stamp_runtime_hook("passive_armor")
		hit_landed.emit(info)
		return
	if state_machine.current_state == _FighterStates.SHIELD_HOLD or shielding:
		var sdmg: float = info.get("shield_damage", info.get("damage", 0.0) * 0.8)
		shield_health -= sdmg
		info["blocked"] = true
		hit_landed.emit(info)
		if shield_health <= 0.0:
			shielding = false
			state_machine.enter(_FighterStates.SHIELD_BREAK)
			shield_health = 0.0
		else:
			state_machine.enter(_FighterStates.SHIELD_STUN)
		return
	var dmg: float = info.get("damage", 0.0)
	if state_machine.current_state == _FighterStates.AURA_CHARGE:
		aura = maxf(0.0, aura - _CombatMath.AURA_HIT_INTERRUPT_LOSS)
		_set_aura_vfx(false)
	damage_percent += dmg
	damaged.emit(dmg, damage_percent)
	var launch: Vector2 = info.get("launch", Vector2.ZERO)
	_di_strength = _CombatMath.di_strength_for_kb(launch.length(), dmg)
	# Initial DI snapshot at hit confirm.
	var sx := _read_axis()
	var sy := -1.0 if _read_up() else (1.0 if _read_down() else 0.0)
	launch = _CombatMath.apply_di(launch, sx, sy, _di_strength)
	velocity = launch
	_last_knockback = launch
	hitstun_remaining = _CombatMath.hitstun_seconds(launch.length())
	_hitstop = _CombatMath.frames_to_seconds(info.get("hitstop_frames", 3))
	if attacker != null and attacker.has_method("configure"):
		attacker._hitstop = _hitstop * 0.5
		attacker.combo_count += 1
		if "aura" in attacker and "fighter_id" in attacker:
			var gain: float = _AuraIdentity.on_hit_aura_gain(
				str(attacker.fighter_id),
				str(attacker.data.get("combatTag", "")) if "data" in attacker else ""
			)
			attacker.aura = minf(100.0, float(attacker.aura) + gain)
	var heavy = dmg >= 8.0 or launch.length() > 14.0
	if launch.length() > 14.0:
		state_machine.enter(_FighterStates.LAUNCHED)
	elif heavy:
		state_machine.enter(_FighterStates.HURT_HEAVY)
	else:
		state_machine.enter(_FighterStates.HURT_LIGHT)
	hit_landed.emit(info)
	# Hit telemetry is recorded by HitResolver.resolve (single source of truth).

func reset_fighter() -> void:
	damage_percent = 0.0
	aura = 0.0
	combo_count = 0
	grabbed_target = null
	grabbed_by = null
	shield_health = float(data.get("shieldProfile", {}).get("maxHealth", 100))
	velocity = Vector2.ZERO
	global_position = spawn_point
	invincible = true
	state_machine.enter(_FighterStates.RESPAWN)
	ensure_visible_presentation()
	get_tree().create_timer(1.2).timeout.connect(func():
		invincible = false
		state_machine.enter(_FighterStates.IDLE)
		ensure_visible_presentation()
		respawned.emit()
	, CONNECT_ONE_SHOT)

func lose_stock() -> void:
	stocks -= 1
	state_machine.enter(_FighterStates.KO)
	ensure_visible_presentation()
	koed.emit()
	var telem = get_node_or_null("/root/MatchTelemetry")
	if telem:
		if telem.has_method("record_ko"):
			telem.record_ko(fighter_id, stocks)
		if telem.has_method("record_stock_loss"):
			telem.record_stock_loss(fighter_id, stocks)
	if stocks > 0:
		reset_fighter()

func reset_damage() -> void:
	damage_percent = 0.0
	combo_count = 0

func reset_position() -> void:
	global_position = spawn_point
	velocity = Vector2.ZERO
	grabbed_target = null
	grabbed_by = null

func fill_aura() -> void:
	aura = 100.0
	state_machine.enter(_FighterStates.AURA_READY)

func clear_aura() -> void:
	aura = 0.0
	_set_aura_vfx(false)
	if state_machine.current_state in [_FighterStates.AURA_CHARGE, _FighterStates.AURA_READY]:
		state_machine.enter(_FighterStates.IDLE)

func set_debug_hitboxes(v: bool) -> void:
	if hitbox_debug:
		hitbox_debug.visible = v

func set_debug_hurtboxes(v: bool) -> void:
	if hurtbox_debug:
		hurtbox_debug.visible = v

func set_debug_visible(v: bool) -> void:
	set_debug_hitboxes(v)
	set_debug_hurtboxes(v)

func set_debug_projectiles(v: bool) -> void:
	_show_projectile_boxes = v
	projectile_spawner.set_debug_visible(v)

func set_debug_grab_range(v: bool) -> void:
	_show_grab_range = v
	if grab_range_debug:
		grab_range_debug.visible = v and state_machine.current_state == _FighterStates.GRAB_HOLD

func debug_combat_summary() -> Dictionary:
	return {
		"aura_level": get_aura_level(),
		"projectile_count": projectile_spawner.count(),
		"throw_direction": _throw_direction,
		"last_hit_result": _last_hit_result.get("move_id", "—"),
		"hitstop_frames": int(_hitstop / _CombatMath.frames_to_seconds(1)) if _hitstop > 0 else 0,
		"knockback_vector": _last_knockback,
		"shield_damage": _last_shield_damage,
		"element_effect": _last_element_effect,
		"combo_count": combo_count,
		"cancel_window": move_runner.in_cancel_window if move_runner else false,
		"stale_window": _recent_move_ids.duplicate(),
		"impact_readable": last_impact_readable,
		"feedback_tier": last_feedback_tier,
		"grab_mash": grab_mash,
	}

func _on_move_ended(_move_id: String) -> void:
	hitbox.monitoring = false
	var s: String = str(state_machine.current_state) if state_machine else ""
	if s == _FighterStates.GRAB_HOLD:
		return
	if not is_on_floor() and s in [_FighterStates.ATTACK_ACTIVE, _FighterStates.ATTACK_STARTUP, _FighterStates.SPECIAL_ACTIVE, _FighterStates.SPECIAL_STARTUP]:
		_pending_landing_from_attack = true
	if s in [_FighterStates.GRAB_ACTIVE, _FighterStates.GRAB_STARTUP] and grabbed_target == null:
		state_machine.enter(_FighterStates.GRAB_WHIFF)
	elif s in [_FighterStates.ATTACK_ACTIVE, _FighterStates.ATTACK_STARTUP]:
		state_machine.enter(_FighterStates.ATTACK_RECOVERY)
	elif s in [_FighterStates.SPECIAL_ACTIVE, _FighterStates.SPECIAL_STARTUP]:
		state_machine.enter(_FighterStates.SPECIAL_RECOVERY)
	elif s in [_FighterStates.AURA_BURST_ACTIVE, _FighterStates.AURA_BURST_STARTUP]:
		state_machine.enter(_FighterStates.AURA_BURST_RECOVERY)
	elif s in [_FighterStates.THROW_RELEASE, _FighterStates.THROW_STARTUP]:
		state_machine.enter(_FighterStates.IDLE)
	else:
		state_machine.enter(_FighterStates.IDLE)

func _on_phase_changed(phase: String) -> void:
	match phase:
		"startup":
			pass
		"active":
			pass
		"recovery":
			if state_machine.current_state == _FighterStates.ATTACK_ACTIVE:
				state_machine.enter(_FighterStates.ATTACK_RECOVERY)
			elif state_machine.current_state == _FighterStates.SPECIAL_ACTIVE:
				state_machine.enter(_FighterStates.SPECIAL_RECOVERY)

func _sync_attack_phase_state() -> void:
	if not move_runner.active:
		return
	match move_runner.phase:
		"startup":
			if state_machine.current_state in [_FighterStates.ATTACK_STARTUP, _FighterStates.SPECIAL_STARTUP, _FighterStates.AURA_BURST_STARTUP, _FighterStates.GRAB_STARTUP, _FighterStates.THROW_STARTUP]:
				pass
		"active":
			pass
		"recovery":
			if state_machine.current_state in [_FighterStates.ATTACK_ACTIVE, _FighterStates.SPECIAL_ACTIVE, _FighterStates.AURA_BURST_ACTIVE]:
				pass

func _sync_motion_state() -> void:
	if not is_on_floor() and state_machine.current_state not in [
		_FighterStates.JUMP, _FighterStates.DOUBLE_JUMP, _FighterStates.ATTACK_STARTUP,
		_FighterStates.SPECIAL_STARTUP, _FighterStates.AURA_BURST_STARTUP, _FighterStates.LAUNCHED,
	]:
		if velocity.y > 0:
			state_machine.enter(_FighterStates.FALL if velocity.y < get_fall_speed() * 0.02 else _FighterStates.FAST_FALL)

func _check_edge() -> void:
	if not is_on_floor():
		return
	var edge_dist = platform_half_width - absf(global_position.x - platform_center_x)
	if edge_dist < EDGE_MARGIN and absf(velocity.x) > 20.0:
		if signf(velocity.x) == signf(global_position.x - platform_center_x):
			state_machine.enter(_FighterStates.EDGE_WARNING)
	elif state_machine.current_state in [_FighterStates.EDGE_WARNING, _FighterStates.LEDGE_TEETER]:
		state_machine.enter(_FighterStates.IDLE if absf(_read_axis()) < 0.1 else _FighterStates.WALK)

func _set_aura_vfx(on: bool) -> void:
	if aura_vfx:
		aura_vfx.visible = on
		if on and data.has("auraColor"):
			var c := Color(data.get("auraColor"))
			c.a = clampf(0.2 + aura / 200.0, 0.2, 0.55)
			aura_vfx.color = c
	if model_3d and model_3d.has_method("set_aura_level"):
		model_3d.set_aura_level(get_aura_level() if on or aura > 1.0 else 0)
	if on and not _aura_sfx_hook:
		_aura_sfx_hook = true


func _on_state_changed(_from: String, to: String) -> void:
	_play_current_animation(to)
	if to in [_FighterStates.AURA_CHARGE, _FighterStates.AURA_READY, _FighterStates.AURA_BURST_STARTUP, _FighterStates.AURA_BURST_ACTIVE]:
		_set_aura_vfx(true)
	elif to in [_FighterStates.IDLE, _FighterStates.WALK, _FighterStates.RUN] and aura < 25.0:
		_set_aura_vfx(false)
	state_changed.emit(to)


func _play_current_animation(state: String) -> void:
	if not animator:
		return
	ensure_visible_presentation()
	if model_3d and model_3d.is_model_loaded():
		var move_copy: Dictionary = _current_move.duplicate()
		move_copy["throw_direction"] = _throw_direction
		# Prefer visual_move_id (projectile tier / signature bind) when set.
		if move_copy.has("visual_move_id") and str(move_copy.get("visual_move_id", "")) != "":
			move_copy["move_id"] = str(move_copy.get("visual_move_id"))
		model_3d.play_for_state(state, move_copy)
		if model_3d.has_method("set_aura_level"):
			model_3d.set_aura_level(get_aura_level())
	else:
		animator.play_for_state(state)

func _setup_shapes() -> void:
	for path in ["CollisionShape2D", "Hurtbox/HurtShape", "Hitbox/HitShape"]:
		var cs = get_node_or_null(path) as CollisionShape2D
		if cs and cs.shape == null:
			var rect = RectangleShape2D.new()
			rect.size = Vector2(40, 48) if "Hit" not in path else Vector2(36, 40)
			cs.shape = rect

func _read_axis() -> float:
	var touch = TouchInputManager.get_axis(slot)
	# Prefer live touch stick when the overlay/harness is active — TIM also
	# mirrors axis into Input actions, and a digital full-press would otherwise
	# outrank an analog tilt and collapse forward_tilt into dash_attack.
	if TouchInputManager.should_show_touch() and slot == 1 and absf(touch) > 0.01:
		return touch
	var kb = Input.get_action_strength("p%d_right" % slot) - Input.get_action_strength("p%d_left" % slot)
	if absf(touch) > absf(kb):
		return touch
	return kb

func _read_jump_pressed() -> bool:
	if TouchInputManager.consume_touch_just_pressed(slot, "jump"):
		return true
	if Input.is_action_just_pressed("p%d_jump" % slot):
		_input_edge_held["jump"] = true
		return true
	return _input_edge("jump")

func _read_jump_held() -> bool:
	if TouchInputManager.is_touch_pressed(slot, "jump"):
		return true
	return Input.is_action_pressed("p%d_jump" % slot)

func _input_edge(suffix: String) -> bool:
	# Rising edge on Input.is_action_pressed. Input.action_press() from scripts /
	# CPU / touch mirrors only guarantees is_action_just_pressed for the issuing
	# frame; if that frame's idle callback runs after CharacterBody physics,
	# attacks/grabs silently drop. Edge-on-pressed matches real digital-button
	# semantics and keeps synthetic presses reliable.
	var action := "p%d_%s" % [slot, suffix]
	var held := Input.is_action_pressed(action)
	var was := bool(_input_edge_held.get(suffix, false))
	_input_edge_held[suffix] = held
	return held and not was


func _read_attack_pressed() -> bool:
	if TouchInputManager.consume_touch_just_pressed(slot, "attack"):
		return true
	if Input.is_action_just_pressed("p%d_attack" % slot):
		_input_edge_held["attack"] = true
		return true
	return _input_edge("attack")

func _read_special_pressed() -> bool:
	if TouchInputManager.consume_touch_just_pressed(slot, "special"):
		return true
	if Input.is_action_just_pressed("p%d_special" % slot):
		_input_edge_held["special"] = true
		return true
	return _input_edge("special")

func _read_shield() -> bool:
	if TouchInputManager.is_touch_pressed(slot, "shield"):
		return true
	return Input.is_action_pressed("p%d_shield" % slot)

func _read_dodge_pressed() -> bool:
	if TouchInputManager.consume_touch_just_pressed(slot, "dodge"):
		return true
	if Input.is_action_just_pressed("p%d_dodge" % slot):
		_input_edge_held["dodge"] = true
		return true
	return _input_edge("dodge")

func _read_grab_pressed() -> bool:
	if TouchInputManager.consume_touch_just_pressed(slot, "grab"):
		return true
	if Input.is_action_just_pressed("p%d_grab" % slot):
		_input_edge_held["grab"] = true
		return true
	return _input_edge("grab")

func _read_up() -> bool:
	if TouchInputManager.get_vertical(slot) < -0.22:
		return true
	return Input.is_action_pressed("p%d_up" % slot)

func _read_down() -> bool:
	if TouchInputManager.get_vertical(slot) > 0.22:
		return true
	return Input.is_action_pressed("p%d_down" % slot)

func _read_aura_burst() -> bool:
	return Input.is_action_just_pressed("p%d_attack" % slot) and aura >= 100.0

func _release_action(action: String) -> void:
	Input.action_release(action)

func _dummy_apply_di() -> void:
	match dummy_mode:
		"di_in":
			var inward := -1.0 if global_position.x > platform_center_x else 1.0
			velocity = _CombatMath.apply_di(velocity, inward, -0.35, _di_strength)
		"di_out":
			var outward := 1.0 if global_position.x > platform_center_x else -1.0
			velocity = _CombatMath.apply_di(velocity, outward, 0.2, _di_strength)

func _dummy_tick(delta: float) -> void:
	var target = _find_opponent()
	if target == null:
		return
	var dx: float = float(target.global_position.x) - global_position.x
	match dummy_mode:
		"shield":
			if not Input.is_action_pressed("p%d_shield" % slot):
				Input.action_press("p%d_shield" % slot)
		"jump":
			if is_on_floor() and randf() < 0.02:
				_jump_short_hop = false
				state_machine.enter(_FighterStates.JUMP_SQUAT)
		"attack":
			if absf(dx) < 90 and randf() < 0.03:
				_start_move_by_command("attack_neutral")
		"di_in", "di_out":
			# Prefer shield between hits; DI applied in hurt path via _dummy_apply_di.
			if state_machine.current_state in [_FighterStates.IDLE, _FighterStates.WALK, _FighterStates.RUN]:
				if not Input.is_action_pressed("p%d_shield" % slot) and randf() < 0.02:
					Input.action_press("p%d_shield" % slot)
		"idle":
			pass

func _find_opponent() -> Node2D:
	var parent = get_parent()
	if parent == null:
		return null
	for c in parent.get_children():
		if c != self and c != null and c.has_method("configure"):
			return c
	return null

func input_display() -> String:
	var parts: PackedStringArray = []
	if absf(_read_axis()) > 0.1:
		parts.append("←→" if _read_axis() < 0 else "→")
	if _read_jump_held():
		parts.append("J")
	if _read_attack_pressed():
		parts.append("A")
	if _read_shield():
		parts.append("S")
	if _read_grab_pressed():
		parts.append("G")
	return " ".join(parts) if parts.size() else "—"
