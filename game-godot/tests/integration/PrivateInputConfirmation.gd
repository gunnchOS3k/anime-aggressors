extends SceneTree
## Actual protocol, integrity wrapper, NetworkSim, private delivery and rollback
## classes. A standalone fixture may supply an inert CampaignRuntime autoload
## solely for loading the unrelated replay path; no Story acceptance is earned.
const Protocol = preload("res://scripts/net/online_protocol.gd")
const Integrity = preload("res://scripts/net/anti_tamper.gd")
var Stack
var checks: Array = []
var failures: Array = []
var output := ""

func _init() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks.append(label)
	if not condition: failures.append(label)

func fresh():
	var stack = Stack.new()
	stack.host_create_room("Host", 0.0, 0.0)
	stack.guest_join("Guest", "", 0.0, 0.0)
	stack.ready_and_start(77)
	stack._deliver(stack.host_peer, stack.guest_peer, 0.0)
	stack._deliver(stack.guest_peer, stack.host_peer, 0.0)
	stack.clock_ms = 250.0
	return stack

func peer_state(peer) -> Dictionary:
	return {
		"confirmed_frame":peer.last_confirmed_frame, "last_rx_ms":peer.last_rx_ms,
		"frame":peer.rollback.current_frame, "checksum":peer.rollback.last_checksum,
		"rollback_count":peer.rollback.rollback_count, "history":peer.rollback._history.duplicate(true),
		"confirmed":peer.rollback._confirmed.duplicate(true), "predicted":peer.rollback._predicted.duplicate(true),
	}

func input_message(payload: Dictionary) -> Dictionary:
	return Integrity.sign_envelope(Protocol.envelope(Protocol.MSG_INPUT, payload))

func reject_case(stack, payload: Dictionary, expected_reason: String, label: String, source = null) -> void:
	var sender = stack.guest_peer if source == null else source
	var receiver = stack.host_peer
	var before := peer_state(receiver)
	sender.outbound.send(input_message(payload))
	var accepted: Array = stack._deliver(sender, receiver, 100.0)
	check(accepted.is_empty() and stack.ended and stack.end_reason == "input_rejected:" + expected_reason, label + ":rejected_and_terminal")
	check(peer_state(receiver) == before, label + ":no_confirmation_history_or_liveness_progress")
	var has_diagnostic: bool = stack.get_property_list().any(func(property):return property.name == "last_input_rejection")
	var diagnostic: Dictionary = stack.get("last_input_rejection") if has_diagnostic else {}
	check(diagnostic.get("reason", "") == expected_reason and not diagnostic.has("winner_slot"), label + ":bounded_reason_without_invented_winner")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.trim_prefix("--ordinary-output=")
	if "Anime Aggressors" in OS.get_user_data_dir():
		push_error("Refused owner save profile"); quit(2); return
	Stack = load("res://scripts/net/private_netplay_stack.gd")
	if Stack == null or not Stack.can_instantiate():
		push_error("Private input delivery source did not load"); quit(2); return
	# Genuine signed protocol packets still traverse both directions. Inputs
	# are per-frame records, never damage/position/outcome grants.
	var normal = fresh()
	for frame in range(3):
		var host_buttons := {"attack":frame % 2 == 0}
		var guest_buttons := {"shield":frame % 2 != 0}
		normal.host_peer.rollback.advance_frame([host_buttons,{}],[true,false])
		normal.guest_peer.rollback.advance_frame([{},guest_buttons],[false,true])
		normal.host_peer.outbound.send(Integrity.sign_envelope(Protocol.encode_input(frame,0,host_buttons)))
		normal.guest_peer.outbound.send(Integrity.sign_envelope(Protocol.encode_input(frame,1,guest_buttons)))
		var host_to_guest: Array = normal._deliver(normal.host_peer,normal.guest_peer,0.0)
		var guest_to_host: Array = normal._deliver(normal.guest_peer,normal.host_peer,0.0)
		check(host_to_guest.size() == 1 and guest_to_host.size() == 1 and not normal.ended and normal.host_peer.last_confirmed_frame == frame and normal.guest_peer.last_confirmed_frame == frame, "ordinary_owned_bilateral_input_acceptance:%d" % frame)
		check(normal.host_peer.rollback._history == normal.guest_peer.rollback._history and normal.host_peer.rollback.current_frame == frame + 1, "actual_peer_input_and_checksum_histories_agree_at_played_tip:%d" % frame)
	var duplicate_before: Dictionary = {"history":normal.host_peer.rollback._history.duplicate(true)}
	normal.guest_peer.outbound.send(Integrity.sign_envelope(Protocol.encode_input(2,1,{"shield":false})))
	var duplicate: Array = normal._deliver(normal.guest_peer,normal.host_peer,0.0)
	check(duplicate.size() == 1 and normal.host_peer.rollback._history == duplicate_before.history and normal.host_peer.last_confirmed_frame == 2, "identical_duplicate_does_not_rewrite_or_advance_confirmed_history")
	var conflict = fresh()
	conflict.guest_peer.outbound.send(Integrity.sign_envelope(Protocol.encode_input(0,1,{"attack":true})))
	conflict._deliver(conflict.guest_peer,conflict.host_peer,0.0)
	reject_case(conflict,{"frame":0,"player_id":1,"buttons":{"attack":false}},"conflicting_confirmation","contradictory_remote_confirmation")
	reject_case(fresh(),{"frame":9,"player_id":1,"buttons":{}},"future_input_limit","remote_confirmation_beyond_prediction_window")
	var stale = fresh()
	for frame in range(10): stale.host_peer.rollback.advance_frame([{},{}],[true,false])
	reject_case(stale,{"frame":0,"player_id":1,"buttons":{"attack":true}},"beyond_rollback","remote_confirmation_older_than_retained_window")
	check(stale.host_peer.rollback.desync_detected, "stale_input_preserves_explicit_desync_signal")
	reject_case(fresh(),{"frame":-1,"player_id":1,"buttons":{}},"invalid_input","negative_frame")
	reject_case(fresh(),{"frame":0,"player_id":1,"buttons":{"teleport":true}},"invalid_input","unknown_button_rejected_after_valid_envelope")
	reject_case(fresh(),{"frame":0,"player_id":1,"buttons":{"attack":1.0}},"invalid_input","numeric_button_rejected_after_valid_envelope")
	for payload in [
		{"frame":"1","player_id":1,"buttons":{}},
		{"frame":0.5,"player_id":1,"buttons":{}},
		{"frame":0,"player_id":"1","buttons":{}},
		{"frame":0,"player_id":1,"buttons":[]},
		{"player_id":1,"buttons":{}},
	]:
		reject_case(fresh(),payload,"invalid_input_payload","malformed_input_shape:" + str(payload))
	reject_case(fresh(),{"frame":0,"player_id":0,"buttons":{}},"player_slot_not_owned","guest_cannot_confirm_host_slot")
	var spectator = fresh()
	spectator.add_spectator("Observer")
	reject_case(spectator,{"frame":0,"player_id":1,"buttons":{}},"player_slot_not_owned","spectator_cannot_inject_guest_input",spectator.spectator_peer)
	var stranger = fresh()
	var other = stranger._make_peer("Unregistered",1,false)
	reject_case(stranger,{"frame":0,"player_id":1,"buttons":{}},"player_slot_not_owned","unregistered_peer_cannot_borrow_guest_id",other)
	var batch = fresh()
	var before := peer_state(batch.host_peer)
	batch.guest_peer.outbound.send(input_message({"frame":20,"player_id":1,"buttons":{}}))
	batch.guest_peer.outbound.send(input_message({"frame":0,"player_id":1,"buttons":{"attack":true}}))
	var batch_result: Array = batch._deliver(batch.guest_peer,batch.host_peer,0.0)
	check(batch_result.is_empty() and batch.ended and peer_state(batch.host_peer) == before,"rejected_first_input_prevents_later_same_batch_acceptance")
	batch.guest_peer.outbound.send(input_message({"frame":0,"player_id":1,"buttons":{"attack":true}}))
	check(batch._deliver(batch.guest_peer,batch.host_peer,100.0).is_empty() and peer_state(batch.host_peer) == before,"terminal_rejection_stays_closed_during_subsequent_drain")
	var tamper = fresh()
	var tamper_before := peer_state(tamper.host_peer)
	var bad := input_message({"frame":0,"player_id":1,"buttons":{}})
	bad.integrity = "corrupted"
	tamper.guest_peer.outbound.send(bad)
	tamper.guest_peer.outbound.send(input_message({"frame":0,"player_id":1,"buttons":{}}))
	check(tamper._deliver(tamper.guest_peer,tamper.host_peer,0.0).is_empty() and tamper.ended and tamper.end_reason == "tamper" and peer_state(tamper.host_peer) == tamper_before,"invalid_integrity_does_not_accept_following_packet_in_same_batch")
	var campaign = root.get_node_or_null("CampaignRuntime")
	var campaign_before: String = JSON.stringify(campaign.progress) if campaign != null else ""
	var ordinary = fresh()
	var replay: Dictionary = ordinary.simulate_match_frames(12)
	check(replay.ok and not ordinary.ended and replay.host_confirmed == 11 and replay.guest_confirmed == 11,"ordinary_twelve_frame_private_simulation_and_replay_still_complete")
	check(campaign == null or JSON.stringify(campaign.progress) == campaign_before,"input_delivery_never_changes_campaign_progress")
	var result := {"PASS":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Actual private protocol/NetworkSim input-delivery and checksum scaffold only; no sockets, combat-world rollback, public authentication, native art/device or human acceptance.","HUMAN":false,"RC2":false,"V1":false}
	if not output.is_empty():
		var file := FileAccess.open(output.path_join("PRIVATE_INPUT_CONFIRMATION.json"),FileAccess.WRITE)
		if file == null: push_error("Cannot write input confirmation result"); quit(2); return
		file.store_string(JSON.stringify(result,"  ")); file.close()
	print("PRIVATE_INPUT_CONFIRMATION ","PASS" if failures.is_empty() else "FAIL"," checks=",checks.size()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
