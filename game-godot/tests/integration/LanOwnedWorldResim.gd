extends "res://tests/integration/BodyVerticalReplay.gd"
## Actual independent localhost ENet processes exchange owned input into the
## bounded isolated world. Both load genuine public Training geometry/jab.
## Shipping BattleScene/CharacterBody LAN is unchanged and NOT rollback-enabled.
const Resim = preload("res://scripts/net/experimental/flat_combat_resim.gd")
const Controls = preload("res://scripts/net/lan_controls.gd")
const Wire = preload("res://tests/support/ResimWire.gd")
var side := ""
var port := 27898
var wire
var api: SceneMultiplayer
var peer: ENetMultiplayerPeer
var remote_peer := 0
var resim
var ready := false
var acknowledged := 0
var tick := 0
var base_frame := 0
var guest_pending: Array = []
var delivery_order: Array = []
var correction_rows: Array = []
var rejected_packets := 0
var dropped_primaries := 0
var resent := 0
var duplicate_observed := false
var saw_predicted_body_hit := false
var remote_digest := ""
var initial_digest := ""
var done := false
var story_before := ""
var initial_world: Dictionary = {}
var start_clock := 0

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.trim_prefix("--ordinary-output=")
		if arg.begins_with("--lan-role="): side = arg.trim_prefix("--lan-role=")
		if arg.begins_with("--lan-port="): port = int(arg.trim_prefix("--lan-port="))
	if output.is_empty() or side not in ["host","guest"] or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Isolated explicit ENet role required"); quit(2); return
	story_before = JSON.stringify(root.get_node("CampaignRuntime").progress)
	if not await fresh_training(): finish(); return
	keys(["attack"]); await frames(2); keys([])
	resolved_jab = battle.fighter1.move_runner.move_data.duplicate(true)
	check(battle.fighter1.move_runner.current_move_id() == "jab_1" and not resolved_jab.is_empty(), "ordinary_input_resolved_actual_canonical_jab")
	if resolved_jab.is_empty() or not await fresh_training(): finish(); return
	var script = load("res://scripts/net/experimental/flat_combat_trial.gd")
	trial = script.new(); root.add_child(trial)
	var stage: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/stages/training-grid.json"))
	check(trial.configure_from_live(battle.fighter1,battle.fighter2,stage,1204,resolved_jab),"bind_actual_public_Training_geometry_and_BASE_rules")
	if not trial.failure.is_empty(): evidence.failure = trial.failure; finish(); return
	battle._battle_sim.set_paused(true)
	battle.fighter1.set_physics_process(false); battle.fighter2.set_physics_process(false)
	# Declared pre-contact spacing, using normal owned movement. Cross-process
	# independently sampled controls begin at the captured interaction boundary.
	for i in range(180):
		if trial.actors[1].position.x-trial.actors[0].position.x < 61.0: break
		if not trial.advance(command(0.65),command()): break
	for i in range(12):
		if not trial.advance(command(),command()): break
	base_frame = trial.frame; initial_world = trial.capture()
	initial_digest = trial.portable_state_checksum()
	wire = Wire.new(); wire.name = "ResimWire"; root.add_child(wire)
	api = SceneMultiplayer.new(); set_multiplayer(api,wire.get_path())
	wire.received.connect(receive_packet)
	peer = ENetMultiplayerPeer.new()
	if side == "host":
		peer.set_bind_ip("127.0.0.1")
		check(peer.create_server(port,1) == OK,"real_ENet_server")
		api.multiplayer_peer = peer
		var marker := FileAccess.open(output.path_join("HOST_READY"),FileAccess.WRITE)
		marker.store_string(str(OS.get_process_id())); marker.close()
	else:
		check(peer.create_client("127.0.0.1",port) == OK,"real_ENet_guest")
		api.multiplayer_peer = peer
		var deadline := Time.get_ticks_msec()+12000
		while peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED and Time.get_ticks_msec()<deadline: await process_frame
		check(peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED,"guest_connected_over_socket")
		if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED: finish(); return
		remote_peer = 1
		wire.send_to(1,{"kind":"hello","digest":initial_digest,"frame":base_frame})
	start_clock = Time.get_ticks_msec()
	var wait_until := Time.get_ticks_msec()+12000
	while not ready and Time.get_ticks_msec()<wait_until: await process_frame
	check(ready and remote_peer > 0,"independent_peer_handshake_and_identical_initial_world")
	if not ready: finish(); return
	if side == "host": await host_play()
	else:
		wait_until = Time.get_ticks_msec()+20000
		while not done and Time.get_ticks_msec()<wait_until: await process_frame
		check(done,"guest_receives_confirmed_end_without_invented_results")
		for i in range(3): await process_frame # Flush reliable final acknowledgment before close.
	check(JSON.stringify(root.get_node("CampaignRuntime").progress) == story_before,"no_Story_or_unlock_progression_writes")
	finish()

func bind_resim() -> void:
	resim = Resim.new()
	var guest_id: int = remote_peer if side == "host" else api.get_unique_id()
	check(resim.bind(trial,[{"seat_id":1,"peer_id":1,"role":"human","fighter_id":"kaia-windrow"},{"seat_id":2,"peer_id":guest_id,"role":"human","fighter_id":"juno-spark"}]),"bind_distinct_transport_owned_fighting_seats_no_bots")

func receive_packet(sender: int, payload: Dictionary) -> void:
	var kind := str(payload.get("kind",""))
	if side == "host" and kind == "hello" and not ready:
		if sender <= 1 or payload.get("digest","") != initial_digest or payload.get("frame",-1) != base_frame: rejected_packets += 1; return
		remote_peer = sender; bind_resim(); ready = true
		wire.send_to(sender,{"kind":"welcome","digest":initial_digest,"frame":base_frame})
		return
	if sender != remote_peer or remote_peer == 0: rejected_packets += 1; return
	if side == "guest" and kind == "welcome" and not ready:
		if payload.get("digest","") != initial_digest or payload.get("frame",-1) != base_frame: rejected_packets += 1; return
		bind_resim(); ready = true; return
	if not ready: rejected_packets += 1; return
	if side == "guest" and kind == "clock":
		if payload.get("epoch",-1) != trial.epoch or payload.get("tick",-1) != tick+1: rejected_packets += 1; return
		tick += 1
		if tick <= 28:
			keys(["shield"]) # This process owns only the guest control sample.
			var owned := sampled_controls()
			if not resim.advance_confirmed(payload.input,owned): check(false,"guest_confirmed_advance"); done=true; return
			var packet := {"kind":"input","epoch":trial.epoch,"frame":trial.frame,"seat":1,"input":owned}
			var delay := 4 if tick%4 != 0 else 5
			var lost := tick%5 == 0
			if lost: dropped_primaries += 1; resent += 1; delay = 6
			guest_pending.append({"due":tick+delay,"packet":packet})
			if tick == 2:
				var spoof := packet.duplicate(true); spoof.seat = 0; wire.send_to(1,spoof)
				spoof = packet.duplicate(true); spoof.epoch += 1; wire.send_to(1,spoof)
		# Jitter can co-deliver inputs; reverse due rows to exercise reordering.
		var due: Array = guest_pending.filter(func(row):return row.due <= tick)
		due.reverse()
		for row in due:
			wire.send_to(1,row.packet); guest_pending.erase(row)
			if row.packet.frame == base_frame+10: wire.send_to(1,row.packet)
		wire.send_to(1,{"kind":"step_ack","tick":tick}) # Clock only, no input confirmation.
		if tick == 36:
			check(guest_pending.is_empty() and trial.events.size() == 1 and trial.events[0].contact_result in ["shield","parry"],"guest_real_guard_contact_and_all_input_retransmissions_sent")
			wire.send_to(1,{"kind":"digest","digest":trial.portable_state_checksum(),"frame":trial.frame})
	elif side == "host" and kind == "input":
		if payload.get("epoch",-1) != trial.epoch or payload.get("seat",-1) != 1 or typeof(payload.get("frame")) != TYPE_INT or typeof(payload.get("input")) != TYPE_DICTIONARY:
			rejected_packets += 1; return
		var before: Dictionary = trial.capture()
		var result: Dictionary = resim.correct_remote_input(payload.frame,1,payload.input,payload.epoch)
		if not result.get("ok",false):
			rejected_packets += 1; check(trial.capture()==before,"rejected_input_cannot_mutate_owned_world"); return
		delivery_order.append(payload.frame)
		duplicate_observed = duplicate_observed or bool(result.get("duplicate",false))
		if result.get("rolled_back",false): correction_rows.append(result)
	elif side == "host" and kind == "step_ack": acknowledged = int(payload.get("tick",0))
	elif side == "host" and kind == "digest": remote_digest = str(payload.get("digest",""))
	elif side == "guest" and kind == "done":
		check(payload.get("digest","") == trial.portable_state_checksum(),"guest_observes_matching_confirmed_world_checksum")
		wire.send_to(1,{"kind":"done_ack"}); done = true
	elif side == "host" and kind == "done_ack": done = true

func sampled_controls() -> Dictionary:
	var packet: Dictionary = Controls.local_packet(trial.epoch,trial.frame+1)
	return {"axis":float(packet.axis),"attack":bool(packet.buttons.attack),"shield":bool(packet.buttons.shield),"jump":bool(packet.buttons.jump),"up":bool(packet.buttons.up),"down":bool(packet.buttons.down)}

func host_play() -> void:
	for i in range(1,37):
		tick = i
		var owned := command()
		if i <= 28:
			keys(["attack"] if i == 1 else [])
			owned = sampled_controls()
			check(resim.advance_with_prediction(0,owned,command()),"host_advances_owned_input_and_declared_remote_prediction:"+str(i))
			saw_predicted_body_hit = saw_predicted_body_hit or trial.events.any(func(event):return event.contact_result == "hit")
		wire.send_to(remote_peer,{"kind":"clock","epoch":trial.epoch,"tick":i,"input":owned})
		var deadline := Time.get_ticks_msec()+2000
		while acknowledged<i and Time.get_ticks_msec()<deadline: await process_frame
		if acknowledged<i: check(false,"guest_clock_timeout"); return
		await process_frame
	keys([])
	var deadline := Time.get_ticks_msec()+3000
	while remote_digest.is_empty() and Time.get_ticks_msec()<deadline: await process_frame
	check(saw_predicted_body_hit and not correction_rows.is_empty(),"actual_predicted_body_contact_then_remote_input_world_resimulation")
	check(trial.events.size()==1 and trial.events[0].contact_result in ["shield","parry"] and trial.actors[1].damage_percent==0.0,"corrected_guard_retires_predicted_damage_and_leaves_one_authoritative_contact_intent")
	check(not remote_digest.is_empty() and remote_digest==trial.portable_state_checksum(),"independent_ENet_clients_agree_on_complete_supported_world_tip")
	check(duplicate_observed and rejected_packets==2,"duplicate_is_idempotent_foreign_epoch_and_host_seat_spoofs_rejected")
	var reordered := false
	for i in range(1,delivery_order.size()): reordered = reordered or delivery_order[i]<delivery_order[i-1]
	check(reordered,"actual_wire_delivery_has_reordered_frames")
	check(resim.history.all(func(row):return row.confirmed[0] and row.confirmed[1]),"retained_tip_has_both_real_client_inputs_confirmed")
	var before: Dictionary = trial.capture()
	var history_before: Array = resim.history.duplicate(true)
	check(not resim.advance_confirmed(command(0.0,true),command()) and trial.capture()==before and resim.history==history_before,"unsupported_second_attack_rolls_back_entire_failed_advance")
	check(not resim.correct_remote_input(trial.frame,1,command(),trial.epoch).get("ok",true) and trial.capture()==before,"confirmed_remote_input_cannot_be_rewritten")
	# Public restore still rejects forward records. Only the unforgeable local
	# transaction can abort to its own privately captured pre-replay origin.
	var ticket: RefCounted = trial.begin_replay_transaction()
	check(ticket!=null and trial.restore(initial_world),"trusted_replay_begins_and_rewinds_to_retained_origin")
	check(not trial.restore(before),"public_forward_state_installation_still_rejected")
	check(not trial.end_replay_transaction(RefCounted.new(),false),"foreign_transaction_ticket_has_no_authority")
	check(trial.end_replay_transaction(ticket,false) and trial.capture()==before,"abort_reinstalls_only_privately_captured_original_tip")
	evidence={"pid":OS.get_process_id(),"guest_peer":remote_peer,"ticks":28,"wire_delay_frames":[4,5,6],"delivery_order":delivery_order,"corrections":correction_rows,"checksum":trial.portable_state_checksum(),"guest_checksum":remote_digest,"rejected":rejected_packets}
	wire.send_to(remote_peer,{"kind":"done","digest":trial.portable_state_checksum()})
	deadline = Time.get_ticks_msec()+3000
	while not done and Time.get_ticks_msec()<deadline: await process_frame
	check(done,"guest_acknowledges_same_final_world")

func finish() -> void:
	keys([])
	if side == "guest": evidence={"pid":OS.get_process_id(),"host_peer":remote_peer,"ticks":28,"dropped_primaries":dropped_primaries,"retransmitted":resent,"checksum":trial.portable_state_checksum() if trial!=null else ""}
	if api!=null: api.multiplayer_peer = null
	if peer!=null: peer.close()
	if trial!=null: trial.free(); trial=null
	var result := {"PASS":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"Two independent actual ENet localhost Godot processes, separately sampled public controls, real canonical contact in isolated owned world, 4/5/6-frame deferred/reordered/lost-primary+retransmitted wire inputs and exact supported-world convergence. Not shipping BattleScene rollback, 4/6/8-player matches, active CPU, human keyboard participants, physical LAN/online, native rendered/audio/art/device or human acceptance.","HUMAN_ART_APPROVED":false,"RC2_READY":false,"V1_0_0_RELEASE_AUTHORIZED":false}
	var file := FileAccess.open(output.path_join("LAN_"+side.to_upper()+".json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"  ")); file.close()
	print("LAN_OWNED_WORLD_RESIM ",side," ","PASS" if failures.is_empty() else "FAIL"," checks=",checks.size()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
