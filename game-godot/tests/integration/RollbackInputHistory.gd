extends SceneTree
## Exact production input/checksum scaffold; no game scene, assets, imports,
## simulated combat outcome, networking, owner save or shipping rollback claim.
const Session = preload("res://scripts/net/rollback_session_gd.gd")
var checks: Array = []
var failures: Array = []
var output := ""

func _init() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks.append(label)
	if not condition: failures.append(label)

func state(session) -> Dictionary:
	return {"public":session.as_dict().duplicate(true), "history":session._history.duplicate(true), "confirmed":session._confirmed.duplicate(true), "predicted":session._predicted.duplicate(true), "checksum":session.last_checksum}

func canonical(buttons: Dictionary) -> Dictionary:
	var result := {"left":false,"right":false,"up":false,"down":false,"jump":false,"attack":false,"special":false,"shield":false,"dodge":false,"grab":false}
	for button in buttons: result[button] = buttons[button]
	return result

func inputs(frame: int, remote_attack: bool = false) -> Array:
	return [canonical({"left":frame % 2 == 0,"jump":frame == 3}), canonical({"attack":remote_attack})]

func expect_rejected(session, frame: int, player: int, buttons: Dictionary, label: String) -> void:
	var before := state(session)
	var result: Dictionary = session.confirm_remote_input(frame, player, buttons)
	check(not result.ok and not result.rolled_back and state(session) == before, label)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.trim_prefix("--ordinary-output=")
	var single = Session.new()
	single.advance_frame(inputs(0), [true,false])
	var corrected: Dictionary = single.confirm_remote_input(0,1,{"attack":true})
	check(corrected.ok and corrected.rolled_back and single.current_frame == 1 and single._history.size() == 1, "one_frame_correction_does_not_invent_seven_unplayed_frames")
	check(single._history[0].inputs == inputs(0,true) and single._history[0].confirmed == [true,true], "corrected_remote_and_recorded_local_input_preserved")
	expect_rejected(single,0,1,{"attack":false},"contradictory_confirmed_input_rejected_before_any_mutation")
	var before := state(single)
	var duplicate: Dictionary = single.confirm_remote_input(0,1,{"attack":true})
	check(duplicate.ok and not duplicate.rolled_back and state(single) == before, "duplicate_confirmation_idempotent")
	for bad in [[-1,1,{"attack":true}], [0,-1,{}], [0,2,{}], [0,1,{"attack":"bad"}], [0,1,{"unknown":false}], [100,1,{}]]:
		expect_rejected(single,bad[0],bad[1],bad[2],"malformed_or_unbounded_packet_rejected:" + str(bad))
	var session = Session.new()
	var reference = Session.new()
	for frame in range(6):
		session.advance_frame(inputs(frame),[true,false])
		reference.advance_frame(inputs(frame,frame in [2,4]),[true,true])
	var first: Dictionary = session.confirm_remote_input(4,1,{"attack":true})
	var second: Dictionary = session.confirm_remote_input(2,1,{"attack":true})
	check(first.ok and second.ok and session.current_frame == 6 and session.rollback_count == 2, "out_of_order_late_confirmations_replay_only_to_original_tip")
	check(session.last_checksum == reference.last_checksum, "final_checksum_matches_on_time_authoritative_inputs")
	var timeline_agrees: bool = session._history.size() == reference._history.size()
	for index in range(mini(session._history.size(),reference._history.size())):
		var actual: Dictionary = session._history[index]
		var expected: Dictionary = reference._history[index]
		timeline_agrees = timeline_agrees and actual.frame == expected.frame and actual.inputs == expected.inputs and actual.checksum == expected.checksum
	check(timeline_agrees, "every_retained_frame_checksum_and_unrelated_local_input_matches_authoritative_timeline")
	var order = Session.new()
	order.advance_frame([{}, {"attack":false,"shield":true}],[true,false])
	var same: Dictionary = order.confirm_remote_input(0,1,{"shield":true,"attack":false})
	check(same.ok and not same.rolled_back and order.rollback_count == 0 and order._history[0].confirmed[1], "dictionary_insertion_order_does_not_create_false_rollback")
	var omitted = Session.new()
	omitted.advance_frame([],[])
	var changed_default: Dictionary = omitted.confirm_remote_input(0,1,{"attack":true})
	check(changed_default.ok and changed_default.rolled_back and omitted.current_frame == 1 and omitted._history[0].inputs[1].attack, "late_input_corrects_implicit_default_even_without_predicted_map_entry")
	var future = Session.new()
	var queued: Dictionary = future.confirm_remote_input(2,1,{"attack":true})
	check(queued.ok and queued.get("queued",false) and future.current_frame == 0 and future._history.is_empty(), "bounded_future_confirmation_queues_without_advancing")
	for frame in range(3): future.advance_frame(inputs(frame),[true,false])
	check(future.current_frame == 3 and future._history[2].inputs[1].attack and future._history[2].confirmed[1], "queued_confirmation_used_on_its_exact_frame")
	var bounded = Session.new()
	bounded.policy.configure(2,4,3)
	for frame in range(100):
		bounded.advance_frame(inputs(frame),[true,false])
		bounded.confirm_remote_input(frame,1,{"attack":true})
	var floor_frame: int = bounded._history[0].frame
	var no_old_entries := true
	for records in [bounded._confirmed,bounded._predicted]:
		for key in records: no_old_entries = no_old_entries and int(str(key).get_slice(":",0)) >= floor_frame
	check(bounded.current_frame == 100 and bounded._history.size() == 6 and bounded._confirmed.size() <= 12 and bounded._predicted.size() <= 12 and no_old_entries, "long_session_bounds_input_maps_with_retained_checksum_history")
	var confirmed_before: Dictionary = bounded._confirmed.duplicate(true)
	var history_before: Array = bounded._history.duplicate(true)
	var late: Dictionary = bounded.confirm_remote_input(0,1,{"attack":true})
	check(not late.ok and late.error == "beyond_rollback" and bounded.desync_detected and bounded._confirmed == confirmed_before and bounded._history == history_before and bounded.current_frame == 100, "stale_confirmation_reports_desync_without_poisoning_input_or_history")
	# A queued remote confirmation is authoritative even when the local frame
	# call accidentally marks its own contradictory copy confirmed.
	var overwrite = Session.new()
	check(overwrite.confirm_remote_input(0,1,{"attack":true}).ok,"queue_actual_remote_attack_before_frame")
	var overwrite_before := state(overwrite)
	var overwritten: Dictionary = overwrite.advance_frame([{"jump":true},{"attack":false}],[true,true])
	check(not overwritten.ok and overwritten.error == "conflicting_confirmation" and state(overwrite) == overwrite_before,"queued_confirmation_cannot_be_overwritten_and_first_slot_is_atomic")
	var matching: Dictionary = overwrite.advance_frame([{"jump":true},{"attack":true,"shield":false}],[true,true])
	check(matching.ok and overwrite.current_frame == 1 and overwrite._history[0].inputs == [canonical({"jump":true}),canonical({"attack":true})],"matching_queued_confirmation_advances_once_with_original_owned_inputs")
	var returned_inputs: Array = matching.inputs
	returned_inputs[0].jump = false
	check(overwrite._history[0].inputs[0].jump and overwrite._confirmed["0:0"].jump,"caller_cannot_rewrite_owned_history_through_returned_inputs")
	# The public bool contract is the same in advance and confirmation. Validate
	# a bad later slot or flag before any earlier slot becomes authoritative.
	for bad_inputs in [[{}, {"attack":"bad"}], [{},[]], [{},null], [{}, {"teleport":false}], [{},{},{}]]:
		var invalid_frame = Session.new()
		var invalid_before := state(invalid_frame)
		var invalid_result: Dictionary = invalid_frame.advance_frame(bad_inputs,[true,true])
		check(not invalid_result.ok and state(invalid_frame) == invalid_before,"malformed_later_slot_rejects_whole_frame:"+str(bad_inputs))
	for bad_flags in [[true,1], [true,"false"], [true,null], [true,true,true]]:
		var invalid_frame = Session.new()
		var invalid_before := state(invalid_frame)
		var invalid_result: Dictionary = invalid_frame.advance_frame([{"attack":true},{}],bad_flags)
		check(not invalid_result.ok and state(invalid_frame) == invalid_before,"malformed_later_flag_rejects_whole_frame:"+str(bad_flags))
	var omitted_false = Session.new()
	omitted_false.advance_frame([{},{}],[true,false])
	var omitted_before := state(omitted_false)
	var explicit_false: Dictionary = omitted_false.confirm_remote_input(0,1,{"attack":false,"shield":false})
	check(explicit_false.ok and not explicit_false.rolled_back and omitted_false.rollback_count == 0 and omitted_false._history[0].confirmed[1],"omitted_false_and_explicit_false_confirm_without_false_rollback")
	var duplicate_state := state(omitted_false)
	check(omitted_false.confirm_remote_input(0,1,{}).ok and state(omitted_false) == duplicate_state,"sparse_semantically_identical_duplicate_is_idempotent")
	var full_false = Session.new()
	full_false.advance_frame([canonical({}),canonical({})],[true,false])
	check(full_false._history[0].checksum == omitted_before.history[0].checksum,"sparse_and_full_released_inputs_have_same_authoritative_checksum")
	for invalid_count in [0,1,3,5,7,9,1000000]:
		var wrong_count = Session.new(); wrong_count.max_players = invalid_count
		var wrong_before := state(wrong_count)
		var wrong_frame: Dictionary = wrong_count.advance_frame([],[])
		var wrong_confirm: Dictionary = wrong_count.confirm_remote_input(0,0,{})
		check(not wrong_frame.ok and not wrong_confirm.ok and state(wrong_count) == wrong_before,"undeclared_player_count_rejects_without_allocating_frame:"+str(invalid_count))
	# These are bounded input-array contracts ONLY, not independently connected
	# clients or accepted 4/6/8-player BattleScenes.
	for count in [2,4,6,8]:
		var slots = Session.new(); slots.max_players = count
		check(slots.confirm_remote_input(0,count-1,{"grab":true}).ok,"declared_scaffold_slot_count_accepts_last_owned_slot:"+str(count))
		var slots_step: Dictionary = slots.advance_frame([],[])
		check(slots_step.ok and slots_step.inputs.size() == count and slots_step.inputs[count-1].grab and slots._history[0].confirmed[count-1],"declared_scaffold_array_retains_queued_last_slot_not_multiclient_acceptance:"+str(count))
		var slot_before := state(slots)
		check(not slots.confirm_remote_input(1,count,{}).ok and state(slots) == slot_before,"slot_outside_declared_count_is_rejected:"+str(count))
	var reconfigured = Session.new(); reconfigured.advance_frame([{},{}],[true,false]); reconfigured.max_players = 4
	var reconfigured_before := state(reconfigured)
	check(not reconfigured.advance_frame([],[]).ok and not reconfigured.confirm_remote_input(1,3,{}).ok and state(reconfigured) == reconfigured_before,"player_count_cannot_change_under_retained_input_history")
	reconfigured.reset()
	check(reconfigured.advance_frame([],[]).ok and reconfigured.current_frame == 1 and reconfigured._history[0].inputs.size() == 4,"explicit_session_reset_releases_old_player_count_binding")
	var prefix = Session.new()
	prefix.confirm_remote_input(2,1,{"attack":true})
	check(prefix.confirmed_through_frame(1)==-1,"queued_later_input_does_not_acknowledge_missing_prefix")
	prefix.confirm_remote_input(0,1,{})
	check(prefix.confirmed_through_frame(1)==0,"received_prefix_stops_at_first_gap")
	prefix.confirm_remote_input(1,1,{"shield":true})
	check(prefix.confirmed_through_frame(1)==2 and prefix.current_frame==0,"filling_hole_advances_input_receipt_prefix_not_simulation")
	prefix.reset()
	check(prefix.confirmed_through_frame(1)==-1 and prefix._confirmed_through.is_empty(),"session_reset_retires_confirmation_prefix")
	check(Session.self_test().ok, "existing_private_checksum_scaffold_self_test_still_passes")
	var result := {"PASS":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Actual standalone Godot input/checksum scaffold only. No game-world rollback, multiplayer sockets, renderer/art/device/human acceptance.","HUMAN_ART_APPROVED":false,"RC2_READY":false,"V1_0_0_RELEASE_AUTHORIZED":false}
	if not output.is_empty():
		var file := FileAccess.open(output.path_join("ROLLBACK_INPUT_HISTORY.json"),FileAccess.WRITE)
		if file == null: push_error("Cannot write rollback result"); quit(2); return
		file.store_string(JSON.stringify(result,"  ")); file.close()
	print("ROLLBACK_INPUT_HISTORY ","PASS" if failures.is_empty() else "FAIL"," checks=",checks.size()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
