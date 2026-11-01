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

func inputs(frame: int, remote_attack: bool = false) -> Array:
	return [{"left":frame % 2 == 0,"jump":frame == 3}, {"attack":remote_attack}]

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
	check(Session.self_test().ok, "existing_private_checksum_scaffold_self_test_still_passes")
	var result := {"PASS":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Actual standalone Godot input/checksum scaffold only. No game-world rollback, multiplayer sockets, renderer/art/device/human acceptance.","HUMAN_ART_APPROVED":false,"RC2_READY":false,"V1_0_0_RELEASE_AUTHORIZED":false}
	if not output.is_empty():
		var file := FileAccess.open(output.path_join("ROLLBACK_INPUT_HISTORY.json"),FileAccess.WRITE)
		if file == null: push_error("Cannot write rollback result"); quit(2); return
		file.store_string(JSON.stringify(result,"  ")); file.close()
	print("ROLLBACK_INPUT_HISTORY ","PASS" if failures.is_empty() else "FAIL"," checks=",checks.size()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
