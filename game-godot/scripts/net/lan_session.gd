extends Node
## Real direct-LAN ENet input bridge. Host BattleScene is the ONLY simulation.
## Guest BattleScene is a read-only presentation replica with no local damage.
## No claim of authenticated Internet service or combat rollback/resimulation.
const Controls = preload("res://scripts/net/lan_controls.gd")
const VERSION := 2
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
var local_rematch_ready := false
var remote_rematch_ready := false
var _guest_result_epoch := -1
var lobby_state: Dictionary = {}
var guest_pick_ready := false
var _lobby_id := ""
var _local_pick: Dictionary = {}
var _pick_revision := 0
var _remote_pick_revision := -1
var _publish_pending := false
var _committed_states: Dictionary = {}
const COMMITTED_HISTORY_LIMIT := 120

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
	_lobby_id = Crypto.new().generate_random_bytes(16).hex_encode()
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
	var allowed: Array = GameState.selectable_roster_ids(false)
	_local_pick = {"fighter":GameState.p1_fighter_id if GameState.p1_fighter_id in allowed else allowed[0], "body":GameState.p1_body_variant if GameState.p1_body_variant in ["male", "female"] else "male"}
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
	local_rematch_ready = false
	remote_rematch_ready = false
	_guest_result_epoch = -1
	lobby_state.clear()
	guest_pick_ready = false
	_lobby_id = ""
	_local_pick.clear()
	_pick_revision = 0
	_remote_pick_revision = -1
	last_sequence = -1
	_publish_pending = false
	_committed_states.clear()
	_last_snapshot = -1
	status = "Offline"

func _peer_joined(id: int) -> void:
	if role != "host" or guest_id != 0 or _bound_once: return
	guest_id = id
	guest_pick_ready = false
	_remote_pick_revision = -1
	_lobby_id = Crypto.new().generate_random_bytes(16).hex_encode()
	status = "Guest connected; host can start the selected versus match"
	_send(guest_id, {"kind":"hello", "version":VERSION, "slot":2, "lobby":_lobby_id})
	_publish_lobby()

func _peer_left(id: int) -> void:
	if role == "host" and id == guest_id:
		guest_id = 0
		guest_pick_ready = false
		_remote_pick_revision = -1
		var battle = _battle.get_ref() if _battle != null else null
		if is_instance_valid(battle): battle.abandon_network_match()
		retire_battle("Guest disconnected; controls retired")

func _send(id: int, data: Dictionary) -> void:
	if id <= 0 or peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED: return
	peer.set_target_peer(id)
	peer.transfer_mode = MultiplayerPeer.TRANSFER_MODE_RELIABLE
	peer.transfer_channel = 0
	peer.put_packet(var_to_bytes(data)) # no object deserialization at receiver

func _physics_process(_delta: float) -> void:
	if peer == null: return
	# ENet closes the native instance after a host departure. Polling that
	# inactive instance every frame logs an engine error, even though the
	# previous frame already observed DISCONNECTED. Retire it before polling.
	if role == "guest" and peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		_retire_guest_transport()
		return
	remote.begin_frame()
	peer.poll()
	if role == "host":
		pass # Peer membership comes from actual ENet connect/disconnect signals.
	else:
		if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED or (_lobby_id.is_empty() and Time.get_ticks_msec() > _guest_deadline):
			_retire_guest_transport()
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
	_try_rematch()
	if _battle != null:
		var battle = _battle.get_ref()
		if not is_instance_valid(battle): retire_battle("Battle scene ended")
		elif not _closed and (battle._match_finished or battle.fighter2.combat_closed): retire_battle("Match complete; late inputs rejected")
		elif battle._paused or get_tree().paused: remote.clear()
		elif Time.get_ticks_msec() - _last_input_ms > INPUT_TIMEOUT_MS: remote.clear()
		if is_instance_valid(battle) and bool(latest.get("paused", false)) != bool(battle._paused): _publish(battle)

func _retire_guest_transport() -> void:
	if peer != null and peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED: peer.close()
	peer = null
	_closed = true
	remote.clear()
	status = "Host unavailable; reconnect from lobby"

func _on_authoritative_step(_frame: int) -> void:
	var battle = _battle.get_ref() if _battle != null else null
	if not is_instance_valid(battle): return
	_ticks += 1
	if battle._battle_sim.committed_active: combat_frames += 1
	# Capture every closed frame, transmit at the existing three-tick cadence.
	# A terminal publication requested during gameplay commit waits until the
	# winner, stocks and actors are all committed together.
	var send_now: bool = _ticks % 3 == 0 or _publish_pending or battle._match_finished
	_publish_pending = false
	_publish(battle, send_now, true)

func _receive(sender: int, message: Dictionary) -> void:
	if role == "host" and message.get("kind", "") == "selection":
		if sender != guest_id or guest_id == 0 or _bound_once or _starting or _battle != null or message.size() != 5 or not message.has_all(["kind", "lobby", "revision", "fighter", "body"]):
			rejected_inputs += 1; return
		if typeof(message.lobby) != TYPE_STRING or message.lobby != _lobby_id or typeof(message.revision) != TYPE_INT or message.revision <= _remote_pick_revision or message.revision > 2147483647 or typeof(message.fighter) != TYPE_STRING or typeof(message.body) != TYPE_STRING:
			rejected_inputs += 1; return
		# Same canonical signed-unlock policy as local selection, without the
		# offline review bypass. Never accept unlock/form/save flags from peers.
		if message.fighter not in GameState.selectable_roster_ids(false) or message.body not in ["male", "female"]:
			rejected_inputs += 1; _send(guest_id, {"kind":"selection_error", "reason":"Fighter/body unavailable in the host's unlocked roster"}); return
		_remote_pick_revision = message.revision
		GameState.p2_fighter_id = message.fighter
		GameState.p2_body_variant = message.body
		guest_pick_ready = true
		_publish_lobby()
		return
	if role == "host" and sender == guest_id and message.get("kind", "") == "rematch":
		if message.size() == 3 and message.has_all(["kind", "epoch", "ready"]) and typeof(message.epoch) == TYPE_INT and message.epoch == epoch and typeof(message.ready) == TYPE_BOOL and message.ready and _bound_once and _closed and latest.get("phase", "") == "result":
			remote_rematch_ready = true
			_try_rematch()
		else: rejected_inputs += 1
		return
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
		_lobby_id = str(message.get("lobby", ""))
		_send_selection()
		status = "Connected as guest slot 2. Host chooses match. P1 controls drive remote fighter."
	elif sender == 1 and message.get("kind", "") == "lobby" and message.get("lobby", "") == _lobby_id and not guest_battle_open:
		lobby_state = message.duplicate(true)
		changed.emit()
	elif sender == 1 and message.get("kind", "") == "selection_error":
		status = str(message.get("reason", "Selection rejected"))
	elif sender == 1 and message.get("kind", "") == "state" and int(message.get("sequence", -1)) > _last_snapshot:
		_last_snapshot = int(message.sequence)
		if epoch != int(message.epoch):
			guest_battle_open = false
			local_rematch_ready = false
			remote_rematch_ready = false
		latest = message.duplicate(true)
		epoch = int(message.epoch)
		status = "Host BattleScene: %s — guest controls slot 2; authoritative host state mirrored; no prediction/rollback" % message.get("phase", "")
		if not guest_battle_open: _open_guest_battle()
		if latest.get("phase", "") == "result" and _guest_result_epoch != epoch:
			_guest_result_epoch = epoch
			_show_guest_results(epoch)
		changed.emit()

func request_rematch() -> bool:
	if role.is_empty() or not latest.get("closed", false) or latest.get("phase", "") != "result": return false
	local_rematch_ready = true
	if role == "guest": _send(1, {"kind":"rematch", "epoch":epoch, "ready":true})
	else: _try_rematch()
	return true

func _try_rematch() -> void:
	if role != "host" or guest_id == 0 or not local_rematch_ready or not remote_rematch_ready or _battle != null: return
	local_rematch_ready = false
	remote_rematch_ready = false
	_bound_once = false
	_starting = false
	combat_frames = 0
	_contact_events.clear()
	remote.clear()
	start_match()

func _show_guest_results(result_epoch: int) -> void:
	await get_tree().create_timer(0.5).timeout
	if role != "guest" or epoch != result_epoch or latest.get("phase", "") != "result": return
	if int(latest.get("winner", -1)) not in [1, 2]: return
	GameState.last_winner_slot = int(latest.winner) # display metadata only; no career/Story award
	SceneRouter.go("results")

func start_match() -> bool:
	if role != "host" or guest_id == 0 or not guest_pick_ready or _bound_once or _starting: return false
	var allowed: Array = GameState.selectable_roster_ids(false)
	if GameState.p1_fighter_id not in allowed or GameState.p2_fighter_id not in allowed or GameState.p1_body_variant not in ["male", "female"] or GameState.p2_body_variant not in ["male", "female"]: return false
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

func select_local_fighter(id: String, body: String) -> bool:
	if role.is_empty() or _starting or _bound_once or guest_battle_open or _battle != null or id not in GameState.selectable_roster_ids(false) or body not in ["male", "female"]: return false
	if role == "host":
		GameState.p1_fighter_id = id; GameState.p1_body_variant = body
		_publish_lobby()
	else:
		_local_pick = {"fighter":id, "body":body}
		_send_selection()
	return true

func _send_selection() -> void:
	if role != "guest" or _lobby_id.is_empty() or _local_pick.is_empty(): return
	_pick_revision += 1
	_send(1, {"kind":"selection", "lobby":_lobby_id, "revision":_pick_revision, "fighter":str(_local_pick.fighter), "body":str(_local_pick.body)})

func _publish_lobby() -> void:
	if role != "host" or _bound_once or _starting: return
	lobby_state = {"kind":"lobby", "lobby":_lobby_id, "roster":GameState.selectable_roster_ids(false), "guest_ready":guest_pick_ready, "revision":_remote_pick_revision,
		"p1":{"fighter":GameState.p1_fighter_id, "body":GameState.p1_body_variant}, "p2":{"fighter":GameState.p2_fighter_id, "body":GameState.p2_body_variant}}
	_send(guest_id, lobby_state)
	changed.emit()

func bind_battle(battle: Node) -> bool:
	if role != "host" or guest_id == 0 or _bound_once or GameState.mode != "online_private":
		_starting = false
		return false
	_bound_once = true
	_starting = false
	local_rematch_ready = false
	remote_rematch_ready = false
	_battle = weakref(battle)
	epoch += 1
	_committed_states.clear()
	_publish_pending = false
	_closed = false
	last_sequence = -1
	_last_input_ms = Time.get_ticks_msec()
	remote.clear()
	battle.fighter2.remote_controls = remote
	battle.fighter2._input_edge_held.clear()
	for actor in [battle.fighter1, battle.fighter2]:
		actor.use_network_physics_clock = true
		actor.hit_resolver.hit_confirmed.connect(_record_contact)
	battle._battle_sim.enable_network_commit(battle, epoch)
	battle._battle_sim.frame_committed.connect(_on_authoritative_step)
	_publish(battle)
	return true

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

func committed_state(frame: int, match_epoch: int) -> Dictionary:
	if match_epoch != epoch or not _committed_states.has(frame): return {}
	# Encoded storage cannot share mutable actor/move/array dictionaries with
	# a renderer, packet consumer or later frame. This is PRESENTATION state,
	# deliberately not advertised as complete/restorable CharacterBody state.
	return bytes_to_var(_committed_states[frame].duplicate())

func _publish(battle: Node, send_packet: bool = true, at_commit: bool = false) -> void:
	if battle._battle_sim.network_commit_enabled and battle._battle_sim.commit_in_progress:
		_publish_pending = true
		return
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
		"snapshot_boundary":"physics_commit" if at_commit else "lifecycle", "rollback_restorable":false,
		"committed_frame":battle._battle_sim.committed_frame, "source_engine_frame":battle._battle_sim.committed_engine_frame,
		"commit_engine_frame":battle._battle_sim.committed_at_engine_frame,
		"simulation_frame":battle._battle_sim.simulation_frame, "completed_engine_frame":battle._battle_sim.completed_engine_frame, "combat_frame":combat_frames, "active":battle._active, "paused":battle._paused, "closed":_closed, "phase":"result" if battle._match_finished else ("abandoned" if battle._network_abandoned else "combat" if battle._active else "countdown"),
		"actors":actors, "winner":GameState.last_winner_slot, "time_remaining":battle._time_remaining,
		"contacts":_contact_events.duplicate(true), "projectiles":shots,
		"config":{"stage":GameState.stage_id, "stocks":GameState.stocks, "timer":GameState.match_timer_seconds,
			"match_type":GameState.match_type,"ruleset":GameState.ruleset_id,"seed":GameState.match_seed}}
	if at_commit:
		_committed_states[battle._battle_sim.committed_frame] = var_to_bytes(latest)
		while _committed_states.size() > COMMITTED_HISTORY_LIMIT: _committed_states.erase(_committed_states.keys()[0])
	if send_packet: _send(guest_id, latest)
