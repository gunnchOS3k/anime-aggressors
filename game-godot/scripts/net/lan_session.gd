extends Node
## Real direct-LAN ENet input bridge. Host BattleScene is the ONLY simulation.
## Guest BattleScene is a read-only presentation replica with no local damage.
## No claim of authenticated Internet service or combat rollback/resimulation.
const Controls = preload("res://scripts/net/lan_controls.gd")
const VERSION := 1
const MAX_PACKET := 32768
const INPUT_TIMEOUT_MS := 1000
signal changed
var peer: ENetMultiplayerPeer
var role := ""
var status := "Offline"
var guest_id := 0
var epoch := 0
var remote = Controls.new()
var latest: Dictionary = {}
var received_inputs := 0
var rejected_inputs := 0
var last_sequence := -1
var _sequence := 0
var _last_input_ms := 0
var _battle: WeakRef
var _ticks := 0
var combat_frames := 0
var _snapshot_seq := 0
var _last_snapshot := -1
var _closed := true
var _bound_once := false
var _guest_deadline := 0
var guest_battle_open := false
var _contact_events: Array = []
var _starting := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_physics_priority = -1000
	for key in Controls.BUTTONS:
		if not InputMap.has_action("p1_" + key): InputMap.add_action("p1_" + key)

func host(port: int = 27834, address: String = "*") -> Error:
	stop()
	peer = ENetMultiplayerPeer.new()
	peer.set_bind_ip(address)
	var error := peer.create_server(port, 1, 1)
	if error != OK: peer = null; return error
	role = "host"
	peer.peer_connected.connect(_peer_joined)
	peer.peer_disconnected.connect(_peer_left)
	status = "Listening on UDP %d; waiting for one LAN guest" % port
	return OK

func join(address: String, port: int = 27834) -> Error:
	stop()
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port, 1)
	if error != OK: peer = null; return error
	role = "guest"
	status = "Connecting to %s:%d" % [address, port]
	_guest_deadline = Time.get_ticks_msec() + 10000
	return OK

func stop() -> void:
	remote.clear()
	if peer != null: peer.close()
	peer = null
	role = ""
	guest_id = 0
	_battle = null
	_closed = true
	_bound_once = false
	combat_frames = 0
	latest.clear()
	_contact_events.clear()
	guest_battle_open = false
	_starting = false
	last_sequence = -1
	_last_snapshot = -1
	status = "Offline"

func _peer_joined(id: int) -> void:
	if role != "host" or guest_id != 0 or _bound_once: return
	guest_id = id
	status = "Guest connected; host can start the selected versus match"
	_send(guest_id, {"kind":"hello", "version":VERSION, "slot":2})

func _peer_left(id: int) -> void:
	if role == "host" and id == guest_id:
		guest_id = 0
		retire_battle("Guest disconnected; held inputs cleared (no result awarded)")

func _send(id: int, data: Dictionary) -> void:
	if id <= 0 or peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED: return
	peer.set_target_peer(id)
	peer.transfer_mode = MultiplayerPeer.TRANSFER_MODE_RELIABLE
	peer.transfer_channel = 0
	peer.put_packet(var_to_bytes(data)) # no object deserialization at receiver

func _physics_process(_delta: float) -> void:
	if peer == null: return
	remote.begin_frame()
	peer.poll()
	if role == "host":
		pass # Peer membership comes from actual ENet connect/disconnect signals.
	else:
		if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED or (latest.is_empty() and Time.get_ticks_msec() > _guest_deadline):
			status = "Host unavailable; reconnect from lobby"
			remote.clear()
			return
	var count := 0
	while peer.get_available_packet_count() > 0 and count < 120:
		var sender := peer.get_packet_peer()
		var bytes := peer.get_packet()
		count += 1
		if bytes.size() > (2048 if role == "host" else MAX_PACKET): rejected_inputs += 1; continue
		var message = bytes_to_var(bytes)
		if typeof(message) != TYPE_DICTIONARY: rejected_inputs += 1; continue
		_receive(sender, message)
	if role == "guest":
		if not latest.is_empty() and not bool(latest.get("closed", true)):
			_send(1, Controls.local_packet(epoch, _sequence))
			_sequence += 1
		return
	if _battle != null:
		var battle = _battle.get_ref()
		if not is_instance_valid(battle): retire_battle("Battle scene ended")
		elif not _closed and (battle._match_finished or battle.fighter2.combat_closed): retire_battle("Match complete; late inputs rejected")
		elif battle._paused or get_tree().paused: remote.clear()
		elif Time.get_ticks_msec() - _last_input_ms > INPUT_TIMEOUT_MS: remote.clear()
		if is_instance_valid(battle):
			_ticks += 1
			if battle._active and not _closed: combat_frames += 1
			if _ticks % 3 == 0: _publish(battle)

func _receive(sender: int, message: Dictionary) -> void:
	if role == "host":
		if sender != guest_id or _closed or not Controls.valid(message) or message.epoch != epoch or message.seq <= last_sequence:
			rejected_inputs += 1
			return
		var battle = _battle.get_ref() if _battle != null else null
		if not is_instance_valid(battle) or battle._match_finished or battle.fighter2.combat_closed or battle._paused or get_tree().paused:
			remote.clear()
			rejected_inputs += 1
			return
		last_sequence = message.seq
		_last_input_ms = Time.get_ticks_msec()
		remote.apply(message)
		received_inputs += 1
	elif sender == 1 and message.get("kind", "") == "hello" and message.get("version", -1) == VERSION:
		status = "Connected as guest slot 2. Host chooses match. P1 controls drive remote fighter."
	elif sender == 1 and message.get("kind", "") == "state" and int(message.get("sequence", -1)) > _last_snapshot:
		_last_snapshot = int(message.sequence)
		latest = message.duplicate(true)
		epoch = int(message.epoch)
		status = "Host BattleScene: %s — guest controls slot 2; authoritative host state mirrored; no prediction/rollback" % message.get("phase", "")
		if not guest_battle_open: _open_guest_battle()
		changed.emit()

func start_match() -> bool:
	if role != "host" or guest_id == 0 or _bound_once or _starting: return false
	_starting = true
	# Existing selected roster, bodies, stage and rules; no in-match changes.
	GameState.begin_online_queue("private")
	GameState.p1_is_cpu = false
	GameState.p2_is_cpu = false
	GameState.battle_eval_mode = false
	GameState.hazards_enabled = false
	GameState.items_enabled = false
	GameState.reset_match()
	SceneRouter.go("battle")
	return true

func bind_battle(battle: Node) -> void:
	if role != "host" or guest_id == 0 or _bound_once or GameState.mode != "online_private": return
	_bound_once = true
	_battle = weakref(battle)
	epoch += 1
	_closed = false
	last_sequence = -1
	_last_input_ms = Time.get_ticks_msec()
	remote.clear()
	battle.fighter2.remote_controls = remote
	battle.fighter2._input_edge_held.clear()
	for actor in [battle.fighter1, battle.fighter2]:
		actor.hit_resolver.hit_confirmed.connect(_record_contact)
	_publish(battle)

func retire_battle(reason: String) -> void:
	_closed = true
	remote.clear()
	status = reason
	if _battle != null:
		var battle = _battle.get_ref()
		if is_instance_valid(battle):
			# Keep the neutral remote source bound until actor teardown; local P2
			# keyboard/touch must not take ownership after a disconnect/result.
			battle.fighter2._input_edge_held.clear()
			_publish(battle)

func unbind_battle(battle: Node) -> void:
	if _battle != null and _battle.get_ref() == battle:
		retire_battle("Battle scene left; reconnect for another LAN match")
		_battle = null

func _record_contact(attacker, defender, info: Dictionary) -> void:
	var event: Dictionary = {"attacker_slot":attacker.slot, "defender_slot":defender.slot}
	for key in ["combat_event_id", "move_id", "confirmed_contact", "contact_world", "contact_direction", "contact_result", "feedback_tier", "attacker_id", "damage", "blocked", "perfect_guard", "sfx_event"]:
		if info.has(key): event[key] = info[key]
	_contact_events.append(event)
	if _contact_events.size() > 8: _contact_events.pop_front()

func _open_guest_battle() -> void:
	if not latest.has_all(["config", "actors"]) or latest.actors.size() != 2: return
	var cfg: Dictionary = latest.config
	GameState.begin_online_queue("private")
	GameState.p1_fighter_id = str(latest.actors[0].fighter)
	GameState.p2_fighter_id = str(latest.actors[1].fighter)
	GameState.p1_body_variant = str(latest.actors[0].body)
	GameState.p2_body_variant = str(latest.actors[1].body)
	GameState.p1_is_cpu = false
	GameState.p2_is_cpu = false
	GameState.battle_eval_mode = false
	GameState.stage_id = str(cfg.stage)
	GameState.stocks = int(cfg.stocks)
	GameState.match_timer_seconds = int(cfg.timer)
	GameState.match_type = str(cfg.match_type)
	GameState.ruleset_id = str(cfg.ruleset)
	GameState.match_seed = int(cfg.seed)
	guest_battle_open = true
	SceneRouter.go("battle")

func _publish(battle: Node) -> void:
	var actors: Array = []
	for actor in [battle.fighter1, battle.fighter2]:
		var shown_move: Dictionary = {}
		for key in ["move_id", "visual_move_id", "startup_frames", "active_frames", "recovery_frames"]:
			if actor._current_move.has(key): shown_move[key] = actor._current_move[key]
		actors.append({"move":shown_move, "move_active":actor.move_runner.active, "move_frame":actor.move_runner.total_frame,
			"state_frame":actor.state_machine.state_frame, "state_time":actor.state_machine.state_time,
			"velocity":actor.velocity, "grounded":actor.is_on_floor(), "shielding":actor.shielding, "hitstop":actor._hitstop,
			"throw_direction":actor._throw_direction, "grab_owner":actor.grabbed_by.slot if is_instance_valid(actor.grabbed_by) else 0,
			"grab_target":actor.grabbed_target.slot if is_instance_valid(actor.grabbed_target) else 0,
			"slot":actor.slot, "fighter":actor.fighter_id, "body":actor.model_3d.get_body_variant(),
			"position":[actor.position.x, actor.position.y], "state":actor.state_machine.current_state,
			"facing":actor.facing, "damage":actor.damage_percent, "stocks":actor.stocks,
			"aura":actor.aura, "aura_level":actor.get_aura_level(), "form":actor._current_form_id,
			"shield":actor.shield_health, "shield_max":float(actor.data.get("shieldProfile", {}).get("maxHealth", 100)),
			"perfect_guard":actor.perfect_guard.snapshot(), "CPU":actor.is_cpu})
	var shots: Array = []
	for actor in [battle.fighter1, battle.fighter2]:
		for shot in actor.projectile_spawner.active_projectiles:
			if is_instance_valid(shot) and shot.active:
				shots.append({"id":shot.order_id, "fighter":shot.fighter_id, "position":shot.global_position, "direction":shot.direction,
					"extent":shot._visual_extent, "integrity":shot.integrity, "initial_integrity":shot.initial_integrity})
	_snapshot_seq += 1
	latest = {"kind":"state", "sequence":_snapshot_seq, "epoch":epoch, "frame":Engine.get_physics_frames(),
		"combat_frame":combat_frames, "active":battle._active, "paused":battle._paused, "closed":_closed, "phase":"result" if battle._match_finished else ("combat" if battle._active else "countdown"),
		"actors":actors, "winner":GameState.last_winner_slot, "time_remaining":battle._time_remaining,
		"contacts":_contact_events.duplicate(true), "projectiles":shots,
		"config":{"stage":GameState.stage_id, "stocks":GameState.stocks, "timer":GameState.match_timer_seconds,
			"match_type":GameState.match_type,"ruleset":GameState.ruleset_id,"seed":GameState.match_seed}}
	_send(guest_id, latest)
